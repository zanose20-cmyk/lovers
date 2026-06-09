const mongoose = require('mongoose');
const config = require('../config');
const User = require('../models/User');

async function seed() {
  await mongoose.connect(config.mongoUri);
  console.log('Connected to MongoDB for seeding admin');

  const email = process.env.ADMIN_EMAIL || 'admin@example.com';
  const existing = await User.findOne({ email });
  if (existing) {
    console.log('Admin user already exists:', existing.userId);
    process.exit(0);
  }

  const adminUser = new User({
    userId: `admin-${Date.now()}`,
    displayName: 'Super Admin',
    email,
    roles: ['admin', 'superadmin'],
    isVerified: true
  });
  await adminUser.save();
  console.log('Admin user created:', adminUser.userId);
  process.exit(0);
}

seed().catch((err) => { console.error(err); process.exit(1); });
