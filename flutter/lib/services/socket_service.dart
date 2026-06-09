import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  IO.Socket? socket;
  final Map<String, List<Function(dynamic)>> _handlers = {};

  void connect(String url, String token) {
    socket = IO.io(url, {
      'transports': ['websocket'],
      'extraHeaders': {'Authorization': 'Bearer $token'}
    });

    socket?.on('connect', (_) => debugPrint('socket connected'));
    socket?.on('disconnect', (_) => debugPrint('socket disconnected'));

    // re-register handlers if any
    _handlers.forEach((event, list) {
      socket?.on(event, (data) {
        for (final h in list) {
          try { h(data); } catch (e) {}
        }
      });
    });
  }

  void on(String event, Function(dynamic) handler) {
    _handlers.putIfAbsent(event, () => []).add(handler);
    socket?.on(event, handler);
  }

  void off(String event, [Function? handler]) {
    if (handler == null) {
      _handlers.remove(event);
      socket?.off(event);
    } else {
      final list = _handlers[event];
      list?.remove(handler);
      socket?.off(event, handler as dynamic);
    }
  }

  void joinRoom(String roomId, Map user) {
    socket?.emit('joinRoom', {'roomId': roomId, 'user': user});
  }

  void sendMessage(Map payload) {
    socket?.emit('roomMessage', payload);
  }

  void dispose() {
    try { socket?.disconnect(); } catch (e) {}
    try { socket?.dispose(); } catch (e) {}
    _handlers.clear();
  }
}
