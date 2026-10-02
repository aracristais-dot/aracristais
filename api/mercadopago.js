'use strict';
/* Aviso do Mercado Pago (webhook): quando um pagamento muda, o Mercado Pago chama este endereço.
   O site confere o pagamento direto no Mercado Pago (ara_confirmar_pagamento) e atualiza o pedido e o estoque.
   Assim o pedido vira "pago" mesmo que o cliente feche a página e ninguém esteja com a retaguarda aberta.
   Nada do que chega aqui é aceito sem essa conferência: o aviso só diz qual pagamento olhar. */
const ara = require('./_ara');

module.exports = async (req, res) => {
  try {
    const q = req.query || {};
    let b = req.body || {};
    if (typeof b === 'string') { try { b = JSON.parse(b); } catch (e) { b = {}; } }
    const tipo = String(q.type || q.topic || b.type || b.topic || b.action || '');
    const id = String((b.data && b.data.id) || q['data.id'] || q.id || '');
    if (/payment/.test(tipo) && /^\d{1,20}$/.test(id)) {
      await ara.prepararTemplate();
      const r = await ara.rpc('ara_confirmar_pagamento', { p_pedido: null, p_payment_id: id });
      console.log('ARA aviso Mercado Pago:', id, r && r.status);
    }
  } catch (e) {
    console.error('ARA aviso Mercado Pago:', e);
  }
  res.statusCode = 200;
  res.setHeader('Content-Type', 'text/plain; charset=utf-8');
  res.end('ok');
};
