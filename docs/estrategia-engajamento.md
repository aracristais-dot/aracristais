# Estratégia de engajamento da ARA

Feita em 16/10/2026 com os dados reais do site (`ara_visitas`, `ara_leads`, `ara_pedidos`) de 30/09 a 16/10.
Conferir toda segunda-feira com a consulta do fim deste arquivo e anotar na tabela "Placar".

## 1. Linha de base (30/09 a 16/10)

Sessões fora do Brasil (robôs de busca e da Vercel, a maioria nos EUA) ficam de fora.

| Indicador | Valor |
|---|---|
| Sessões | 160 (61% no celular) |
| Viram pelo menos um produto | 56 (35%) |
| Leram o blog | 10 |
| Vieram do Instagram | 6 |
| Vieram do Google | 6 |
| Clicaram no WhatsApp | 2 |
| Clicaram no Instagram | 3 |
| Cadastros do cupom 10% | **0** |
| Pedidos pagos | **0** (1 pedido de R$ 43,35, cartão recusado em 02/10) |

O que mais chamou atenção (páginas de produto mais vistas): Aura da Limpeza, Aura da Calma, Aura do Equilíbrio, Aura da Clareza, ARA Terra Solar.
Horário de pico do site: **21h às 0h** (horário de São Paulo).

## 2. O que estava quebrado (corrigido em 16/10)

O site manda os eventos em lote. A regra do banco só aceitava uma lista fixa de nomes de evento, e `carrinho`, `leve_junto` e `checkout_inicio` (criados em 02/10) ficaram de fora. Resultado: **toda vez que alguém punha uma peça no carrinho, o banco recusava o lote inteiro**, inclusive a visita ao produto que ia junto. Desde 02/10 não existe nenhum carrinho registrado, e as visitas a produto estão subcontadas.

Corrigido em `supabase/migrations/20261016010000_ara_visitas_eventos_do_carrinho.sql`. Teste feito como visitante anônimo: os quatro eventos (produto, carrinho, leve junto, início do checkout) entram; nome de evento fora do padrão continua bloqueado.

A partir de agora o funil completo fica visível: visita → produto → carrinho → checkout → pago.

## 3. Diagnóstico

1. **Tráfego é pouco e quase todo "direto".** Instagram e Google trouxeram 12 sessões em 16 dias. O site não tem problema de interesse (35% chegam a um produto); o gargalo é gente chegando.
2. **O pop-up de 10% não converte: 0 cadastros em 160 sessões.** Ele abre aos 7 segundos, antes de a pessoa ver qualquer peça, e pede nome, WhatsApp e Instagram.
3. **As Auras são o que atrai.** As cinco páginas de produto mais vistas são Auras ou composições.
4. **O único pedido morreu no cartão recusado** e ninguém retomou o contato.

## 4. Plano (em ordem de prioridade)

### A. Medir (feito)
- Funil completo registrado a partir de 16/10.
- Todo link que a ARA publicar leva `?utm_source=`: `instagram_bio`, `instagram_story`, `whatsapp_lista`, `google_perfil`. O site já lê esse campo e ele aparece como origem no painel.

### B. Pop-up que capta contato
- Abrir **depois que a pessoa viu um produto** (ou ao tentar sair da página), não aos 7 segundos.
- Pedir **só o WhatsApp** no primeiro passo. O @ do Instagram fica para o segundo passo (os +5%), como já existe.
- Meta: 3% das sessões viram cadastro.

### C. Instagram como motor de tráfego
- 3 posts por semana + stories diários, publicados **entre 20h e 21h** (antes do pico do site).
- Conteúdo puxado pelas Auras: montagem da Aura na bandeja, a intenção de cada uma, a Aura no ambiente (quarto, sala, escritório).
- Todo domingo, o post do blog vira story com link (`?utm_source=instagram_story`).
- Meta: 30 sessões por semana vindas do Instagram.

### D. WhatsApp: lista de transmissão
- Quem se cadastra com "aceita novidades" entra numa lista de transmissão.
- 1 mensagem por semana, no máximo: peça nova ou post de domingo, sempre com link marcado (`?utm_source=whatsapp_lista`).

### E. Recuperar compra perdida
- Pedido com pagamento recusado ou carrinho abandonado (agora visível): chamar no WhatsApp em até 1 hora oferecendo Pix.

### F. Blog e Google
- Manter o post de domingo (`docs/blog-calendario.md`). O próximo é Pirita, em 18/10.
- Conectar o Google Ads e o Instagram à ferramenta de relatório (Supermetrics) para conferir custo por clique e alcance junto com estes números.

## 5. Placar semanal

| Semana | Sessões | Viram produto | Carrinho | Checkout | Cadastros | Vindas do IG | Pedidos pagos |
|---|---|---|---|---|---|---|---|
| 30/09 a 16/10 (base) | 160 | 56 | (não medido) | (não medido) | 0 | 6 | 0 |
| 19/10 a 25/10 | | | | | | | |

## 6. Consulta para conferir o resultado

Rode no Supabase (SQL Editor) toda segunda-feira. Mostra os últimos 7 dias, sem as sessões de fora do Brasil.

```sql
with s as (
  select sessao,
         max(pais) pais,
         bool_or(evento = 'produto') produto,
         bool_or(evento = 'carrinho') carrinho,
         bool_or(evento in ('checkout_inicio', 'checkout')) checkout,
         bool_or(evento = 'cupom') cupom,
         bool_or(evento = 'whatsapp') whatsapp,
         max(origem) filter (where origem not in ('interno', '', 'direto')) origem
  from ara_visitas
  where ts >= now() - interval '7 days'
  group by sessao
)
select count(*) sessoes,
       sum(produto::int) viram_produto,
       sum(carrinho::int) carrinho,
       sum(checkout::int) checkout,
       sum(cupom::int) cadastros,
       sum(whatsapp::int) whatsapp,
       sum((origem like 'instagram%')::int) vindas_ig,
       sum((origem = 'google')::int) vindas_google,
       (select count(*) from ara_pedidos where pago_em >= now() - interval '7 days') pedidos_pagos
from s
where coalesce(pais, '') in ('', 'Brazil', 'Brasil');
```
