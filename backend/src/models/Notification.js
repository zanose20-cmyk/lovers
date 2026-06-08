const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid');

const NotificationSchema = new mongoose.Schema({
  notifId: { type: String, default: () => uuidv4(), unique: true },
  userId: { type: String, required: true, index: true },
  type: { 
    type: String, 
    enum: ['gift', 'follow', 'like', 'comment', 'room_invite', 'friend_request', 'achievement', 'system', 'vip', 'agency', 'daily_reward'],
    required: true 
  },
  title: String,
  body: String,
  data: mongoose.Schema.Types.Mixed,
  imageUrl: String,
  isRead: { type: Boolean, default: false },
  readAt: Date,
  createdAt: { type: Date, default: Date.now }
});

NotificationSchema.index({ userId: 1, createdAt: -1 });
NotificationSchema.index({ createdAt: 1 }, { expireAfterSeconds: 90 * 24 * 60 * 60 }); // TTL: 90 days

module.exports = mongoose.model('Notification', NotificationSchema);
