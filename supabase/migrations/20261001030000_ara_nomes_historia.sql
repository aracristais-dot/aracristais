-- Nomes das peças inspirados na história dos cristais (endereços antigos redirecionam no site).
update public.ara_produtos set
  slug = 'caixa-relicario',
  nome = 'Caixa Relicário',
  texto = E'Na Idade Média, o cristal de rocha era símbolo de pureza e guardava o que havia de mais sagrado: nas igrejas, as relíquias ficavam em relicários de cristal, à vista de todos, sem que ninguém precisasse tocá-las. A Caixa Relicário nasce dessa ideia.\n\nÉ um objeto de coleção criado para guardar cristais, minerais e pequenos objetos que carregam significado.\n\nMadeira, vidro e interior em veludo preto formam uma composição que deixa cada peça organizada e à vista, transformando aquilo que você guarda em parte da decoração e da sua história.\n\nPossui cinco compartimentos individuais e pode ser usada para criar sua própria coleção ou receber uma curadoria de cristais ARA.\n\nUma peça para guardar aquilo que você escolheu cultivar.',
  seo_titulo = 'Caixa Relicário: caixa de madeira e vidro para cristais | ARA',
  atualizado_em = now()
where slug in ('ara-santuario', 'caixa-relicario');

update public.ara_produtos set
  slug = 'estojo-travessia',
  nome = 'Estojo Travessia',
  frase = 'Para levar seus cristais e suas intenções em cada caminho.',
  texto = E'Por séculos, viajantes levaram pedras como amuleto de proteção. Na Pérsia e nas rotas do Oriente, cavaleiros prendiam turquesas nas rédeas e nas roupas para atravessar estradas e batalhas em segurança. O Estojo Travessia nasce dessa tradição.\n\nCompacto e protegido, ele organiza cristais, pequenas peças e acessórios em uma composição que pode ser montada de acordo com a sua intenção, rotina e história.\n\nCada composição pode ser diferente. Cristais, pulseiras e outros elementos podem ocupar seu espaço e acompanhar você onde estiver.\n\nVocê pode escolher uma composição pronta da ARA ou começar pela própria peça e, aos poucos, construir a sua.\n\nPorque aquilo que tem significado também merece um lugar para ser guardado.',
  seo_titulo = 'Estojo Travessia: porta-cristais para levar seus cristais | ARA',
  seo_descricao = 'Estojo porta-cristais compacto e rígido, revestido em tecido, para organizar e levar cristais, pulseiras e pequenos objetos. Nas cores roxo e cinza. Loja ARA.',
  atualizado_em = now()
where slug in ('ara-porta-cristais', 'estojo-travessia');

update public.ara_produtos set
  texto = E'No Egito antigo, o lápis-lazúli, a cornalina e a turquesa viravam amuletos de proteção, e um escaravelho de lápis-lazúli acompanhava os mortos para guardá-los na outra vida. A Caixa Guardiã guarda os seus guardiões.\n\nMadeira e vidro para guardar o que é precioso sem esconder: os seus cristais, uma joia herdada, as lembranças de uma viagem. A tampa de vidro deixa tudo à vista e protegido.',
  atualizado_em = now()
where slug = 'caixa-guardia';

update public.ara_produtos set
  texto = E'Os primeiros registros do uso de cristais vêm dos sumérios, que há mais de quatro mil anos os incluíam em fórmulas e rituais. A Bandeja Ritual é um altar pronto para os seus.\n\nMármore natural e três cristais brutos brasileiros, escolhidos à mão e compostos para uma intenção. Cada bandeja é única: os veios da pedra e a forma de cada cristal nunca se repetem.',
  atualizado_em = now()
where slug = 'bandeja-ritual';

update public.ara_produtos set
  texto = E'A areia é feita, em grande parte, de quartzo: cristais que o tempo transformou em grãos.\n\nVire a ampulheta e respire até a areia terminar de cair. Um jeito bonito de marcar uma pausa, uma meditação curta ou o tempo de um chá, sem olhar para a tela.',
  atualizado_em = now()
where slug = 'ampulheta-pausa';

update public.ara_produtos set
  texto = E'Os gregos chamavam o âmbar de élektron e o ligavam ao brilho do sol. É dessa palavra que vem "eletricidade".\n\nBlocos de vidro âmbar lapidados em facetas geométricas, que lembram a estrutura de um cristal. Perto da janela, espalham reflexos dourados pelo ambiente.',
  atualizado_em = now()
where slug = 'prisma-ambar';

update public.ara_produtos set
  texto = E'A drusa de ametista é um aglomerado de pequenas pontas de cristal que nascem juntas, dentro dos geodos do sul do Brasil. É uma das pedras mais queridas de quem começa uma coleção, e uma das mais bonitas para um cantinho de calma.\n\nO nome vem do grego amethystos, "não embriagado": os gregos acreditavam que a pedra protegia contra os excessos do vinho. Na tradição dos cristais, a ametista é associada à calma, ao sono tranquilo e à intuição. Muita gente a deixa no quarto, na mesa de cabeceira ou no espaço de meditação.\n\nCada drusa é única: escolhemos as peças uma a uma, pela cor e pelo brilho das pontas.',
  uso = 'Deixe em um lugar onde bata luz natural: no quarto, no altar ou na mesa de trabalho. Para guardar junto com outros cristais, a Caixa Relicário mantém cada peça separada e à vista.',
  atualizado_em = now()
where slug = 'drusa-de-ametista';

update public.ara_produtos set
  uso = 'Na entrada de casa, na mesa de trabalho ou na bolsa. Para levar com você, o Estojo Travessia protege a pedra no dia a dia.',
  atualizado_em = now()
where slug = 'turmalina-negra-bruta';

update public.ara_produtos set
  texto = E'A ponta de cristal é o quartzo transparente na sua forma natural: seis faces que terminam em uma ponta. O Brasil é um dos maiores produtores de quartzo do mundo.\n\nA palavra cristal vem do grego krýstallos, "gelo": os gregos acreditavam que o quartzo transparente era gelo que nunca derretia. Na tradição dos cristais, ele é a pedra da clareza, o cristal que acompanha qualquer outra pedra e amplifica a sua intenção. Por isso é a primeira peça de muitas coleções.\n\nCada ponta é única e escolhida à mão, pela transparência.',
  uso = 'Sobre a mesa, no altar ou junto de outros cristais. Na Caixa Relicário, ela fica no centro da coleção.',
  atualizado_em = now()
where slug = 'ponta-de-cristal';
