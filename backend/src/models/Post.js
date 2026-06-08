const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid');

const CommentSchema = new mongoose.Schema({
  commentId: { type: String, default: () => uuidv4() },
  userId: String,
  displayName: String,
  avatarUrl: String,
  content: String,
  likes: [String],
  createdAt: { type: Date, default: Date.now }
});

const PostSchema = new mongoose.Schema({
  postId: { type: String, default: () => uuidv4(), unique: true },
  authorId: { type: String, required: true },
  authorName: String,
  authorAvatar: String,
  content: String,
  media: [{
    type: { type: String, enum: ['image', 'video', 'audio'] },
    url: String,
    thumbnailUrl: String,
    duration: Number
  }],
  hashtags: [String],
  mentions: [String],
  likes: [String],
  likesCount: { type: Number, default: 0 },
  comments: [CommentSchema],
  commentsCount: { type: Number, default: 0 },
  sharesCount: { type: Number, default: 0 },
  isTrending: { type: Boolean, default: false },
  isPinned: { type: Boolean, default: false },
  isDeleted: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

PostSchema.pre('save', function (next) {
  this.updatedAt = new Date();
  this.likesCount = (this.likes || []).length;
  this.commentsCount = (this.comments || []).length;
  next();
});

module.exports = mongoose.model('Post', PostSchema);
