const Room = require('../models/Room');
const User = require('../models/User');
const Notification = require('../models/Notification');
const config = require('../config');
const logger = require('../utils/logger');

let generateRtcToken;
try { generateRtcToken = require('../services/agora').generateRtcToken; } catch (e) { generateRtcToken = null; }

async function createRoom(req, res) {
  try {
    const userPayload = req.user;
    const { title, type = 'public', password, capacity = 12, maxCapacity = 20, background, entranceEffects } = req.body;
    
    if (!title) return res.status(400).json({ error: 'Title required' });
    if (!['public', 'private', 'vip', 'agency'].includes(type)) {
      return res.status(400).json({ error: 'Invalid room type' });
    }
    
    const user = await User.findOne({ userId: userPayload.userId });
    if (!user) return res.status(404).json({ error: 'User not found' });
    
    const room = new Room({
      title,
      type,
      password: type === 'private' ? password : undefined,
      capacity: Math.min(capacity, maxCapacity),
      maxCapacity,
      ownerId: user.userId,
      ownerName: user.displayName,
      background,
      entranceEffects,
      seats: [{ index: 0, userId: user.userId, displayName: user.displayName, avatarUrl: user.avatarUrl, joinedAt: new Date() }],
      moderators: [user.userId],
      coOwners: [],
      metadata: {}
    });
    
    room.logs.push({
      action: 'room_created',
      userId: user.userId,
      timestamp: new Date(),
      details: `Room created by ${user.displayName}`
    });
    
    await room.save();
    
    res.json({ ok: true, room });
  } catch (err) {
    logger.error('createRoom error', err);
    res.status(500).json({ error: 'Failed to create room', details: err.message });
  }
}

async function getRoom(req, res) {
  try {
    const { roomId } = req.params;
    const room = await Room.findOne({ roomId }).lean();
    if (!room) return res.status(404).json({ error: 'Room not found' });
    delete room.password;
    res.json(room);
  } catch (err) {
    logger.error('getRoom error', err);
    res.status(500).json({ error: 'Failed to get room' });
  }
}

async function listRooms(req, res) {
  try {
    const { type, page = 1, limit = 20, sort = '-createdAt' } = req.query;
    const filter = {};
    if (type) filter.type = type;
    else filter.type = { $in: ['public', 'vip'] };
    
    const allowedSorts = ['-createdAt', 'createdAt', '-capacity', 'capacity', 'title'];
    const safeSort = allowedSorts.includes(sort) ? sort : '-createdAt';
    const cappedLimit = Math.min(parseInt(limit) || 20, 50);
    
    const rooms = await Room.find(filter)
      .select('-password')
      .sort(safeSort)
      .skip((page - 1) * cappedLimit)
      .limit(cappedLimit)
      .lean();
    
    const total = await Room.countDocuments(filter);
    
    res.json({ rooms, total, page: parseInt(page), pages: Math.ceil(total / limit) });
  } catch (err) {
    logger.error('listRooms error', err);
    res.status(500).json({ error: 'Failed to list rooms' });
  }
}

async function joinRoom(req, res) {
  try {
    const { roomId } = req.params;
    const userPayload = req.user;
    const { password } = req.body;
    
    const room = await Room.findOne({ roomId });
    if (!room) return res.status(404).json({ error: 'Room not found' });
    
    if (room.type === 'private' && room.password && room.password !== password) {
      return res.status(403).json({ error: 'Incorrect password' });
    }
    
    const occupiedSeats = (room.seats || []).filter(s => s.userId).length;
    if (occupiedSeats >= room.capacity) {
      return res.status(400).json({ error: 'Room is full' });
    }
    
    const existing = (room.seats || []).find(s => s.userId === userPayload.userId);
    if (existing) return res.json({ ok: true, room });
    
    const user = await User.findOne({ userId: userPayload.userId });
    if (!user) return res.status(404).json({ error: 'User not found' });
    
    let seatIndex = -1;
    for (let i = 1; i < room.capacity; i++) {
      const seat = room.seats.find(s => s.index === i);
      if (!seat || (!seat.userId && !seat.isLocked)) {
        seatIndex = i;
        break;
      }
    }
    
    if (seatIndex === -1) return res.status(400).json({ error: 'No available seats' });
    
    room.seats.push({
      index: seatIndex,
      userId: user.userId,
      displayName: user.displayName,
      avatarUrl: user.avatarUrl,
      joinedAt: new Date()
    });
    
    room.logs.push({
      action: 'user_joined',
      userId: user.userId,
      timestamp: new Date(),
      details: `${user.displayName} joined the room`
    });
    
    await room.save();
    
    try {
      const { emitToRoom } = require('../services/socket');
      emitToRoom(roomId, 'userJoined', { userId: user.userId, displayName: user.displayName, avatarUrl: user.avatarUrl, seatIndex });
    } catch (e) {}
    
    res.json({ ok: true, room });
  } catch (err) {
    logger.error('joinRoom error', err);
    res.status(500).json({ error: 'Failed to join room' });
  }
}

