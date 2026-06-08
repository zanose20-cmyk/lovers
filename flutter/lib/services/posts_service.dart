import 'api_service.dart';

class PostsService {
  final ApiService api;
  PostsService(this.api);

  Future<List<dynamic>> listPosts({String? hashtag, String? authorId, bool trending = false, int page = 1}) async {
    final params = <String, String>{'page': '$page', 'limit': '20'};
    if (hashtag != null) params['hashtag'] = hashtag;
    if (authorId != null) params['authorId'] = authorId;
    if (trending) params['trending'] = 'true';
    final resp = await api.get('/api/posts', queryParams: params);
    if (resp.statusCode == 200) return resp.data['posts'] ?? [];
    return [];
  }

  Future<Map?> createPost(String content, {List<String>? media, List<String>? hashtags}) async {
    final resp = await api.post('/api/posts', body: {'content': content, 'media': media ?? [], 'hashtags': hashtags ?? []});
    if (resp.statusCode == 200 && resp.data['ok'] == true) return resp.data['post'];
    return null;
  }

  Future<bool> likePost(String postId) async {
    final resp = await api.post('/api/posts/$postId/like');
    return resp.statusCode == 200;
  }

  Future<bool> commentPost(String postId, String content) async {
    final resp = await api.post('/api/posts/$postId/comment', body: {'content': content});
    return resp.statusCode == 200 && resp.data['ok'] == true;
  }

  Future<bool> sharePost(String postId) async {
    final resp = await api.post('/api/posts/$postId/share');
    return resp.statusCode == 200;
  }

  Future<bool> deletePost(String postId) async {
    final resp = await api.delete('/api/posts/$postId');
    return resp.statusCode == 200;
  }
}
