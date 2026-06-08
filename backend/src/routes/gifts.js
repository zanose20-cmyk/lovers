const express = require('express');
const router = express.Router();
const { listGifts, sendGift, sendRoomGift, createGift, updateGift, deleteGift, getGift } = require('../controllers/giftsController');
const { requireAuth } = require('../middleware/authMiddleware');
const { requireRole } = require('../middleware/roleMiddleware');

router.get('/store/gifts', listGifts);
router.post('/gifts/send', requireAuth, sendGift);
router.post('/gifts/room-send', requireAuth, sendRoomGift);

// Admin gift management
router.post('/admin/gifts', requireAuth, requireRole('admin'), createGift);
router.put('/admin/gifts/:sku', requireAuth, requireRole('admin'), updateGift);
router.delete('/admin/gifts/:sku', requireAuth, requireRole('admin'), deleteGift);
router.get('/admin/gifts/:sku', requireAuth, requireRole('admin'), getGift);

module.exports = router;
