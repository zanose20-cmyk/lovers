import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _sound = true;
  bool _vibration = true;
  bool _autoJoin = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(title: const Text('الإعدادات')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('الإشعارات', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            _SettingsSwitch(title: 'إشعارات التطبيق', subtitle: 'تلقي الإشعارات العامة', value: _notifications, onChanged: (v) => setState(() => _notifications = v)),
            const SizedBox(height: 24),
            const Text('الصوت', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            _SettingsSwitch(title: 'صوت الإشعارات', subtitle: 'تشغيل صوت عند الإشعارات', value: _sound, onChanged: (v) => setState(() => _sound = v)),
            _SettingsSwitch(title: 'اهتزاز', subtitle: 'اهتزاز الجهاز عند الإشعارات', value: _vibration, onChanged: (v) => setState(() => _vibration = v)),
            const SizedBox(height: 24),
            const Text('الغرف', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            _SettingsSwitch(title: 'الانضمام التلقائي', subtitle: 'الدخول التلقائي للغرفة عند الدعوة', value: _autoJoin, onChanged: (v) => setState(() => _autoJoin = v)),
            const SizedBox(height: 24),
            const Text('الحساب', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            InfoRow(label: 'اسم المستخدم', value: auth.user?['displayName'] ?? 'زائر'),
            InfoRow(label: 'معرف المستخدم', value: auth.user?['userId'] ?? '-'),
            InfoRow(label: 'المستوى', value: '${auth.user?['level'] ?? 1}'),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.backgroundCard,
                    title: const Text('تسجيل الخروج', style: TextStyle(color: AppColors.textPrimary)),
                    content: const Text('هل أنت متأكد؟', style: TextStyle(color: AppColors.textSecondary)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('إلغاء', style: TextStyle(color: AppColors.textHint)),
                      ),
                      TextButton(
                        onPressed: () {
                          auth.logout();
                          Navigator.pop(ctx);
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: const Text('تسجيل الخروج', style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('تسجيل الخروج'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error.withValues(alpha: 0.1),
                  foregroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSwitch extends StatelessWidget {
  final String title; final String subtitle; final bool value; final ValueChanged<bool> onChanged;
  const _SettingsSwitch({required this.title, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: AppColors.backgroundCard, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(subtitle, style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeThumbColor: AppColors.primary),
        ],
      ),
    );
  }
}
