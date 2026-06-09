const mongoose = require('mongoose');

const reportSchema = new mongoose.Schema({
  reportId: { type: String, required: true, unique: true },
  reporterId: { type: String, required: true },
  targetType: { type: String, enum: ['user', 'room', 'post', 'message'], required: true },
  targetId: { type: String, required: true },
  reason: { type: String, enum: ['spam', 'harassment', 'inappropriate', 'impersonation', 'scam', 'other'], required: true },
  description: { type: String, default: '' },
  status: { type: String, enum: ['pending', 'reviewed', 'resolved', 'dismissed'], default: 'pending' },
  adminNote: { type: String, default: '' },
  createdAt: { type: Date, default: Date.now },
  reviewedAt: Date,
  reviewedBy: String,
});

reportSchema.index({ targetType: 1, targetId: 1 });
reportSchema.index({ reporterId: 1 });
reportSchema.index({ status: 1 });

module.exports = mongoose.model('Report', reportSchema);
