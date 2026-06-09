const VIPLevel = require('../models/VIPLevel');
const User = require('../models/User');
const WalletTransaction = require('../models/WalletTransaction');
const Notification = require('../models/Notification');
const logger = require('../utils/logger');

async function getVIPLevels(req, res) {
  try {
    const levels = await VIPLevel.find({ isActive: true }).sort({ level: 1 }).lean();
    res.json(levels);
  } catch (err) {
    logger.error('getVIPLevels error', err);
    res.status(500).json({ error: 'Failed to get VIP levels' });
  }
}

async function getUserVIP(req, res) {
  try {
    const userId = req.params.userId || req.user.userId;
    const user = await User.findOne({ userId }).select('level chargeLevel activityLevel personalBadge specialBadges frames vehicles').lean();
    if (!user) return res.status(404).json({ error: 'User not found' });
    
    const levels = await VIPLevel.find({ isActive: true }).sort({ level: 1 }).lean();
    
    let currentVIP = 0;
    let nextVIP = null;
    
    for (let i = 0; i < levels.length; i++) {
      const level = levels[i];
      if (user.chargeLevel >= level.requirements.minChargeLevel) {
        currentVIP = level.level;
        nextVIP = levels[i + 1] || null;
      }
    }
    
    res.json({
      currentVIP,
      nextVIP,
      chargeLevel: user.chargeLevel,
      activityLevel: user.activityLevel,
      level: user.level,
      badges: {
        personalBadge: user.personalBadge,
        specialBadges: user.specialBadges
      },
      frames: user.frames,
      vehicles: user.vehicles
    });
  } catch (err) {
    logger.error('getUserVIP error', err);
    res.status(500).json({ error: 'Failed to get VIP info' });
  }
}

async function purchaseVIP(req, res) {
  try {
    const userId = req.user.userId;
    const { level } = req.body;
    
    if (!level || level < 1 || level > 10) {
      return res.status(400).json({ error: 'Invalid VIP level (1-10)' });
    }
    
    const vip = await VIPLevel.findOne({ level, isActive: true });
    if (!vip) return res.status(404).json({ error: 'VIP level not found' });
    
    const user = await User.findOne({ userId });
    if (!user) return res.status(404).json({ error: 'User not found' });
    
    const cost = vip.priceCoins;
    if ((user.chargeLevel || 0) < cost) {
      return res.status(400).json({ error: 'Insufficient coins' });
    }
    
    user.chargeLevel = (user.chargeLevel || 0) - cost;
    user.level = Math.max(user.level || 0, level);
    user.vipLevel = Math.max(user.vipLevel || 0, level);
    user.vipExpiresAt = new Date(Date.now() + (vip.durationDays || 30) * 24 * 60 * 60 * 1000);
    user.personalBadge = {
      key: `vip${level}`,
      label: `VIP ${level}`,
      color: vip.color
    };
    
    // Add VIP badge to special badges
    user.specialBadges = user.specialBadges || [];
    const existingBadge = user.specialBadges.find(b => b.key === `vip${level}`);
    if (!existingBadge) {
      user.specialBadges.push(vip.badge);
    }
    
    // Add VIP frame
    if (vip.frame) {
      user.frames = user.frames || [];
      const existingFrame = user.frames.find(f => f.key === `vip${level}_frame`);
      if (!existingFrame) {
        user.frames.push(vip.frame);
      }
    }
    
    await user.save();
    
    const tx = new WalletTransaction({
      userId,
      type: 'transfer',
      amountCoins: cost,
      status: 'ok',
      metadata: { vipLevel: level }
    });
    await tx.save();
    
    res.json({ ok: true, currentVIP: level, user });
  } catch (err) {
    logger.error('purchaseVIP error', err);
    res.status(500).json({ error: 'Failed to purchase VIP' });
  }
}

async function createVIPLevel(req, res) {
  try {
    const vip = new VIPLevel(req.body);
    await vip.save();
    res.json({ ok: true, vip });
  } catch (err) {
    if (err.code === 11000) {
      return res.status(400).json({ error: 'VIP level already exists' });
    }
    logger.error('createVIPLevel error', err);
    res.status(500).json({ error: 'Failed to create VIP level' });
  }
}

async function updateVIPLevel(req, res) {
  try {
    const { level } = req.params;
    const body = req.body || {};
    const allowedFields = ['name', 'priceCoins', 'priceDiamonds', 'durationDays', 'isActive', 'perks', 'badge', 'meta'];
    const updates = {};
    for (const f of allowedFields) {
      if (body[f] !== undefined) updates[f] = body[f];
    }
    const vip = await VIPLevel.findOneAndUpdate(
      { level: parseInt(level) },
      { $set: updates },
      { new: true }
    );
    if (!vip) return res.status(404).json({ error: 'VIP level not found' });
    res.json({ ok: true, vip });
  } catch (err) {
    logger.error('updateVIPLevel error', err);
    res.status(500).json({ error: 'Failed to update VIP level' });
  }
}

module.exports = {
  getVIPLevels, getUserVIP, purchaseVIP,
  createVIPLevel, updateVIPLevel
};
