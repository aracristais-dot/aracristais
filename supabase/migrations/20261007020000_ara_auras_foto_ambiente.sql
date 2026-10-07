-- Auras: foto de ambiente como segunda foto (a primeira continua em fundo branco).
update public.ara_produtos set fotos = '["/img/loja/aura-da-prosperidade-ambiente.e6e12819.jpg"]'::jsonb, atualizado_em = now() where slug = 'aura-da-prosperidade';
update public.ara_produtos set fotos = '["/img/loja/aura-da-calma-ambiente.b011d9a2.jpg"]'::jsonb, atualizado_em = now() where slug = 'aura-da-calma';
update public.ara_produtos set fotos = '["/img/loja/aura-da-clareza-ambiente.ac008047.jpg"]'::jsonb, atualizado_em = now() where slug = 'aura-da-clareza';
update public.ara_produtos set fotos = '["/img/loja/aura-do-equilibrio-ambiente.16308adb.jpg", "/img/loja/aura-do-equilibrio-2.b4e1aac0.jpg"]'::jsonb, atualizado_em = now() where slug = 'aura-do-equilibrio';
update public.ara_produtos set fotos = '["/img/loja/aura-da-limpeza-ambiente.467a651a.jpg", "/img/loja/aura-da-limpeza-placa.e7d54139.jpg"]'::jsonb, atualizado_em = now() where slug = 'aura-da-limpeza';
