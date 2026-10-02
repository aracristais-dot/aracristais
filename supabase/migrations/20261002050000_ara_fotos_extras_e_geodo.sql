-- Até três fotos por produto: a principal continua em foto_url; as outras (ângulos diferentes) ficam em fotos.
alter table public.ara_produtos add column if not exists fotos jsonb not null default '[]'::jsonb;

-- Geodo Marroquino e Geodo Branco eram a mesma peça: fica um produto só, com a foto de fora e a de dentro.
update public.ara_produtos set
  fotos = '["/img/loja/geodo-branco.54022ac1.jpg"]'::jsonb,
  frase = 'Rústico por fora, forrado de cristais brancos por dentro.',
  texto = E'O geodo é uma pedra oca: por fora, uma casca rústica; por dentro, uma cavidade forrada de pequenos cristais brancos que se formaram ao longo de milhões de anos. Este vem do Marrocos.\n\nNa tradição dos cristais, o geodo é símbolo do que guardamos de mais bonito por dentro.',
  detalhes = '[{"k": "Pedra", "v": "Geodo natural, com cristais de quartzo branco por dentro"}, {"k": "Origem", "v": "Marrocos"}, {"k": "Observação", "v": "Peça natural: as fotos são da própria pedra que você vai receber."}]'::jsonb,
  seo_descricao = 'Geodo natural do Marrocos, rústico por fora e forrado de cristais brancos por dentro. Peça única. Loja ARA.',
  atualizado_em = now()
where slug = 'geodo-marroquino';
update public.ara_produtos set ativo = false, disponivel = false, estoque = 0, atualizado_em = now() where slug = 'geodo-branco';
