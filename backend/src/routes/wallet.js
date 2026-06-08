const express = require('express');
const router = express.Router();
const { getTransactions, recharge, withdraw } = require('../controllers/walletController');
const { requireAuth } = require('../middleware/authMiddleware');

router.get('/wallet/transactions', requireAuth, getTransactions);
router.post('/wallet/recharge', requireAuth, recharge);
router.post('/wallet/withdraw', requireAuth, withdraw);

module.exports = router;
