const { initFirebase } = require('../services/firebaseAdmin');
const User = require('../models/User');
const jwt = require('jsonwebtoken');
const config = require('../config');
const { v4: uuidv4 } = require('uuid');

initFirebase();

async function firebaseLogin(req, res) {
  const { idToken } = req.body;
  if (!idToken) return res.status(400).json({ error: 'idToken required' });
  try {
    const admin = require('firebase-admin');
    const decoded = await admin.auth().verifyIdToken(idToken);

    // upsert user
    const data = {
      uid: decoded.uid,
      displayName: decoded.name || decoded.email || 'User',
      email: decoded.email,
      phoneNumber: decoded.phone_number,
      avatarUrl: decoded.picture,
      isVerified: decoded.email_verified || false,
    };
    const user = await User.findOneAndUpdate({ uid: decoded.uid }, { $set: data }, { upsert: true, new: true });

    // create server JWT
    const token = jwt.sign({ uid: user.uid, userId: user.userId, roles: user.roles }, config.jwtSecret, { expiresIn: config.jwtExpiresIn });

    return res.json({ token, user });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'Firebase verification failed', details: err.message });
  }
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

module.exports = { firebaseLogin, createGuest, registerDevice, listDevices, revokeDevice };
