-- SEO de decoração: início, categoria de acessórios, peças decorativas e o artigo da Arca (sem chamado a arquitetos).
update public.ara_config set valor = valor
  || jsonb_build_object('titulo', 'ARA · Arca de cristais e objetos de decoração exclusivos',
                        'descricao', 'Caixa decorativa de cristais naturais, montada à mão com o seu nome e data de nascimento, e objetos de decoração exclusivos para sala, quarto e escritório.')
where chave = 'seo';

update public.ara_config set valor = (
  select jsonb_agg(case when c->>'id' = 'acessorio'
    then c || jsonb_build_object('nome', 'Decoração e acessórios',
      'intro', 'Objetos de decoração escolhidos pela ARA para a sala, o quarto, o escritório e o altar: peças de vidro, mármore, madeira e pedra que trazem luz e textura para o ambiente.')
    else c end order by o)
  from jsonb_array_elements(valor) with ordinality as t(c, o))
where chave = 'categorias';

update public.ara_produtos set seo_titulo = 'Prisma Âmbar: objeto de decoração em vidro facetado | ARA',
  seo_descricao = 'Objeto de decoração em vidro âmbar lapidado em facetas, que espalha reflexos dourados pela sala, aparador ou escritório. Peça única na loja ARA.', atualizado_em = now()
  where slug = 'prisma-ambar';
update public.ara_produtos set seo_titulo = 'Bandeja de mármore decorativa com cristais brutos | ARA',
  seo_descricao = 'Bandeja decorativa de mármore natural com três cristais brutos brasileiros, para a mesa de centro, o aparador ou a cabeceira. Peça única na loja ARA.', atualizado_em = now()
  where slug = 'bandeja-ritual';
update public.ara_produtos set seo_titulo = 'Escultura mineral decorativa de aragonita e pirita | ARA',
  seo_descricao = 'Escultura mineral decorativa de aragonita rajada e pirita natural, montada à mão, para estante, aparador ou escritório. Peça única, 10 cm. Loja ARA.', atualizado_em = now()
  where slug = 'ara-terra-solar';
update public.ara_produtos set seo_titulo = 'Ágata marrom com base: pedra decorativa natural | ARA',
  seo_descricao = 'Chapa de ágata natural em tons de marrom, com base, para decorar a estante ou a mesa de trabalho. A pedra do equilíbrio. Peça única. Loja ARA.', atualizado_em = now()
  where slug = 'agata-marrom-com-base';
update public.ara_produtos set seo_titulo = 'Caixa Guardiã: caixa decorativa de madeira e vidro | ARA',
  seo_descricao = 'Caixa decorativa de madeira com tampa de vidro para guardar e exibir cristais, joias e lembranças na sala ou no quarto. Peça selecionada pela ARA.', atualizado_em = now()
  where slug = 'caixa-guardia';
update public.ara_produtos set seo_titulo = 'Caixa Relicário: caixa decorativa de madeira e vidro para cristais | ARA', atualizado_em = now()
  where slug = 'caixa-relicario';

update public.ara_posts set
  conteudo = regexp_replace(conteudo, '<h2 id="profissionais">.*$',
'<h2>Uma peça de decoração pronta para o ambiente</h2>
<p>A Arca chega pronta para entrar na decoração: montada à mão, embalada com cuidado e com envio para todo o Brasil. Também é um presente marcante para quem acabou de mudar de casa ou inaugurar um escritório.</p>
<p><a href="/arca#colecao">Escolha a sua Arca</a> ou <a href="https://wa.me/5511973371416?text=Ol%C3%A1!%20Quero%20saber%20mais%20sobre%20a%20Arca." target="_blank" rel="noopener">fale com a ARA pelo WhatsApp</a>.</p>'),
  subtitulo = 'Ideias de decoração com cristais naturais para a sala, o quarto e o escritório.',
  seo_descricao = 'Como usar cristais naturais na decoração: a Arca da ARA na mesa de centro, no aparador, no quarto e no escritório. Ideias de design de interiores.',
  atualizado_em = now()
where slug = 'arca-de-cristais-na-decoracao';
