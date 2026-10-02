# ARA Cristais: notas para o Claude

## Cadastro de produtos
- Os produtos ficam na retaguarda (Supabase, tabela `ara_produtos`). O bloco `ara-def` do `index.html` é a lista de reserva: mantenha os dois iguais.
- Cada mudança no banco fica registrada em `supabase/migrations/`.
- O site lê `ara_produtos` com permissão por coluna (custo e custos ficam escondidos). Coluna nova que o site lê precisa de `grant select (coluna) on public.ara_produtos to anon, authenticated`; sem isso a consulta falha e o site mostra fotos e preços antigos.
- Foto padrão da loja: a própria peça em fundo branco, quadrada (1000 × 1000), sem etiqueta de preço, cartela ou embalagem. Fotos pequenas são ampliadas antes.
- Peça natural com uma unidade só: `estoque = 1`.

## Preço das pedras e cristais (planilha de compra)
Sempre que chegar uma planilha de compra:
- **Se ela tiver a coluna "VALOR DE VENDA", use exatamente esse valor.** É o preço que o dono já definiu.
- Só quando essa coluna faltar (ou estiver vazia numa linha), calcule pela régua abaixo.

Régua do dono:
1. Parta do "Preço de venda sugerido" da planilha (custo real × 3, terminado em ,90).
2. Arredonde **para cima**, para um valor redondo: em geral o próximo múltiplo de R$ 10 (27,90 → 30; 54,90 → 60; 108,90 → 110; 97,90 → 100).
3. Nunca trabalhe no preço limite: a loja dá desconto no Pix e para quem se cadastra, então o preço cheio precisa ter folga para essa régua de descontos.
4. Peças parecidas podem ficar com o mesmo preço. O dono corrige depois, pelo painel, o que achar necessário.
