import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/api_provider.dart';
import '../models/vip_level_model.dart';

class VIPScreen extends StatefulWidget {
  const VIPScreen({super.key});

  @override
  State<VIPScreen> createState() => _VIPScreenState();
}

class _VIPScreenState extends State<VIPScreen> {
  List<VIPLevelModel> _levels = [];
  bool _loading = true;

  Color _parseColor(String? colorStr, {Color fallback = AppColors.gold}) {
    if (colorStr == null || colorStr.isEmpty) return fallback;
    try {
      final hex = colorStr.replaceFirst('#', '').padLeft(6, '0');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadVIP();
  }

  Future<void> _loadVIP() async {
    final api = context.read<ApiProvider>().api;
    try {
      final resp = await api.get('/api/vip/levels');
      if (resp.statusCode == 200) {
        final list = resp.data;
        final data = (list is List) ? list : (resp.data['levels'] ?? []);
        _levels = data.map((e) => VIPLevelModel.fromJson(e)).toList();
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('VIP'),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.diamond, color: AppColors.gold, size: 16),
                SizedBox(width: 4),
                Text('VIP 0', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_levels.isNotEmpty)
                    Builder(builder: (ctx) {
                      final vip = _levels.first;
                      final vipColor = _parseColor(vip.color);
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [vipColor, const Color(0xFFFF8C00)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 2)],
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.diamond, size: 60, color: Colors.white),
                            const SizedBox(height: 12),
                            Text('VIP ${vip.level} - ${vip.name ?? ''}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 8),
                            if (vip.priceCoins != null && vip.priceCoins! > 0)
                              Text('${vip.priceCoins} عملة', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 24),
                  const Text('مميزات VIP', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  ..._levels.take(5).map((vip) {
                    final benefits = vip.benefits ?? [];
                    return Column(
                      children: benefits.take(5).map((b) => _BenefitCard(
                        icon: Icons.diamond_outlined,
                        title: b,
                        description: vip.name ?? '',
                      )).toList(),
                    );
                  }),
                  const SizedBox(height: 24),
                  const Text('جميع مستويات VIP', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  ..._levels.map((vip) => _VIPLevelCard(
                    level: vip.level ?? 0,
                    name: vip.name ?? '',
                    price: vip.priceCoins ?? 0,
                    color: _parseColor(vip.color),
                    isCurrent: false,
                    isLocked: true,
                  )),
                ],
              ),
            ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  final IconData icon; final String title; final String description;
  const _BenefitCard({required this.icon, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.gold, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(description, style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VIPLevelCard extends StatelessWidget {
  final int level; final String name; final int price;
  final Color color; final bool isCurrent; final bool isLocked;
  const _VIPLevelCard({required this.level, required this.name, required this.price, required this.color, required this.isCurrent, required this.isLocked});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCurrent ? color.withValues(alpha: 0.1) : AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isCurrent ? color : AppColors.backgroundCardLight, width: isCurrent ? 2 : 1),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isLocked ? Icons.lock_outline : Icons.diamond,
              color: isLocked ? AppColors.textHint : color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('VIP $level', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(name, style: TextStyle(color: color, fontSize: 12)),
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
                        child: const Text('حالي', style: TextStyle(color: Colors.white, fontSize: 10)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text('$price عملة', style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
              ],
            ),
          ),
          if (isLocked)
            ElevatedButton(
              onPressed: () async {
                final api = context.read<ApiProvider>().api;
                try {
                  await api.post('/api/vip/upgrade', body: {'level': level});
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم الترقية بنجاح')),
                    );
                  }
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('فشلت الترقية')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('ترقية', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
