const { Server } = require('socket.io');
const { createClient } = require('redis');
const { createAdapter } = require('@socket.io/redis-adapter');
const jwt = require('jsonwebtoken');
const config = require('../config');
const logger = require('../utils/logger');
const User = require('../models/User');
const Message = require('../models/Message');
const { v4: uuidv4 } = require('uuid');

let io;

function initSocket(server) {
  io = new Server(server, {
    cors: { origin: '*' },
    maxHttpBufferSize: 1e6,
    pingTimeout: 60000,
    pingInterval: 25000
  });

  if (config.redisUrl) {
    const pubClient = createClient({ url: config.redisUrl });
    const subClient = pubClient.duplicate();
    Promise.all([pubClient.connect(), subClient.connect()])
      .then(() => {
        io.adapter(createAdapter(pubClient, subClient));
        logger.info('Socket.io Redis adapter connected');
      })
      .catch((err) => logger.error('Redis adapter error', err));
  }

  // Authentication middleware
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth?.token || socket.handshake.headers?.authorization?.replace('Bearer ', '');
      if (token) {
        const payload = jwt.verify(token, config.jwtSecret);
        socket.userId = payload.userId;
        socket.roles = payload.roles || ['user'];
      }
      next();
    } catch (err) {
      next(new Error('Authentication required'));
    }
  });

  io.on('connection', (socket) => {
    logger.info('Socket connected', { id: socket.id, userId: socket.userId });

    // Join user's personal room for direct messages
    if (socket.userId) {
      socket.join(`user:${socket.userId}`);
    }

    // --- Room Events ---
    socket.on('joinRoom', async ({ roomId, password }) => {
      try {
        const Room = require('../models/Room');
        const room = await Room.findOne({ roomId });
        if (!room) {
          socket.emit('error', { message: 'Room not found' });
          return;
        }
        
        if (room.type === 'private' && room.password && room.password !== password) {
          socket.emit('error', { message: 'Incorrect password' });
          return;
        }
        
        socket.join(roomId);
        socket.currentRoom = roomId;
        
        // Notify others
        socket.to(roomId).emit('userJoined', {
          userId: socket.userId,
          socketId: socket.id,
          timestamp: new Date()
        });
        
        socket.emit('roomJoined', { roomId, title: room.title });
      } catch (err) {
        logger.error('joinRoom socket error', err);
      }
    });

    socket.on('leaveRoom', ({ roomId }) => {
      const targetRoom = roomId || socket.currentRoom;
      if (targetRoom) {
        socket.leave(targetRoom);
        io.to(targetRoom).emit('userLeft', { userId: socket.userId });
        socket.currentRoom = null;
      }
    });

    // --- Chat Events ---
    socket.on('roomMessage', async (payload) => {
      try {
        const message = {
          messageId: uuidv4(),
          fromUserId: socket.userId,
          roomId: payload.roomId,
          type: payload.type || 'text',
          content: payload.content,
          attachments: payload.attachments || [],
          createdAt: new Date()
        };
        
        // Save to DB
        const Msg = require('../models/Message');
        await new Msg(message).save();
        
        // Broadcast to room
        io.to(payload.roomId).emit('roomMessage', message);
      } catch (err) {
        logger.error('roomMessage socket error', err);
      }
    });

    socket.on('privateMessage', async (payload) => {
      try {
        const message = {
          messageId: uuidv4(),
          fromUserId: socket.userId,
          toUserId: payload.toUserId,
          type: payload.type || 'text',
          content: payload.content,
          attachments: payload.attachments || [],
          createdAt: new Date()
        };
        
        const Msg = require('../models/Message');
        await new Msg(message).save();
        
        // Send to recipient's personal room
        io.to(`user:${payload.toUserId}`).emit('privateMessage', message);
        // Also send back to sender for confirmation
        socket.emit('privateMessage', message);
      } catch (err) {
        logger.error('privateMessage socket error', err);
      }
    });

    // --- Seat Events ---
    socket.on('seat:request', ({ roomId, seatIndex }) => {
      io.to(roomId).emit('seat:requested', { userId: socket.userId, seatIndex });
    });

    socket.on('seat:assign', ({ roomId, userId, seatIndex }) => {
      io.to(roomId).emit('seat:assigned', { userId, seatIndex });
    });

    socket.on('seat:release', ({ roomId, seatIndex }) => {
      io.to(roomId).emit('seat:released', { userId: socket.userId, seatIndex });
    });

    // --- Gift Events ---
    socket.on('gift:send', ({ roomId, toUserId, giftSku, count, giftMeta }) => {
      const payload = { fromUserId: socket.userId, toUserId, giftSku, count, giftMeta };
      if (roomId) {
        io.to(roomId).emit('gift:sent', payload);
      } else {
        io.to(`user:${toUserId}`).emit('gift:sent', payload);
      }
    });

    // --- Voice Events ---
    socket.on('voice:mute', ({ roomId, userId, muted }) => {
      io.to(roomId).emit('voice:muted', { userId, muted });
    });

    socket.on('voice:raised-hand', ({ roomId }) => {
      io.to(roomId).emit('voice:hand-raised', { userId: socket.userId });
    });

    // --- Admin Events ---
    socket.on('admin:kick', async ({ roomId, userId }) => {
      if (!socket.userId) return socket.emit('error', { message: 'Unauthorized' });
      const Room = require('../models/Room');
      const room = await Room.findOne({ roomId });
      if (!room) return socket.emit('error', { message: 'Room not found' });
      const isOwner = room.ownerId === socket.userId;
      const isAdmin = (socket.roles || []).includes('admin');
      if (!isOwner && !isAdmin) return socket.emit('error', { message: 'Not authorized' });
      io.to(roomId).emit('admin:kicked', { userId });
      const sockets = io.sockets.adapter.rooms.get(roomId);
      if (sockets) {
        for (const socketId of sockets) {
          const sock = io.sockets.sockets.get(socketId);
          if (sock && sock.userId === userId) {
            sock.leave(roomId);
            sock.emit('kicked', { roomId });
          }
        }
      }
    });

    socket.on('admin:ban', async ({ roomId, userId }) => {
      if (!socket.userId) return socket.emit('error', { message: 'Unauthorized' });
      const Room = require('../models/Room');
      const room = await Room.findOne({ roomId });
      if (!room) return socket.emit('error', { message: 'Room not found' });
      const isOwner = room.ownerId === socket.userId;
      const isAdmin = (socket.roles || []).includes('admin');
      if (!isOwner && !isAdmin) return socket.emit('error', { message: 'Not authorized' });
      io.to(roomId).emit('admin:banned', { userId });
    });

    // --- Typing Events ---
    socket.on('typing:start', ({ roomId, toUserId }) => {
      if (roomId) {
        socket.to(roomId).emit('typing:start', { userId: socket.userId });
      } else if (toUserId) {
        io.to(`user:${toUserId}`).emit('typing:start', { userId: socket.userId });
      }
    });

    socket.on('typing:stop', ({ roomId, toUserId }) => {
      if (roomId) {
        socket.to(roomId).emit('typing:stop', { userId: socket.userId });
      } else if (toUserId) {
        io.to(`user:${toUserId}`).emit('typing:stop', { userId: socket.userId });
      }
    });

    // --- Disconnect ---
    socket.on('disconnect', (reason) => {
      logger.info('Socket disconnected', { id: socket.id, userId: socket.userId, reason });
      
      // Notify room if user was in one
      if (socket.currentRoom) {
        io.to(socket.currentRoom).emit('userLeft', { userId: socket.userId });
      }
    });
  });
}

function emitToRoom(room, event, payload) {
  if (io) io.to(room).emit(event, payload);
}

function emitToUser(userId, event, payload) {
  if (io) io.to(`user:${userId}`).emit(event, payload);
}

function getIO() {
  return io;
}

module.exports = { initSocket, getIO, emitToRoom, emitToUser };
