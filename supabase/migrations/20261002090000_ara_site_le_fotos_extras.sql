-- O site lê ara_produtos com permissão por coluna (custo e custos ficam escondidos).
-- A coluna fotos (Foto 2 e Foto 3) nasceu sem essa permissão: a consulta do site falhava inteira
-- e ele caía na lista de reserva, com as fotos antigas. Toda coluna nova que o site lê precisa entrar aqui.
grant select (fotos) on public.ara_produtos to anon, authenticated;
