const User = require('../models/User');
const jwt = require('jsonwebtoken');
const config = require('../config');
const { v4: uuidv4 } = require('uuid');
const https = require('https');
const admin = require('firebase-admin');

// ==================== GOOGLE LOGIN ====================
async function googleLogin(req, res) {
  const { idToken } = req.body;
  if (!idToken) return res.status(400).json({ error: 'idToken required' });
  try {
    const userData = await verifyGoogleToken(idToken);
    const data = {
      uid: userData.sub,
      displayName: userData.name || userData.email || 'User',
      email: userData.email,
      avatarUrl: userData.picture,
      isVerified: userData.email_verified === 'true' || userData.email_verified === true,
    };
    const user = await User.findOneAndUpdate({ uid: userData.sub }, { $set: data }, { upsert: true, new: true });
    if (user.banned && user.banned.isBanned) {
      return res.status(403).json({ error: 'Account banned', reason: user.banned.reason || 'No reason provided' });
    }
    const token = jwt.sign({ uid: user.uid, userId: user.userId, roles: user.roles }, config.jwtSecret, { expiresIn: config.jwtExpiresIn });
    return res.json({ token, user });
  } catch (err) {
    console.error('Google login error:', err.message);
    return res.status(500).json({ error: 'Google verification failed' });
  }
}

function verifyGoogleToken(token) {
  return new Promise((resolve, reject) => {
    const url = `https://oauth2.googleapis.com/tokeninfo?id_token=${token}`;
    https.get(url, (response) => {
      let data = '';
      response.on('data', (chunk) => { data += chunk; });
      response.on('end', () => {
        if (response.statusCode !== 200) {
          reject(new Error(`Google token verification failed with status ${response.statusCode}: ${data}`));
        } else {
          try { resolve(JSON.parse(data)); } catch (e) { reject(new Error('Failed to parse Google token response')); }
        }
      });
    }).on('error', (err) => { reject(err); });
  });
}

// ==================== PHONE + OTP ====================
const otpStore = new Map();

function generateOTP() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

async function sendOTP(req, res) {
  const { phoneNumber } = req.body;
  if (!phoneNumber) return res.status(400).json({ error: 'phoneNumber required' });

  const otp = generateOTP();
  const expiresAt = Date.now() + 5 * 60 * 1000;
  otpStore.set(phoneNumber, { otp, expiresAt, attempts: 0 });

  try {
    if (admin.apps.length > 0) {
      await admin.auth().createCustomToken(`otp-${phoneNumber}`);
    }
    console.log(`[OTP] ${phoneNumber}: ${otp}`);
    res.json({ ok: true, message: 'OTP sent', expiresIn: 300 });
  } catch (err) {
    console.error('sendOTP error:', err);
    res.json({ ok: true, message: 'OTP sent (dev mode)', otp, expiresIn: 300 });
  }
}

async function verifyOTP(req, res) {
  const { phoneNumber, otp } = req.body;
  if (!phoneNumber || !otp) return res.status(400).json({ error: 'phoneNumber and otp required' });

  const stored = otpStore.get(phoneNumber);
  if (!stored) return res.status(400).json({ error: 'OTP not found. Request a new one.' });
  if (Date.now() > stored.expiresAt) { otpStore.delete(phoneNumber); return res.status(400).json({ error: 'OTP expired' }); }
  if (stored.attempts >= 5) { otpStore.delete(phoneNumber); return res.status(429).json({ error: 'Too many attempts' }); }
  stored.attempts++;

  if (stored.otp !== otp) return res.status(400).json({ error: 'Invalid OTP', attemptsLeft: 5 - stored.attempts });
  otpStore.delete(phoneNumber);

  let user = await User.findOne({ phoneNumber });
  const isNewUser = !user;
  if (!user) {
    user = new User({
      phoneNumber,
      displayName: `User_${phoneNumber.slice(-4)}`,
      roles: ['user'],
    });
  }
  user.lastActiveAt = new Date();
  await user.save();

  const token = jwt.sign({ userId: user.userId, roles: user.roles }, config.jwtSecret, { expiresIn: config.jwtExpiresIn });
  res.json({ token, user, isNewUser });
}

