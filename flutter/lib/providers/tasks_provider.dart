import 'package:flutter/foundation.dart';
import '../models/daily_task_model.dart';
import '../services/api_service.dart';
import '../services/tasks_service.dart';

class TasksProvider extends ChangeNotifier {
  final TasksService _service;
  List<DailyTaskModel> _tasks = [];
  bool _isLoading = false;
  String? _error;
  bool? _dailyLogin;
  int? _loginStreak;
  int? _activityMinutes;

  TasksProvider(ApiService api) : _service = TasksService(api);

  List<DailyTaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool? get dailyLogin => _dailyLogin;
  int? get loginStreak => _loginStreak;
  int? get activityMinutes => _activityMinutes;

  Future<void> loadDailyTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _service.getDailyTasks();
      if (data != null) {
        final list = data['tasks'] as List? ?? [];
        _tasks = list.map((e) => DailyTaskModel.fromJson(e)).toList();
        _dailyLogin = data['dailyLogin'];
        _loginStreak = data['loginStreak'];
        _activityMinutes = data['activityMinutes'];
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> claimReward(String taskId) async {
    try {
      return await _service.claimDailyReward(taskId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> doDailyLogin() async {
    try {
      final data = await _service.dailyLogin();
      if (data != null && data['ok'] == true) {
        _dailyLogin = true;
        _loginStreak = data['streak'];
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
