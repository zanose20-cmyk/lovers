import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/auth_provider.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';

class BadgeShopScreen extends StatefulWidget {
  const BadgeShopScreen({super.key});

  @override
  State<BadgeShopScreen> createState() => _BadgeShopScreenState();
}

class _BadgeShopScreenState extends State<BadgeShopScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _badges = [];
  List<dynamic> _frames = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    try {
      final api = ApiService(AppConfig.serverUrl);
      final resp = await api.get('/api/gifts');
      if (resp.statusCode == 200 && mounted) {
        setState(() {
          _frames = (resp.data['gifts'] ?? []).where((g) => g['type'] == 'frame').toList();
          _badges = (resp.data['gifts'] ?? []).where((g) => g['type'] == 'badge').toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _purchase(String sku, String name, int price) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text('شراء $name', style: const TextStyle(color: AppColors.textPrimary)),
        content: Text('السعر: $price عملة ذهبية', style: const TextStyle(color: AppColors.textHint)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('شراء', style: TextStyle(color: AppColors.primary))),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    try {
      final auth = context.read<AuthProvider>();
      final token = auth.token;
      if (token == null) return;
      final api = ApiService(AppConfig.serverUrl);
      api.setToken(token);
      final resp = await api.post('/api/gifts/$sku/buy');
      if (resp.statusCode == 200) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم شراء $name بنجاح')));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp.data['error'] ?? 'فشل الشراء')));
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خطأ في الاتصال')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('متجر الإطارات والشارات'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          tabs: const [
            Tab(text: 'الشارات'),
            Tab(text: 'الإطارات'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGrid(_badges),
                _buildGrid(_frames),
              ],
            ),
    );
  }

  Widget _buildGrid(List<dynamic> items) {
    if (items.isEmpty) {
      return const Center(child: Text('لا توجد عناصر', style: TextStyle(color: AppColors.textHint)));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.8,
      ),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final item = items[i];
        return GestureDetector(
          onTap: () => _purchase(item['sku'] ?? '', item['name'] ?? '', item['priceCoins'] ?? 0),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.backgroundCardLight),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events, size: 36, color: AppColors.primary),
                const SizedBox(height: 6),
                Text(item['name'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.monetization_on, size: 12, color: Colors.amber),
                    const SizedBox(width: 2),
                    Text('${item['priceCoins'] ?? 0}', style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
