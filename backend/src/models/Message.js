const mongoose = require('mongoose');

const MessageSchema = new mongoose.Schema({
  messageId: { type: String, index: true },
  fromUserId: String,
  toUserId: String, // for private messages
  roomId: String, // for group messages
  type: { type: String, enum: ['text','image','gif','audio','system'], default: 'text' },
  content: String,
  attachments: [mongoose.Schema.Types.Mixed],
  translatedText: String,
  isRead: { type: Boolean, default: false },
  isDeleted: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now }
});

MessageSchema.index({ fromUserId: 1, toUserId: 1 });
MessageSchema.index({ createdAt: 1 }, { expireAfterSeconds: 365 * 24 * 60 * 60 }); // TTL: 1 year

module.exports = mongoose.model('Message', MessageSchema);
