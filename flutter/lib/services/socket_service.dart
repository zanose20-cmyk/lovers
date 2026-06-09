import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  IO.Socket? socket;
  final Map<String, List<Function(dynamic)>> _handlers = {};
  bool _connected = false;

  void connect(String url, String token) {
    if (_connected) return;
    socket = IO.io(url, {
      'transports': ['websocket'],
      'extraHeaders': {'Authorization': 'Bearer $token'}
    });

    socket?.on('connect', (_) => debugPrint('socket connected'));
    socket?.on('disconnect', (_) {
      _connected = false;
      debugPrint('socket disconnected');
    });
    socket?.on('connect_error', (err) {
      _connected = false;
      debugPrint('socket connect_error: $err');
    });

    _connected = true;

    _handlers.forEach((event, list) {
      socket?.on(event, (data) {
        for (final h in list) {
          try { h(data); } catch (e) {}
        }
      });
    });
  }

  void on(String event, Function(dynamic) handler) {
    final list = _handlers.putIfAbsent(event, () => []);
    list.add(handler);
    if (_connected) {
      socket?.on(event, (data) {
        for (final h in list) {
          try { h(data); } catch (e) {}
        }
      });
    }
  }

  void off(String event, [Function? handler]) {
    if (handler == null) {
      _handlers.remove(event);
      socket?.off(event);
    } else {
      final list = _handlers[event];
      list?.remove(handler);
      socket?.off(event);
    }
  }

  void joinRoom(String roomId, Map user) {
    socket?.emit('joinRoom', {'roomId': roomId, 'user': user});
  }

  void sendMessage(Map payload) {
    socket?.emit('roomMessage', payload);
  }

  void emit(String event, [dynamic data]) {
    socket?.emit(event, data);
  }

  void dispose() {
    _connected = false;
    try { socket?.disconnect(); } catch (e) {}
    try { socket?.dispose(); } catch (e) {}
    _handlers.clear();
    socket = null;
  }
}
