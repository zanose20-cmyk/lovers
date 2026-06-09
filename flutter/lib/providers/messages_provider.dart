import 'package:flutter/foundation.dart';
import '../models/message_model.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class MessagesProvider extends ChangeNotifier {
  final ApiService _api;
  final SocketService _socket = SocketService();
  List<ConversationModel> _conversations = [];
  List<MessageModel> _messages = [];
  String? _currentChatUserId;
  bool _isLoading = false;
  String? _error;

  MessagesProvider(this._api);

  List<ConversationModel> get conversations => _conversations;
  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _conversations.fold(0, (sum, c) => sum + (c.unread ?? 0));
  SocketService get socketService => _socket;

  void listenForMessages(String myUserId) {
    _socket.on('privateMessage', (data) {
      try {
        final msg = MessageModel.fromJson(data);
        if (msg.fromUserId == _currentChatUserId || msg.toUserId == _currentChatUserId) {
          if (msg.fromUserId != myUserId) {
            _messages.add(msg);
            notifyListeners();
          }
        }
        final otherUserId = msg.fromUserId == myUserId ? msg.toUserId : msg.fromUserId;
        final idx = _conversations.indexWhere((c) => c.user?['userId'] == otherUserId);
        if (idx != -1) {
          _conversations[idx] = ConversationModel(
            user: _conversations[idx].user,
            lastMessage: msg,
            unread: msg.fromUserId == _currentChatUserId ? 0 : (_conversations[idx].unread ?? 0) + 1,
          );
          notifyListeners();
        }
      } catch (_) {}
    });
  }

  void setCurrentChatUser(String? userId) {
    _currentChatUserId = userId;
  }

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

  Future<bool> sendMessage(String toUserId, String content, {String type = 'text'}) async {
    try {
      final resp = await _api.post('/api/messages/private', body: {
        'toUserId': toUserId,
        'content': content,
        'type': type,
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

  @override
  void dispose() {
    _socket.dispose();
    super.dispose();
  }
}
