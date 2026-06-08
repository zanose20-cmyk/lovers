import 'package:flutter/foundation.dart';
import '../models/message_model.dart';
import '../services/api_service.dart';

class MessagesProvider extends ChangeNotifier {
  final ApiService _api;
  List<ConversationModel> _conversations = [];
  List<MessageModel> _messages = [];
  bool _isLoading = false;
  String? _error;

  MessagesProvider(this._api);

  List<ConversationModel> get conversations => _conversations;
  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadConversations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final resp = await _api.get('/api/messages/conversations');
      if (resp.statusCode == 200) {
        final list = resp.data['conversations'] as List? ?? [];
        _conversations = list.map((e) => ConversationModel.fromJson(e)).toList();
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMessages(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final resp = await _api.get('/api/messages/conversations/$userId');
      if (resp.statusCode == 200) {
        final list = resp.data['messages'] as List? ?? [];
        _messages = list.map((e) => MessageModel.fromJson(e)).toList();
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> sendMessage(String toUserId, String content) async {
    try {
      final resp = await _api.post('/api/messages/private', body: {
        'toUserId': toUserId,
        'content': content,
        'type': 'text',
      });
      if (resp.statusCode == 200 && resp.data['ok'] == true) {
        final msg = MessageModel.fromJson(resp.data['message']);
        _messages.add(msg);
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
    return false;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
