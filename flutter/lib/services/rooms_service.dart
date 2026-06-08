import 'api_service.dart';

class RoomsService {
  final ApiService api;

  RoomsService(this.api);

  Future<List<dynamic>> listRooms({String? type, int page = 1, int limit = 20}) async {
    final params = <String, String>{'page': '$page', 'limit': '$limit'};
    if (type != null) params['type'] = type;
    final resp = await api.get('/api/rooms', queryParams: params);
    if (resp.statusCode == 200) return resp.data['rooms'] ?? [];
    return [];
  }

  Future<Map?> getRoom(String roomId) async {
    final resp = await api.get('/api/rooms/$roomId');
    if (resp.statusCode == 200) return resp.data;
    return null;
  }

  Future<Map?> createRoom(Map<String, dynamic> body) async {
    final resp = await api.post('/api/rooms', body: body);
    if (resp.statusCode == 200 && resp.data['ok'] == true) return resp.data['room'];
    return null;
  }

  Future<bool> joinRoom(String roomId, {String? password}) async {
    final resp = await api.post('/api/rooms/$roomId/join', body: password != null ? {'password': password} : {});
    return resp.statusCode == 200 && resp.data['ok'] == true;
  }

  Future<bool> leaveRoom(String roomId) async {
    final resp = await api.post('/api/rooms/$roomId/leave');
    return resp.statusCode == 200 && resp.data['ok'] == true;
  }

  Future<Map?> getVoiceAccess(String roomId) async {
    final resp = await api.post('/api/rooms/$roomId/voice-access', body: {});
    if (resp.statusCode == 200) return resp.data;
    return null;
  }

  Future<bool> muteUser(String roomId, String userId, {bool mute = true}) async {
    final resp = await api.post('/api/rooms/$roomId/mute', body: {'userId': userId, 'mute': mute});
    return resp.statusCode == 200 && resp.data['ok'] == true;
  }

  Future<bool> lockSeat(String roomId, int seatIndex, {bool lock = true}) async {
    final resp = await api.post('/api/rooms/$roomId/lock-seat', body: {'seatIndex': seatIndex, 'lock': lock});
    return resp.statusCode == 200 && resp.data['ok'] == true;
  }
}
