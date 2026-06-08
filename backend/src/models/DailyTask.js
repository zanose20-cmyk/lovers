const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid');

const DailyTaskSchema = new mongoose.Schema({
  taskId: { type: String, default: () => uuidv4(), unique: true },
  title: { type: String, required: true },
  description: String,
  type: { 
    type: String, 
    enum: ['daily_login', 'activity_hours', 'send_gifts', 'join_rooms', 'invite_friends', 'watch_ads', 'share_content'],
    required: true 
  },
  reward: {
    coins: { type: Number, default: 0 },
    diamonds: { type: Number, default: 0 },
    xp: { type: Number, default: 0 }
  },
  requirement: {
    target: { type: Number, default: 1 },
    unit: String
  },
  icon: String,
  isActive: { type: Boolean, default: true },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('DailyTask', DailyTaskSchema);
