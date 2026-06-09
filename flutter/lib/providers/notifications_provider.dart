import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';

class NotificationsProvider extends ChangeNotifier {
  final ApiService _api;
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;
  int _unread = 0;

  NotificationsProvider(this._api);

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unread => _unread;

  Future<void> loadNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final resp = await _api.get('/api/users/me/notifications');
      if (resp.statusCode == 200) {
        final list = resp.data['notifications'] as List? ?? [];
        _notifications = list.map((e) => NotificationModel.fromJson(e)).toList();
        _unread = (resp.data['unread'] as num?)?.toInt() ?? 0;
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> markRead(String notifId) async {
    try {
      final resp = await _api.put('/api/users/me/notifications/$notifId/read');
      if (resp.statusCode == 200) {
        final idx = _notifications.indexWhere((n) => n.notifId == notifId);
        if (idx != -1) {
          _notifications[idx].isRead = true;
          _unread = (_unread - 1).clamp(0, 999999);
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
    return false;
  }

  Future<bool> markAllRead() async {
    try {
      final resp = await _api.put('/api/users/me/notifications/read-all');
      if (resp.statusCode == 200) {
        for (var n in _notifications) {
          n.isRead = true;
        }
        _unread = 0;
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
