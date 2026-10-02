'use strict';
/* =========================================================
   ARA - páginas entregues pelo servidor (Vercel)
   Cada endereço (/arca, /loja/<produto>, /blog/<artigo>...) sai com título,
   descrição, foto, preço e conteúdo já no HTML: é o que o Google indexa e o que
   o Instagram/WhatsApp mostram na prévia do link. Depois o site segue igual.
   Os dados vêm da retaguarda (Supabase); se ela não responder, usa a lista
   embutida no index.html.
   ========================================================= */
const fs = require('fs');
const path = require('path');

const DOMINIO = 'https://www.aracristais.com.br';
const VIEWS = ['inicio', 'historia', 'arca', 'loja', 'blog'];
const SECOES = { colecao: '/arca#colecao', pedido: '/arca#pedido', obra: '/#obra', intencoes: '/#intencoes', cristais: '/historia#cristais', 'linha-do-tempo': '/historia#linha-do-tempo' };
const INTRO_CRISTAIS = '<p class="lj-sec-intro">Os cristais se formam ao longo de milhões de anos e acompanham a humanidade desde os sumérios. <a href="/historia#linha-do-tempo">Conheça essa história</a>, que também dá nome às peças da ARA.</p>';
/* produtos que mudaram de nome: o endereço antigo leva ao novo */
const ENDERECOS_ANTIGOS = { 'ara-santuario': 'caixa-relicario', 'ara-porta-cristais': 'estojo-travessia', 'quartzo-rosa-bruto': 'cristal-de-quartzo', 'drusa-de-citrino': 'pulseira-de-citrino', 'geodo-branco': 'geodo-marroquino' };
const COLS_PRODUTO = 'id,slug,nome,tag,frase,texto,preco,rotulo,variantes,detalhes,uso,cuidados,foto_url,fotos,disponivel,sem_adicional,ativo,ordem,seo_titulo,seo_descricao,estoque,atualizado_em,categoria';
const ARCA_PADRAO = {
  essencial: { nome: 'Arca Essencial', preco: 1200, medidas: '30 x 16 x 8,5 cm', prazo: '4 dias',
    descricao: 'Mosaico de cristais naturais brasileiros montado à mão numa caixa compacta de madeira, com vidro nas laterais e tampa que abre. Criado a partir do seu nome completo e da sua data de nascimento: uma peça única.' },
  plena: { nome: 'Arca Plena', preco: 1700, medidas: '36 x 21 x 12 cm', prazo: '4 dias',
    descricao: 'Mosaico de cristais naturais brasileiros montado à mão numa caixa maior de madeira e vidro, com mais pedras e mais camadas. Criado a partir do seu nome completo e da sua data de nascimento: uma peça única.' },
  atelie: { nome: 'Arca Ateliê', preco: 4200, medidas: '30 x 22 x 10 cm', prazo: '40 dias',
    descricao: 'Mosaico de cristais naturais brasileiros numa caixa feita à mão, sob encomenda, por um marceneiro artesão, em madeira maciça e vidro. Criado a partir do seu nome completo e da sua data de nascimento: exclusiva do início ao fim.' },
};
const WHATS_PADRAO = '5511973371416';
const ICONE_HUMANO = '<svg viewBox="0 0 24 24" aria-hidden="true" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"><path d="M4 5.5h16v10H9.5L5 19.5v-4H4z"/><path d="M12 13.2s-3-1.8-3-3.6a1.6 1.6 0 0 1 3-.8 1.6 1.6 0 0 1 3 .8c0 1.8-3 3.6-3 3.6z" fill="currentColor" stroke="none"/></svg>';
function whats(d) { const c = (d.cfg && d.cfg.contato) || {}; return String(c.whatsapp || WHATS_PADRAO).replace(/\D/g, '') || WHATS_PADRAO; }

/* ---------- modelo da página ---------- */
let _tpl = null;
function template() {
  if (_tpl) return _tpl;
  const cands = [path.join(__dirname, '..', 'index.html'), path.join(process.cwd(), 'index.html')];
  for (const c of cands) { try { _tpl = fs.readFileSync(c, 'utf8'); return _tpl; } catch (e) { /* tenta o próximo */ } }
  throw new Error('index.html não encontrado');
}
/* garante o modelo: do pacote da função ou, se faltar, do próprio site */
async function prepararTemplate(origem) {
  try { return template(); } catch (e) { /* busca no site */ }
  const ctl = new AbortController();
  const t = setTimeout(() => ctl.abort(), 3000);
  try {
    const r = await fetch((origem || DOMINIO) + '/index.html', { signal: ctl.signal });
    if (r.ok) { _tpl = await r.text(); return _tpl; }
  } finally { clearTimeout(t); }
  throw new Error('index.html não encontrado');
}
function blocoJSON(html, id) {
  const m = html.match(new RegExp('<script type="application/json" id="' + id + '">([\\s\\S]*?)</script>'));
  if (!m) return null;
  try { return JSON.parse(m[1]); } catch (e) { return null; }
}
function trocarBlocoJSON(html, id, valor) {
  const json = JSON.stringify(valor).replace(/</g, '\\u003c');
  return html.replace(new RegExp('(<script type="application/json" id="' + id + '">)[\\s\\S]*?(</script>)'), (m, a, b) => a + json + b);
}

