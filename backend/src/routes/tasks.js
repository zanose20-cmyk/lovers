const express = require('express');
const router = express.Router();
const {
  getDailyTasks, claimDailyReward, dailyLogin,
  updateTaskProgress, createDailyTask
} = require('../controllers/tasksController');
const { requireAuth } = require('../middleware/authMiddleware');
const { requireRole } = require('../middleware/roleMiddleware');

router.get('/daily', requireAuth, getDailyTasks);
router.post('/daily/login', requireAuth, dailyLogin);
router.post('/daily/claim', requireAuth, claimDailyReward);
router.post('/daily/progress', requireAuth, updateTaskProgress);
router.post('/admin/tasks', requireAuth, requireRole('admin'), createDailyTask);

module.exports = router;
