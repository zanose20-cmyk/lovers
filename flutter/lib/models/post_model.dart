class PostMedia {
  String? type;
  String? url;
  String? thumbnailUrl;
  int? duration;

  PostMedia({this.type, this.url, this.thumbnailUrl, this.duration});

  factory PostMedia.fromJson(Map json) => PostMedia(
        type: json['type'],
        url: json['url'],
        thumbnailUrl: json['thumbnailUrl'],
        duration: json['duration'],
      );

  Map toJson() => {'type': type, 'url': url, 'thumbnailUrl': thumbnailUrl, 'duration': duration};
}

class PostComment {
  String? commentId;
  String? userId;
  String? displayName;
  String? avatarUrl;
  String? content;
  List<String>? likes;
  DateTime? createdAt;

  PostComment({
    this.commentId,
    this.userId,
    this.displayName,
    this.avatarUrl,
    this.content,
    this.likes,
    this.createdAt,
  });

  factory PostComment.fromJson(Map json) => PostComment(
        commentId: json['commentId'],
        userId: json['userId'],
        displayName: json['displayName'],
        avatarUrl: json['avatarUrl'],
        content: json['content'],
        likes: json['likes'] != null ? List<String>.from(json['likes']) : null,
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      );

  Map toJson() => {
        'commentId': commentId,
        'userId': userId,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
        'content': content,
        'likes': likes,
        'createdAt': createdAt?.toIso8601String(),
      };
}

class PostModel {
  String? postId;
  String? authorId;
  String? authorName;
  String? authorAvatar;
  String? content;
  List<PostMedia>? media;
  List<String>? hashtags;
  List<String>? mentions;
  List<String>? likes;
  int? likesCount;
  List<PostComment>? comments;
  int? commentsCount;
  int? sharesCount;
  bool? isTrending;
  bool? isPinned;
  DateTime? createdAt;
  DateTime? updatedAt;

  PostModel({
    this.postId,
    this.authorId,
    this.authorName,
    this.authorAvatar,
    this.content,
    this.media,
    this.hashtags,
    this.mentions,
    this.likes,
    this.likesCount,
    this.comments,
    this.commentsCount,
    this.sharesCount,
    this.isTrending,
    this.isPinned,
    this.createdAt,
    this.updatedAt,
  });

  factory PostModel.fromJson(Map json) => PostModel(
        postId: json['postId'],
        authorId: json['authorId'],
        authorName: json['authorName'],
        authorAvatar: json['authorAvatar'],
        content: json['content'],
        media: json['media'] != null ? (json['media'] as List).map((e) => PostMedia.fromJson(e)).toList() : null,
        hashtags: json['hashtags'] != null ? List<String>.from(json['hashtags']) : null,
        mentions: json['mentions'] != null ? List<String>.from(json['mentions']) : null,
        likes: json['likes'] != null ? List<String>.from(json['likes']) : null,
        likesCount: json['likesCount'],
        comments: json['comments'] != null ? (json['comments'] as List).map((e) => PostComment.fromJson(e)).toList() : null,
        commentsCount: json['commentsCount'],
        sharesCount: json['sharesCount'],
        isTrending: json['isTrending'],
        isPinned: json['isPinned'],
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
        updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
      );

  Map toJson() => {
        'postId': postId,
        'authorId': authorId,
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'content': content,
        'media': media?.map((e) => e.toJson()).toList(),
        'hashtags': hashtags,
        'mentions': mentions,
        'likes': likes,
        'likesCount': likesCount,
        'comments': comments?.map((e) => e.toJson()).toList(),
        'commentsCount': commentsCount,
        'sharesCount': sharesCount,
        'isTrending': isTrending,
        'isPinned': isPinned,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}
