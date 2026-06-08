import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

typedef NavigationCallback = void Function(String route, dynamic arguments);

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static NavigationCallback? onNavigate;
  static Future<void> Function(String token)? onTokenUpdate;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true, badge: true, sound: true,
    );
    if (settings.authorizationStatus != AuthorizationStatus.authorized) return;

    final token = await _messaging.getToken();
    if (token != null) _sendTokenToServer(token);

    _messaging.onTokenRefresh.listen(_sendTokenToServer);
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('FCM: ${message.notification?.title}');
  }

  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];
    final targetId = data['targetId'];

    if (onNavigate == null) return;

    switch (type) {
      case 'chat':
        onNavigate!('/conversation', targetId);
        break;
      case 'friend_request':
        onNavigate!('/friend-requests', null);
        break;
      case 'room':
        onNavigate!('/room', targetId);
        break;
      case 'post':
        onNavigate!('/posts', null);
        break;
    }
  }

  void _sendTokenToServer(String token) {
    onTokenUpdate?.call(token);
  }
}
