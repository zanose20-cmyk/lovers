import 'package:flutter/foundation.dart';
import '../models/gift_model.dart';
import '../services/api_service.dart';
import '../services/gift_service.dart';

class GiftsProvider extends ChangeNotifier {
  final GiftService _service;
  List<GiftModel> _gifts = [];
  bool _isLoading = false;
  String? _error;

  GiftsProvider(ApiService api) : _service = GiftService(api);

  List<GiftModel> get gifts => _gifts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadGifts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _service.fetchGifts();
      _gifts = data.map((e) => GiftModel.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> sendGift(String toUserId, String sku, int count, {String? roomId}) async {
    try {
      return await _service.sendGift(toUserId, sku, count, roomId: roomId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendGiftToRoom(String roomId, String sku, int count) async {
    try {
      return await _service.sendGiftToRoom(roomId, sku, count);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
