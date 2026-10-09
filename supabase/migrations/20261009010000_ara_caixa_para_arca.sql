-- A Arca não é chamada de "caixa": textos do blog, SEO e categoria.
update public.ara_posts set
  conteudo = replace(replace(replace(replace(replace(replace(conteudo,
    'dentro de uma caixa de madeira e vidro', 'em madeira e vidro'),
    'a caixa tem tampa de vidro que abre', 'a Arca tem tampa de vidro que abre'),
    'uma caixa com mosaico de cristais, como a ', 'uma obra com mosaico de cristais, como a '),
    'É uma caixa de madeira e vidro com um mosaico', 'É uma peça de madeira e vidro com um mosaico'),
    'a madeira da caixa aquece o conjunto', 'a madeira da Arca aquece o conjunto'),
    'com caixa feita sob encomenda por um marceneiro artesão', 'com estrutura feita sob encomenda por um marceneiro artesão'),
  resumo = replace(resumo, 'como usar a Arca, a caixa de cristais da ARA, na decoração', 'como usar a Arca, a obra de cristais da ARA, na decoração'),
  atualizado_em = now()
where conteudo ~* 'caixa' or resumo ~* 'caixa';

update public.ara_config set valor = jsonb_set(valor, '{descricao}', to_jsonb(replace(valor->>'descricao', 'Caixa decorativa de cristais naturais, montada à mão', 'Arca de cristais naturais, montada à mão')))
where chave = 'seo';

update public.ara_config set valor = replace(valor::text,
  'Para uma caixa já montada com os seus cristais, a partir do seu nome e da sua data de nascimento,',
  'Para os seus cristais já montados em uma obra única, a partir do seu nome e da sua data de nascimento,')::jsonb
where chave = 'categorias';
