const express = require('express');
const router = express.Router();
const {
  getVIPLevels, getUserVIP, purchaseVIP,
  createVIPLevel, updateVIPLevel
} = require('../controllers/vipController');
const { requireAuth } = require('../middleware/authMiddleware');
const { requireRole } = require('../middleware/roleMiddleware');

router.get('/levels', getVIPLevels);
router.get('/user', requireAuth, getUserVIP);
router.get('/user/:userId', getUserVIP);
router.post('/purchase', requireAuth, purchaseVIP);
router.post('/admin/levels', requireAuth, requireRole('admin'), createVIPLevel);
router.put('/admin/levels/:level', requireAuth, requireRole('admin'), updateVIPLevel);

module.exports = router;
