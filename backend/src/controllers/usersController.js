const User = require('../models/User');
const Agency = require('../models/Agency');
const Post = require('../models/Post');
const Notification = require('../models/Notification');
const logger = require('../utils/logger');

async function getProfile(req, res) {
  try {
    const { userId } = req.params;
    const user = await User.findOne({ userId }).lean();
    if (!user) return res.status(404).json({ error: 'User not found' });
    
    // Remove sensitive data
    delete user.devices;
    delete user.settings;
    
    res.json({ user });
  } catch (err) {
    logger.error('getProfile error', err);
    res.status(500).json({ error: 'Failed to get profile' });
  }
}

async function updateProfile(req, res) {
  try {
    const userPayload = req.user;
    const allowedFields = ['displayName', 'avatarUrl', 'coverUrl', 'bio', 'gender', 'age', 'country', 'settings'];
    const updates = {};
    
    for (const field of allowedFields) {
      if (req.body[field] !== undefined) {
        updates[field] = req.body[field];
      }
    }
    
    const user = await User.findOneAndUpdate(
      { userId: userPayload.userId },
      { $set: updates },
      { new: true }
    );
    
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.json({ ok: true, user });
  } catch (err) {
    logger.error('updateProfile error', err);
    res.status(500).json({ error: 'Failed to update profile' });
  }
}

async function searchUsers(req, res) {
  try {
    const { q, page = 1, limit = 20 } = req.query;
    if (!q) return res.status(400).json({ error: 'Query required' });
    
    const escaped = q.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const regex = new RegExp(escaped, 'i');
    const cappedLimit = Math.min(parseInt(limit) || 20, 50);
    const users = await User.find({
      $or: [
        { displayName: regex },
        { userId: regex },
        { email: regex }
      ]
    })
    .select('userId displayName avatarUrl level country isVerified')
    .skip((page - 1) * cappedLimit)
    .limit(cappedLimit)
    .lean();
    
    const total = await User.countDocuments({
      $or: [
        { displayName: regex },
        { userId: regex },
        { email: regex }
      ]
    });

    const Post = require('../models/Post');
    const hashtags = await Post.aggregate([
      { $unwind: '$hashtags' },
      { $match: { hashtags: regex } },
      { $group: { _id: '$hashtags', count: { $sum: 1 } } },
      { $sort: { count: -1 } },
      { $limit: 20 }
    ]);
    
    res.json({ users, total, page: parseInt(page), pages: Math.ceil(total / limit), hashtags: hashtags.map(h => ({ tag: h._id, count: h.count })) });
  } catch (err) {
    logger.error('searchUsers error', err);
    res.status(500).json({ error: 'Failed to search users' });
  }
}

async function followUser(req, res) {
  try {
    const { userId } = req.params;
    const currentUserId = req.user.userId;
    
    if (userId === currentUserId) {
      return res.status(400).json({ error: 'Cannot follow yourself' });
    }
    
    const targetUser = await User.findOne({ userId });
    const currentUser = await User.findOne({ userId: currentUserId });
    
    if (!targetUser || !currentUser) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    // Check if already following
    const alreadyFollowing = await User.findOne({
      userId: currentUserId,
      following: userId
    });
    
    if (alreadyFollowing) {
      return res.status(400).json({ error: 'Already following this user' });
    }
    
    await User.updateOne(
      { userId: currentUserId },
      { $inc: { followingCount: 1 }, $push: { following: userId } }
    );
    
    await User.updateOne(
      { userId },
      { $inc: { followersCount: 1 }, $push: { followers: currentUserId } }
    );
    
    // Create notification
    const notif = new Notification({
      userId,
      type: 'follow',
      title: 'متابعة جديدة',
      body: `${currentUser.displayName} بدأ متابعتك`,
      data: { userId: currentUserId, displayName: currentUser.displayName }
    });
    await notif.save();
    
    res.json({ ok: true });
  } catch (err) {
    logger.error('followUser error', err);
    res.status(500).json({ error: 'Failed to follow user' });
  }
}

async function unfollowUser(req, res) {
  try {
    const { userId } = req.params;
    const currentUserId = req.user.userId;
    
    const currentUser = await User.findOne({ userId: currentUserId });
    if (!currentUser || !(currentUser.following || []).includes(userId)) {
      return res.json({ ok: true });
    }
    
    await User.updateOne(
      { userId: currentUserId },
      { $inc: { followingCount: -1 }, $pull: { following: userId } }
    );
    
    await User.updateOne(
      { userId },
      { $inc: { followersCount: -1 }, $pull: { followers: currentUserId } }
    );
    
    res.json({ ok: true });
  } catch (err) {
    logger.error('unfollowUser error', err);
    res.status(500).json({ error: 'Failed to unfollow user' });
  }
}