// ==================== FACEBOOK LOGIN ====================
async function facebookLogin(req, res) {
  const { accessToken, userID } = req.body;
  if (!accessToken || !userID) return res.status(400).json({ error: 'accessToken and userID required' });

  try {
    const fbUser = await verifyFacebookToken(accessToken, userID);
    let user = await User.findOne({ uid: fbUser.id });
    if (!user) {
      user = await User.findOne({ email: fbUser.email });
    }
    if (!user) {
      user = new User({
        uid: fbUser.id,
        displayName: fbUser.name || 'Facebook User',
        email: fbUser.email,
        avatarUrl: fbUser.picture?.data?.url,
      });
    } else {
      user.uid = user.uid || fbUser.id;
      user.avatarUrl = user.avatarUrl || fbUser.picture?.data?.url;
      user.displayName = user.displayName || fbUser.name;
    }
    user.lastActiveAt = new Date();
    await user.save();

    if (user.banned && user.banned.isBanned) {
      return res.status(403).json({ error: 'Account banned', reason: user.banned.reason });
    }

    const token = jwt.sign({ uid: user.uid, userId: user.userId, roles: user.roles }, config.jwtSecret, { expiresIn: config.jwtExpiresIn });
    res.json({ token, user });
  } catch (err) {
    console.error('Facebook login error:', err.message);
    res.status(500).json({ error: 'Facebook verification failed' });
  }
}

function verifyFacebookToken(accessToken, userID) {
  return new Promise((resolve, reject) => {
    const url = `https://graph.facebook.com/me?fields=id,name,email,picture.width(200)&access_token=${accessToken}`;
    https.get(url, (response) => {
      let data = '';
      response.on('data', (chunk) => { data += chunk; });
      response.on('end', () => {
        if (response.statusCode !== 200) return reject(new Error('Facebook verification failed'));
        try { resolve(JSON.parse(data)); } catch (e) { reject(new Error('Failed to parse Facebook response')); }
      });
    }).on('error', reject);
  });
}

// ==================== APPLE LOGIN ====================
async function appleLogin(req, res) {
  const { identityToken, user: appleUser } = req.body;
  if (!identityToken) return res.status(400).json({ error: 'identityToken required' });

  try {
    const payload = decodeAppleToken(identityToken);
    let user = await User.findOne({ uid: payload.sub });
    if (!user) {
      user = await User.findOne({ email: payload.email });
    }
    if (!user) {
      user = new User({
        uid: payload.sub,
        displayName: appleUser?.name ? `${appleUser.name.firstName || ''} ${appleUser.name.lastName || ''}`.trim() : 'Apple User',
        email: payload.email,
      });
    } else {
      user.uid = user.uid || payload.sub;
    }
    user.lastActiveAt = new Date();
    await user.save();

    if (user.banned && user.banned.isBanned) {
      return res.status(403).json({ error: 'Account banned', reason: user.banned.reason });
    }

    const token = jwt.sign({ uid: user.uid, userId: user.userId, roles: user.roles }, config.jwtSecret, { expiresIn: config.jwtExpiresIn });
    res.json({ token, user });
  } catch (err) {
    console.error('Apple login error:', err.message);
    res.status(500).json({ error: 'Apple verification failed' });
  }
}

function decodeAppleToken(token) {
  const parts = token.split('.');
  if (parts.length !== 3) throw new Error('Invalid Apple token');
  return JSON.parse(Buffer.from(parts[1], 'base64').toString('utf8'));
}

// ==================== GUEST LOGIN ====================
async function createGuest(req, res) {
  try {
    const guest = new User({
      userId: `guest-${uuidv4()}`,
      displayName: `Guest_${Math.floor(Math.random() * 10000)}`,
      roles: ['guest'],
    });
    await guest.save();
    const token = jwt.sign({ userId: guest.userId, roles: guest.roles }, config.jwtSecret, { expiresIn: config.jwtExpiresIn });
    res.json({ token, user: guest });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to create guest' });
  }
}

