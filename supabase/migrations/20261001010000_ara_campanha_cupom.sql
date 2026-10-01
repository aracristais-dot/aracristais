-- Campanha "10% na primeira compra": 5% ao se cadastrar + 5% informando o @ do Instagram.
-- Cadastros (CRM) em ara_leads; cupom aplicado no pagamento; marcado como usado quando o pedido é pago.

create table if not exists public.ara_leads (
  id uuid primary key default gen_random_uuid(),
  criado_em timestamptz not null default now(),
  atualizado_em timestamptz not null default now(),
  nome text not null default '',
  whatsapp text not null default '',
  whatsapp_digitos text not null unique,
  instagram text not null default '',
  aceita_novidades boolean not null default false,
  cupom text not null unique,
  pct int not null,
  seguiu_verificado boolean,
  status text not null default 'ativo' check (status in ('ativo','usado','cancelado')),
  usado_em timestamptz,
  pedido_id uuid,
  origem text not null default '',
  pagina text not null default '',
  obs text not null default ''
);
alter table public.ara_leads enable row level security;
drop policy if exists ara_leads_admin on public.ara_leads;
create policy ara_leads_admin on public.ara_leads for all to authenticated using (ara_is_admin()) with check (ara_is_admin());
revoke all on public.ara_leads from anon;

insert into public.ara_config(chave, valor)
select 'campanha', '{"ativa": true, "base": 5, "instagram": 5, "perfil": "ara.cristais"}'::jsonb
where not exists (select 1 from public.ara_config where chave = 'campanha');

-- código de cupom legível (sem 0/O, 1/I)
create or replace function public.ara_codigo_cupom() returns text
 language sql volatile set search_path to 'public'
as $$ select 'ARA-' || string_agg(substr('ABCDEFGHJKLMNPQRSTUVWXYZ23456789', 1 + floor(random() * 32)::int, 1), '') from generate_series(1, 6) $$;

-- cadastro do pop-up: devolve o cupom (o mesmo, se o WhatsApp já estiver cadastrado)
create or replace function public.ara_registrar_lead(p jsonb) returns jsonb
 language plpgsql security definer set search_path to 'public'
as $$
declare c jsonb; wz text; ig text; nm text; base int; extra int; l ara_leads; tent int := 0;
begin
  select valor into c from ara_config where chave = 'campanha';
  if c is null or not coalesce((c->>'ativa')::boolean, false) then return jsonb_build_object('erro', 'Campanha encerrada'); end if;
  base := coalesce((c->>'base')::int, 5); extra := coalesce((c->>'instagram')::int, 5);
  wz := regexp_replace(coalesce(p->>'whatsapp', ''), '\D', '', 'g');
  if length(wz) between 10 and 11 then wz := '55' || wz; end if;
  if length(wz) not between 12 and 13 then return jsonb_build_object('erro', 'Escreva um WhatsApp com DDD.'); end if;
  ig := lower(btrim(coalesce(p->>'instagram', '')));
  ig := regexp_replace(ig, '^.*instagram\.com/', '');
  ig := regexp_replace(ig, '[/?#].*$', '');
  ig := left(regexp_replace(regexp_replace(ig, '^@+', ''), '[^a-z0-9._]', '', 'g'), 30);
  nm := left(btrim(coalesce(p->>'nome', '')), 120);
  select * into l from ara_leads where whatsapp_digitos = wz;
  if found then
    if l.status = 'ativo' and ig <> '' and l.instagram = '' then
      update ara_leads set instagram = ig, pct = greatest(pct, base + extra), atualizado_em = now(),
        nome = case when nome = '' then nm else nome end where id = l.id returning * into l;
    end if;
    return jsonb_build_object('cupom', l.cupom, 'pct', l.pct, 'status', l.status, 'instagram', l.instagram <> '', 'novo', false);
  end if;
  loop
    begin
      insert into ara_leads(nome, whatsapp, whatsapp_digitos, instagram, aceita_novidades, cupom, pct, origem, pagina)
      values (nm, left(coalesce(p->>'whatsapp', ''), 40), wz, ig, coalesce((p->>'novidades')::boolean, false), ara_codigo_cupom(),
              base + case when ig <> '' then extra else 0 end, left(coalesce(p->>'origem', ''), 60), left(coalesce(p->>'pagina', ''), 200))
      returning * into l;
      exit;
    exception when unique_violation then
      select * into l from ara_leads where whatsapp_digitos = wz;
      if found then return jsonb_build_object('cupom', l.cupom, 'pct', l.pct, 'status', l.status, 'instagram', l.instagram <> '', 'novo', false); end if;
      tent := tent + 1;
      if tent > 5 then raise; end if;
    end;
  end loop;
  return jsonb_build_object('cupom', l.cupom, 'pct', l.pct, 'status', l.status, 'instagram', l.instagram <> '', 'novo', true);
