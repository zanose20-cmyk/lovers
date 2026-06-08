const mongoose = require('mongoose');

const UserDailyProgressSchema = new mongoose.Schema({
  userId: { type: String, required: true },
  date: { type: String, required: true }, // YYYY-MM-DD
  tasks: [{
    taskId: String,
    progress: { type: Number, default: 0 },
    target: { type: Number, default: 1 },
    completed: { type: Boolean, default: false },
    claimed: { type: Boolean, default: false }
  }],
  dailyLogin: { type: Boolean, default: false },
  loginStreak: { type: Number, default: 0 },
  lastLoginDate: String,
  activityMinutes: { type: Number, default: 0 },
  giftsSent: { type: Number, default: 0 },
  roomsJoined: { type: Number, default: 0 },
  invitesSent: { type: Number, default: 0 },
  coinsEarned: { type: Number, default: 0 },
  xpEarned: { type: Number, default: 0 },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

UserDailyProgressSchema.index({ userId: 1, date: 1 }, { unique: true });

UserDailyProgressSchema.pre('save', function (next) {
  this.updatedAt = new Date();
  next();
});

module.exports = mongoose.model('UserDailyProgress', UserDailyProgressSchema);
