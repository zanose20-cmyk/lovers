import 'package:flutter/foundation.dart';
import '../models/post_model.dart';
import '../services/api_service.dart';
import '../services/posts_service.dart';

class PostsProvider extends ChangeNotifier {
  final PostsService _service;
  List<PostModel> _posts = [];
  bool _isLoading = false;
  String? _error;

  PostsProvider(ApiService api) : _service = PostsService(api);

  List<PostModel> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPosts({String? hashtag, bool trending = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _service.listPosts(hashtag: hashtag, trending: trending);
      _posts = data.map((e) => PostModel.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<PostModel?> createPost(String content, {List<String>? hashtags}) async {
    try {
      final data = await _service.createPost(content, hashtags: hashtags);
      if (data != null) {
        final post = PostModel.fromJson(data);
        _posts.insert(0, post);
        notifyListeners();
        return post;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
    return null;
  }

  Future<bool> likePost(String postId) async {
    try {
      final ok = await _service.likePost(postId);
      if (ok) {
        final idx = _posts.indexWhere((p) => p.postId == postId);
        if (idx != -1) {
          _posts[idx].likesCount = (_posts[idx].likesCount ?? 0) + 1;
          notifyListeners();
        }
      }
      return ok;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> sharePost(String postId) async {
    try {
      return await _service.sharePost(postId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> commentPost(String postId, String content) async {
    try {
      return await _service.commentPost(postId, content);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePost(String postId) async {
    try {
      final ok = await _service.deletePost(postId);
      if (ok) {
        _posts.removeWhere((p) => p.postId == postId);
        notifyListeners();
      }
      return ok;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
