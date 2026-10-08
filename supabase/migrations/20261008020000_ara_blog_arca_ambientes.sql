-- Artigo "onde colocar a Arca": fotos de ambientação na sala, no quarto e no escritório.
update public.ara_posts set conteudo = replace(replace(replace(conteudo,
  '<h2>Na mesa de centro da sala</h2>',
  '<h2>Na mesa de centro da sala</h2>
<figure><img src="/img/arca-ambiente-sala.12e14bc2.jpg" alt="Arca de cristais sobre a mesa de centro de travertino, na sala de estar" width="1374" height="1145" loading="lazy"><figcaption>Ambientação ilustrativa.</figcaption></figure>'),
  '<h2>Na mesa do escritório, perto da janela</h2>',
  '<h2>No quarto, na luz do fim de tarde</h2>
<figure><img src="/img/arca-ambiente-quarto.f26886bf.jpg" alt="Arca de cristais sobre a cômoda do quarto, perto do espelho" width="1374" height="1145" loading="lazy"><figcaption>Ambientação ilustrativa.</figcaption></figure>
<p>Sobre a cômoda ou o móvel baixo ao lado da cama, a Arca recebe a luz suave da janela e cria um canto de pausa. No quarto, combinam as pedras ligadas à calma e ao sono, como a ametista e o quartzo rosa.</p>
<h2>Na mesa do escritório, perto da janela</h2>
<figure><img src="/img/arca-ambiente-escritorio.f7bab6bf.jpg" alt="Arca de cristais sobre a mesa do escritório, ao lado do notebook" width="1374" height="1145" loading="lazy"><figcaption>Ambientação ilustrativa.</figcaption></figure>'),
  'Abaixo, três lugares onde ela funciona bem.', 'Abaixo, alguns lugares onde ela funciona bem.'),
  titulo = 'Cristais na decoração: onde colocar a Arca na sala, no quarto e no escritório',
  resumo = 'Mesa de centro, aparador do hall, quarto ou escritório perto da janela: como usar a Arca, a caixa de cristais da ARA, na decoração.',
  seo_titulo = 'Cristais na decoração: sala, quarto e escritório | ARA',
  foto_url = '/img/arca-ambiente-sala.12e14bc2.jpg',
  atualizado_em = now()
where slug = 'arca-de-cristais-na-decoracao' and position('arca-ambiente-quarto' in conteudo) = 0;
