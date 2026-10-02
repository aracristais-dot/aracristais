-- Cartão no próprio site (formulário seguro do Mercado Pago, sem sair da página).
-- 1) ara_criar_pagamento com metodo = 'cartao' só cria o pedido e devolve o total.
-- 2) O formulário do Mercado Pago gera o token do cartão no navegador (os dados do cartão não passam pela ARA).
-- 3) ara_pagar_cartao cobra o pedido com esse token. Se o cartão for recusado, o cliente tenta de novo no MESMO pedido,
--    sem criar pedido duplicado; pedido já pago ou em análise não é cobrado de novo.
CREATE OR REPLACE FUNCTION public.ara_criar_pagamento(p jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare
  c_loja jsonb; c_frete jsonb; c_arcas jsonb; c_pag jsonb; tok jsonb; modo text; token text;
  linhas jsonb := '[]'::jsonb; it jsonb; prod record; v jsonb; qtd int; preco numeric; nome text; est int; adic numeric;
  subtotal numeric := 0; valor_frete numeric; reg jsonb; cepd text; total numeric; pid uuid; pref jsonb;
  resp extensions.http_response; mp jsonb; parcelas int; site text := 'https://aracristais.com.br'; cup jsonb;
  pix jsonb; email_pagador text;
begin
  select valor into c_loja from ara_config where chave = 'loja';
  select valor into c_frete from ara_config where chave = 'frete';
  select valor into c_arcas from ara_config where chave = 'arcas';
  select valor into c_pag from ara_config where chave = 'pagamento';
  select valor into tok from ara_privado where chave = 'mercadopago';
  modo := case when c_pag->>'modo' = 'teste' then 'teste' else 'producao' end;
  token := tok->>modo;
  if token is null then return jsonb_build_object('erro','Pagamento não configurado'); end if;

  if coalesce(p->>'tipo','loja') = 'arca' then
    v := c_arcas->'modelos'->(p->>'modelo');
    if v is null then return jsonb_build_object('erro','Modelo inválido'); end if;
    if v->>'disponivel' = 'false' or (jsonb_typeof(v->'estoque') = 'number' and (v->>'estoque')::int <= 0) then
      return jsonb_build_object('erro','Este modelo está esgotado'); end if;
    linhas := jsonb_build_array(jsonb_build_object('title',(v->>'nome')||' · peça única ARA','quantity',1,'unit_price',(v->>'preco')::numeric,
              'ref',jsonb_build_object('tipo','arca','modelo',p->>'modelo')));
    parcelas := coalesce((c_arcas->>'parcelasMax')::int, 10);
  else
    parcelas := coalesce((c_loja->>'parcelasMax')::int, 6);
  end if;

  -- itens da loja: o pedido da loja, ou os acessórios que acompanham a Arca
  for it in select * from jsonb_array_elements(coalesce(p->'itens','[]'::jsonb)) loop
    select * into prod from ara_produtos where slug = it->>'slug' and ativo;
    if not found or not prod.disponivel then return jsonb_build_object('erro','Produto indisponível'); end if;
    qtd := greatest(1, least(10, coalesce((it->>'qtd')::int, 1)));
    preco := prod.preco; nome := prod.nome; est := prod.estoque; v := null;
    if jsonb_array_length(coalesce(prod.variantes,'[]'::jsonb)) > 0 then
      select e into v from jsonb_array_elements(prod.variantes) e where e->>'id' = it->>'variante' limit 1;
      if v is null then v := prod.variantes->0; end if;
      preco := (v->>'preco')::numeric; nome := nome || ' (' || (v->>'nome') || ')';
      if jsonb_typeof(v->'estoque') = 'number' then est := (v->>'estoque')::int; end if;
    end if;
    if est is not null and est < qtd then return jsonb_build_object('erro','Estoque insuficiente: '||nome); end if;
    adic := 0;
    if coalesce((it->>'adicional')::boolean,false) and not coalesce(prod.sem_adicional,false) then
      adic := coalesce((c_loja->>'adicionalPreco')::numeric, 0);
      nome := nome || ' + cristais (' || coalesce(nullif(it->>'intencao',''),'intenção') || ')';
    end if;
    linhas := linhas || jsonb_build_array(jsonb_build_object('title',nome,'quantity',qtd,'unit_price',preco + adic,
              'ref',jsonb_build_object('tipo','loja','slug',prod.slug,'variante',v->>'id')));
  end loop;
  if jsonb_array_length(linhas) = 0 then return jsonb_build_object('erro','Nenhum item'); end if;

  -- cupom de primeira compra (campanha do pop-up): desconto em cada item, antes do frete
  if coalesce(p->>'cupom','') <> '' then
    cup := ara_aplicar_cupom(linhas, p->>'cupom');
    if cup ? 'erro' then return cup; end if;
    linhas := cup->'linhas';
  end if;

  select sum((l->>'unit_price')::numeric * (l->>'quantity')::int) into subtotal from jsonb_array_elements(linhas) l;
  cepd := regexp_replace(coalesce(p->>'cep',''), '\D', '', 'g');
  if coalesce((c_frete->>'ativo')::boolean, true) and length(cepd) = 8 then
    select r into reg from jsonb_array_elements(coalesce(c_frete->'regioes','[]'::jsonb)) r
      where cepd::bigint between regexp_replace(r->>'cepIni','\D','','g')::bigint and regexp_replace(r->>'cepFim','\D','','g')::bigint limit 1;
    if reg is not null then
      valor_frete := round((reg->>'valor')::numeric + coalesce((c_frete->>'acrescimo')::numeric,0) + subtotal * coalesce((c_frete->>'seguroPct')::numeric,0) / 100, 2);
      if coalesce((c_frete->>'gratisAcima')::numeric,0) > 0 and subtotal >= (c_frete->>'gratisAcima')::numeric then valor_frete := 0; end if;
      if p->>'entrega' = 'express' and coalesce((c_frete->'express'->>'ativo')::boolean,false) and coalesce((reg->>'express')::boolean,true) then
        valor_frete := round(coalesce((c_frete->'express'->>'valor')::numeric, 50), 2);
      end if;
    end if;
  end if;
  total := round(subtotal + coalesce(valor_frete,0), 2);

  insert into ara_pedidos(tipo,item,valor,nome,whatsapp,email,cep,dados,total,frete,itens,status,mp_status)
  values (case when p->>'tipo' = 'arca' then 'arca' else 'loja' end,
    left((select string_agg((l->>'quantity') || ' x ' || (l->>'title'), ' | ') from jsonb_array_elements(linhas) l), 400),
    'R$ ' || replace(to_char(total,'FM999999990.00'),'.',',') || case when valor_frete is null then ' + frete a combinar' else ' (com frete)' end,
    left(coalesce(p->>'nome',''),200), left(coalesce(p->>'whatsapp',''),40), left(coalesce(p->>'email',''),200), left(cepd,12),
    coalesce(p->'dados','{}'::jsonb) || jsonb_build_object('entrega', case when p->>'entrega' = 'express' and reg is not null and coalesce((reg->>'express')::boolean,true) and coalesce((c_frete->'express'->>'ativo')::boolean,false) then 'Motoboy Express' when reg is null then 'A combinar' else 'Coleta PEX' end)
      || jsonb_build_object('metodo', case when p->>'metodo' in ('pix','cartao') then p->>'metodo' else 'checkout' end)
      || case when cup ? 'cupom' then jsonb_build_object('cupom', cup->>'cupom', 'desconto_pct', (cup->>'pct')::int) else '{}'::jsonb end, total, valor_frete,
    (select jsonb_agg((l->'ref') || jsonb_build_object('qtd',l->'quantity','preco',l->'unit_price','titulo',l->'title')) from jsonb_array_elements(linhas) l),
    'aguardando pagamento', case when modo = 'teste' then 'teste' else '' end)
  returning id into pid;

  -- cartão no site: o pedido nasce aqui e a cobrança vem depois, em ara_pagar_cartao, com o token do formulário do Mercado Pago
  if p->>'metodo' = 'cartao' then
    return jsonb_build_object('pedido_id',pid,'modo',modo,'subtotal',subtotal,'frete',valor_frete,'total',total,'parcelas',parcelas);
  end if;

  perform extensions.http_set_curlopt('CURLOPT_TIMEOUT', '20');

  -- Pix direto: o Mercado Pago devolve o QR Code e o código "copia e cola" para mostrar no próprio site
  if p->>'metodo' = 'pix' then
    email_pagador := case when coalesce(p->>'email','') ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then p->>'email'
                          else 'cliente.' || left(pid::text, 8) || '@aracristais.com.br' end;
    pix := jsonb_build_object(
      'transaction_amount', total,
      'payment_method_id', 'pix',
      'description', left('ARA Cristais: ' || (select string_agg((l->>'quantity') || ' x ' || (l->>'title'), ', ') from jsonb_array_elements(linhas) l), 250),
      'external_reference', pid::text,
      'statement_descriptor', 'ARA CRISTAIS',
      'payer', jsonb_build_object('email', email_pagador, 'first_name', left(split_part(coalesce(p->>'nome',''), ' ', 1), 60)));
    select * into resp from extensions.http(('POST', 'https://api.mercadopago.com/v1/payments',
        array[extensions.http_header('Authorization','Bearer '||token), extensions.http_header('X-Idempotency-Key', pid::text)],
        'application/json', pix::text)::extensions.http_request);
    if resp.status < 200 or resp.status > 299 then
      update ara_pedidos set mp_status = 'erro ao criar o Pix' where id = pid;
      return jsonb_build_object('erro','Não foi possível gerar o Pix agora','pedido_id',pid,'status',resp.status);
    end if;
    mp := resp.content::jsonb;
    update ara_pedidos set mp_payment_id = mp->>'id', mp_status = mp->>'status' where id = pid;
    return jsonb_build_object('pedido_id',pid,'payment_id',mp->>'id','modo',modo,'subtotal',subtotal,'frete',valor_frete,'total',total,
      'pix_codigo', mp->'point_of_interaction'->'transaction_data'->>'qr_code',
      'pix_qr', mp->'point_of_interaction'->'transaction_data'->>'qr_code_base64',
      'pix_link', mp->'point_of_interaction'->'transaction_data'->>'ticket_url',
      'expira', mp->>'date_of_expiration');
  end if;

  pref := jsonb_build_object(
    'items', (select jsonb_agg(jsonb_build_object('title',left(l->>'title',250),'quantity',(l->>'quantity')::int,'unit_price',round((l->>'unit_price')::numeric,2),'currency_id','BRL')) from jsonb_array_elements(linhas) l),
    'external_reference', pid::text,
    'statement_descriptor', 'ARA CRISTAIS',
    'back_urls', jsonb_build_object('success', site||'/?pagamento=aprovado', 'pending', site||'/?pagamento=pendente', 'failure', site||'/?pagamento=falhou'),
    'auto_return', 'approved',
    'payment_methods', jsonb_build_object('installments', parcelas));
  if coalesce(valor_frete,0) > 0 then pref := pref || jsonb_build_object('shipments', jsonb_build_object('cost', valor_frete, 'mode', 'not_specified')); end if;
  if coalesce(p->>'email','') ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then pref := pref || jsonb_build_object('payer', jsonb_build_object('email', p->>'email')); end if;

  select * into resp from extensions.http(('POST', 'https://api.mercadopago.com/checkout/preferences',
      array[extensions.http_header('Authorization','Bearer '||token)], 'application/json', pref::text)::extensions.http_request);
  if resp.status < 200 or resp.status > 299 then
    update ara_pedidos set mp_status = 'erro ao criar pagamento' where id = pid;
    return jsonb_build_object('erro','O Mercado Pago recusou a criação do pagamento','pedido_id',pid,'status',resp.status);
  end if;
  mp := resp.content::jsonb;
  update ara_pedidos set mp_preference_id = mp->>'id' where id = pid;
  return jsonb_build_object('pedido_id',pid,'init_point',case when modo = 'teste' then mp->>'sandbox_init_point' else mp->>'init_point' end,
    'modo',modo,'subtotal',subtotal,'frete',valor_frete,'total',total,'regiao',reg->>'nome','prazo',reg->>'prazo');
end $function$;

CREATE OR REPLACE FUNCTION public.ara_pagar_cartao(p_pedido uuid, p_cartao jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare
  c_loja jsonb; c_arcas jsonb; c_pag jsonb; tok jsonb; modo text; token text; ped record; parcelas int; inst int;
  body jsonb; resp extensions.http_response; mp jsonb; st text; novo text; email_pagador text; ident jsonb;
begin
  select * into ped from ara_pedidos where id = p_pedido for update;
  if not found then return jsonb_build_object('erro','Pedido não encontrado'); end if;
  if ped.status = 'pago' or ped.mp_status = 'approved' then
    return jsonb_build_object('pedido_id',ped.id,'status','pago','mp','approved','total',ped.total); end if;
  if ped.mp_status in ('in_process','pending','authorized') and coalesce(ped.mp_payment_id,'') <> '' then
    return jsonb_build_object('pedido_id',ped.id,'status',ped.status,'mp',ped.mp_status,'total',ped.total); end if;
  if ped.status not in ('aguardando pagamento','pagamento recusado') or ped.total is null then
    return jsonb_build_object('erro','Este pedido não está aguardando pagamento'); end if;
  if coalesce(p_cartao->>'token','') = '' or coalesce(p_cartao->>'payment_method_id','') = '' then
    return jsonb_build_object('erro','Dados do cartão incompletos'); end if;

  select valor into c_loja from ara_config where chave = 'loja';
  select valor into c_arcas from ara_config where chave = 'arcas';
  select valor into c_pag from ara_config where chave = 'pagamento';
  select valor into tok from ara_privado where chave = 'mercadopago';
  modo := case when c_pag->>'modo' = 'teste' then 'teste' else 'producao' end;
  token := tok->>modo;
  if token is null then return jsonb_build_object('erro','Pagamento não configurado'); end if;

  parcelas := case when ped.tipo = 'arca' then coalesce((c_arcas->>'parcelasMax')::int, 10) else coalesce((c_loja->>'parcelasMax')::int, 6) end;
  inst := greatest(1, least(parcelas, coalesce(nullif(p_cartao->>'installments','')::int, 1)));
  email_pagador := coalesce(nullif(p_cartao->'payer'->>'email',''), nullif(ped.email,''), 'cliente.' || left(ped.id::text, 8) || '@aracristais.com.br');
  ident := p_cartao->'payer'->'identification';

  body := jsonb_build_object(
    'transaction_amount', ped.total,
    'token', p_cartao->>'token',
    'installments', inst,
    'payment_method_id', p_cartao->>'payment_method_id',
    'description', left('ARA Cristais: ' || coalesce(ped.item,''), 250),
    'external_reference', ped.id::text,
    'statement_descriptor', 'ARA CRISTAIS',
    'payer', jsonb_build_object('email', email_pagador)
       || case when ident is not null and coalesce(ident->>'number','') <> '' then jsonb_build_object('identification', ident) else '{}'::jsonb end);
  if coalesce(p_cartao->>'issuer_id','') <> '' then body := body || jsonb_build_object('issuer_id', p_cartao->>'issuer_id'); end if;

  perform extensions.http_set_curlopt('CURLOPT_TIMEOUT', '30');
  select * into resp from extensions.http(('POST', 'https://api.mercadopago.com/v1/payments',
      array[extensions.http_header('Authorization','Bearer '||token), extensions.http_header('X-Idempotency-Key', gen_random_uuid()::text)],
      'application/json', body::text)::extensions.http_request);
  begin mp := resp.content::jsonb; exception when others then mp := '{}'::jsonb; end;
  if resp.status < 200 or resp.status > 299 or mp->>'id' is null then
    update ara_pedidos set mp_status = 'erro no cartão' where id = ped.id;
    return jsonb_build_object('erro','O pagamento não foi aceito. Confira os dados do cartão ou pague com Pix.','pedido_id',ped.id,'status_http',resp.status,'detalhe',mp->>'message');
  end if;

  st := mp->>'status';
  novo := case when st = 'approved' then 'pago'
               when st in ('pending','in_process','authorized') then 'aguardando pagamento'
               when st in ('rejected','cancelled') then 'pagamento recusado' else ped.status end;
  update ara_pedidos set mp_payment_id = mp->>'id', mp_status = st, status = novo,
     dados = coalesce(dados,'{}'::jsonb) || jsonb_build_object('parcelas', inst, 'cartao', coalesce(mp->'payment_method_id', to_jsonb(p_cartao->>'payment_method_id'))),
     pago_em = case when st = 'approved' then coalesce(pago_em, now()) else pago_em end
   where id = ped.id;
  if st = 'approved' then perform ara_baixar_estoque(ped.id); end if;
  return jsonb_build_object('pedido_id',ped.id,'payment_id',mp->>'id','status',novo,'mp',st,'detalhe',mp->>'status_detail','total',ped.total,'parcelas',inst);
end $function$;

-- Quando o cliente troca a forma de pagamento (ex.: abriu o cartão e foi para o Pix), o pedido anterior,
-- ainda sem pagamento, é cancelado para não aparecer em dobro na retaguarda.
-- Se mesmo assim ele for pago depois, ara_confirmar_pagamento volta o status para "pago".
CREATE OR REPLACE FUNCTION public.ara_cancelar_aberto(p_pedido uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  update ara_pedidos set status = 'cancelado',
     dados = coalesce(dados,'{}'::jsonb) || jsonb_build_object('cancelado', 'o cliente trocou a forma de pagamento')
   where id = p_pedido and status = 'aguardando pagamento' and pago_em is null
     and coalesce(mp_status,'') not in ('approved','in_process','authorized');
  return jsonb_build_object('ok', found);
end $function$;
