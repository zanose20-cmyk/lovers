import 'package:flutter/foundation.dart';
import '../models/agency_model.dart';
import '../services/api_service.dart';
import '../services/agencies_service.dart';

class AgenciesProvider extends ChangeNotifier {
  final AgenciesService _service;
  List<AgencyModel> _agencies = [];
  bool _isLoading = false;
  String? _error;

  AgenciesProvider(ApiService api) : _service = AgenciesService(api);

  List<AgencyModel> get agencies => _agencies;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAgencies() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _service.listAgencies();
      _agencies = data.map((e) => AgencyModel.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<AgencyModel?> createAgency(String name, {String? description}) async {
    try {
      final data = await _service.createAgency(name, description: description);
      if (data != null) {
        final agency = AgencyModel.fromJson(data);
        _agencies.insert(0, agency);
        notifyListeners();
        return agency;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
    return null;
  }

  Future<bool> joinAgency(String agencyId) async {
    try {
      return await _service.joinAgency(agencyId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> leaveAgency(String agencyId) async {
    try {
      return await _service.leaveAgency(agencyId);
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
