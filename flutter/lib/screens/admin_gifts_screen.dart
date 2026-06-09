import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/api_provider.dart';

class AdminGiftsScreen extends StatefulWidget {
  const AdminGiftsScreen({super.key});

  @override
  State<AdminGiftsScreen> createState() => _AdminGiftsScreenState();
}

class _AdminGiftsScreenState extends State<AdminGiftsScreen> {
  List<dynamic> _gifts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGifts();
  }

  Future<void> _loadGifts() async {
    try {
      final api = context.read<ApiProvider>().api;
      final resp = await api.get('/api/admin/gifts');
      if (resp.statusCode == 200 && mounted) {
        setState(() {
          _gifts = resp.data['gifts'] ?? [];
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
      appBar: AppBar(title: const Text('إدارة الهدايا')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadGifts,
              child: _gifts.isEmpty
                  ? const Center(child: Text('لا توجد هدايا', style: TextStyle(color: AppColors.textHint)))
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: _gifts.length,
                      itemBuilder: (ctx, i) {
                        final gift = _gifts[i];
                        return Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundCard,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.card_giftcard, size: 36, color: AppColors.primary),
                              const SizedBox(height: 6),
                              Text(gift['name'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.monetization_on, size: 12, color: Colors.amber),
                                  const SizedBox(width: 2),
                                  Text('${gift['priceCoins'] ?? 0}', style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Text(gift['type'] ?? 'generic', style: const TextStyle(color: AppColors.textHint, fontSize: 9)),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
