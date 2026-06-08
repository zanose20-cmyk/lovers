const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid');

const AdminLogSchema = new mongoose.Schema({
  logId: { type: String, default: () => uuidv4(), unique: true },
  adminId: String,
  adminName: String,
  action: { type: String, required: true },
  targetType: { type: String, enum: ['user', 'room', 'gift', 'agency', 'post', 'payment', 'report', 'system'] },
  targetId: String,
  details: String,
  metadata: mongoose.Schema.Types.Mixed,
  ip: String,
  userAgent: String,
  createdAt: { type: Date, default: Date.now }
});

AdminLogSchema.index({ createdAt: -1 });
AdminLogSchema.index({ adminId: 1, createdAt: -1 });

module.exports = mongoose.model('AdminLog', AdminLogSchema);
