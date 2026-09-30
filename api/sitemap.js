'use strict';
/* /sitemap.xml: lista para o Google todas as páginas, produtos e artigos, sempre atualizada com a retaguarda. */
const ara = require('./_ara');

module.exports = async (req, res) => {
  try {
    const host = req.headers && (req.headers['x-forwarded-host'] || req.headers.host);
    await ara.prepararTemplate(host ? 'https://' + host : undefined);
    const x = await ara.sitemap();
    res.statusCode = 200;
    res.setHeader('Content-Type', 'application/xml; charset=utf-8');
    res.setHeader('Cache-Control', 'public, max-age=0, s-maxage=3600, stale-while-revalidate=86400');
    res.end(x);
  } catch (e) {
    console.error('ARA sitemap:', e);
    res.statusCode = 500;
    res.end('erro');
  }
};
