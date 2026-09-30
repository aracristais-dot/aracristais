'use strict';
/* /feed.xml: catálogo de produtos para o Google Merchant Center (Google Shopping) e o catálogo do Instagram/Facebook. */
const ara = require('./_ara');

module.exports = async (req, res) => {
  try {
    const x = await ara.feed();
    res.statusCode = 200;
    res.setHeader('Content-Type', 'application/xml; charset=utf-8');
    res.setHeader('Cache-Control', 'public, max-age=0, s-maxage=3600, stale-while-revalidate=86400');
    res.end(x);
  } catch (e) {
    console.error('ARA feed:', e);
    res.statusCode = e.status || 500;
    res.setHeader('Retry-After', '600');
    res.end('indisponível');
  }
};
