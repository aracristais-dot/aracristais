-- Artigo da Arca: sem foto repetida no topo e sem "brasileiros" (a ARA trabalha com cristais do Brasil e de fora).
update public.ara_posts set
  conteudo = replace(conteudo, 'um mosaico de cristais naturais brasileiros montado à mão', 'um mosaico de cristais naturais montado à mão'),
  foto_url = '', atualizado_em = now()
where slug = 'arca-de-cristais-na-decoracao';