/* ---------- retaguarda ---------- */
async function sb(tabela, query) {
  const html = template();
  const url = (html.match(/var ARA_SB_URL='([^']+)'/) || [])[1];
  const key = (html.match(/var ARA_SB_KEY='([^']+)'/) || [])[1];
  if (!url || !key) return null;
  const ctl = new AbortController();
  const t = setTimeout(() => ctl.abort(), 2500);
  try {
    const r = await fetch(url + '/rest/v1/' + tabela + '?' + query, { headers: { apikey: key, Authorization: 'Bearer ' + key }, signal: ctl.signal });
    if (!r.ok) { console.warn('ARA ' + tabela + ': HTTP ' + r.status); return null; }
    return await r.json();
  } catch (e) {
    console.warn('ARA ' + tabela + ': ' + e.message);
    return null;
  } finally { clearTimeout(t); }
}

/* chama uma função do banco (RPC) com a chave pública do site */
async function rpc(nome, args, ms) {
  const html = template();
  const url = (html.match(/var ARA_SB_URL='([^']+)'/) || [])[1];
  const key = (html.match(/var ARA_SB_KEY='([^']+)'/) || [])[1];
  if (!url || !key) return null;
  const ctl = new AbortController();
  const t = setTimeout(() => ctl.abort(), ms || 15000);
  try {
    const r = await fetch(url + '/rest/v1/rpc/' + nome, { method: 'POST', headers: { apikey: key, Authorization: 'Bearer ' + key, 'Content-Type': 'application/json' }, body: JSON.stringify(args || {}), signal: ctl.signal });
    if (!r.ok) { console.warn('ARA rpc ' + nome + ': HTTP ' + r.status); return null; }
    return await r.json();
  } catch (e) {
    console.warn('ARA rpc ' + nome + ': ' + e.message);
    return null;
  } finally { clearTimeout(t); }
}

let _cache = null, _cacheEm = 0;
async function dados() {
  if (_cache && Date.now() - _cacheEm < 60000) return _cache;
  const html = template();
  const def = blocoJSON(html, 'ara-def') || { produtos: [], posts: [], ilus: {} };
  const [prods, posts, cfg] = await Promise.all([
    sb('ara_produtos', 'select=' + COLS_PRODUTO + '&order=ordem.asc'),
    sb('ara_posts', 'select=*&order=ordem.asc'),
    sb('ara_config', 'select=chave,valor'),
  ]);
  const okProd = Array.isArray(prods) && prods.length > 0, okPost = Array.isArray(posts) && posts.length > 0;
  const ordem = (a, b) => (a.ordem || 0) - (b.ordem || 0);
  const d = {
    produtos: (okProd ? prods : def.produtos || []).filter(p => p.ativo !== false).sort((a, b) => (cristal(b) - cristal(a)) || ordem(a, b)),
    posts: (okPost ? posts : def.posts || []).filter(p => p.publicado !== false).sort(ordem),
    config: Array.isArray(cfg) ? cfg : [],
    ilus: def.ilus || {},
    imgs: blocoJSON(html, 'ara-imgs') || {},
    seo: blocoJSON(html, 'ara-seo') || {},
    okProd, okPost,
  };
  d.cfg = {};
  d.config.forEach(r => { d.cfg[r.chave] = r.valor; });
  if (okProd && okPost && Array.isArray(cfg)) { _cache = d; _cacheEm = Date.now(); }
  return d;
}