async function getFollowers(req, res) {
  try {
    const { userId } = req.params;
    const { page = 1, limit = 20 } = req.query;
    
    const user = await User.findOne({ userId })
      .select('followers')
      .lean();
    
    if (!user) return res.status(404).json({ error: 'User not found' });
    
    const followers = await User.find({
      userId: { $in: user.followers || [] }
    })
    .select('userId displayName avatarUrl level isVerified')
    .skip((page - 1) * limit)
    .limit(parseInt(limit))
    .lean();
    
    res.json({ followers, total: (user.followers || []).length });
  } catch (err) {
    logger.error('getFollowers error', err);
    res.status(500).json({ error: 'Failed to get followers' });
  }
}

async function getFollowing(req, res) {
  try {
    const { userId } = req.params;
    const { page = 1, limit = 20 } = req.query;
    
    const user = await User.findOne({ userId })
      .select('following')
      .lean();
    
    if (!user) return res.status(404).json({ error: 'User not found' });
    
    const following = await User.find({
      userId: { $in: user.following || [] }
    })
    .select('userId displayName avatarUrl level isVerified')
    .skip((page - 1) * limit)
    .limit(parseInt(limit))
    .lean();
    
    res.json({ following, total: (user.following || []).length });
  } catch (err) {
    logger.error('getFollowing error', err);
    res.status(500).json({ error: 'Failed to get following' });
  }
}

async function addFriend(req, res) {
  try {
    const { userId } = req.params;
    const currentUserId = req.user.userId;
    
    const targetUser = await User.findOne({ userId });
    const currentUser = await User.findOne({ userId: currentUserId });
    
    if (!targetUser || !currentUser) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    await User.updateOne(
      { userId: currentUserId },
      { $inc: { friendsCount: 1 }, $addToSet: { friends: userId } }
    );
    
    await User.updateOne(
      { userId },
      { $inc: { friendsCount: 1 }, $addToSet: { friends: currentUserId } }
    );
    
    const notif = new Notification({
      userId,
      type: 'friend_request',
      title: 'طلب صداقة',
      body: `${currentUser.displayName} أضافك كصديق`,
      data: { userId: currentUserId, displayName: currentUser.displayName }
    });
    await notif.save();
    
    res.json({ ok: true });
  } catch (err) {
    logger.error('addFriend error', err);
    res.status(500).json({ error: 'Failed to add friend' });
  }
}

async function getNotifications(req, res) {
  try {
    const userId = req.user.userId;
    const { page = 1, limit = 50 } = req.query;
    
    const notifications = await Notification.find({ userId })
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(parseInt(limit))
      .lean();
    
    const total = await Notification.countDocuments({ userId });
    const unread = await Notification.countDocuments({ userId, isRead: false });
    
    res.json({ notifications, total, unread, page: parseInt(page) });
  } catch (err) {
    logger.error('getNotifications error', err);
    res.status(500).json({ error: 'Failed to get notifications' });
  }
}

async function markNotificationRead(req, res) {
  try {
    const { notifId } = req.params;
    const userId = req.user.userId;
    
    await Notification.updateOne(
      { notifId, userId },
      { $set: { isRead: true, readAt: new Date() } }
    );
    
    res.json({ ok: true });
  } catch (err) {
    logger.error('markNotificationRead error', err);
    res.status(500).json({ error: 'Failed to mark notification' });
  }
}

async function markAllNotificationsRead(req, res) {
  try {
    const userId = req.user.userId;
    
    await Notification.updateMany(
      { userId, isRead: false },
      { $set: { isRead: true, readAt: new Date() } }
    );
    
    res.json({ ok: true });
  } catch (err) {
    logger.error('markAllNotificationsRead error', err);
    res.status(500).json({ error: 'Failed to mark all notifications' });
  }
}

async function getUserVIPStatus(req, res) {
  try {
    const { userId } = req.params;
    const user = await User.findOne({ userId }).select('level chargeLevel activityLevel personalBadge specialBadges frames').lean();
    if (!user) return res.status(404).json({ error: 'User not found' });
    
    const VIPLevel = require('../models/VIPLevel');
    const vipLevels = await VIPLevel.find({ isActive: true }).sort({ level: 1 }).lean();
    
    // Determine current VIP level based on chargeLevel
    let currentVIP = 0;
    for (const vip of vipLevels) {
      if (user.chargeLevel >= vip.requirements.minChargeLevel) {
        currentVIP = vip.level;
      }
    }
    
    res.json({
      currentVIP,
      chargeLevel: user.chargeLevel,
      activityLevel: user.activityLevel,
      level: user.level,
      personalBadge: user.personalBadge,
      specialBadges: user.specialBadges,
      frames: user.frames
    });
  } catch (err) {
    logger.error('getUserVIPStatus error', err);
    res.status(500).json({ error: 'Failed to get VIP status' });
  }
}

module.exports = {
  getProfile,
  updateProfile,
  searchUsers,
  followUser,
  unfollowUser,
  getFollowers,
  getFollowing,
  addFriend,
  getNotifications,
  markNotificationRead,
  markAllNotificationsRead,
  getUserVIPStatus
};
