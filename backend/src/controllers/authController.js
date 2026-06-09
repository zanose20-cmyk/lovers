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

module.exports = {
  googleLogin, facebookLogin, appleLogin,
  sendOTP, verifyOTP,
  createGuest,
  requestRecovery, verifyRecovery,
  registerDevice, listDevices, revokeDevice,
};
