const Message = require('../models/Message');
const User = require('../models/User');
const logger = require('../utils/logger');
const { v4: uuidv4 } = require('uuid');

async function sendPrivateMessage(req, res) {
  try {
    const fromUserId = req.user.userId;
    const { toUserId, type = 'text', content, attachments } = req.body;
    
    if (!toUserId || !content) return res.status(400).json({ error: 'toUserId and content required' });
    const safeContent = typeof content === 'string' ? content.trim().slice(0, 5000) : '';
    if (!safeContent) return res.status(400).json({ error: 'Content required' });
    
    const receiver = await User.findOne({ userId: toUserId });
    if (!receiver) return res.status(404).json({ error: 'User not found' });
    
    const message = new Message({
      messageId: uuidv4(),
      fromUserId,
      toUserId,
      type,
      content: safeContent,
      attachments: attachments || []
    });
    
    await message.save();
    
    // Emit via socket
    try {
      const { getIO } = require('../services/socket');
      const io = getIO();
      if (io) {
        io.to(`user:${toUserId}`).emit('privateMessage', message);
      }
    } catch (e) {}
    
    res.json({ ok: true, message });
  } catch (err) {
    logger.error('sendPrivateMessage error', err);
    res.status(500).json({ error: 'Failed to send message' });
  }
}

async function getConversation(req, res) {
  try {
    const userId = req.user.userId;
    const { userId: otherUserId } = req.params;
    const { page = 1, limit = 50 } = req.query;
    
    const messages = await Message.find({
      $or: [
        { fromUserId: userId, toUserId: otherUserId },
        { fromUserId: otherUserId, toUserId: userId }
      ],
      isDeleted: false
    })
    .sort({ createdAt: -1 })
    .skip((page - 1) * limit)
    .limit(parseInt(limit))
    .lean();
    
    const total = await Message.countDocuments({
      $or: [
        { fromUserId: userId, toUserId: otherUserId },
        { fromUserId: otherUserId, toUserId: userId }
      ],
      isDeleted: false
    });
    
    res.json({ messages: messages.reverse(), total, page: parseInt(page) });
  } catch (err) {
    logger.error('getConversation error', err);
    res.status(500).json({ error: 'Failed to get conversation' });
  }
}

async function getConversationsList(req, res) {
  try {
    const userId = req.user.userId;
    
    const messages = await Message.aggregate([
      {
        $match: {
          $or: [{ fromUserId: userId }, { toUserId: userId }],
          isDeleted: false
        }
      },
      { $sort: { createdAt: -1 } },
      {
        $group: {
          _id: {
            $cond: [
              { $eq: ['$fromUserId', userId] },
              '$toUserId',
              '$fromUserId'
            ]
          },
          lastMessage: { $first: '$$ROOT' },
          count: { $sum: 1 }
        }
      },
      { $sort: { 'lastMessage.createdAt': -1 } },
      { $limit: 50 }
    ]);
    
    // Get user details for each conversation
    const userIds = messages.map(m => m._id);
    const users = await User.find({ userId: { $in: userIds } })
      .select('userId displayName avatarUrl isVerified')
      .lean();
    
    const userMap = {};
    for (const u of users) {
      userMap[u.userId] = u;
    }
    
    const conversations = messages.map(m => ({
      user: userMap[m._id] || { userId: m._id },
      lastMessage: m.lastMessage,
      unread: 0 // TODO: implement unread count
    }));
    
    res.json({ conversations });
  } catch (err) {
    logger.error('getConversationsList error', err);
    res.status(500).json({ error: 'Failed to get conversations' });
  }
}

async function markAsRead(req, res) {
  try {
    const userId = req.user.userId;
    const { messageId } = req.params;
    
    await Message.updateOne({ messageId, toUserId: userId }, { $set: { isRead: true } });
    
    res.json({ ok: true });
  } catch (err) {
    logger.error('markAsRead error', err);
    res.status(500).json({ error: 'Failed to mark as read' });
  }
}

async function editMessage(req, res) {
  try {
    const { messageId } = req.params;
    const userId = req.user.userId;
    const { content } = req.body;
    
    if (!content) return res.status(400).json({ error: 'Content required' });
    const safeEdit = typeof content === 'string' ? content.trim().slice(0, 5000) : '';
    if (!safeEdit) return res.status(400).json({ error: 'Content required' });
    
    const message = await Message.findOne({ messageId });
    if (!message) return res.status(404).json({ error: 'Message not found' });
    if (message.fromUserId !== userId) return res.status(403).json({ error: 'Not your message' });
    
    message.content = safeEdit;
    await message.save();
    
    res.json({ ok: true, message });
  } catch (err) {
    logger.error('editMessage error', err);
    res.status(500).json({ error: 'Failed to edit message' });
  }
}

async function deleteMessage(req, res) {
  try {
    const { messageId } = req.params;
    const userId = req.user.userId;
    
    const message = await Message.findOne({ messageId });
    if (!message) return res.status(404).json({ error: 'Message not found' });
    if (message.fromUserId !== userId) return res.status(403).json({ error: 'Not your message' });
    
    message.isDeleted = true;
    await message.save();
    
    res.json({ ok: true });
  } catch (err) {
    logger.error('deleteMessage error', err);
    res.status(500).json({ error: 'Failed to delete message' });
  }
}

async function translateMessage(req, res) {
  try {
    const { messageId } = req.params;
    const { targetLang = 'en' } = req.body;
    
    const message = await Message.findOne({ messageId });
    if (!message) return res.status(404).json({ error: 'Message not found' });
    
    // TODO: Integrate with translation API (e.g., Google Translate)
    // For now, placeholder
    message.translatedText = `[Translated to ${targetLang}]: ${message.content}`;
    await message.save();
    
    res.json({ ok: true, translatedText: message.translatedText });
  } catch (err) {
    logger.error('translateMessage error', err);
    res.status(500).json({ error: 'Failed to translate message' });
  }
}

module.exports = {
  sendPrivateMessage, getConversation, getConversationsList,
  markAsRead, editMessage, deleteMessage, translateMessage
};
