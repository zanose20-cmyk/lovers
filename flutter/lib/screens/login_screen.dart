import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/native_google_sign_in.dart';
import '../services/auth_provider.dart' as app_auth;
import '../services/api_service.dart';
import '../config/app_config.dart';
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
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _scaleIn = Tween<double>(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _animController, curve: Curves.elasticOut));
    _animController.forward();
    _silentSignIn();
  }

  Future<void> _silentSignIn() async {
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
      if (mounted) setState(() => _error = 'Google: ${e.message}');
    } on SocketException catch (e) {
      if (mounted) setState(() => _error = 'لا يوجد اتصال بالإنترنت');
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _signInWithGoogle() async {
    try {
      final result = await NativeGoogleSignIn.signIn(_webClientId);
      if (result == null) return;
      await _handleGoogleResult(result);
    } on PlatformException catch (e) {
      if (mounted) setState(() => _error = 'Google: ${e.message}');
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _signInAsGuest() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api = ApiService(AppConfig.serverUrl);
      final resp = await api.post('/api/auth/guest');
      if (resp.statusCode == 200 && resp.data['token'] != null) {
        final auth = context.read<app_auth.AuthProvider>();
        auth.setToken(resp.data['token']);
        auth.setUser(Map<String, dynamic>.from(resp.data['user']));
        if (mounted) Navigator.pushReplacementNamed(context, '/home');
      } else {
        if (mounted) setState(() => _error = 'فشل الدخول كضيف');
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
    if (mounted) setState(() => _loading = false);
  }

  void _showPhoneOTPDialog() {
    final phoneController = TextEditingController();
    final otpController = TextEditingController();
    bool otpSent = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textHint, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text(otpSent ? 'أدخل رمز التحقق' : 'تسجيل الدخول بالهاتف', style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              if (!otpSent) ...[
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    hintText: '+966 5XX XXX XXXX',
                    hintStyle: const TextStyle(color: AppColors.textHint),
                    prefixIcon: const Icon(Icons.phone, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.backgroundCardLight)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.backgroundCardLight)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
                  ),
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      final phone = phoneController.text.trim();
                      if (phone.isEmpty) return;
                      try {
                        final api = ApiService(AppConfig.serverUrl);
                        final resp = await api.post('/api/auth/otp/send', body: {'phoneNumber': phone});
                        if (resp.statusCode == 200) {
                          setModalState(() => otpSent = true);
                        } else {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp.data['error'] ?? 'فشل إرسال الرمز')));
                        }
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('إرسال رمز التحقق', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ] else ...[
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  maxLength: 6,
                  decoration: InputDecoration(
                    hintText: '------',
                    hintStyle: const TextStyle(color: AppColors.textHint, letterSpacing: 8),
                    counterText: '',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.backgroundCardLight)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.backgroundCardLight)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
                  ),
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 24, letterSpacing: 8),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      final otp = otpController.text.trim();
                      if (otp.length != 6) return;
                      try {
                        final api = ApiService(AppConfig.serverUrl);
                        final resp = await api.post('/api/auth/otp/verify', body: {
                          'phoneNumber': phoneController.text.trim(),
                          'otp': otp,
                        });
                        if (resp.statusCode == 200 && resp.data['token'] != null) {
                          final auth = context.read<app_auth.AuthProvider>();
                          auth.setToken(resp.data['token']);
                          auth.setUser(Map<String, dynamic>.from(resp.data['user']));
                          if (mounted) {
                            Navigator.pop(ctx);
                            Navigator.pushReplacementNamed(context, '/home');
                          }
                        } else {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp.data['error'] ?? 'رمز غير صحيح')));
                        }
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('تحقق', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
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
                          boxShadow: [BoxShadow(color: const Color(0xFFE94560).withValues(alpha: 0.3), blurRadius: 30, spreadRadius: 5)],
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
                      _buildLoginButton(
                        onPressed: _loading ? null : _signInWithGoogle,
                        icon: Icons.g_mobiledata_rounded,
                        label: 'Google',
                        color: Colors.white,
                        textColor: Colors.black87,
                      ),
                      const SizedBox(height: 12),
                      _buildLoginButton(
                        onPressed: _loading ? null : _showPhoneOTPDialog,
                        icon: Icons.phone_rounded,
                        label: 'الهاتف',
                        color: AppColors.primary,
                        textColor: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      _buildLoginButton(
                        onPressed: _loading ? null : () {},
                        icon: Icons.facebook,
                        label: 'Facebook',
                        color: const Color(0xFF1877F2),
                        textColor: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      _buildLoginButton(
                        onPressed: _loading ? null : () {},
                        icon: Icons.apple,
                        label: 'Apple',
                        color: Colors.white,
                        textColor: Colors.black87,
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: _loading ? null : _signInAsGuest,
                        child: const Text('الدخول كضيف', style: TextStyle(color: AppColors.textHint, fontSize: 14)),
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

  Widget _buildLoginButton({required VoidCallback? onPressed, required IconData icon, required String label, required Color color, required Color textColor}) {
    return SizedBox(
      width: double.infinity, height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 22),
        label: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