end $$;

-- o site confere se o cupom guardado ainda vale
create or replace function public.ara_validar_cupom(p_cupom text) returns jsonb
 language plpgsql stable security definer set search_path to 'public'
as $$
declare l ara_leads;
begin
  select * into l from ara_leads where replace(cupom, '-', '') = upper(regexp_replace(coalesce(p_cupom, ''), '[^A-Za-z0-9]', '', 'g'));
  if not found then return jsonb_build_object('ok', false, 'erro', 'Cupom não encontrado'); end if;
  if l.status <> 'ativo' then return jsonb_build_object('ok', false, 'erro', 'Este cupom já foi utilizado'); end if;
  return jsonb_build_object('ok', true, 'cupom', l.cupom, 'pct', l.pct);
end $$;

-- desconto do cupom em cada linha do pagamento (usada só pela ara_criar_pagamento)
create or replace function public.ara_aplicar_cupom(linhas jsonb, codigo text) returns jsonb
 language plpgsql security definer set search_path to 'public'
as $$
declare l ara_leads; novas jsonb;
begin
  select * into l from ara_leads where replace(cupom, '-', '') = upper(regexp_replace(coalesce(codigo, ''), '[^A-Za-z0-9]', '', 'g'));
  if not found then return jsonb_build_object('erro', 'Cupom não encontrado'); end if;
  if l.status <> 'ativo' then return jsonb_build_object('erro', 'Este cupom já foi utilizado'); end if;
  select jsonb_agg(e || jsonb_build_object('unit_price', round((e->>'unit_price')::numeric * (100 - l.pct) / 100, 2)) order by o) into novas
    from jsonb_array_elements(linhas) with ordinality t(e, o);
  return jsonb_build_object('linhas', novas, 'cupom', l.cupom, 'pct', l.pct);
end $$;

revoke execute on function public.ara_aplicar_cupom(jsonb, text) from public, anon, authenticated;
revoke execute on function public.ara_codigo_cupom() from public, anon, authenticated;
grant execute on function public.ara_registrar_lead(jsonb) to anon, authenticated;
grant execute on function public.ara_validar_cupom(text) to anon, authenticated;

-- pedido pago (pelo Mercado Pago ou marcado na retaguarda): o cupom deixa de valer
create or replace function public.ara_cupom_usado() returns trigger
 language plpgsql security definer set search_path to 'public'
as $$
begin
  if new.status in ('pago', 'enviado', 'concluído') and coalesce(old.status, '') not in ('pago', 'enviado', 'concluído')
     and coalesce(new.dados->>'cupom', '') <> '' then
    update ara_leads set status = 'usado', usado_em = now(), pedido_id = new.id, atualizado_em = now()
     where replace(cupom, '-', '') = upper(regexp_replace(new.dados->>'cupom', '[^A-Za-z0-9]', '', 'g')) and status = 'ativo';
  end if;
  return new;
end $$;
drop trigger if exists ara_pedidos_cupom on public.ara_pedidos;
create trigger ara_pedidos_cupom after update of status on public.ara_pedidos for each row execute function public.ara_cupom_usado();

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
    coalesce(p->'dados','{}'::jsonb) || jsonb_build_object('entrega', case when p->>'entrega' = 'express' and reg is not null and coalesce((reg->>'express')::boolean,true) and coalesce((c_frete->'express'->>'ativo')::boolean,false) then 'Motoboy Express' when reg is null then 'A combinar' else 'Coleta PEX' end) || case when cup ? 'cupom' then jsonb_build_object('cupom', cup->>'cupom', 'desconto_pct', (cup->>'pct')::int) else '{}'::jsonb end, total, valor_frete,
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

-- a função do gatilho não precisa ser chamável pela API
revoke execute on function public.ara_cupom_usado() from public, anon, authenticated;

-- cliques no WhatsApp/Instagram e cadastros do cupom entram no painel de visitas
drop policy if exists ara_visitas_criar on public.ara_visitas;
create policy ara_visitas_criar on public.ara_visitas for insert to anon, authenticated
with check ((char_length(COALESCE(pagina, ''::text)) <= 200) AND (char_length(COALESCE(termo, ''::text)) <= 120) AND (char_length(COALESCE(sessao, ''::text)) <= 60) AND (char_length(COALESCE(origem, ''::text)) <= 120)
  AND (evento = ANY (ARRAY['visita'::text, 'pagina'::text, 'produto'::text, 'busca'::text, 'checkout'::text, 'whatsapp'::text, 'instagram'::text, 'cupom'::text])));
