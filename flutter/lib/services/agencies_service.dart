import 'api_service.dart';

class AgenciesService {
  final ApiService api;
  AgenciesService(this.api);

  Future<List<dynamic>> listAgencies({int page = 1}) async {
    final resp = await api.get('/api/agencies', queryParams: {'page': '$page'});
    if (resp.statusCode == 200) return resp.data['agencies'] ?? [];
    return [];
  }

  Future<Map?> getAgency(String agencyId) async {
    final resp = await api.get('/api/agencies/$agencyId');
    if (resp.statusCode == 200) return resp.data;
    return null;
  }

  Future<Map?> createAgency(String name, {String? description}) async {
    final resp = await api.post('/api/agencies', body: {'name': name, 'description': description ?? ''});
    if (resp.statusCode == 200 && resp.data['ok'] == true) return resp.data['agency'];
    return null;
  }

  Future<bool> joinAgency(String agencyId) async {
    final resp = await api.post('/api/agencies/$agencyId/join');
    return resp.statusCode == 200 && resp.data['ok'] == true;
  }

  Future<bool> leaveAgency(String agencyId) async {
    final resp = await api.post('/api/agencies/$agencyId/leave');
    return resp.statusCode == 200 && resp.data['ok'] == true;
  }
}
