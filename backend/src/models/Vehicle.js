const mongoose = require('mongoose');

const VehicleSchema = new mongoose.Schema({
  sku: { type: String, unique: true },
  name: String,
  description: String,
  type: { type: String, enum: ['car', 'plane', 'yacht', 'helicopter', 'horse', 'throne', 'legendary'], required: true },
  rarity: { type: String, enum: ['common', 'rare', 'epic', 'legendary'], default: 'common' },
  priceCoins: { type: Number, default: 0 },
  priceDiamonds: { type: Number, default: 0 },
  durationDays: { type: Number, default: 30 },
  imageUrl: String,
  animationUrl: String,
  model3dUrl: String,
  entryEffect: String,
  entryAnimationUrl: String,
  colors: [String],
  effects: mongoose.Schema.Types.Mixed,
  meta: mongoose.Schema.Types.Mixed,
  isActive: { type: Boolean, default: true },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Vehicle', VehicleSchema);
