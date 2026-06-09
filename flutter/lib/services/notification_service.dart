import 'dart:async';
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
  StreamSubscription<String>? _tokenSub;
  StreamSubscription<RemoteMessage>? _messageSub;
  StreamSubscription<RemoteMessage>? _tapSub;

  Future<void> initialize() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true, badge: true, sound: true,
    );
    if (settings.authorizationStatus != AuthorizationStatus.authorized) return;

    final token = await _messaging.getToken();
    if (token != null) _sendTokenToServer(token);

    _tokenSub?.cancel();
    _tokenSub = _messaging.onTokenRefresh.listen(_sendTokenToServer);
    _messageSub?.cancel();
    _messageSub = FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    _tapSub?.cancel();
    _tapSub = FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  void dispose() {
    _tokenSub?.cancel();
    _messageSub?.cancel();
    _tapSub?.cancel();
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
      case 'room_invite':
        onNavigate!('/room', targetId);
        break;
      case 'post':
        onNavigate!('/posts', null);
        break;
      case 'like':
      case 'comment':
        onNavigate!('/posts', null);
        break;
      case 'gift':
        onNavigate!('/store', null);
        break;
      case 'follow':
        onNavigate!('/profile', targetId);
        break;
      case 'vip':
        onNavigate!('/vip', null);
        break;
      case 'daily_reward':
        onNavigate!('/daily-tasks', null);
        break;
      case 'achievement':
        onNavigate!('/profile', null);
        break;
      case 'agency':
        onNavigate!('/agencies', null);
        break;
    }
  }

  void _sendTokenToServer(String token) {
    onTokenUpdate?.call(token);
  }
}
