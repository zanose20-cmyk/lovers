const User = require('../models/User');
const jwt = require('jsonwebtoken');
const config = require('../config');
const { v4: uuidv4 } = require('uuid');
const https = require('https');

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
          try {
            resolve(JSON.parse(data));
          } catch (e) {
            reject(new Error('Failed to parse Google token response'));
          }
        }
      });
    }).on('error', (err) => {
      reject(err);
    });
  });
}

async function createGuest(req, res) {
  try {
    const guest = new User({
      userId: `guest-${uuidv4()}`,
      displayName: `Guest_${Math.floor(Math.random() * 10000)}`,
      roles: ['guest']
    });
    await guest.save();
    const token = jwt.sign({ userId: guest.userId, roles: guest.roles }, config.jwtSecret, { expiresIn: config.jwtExpiresIn });
    res.json({ token, user: guest });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to create guest' });
  }
}

async function registerDevice(req, res) {
  try {
    const userPayload = req.user;
    if (!userPayload) return res.status(401).json({ error: 'Unauthorized' });
    const { deviceId, platform, pushToken } = req.body;
    if (!deviceId) return res.status(400).json({ error: 'deviceId required' });

    const user = await User.findOne({ userId: userPayload.userId });
    if (!user) return res.status(404).json({ error: 'User not found' });

    // upsert device
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
    console.error('registerDevice error', err);
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

module.exports = { googleLogin, createGuest, registerDevice, listDevices, revokeDevice };
