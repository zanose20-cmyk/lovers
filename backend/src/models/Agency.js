const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid');

const AgencyMemberSchema = new mongoose.Schema({
  userId: { type: String, required: true },
  role: { type: String, enum: ['owner', 'manager', 'member'], default: 'member' },
  joinedAt: { type: Date, default: Date.now },
  salary: { type: Number, default: 0 }
});

const AgencyTaskSchema = new mongoose.Schema({
  taskId: { type: String, default: () => uuidv4() },
  title: String,
  description: String,
  type: { type: String, enum: ['daily', 'weekly', 'monthly', 'special'], default: 'daily' },
  reward: { type: Number, default: 0 },
  target: mongoose.Schema.Types.Mixed,
  assignedTo: [String],
  status: { type: String, enum: ['pending', 'active', 'completed', 'cancelled'], default: 'pending' },
  createdAt: { type: Date, default: Date.now },
  completedAt: Date
});

const AgencyReportSchema = new mongoose.Schema({
  reportId: { type: String, default: () => uuidv4() },
  period: String, // e.g., "2024-01"
  totalMembers: Number,
  activeMembers: Number,
  totalGifts: Number,
  totalEarnings: Number,
  topGivers: [String],
  createdAt: { type: Date, default: Date.now }
});

const AgencySchema = new mongoose.Schema({
  agencyId: { type: String, default: () => uuidv4(), unique: true },
  name: { type: String, required: true },
  description: String,
  logo: String,
  coverImage: String,
  ownerId: { type: String, required: true },
  managers: [String],
  members: [AgencyMemberSchema],
  stats: {
    totalMembers: { type: Number, default: 0 },
    totalGiftsReceived: { type: Number, default: 0 },
    totalEarnings: { type: Number, default: 0 },
    rank: { type: Number, default: 0 }
  },
  payroll: [{
    userId: String,
    amount: Number,
    period: String,
    paidAt: Date
  }],
  tasks: [AgencyTaskSchema],
  reports: [AgencyReportSchema],
  isActive: { type: Boolean, default: true },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

AgencySchema.pre('save', function (next) {
  this.updatedAt = new Date();
  this.stats.totalMembers = (this.members || []).length;
  next();
});

module.exports = mongoose.model('Agency', AgencySchema);
