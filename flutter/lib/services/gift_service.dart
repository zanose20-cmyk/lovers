import 'api_service.dart';

class GiftService {
  final ApiService api;

  GiftService(this.api);

  Future<List<dynamic>> fetchGifts() async {
    final resp = await api.get('/api/store/gifts');
    if (resp.statusCode == 200) {
      final data = resp.data;
      if (data is List) return data as List<dynamic>;
      if (data['gifts'] is List) return (data['gifts'] as List<dynamic>);
      if (data['data'] is List) return (data['data'] as List<dynamic>);
    }
    return [];
  }

  Future<bool> sendGift(String toUserId, String sku, int count, {String? roomId}) async {
    final resp = await api.post('/api/gifts/send', body: {
      'toUserId': toUserId, 'giftSku': sku, 'count': count, 'roomId': roomId
    });
    return resp.statusCode == 200 && resp.data['ok'] == true;
  }

  Future<bool> sendGiftToRoom(String roomId, String sku, int count) async {
    final resp = await api.post('/api/gifts/room-send', body: {
      'roomId': roomId, 'giftSku': sku, 'count': count
    });
    return resp.statusCode == 200 && resp.data['ok'] == true;
  }
}
