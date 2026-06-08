import 'api_service.dart';

class TasksService {
  final ApiService api;
  TasksService(this.api);

  Future<Map?> getDailyTasks() async {
    final resp = await api.get('/api/tasks/daily');
    if (resp.statusCode == 200) return resp.data;
    return null;
  }

  Future<bool> claimDailyReward(String taskId) async {
    final resp = await api.post('/api/tasks/daily/claim', body: {'taskId': taskId});
    return resp.statusCode == 200 && resp.data['ok'] == true;
  }

  Future<Map?> dailyLogin() async {
    final resp = await api.post('/api/tasks/daily/login');
    if (resp.statusCode == 200) return resp.data;
    return null;
  }
}
