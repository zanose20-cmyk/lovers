import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;
  final http.Client _client = http.Client();
  String? _token;

  ApiService(this.baseUrl);

  void setToken(String token) => _token = token;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<ApiResponse> get(String path, {Map<String, String>? queryParams, Map<String, String>? headers}) async {
    try {
      final uri = Uri.parse('$baseUrl$path').replace(queryParameters: queryParams);
      final response = await _client.get(uri, headers: {..._headers, ...?headers});
      return _parseResponse(response);
    } catch (e) {
      return ApiResponse(statusCode: 0, data: {'error': 'Network error: $e'});
    }
  }

  Future<ApiResponse> post(String path, {Map<String, dynamic>? body, Map<String, String>? headers}) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final response = await _client.post(uri, headers: {..._headers, ...?headers}, body: body != null ? jsonEncode(body) : null);
      return _parseResponse(response);
    } catch (e) {
      return ApiResponse(statusCode: 0, data: {'error': 'Network error: $e'});
    }
  }

  Future<ApiResponse> put(String path, {Map<String, dynamic>? body, Map<String, String>? headers}) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final response = await _client.put(uri, headers: {..._headers, ...?headers}, body: body != null ? jsonEncode(body) : null);
      return _parseResponse(response);
    } catch (e) {
      return ApiResponse(statusCode: 0, data: {'error': 'Network error: $e'});
    }
  }

  Future<ApiResponse> delete(String path, {Map<String, String>? headers}) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final response = await _client.delete(uri, headers: {..._headers, ...?headers});
      return _parseResponse(response);
    } catch (e) {
      return ApiResponse(statusCode: 0, data: {'error': 'Network error: $e'});
    }
  }

  ApiResponse _parseResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return ApiResponse(statusCode: response.statusCode, data: data);
    } catch (_) {
      return ApiResponse(statusCode: response.statusCode, data: {'error': response.body});
    }
  }

  void dispose() => _client.close();
}

class ApiResponse {
  final int statusCode;
  final Map<String, dynamic> data;
  ApiResponse({required this.statusCode, required this.data});
}
