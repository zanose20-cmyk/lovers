import 'package:flutter/foundation.dart';
import '../models/room_model.dart';
import '../services/api_service.dart';
import '../services/rooms_service.dart';

class RoomsProvider extends ChangeNotifier {
  final RoomsService _service;
  List<RoomModel> _rooms = [];
  RoomModel? _currentRoom;
  bool _isLoading = false;
  String? _error;

  RoomsProvider(ApiService api) : _service = RoomsService(api);

  List<RoomModel> get rooms => _rooms;
  RoomModel? get currentRoom => _currentRoom;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadRooms({String? type}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _service.listRooms(type: type);
      _rooms = data.map((e) => RoomModel.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadRoom(String roomId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _service.getRoom(roomId);
      if (data != null) _currentRoom = RoomModel.fromJson(data);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<RoomModel?> createRoom(Map<String, dynamic> body) async {
    try {
      final data = await _service.createRoom(body);
      if (data != null) {
        final room = RoomModel.fromJson(data);
        _rooms.insert(0, room);
        notifyListeners();
        return room;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
    return null;
  }

  Future<bool> joinRoom(String roomId, {String? password}) async {
    try {
      final ok = await _service.joinRoom(roomId, password: password);
      if (ok) await loadRoom(roomId);
      return ok;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> leaveRoom(String roomId) async {
    try {
      final ok = await _service.leaveRoom(roomId);
      if (ok) _currentRoom = null;
      notifyListeners();
      return ok;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<Map?> getVoiceAccess(String roomId) async {
    try {
      return await _service.getVoiceAccess(roomId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