async function leaveRoom(req, res) {
  try {
    const { roomId } = req.params;
    const userPayload = req.user;
    
    const room = await Room.findOne({ roomId });
    if (!room) return res.status(404).json({ error: 'Room not found' });
    
    room.seats = (room.seats || []).filter(s => s.userId !== userPayload.userId);
    
    room.logs.push({
      action: 'user_left',
      userId: userPayload.userId,
      timestamp: new Date(),
      details: 'User left the room'
    });
    
    await room.save();
    
    try {
      const { emitToRoom } = require('../services/socket');
      emitToRoom(roomId, 'userLeft', { userId: userPayload.userId });
    } catch (e) {}
    
    res.json({ ok: true });
  } catch (err) {
    logger.error('leaveRoom error', err);
    res.status(500).json({ error: 'Failed to leave room' });
  }
}

async function muteUser(req, res) {
  try {
    const { roomId } = req.params;
    const { userId, mute = true } = req.body;
    const adminId = req.user.userId;
    
    const room = await Room.findOne({ roomId });
    if (!room) return res.status(404).json({ error: 'Room not found' });
    
    const isAdmin = room.ownerId === adminId || room.coOwners.includes(adminId) || room.moderators.includes(adminId);
    if (!isAdmin) return res.status(403).json({ error: 'Not authorized' });
    
    const seat = room.seats.find(s => s.userId === userId);
    if (seat) seat.isMuted = mute;
    
    room.logs.push({
      action: mute ? 'user_muted' : 'user_unmuted',
      userId: adminId,
      targetId: userId,
      timestamp: new Date()
    });
    
    await room.save();
    
    try {
      const { emitToRoom } = require('../services/socket');
      emitToRoom(roomId, 'userMuted', { userId, muted: mute });
    } catch (e) {}
    
    res.json({ ok: true });
  } catch (err) {
    logger.error('muteUser error', err);
    res.status(500).json({ error: 'Failed to mute user' });
  }
}

async function lockSeat(req, res) {
  try {
    const { roomId } = req.params;
    const { seatIndex, lock = true } = req.body;
    const adminId = req.user.userId;
    
    const room = await Room.findOne({ roomId });
    if (!room) return res.status(404).json({ error: 'Room not found' });
    
    const isAdmin = room.ownerId === adminId || room.coOwners.includes(adminId) || room.moderators.includes(adminId);
    if (!isAdmin) return res.status(403).json({ error: 'Not authorized' });
    
    const seat = room.seats.find(s => s.index === seatIndex);
    if (seat) seat.isLocked = lock;
    
    await room.save();
    res.json({ ok: true });
  } catch (err) {
    logger.error('lockSeat error', err);
    res.status(500).json({ error: 'Failed to lock seat' });
  }
}

async function removeFromSeat(req, res) {
  try {
    const { roomId } = req.params;
    const { userId } = req.body;
    const adminId = req.user.userId;
    
    const room = await Room.findOne({ roomId });
    if (!room) return res.status(404).json({ error: 'Room not found' });
    
    const isAdmin = room.ownerId === adminId || room.coOwners.includes(adminId);
    if (!isAdmin) return res.status(403).json({ error: 'Not authorized' });
    
    room.seats = room.seats.filter(s => s.userId !== userId);
    await room.save();
    
    try {
      const { emitToRoom } = require('../services/socket');
      emitToRoom(roomId, 'userRemoved', { userId });
    } catch (e) {}
    
    res.json({ ok: true });
  } catch (err) {
    logger.error('removeFromSeat error', err);
    res.status(500).json({ error: 'Failed to remove user' });
  }
}

async function transferOwnership(req, res) {
  try {
    const { roomId } = req.params;
    const { newOwnerId } = req.body;
    const currentOwnerId = req.user.userId;
    
    const room = await Room.findOne({ roomId });
    if (!room) return res.status(404).json({ error: 'Room not found' });
    if (room.ownerId !== currentOwnerId) return res.status(403).json({ error: 'Only owner can transfer' });
    
    room.ownerId = newOwnerId;
    room.coOwners = room.coOwners.filter(id => id !== newOwnerId);
    
    room.logs.push({
      action: 'ownership_transferred',
      userId: currentOwnerId,
      targetId: newOwnerId,
      timestamp: new Date()
    });
    
    await room.save();
    res.json({ ok: true, room });
  } catch (err) {
    logger.error('transferOwnership error', err);
    res.status(500).json({ error: 'Failed to transfer ownership' });
  }
}

async function setModerator(req, res) {
  try {
    const { roomId } = req.params;
    const { userId, isModerator = true } = req.body;
    const adminId = req.user.userId;
    
    const room = await Room.findOne({ roomId });
    if (!room) return res.status(404).json({ error: 'Room not found' });
    if (room.ownerId !== adminId) return res.status(403).json({ error: 'Only owner can assign moderators' });
    
    if (isModerator) {
      if (!room.moderators.includes(userId)) room.moderators.push(userId);
    } else {
      room.moderators = room.moderators.filter(id => id !== userId);
    }
    
    room.logs.push({
      action: isModerator ? 'moderator_added' : 'moderator_removed',
      userId: adminId,
      targetId: userId,
      timestamp: new Date()
    });
    
    await room.save();
    res.json({ ok: true, room });
  } catch (err) {
    logger.error('setModerator error', err);
    res.status(500).json({ error: 'Failed to set moderator' });
  }
}

