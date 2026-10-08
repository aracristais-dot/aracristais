-- Loja: Auras, Esculturas e cristais, Caixas, Decoração e acessórios, Incensos (nessa ordem).
update public.ara_config set valor = (
  select jsonb_agg(c order by o) from (
    select case when c->>'id' = 'cristal' then c || jsonb_build_object('nome', 'Esculturas e cristais',
             'intro', 'Esculturas minerais e cristais naturais escolhidos à mão, um a um: peças únicas para a estante, o aparador ou a mesa de trabalho. [Conheça a história dos cristais](/historia#linha-do-tempo).')
           else c end c,
           case c->>'id' when 'aura' then 1 when 'cristal' then 2 when 'acessorio' then 4 when 'incenso' then 5 else 6 end o
    from jsonb_array_elements(valor) c
    union all
    select jsonb_build_object('id', 'caixa', 'nome', 'Caixas',
             'intro', 'Caixas de madeira e vidro para guardar e expor cristais, joias e lembranças. Para uma caixa já montada com os seus cristais, a partir do seu nome e da sua data de nascimento, [conheça a Arca](/arca#colecao).'), 3
    where not exists (select 1 from jsonb_array_elements(valor) x where x->>'id' = 'caixa')
  ) t)
where chave = 'categorias';

update public.ara_produtos set categoria = 'cristal', atualizado_em = now() where slug = 'prisma-ambar';
update public.ara_produtos set categoria = 'caixa', atualizado_em = now() where slug in ('caixa-guardia', 'caixa-relicario', 'estojo-travessia');
