const express = require('express');
const multer = require('multer');
const router = express.Router();
const {
  getProfile, updateProfile, searchUsers,
  followUser, unfollowUser, getFollowers, getFollowing,
  addFriend, getNotifications, markNotificationRead, markAllNotificationsRead,
  getUserVIPStatus,
  blockUser, unblockUser, isBlocked, getBlockedList,
  uploadFileHandler,
} = require('../controllers/usersController');
const { requireAuth } = require('../middleware/authMiddleware');

const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 10 * 1024 * 1024 } });

router.get('/search', searchUsers);
router.get('/:userId', getProfile);
router.put('/me', requireAuth, updateProfile);
router.post('/me/upload', requireAuth, upload.single('file'), uploadFileHandler);

router.post('/:userId/follow', requireAuth, followUser);
router.post('/:userId/unfollow', requireAuth, unfollowUser);
router.get('/:userId/followers', getFollowers);
router.get('/:userId/following', getFollowing);
router.post('/:userId/friend', requireAuth, addFriend);

router.post('/:userId/block', requireAuth, blockUser);
router.post('/:userId/unblock', requireAuth, unblockUser);
router.get('/:userId/is-blocked', requireAuth, isBlocked);
router.get('/me/blocked', requireAuth, getBlockedList);

router.get('/:userId/vip', getUserVIPStatus);

router.get('/me/notifications', requireAuth, getNotifications);
router.put('/me/notifications/:notifId/read', requireAuth, markNotificationRead);
router.put('/me/notifications/read-all', requireAuth, markAllNotificationsRead);

module.exports = router;
