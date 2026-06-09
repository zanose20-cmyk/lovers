const WalletTransaction = require('../models/WalletTransaction');
const User = require('../models/User');
const logger = require('../utils/logger');

async function getTransactions(req, res) {
  try {
    const userId = req.user.userId;
    const txs = await WalletTransaction.find({ userId }).sort({ createdAt: -1 }).limit(200).lean();
    res.json(txs);
  } catch (err) {
    logger.error('getTransactions error', err);
    res.status(500).json({ error: 'Failed to fetch transactions' });
  }
}

async function recharge(req, res) {
  try {
    return res.status(403).json({ error: 'Recharge is disabled. Use payment provider.' });
  } catch (err) {
    logger.error('recharge error', err);
    res.status(500).json({ error: 'Failed to recharge' });
  }
}

async function withdraw(req, res) {
  try {
    const userId = req.user.userId;
    const { amountCoins = 0 } = req.body;
    const amount = parseInt(amountCoins);
    if (!amount || amount <= 0 || amount > 100000) return res.status(400).json({ error: 'Invalid amount' });
    const user = await User.findOne({ userId });
    if (!user) return res.status(404).json({ error: 'User not found' });
    if ((user.chargeLevel || 0) < amount) return res.status(400).json({ error: 'Insufficient balance' });
    user.chargeLevel = (user.chargeLevel || 0) - amount;
    await user.save();
    const tx = new WalletTransaction({ userId, type: 'withdraw', amountCoins: amount });
    await tx.save();
    res.json({ ok: true, txId: tx.txId });
  } catch (err) {
    logger.error('withdraw error', err);
    res.status(500).json({ error: 'Failed to withdraw' });
  }
}

module.exports = { getTransactions, recharge, withdraw };
