import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../providers/api_provider.dart';
import '../services/auth_provider.dart';
import '../models/vip_level_model.dart';

class VIPScreen extends StatefulWidget {
  const VIPScreen({super.key});

  @override
  State<VIPScreen> createState() => _VIPScreenState();
}

class _VIPScreenState extends State<VIPScreen> {
  List<VIPLevelModel> _levels = [];
  bool _loading = true;
  Map<String, dynamic>? _status;
  int _selectedDuration = 1;
  int? _purchasingLevel;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final api = context.read<ApiProvider>().api;
    try {
      final results = await Future.wait([
        api.get('/api/vip/levels'),
        api.get('/api/vip/status'),
      ]);
      final levelsResp = results[0];
      final statusResp = results[1];

      if (levelsResp.statusCode == 200) {
        final data = levelsResp.data;
        final list = (data is List) ? data : (data['levels'] ?? []);
        _levels = (list as List).map((e) => VIPLevelModel.fromJson(e)).toList();
      }
      if (statusResp.statusCode == 200) {
        _status = statusResp.data;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Color _parseColor(String? colorStr, {Color fallback = AppColors.gold}) {
    if (colorStr == null || colorStr.isEmpty) return fallback;
    try {
      final hex = colorStr.replaceFirst('#', '').padLeft(6, '0');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  String _formatDuration(int days) {
    if (days <= 0) return 'منتهي';
    if (days == 1) return 'يوم واحد';
    if (days < 7) return '$days أيام';
    if (days < 30) return '${(days / 7).floor()} أسابيع';
    if (days < 365) return '${(days / 30).floor()} أشهر';
    return '${(days / 365).floor()} سنوات';
  }

  Future<void> _purchase(int level) async {
    final api = context.read<ApiProvider>().api;
    final auth = context.read<AuthProvider>();
    setState(() => _purchasingLevel = level);

    try {
      final resp = await api.post('/api/vip/purchase', body: {
        'level': level,
        'duration': _selectedDuration,
      });

      if (resp.statusCode == 200 && resp.data['ok'] == true) {
        final updatedUser = resp.data['user'] as Map<String, dynamic>?;
        if (updatedUser != null) auth.setUser(updatedUser);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('تم ترقيةك إلى VIP $level لمدة $_selectedDuration ${_selectedDuration == 1 ? 'شهر' : (_selectedDuration == 3 ? 'أشهر' : 'سنة')}'),
            backgroundColor: AppColors.success,
          ));
        }
      } else {
        final error = resp.data['error'] ?? 'فشلت الترقية';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(error.toString()),
            backgroundColor: AppColors.error,
          ));
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('خطأ في الاتصال'),
          backgroundColor: AppColors.error,
        ));
      }
    }
    if (mounted) setState(() => _purchasingLevel = null);
  }

  int _getPrice(VIPLevelModel vip) {
    switch (_selectedDuration) {
      case 3: return vip.priceCoins3Months ?? ((vip.priceCoins ?? 0) * 3 * 0.9).round();
      case 12: return vip.priceCoins12Months ?? ((vip.priceCoins ?? 0) * 12 * 0.7).round();
      default: return vip.priceCoins ?? 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('اشتراك VIP'),
        actions: [
          if (_status != null) ...[
            Container(
              margin: const EdgeInsets.only(left: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: (_status!['isActive'] == true ? AppColors.success : AppColors.textHint).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _status!['isActive'] == true ? Icons.diamond : Icons.diamond_outlined,
                    color: _status!['isActive'] == true ? AppColors.gold : AppColors.textHint,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _status!['isActive'] == true ? 'VIP ${_status!['vipLevel']}' : 'غير مشترك',
                    style: TextStyle(
                      color: _status!['isActive'] == true ? AppColors.gold : AppColors.textHint,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_status != null) _buildStatusCard(),
                    const SizedBox(height: 24),
                    _buildDurationSelector(),
                    const SizedBox(height: 24),
                    const Text('اختر مستواك', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    ..._levels.map((vip) => _buildLevelCard(vip)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    final isActive = _status!['isActive'] == true;
    final daysRemaining = _status!['daysRemaining'] ?? 0;
    final expiresAt = _status!['expiresAt'] as String?;
    final chargeLevel = _status!['chargeLevel'] ?? 0;
    final vipLevel = _status!['vipLevel'] ?? 0;
    final color = isActive ? AppColors.gold : AppColors.textHint;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [AppColors.gold, AppColors.gold.withValues(alpha: 0.7)]
              : [AppColors.backgroundCard, AppColors.backgroundCardLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: isActive
            ? [BoxShadow(color: AppColors.gold.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 2)]
            : [],
      ),
      child: Column(
        children: [
          if (isActive && _status!['currentLevel'] != null && (_status!['currentLevel']['entryAnimationUrl'] as String?)?.isNotEmpty == true)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: _status!['currentLevel']['entryAnimationUrl'],
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                placeholder: (_, __) => const Icon(Icons.diamond, size: 64, color: Colors.white),
                errorWidget: (_, __, ___) => const Icon(Icons.diamond, size: 64, color: Colors.white),
              ),
            )
          else
            Icon(
              isActive ? Icons.diamond : Icons.diamond_outlined,
              size: 64,
              color: isActive ? Colors.white : AppColors.textHint,
            ),
          const SizedBox(height: 12),
          Text(
            isActive ? 'VIP $vipLevel' : 'غير مشترك',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          if (isActive) ...[
            Text(
              'متبقي ${_formatDuration(daysRemaining)}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            if (expiresAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'ينتهي في ${_formatExpiry(expiresAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
            const SizedBox(height: 16),
            _buildCountdownBar(daysRemaining),
          ] else ...[
            Text(
              'اشترك الآن للاستمتاع بمميزات VIP',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textHint,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.account_balance_wallet, color: Colors.white.withValues(alpha: 0.9), size: 18),
                const SizedBox(width: 8),
                Text(
                  '$chargeLevel عملة',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownBar(int daysRemaining) {
    final maxDays = 365;
    final progress = (daysRemaining / maxDays).clamp(0.0, 1.0);
    final color = daysRemaining > 30
        ? Colors.green
        : daysRemaining > 7
            ? Colors.orange
            : Colors.red;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0 يوم', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10)),
            Text(
              daysRemaining > 30 ? 'ممتاز' : daysRemaining > 7 ? 'يحتاج تجديد' : 'يوشك على الانتهاء',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.bold),
            ),
            Text('365 يوم', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10)),
          ],
        ),
      ],
    );
  }

  String _formatExpiry(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return isoDate;
    }
  }

  Widget _buildDurationSelector() {
    final options = [
      {'months': 1, 'label': 'شهر واحد', 'discount': null},
      {'months': 3, 'label': '3 أشهر', 'discount': '10%'},
      {'months': 12, 'label': '12 شهر', 'discount': '30%'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('مدة الاشتراك', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Row(
          children: options.map((opt) {
            final months = opt['months'] as int;
            final isSelected = _selectedDuration == months;
            final discount = opt['discount'] as String?;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedDuration = months),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.backgroundCardLight,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        opt['label'] as String,
                        style: TextStyle(
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      if (discount != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'وفر $discount',
                            style: const TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLevelCard(VIPLevelModel vip) {
    final vipColor = _parseColor(vip.color);
    final price = _getPrice(vip);
    final currentVip = _status?['vipLevel'] ?? 0;
    final isActive = _status?['isActive'] == true;
    final isCurrent = (vip.level ?? 0) == currentVip && isActive;
    final isLocked = (vip.level ?? 0) > currentVip || !isActive;
    final isPurchasing = _purchasingLevel == vip.level;
    final chargeLevel = _status?['chargeLevel'] ?? 0;
    final canAfford = chargeLevel >= price;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrent ? vipColor.withValues(alpha: 0.1) : AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent ? vipColor : AppColors.backgroundCardLight,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: vipColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: vip.entryAnimationUrl != null && vip.entryAnimationUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: CachedNetworkImage(
                          imageUrl: vip.entryAnimationUrl!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Icon(
                            isLocked ? Icons.lock_outline : Icons.diamond,
                            color: isLocked ? AppColors.textHint : vipColor,
                            size: 26,
                          ),
                          errorWidget: (_, __, ___) => Icon(
                            isLocked ? Icons.lock_outline : Icons.diamond,
                            color: isLocked ? AppColors.textHint : vipColor,
                            size: 26,
                          ),
                        ),
                      )
                    : Icon(
                        isLocked ? Icons.lock_outline : Icons.diamond,
                        color: isLocked ? AppColors.textHint : vipColor,
                        size: 26,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('VIP ${vip.level}', style: TextStyle(color: vipColor, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(vip.name ?? '', style: TextStyle(color: vipColor, fontSize: 13)),
                        if (isCurrent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: vipColor, borderRadius: BorderRadius.circular(8)),
                            child: const Text('حالي', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.account_balance_wallet, size: 14, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Text('$price عملة / ${_selectedDuration == 1 ? 'شهر' : (_selectedDuration == 3 ? '3 أشهر' : '12 شهر')}',
                            style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (vip.benefits != null && vip.benefits!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: vip.benefits!.take(4).map((b) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: vipColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(b, style: TextStyle(color: vipColor, fontSize: 11)),
              )).toList(),
            ),
          ],
          if (isLocked && !isCurrent) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isPurchasing ? null : () => _purchase(vip.level ?? 0),
                style: ElevatedButton.styleFrom(
                  backgroundColor: canAfford ? vipColor : AppColors.backgroundCardLight,
                  foregroundColor: canAfford ? Colors.white : AppColors.textHint,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isPurchasing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(
                        canAfford ? 'اشترك الآن - $price عملة' : 'رصيد غير كافٍ ($chargeLevel عملة)',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
