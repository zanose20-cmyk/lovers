import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/native_google_sign_in.dart';
import '../services/auth_provider.dart' as app_auth;
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;
  bool _loading = false;
  String? _error;
  static const String _webClientId = '364291041039-ru2cih28rmrh1gvctbv2ovosjq2nb98p.apps.googleusercontent.com';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _scaleIn = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
    _animController.forward();
    _silentSignIn();
  }

  Future<void> _silentSignIn() async {
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
    } catch (_) {}
    try {
      final result = await NativeGoogleSignIn.signInSilently(_webClientId);
      if (result != null) await _handleGoogleResult(result);
    } catch (_) {}
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleResult(Map<String, dynamic> result) async {
    setState(() { _loading = true; _error = null; });
    try {
      final idToken = result['idToken'] as String?;
      if (idToken == null || idToken.isEmpty) throw Exception('لا يوجد رمز توثيق');

      final auth = context.read<app_auth.AuthProvider>();
      final ok = await auth.loginWithGoogle(idToken);
      if (mounted) {
        if (ok) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          setState(() => _error = 'فشل تسجيل الدخول');
        }
      }
    } on PlatformException catch (e) {
      setState(() => _error = 'Google: ${e.message}');
    } on SocketException catch (e) {
      setState(() => _error = 'نت مشكلة: ${e.message}');
    } on FirebaseAuthException catch (e) {
      setState(() => _error = 'Firebase: ${e.message}');
    } catch (e) {
      setState(() => _error = '$e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _signInWithGoogle() async {
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
    } catch (_) {}
    try {
      final result = await NativeGoogleSignIn.signIn(_webClientId);
      if (result == null) return;
      await _handleGoogleResult(result);
    } on PlatformException catch (e) {
      setState(() => _error = 'Google: ${e.message}');
    } catch (e) {
      setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D0D1A), Color(0xFF1A0A2E), Color(0xFF16213E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              FadeTransition(
                opacity: _fadeIn,
                child: ScaleTransition(
                  scale: _scaleIn,
                  child: Column(
                    children: [
                      Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(colors: [Color(0xFFE94560), Color(0xFF0F3460)]),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE94560).withValues(alpha: 0.3),
                              blurRadius: 30, spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('L', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('LOVERS', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 8, color: Colors.white)),
                      const SizedBox(height: 8),
                      const Text('تواصل بلا حدود', style: TextStyle(fontSize: 15, color: Color(0xFF8899AA))),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 1),
              FadeTransition(
                opacity: _fadeIn,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      if (_error != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE94560).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFE94560), fontSize: 13)),
                        ),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _signInWithGoogle,
                          icon: _loading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Image.asset('assets/images/google_logo.png', width: 22, height: 22, errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata_rounded, size: 26)),
                          label: Text(_loading ? 'جاري تسجيل الدخول...' : 'تسجيل الدخول بواسطة Google', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            shadowColor: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}