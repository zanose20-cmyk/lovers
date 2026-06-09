import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/api_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final api = context.read<ApiProvider>().api;
      final resp = await api.get('/api/admin/stats');
      if (resp.statusCode == 200 && mounted) {
        setState(() {
          _stats = resp.data;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('لوحة التحكم'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadStats),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('إحصائيات عامة', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _StatCard(icon: Icons.people, label: 'المستخدمون', value: '${_stats?['totalUsers'] ?? 0}', color: AppColors.primary),
                        _StatCard(icon: Icons.forum, label: 'الغرف', value: '${_stats?['totalRooms'] ?? 0}', color: AppColors.success),
                        _StatCard(icon: Icons.card_giftcard, label: 'الهدايا', value: '${_stats?['totalGifts'] ?? 0}', color: AppColors.neonPink),
                        _StatCard(icon: Icons.article, label: 'المنشورات', value: '${_stats?['totalPosts'] ?? 0}', color: AppColors.primary),
                        _StatCard(icon: Icons.work, label: 'الوكالات', value: '${_stats?['totalAgencies'] ?? 0}', color: Colors.amber),
                        _StatCard(icon: Icons.person_search, label: 'المستخدمون النشطون', value: '${_stats?['activeUsers'] ?? 0}', color: AppColors.success),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('الإدارة', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _AdminMenuItem(Icons.people_outline, 'إدارة المستخدمين', onTap: () => Navigator.pushNamed(context, '/admin-users')),
                    _AdminMenuItem(Icons.forum_outlined, 'إدارة الغرف', onTap: () => Navigator.pushNamed(context, '/admin-rooms')),
                    _AdminMenuItem(Icons.card_giftcard_outlined, 'إدارة الهدايا', onTap: () => Navigator.pushNamed(context, '/admin-gifts')),
                    _AdminMenuItem(Icons.inventory_2_outlined, 'إدارة المركبات', onTap: () => Navigator.pushNamed(context, '/admin-vehicles')),
                    _AdminMenuItem(Icons.shield_outlined, 'التقارير والبلاغات'),
                    _AdminMenuItem(Icons.history, 'سجل الأحداث'),
                  ],
                ),
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
        ],
      ),
    );
  }
}

class _AdminMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const _AdminMenuItem(this.icon, this.title, {this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
        trailing: const Icon(Icons.chevron_left, color: AppColors.textHint),
        tileColor: AppColors.backgroundCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }
}
