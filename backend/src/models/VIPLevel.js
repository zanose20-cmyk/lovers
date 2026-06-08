const mongoose = require('mongoose');

const VIPLevelSchema = new mongoose.Schema({
  level: { type: Number, unique: true, required: true }, // 1-10
  name: String,
  badge: {
    key: String,
    label: String,
    color: String,
    imageUrl: String
  },
  frame: {
    key: String,
    label: String,
    color: String,
    imageUrl: String
  },
  entryEffect: String,
  entryAnimationUrl: String,
  color: String,
  benefits: [String],
  requirements: {
    minChargeLevel: { type: Number, default: 0 },
    minActivityLevel: { type: Number, default: 0 },
    minDaysActive: { type: Number, default: 0 }
  },
  priceCoins: { type: Number, default: 0 },
  priceDiamonds: { type: Number, default: 0 },
  isActive: { type: Boolean, default: true },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('VIPLevel', VIPLevelSchema);
