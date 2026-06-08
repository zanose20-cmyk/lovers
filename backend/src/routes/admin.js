const express = require('express');
const router = express.Router();
const {
  getDashboardStats, getRealtimeStats,
  listUsers, updateUser, banUser, unbanUser,
  listRooms, deleteRoom,
  listGifts,
  listReports,
  getAdminLogs
} = require('../controllers/adminController');
const { requireAuth } = require('../middleware/authMiddleware');
const { requireRole } = require('../middleware/roleMiddleware');

// All admin routes require authentication and admin role
router.use(requireAuth);
router.use(requireRole('admin', 'superadmin'));

// Dashboard
router.get('/stats', getDashboardStats);
router.get('/stats/realtime', getRealtimeStats);

// Users
router.get('/users', listUsers);
router.put('/users/:userId', updateUser);
router.post('/users/:userId/ban', banUser);
router.post('/users/:userId/unban', unbanUser);

// Rooms
router.get('/rooms', listRooms);
router.delete('/rooms/:roomId', deleteRoom);

// Gifts
router.get('/gifts', listGifts);

// Reports
router.get('/reports', listReports);

// Logs
router.get('/logs', getAdminLogs);

module.exports = router;