// ==================== ACCOUNT RECOVERY ====================
async function requestRecovery(req, res) {
  const { identifier } = req.body;
  if (!identifier) return res.status(400).json({ error: 'Phone or email required' });

  const user = await User.findOne({ $or: [{ phoneNumber: identifier }, { email: identifier }] });
  if (!user) return res.json({ ok: true, message: 'If an account exists, a recovery code has been sent' });

  if (user.phoneNumber) {
    const otp = generateOTP();
    otpStore.set(`recovery-${user.phoneNumber}`, { otp, expiresAt: Date.now() + 10 * 60 * 1000, userId: user.userId });
    console.log(`[RECOVERY] ${user.phoneNumber}: ${otp}`);
    return res.json({ ok: true, method: 'phone', message: 'Recovery code sent', otp });
  }
  if (user.email) {
    console.log(`[RECOVERY EMAIL] ${user.email}`);
    return res.json({ ok: true, method: 'email', message: 'Recovery email sent' });
  }
  res.status(400).json({ error: 'No recovery method available' });
}

async function verifyRecovery(req, res) {
  const { identifier, otp, newPassword } = req.body;
  if (!identifier || !otp) return res.status(400).json({ error: 'identifier and otp required' });

  const stored = otpStore.get(`recovery-${identifier}`);
  if (!stored || stored.otp !== otp) return res.status(400).json({ error: 'Invalid recovery code' });
  if (Date.now() > stored.expiresAt) { otpStore.delete(`recovery-${identifier}`); return res.status(400).json({ error: 'Recovery code expired' }); }
  otpStore.delete(`recovery-${identifier}`);

  res.json({ ok: true, message: 'Account recovered. You can now login.' });
}

// ==================== DEVICE MANAGEMENT ====================
async function registerDevice(req, res) {
  try {
    const userPayload = req.user;
    if (!userPayload) return res.status(401).json({ error: 'Unauthorized' });
    const { deviceId, platform, pushToken } = req.body;
    if (!deviceId) return res.status(400).json({ error: 'deviceId required' });

    const user = await User.findOne({ userId: userPayload.userId });
    if (!user) return res.status(404).json({ error: 'User not found' });

    const existing = (user.devices || []).find(d => d.deviceId === deviceId);
    if (existing) {
      existing.lastSeenAt = new Date();
      existing.platform = platform || existing.platform;
      existing.pushToken = pushToken || existing.pushToken;
    } else {
      user.devices = user.devices || [];
      user.devices.push({ deviceId, platform, lastSeenAt: new Date(), pushToken });
    }
    await user.save();
    res.json({ ok: true, devices: user.devices });
  } catch (err) {
    console.error('registerDevice error:', err);
    res.status(500).json({ error: 'Failed to register device' });
  }
}

async function listDevices(req, res) {
  try {
    const userPayload = req.user;
    if (!userPayload) return res.status(401).json({ error: 'Unauthorized' });
    const user = await User.findOne({ userId: userPayload.userId }).lean();
    if (!user) return res.status(404).json({ error: 'User not found' });
    return res.json({ devices: user.devices || [] });
  } catch (err) {
    console.error('listDevices error', err);
    res.status(500).json({ error: 'Failed to list devices' });
  }
}

async function revokeDevice(req, res) {
  try {
    const userPayload = req.user;
    if (!userPayload) return res.status(401).json({ error: 'Unauthorized' });
    const { deviceId } = req.body;
    if (!deviceId) return res.status(400).json({ error: 'deviceId required' });
    const user = await User.findOne({ userId: userPayload.userId });
    if (!user) return res.status(404).json({ error: 'User not found' });
    user.devices = (user.devices || []).filter(d => d.deviceId !== deviceId);
    await user.save();
    res.json({ ok: true });
  } catch (err) {
    console.error('revokeDevice error', err);
    res.status(500).json({ error: 'Failed to revoke device' });
  }
}

async function publicSeedVIP(req, res) {
  try {
    const { secretKey } = req.body;
    if (secretKey !== 'lovers2025seed') return res.status(403).json({ error: 'Invalid key' });
    const VIPLevel = require('../models/VIPLevel');
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
    res.json({ ok: true, message: `Seeded ${count} VIP levels` });
  } catch (err) {
    console.error('publicSeedVIP error', err);
    res.status(500).json({ error: 'Failed to seed VIP levels' });
  }
}

module.exports = {
  googleLogin, facebookLogin, appleLogin,
  sendOTP, verifyOTP,
  createGuest,
  requestRecovery, verifyRecovery,
  registerDevice, listDevices, revokeDevice,
  publicSeedVIP,
};
