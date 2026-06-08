const express = require('express');
const router = express.Router();
const { createRechargeOrder, stripeWebhook } = require('../controllers/paymentsController');
const { requireAuth } = require('../middleware/authMiddleware');

router.post('/create-order', requireAuth, createRechargeOrder);
// webhook route - expects raw body (configure in deployment)
router.post('/webhook/stripe', express.raw({ type: 'application/json' }), stripeWebhook);

module.exports = router;
