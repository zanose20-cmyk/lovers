const VIPLevel = require('../models/VIPLevel');
const User = require('../models/User');
const WalletTransaction = require('../models/WalletTransaction');
const Notification = require('../models/Notification');
const logger = require('../utils/logger');

async function getVIPLevels(req, res) {
  try {
    const levels = await VIPLevel.find({ isActive: true }).sort({ level: 1 }).lean();
    res.json({ levels });
  } catch (err) {
    logger.error('getVIPLevels error', err);
    res.status(500).json({ error: 'Failed to get VIP levels' });
  }
}

async function getVIPStatus(req, res) {
  try {
    const userId = req.user.userId;
    const user = await User.findOne({ userId }).select('vipLevel vipExpiresAt chargeLevel level').lean();
    if (!user) return res.status(404).json({ error: 'User not found' });

    const now = new Date();
    const expiresAt = user.vipExpiresAt ? new Date(user.vipExpiresAt) : null;
    const isActive = expiresAt && expiresAt > now;
    const isExpired = expiresAt && expiresAt <= now;
    const daysRemaining = isActive ? Math.ceil((expiresAt - now) / (1000 * 60 * 60 * 24)) : 0;
    const hoursRemaining = isActive ? Math.ceil((expiresAt - now) / (1000 * 60 * 60)) : 0;

    const currentLevel = await VIPLevel.findOne({ level: user.vipLevel || 0 }).lean();

    res.json({
      vipLevel: user.vipLevel || 0,
      isActive,
      isExpired,
      expiresAt: expiresAt ? expiresAt.toISOString() : null,
      daysRemaining,
      hoursRemaining,
      chargeLevel: user.chargeLevel || 0,
      level: user.level || 1,
      currentLevel
    });
  } catch (err) {
    logger.error('getVIPStatus error', err);
    res.status(500).json({ error: 'Failed to get VIP status' });
  }
}

async function purchaseVIP(req, res) {
  try {
    const userId = req.user.userId;
    const { level, duration } = req.body;
    
    if (!level || level < 1 || level > 10) {
      return res.status(400).json({ error: 'Invalid VIP level (1-10)' });
    }
    
    if (duration && !['1', '3', '12'].includes(String(duration))) {
      return res.status(400).json({ error: 'Invalid duration (1, 3, or 12 months)' });
    }
    
    const vip = await VIPLevel.findOne({ level, isActive: true });
    if (!vip) return res.status(404).json({ error: 'VIP level not found' });
    
    const user = await User.findOne({ userId });
    if (!user) return res.status(404).json({ error: 'User not found' });

    const months = parseInt(duration) || 1;
    let cost;
    let days;

    if (months === 1) {
      cost = vip.priceCoins || 0;
      days = vip.durationDays || 30;
    } else if (months === 3) {
      cost = vip.priceCoins3Months || (vip.priceCoins * 3 * 0.9);
      days = 90;
    } else {
      cost = vip.priceCoins12Months || (vip.priceCoins * 12 * 0.7);
      days = 365;
    }
    cost = Math.round(cost);

    if ((user.chargeLevel || 0) < cost) {
      return res.status(400).json({ error: 'Insufficient coins', required: cost, balance: user.chargeLevel || 0 });
    }

    user.chargeLevel = (user.chargeLevel || 0) - cost;
    user.level = Math.max(user.level || 0, level);
    user.vipLevel = Math.max(user.vipLevel || 0, level);

    const existingExpiry = user.vipExpiresAt ? new Date(user.vipExpiresAt) : new Date();
    const baseDate = existingExpiry > new Date() ? existingExpiry : new Date();
    user.vipExpiresAt = new Date(baseDate.getTime() + days * 24 * 60 * 60 * 1000);

    user.personalBadge = {
      key: `vip${level}`,
      label: `VIP ${level}`,
      color: vip.color
    };
    
    user.specialBadges = user.specialBadges || [];
    const existingBadge = user.specialBadges.find(b => b.key === `vip${level}`);
    if (!existingBadge && vip.badge) {
      user.specialBadges.push(vip.badge);
    }
    
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
      metadata: { vipLevel: level, duration: months, days }
    });
    await tx.save();

    const notif = new Notification({
      userId,
      type: 'vip',
      title: 'ترقية VIP',
      body: `تم ترقيةك إلى VIP ${level} لمدة ${months} شهر`,
      data: { vipLevel: level, duration: months }
    });
    await notif.save();
    
    res.json({
      ok: true,
      currentVIP: level,
      duration: months,
      days,
      cost,
      expiresAt: user.vipExpiresAt,
      user: {
        userId: user.userId,
        vipLevel: user.vipLevel,
        vipExpiresAt: user.vipExpiresAt,
        chargeLevel: user.chargeLevel,
        level: user.level,
        personalBadge: user.personalBadge
      }
    });
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
    const allowedFields = ['name', 'priceCoins', 'priceCoins3Months', 'priceCoins12Months', 'priceDiamonds', 'durationDays', 'isActive', 'perks', 'badge', 'meta'];
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
  getVIPLevels, getVIPStatus, getUserVIP, purchaseVIP,
  createVIPLevel, updateVIPLevel
};
