-- Colares de vidro: frase, descrição e textos do Google reescritos (estavam soltos).
update public.ara_produtos set
  frase = 'Vidro e um pingente de olho, o amuleto da proteção, para usar todo dia.',
  texto = E'Colar de vidro com pingente de olho, o amuleto que, em muitas tradições, protege contra o olhar invejoso.\n\nUma peça exclusiva da ARA para usar no dia a dia ou para dar de presente.',
  seo_titulo = 'Colar de vidro com pingente de olho | Loja ARA',
  seo_descricao = 'Colar de vidro com pingente de olho, o amuleto da proteção. Peça exclusiva da ARA para usar todo dia ou presentear. Envio para todo o Brasil.',
  atualizado_em = now()
where slug = 'colar-de-vidro-com-pingente';

update public.ara_produtos set
  frase = 'Vidro e corrente, leve e delicado, para usar todo dia.',
  texto = E'Colar de vidro com corrente, leve e delicado. Combina com o dia a dia e com as suas outras peças.\n\nUma peça exclusiva da ARA para usar ou para dar de presente.',
  seo_titulo = 'Colar de vidro com corrente | Loja ARA',
  seo_descricao = 'Colar de vidro com corrente, leve e delicado. Peça exclusiva da ARA para usar todo dia ou presentear. Envio para todo o Brasil.',
  atualizado_em = now()
where slug = 'colar-de-vidro-corrente';
