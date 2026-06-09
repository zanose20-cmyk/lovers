const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid');

const FriendRequestSchema = new mongoose.Schema({
  requestId: { type: String, default: () => uuidv4(), unique: true },
  fromUserId: { type: String, required: true },
  toUserId: { type: String, required: true },
  status: { type: String, enum: ['pending', 'accepted', 'rejected', 'cancelled'], default: 'pending' },
  createdAt: { type: Date, default: Date.now },
  respondedAt: { type: Date }
});

FriendRequestSchema.index({ fromUserId: 1, toUserId: 1 });
FriendRequestSchema.index({ toUserId: 1, status: 1 });

module.exports = mongoose.model('FriendRequest', FriendRequestSchema);
