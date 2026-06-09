import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';
import '../theme/app_theme.dart';

class AccountRecoveryScreen extends StatefulWidget {
  const AccountRecoveryScreen({super.key});

  @override
  State<AccountRecoveryScreen> createState() => _AccountRecoveryScreenState();
}

class _AccountRecoveryScreenState extends State<AccountRecoveryScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPassController = TextEditingController();
  bool _otpSent = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPassController.dispose();
    super.dispose();
  }

  Future<void> _requestRecovery() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'أدخل بريد صحيح');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final api = ApiService(AppConfig.serverUrl);
      final resp = await api.post('/api/auth/recovery/request', body: {'email': email});
      if (resp.statusCode == 200) {
        setState(() => _otpSent = true);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال رمز التحقق')));
      } else {
        setState(() => _error = resp.data['error'] ?? 'فشل إرسال الرمز');
      }
    } catch (e) {
      setState(() => _error = '$e');
    }
    setState(() => _loading = false);
  }

  Future<void> _verifyRecovery() async {
    final otp = _otpController.text.trim();
    final newPass = _newPassController.text.trim();
    if (otp.length != 6) {
      setState(() => _error = 'أدخل الرمز المكون من 6 أرقام');
      return;
    }
    if (newPass.length < 6) {
      setState(() => _error = 'كلمة المرور 6 أحرف على الأقل');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final api = ApiService(AppConfig.serverUrl);
      final resp = await api.post('/api/auth/recovery/verify', body: {
        'email': _emailController.text.trim(),
        'otp': otp,
        'newPassword': newPass,
      });
      if (resp.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تغيير كلمة المرور بنجاح')));
          Navigator.pop(context);
        }
      } else {
        setState(() => _error = resp.data['error'] ?? 'فشل التحقق');
      }
    } catch (e) {
      setState(() => _error = '$e');
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(title: const Text('استرداد الحساب')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            const Icon(Icons.lock_reset, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              _otpSent ? 'أدخل الرمز وكلمة المرور الجديدة' : 'أدخل بريدك الإلكتروني لاسترداد الحساب',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error, fontSize: 13)),
              ),
            if (!_otpSent) ...[
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  hintText: 'email@example.com',
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.backgroundCardLight)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.backgroundCardLight)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _requestRecovery,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('إرسال رمز الاسترداد', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ] else ...[
              TextField(
                controller: _otpController,
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
              TextField(
                controller: _newPassController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'كلمة المرور الجديدة',
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  prefixIcon: const Icon(Icons.vpn_key_outlined, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.backgroundCardLight)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.backgroundCardLight)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _verifyRecovery,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('إعادة تعيين كلمة المرور', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
