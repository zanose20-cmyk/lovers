import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';
import '../services/rooms_service.dart';
import '../services/gift_service.dart';
import '../services/wallet_service.dart';
import '../services/posts_service.dart';
import '../services/agencies_service.dart';
import '../services/tasks_service.dart';

class ApiProvider extends ChangeNotifier {
  final ApiService api;
  String? _token;

  ApiProvider() : api = ApiService(AppConfig.serverUrl);

  void setToken(String? t) {
    _token = t;
    if (t != null) api.setToken(t);
    notifyListeners();
  }

  String? get token => _token;

  RoomsService roomsService() => RoomsService(api);
  GiftService giftService() => GiftService(api);
  WalletService walletService() => WalletService(api);
  PostsService postsService() => PostsService(api);
  AgenciesService agenciesService() => AgenciesService(api);
  TasksService tasksService() => TasksService(api);
}
