const express = require('express');
const router = express.Router();
const {
  sendPrivateMessage, getConversation, getConversationsList,
  markAsRead, editMessage, deleteMessage, translateMessage
} = require('../controllers/messagesController');
const { requireAuth } = require('../middleware/authMiddleware');

router.get('/conversations', requireAuth, getConversationsList);
router.get('/conversations/:userId', requireAuth, getConversation);
router.post('/private', requireAuth, sendPrivateMessage);
router.put('/:messageId/read', requireAuth, markAsRead);
router.put('/:messageId/edit', requireAuth, editMessage);
router.put('/:messageId/translate', requireAuth, translateMessage);
router.delete('/:messageId', requireAuth, deleteMessage);

module.exports = router;
