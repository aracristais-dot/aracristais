-- "Complete o seu santuário": o pedido da Arca pode levar acessórios da loja no mesmo pagamento.
-- Única mudança em relação à versão anterior: os itens da loja (p->'itens') agora são processados
-- também quando tipo = 'arca' (antes eram ignorados). Preço e estoque continuam vindo do banco,
-- e a baixa de estoque na aprovação (ara_baixar_estoque) já trata itens do tipo 'loja'.
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
  resp extensions.http_response; mp jsonb; parcelas int; site text := 'https://aracristais.com.br';
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
    coalesce(p->'dados','{}'::jsonb) || jsonb_build_object('entrega', case when p->>'entrega' = 'express' and reg is not null and coalesce((reg->>'express')::boolean,true) and coalesce((c_frete->'express'->>'ativo')::boolean,false) then 'Motoboy Express' when reg is null then 'A combinar' else 'Coleta PEX' end), total, valor_frete,
    (select jsonb_agg((l->'ref') || jsonb_build_object('qtd',l->'quantity','preco',l->'unit_price','titulo',l->'title')) from jsonb_array_elements(linhas) l),
    'aguardando pagamento', case when modo = 'teste' then 'teste' else '' end)
  returning id into pid;

  pref := jsonb_build_object(
    'items', (select jsonb_agg(jsonb_build_object('title',left(l->>'title',250),'quantity',(l->>'quantity')::int,'unit_price',round((l->>'unit_price')::numeric,2),'currency_id','BRL')) from jsonb_array_elements(linhas) l),
    'external_reference', pid::text,
    'statement_descriptor', 'ARA CRISTAIS',
    'back_urls', jsonb_build_object('success', site||'/?pagamento=aprovado', 'pending', site||'/?pagamento=pendente', 'failure', site||'/?pagamento=falhou'),
    'auto_return', 'approved',
    'payment_methods', jsonb_build_object('installments', parcelas));
  if coalesce(valor_frete,0) > 0 then pref := pref || jsonb_build_object('shipments', jsonb_build_object('cost', valor_frete, 'mode', 'not_specified')); end if;
  if coalesce(p->>'email','') ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then pref := pref || jsonb_build_object('payer', jsonb_build_object('email', p->>'email')); end if;

  perform extensions.http_set_curlopt('CURLOPT_TIMEOUT', '20');
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
