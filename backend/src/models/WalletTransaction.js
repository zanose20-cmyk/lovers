const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid');

const WalletTransactionSchema = new mongoose.Schema({
  txId: { type: String, default: () => uuidv4(), index: true },
  userId: String,
  type: { type: String, enum: ['recharge','withdraw','gift_sent','gift_received','transfer'], default: 'gift_sent' },
  amountCoins: { type: Number, default: 0 },
  amountDiamonds: { type: Number, default: 0 },
  relatedUserId: String,
  giftSku: String,
  roomId: String,
  status: { type: String, enum: ['pending','ok','failed'], default: 'ok' },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('WalletTransaction', WalletTransactionSchema);