/* ---------- utilidades ---------- */
const esc = t => String(t == null ? '' : t).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
const xml = t => String(t == null ? '' : t).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&apos;' }[c]));
const brl0 = v => Number(v).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL', minimumFractionDigits: 0, maximumFractionDigits: 0 });
const brl2 = v => Number(v).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
const abs = u => !u ? '' : (/^https?:\/\//.test(u) ? u : DOMINIO + (u.charAt(0) === '/' ? u : '/' + u));
const dia = t => { const m = String(t || '').match(/^\d{4}-\d{2}-\d{2}/); return m ? m[0] : ''; };
const paragrafos = t => String(t || '').split(/\n\s*\n/).map(x => x.trim()).filter(Boolean).map(x => '<p>' + esc(x).replace(/\n/g, '<br>') + '</p>').join('');
const texto = t => String(t || '').replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();

/* estoque: o da opção vale quando existe; senão vale o do produto (mesma regra do site e do pagamento) */
function estoque(p, v) { if (v && typeof v.estoque === 'number') return v.estoque; return (p && typeof p.estoque === 'number') ? p.estoque : null; }
function varOk(p, v) { const e = estoque(p, v); return e === null || e > 0; }
function disponivel(p) {
  if (!p || !p.disponivel) return false;
  const vs = p.variantes || [];
  return vs.length ? vs.some(v => varOk(p, v)) : varOk(p, null);
}
function mesmoPreco(p) { const vs = p.variantes || []; return vs.length > 0 && vs.every(k => Number(k.preco) === Number(vs[0].preco)); }
function precoBase(p) { const vs = p.variantes || []; return vs.length ? Math.min.apply(null, vs.map(v => Number(v.preco))) : Number(p.preco); }
function textoPreco(p) { const vs = p.variantes || []; return (vs.length && !mesmoPreco(p) ? 'a partir de ' : '') + brl0(precoBase(p)) + (disponivel(p) ? '' : ' · Esgotado'); }
/* cristais vêm primeiro na loja; o resto é acessório e complemento */
function cristal(p) { return p && p.categoria === 'cristal' ? 1 : 0; }
/* imagem ilustrativa (enquanto não há foto da peça): fica fora do Google Shopping */
function ilustrativa(u) { return /\/img\/loja\/ilus-/.test(String(u || '')); }
/* "Também na loja": primeiro o que dá para comprar agora */
function relacionados(d, p) { return d.produtos.filter(x => x.slug !== p.slug).map((x, i) => [x, i]).sort((a, b) => (disponivel(b[0]) - disponivel(a[0])) || (a[1] - b[1])).slice(0, 3).map(x => x[0]); }
/* foto da prévia do link da loja: a primeira peça à venda com foto de verdade */
function capaLoja(d) { const p = d.produtos.filter(x => disponivel(x) && !ilustrativa(foto(d, x, null)))[0] || d.produtos[0]; return p ? foto(d, p, null) : ''; }
function gradeLoja(d) {
  const card = p => cardProduto(d, p), cr = d.produtos.filter(p => cristal(p)), ac = d.produtos.filter(p => !cristal(p));
  if (!cr.length || !ac.length) return '<div class="lj-grade">' + d.produtos.map(card).join('') + '</div>';
  return '<h2 class="lj-sec">Cristais</h2>' + INTRO_CRISTAIS + '<div class="lj-grade">' + cr.map(card).join('') + '</div>' +
    '<h2 class="lj-sec">Acessórios e complementos</h2><div class="lj-grade">' + ac.map(card).join('') + '</div>';
}
function foto(d, p, v) {
  if (v && v.img) return v.img;
  if (v && d.imgs[p.slug + '-' + v.id]) return d.imgs[p.slug + '-' + v.id];
  if (p.foto_url) return p.foto_url;
  return d.imgs[p.slug] || '/og-image.jpg';
}
/* até três fotos: a principal (ou a da opção) e outras de ângulos diferentes */
function fotos(d, p, v) { return [foto(d, p, v)].concat(Array.isArray(p.fotos) ? p.fotos : []).filter((u, i, a) => u && a.indexOf(u) === i).slice(0, 3); }
function fotoReal(d, p, v) { return !!((v && v.img) || (!(v && d.imgs[p.slug + '-' + v.id]) && p.foto_url)); }
function opcaoInicial(p, pedida) {
  const vs = p.variantes || [];
  if (!vs.length) return null;
  const livres = vs.filter(v => varOk(p, v));
  return livres.filter(v => v.id === pedida)[0] || livres[0] || vs[0];
}

function arcas(d) {
  const cfg = (d.cfg.arcas && d.cfg.arcas.modelos) || {};
  const html = template();
  const out = {};
  Object.keys(ARCA_PADRAO).forEach(k => {
    const m = Object.assign({ id: k }, ARCA_PADRAO[k]);
    const x = cfg[k] || {};
    ['nome', 'preco', 'medidas', 'prazo', 'foto_url'].forEach(f => { if (x[f] != null && x[f] !== '') m[f] = x[f]; });
    m.esgotado = x.disponivel === false || (typeof x.estoque === 'number' && x.estoque <= 0);
    m.foto = m.foto_url || (html.match(new RegExp('/img/arca-' + k + '\\.[0-9a-f]{8}\\.jpg')) || [])[0] || '/og-image.jpg';
    out[k] = m;
  });
  return out;
}
function parcelasArca(d) { return Number((d.cfg.arcas && d.cfg.arcas.parcelasMax) || 10); }

/* ---------- cabeçalho (título, descrição, prévia do link, dados estruturados) ---------- */
function grafoBase(html) {
  const m = html.match(/<script type="application\/ld\+json">([\s\S]*?)<\/script>/);
  try { return JSON.parse(m[1])['@graph'].filter(n => n['@type'] === 'Organization' || n['@type'] === 'WebSite'); } catch (e) { return []; }
}
function trocar(html, re, novo) {
  if (!re.test(html)) throw new Error('marcação não encontrada: ' + re);
  return html.replace(re, () => novo);
}
function aplicarHead(html, o) {
  html = trocar(html, /<title>[\s\S]*?<\/title>/, '<title>' + esc(o.titulo) + '</title>');
  html = trocar(html, /<meta name="description" content="[^"]*">/, '<meta name="description" content="' + esc(o.descricao) + '">');
  html = trocar(html, /<link rel="canonical" href="[^"]*">/, '<link rel="canonical" href="' + esc(o.url) + '">');
  if (o.robots) html = trocar(html, /<meta name="robots" content="[^"]*">/, '<meta name="robots" content="' + o.robots + '">');
  html = trocar(html, /<meta property="og:type" content="[^"]*">/, '<meta property="og:type" content="' + (o.ogTipo || 'website') + '">');
  html = trocar(html, /<meta property="og:url" content="[^"]*">/, '<meta property="og:url" content="' + esc(o.url) + '">');
  html = trocar(html, /<meta property="og:title" content="[^"]*">/, '<meta property="og:title" content="' + esc(o.titulo) + '">');
  html = trocar(html, /<meta property="og:description" content="[^"]*">/, '<meta property="og:description" content="' + esc(o.descricao) + '">');
  if (o.imagem) {
    const extra = o.preco ? '<meta property="product:price:amount" content="' + Number(o.preco).toFixed(2) + '"><meta property="product:price:currency" content="BRL">' : '';
    html = trocar(html, /<meta property="og:image" content="[^"]*">/, '<meta property="og:image" content="' + esc(abs(o.imagem)) + '">');
    html = trocar(html, /<meta property="og:image:width" content="\d+"><meta property="og:image:height" content="\d+">/,
      (o.imgW ? '<meta property="og:image:width" content="' + o.imgW + '"><meta property="og:image:height" content="' + o.imgH + '">' : '') + (o.alt ? '<meta property="og:image:alt" content="' + esc(o.alt) + '">' : '') + extra);
    html = trocar(html, /<meta name="twitter:image" content="[^"]*">/, '<meta name="twitter:image" content="' + esc(abs(o.imagem)) + '">');
  }
  const grafo = grafoBase(html).concat(o.ld || []);
  html = trocar(html, /<script type="application\/ld\+json">[\s\S]*?<\/script>/,
    '<script type="application/ld+json">' + JSON.stringify({ '@context': 'https://schema.org', '@graph': grafo }).replace(/</g, '\\u003c') + '</script>');
  return html;
}
function migalhas(itens) {
  return { '@type': 'BreadcrumbList', itemListElement: itens.map((it, i) => ({ '@type': 'ListItem', position: i + 1, name: it[0], item: DOMINIO + it[1] })) };
}
function mostrarView(html, v) {
  if (v === 'inicio') return html;
  html = trocar(html, /<div class="view" id="v-inicio">/, '<div class="view" id="v-inicio" hidden>');
  html = trocar(html, new RegExp('<div class="view" id="v-' + v + '" hidden>'), '<div class="view" id="v-' + v + '">');
  return html.replace(new RegExp('(<a href="[^"]*" data-nav="' + v + '")'), '$1 class="ativo"');
}
function injetarDados(html, d) {
  const def = blocoJSON(html, 'ara-def');
  if (def) {
    if (d.okProd) def.produtos = d.produtos;
    if (d.okPost) def.posts = d.posts;
    html = trocarBlocoJSON(html, 'ara-def', def);
  }
  return trocarBlocoJSON(html, 'ara-cfg', d.config);
}

/* ---------- pedaços de página (mesma marcação que o site monta no navegador) ---------- */
function botaoCard(p) {
  if (!disponivel(p)) return '';
  if ((p.variantes || []).length) return '<a class="lj-btn-add" href="/loja/' + esc(p.slug) + '">Escolher opção</a>';
  return '<button class="lj-btn-add" type="button" data-add="' + esc(p.slug) + '">Adicionar ao carrinho</button>';
}
function cardProduto(d, p) {
  return '<div class="lj-card"><a class="lj-item" href="/loja/' + esc(p.slug) + '"><div class="lj-foto' + (fotoReal(d, p, null) ? ' real' : '') + '"><img src="' + esc(foto(d, p, null)) + '" alt="' + esc(p.nome) + '" loading="lazy"></div>' +
    (p.tag ? '<span class="lj-tag">' + esc(p.tag) + '</span>' : '') + '<h3>' + esc(p.nome) + '</h3><span class="lj-preco">' + esc(textoPreco(p)) + '</span>' +
    (p.frase ? '<p class="lj-frase">' + esc(p.frase) + '</p>' : '') + '</a>' + botaoCard(p) + '</div>';
}
function htmlProduto(d, p, v) {
  const disp = disponivel(p), vs = p.variantes || [], mx = Number((d.cfg.loja && d.cfg.loja.parcelasMax) || 1);
  const preco = v ? Number(v.preco) : Number(p.preco);
  const DESTAQUE = ['Significado', 'Para que serve', 'Exclusividade'];
  const det = (p.detalhes || []).filter(x => DESTAQUE.indexOf(x.k) < 0).map(x => '<li><span>' + esc(x.k) + '</span><span>' + esc(x.v) + '</span></li>').join('');
  const sig = (p.detalhes || []).filter(x => x.k === 'Significado' || x.k === 'Para que serve').map(x => '<p><b>' + esc(x.k) + '</b>' + esc(x.v) + '</p>').join('');
  const unica = (p.detalhes || []).filter(x => x.k === 'Exclusividade')[0];
  const vars = vs.map(x => '<button type="button" aria-pressed="' + (x === v) + '"' + (varOk(p, x) ? '' : ' disabled') + '>' + esc(mesmoPreco(p) ? x.nome : x.nome + ' · ' + brl0(x.preco)) + (varOk(p, x) ? '' : ' · esgotado') + '</button>').join('');
  const rel = relacionados(d, p).map(x => cardProduto(d, x)).join('');
  const wa = t => 'https://wa.me/' + esc(whats(d)) + '?text=' + encodeURIComponent(t);
  return '<p class="lj-crumbs"><a href="/">Início</a> / <a href="/loja">Loja</a> / ' + esc(p.nome) + '</p>' +
    '<article class="lj-prod"><div class="lj-foto-box"><div class="lj-foto' + (fotoReal(d, p, v) ? ' real' : '') + '"><img id="lj-foto-img" src="' + esc(foto(d, p, v)) + '" alt="' + esc(p.nome) + '"></div>' +
    (fotos(d, p, v).length > 1 ? '<div class="lj-thumbs" id="lj-thumbs">' + fotos(d, p, v).map((u, i) => '<button type="button" data-foto="' + i + '" aria-label="Foto ' + (i + 1) + '"' + (i ? '' : ' aria-current="true"') + '><img src="' + esc(u) + '" alt="" loading="lazy"></button>').join('') + '</div>' : '') +
    '<p class="lj-ilus" id="lj-ilus"' + (ilustrativa(foto(d, p, v)) ? '' : ' hidden') + '>' + (cristal(p) ? 'Imagem ilustrativa. Cada cristal é único: peça pelo WhatsApp as fotos do seu.' : 'Imagem ilustrativa. Peça pelo WhatsApp as fotos da peça.') + '</p></div><div class="lj-info">' +
    (p.tag ? '<span class="m-tag">' + esc(p.tag) + '</span>' : '') + '<h1>' + esc(p.nome) + '</h1>' + (p.frase ? '<p class="lj-frase-g">' + esc(p.frase) + '</p>' : '') +
    '<p class="lj-preco-g"><span id="lj-preco">' + brl0(preco) + '</span><small id="lj-parc">' + (mx > 1 ? 'ou em até ' + mx + 'x de ' + brl2(preco / mx) + ' sem juros' : '') + '</small></p>' + (unica ? '<p class="lj-unica">' + esc(unica.v) + '</p>' : '') + paragrafos(p.texto) + (sig ? '<div class="lj-sig">' + sig + '</div>' : '') +
    (vars ? '<div><span class="muted" style="font-size:14px">' + esc(p.rotulo || 'Opção') + '</span><div class="lj-var" style="margin-top:8px">' + vars + '</div>' + (v && v.pedras ? '<p class="lj-pedras">Acompanha ' + esc(v.pedras) + '.</p>' : '') + '</div>' : '') +
    '<div class="lj-acoes">' + (disp ? '<button class="btn btn-champ" type="button">Adicionar ao carrinho</button><button class="btn btn-vazado" type="button">Comprar agora</button>' : '<button class="btn btn-champ" type="button" disabled style="opacity:.45">Esgotado</button>') + '</div>' +
    (disp ? '' : '<p class="lj-indisp">Esgotado no momento. <a href="' + wa('Olá! Quero um aviso quando chegar: ' + p.nome + '.') + '" target="_blank" rel="noopener">Avise-me quando chegar</a></p>') +
    '<p class="lj-humano">' + ICONE_HUMANO + '<span><b>Atendimento 100% humanizado.</b> Quem responde é uma pessoa da ARA. <a href="' + wa('Olá! Tenho uma dúvida sobre: ' + p.nome + '.') + '" target="_blank" rel="noopener">Fale com a gente</a></span></p>' +
    '<p class="muted" style="font-size:14px">' + esc((d.cfg.loja && d.cfg.loja.entrega) || '') + '</p>' +
    '<div><details open><summary>Detalhes</summary><div class="c"><ul class="lj-ficha">' + det + '</ul></div></details>' +
    (p.uso ? '<details><summary>Como usar</summary><div class="c">' + esc(p.uso) + '</div></details>' : '') +
    (p.cuidados ? '<details><summary>Cuidados</summary><div class="c">' + esc(p.cuidados) + '</div></details>' : '') + '</div></div></article>' +
    (rel ? '<section class="lj-rel"><h2>Também na loja</h2><div class="lj-grade">' + rel + '</div></section>' : '');
}
function linkSecao(id) { return VIEWS.indexOf(id) >= 0 ? (id === 'inicio' ? '/' : '/' + id) : (SECOES[id] || '/#' + id); }
function htmlPost(d, p) {
  const corpo = String(p.conteudo || '').replace(/href="([a-z0-9-]+)\.html"/g, 'href="/blog/$1"').replace(/href="\.\.\/#([a-z-]+)"/g, (m, id) => 'href="' + linkSecao(id) + '"');
  const dt = p.data ? new Date(p.data + 'T12:00:00').toLocaleDateString('pt-BR', { day: 'numeric', month: 'long', year: 'numeric' }) : '';
  const mais = d.posts.filter(x => x.slug !== p.slug).slice(0, 3).map(x => '<a href="/blog/' + esc(x.slug) + '">' + esc(x.titulo) + '</a>').join('');
  const ilus = p.foto_url ? '<img src="' + esc(p.foto_url) + '" alt="">' : (d.ilus[p.ilustracao] || d.ilus.quartzo || '');
  return '<p class="lj-crumbs"><a href="/">Início</a> / <a href="/blog">Blog</a></p><header class="bl-head">' + ilus + '<h1>' + esc(p.titulo) + '</h1>' +
    (p.subtitulo ? '<p class="bl-sub">' + esc(p.subtitulo) + '</p>' : '') + '<p class="bl-meta">ARA' + (dt ? ' · ' + dt : '') + '</p></header>' +
    '<div class="bl-corpo">' + corpo + '</div><aside class="bl-cta"><h2>Uma peça que só existe para você</h2><p class="muted">Cada Arca da ARA é um mosaico de cristais naturais montado à mão, a partir do seu nome completo e da sua data de nascimento.</p><a class="btn btn-champ" href="/arca#colecao">Conhecer a Arca</a></aside>' +
    (mais ? '<nav class="bl-mais" aria-label="Leia também"><h2>Leia também</h2>' + mais + '</nav>' : '');
}
function cardPost(d, p) {
  return '<a class="bl-card" href="/blog/' + esc(p.slug) + '">' + (d.ilus[p.ilustracao] || '') + '<h3>' + esc(p.titulo) + '</h3><p>' + esc(p.resumo) + '</p><span>Ler o artigo</span></a>';
}
function preencherArca(html, d) {
  const ms = arcas(d), px = parcelasArca(d);
  const val = (k, f) => {
    const m = ms[k]; if (!m) return null;
    return { preco: brl0(m.preco), parcelas: 'ou em até ' + px + 'x de ' + brl2(m.preco / px) + ' sem juros', medidas: m.medidas, prazo: m.prazo }[f];
  };
  html = html.replace(/(<(span|small) data-mod="(\w+)" data-k="(\w+)">)[^<]*(<\/\2>)/g, (t, a, tag, k, f, b) => { const v = val(k, f); return v == null ? t : a + esc(v) + b; });
  Object.keys(ms).forEach(k => {
    if (!ms[k].esgotado) return;
    html = html.replace(new RegExp('<button class="btn btn-champ" type="button" data-abrir data-modelo="' + k + '">[^<]*</button>'),
      '<button class="btn btn-champ" type="button" data-abrir data-modelo="' + k + '" disabled style="opacity:.45">Esgotado</button>');
  });
  return html;
}

/* ---------- dados estruturados ---------- */
const ORG = { '@id': DOMINIO + '/#org' };
function disponibilidade(ok) { return ok ? 'https://schema.org/InStock' : 'https://schema.org/OutOfStock'; }
function ldProduto(d, p) {
  const url = DOMINIO + '/loja/' + p.slug, disp = disponivel(p), vs = p.variantes || [];
  const imagens = fotos(d, p, null).map(abs).concat(vs.map(v => abs(foto(d, p, v)))).filter((x, i, a) => a.indexOf(x) === i);
  let oferta;
  if (vs.length && !mesmoPreco(p)) {
    const ps = vs.map(v => Number(v.preco));
    oferta = { '@type': 'AggregateOffer', priceCurrency: 'BRL', lowPrice: Math.min.apply(null, ps).toFixed(2), highPrice: Math.max.apply(null, ps).toFixed(2), offerCount: vs.length,
      availability: disponibilidade(disp), url,
      offers: vs.map(v => ({ '@type': 'Offer', name: v.nome, price: Number(v.preco).toFixed(2), priceCurrency: 'BRL', availability: disponibilidade(disp && varOk(p, v)), url: url + '?opcao=' + encodeURIComponent(v.id), itemCondition: 'https://schema.org/NewCondition', seller: ORG })) };
  } else {
    oferta = { '@type': 'Offer', price: precoBase(p).toFixed(2), priceCurrency: 'BRL', availability: disponibilidade(disp), url, itemCondition: 'https://schema.org/NewCondition', seller: ORG };
  }
  return { '@type': 'Product', '@id': url + '#produto', name: p.nome, description: p.seo_descricao || p.texto || p.frase || '', image: imagens, sku: p.slug,
    brand: { '@type': 'Brand', name: 'ARA' }, url, category: 'Objetos de ritual com cristais', offers: oferta };
}
function ldArcas(d) {
  const ms = arcas(d);
  return Object.keys(ms).map(k => {
    const m = ms[k];
    return { '@type': 'Product', '@id': DOMINIO + '/arca#' + k, name: m.nome + ' · caixa de cristais personalizada', description: m.descricao, image: [abs(m.foto)], sku: 'arca-' + k,
      brand: { '@type': 'Brand', name: 'ARA' }, url: DOMINIO + '/arca', category: 'Caixa de cristais personalizada',
      offers: { '@type': 'Offer', price: Number(m.preco).toFixed(2), priceCurrency: 'BRL', availability: disponibilidade(!m.esgotado), url: DOMINIO + '/arca', itemCondition: 'https://schema.org/NewCondition', seller: ORG } };
  });
}
function ldPost(d, p) {
  const url = DOMINIO + '/blog/' + p.slug;
  return { '@type': 'BlogPosting', '@id': url + '#artigo', headline: p.titulo, description: p.seo_descricao || p.resumo || '', inLanguage: 'pt-BR',
    datePublished: p.data || undefined, dateModified: dia(p.atualizado_em) || p.data || undefined, mainEntityOfPage: url, url,
    image: abs(p.foto_url || '/og-image.jpg'), author: ORG, publisher: ORG };
}

/* ---------- montagem por endereço ---------- */
async function renderizar(rota, params) {
  const d = await dados();
  let html = template();
  const partes = String(rota || '').split('/').filter(Boolean), base = partes[0] || 'inicio', slug = partes[1];
  const seo = d.seo[base] || d.seo.inicio || {};
  let status = 200, o;
  if (base === 'loja' && slug) {
    const p = d.produtos.filter(x => x.slug === slug)[0];
    const novo = !p && ENDERECOS_ANTIGOS[slug];
    if (novo && d.produtos.some(x => x.slug === novo)) {
      /* a Vercel acrescenta rota/secao/slug da reescrita; ficam fora do endereço novo */
      const q = params && params.toString ? new URLSearchParams([...params].filter(kv => ['rota', 'secao', 'slug'].indexOf(kv[0]) < 0)).toString() : '';
      return { status: 301, location: '/loja/' + novo + (q ? '?' + q : ''), html: '' };
    }
    if (!p) { status = 404; o = { titulo: 'Produto não encontrado | ARA', descricao: seo.descricao, url: DOMINIO + '/loja', robots: 'noindex,follow' }; }
    else {
      const v = opcaoInicial(p, params && params.get && params.get('opcao'));
      const img = foto(d, p, null);
      o = { titulo: p.seo_titulo || (p.nome + ' | ARA'), descricao: p.seo_descricao || p.frase || p.texto || '', url: DOMINIO + '/loja/' + p.slug, ogTipo: 'product',
        imagem: img, imgW: /\/img\/loja\//.test(img) ? 1000 : 0, imgH: 1000, alt: p.nome, preco: v ? v.preco : p.preco,
        ld: [ldProduto(d, p), migalhas([['Início', '/'], ['Loja', '/loja'], [p.nome, '/loja/' + p.slug]])] };
      html = html.replace('<div id="lj-lista">', '<div id="lj-lista" hidden>').replace('<div id="lj-produto" hidden></div>', '<div id="lj-produto">' + htmlProduto(d, p, v) + '</div>');
    }
  } else if (base === 'loja') {
    o = { titulo: seo.titulo, descricao: seo.descricao, url: DOMINIO + '/loja',
      imagem: capaLoja(d), imgW: 1000, imgH: 1000, alt: 'Loja ARA',
      ld: [{ '@type': 'CollectionPage', '@id': DOMINIO + '/loja#pagina', name: seo.titulo, url: DOMINIO + '/loja', isPartOf: { '@id': DOMINIO + '/#site' },
        mainEntity: { '@type': 'ItemList', itemListElement: d.produtos.map((p, i) => ({ '@type': 'ListItem', position: i + 1, url: DOMINIO + '/loja/' + p.slug, name: p.nome })) } },
        migalhas([['Início', '/'], ['Loja', '/loja']])] };
    html = html.replace('<div id="lj-grade"></div>', '<div id="lj-grade">' + gradeLoja(d) + '</div>');
  } else if (base === 'blog' && slug) {
    const p = d.posts.filter(x => x.slug === slug)[0];
    if (!p) { status = 404; o = { titulo: 'Artigo não encontrado | ARA', descricao: seo.descricao, url: DOMINIO + '/blog', robots: 'noindex,follow' }; }
    else {
      o = { titulo: p.seo_titulo || (p.titulo + ' | ARA'), descricao: p.seo_descricao || p.resumo || '', url: DOMINIO + '/blog/' + p.slug, ogTipo: 'article',
        imagem: p.foto_url || '', ld: [ldPost(d, p), migalhas([['Início', '/'], ['Blog', '/blog'], [p.titulo, '/blog/' + p.slug]])] };
      html = html.replace('<div id="bl-lista">', '<div id="bl-lista" hidden>').replace('<article id="bl-post" class="bl-post" hidden></article>', '<article id="bl-post" class="bl-post">' + htmlPost(d, p) + '</article>');
    }
  } else if (base === 'blog') {
    o = { titulo: seo.titulo, descricao: seo.descricao, url: DOMINIO + '/blog',
      ld: [{ '@type': 'Blog', '@id': DOMINIO + '/blog#blog', name: seo.titulo, url: DOMINIO + '/blog', inLanguage: 'pt-BR', publisher: ORG,
        blogPost: d.posts.map(p => ({ '@type': 'BlogPosting', headline: p.titulo, url: DOMINIO + '/blog/' + p.slug, datePublished: p.data || undefined })) },
        migalhas([['Início', '/'], ['Blog', '/blog']])] };
    html = html.replace('<div class="bl-grade" id="bl-grade"></div>', '<div class="bl-grade" id="bl-grade">' + d.posts.map(p => cardPost(d, p)).join('') + '</div>');
  } else if (base === 'arca') {
    const ms = arcas(d);
    o = { titulo: seo.titulo, descricao: seo.descricao, url: DOMINIO + '/arca', ogTipo: 'product', imagem: ms.atelie.foto, imgW: 1400, imgH: 1011, alt: 'Arca ARA, caixa de madeira e vidro com cristais',
      preco: ms.essencial.preco, ld: ldArcas(d).concat([migalhas([['Início', '/'], ['A Arca', '/arca']])]) };
  } else if (base === 'historia') {
    o = { titulo: seo.titulo, descricao: seo.descricao, url: DOMINIO + '/historia',
      ld: [{ '@type': 'AboutPage', '@id': DOMINIO + '/historia#pagina', name: seo.titulo, url: DOMINIO + '/historia', about: ORG }, migalhas([['Início', '/'], ['Nossa história', '/historia']])] };
  } else {
    return { status: 200, html: injetarDados(preencherArca(html, d), d) };
  }
  html = aplicarHead(html, o);
  html = mostrarView(html, base);
  html = preencherArca(html, d);
  html = injetarDados(html, d);
  return { status, html };
}

/* ---------- sitemap (Google) ---------- */
async function sitemap() {
  const d = await dados();
  const ms = arcas(d);
  const img = (u, t) => '<image:image><image:loc>' + xml(abs(u)) + '</image:loc>' + (t ? '<image:title>' + xml(t) + '</image:title>' : '') + '</image:image>';
  const url = (loc, lastmod, imgs) => '<url><loc>' + xml(DOMINIO + loc) + '</loc>' + (lastmod ? '<lastmod>' + lastmod + '</lastmod>' : '') + (imgs || '') + '</url>';
  const ultimo = lista => lista.map(x => dia(x.atualizado_em) || x.data || '').filter(Boolean).sort().pop() || '';
  const html = template();
  const casa = (html.match(/\/img\/arca-cristais-na-sala\.[0-9a-f]{8}\.jpg/) || [])[0];
  const linhas = [
    url('/', '', casa ? img(casa, 'Arca ARA com cristais numa sala') : ''),
    url('/arca', '', Object.keys(ms).map(k => img(ms[k].foto, ms[k].nome)).join('')),
    url('/loja', ultimo(d.produtos)),
  ].concat(d.produtos.map(p => url('/loja/' + p.slug, dia(p.atualizado_em), ilustrativa(foto(d, p, null)) ? '' : fotos(d, p, null).map(u => img(u, p.nome)).join(''))))
    .concat([url('/blog', ultimo(d.posts))])
    .concat(d.posts.map(p => url('/blog/' + p.slug, dia(p.atualizado_em) || p.data || '')))
    .concat([url('/historia', '')]);
  return '<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:image="http://www.google.com/schemas/sitemap-image/1.1">\n' + linhas.join('\n') + '\n</urlset>\n';
}

/* ---------- feed de produtos (Google Merchant Center e catálogo do Instagram/Facebook) ---------- */
async function feed() {
  const d = await dados();
  /* sem a retaguarda não dá para garantir estoque e preço: melhor o Google manter o feed anterior */
  if (!d.okProd || !d.config.length) { const e = new Error('retaguarda indisponível'); e.status = 503; throw e; }
  const itens = [];
  const item = o => ilustrativa(o.imagem) ? '' : '<item>' +
    '<g:id>' + xml(o.id) + '</g:id>' + (o.grupo ? '<g:item_group_id>' + xml(o.grupo) + '</g:item_group_id>' : '') +
    '<g:title>' + xml(o.titulo) + '</g:title><g:description>' + xml(o.descricao) + '</g:description>' +
    '<g:link>' + xml(o.link) + '</g:link><g:image_link>' + xml(abs(o.imagem)) + '</g:image_link>' +
    (o.extras || []).map(u => '<g:additional_image_link>' + xml(abs(u)) + '</g:additional_image_link>').join('') +
    '<g:availability>' + (o.ok ? 'in_stock' : 'out_of_stock') + '</g:availability>' +
    '<g:price>' + Number(o.preco).toFixed(2) + ' BRL</g:price>' +
    '<g:brand>ARA</g:brand><g:condition>new</g:condition><g:identifier_exists>no</g:identifier_exists>' +
    '<g:google_product_category>696</g:google_product_category><g:product_type>' + xml(o.tipo) + '</g:product_type>' +
    '</item>';
  const ms = arcas(d);
  Object.keys(ms).forEach(k => {
    const m = ms[k];
    itens.push(item({ id: 'arca-' + k, titulo: m.nome + ' · Caixa de cristais personalizada ARA', descricao: m.descricao, link: DOMINIO + '/arca', imagem: m.foto,
      ok: !m.esgotado, preco: m.preco, tipo: 'Arca > Caixa de cristais personalizada' }));
  });
  d.produtos.forEach(p => {
    const vs = p.variantes || [], desc = texto(p.texto || p.seo_descricao || p.frase);
    if (!vs.length) {
      itens.push(item({ id: p.slug, titulo: p.nome + ' · ARA', descricao: desc, link: DOMINIO + '/loja/' + p.slug, imagem: foto(d, p, null), extras: fotos(d, p, null).slice(1), ok: disponivel(p), preco: p.preco, tipo: cristal(p) ? 'Loja > Cristais' : 'Loja > Objetos de ritual' }));
    } else {
      vs.forEach(v => {
        itens.push(item({ id: p.slug + '-' + v.id, grupo: p.slug, titulo: p.nome + ' · ' + v.nome + ' · ARA', descricao: desc + (v.pedras ? ' Acompanha ' + v.pedras + '.' : ''),
          link: DOMINIO + '/loja/' + p.slug + '?opcao=' + encodeURIComponent(v.id), imagem: foto(d, p, v), ok: disponivel(p) && varOk(p, v), preco: v.preco, tipo: cristal(p) ? 'Loja > Cristais' : 'Loja > Objetos de ritual' }));
      });
    }
  });
  return '<?xml version="1.0" encoding="UTF-8"?>\n<rss version="2.0" xmlns:g="http://base.google.com/ns/1.0"><channel>' +
    '<title>ARA · Cristais de autor</title><link>' + DOMINIO + '</link><description>Caixas de cristais personalizadas e objetos de ritual da ARA.</description>\n' +
    itens.filter(Boolean).join('\n') + '\n</channel></rss>\n';
}

module.exports = { renderizar, sitemap, feed, template, prepararTemplate, rpc, DOMINIO };
