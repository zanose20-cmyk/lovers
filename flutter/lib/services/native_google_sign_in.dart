import 'package:flutter/services.dart';

class NativeGoogleSignIn {
  static const _channel = MethodChannel('com.example.lovers_app/google_sign_in');

  static Future<Map<String, dynamic>?> signIn(String webClientId) async {
    final result = await _channel.invokeMethod('signIn', {
      'webClientId': webClientId,
    });
    if (result == null) return null;
    return Map<String, dynamic>.from(result as Map);
  }

  static Future<Map<String, dynamic>?> signInSilently(String webClientId) async {
    final result = await _channel.invokeMethod('signInSilently', {
      'webClientId': webClientId,
    });
    if (result == null) return null;
    return Map<String, dynamic>.from(result as Map);
  }

  static Future<void> signOut() async {
    await _channel.invokeMethod('signOut');
  }
}
