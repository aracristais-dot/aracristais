-- Eventos do carrinho no painel de visitas.
-- O site manda os eventos em lote (um POST com várias linhas). A regra de inserção só aceitava uma lista
-- fixa de nomes, e 'carrinho', 'leve_junto' e 'checkout_inicio' (criados depois) ficaram de fora: o banco
-- recusava o lote inteiro, inclusive a visita ao produto que ia junto. Desde 02/10 nenhum carrinho foi registrado.
-- Agora vale qualquer nome curto em minúsculas, para um evento novo não voltar a derrubar o lote.
drop policy if exists ara_visitas_criar on public.ara_visitas;
create policy ara_visitas_criar on public.ara_visitas for insert to anon, authenticated
with check ((char_length(COALESCE(pagina, ''::text)) <= 200) AND (char_length(COALESCE(termo, ''::text)) <= 120) AND (char_length(COALESCE(sessao, ''::text)) <= 60) AND (char_length(COALESCE(origem, ''::text)) <= 120)
  AND (evento ~ '^[a-z_]{1,30}$'));
