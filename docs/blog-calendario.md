# Blog da ARA: calendário e roteiro do post de domingo

Um post novo todo **domingo às 12h** (horário de São Paulo). Domingo é o dia em que a pessoa está em casa e pesquisa com calma o que vai comprar na semana.

## Ordem de prioridade do tema da semana

1. **Peça nova na loja.** Produto ativo, com estoque, alterado nos últimos 7 dias e que ainda não aparece em nenhum post (nenhum link `/loja/<slug>` no `conteudo` de `ara_posts`). Escreva sobre ela: o que é, significado do cristal, onde colocar em casa, cuidados e link para a peça. Se entraram várias, faça um post reunindo as novidades.
2. **Assunto em alta.** Pesquise a semana (Google Trends Brasil/SP, notícias de decoração, datas comemorativas próximas) e, se houver tema forte ligado a cristais ou decoração, use-o.
3. **Calendário abaixo.** Pegue o primeiro tema ainda não publicado (confira pelo slug em `ara_posts`).

Depois de publicar, marque o tema como feito na tabela (coluna "Status") e, se usou um tema fora da lista, acrescente uma linha.

## Calendário

| Domingo | Tema | Busca alvo | Peças para linkar | Status |
|---|---|---|---|---|
| 11/10/2026 | Cristais para o quarto: quais escolher para dormir melhor | cristal para o quarto, cristal para dormir | Aura da Calma, Aura da Limpeza, Arca (quarto) | |
| 18/10/2026 | Pirita: significado, como usar e onde colocar em casa | pirita significado, pirita para que serve | Aura da Prosperidade, /loja?pedra=pirita | |
| 25/10/2026 | Presente com cristal: como escolher para cada pessoa | presente com cristal, presente espiritual | Arca, Auras, Bandeja Ritual | |
| 01/11/2026 | Ametista: significado, decoração e cuidados com o sol | ametista significado, drusa de ametista | Aura da Calma, /loja?pedra=ametista | |
| 08/11/2026 | Cristais para o escritório e o home office | cristal para o escritório, cristal para foco | Aura da Prosperidade, Aura da Clareza, Ampulheta Pausa | |
| 15/11/2026 | Selenita: o que é, para que serve e por que não molhar | selenita significado, selenita para que serve | Aura da Limpeza, /loja?pedra=selenita | |
| 22/11/2026 | Presentes de Natal com significado: guia de cristais por perfil | presente de natal diferente, presente de natal com significado | Arca, Auras, Frasco Lapidado | |
| 29/11/2026 | Decoração de fim de ano com cristais: mesa posta e cantinho da casa | decoração de natal com cristais | Bandeja Ritual, Prisma Âmbar, Auras | |
| 06/12/2026 | Amigo secreto: presentes de cristal até R$ 120 | presente amigo secreto até 100 reais | Chaveiros de pedra, Aura da Clareza, incensos | |
| 13/12/2026 | As cores e os cristais para a virada de 2027 | cor do ano novo, cristal para o ano novo | Citrino, Pirita, Quartzo | |
| 20/12/2026 | Presente de última hora em São Paulo: entrega no mesmo dia | presente de última hora sp, entrega no mesmo dia | Motoboy Express, Auras, Arca | |
| 27/12/2026 | Ritual de ano novo com cristais: limpeza e intenção para 2027 | ritual de ano novo, ritual com cristais | ARA Ritual · Limpeza, Palo Santo, Selenita | |

## Regras de texto (marca ARA)

- Português do Brasil, tom de quem entende e cuida das pedras. Vender desejo e resolver a dor de quem lê.
- Use "cristais", não "pedrinhas". A Arca **nunca** é "caixa": é obra, altar particular, em madeira orgânica e vidro. Cristais vêm do Brasil e de outras partes do mundo.
- Nada inventado: sem depoimentos, números de vendas, prêmios, citações de imprensa ou "a melhor loja de SP". Significados dos cristais sempre como "na tradição".
- Fonte externa (Pantone, CASACOR, notícias) só com link real no fim, em `<p class="muted">Fontes: …</p>`.
- Só links para páginas que existem: `/loja/<slug>` de produto ativo, `/loja?pedra=<pedra>` (ametista, pirita, quartzo, selenita, turmalina, agata, citrino, fluorita, amazonita, aragonita, geodo), `/arca#colecao`, `/como-comprar`, `/blog/<slug>`.
- Estrutura: parágrafo de abertura com a busca alvo, 3 a 6 `<h2>`, listas curtas, link para 2 a 5 peças, fechamento com `/como-comprar` e WhatsApp (`https://wa.me/5511973371416?text=…`).
- Imagens só as que já existem em `/img/` (ex.: `arca-ambiente-sala.12e14bc2.jpg`, `arca-ambiente-quarto.f26886bf.jpg`, `arca-ambiente-escritorio.f7bab6bf.jpg`), em `<figure>` com `alt` descritivo, `width`/`height` e `<figcaption>Ambientação ilustrativa.</figcaption>` quando for imagem ilustrativa.
- 600 a 1.000 palavras. `seo_titulo` até 60 caracteres terminando em ` | ARA`; `seo_descricao` até 155 caracteres.

## Como publicar

1. Escolha `ilustracao` entre: ametista, quartzo, pirita, turmalina, citrino, rosa.
2. Grave em `ara_posts` com `publicado = true`, `data` = o domingo, `ordem` = menor `ordem` atual − 1 (o mais novo fica em primeiro). Use `insert … on conflict (slug) do update`, no mesmo formato de `supabase/migrations/20261010010000_ara_blog_loja_de_cristais.sql`.
3. Salve o mesmo SQL em `supabase/migrations/<AAAAMMDD>120000_ara_blog_<slug_com_underline>.sql`.
4. Coloque o mesmo post no começo da lista `posts` do bloco `ara-def` do `index.html`, sem reformatar o resto do JSON (o bloco usa `<\/` dentro das strings). Confira que o md5 do `conteudo` é igual no banco e no `ara-def`.
5. Atualize o Status nesta tabela, faça commit, abra o PR, faça o merge (squash) e confira a página no ar com `extensions.http_get('https://www.aracristais.com.br/blog/<slug>')`.
