const express = require('express');
const multer = require('multer');
const router = express.Router();
const {
  createPost, getPost, listPosts,
  likePost, commentOnPost, sharePost, deletePost,
  followPostAuthor, unfollowPostAuthor,
  getTrendingHashtags
} = require('../controllers/postsController');
const { requireAuth } = require('../middleware/authMiddleware');
const { uploadFileHandler } = require('../controllers/usersController');

const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 10 * 1024 * 1024 } });

router.get('/', listPosts);
router.get('/trending/hashtags', getTrendingHashtags);
router.get('/:postId', getPost);
router.post('/', requireAuth, createPost);
router.post('/upload', requireAuth, upload.array('files', 10), uploadFileHandler);
router.post('/:postId/like', requireAuth, likePost);
router.post('/:postId/comment', requireAuth, commentOnPost);
router.post('/:postId/share', requireAuth, sharePost);
router.post('/:postId/follow', requireAuth, followPostAuthor);
router.post('/:postId/unfollow', requireAuth, unfollowPostAuthor);
router.delete('/:postId', requireAuth, deletePost);

module.exports = router;
