const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid');

const DeviceSchema = new mongoose.Schema({
  deviceId: String,
  platform: String,
  lastSeenAt: Date,
});

const VehicleSchema = new mongoose.Schema({
  sku: String,
  name: String,
  type: String, // car, plane, yacht, legendary
  expiresAt: Date,
  meta: mongoose.Schema.Types.Mixed,
});

const BadgeSchema = new mongoose.Schema({
  key: String,
  label: String,
  color: String,
});

const UserSchema = new mongoose.Schema({
  uid: { type: String, index: true }, // Firebase uid
  userId: { type: String, default: () => uuidv4(), unique: true },
  displayName: { type: String },
  phoneNumber: { type: String },
  email: { type: String, index: true },
  avatarUrl: { type: String },
  coverUrl: { type: String },
  level: { type: Number, default: 1 },
  chargeLevel: { type: Number, default: 0 },
  activityLevel: { type: Number, default: 0 },
  gender: { type: String, enum: ['male', 'female', 'other'] },
  age: { type: Number },
  country: { type: String },
  bio: { type: String },

  followers: [String],
  followersCount: { type: Number, default: 0 },
  following: [String],
  followingCount: { type: Number, default: 0 },
  friends: [String],
  friendsCount: { type: Number, default: 0 },

  giftsReceivedCount: { type: Number, default: 0 },
  giftsSentCount: { type: Number, default: 0 },

  personalBadge: BadgeSchema,
  specialBadges: [BadgeSchema],

  vehicles: [VehicleSchema],
  frames: [BadgeSchema],

  vipLevel: { type: Number, default: 0 },
  vipExpiresAt: { type: Date },

  isVerified: { type: Boolean, default: false },
  verificationBadge: BadgeSchema,

  roles: { type: [String], default: ['user'] },
  banned: {
    isBanned: { type: Boolean, default: false },
    reason: String,
    bannedBy: String,
    bannedAt: Date,
    expiresAt: Date
  },

  devices: [DeviceSchema],

  settings: { type: mongoose.Schema.Types.Mixed },

  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now },
  lastActiveAt: { type: Date }
});

UserSchema.pre('save', function (next) {
  this.updatedAt = new Date();
  next();
});

module.exports = mongoose.model('User', UserSchema);
