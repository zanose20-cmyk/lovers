import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../config/app_config.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  bool _isInitialized = false;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _token != null;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('server_token');
    final userData = prefs.getString('user_data');
    if (userData != null) {
      _user = jsonDecode(userData) as Map<String, dynamic>;
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<bool> loginWithGoogle(String idToken) async {
    _isLoading = true;
    notifyListeners();
    try {
      final api = ApiService(AppConfig.serverUrl);
      final response = await api.post('/api/auth/firebase', body: {'idToken': idToken});
      if (response.statusCode == 200) {
        _token = response.data['token'] as String;
        _user = response.data['user'] as Map<String, dynamic>;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('server_token', _token!);
        await prefs.setString('user_data', jsonEncode(_user));
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Google login error: $e');
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> loginWithFirebase(String idToken) async {
    _isLoading = true;
    notifyListeners();
    try {
      final api = ApiService(AppConfig.serverUrl);
      final response = await api.post('/api/auth/firebase', body: {'idToken': idToken});
      if (response.statusCode == 200) {
        _token = response.data['token'] as String;
        _user = response.data['user'] as Map<String, dynamic>;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('server_token', _token!);
        await prefs.setString('user_data', jsonEncode(_user));
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Firebase login error: $e');
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  void setToken(String t) {
    _token = t;
    notifyListeners();
  }

  void setUser(Map<String, dynamic> u) {
    _user = u;
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('server_token');
    await prefs.remove('user_data');
    notifyListeners();
  }
}
