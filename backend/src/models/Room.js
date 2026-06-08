const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid');

const SeatSchema = new mongoose.Schema({
  index: Number,
  userId: String,
  displayName: String,
  avatarUrl: String,
  isMuted: { type: Boolean, default: false },
  isLocked: { type: Boolean, default: false },
  joinedAt: Date,
});

const RoomSchema = new mongoose.Schema({
  roomId: { type: String, default: () => uuidv4(), unique: true },
  title: String,
  ownerId: String,
  ownerName: String,
  type: { type: String, enum: ['public', 'private', 'vip', 'agency'], default: 'public' },
  password: String,
  capacity: { type: Number, default: 12 },
  maxCapacity: { type: Number, default: 20 },
  isLocked: { type: Boolean, default: false },
  seats: [SeatSchema],
  moderators: [String],
  coOwners: [String],
  metadata: mongoose.Schema.Types.Mixed,
  background: { type: String },
  entranceEffects: { type: String },
  ads: [String],
  logs: [mongoose.Schema.Types.Mixed], // admin logs and events
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

RoomSchema.pre('save', function (next) {
  this.updatedAt = new Date();
  next();
});

module.exports = mongoose.model('Room', RoomSchema);
