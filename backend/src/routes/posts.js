const express = require('express');
const router = express.Router();
const {
  createPost, getPost, listPosts,
  likePost, commentOnPost, sharePost, deletePost,
  getTrendingHashtags
} = require('../controllers/postsController');
const { requireAuth } = require('../middleware/authMiddleware');

router.get('/', listPosts);
router.get('/trending/hashtags', getTrendingHashtags);
router.get('/:postId', getPost);
router.post('/', requireAuth, createPost);
router.post('/:postId/like', requireAuth, likePost);
router.post('/:postId/comment', requireAuth, commentOnPost);
router.post('/:postId/share', requireAuth, sharePost);
router.delete('/:postId', requireAuth, deletePost);

module.exports = router;
