'use strict';
/* Entrega /historia, /arca, /loja, /loja/<produto>, /blog e /blog/<artigo> já prontos para o Google e para a prévia de links. */
const ara = require('./_ara');

module.exports = async (req, res) => {
  const u = new URL(req.url || '/', 'https://aracristais.com.br');
  let rota = u.searchParams.get('rota');
  if (!rota) rota = u.pathname.replace(/^\/api\/pagina\/?/, '');
  rota = decodeURIComponent(String(rota)).replace(/^\/+|\/+$/g, '');
  let r;
  try {
    r = await ara.renderizar(rota, u.searchParams);
  } catch (e) {
    console.error('ARA pagina:', e);
    r = { status: 200, html: ara.template() };
  }
  res.statusCode = r.status;
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.setHeader('Cache-Control', r.status === 200 ? 'public, max-age=0, s-maxage=300, stale-while-revalidate=86400' : 'public, max-age=0, s-maxage=60');
  res.end(r.html);
};
