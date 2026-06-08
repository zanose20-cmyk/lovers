const express = require('express');
const router = express.Router();
const {
  getProfile, updateProfile, searchUsers,
  followUser, unfollowUser, getFollowers, getFollowing,
  addFriend, getNotifications, markNotificationRead, markAllNotificationsRead,
  getUserVIPStatus
} = require('../controllers/usersController');
const { requireAuth } = require('../middleware/authMiddleware');

// Profile
router.get('/search', searchUsers);
router.get('/:userId', getProfile);
router.put('/me', requireAuth, updateProfile);

// Social
router.post('/:userId/follow', requireAuth, followUser);
router.post('/:userId/unfollow', requireAuth, unfollowUser);
router.get('/:userId/followers', getFollowers);
router.get('/:userId/following', getFollowing);
router.post('/:userId/friend', requireAuth, addFriend);

// VIP
router.get('/:userId/vip', getUserVIPStatus);

// Notifications
router.get('/me/notifications', requireAuth, getNotifications);
router.put('/me/notifications/:notifId/read', requireAuth, markNotificationRead);
router.put('/me/notifications/read-all', requireAuth, markAllNotificationsRead);

module.exports = router;
