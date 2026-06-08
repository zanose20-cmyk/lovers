const User = require('../models/User');
const Room = require('../models/Room');
const Gift = require('../models/Gift');
const Agency = require('../models/Agency');
const Post = require('../models/Post');
const Notification = require('../models/Notification');
const WalletTransaction = require('../models/WalletTransaction');
const AdminLog = require('../models/AdminLog');
const logger = require('../utils/logger');

function logAdminAction(adminId, action, targetType, targetId, details, req) {
  const log = new AdminLog({
    adminId,
    action,
    targetType,
    targetId,
    details,
    ip: req.ip,
    userAgent: req.headers['user-agent']
  });
  log.save().catch(err => logger.error('AdminLog error', err));
}

async function getDashboardStats(req, res) {
  try {
    const [totalUsers, totalRooms, totalGifts, totalAgencies, totalPosts, activeUsers, pendingReports] = await Promise.all([
      User.countDocuments(),
      Room.countDocuments(),
      Gift.countDocuments(),
      Agency.countDocuments({ isActive: true }),
      Post.countDocuments({ isDeleted: false }),
      User.countDocuments({ lastActiveAt: { $gte: new Date(Date.now() - 24 * 60 * 60 * 1000) } }),
      0 // placeholder for reports
    ]);
    
    const revenue = await WalletTransaction.aggregate([
      { $match: { type: 'recharge', status: 'ok' } },
      { $group: { _id: null, total: { $sum: '$amountCoins' } } }
    ]);
    
    res.json({
      totalUsers,
      totalRooms,
      totalGifts,
      totalAgencies,
      totalPosts,
      activeUsers24h: activeUsers,
      totalRevenue: revenue.length > 0 ? revenue[0].total : 0,
      pendingReports
    });
  } catch (err) {
    logger.error('getDashboardStats error', err);
    res.status(500).json({ error: 'Failed to get stats' });
  }
}

async function getRealtimeStats(req, res) {
  try {
    const now = new Date();
    const lastHour = new Date(now - 60 * 60 * 1000);
    
    const [newUsers, newRooms, transactions, activeSockets] = await Promise.all([
      User.countDocuments({ createdAt: { $gte: lastHour } }),
      Room.countDocuments({ createdAt: { $gte: lastHour } }),
      WalletTransaction.countDocuments({ createdAt: { $gte: lastHour } }),
      0 // placeholder for connected sockets
    ]);
    
    res.json({
      newUsersLastHour: newUsers,
      newRoomsLastHour: newRooms,
      transactionsLastHour: transactions,
      activeConnections: activeSockets,
      timestamp: now
    });
  } catch (err) {
    logger.error('getRealtimeStats error', err);
    res.status(500).json({ error: 'Failed to get realtime stats' });
  }
}

async function listUsers(req, res) {
  try {
    const { page = 1, limit = 50, search, role, isVerified } = req.query;
    const filter = {};
    
    if (search) {
      filter.$or = [
        { displayName: new RegExp(search, 'i') },
        { userId: new RegExp(search, 'i') },
        { email: new RegExp(search, 'i') },
        { phoneNumber: new RegExp(search, 'i') }
      ];
    }
    if (role) filter.roles = role;
    if (isVerified !== undefined) filter.isVerified = isVerified === 'true';
    
    const users = await User.find(filter)
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(parseInt(limit))
      .lean();
    
    const total = await User.countDocuments(filter);
    
    res.json({ users, total, page: parseInt(page), pages: Math.ceil(total / limit) });
  } catch (err) {
    logger.error('listUsers error', err);
    res.status(500).json({ error: 'Failed to list users' });
  }
}

async function updateUser(req, res) {
  try {
    const { userId } = req.params;
    const updates = req.body;
    const adminId = req.user.userId;
    
    const allowedFields = ['roles', 'isVerified', 'level', 'chargeLevel', 'activityLevel', 'personalBadge', 'specialBadges', 'banned'];
    const filtered = {};
    for (const field of allowedFields) {
      if (updates[field] !== undefined) filtered[field] = updates[field];
    }
    
    const user = await User.findOneAndUpdate({ userId }, { $set: filtered }, { new: true });
    if (!user) return res.status(404).json({ error: 'User not found' });
    
    logAdminAction(adminId, 'user_updated', 'user', userId, JSON.stringify(filtered), req);
    
    res.json({ ok: true, user });
  } catch (err) {
    logger.error('updateUser error', err);
    res.status(500).json({ error: 'Failed to update user' });
  }
}

