import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/gifts_provider.dart';
import '../models/gift_model.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GiftsProvider>().loadGifts();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('متجر الهدايا'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          tabs: const [
            Tab(text: 'مميزة'),
            Tab(text: 'رائجة'),
            Tab(text: 'كلاسيك'),
            Tab(text: 'VIP'),
          ],
        ),
      ),
      body: Consumer<GiftsProvider>(
        builder: (ctx, gp, _) {
          if (gp.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final premium = gp.gifts.where((g) => g.rarity == 'legendary' || g.type == 'fullscreen').toList();
          final trending = gp.gifts.where((g) => g.rarity == 'rare').toList();
          final classic = gp.gifts.where((g) => g.rarity == 'common').toList();
          final vipGifts = gp.gifts.where((g) => (g.priceDiamonds ?? 0) > 0).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _GiftGrid(gifts: premium.isNotEmpty ? premium : gp.gifts.take(4).toList()),
              _GiftGrid(gifts: trending.isNotEmpty ? trending : gp.gifts.take(4).toList()),
              _GiftGrid(gifts: classic.isNotEmpty ? classic : gp.gifts.take(4).toList()),
              _GiftGrid(gifts: vipGifts.isNotEmpty ? vipGifts : []),
            ],
          );
        },
      ),
    );
  }
}

void _sendGiftDialog(BuildContext context, GiftModel gift) {
  final controller = TextEditingController();
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.backgroundCard,
      title: Text('إرسال ${gift.name ?? 'هدية'}', style: const TextStyle(color: AppColors.textPrimary)),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          hintText: 'معرف المستخدم',
          hintStyle: TextStyle(color: AppColors.textHint),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () { controller.dispose(); Navigator.pop(ctx); },
          child: const Text('إلغاء', style: TextStyle(color: AppColors.textHint)),
        ),
        TextButton(
          onPressed: () async {
            final userId = controller.text.trim();
            if (userId.isEmpty) return;
            try {
              await context.read<GiftsProvider>().sendGift(userId, gift.sku ?? '', 1);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم إرسال الهدية')),
                );
              }
            } catch (_) {
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('فشل إرسال الهدية')),
                );
              }
            }
            controller.dispose();
          },
          child: const Text('إرسال', style: TextStyle(color: AppColors.primary)),
        ),
      ],
    ),
  );
}

class _GiftGrid extends StatelessWidget {
  final List<GiftModel> gifts;
  const _GiftGrid({required this.gifts});

  @override
  Widget build(BuildContext context) {
    if (gifts.isEmpty) {
      return const Center(child: Text('لا توجد هدايا', style: TextStyle(color: AppColors.textHint)));
    }
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: gifts.length,
        itemBuilder: (context, index) {
          final gift = gifts[index];
          return Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.backgroundCardLight),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: gift.imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(gift.imageUrl!, width: 60, height: 60, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.card_giftcard, size: 50, color: AppColors.primary),
                                  ),
                                )
                              : const Icon(Icons.card_giftcard, size: 50, color: AppColors.primary),
                        ),
                        if (gift.type == 'animated' || gift.rarity == 'legendary')
                          Positioned(
                            top: 8, right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.neonBlue.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                gift.rarity == 'legendary' ? 'أسطوري' : 'GIF',
                                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Text(gift.name ?? '', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.diamond, size: 14, color: AppColors.gold),
                          const SizedBox(width: 4),
                          Text('${gift.priceCoins ?? gift.priceDiamonds ?? 0}', style: const TextStyle(color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _sendGiftDialog(context, gift),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: const Text('إرسال', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
