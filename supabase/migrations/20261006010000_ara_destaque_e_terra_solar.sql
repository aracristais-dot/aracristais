-- "Mais desejadas" da página inicial: o dono marca no painel com um clique.
alter table public.ara_produtos add column if not exists destaque boolean not null default false;
grant select (destaque) on public.ara_produtos to anon, authenticated;

-- Ara Terra Solar: peça única (estoque 1), selos, ficha e textos do Google que ficaram vazios no cadastro.
update public.ara_produtos set
  tag = 'Peça única · Exclusivo',
  estoque = 1,
  destaque = true,
  frase = 'Aragonita rajada e pirita natural numa composição montada à mão. Peça única.',
  texto = regexp_replace(texto, 'A composição\s+A composição cria', 'A composição cria'),
  detalhes = '[{"k":"Pedras","v":"Aragonita (calcita) rajada e pirita natural"},{"k":"Significado","v":"Estabilidade e prosperidade"},{"k":"Medidas","v":"Aprox. 10 × 10 × 10 cm"}]'::jsonb,
  uso = 'Para a mesa de trabalho, a estante ou o altar: a aragonita traz estrutura e a pirita, a ideia de prosperidade.',
  cuidados = 'Limpe só com pincel macio ou pano seco. Evite água e umidade: a pirita oxida e perde o brilho.',
  seo_titulo = 'ARA Terra Solar · aragonita e pirita | Loja ARA',
  seo_descricao = 'Composição mineral de aragonita rajada e pirita natural, montada à mão: estabilidade e prosperidade. Peça única, 10 cm. Envio para todo o Brasil.',
  atualizado_em = now()
where slug = 'ara-terra-solar';

-- primeiras "mais desejadas"; o dono troca pelo painel
update public.ara_produtos set destaque = true where slug in ('drusa-de-ametista', 'pirita-bruta', 'agata-in-natura');
