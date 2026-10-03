'use strict';
/* Entrega /historia, /arca, /loja, /loja/<produto>, /blog e /blog/<artigo> já prontos para o Google e para a prévia de links. */
const ara = require('./_ara');

module.exports = async (req, res) => {
  const u = new URL(req.url || '/', 'https://www.aracristais.com.br');
  let rota = u.searchParams.get('rota');
  if (!rota) rota = u.pathname.replace(/^\/api\/pagina\/?/, '');
  rota = decodeURIComponent(String(rota)).replace(/^\/+|\/+$/g, '');
  const host = req.headers && (req.headers['x-forwarded-host'] || req.headers.host);
  let r;
  try {
    await ara.prepararTemplate(host ? 'https://' + host : undefined);
    r = await ara.renderizar(rota, u.searchParams);
  } catch (e) {
    console.error('ARA pagina:', e);
    /* nunca deixa o cliente numa página de erro: cai no site normal, que abre a mesma página pelo navegador */
    u.searchParams.delete('rota');
    const q = u.searchParams.toString();
    res.statusCode = 302;
    res.setHeader('Location', '/' + (q ? '?' + q : '') + '#' + rota);
    res.setHeader('Cache-Control', 'no-store');
    return res.end();
  }
  if (r.location) {
    /* endereço antigo de um produto que mudou de nome */
    res.statusCode = r.status;
    res.setHeader('Location', r.location);
    res.setHeader('Cache-Control', 'public, max-age=0, s-maxage=3600');
    return res.end();
  }
  res.statusCode = r.status;
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  /* cache curto: foto, preço ou estoque mudados no painel aparecem no ar em segundos */
  res.setHeader('Cache-Control', r.status === 200 ? 'public, max-age=0, s-maxage=5, stale-while-revalidate=30' : 'public, max-age=0, s-maxage=5');
  res.end(r.html);
};
