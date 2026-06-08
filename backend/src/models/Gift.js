const mongoose = require('mongoose');

const GiftSchema = new mongoose.Schema({
  sku: { type: String, unique: true },
  name: String,
  type: { type: String, enum: ['normal','animated','3d','fullscreen'], default: 'normal' },
  rarity: { type: String, enum: ['common','rare','legendary'], default: 'common' },
  // pricing can support multiple currencies and tiers
  priceCoins: { type: Number, default: 0 },
  priceDiamonds: { type: Number, default: 0 },
  prices: { type: mongoose.Schema.Types.Mixed },
  // asset URLs and effect metadata
  imageUrl: String,
  animationUrl: String,
  asset3dUrl: String,
  fullscreenEffect: { type: Boolean, default: false },
  entryEffect: String,
  effects: mongoose.Schema.Types.Mixed,
  meta: mongoose.Schema.Types.Mixed,
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Gift', GiftSchema);
