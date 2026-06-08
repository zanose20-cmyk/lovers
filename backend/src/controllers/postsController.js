const Post = require('../models/Post');
const User = require('../models/User');
const Notification = require('../models/Notification');
const logger = require('../utils/logger');

async function createPost(req, res) {
  try {
    const userPayload = req.user;
    const { content, media, hashtags } = req.body;
    
    const user = await User.findOne({ userId: userPayload.userId });
    if (!user) return res.status(404).json({ error: 'User not found' });
    
    // Extract hashtags from content if not provided
    let tags = hashtags || [];
    if (content) {
      const found = content.match(/#[\w\u0600-\u06FF]+/g);
      if (found) tags = [...new Set([...tags, ...found])];
    }
    
    const post = new Post({
      authorId: user.userId,
      authorName: user.displayName,
      authorAvatar: user.avatarUrl,
      content,
      media: media || [],
      hashtags: tags
    });
    
    await post.save();
    res.json({ ok: true, post });
  } catch (err) {
    logger.error('createPost error', err);
    res.status(500).json({ error: 'Failed to create post' });
  }
}

async function getPost(req, res) {
  try {
    const { postId } = req.params;
    const post = await Post.findOne({ postId, isDeleted: false }).lean();
    if (!post) return res.status(404).json({ error: 'Post not found' });
    res.json(post);
  } catch (err) {
    logger.error('getPost error', err);
    res.status(500).json({ error: 'Failed to get post' });
  }
}

async function listPosts(req, res) {
  try {
    const { page = 1, limit = 20, hashtag, authorId, trending } = req.query;
    const filter = { isDeleted: false };
    
    if (hashtag) filter.hashtags = hashtag;
    if (authorId) filter.authorId = authorId;
    if (trending) filter.isTrending = true;
    
    const sort = trending ? { likesCount: -1 } : { createdAt: -1 };
    
    const posts = await Post.find(filter)
      .sort(sort)
      .skip((page - 1) * limit)
      .limit(parseInt(limit))
      .lean();
    
    const total = await Post.countDocuments(filter);
    
    res.json({ posts, total, page: parseInt(page), pages: Math.ceil(total / limit) });
  } catch (err) {
    logger.error('listPosts error', err);
    res.status(500).json({ error: 'Failed to list posts' });
  }
}

async function likePost(req, res) {
  try {
    const { postId } = req.params;
    const userId = req.user.userId;
    
    const post = await Post.findOne({ postId });
    if (!post) return res.status(404).json({ error: 'Post not found' });
    
    const alreadyLiked = post.likes.includes(userId);
    if (alreadyLiked) {
      post.likes = post.likes.filter(id => id !== userId);
    } else {
      post.likes.push(userId);
      
      if (post.authorId !== userId) {
        const user = await User.findOne({ userId });
        const notif = new Notification({
          userId: post.authorId,
          type: 'like',
          title: 'إعجاب جديد',
          body: `${user.displayName} أعجب بمنشورك`,
          data: { postId, userId }
        });
        await notif.save();
      }
    }
    
    await post.save();
    res.json({ ok: true, liked: !alreadyLiked, likesCount: post.likes.length });
  } catch (err) {
    logger.error('likePost error', err);
    res.status(500).json({ error: 'Failed to like post' });
  }
}

async function commentOnPost(req, res) {
  try {
    const { postId } = req.params;
    const userId = req.user.userId;
    const { content } = req.body;
    
    if (!content) return res.status(400).json({ error: 'Content required' });
    
    const post = await Post.findOne({ postId });
    if (!post) return res.status(404).json({ error: 'Post not found' });
    
    const user = await User.findOne({ userId });
    
    post.comments.push({
      userId,
      displayName: user.displayName,
      avatarUrl: user.avatarUrl,
      content
    });
    
    await post.save();
    
    if (post.authorId !== userId) {
      const notif = new Notification({
        userId: post.authorId,
        type: 'comment',
        title: 'تعليق جديد',
        body: `${user.displayName} علّق على منشورك`,
        data: { postId, userId }
      });
      await notif.save();
    }
    
    res.json({ ok: true, commentsCount: post.comments.length });
  } catch (err) {
    logger.error('commentOnPost error', err);
    res.status(500).json({ error: 'Failed to comment' });
  }
}

async function sharePost(req, res) {
  try {
    const { postId } = req.params;
    
    const post = await Post.findOne({ postId });
    if (!post) return res.status(404).json({ error: 'Post not found' });
    
    post.sharesCount = (post.sharesCount || 0) + 1;
    await post.save();
    
    res.json({ ok: true, sharesCount: post.sharesCount });
  } catch (err) {
    logger.error('sharePost error', err);
    res.status(500).json({ error: 'Failed to share post' });
  }
}

async function deletePost(req, res) {
  try {
    const { postId } = req.params;
    const userId = req.user.userId;
    
    const post = await Post.findOne({ postId });
    if (!post) return res.status(404).json({ error: 'Post not found' });
    
    if (post.authorId !== userId && !req.user.roles.includes('admin')) {
      return res.status(403).json({ error: 'Not authorized' });
    }
    
    post.isDeleted = true;
    await post.save();
    
    res.json({ ok: true });
  } catch (err) {
    logger.error('deletePost error', err);
    res.status(500).json({ error: 'Failed to delete post' });
  }
}

async function getTrendingHashtags(req, res) {
  try {
    const posts = await Post.find({ isDeleted: false })
      .select('hashtags likesCount')
      .lean();
    
    const tagCount = {};
    for (const post of posts) {
      for (const tag of post.hashtags || []) {
        tagCount[tag] = (tagCount[tag] || 0) + 1;
      }
    }
    
    const trending = Object.entries(tagCount)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 20)
      .map(([tag, count]) => ({ tag, count }));
    
    res.json(trending);
  } catch (err) {
    logger.error('getTrendingHashtags error', err);
    res.status(500).json({ error: 'Failed to get trending hashtags' });
  }
}

module.exports = {
  createPost, getPost, listPosts,
  likePost, commentOnPost, sharePost, deletePost,
  getTrendingHashtags
};
