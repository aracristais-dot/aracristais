-- Blog (post de domingo): cristais para o quarto.
insert into public.ara_posts (slug,titulo,subtitulo,resumo,conteudo,ilustracao,foto_url,publicado,data,ordem,seo_titulo,seo_descricao) values ('cristais-para-o-quarto','Cristais para o quarto: quais escolher para um sono mais tranquilo','Ametista, selenita e quartzo: os cristais que a tradição liga ao descanso e onde colocá-los no quarto.','Qual cristal colocar no quarto? Veja os cristais ligados à calma e ao descanso, onde posicioná-los e um ritual simples de cinco minutos para fechar o dia.','<p>O quarto é o último lugar que você vê antes de dormir e o primeiro ao acordar. Se ele está cheio de estímulos, a cabeça demora a desligar. Por isso tanta gente procura um <strong>cristal para o quarto</strong>: uma peça bonita, natural, que transforma a cabeceira num pequeno ritual de pausa.</p>
<p>Cristais não substituem cuidado com o sono, nem tratamento quando ele é necessário. O que eles fazem, e fazem bem, é mudar o clima do ambiente e marcar a hora de desacelerar. Abaixo, os cristais que a tradição liga ao descanso e como usá-los na decoração do quarto.</p>
<figure><img src="/img/arca-ambiente-quarto.f26886bf.jpg" alt="Arca de cristais sobre a cômoda do quarto, perto do espelho" width="1374" height="1145" loading="lazy"><figcaption>Ambientação ilustrativa.</figcaption></figure>
<h2>Ametista: o cristal clássico para o quarto</h2>
<p>Se existe um <strong>cristal para dormir</strong>, na tradição ele é a ametista. O violeta é associado à calma, ao sono tranquilo e à intuição. O nome vem do grego <em>amethystos</em>, "não embriagado": os antigos a viam como a pedra da mente serena.</p>
<p>Na decoração, uma drusa de ametista sobre a mesa de cabeceira ou a cômoda traz cor sem pesar, e as pontas pegam a luz do abajur à noite. Veja a <a href="/loja/aura-da-calma">Aura da Calma</a>: duas drusas de ametista brasileira sobre uma bandeja dourada, composição única, montada à mão. Ou conheça todas as peças na página da <a href="/loja?pedra=ametista">ametista</a>.</p>
<p><strong>Cuidado:</strong> a ametista desbota com sol direto por muitas horas. No quarto, longe da janela, ela fica perfeita.</p>
<h2>Selenita: para limpar o ambiente</h2>
<p>A selenita tem um branco sedoso, quase perolado. O nome vem de Selene, a deusa grega da lua, e na tradição ela é a pedra da limpeza energética. Muita gente deixa uma placa ou um bastão de selenita no quarto para "renovar" o espaço e apoiar os outros cristais em cima dela.</p>
<p>A <a href="/loja/aura-da-limpeza">Aura da Limpeza</a> une selenita e ágata sobre a bandeja dourada: a pedra que limpa e a pedra que equilibra. Mais sobre ela na página da <a href="/loja?pedra=selenita">selenita</a>.</p>
<p><strong>Cuidado:</strong> a selenita se desfaz com água. Nunca molhe; limpe só com pano seco.</p>
<h2>Quartzo transparente: clareza para começar o dia</h2>
<p>O cristal de quartzo é associado à clareza e à força das intenções. No quarto, funciona bem perto do espelho ou da janela, onde a luz da manhã atravessa a pedra. É um jeito simples de lembrar, ao acordar, do que você quer para o dia. Veja a <a href="/loja/aura-da-clareza">Aura da Clareza</a>, com três cristais de quartzo natural.</p>
<h2>Onde colocar os cristais no quarto</h2>
<ul>
<li><strong>Mesa de cabeceira:</strong> o lugar mais comum. Uma peça só, sem amontoar, para não virar mais um objeto na bagunça.</li>
<li><strong>Cômoda ou penteadeira:</strong> uma composição maior, como uma Aura ou a <a href="/arca#colecao">Arca</a>, vira o ponto de atenção do quarto.</li>
<li><strong>Perto do espelho:</strong> o reflexo multiplica o brilho das pedras.</li>
<li><strong>Longe do sol direto:</strong> principalmente a ametista e outras pedras coloridas.</li>
</ul>
<h2>Um ritual simples para fechar o dia</h2>
<p>O cristal funciona melhor quando faz parte de um momento. Uma sugestão de cinco minutos antes de deitar:</p>
<ol>
<li>Apague as luzes fortes e deixe só o abajur.</li>
<li>Acenda um incenso de aroma suave, como o <a href="/loja/incenso-shankar-lavanda">massala de lavanda</a>, ou use o <a href="/loja/kit-difusor-pedra-sabao">difusor de pedra-sabão</a> com algumas gotas de óleo essencial.</li>
<li>Segure o seu cristal por um instante e pense em uma coisa boa do dia.</li>
<li>Apague o incenso ou a vela antes de dormir. Nunca deixe chama acesa sem ninguém acordado por perto.</li>
</ol>
<h2>Uma peça só sua</h2>
<p>Se você quer ir além de uma pedra, a <a href="/arca#colecao">Arca</a> é uma obra exclusiva, criada à mão a partir do seu nome e da sua data de nascimento. Cada cristal é escolhido um a um e reunido entre madeira orgânica e vidro: um altar particular que cabe na cômoda do quarto.</p>
<p>Entrega na Grande São Paulo em até 3 dias, ou no mesmo dia pelo Motoboy Express para pedidos até 12h. Veja <a href="/como-comprar">como comprar e entrega</a> ou <a href="https://wa.me/5511973371416?text=Ol%C3%A1!%20Li%20o%20post%20sobre%20cristais%20para%20o%20quarto%20e%20quero%20ajuda%20para%20escolher." target="_blank" rel="noopener">fale com a ARA pelo WhatsApp</a> para escolher o cristal do seu quarto.</p>','ametista','',true,'2026-10-11',-4,'Cristais para o quarto: quais escolher para dormir | ARA','Ametista, selenita e quartzo: os cristais ligados à calma e ao descanso, onde colocar no quarto e um ritual simples para fechar o dia.') on conflict (slug) do update set titulo=excluded.titulo, subtitulo=excluded.subtitulo, resumo=excluded.resumo, conteudo=excluded.conteudo, ilustracao=excluded.ilustracao, foto_url=excluded.foto_url, publicado=excluded.publicado, data=excluded.data, ordem=excluded.ordem, seo_titulo=excluded.seo_titulo, seo_descricao=excluded.seo_descricao, atualizado_em=now();
