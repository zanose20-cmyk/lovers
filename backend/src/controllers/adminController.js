const User = require('../models/User');
const Room = require('../models/Room');
const Gift = require('../models/Gift');
const Agency = require('../models/Agency');
const Post = require('../models/Post');
const Notification = require('../models/Notification');
const WalletTransaction = require('../models/WalletTransaction');
const AdminLog = require('../models/AdminLog');
const VIPLevel = require('../models/VIPLevel');
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
    
    const allowedFields = ['roles', 'isVerified', 'level', 'chargeLevel', 'activityLevel', 'personalBadge', 'specialBadges', 'banned', 'banReason'];
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

async function seedVIPLevels(req, res) {
  try {
    const vipData = [
      { level: 1, name: 'VIP 1 - برونزي', color: '#CD7F32', badge: { key: 'vip1', label: 'VIP 1', color: '#CD7F32' }, frame: { key: 'vip1_frame', label: 'VIP 1 Frame', color: '#CD7F32' }, benefits: ['شارة VIP 1', 'إطار VIP 1', 'تأثير دخول بسيط'], priceCoins: 100, priceCoins3Months: 90, priceCoins12Months: 70, durationDays: 30, requirements: { minChargeLevel: 100, minActivityLevel: 1, minDaysActive: 1 } },
      { level: 2, name: 'VIP 2 - فضي', color: '#C0C0C0', badge: { key: 'vip2', label: 'VIP 2', color: '#C0C0C0' }, frame: { key: 'vip2_frame', label: 'VIP 2 Frame', color: '#C0C0C0' }, benefits: ['شارة VIP 2', 'إطار VIP 2', 'تأثير دخول فضي'], priceCoins: 500, priceCoins3Months: 450, priceCoins12Months: 350, durationDays: 30, requirements: { minChargeLevel: 500, minActivityLevel: 5, minDaysActive: 3 } },
      { level: 3, name: 'VIP 3 - ذهبي', color: '#FFD700', badge: { key: 'vip3', label: 'VIP 3', color: '#FFD700' }, frame: { key: 'vip3_frame', label: 'VIP 3 Frame', color: '#FFD700' }, benefits: ['شارة VIP 3', 'إطار VIP 3', 'تأثير دخول ذهبي'], priceCoins: 1500, priceCoins3Months: 1350, priceCoins12Months: 1050, durationDays: 30, requirements: { minChargeLevel: 1500, minActivityLevel: 10, minDaysActive: 7 } },
      { level: 4, name: 'VIP 4 - بلاتيني', color: '#E5E4E2', badge: { key: 'vip4', label: 'VIP 4', color: '#E5E4E2' }, frame: { key: 'vip4_frame', label: 'VIP 4 Frame', color: '#E5E4E2' }, benefits: ['شارة VIP 4', 'إطار VIP 4', 'تأثير دخول بلاتيني'], priceCoins: 3000, priceCoins3Months: 2700, priceCoins12Months: 2100, durationDays: 30, requirements: { minChargeLevel: 3000, minActivityLevel: 20, minDaysActive: 14 } },
      { level: 5, name: 'VIP 5 - الماسي', color: '#B9F2FF', badge: { key: 'vip5', label: 'VIP 5', color: '#B9F2FF' }, frame: { key: 'vip5_frame', label: 'VIP 5 Frame', color: '#B9F2FF' }, benefits: ['شارة VIP 5', 'إطار VIP 5', 'تأثير دخول ماسي'], priceCoins: 6000, priceCoins3Months: 5400, priceCoins12Months: 4200, durationDays: 30, requirements: { minChargeLevel: 6000, minActivityLevel: 40, minDaysActive: 21 } },
      { level: 6, name: 'VIP 6 - الياقوتي', color: '#E0115F', badge: { key: 'vip6', label: 'VIP 6', color: '#E0115F' }, frame: { key: 'vip6_frame', label: 'VIP 6 Frame', color: '#E0115F' }, benefits: ['شارة VIP 6', 'إطار VIP 6', 'تأثير دخول ياقوتي'], priceCoins: 12000, priceCoins3Months: 10800, priceCoins12Months: 8400, durationDays: 30, requirements: { minChargeLevel: 12000, minActivityLevel: 60, minDaysActive: 30 } },
      { level: 7, name: 'VIP 7 - الزمردي', color: '#50C878', badge: { key: 'vip7', label: 'VIP 7', color: '#50C878' }, frame: { key: 'vip7_frame', label: 'VIP 7 Frame', color: '#50C878' }, benefits: ['شارة VIP 7', 'إطار VIP 7', 'تأثير دخول زمردي'], priceCoins: 25000, priceCoins3Months: 22500, priceCoins12Months: 17500, durationDays: 30, requirements: { minChargeLevel: 25000, minActivityLevel: 80, minDaysActive: 45 } },
      { level: 8, name: 'VIP 8 - الياقوت الأزرق', color: '#0F52BA', badge: { key: 'vip8', label: 'VIP 8', color: '#0F52BA' }, frame: { key: 'vip8_frame', label: 'VIP 8 Frame', color: '#0F52BA' }, benefits: ['شارة VIP 8', 'إطار VIP 8', 'تأثير دخول ياقوت أزرق'], priceCoins: 50000, priceCoins3Months: 45000, priceCoins12Months: 35000, durationDays: 30, requirements: { minChargeLevel: 50000, minActivityLevel: 100, minDaysActive: 60 } },
      { level: 9, name: 'VIP 9 - التاج الملكي', color: '#FF2400', badge: { key: 'vip9', label: 'VIP 9', color: '#FF2400' }, frame: { key: 'vip9_frame', label: 'VIP 9 Frame', color: '#FF2400' }, benefits: ['شارة VIP 9', 'إطار VIP 9', 'تأثير دخول تاج ملكي'], priceCoins: 100000, priceCoins3Months: 90000, priceCoins12Months: 70000, durationDays: 30, requirements: { minChargeLevel: 100000, minActivityLevel: 150, minDaysActive: 90 } },
      { level: 10, name: 'VIP 10 - الأسطوري', color: '#FFD700', badge: { key: 'vip10', label: 'VIP 10', color: '#FFD700' }, frame: { key: 'vip10_frame', label: 'VIP 10 Frame', color: '#FFD700' }, entryEffect: 'legendary_entry', benefits: ['شارة VIP 10 الأسطورية', 'تأثير دخول أسطوري'], priceCoins: 500000, priceCoins3Months: 450000, priceCoins12Months: 350000, durationDays: 30, requirements: { minChargeLevel: 500000, minActivityLevel: 300, minDaysActive: 180 } },
    ];

    let count = 0;
    for (const data of vipData) {
      await VIPLevel.findOneAndUpdate({ level: data.level }, { $set: data }, { upsert: true });
      count++;
    }

    logAdminAction(req.user.userId, 'seed_vip_levels', 'system', null, { count }, req);
    res.json({ ok: true, message: `Seeded ${count} VIP levels` });
  } catch (err) {
    logger.error('seedVIPLevels error', err);
    res.status(500).json({ error: 'Failed to seed VIP levels' });
  }
}

module.exports = {
  getDashboardStats, getRealtimeStats,
  listUsers, updateUser, banUser, unbanUser,
  listRooms, deleteRoom,
  listGifts,
  listReports,
  getAdminLogs,
  seedVIPLevels,
};
