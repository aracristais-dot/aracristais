-- A Arca é o carro-chefe: título e descrição da página inicial falam dela
-- (o site agora usa estes textos também na versão que o Google lê).
update public.ara_config
   set valor = valor
       || jsonb_build_object('titulo', 'ARA · Arca de cristais personalizada e cristais naturais')
       || jsonb_build_object('descricao', 'A Arca ARA é um mosaico de cristais naturais numa caixa de madeira e vidro, criado à mão a partir do seu nome e data de nascimento. Peça única, presente autoral.')
 where chave = 'seo';
