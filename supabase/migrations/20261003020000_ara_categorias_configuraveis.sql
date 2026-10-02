-- Categorias da loja configuráveis pela retaguarda: nome, ordem na loja e texto de abertura.
-- Ficam em ara_config (chave 'categorias'), na ordem em que aparecem no site.
-- O produto guarda só o código da categoria (cristal, acessorio, incenso...), então categoria nova
-- não precisa mais de mudança no banco: a trava passa a aceitar qualquer código simples.
alter table public.ara_produtos drop constraint if exists ara_produtos_categoria_chk;
alter table public.ara_produtos add constraint ara_produtos_categoria_chk check (categoria ~ '^[a-z0-9-]{1,40}$');

insert into public.ara_config (chave, valor)
values ('categorias', '[
  {"id": "cristal", "nome": "Cristais", "intro": "Os cristais se formam ao longo de milhões de anos e acompanham a humanidade desde os sumérios. [Conheça essa história](/historia#linha-do-tempo), que também dá nome às peças da ARA."},
  {"id": "acessorio", "nome": "Acessórios e complementos", "intro": ""},
  {"id": "incenso", "nome": "Incensos", "intro": "Incensos indianos para perfumar a casa e marcar o início da meditação. Cada aroma é um produto: escolha os seus e adicione ao carrinho."}
]'::jsonb)
on conflict (chave) do nothing;
