const mongoose = require('mongoose');
const config = require('../config');
const Gift = require('../models/Gift');

const sampleGifts = [
  {
    sku: 'rose_01',
    name: 'Red Rose',
    type: 'animated',
    rarity: 'common',
    priceCoins: 5,
    imageUrl: '/assets/gifts/rose.png',
    animationUrl: '/assets/gifts/rose_anim.json',
    entryEffect: 'sparkle',
    prices: { coins: 5 }
  },
  {
    sku: 'teddy_01',
    name: 'Teddy',
    type: 'animated',
    rarity: 'rare',
    priceCoins: 50,
    imageUrl: '/assets/gifts/teddy.png',
    animationUrl: '/assets/gifts/teddy_anim.json',
    entryEffect: 'bounce',
    prices: { coins: 50 }
  },
  {
    sku: 'jet_legend',
    name: 'Private Jet',
    type: '3d',
    rarity: 'legendary',
    priceCoins: 1000,
    imageUrl: '/assets/gifts/jet.png',
    asset3dUrl: '/assets/gifts/jet.glb',
    fullscreenEffect: true,
    entryEffect: 'flyin',
    prices: { coins: 1000 }
  }
];

async function seed() {
  await mongoose.connect(config.mongoUri, { useNewUrlParser: true, useUnifiedTopology: true });
  console.log('Connected to MongoDB for seeding gifts');
  for (const g of sampleGifts) {
    try {
      await Gift.updateOne({ sku: g.sku }, { $set: g }, { upsert: true });
      console.log('Upserted', g.sku);
    } catch (e) {
      console.error('Failed to upsert', g.sku, e.message);
    }
  }
  console.log('Seeding completed');
  process.exit(0);
}

seed().catch((err) => { console.error(err); process.exit(1); });
