import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/api_provider.dart';
import '../services/auth_provider.dart';
import '../models/vehicle_model.dart';

class VehiclesStoreScreen extends StatefulWidget {
  const VehiclesStoreScreen({super.key});

  @override
  State<VehiclesStoreScreen> createState() => _VehiclesStoreScreenState();
}

class _VehiclesStoreScreenState extends State<VehiclesStoreScreen> with SingleTickerProviderStateMixin {
  List<VehicleModel> _vehicles = [];
  List<VehicleModel> _myVehicles = [];
  bool _loading = true;
  late TabController _tabController;
  String _selectedCategory = 'all';

  static const _categories = [
    {'key': 'all', 'label': 'الكل', 'icon': Icons.apps},
    {'key': 'car', 'label': 'سيارات', 'icon': Icons.directions_car},
    {'key': 'plane', 'label': 'طائرات', 'icon': Icons.flight},
    {'key': 'yacht', 'label': 'يخوت', 'icon': Icons.directions_boat},
    {'key': 'legendary', 'label': 'أسطورية', 'icon': Icons.workspace_premium},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final api = context.read<ApiProvider>().api;
    try {
      final resp = await api.get('/api/store/vehicles');
      if (resp.statusCode == 200) {
        final data = resp.data;
        final list = (data is List) ? data : (data['vehicles'] ?? []);
        _vehicles = (list as List).map((e) => VehicleModel.fromJson(e)).toList();
      }
      final auth = context.read<AuthProvider>();
      final myVehicles = auth.user?['vehicles'] as List? ?? [];
      _myVehicles = myVehicles.map((e) => VehicleModel.fromJson(e)).toList();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(title: const Text('متجر المركبات')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCard,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.directions_car, size: 64, color: AppColors.primary),
                        const SizedBox(height: 8),
                        const Text('مركبتек الحالية', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        Consumer<AuthProvider>(
                          builder: (_, auth, __) {
                            final vehicles = auth.user?['vehicles'] as List? ?? [];
                            final current = vehicles.isNotEmpty ? vehicles.last['name'] ?? 'سيارة عادية' : 'سيارة عادية';
                            return Text(current, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold));
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: _vehicles.length,
                      itemBuilder: (context, index) {
                        final v = _vehicles[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.backgroundCardLight),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_vehicleIcon(v.type), size: 40, color: AppColors.primary),
                              const SizedBox(height: 8),
                              Text(v.name ?? '', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text('${v.priceCoins ?? 0} عملة', style: const TextStyle(color: AppColors.gold, fontSize: 12)),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        backgroundColor: AppColors.backgroundCard,
                                        title: const Text('تأكيد الشراء', style: TextStyle(color: AppColors.textPrimary)),
                                        content: Text('هل تريد شراء ${v.name} بـ ${v.priceCoins ?? 0} عملة؟', style: const TextStyle(color: AppColors.textSecondary)),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: AppColors.textHint))),
                                          TextButton(
                                            onPressed: () async {
                                              Navigator.pop(ctx);
                                              try {
                                                final api = context.read<ApiProvider>().api;
                                                await api.post('/api/store/vehicles/buy', body: {'sku': v.sku});
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الشراء بنجاح')));
                                                }
                                              } catch (_) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل الشراء')));
                                                }
                                              }
                                            },
                                            child: const Text('شراء', style: TextStyle(color: AppColors.primary)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                    foregroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    elevation: 0,
                                  ),
                                  child: const Text('شراء', style: TextStyle(fontSize: 12)),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  IconData _vehicleIcon(String? type) {
    switch (type) {
      case 'car': return Icons.directions_car;
      case 'plane': return Icons.flight;
      case 'yacht': return Icons.directions_boat;
      case 'legendary': return Icons.workspace_premium;
      default: return Icons.directions_car;
    }
  }
}

class _VehicleCard extends StatelessWidget {
  final VehicleModel vehicle;
  final bool isOwned;
  final VoidCallback? onBuy;
  final VoidCallback? onEquip;

  const _VehicleCard({required this.vehicle, this.isOwned = false, this.onBuy, this.onEquip});

  IconData _vehicleIcon(String? type) {
    switch (type) {
      case 'car': return Icons.directions_car;
      case 'plane': return Icons.flight;
      case 'yacht': return Icons.directions_boat;
      case 'legendary': return Icons.workspace_premium;
      default: return Icons.directions_car;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLegendary = vehicle.type == 'legendary';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLegendary ? AppColors.gold.withValues(alpha: 0.5) : AppColors.backgroundCardLight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              Icon(_vehicleIcon(vehicle.type), size: 40, color: isLegendary ? AppColors.gold : AppColors.primary),
              if (isOwned)
                Positioned(
                  top: -4, right: -4,
                  child: Container(
                    width: 18, height: 18,
                    decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                    child: const Icon(Icons.check, color: Colors.white, size: 10),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(vehicle.name ?? '', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text('${vehicle.priceCoins ?? 0} عملة', style: const TextStyle(color: AppColors.gold, fontSize: 12)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isOwned ? onEquip : onBuy,
              style: ElevatedButton.styleFrom(
                backgroundColor: isOwned ? AppColors.success.withValues(alpha: 0.15) : AppColors.primary.withValues(alpha: 0.15),
                foregroundColor: isOwned ? AppColors.success : AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Text(isOwned ? 'تجهيز' : 'شراء', style: const TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}