async function setCoOwner(req, res) {
  try {
    const { roomId } = req.params;
    const { userId, isCoOwner = true } = req.body;
    const adminId = req.user.userId;
    
    const room = await Room.findOne({ roomId });
    if (!room) return res.status(404).json({ error: 'Room not found' });
    if (room.ownerId !== adminId) return res.status(403).json({ error: 'Only owner can assign co-owners' });
    
    if (isCoOwner) {
      if (!room.coOwners.includes(userId)) room.coOwners.push(userId);
    } else {
      room.coOwners = room.coOwners.filter(id => id !== userId);
    }
    
    room.logs.push({
      action: isCoOwner ? 'coowner_added' : 'coowner_removed',
      userId: adminId,
      targetId: userId,
      timestamp: new Date()
    });
    
    await room.save();
    res.json({ ok: true, room });
  } catch (err) {
    logger.error('setCoOwner error', err);
    res.status(500).json({ error: 'Failed to set co-owner' });
  }
}

async function updateRoomSettings(req, res) {
  try {
    const { roomId } = req.params;
    const adminId = req.user.userId;
    const updates = req.body;
    
    const room = await Room.findOne({ roomId });
    if (!room) return res.status(404).json({ error: 'Room not found' });
    
    const isAdmin = room.ownerId === adminId || room.coOwners.includes(adminId);
    if (!isAdmin) return res.status(403).json({ error: 'Not authorized' });
    
    const allowedFields = ['title', 'capacity', 'maxCapacity', 'password', 'background', 'entranceEffects', 'ads'];
    for (const field of allowedFields) {
      if (updates[field] !== undefined) {
        if (field === 'title' && typeof updates[field] !== 'string') continue;
        if ((field === 'capacity' || field === 'maxCapacity') && (typeof updates[field] !== 'number' || updates[field] < 2 || updates[field] > 100)) continue;
        if (field === 'password' && typeof updates[field] !== 'string') continue;
        room[field] = updates[field];
      }
    }
    
    room.logs.push({
      action: 'room_settings_updated',
      userId: adminId,
      timestamp: new Date(),
      details: 'Room settings updated'
    });
    
    await room.save();
    res.json({ ok: true, room });
  } catch (err) {
    logger.error('updateRoomSettings error', err);
    res.status(500).json({ error: 'Failed to update room' });
  }
}

async function getRoomLogs(req, res) {
  try {
    const { roomId } = req.params;
    const room = await Room.findOne({ roomId }).select('logs').lean();
    if (!room) return res.status(404).json({ error: 'Room not found' });
    res.json({ logs: room.logs || [] });
  } catch (err) {
    logger.error('getRoomLogs error', err);
    res.status(500).json({ error: 'Failed to get room logs' });
  }
}

async function inviteToRoom(req, res) {
  try {
    const { roomId } = req.params;
    const { userId } = req.body;
    const inviterId = req.user.userId;
    
    const room = await Room.findOne({ roomId });
    if (!room) return res.status(404).json({ error: 'Room not found' });
    
    const inviter = await User.findOne({ userId: inviterId });
    
    const notif = new Notification({
      userId,
      type: 'room_invite',
      title: 'دعوة غرفة',
      body: `${inviter.displayName} يدعوك للانضمام إلى ${room.title}`,
      data: { roomId, roomTitle: room.title, inviterId, inviterName: inviter.displayName }
    });
    await notif.save();
    
    res.json({ ok: true });
  } catch (err) {
    logger.error('inviteToRoom error', err);
    res.status(500).json({ error: 'Failed to send invitation' });
  }
}

async function getVoiceAccess(req, res) {
  try {
    const { roomId } = req.params;
    const { role = 'publisher', uid } = req.body || {};
    const user = req.user;
    if (!user) return res.status(401).json({ error: 'Unauthorized' });

    const room = await Room.findOne({ roomId });
    if (!room) return res.status(404).json({ error: 'Room not found' });

    const engine = (config.voiceEngine || 'agora').toLowerCase();
    if (engine === 'jitsi') {
      return res.json({ engine: 'jitsi', server: config.jitsiServer, roomName: room.roomId });
    }

    if (!generateRtcToken) return res.status(500).json({ error: 'Agora token generator not available' });
    const account = uid || user.userId;
    const expireSeconds = 3600;
    const token = generateRtcToken(room.roomId, account, role, expireSeconds);
    return res.json({ engine: 'agora', token, channelName: room.roomId, expiresIn: expireSeconds, appId: config.agoraAppId });
  } catch (err) {
    logger.error('getVoiceAccess error', err);
    return res.status(500).json({ error: 'Failed to generate access', details: err.message });
  }
}

module.exports = {
  createRoom, getRoom, listRooms, joinRoom, leaveRoom,
  muteUser, lockSeat, removeFromSeat, transferOwnership,
  setModerator, setCoOwner, updateRoomSettings, getRoomLogs, inviteToRoom,
  getVoiceAccess
};