async function banUser(req, res) {
  try {
    const { userId } = req.params;
    const { reason, permanent = false, durationHours = 24 } = req.body;
    const adminId = req.user.userId;
    
    const user = await User.findOne({ userId });
    if (!user) return res.status(404).json({ error: 'User not found' });
    
    if (user.roles.includes('admin')) {
      return res.status(403).json({ error: 'Cannot ban an admin' });
    }
    
    user.banned = {
      isBanned: true,
      reason: reason || 'Violation of terms',
      bannedBy: adminId,
      bannedAt: new Date(),
      expiresAt: permanent ? null : new Date(Date.now() + durationHours * 60 * 60 * 1000)
    };
    
    await user.save();
    
    logAdminAction(adminId, 'user_banned', 'user', userId, reason || 'No reason', req);
    
    // Notify user
    const notif = new Notification({
      userId,
      type: 'system',
      title: 'تم حظر حسابك',
      body: `تم حظر حسابك. السبب: ${reason || 'مخالفة الشروط'}`,
      data: { banned: true }
    });
    await notif.save();
    
    res.json({ ok: true });
  } catch (err) {
    logger.error('banUser error', err);
    res.status(500).json({ error: 'Failed to ban user' });
  }
}

async function unbanUser(req, res) {
  try {
    const { userId } = req.params;
    const adminId = req.user.userId;
    
    const user = await User.findOne({ userId });
    if (!user) return res.status(404).json({ error: 'User not found' });
    
    user.banned = { isBanned: false };
    await user.save();
    
    logAdminAction(adminId, 'user_unbanned', 'user', userId, 'User unbanned', req);
    
    res.json({ ok: true });
  } catch (err) {
    logger.error('unbanUser error', err);
    res.status(500).json({ error: 'Failed to unban user' });
  }
}

async function listRooms(req, res) {
  try {
    const { page = 1, limit = 50, type } = req.query;
    const filter = {};
    if (type) filter.type = type;
    
    const rooms = await Room.find(filter)
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(parseInt(limit))
      .lean();
    
    const total = await Room.countDocuments(filter);
    
    res.json({ rooms, total, page: parseInt(page), pages: Math.ceil(total / limit) });
  } catch (err) {
    logger.error('listRooms error', err);
    res.status(500).json({ error: 'Failed to list rooms' });
  }
}

async function deleteRoom(req, res) {
  try {
    const { roomId } = req.params;
    const adminId = req.user.userId;
    
    await Room.deleteOne({ roomId });
    
    logAdminAction(adminId, 'room_deleted', 'room', roomId, 'Room deleted by admin', req);
    
    res.json({ ok: true });
  } catch (err) {
    logger.error('deleteRoom error', err);
    res.status(500).json({ error: 'Failed to delete room' });
  }
}

async function listGifts(req, res) {
  try {
    const { page = 1, limit = 50 } = req.query;
    const gifts = await Gift.find()
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(parseInt(limit))
      .lean();
    
    const total = await Gift.countDocuments();
    
    res.json({ gifts, total, page: parseInt(page), pages: Math.ceil(total / limit) });
  } catch (err) {
    logger.error('listGifts error', err);
    res.status(500).json({ error: 'Failed to list gifts' });
  }
}

async function listReports(req, res) {
  try {
    // Placeholder - implement reports model as needed
    res.json({ reports: [], total: 0 });
  } catch (err) {
    logger.error('listReports error', err);
    res.status(500).json({ error: 'Failed to list reports' });
  }
}

async function getAdminLogs(req, res) {
  try {
    const { page = 1, limit = 100 } = req.query;
    const logs = await AdminLog.find()
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(parseInt(limit))
      .lean();
    
    const total = await AdminLog.countDocuments();
    
    res.json({ logs, total, page: parseInt(page) });
  } catch (err) {
    logger.error('getAdminLogs error', err);
    res.status(500).json({ error: 'Failed to get logs' });
  }
}

module.exports = {
  getDashboardStats, getRealtimeStats,
  listUsers, updateUser, banUser, unbanUser,
  listRooms, deleteRoom,
  listGifts,
  listReports,
  getAdminLogs
};
