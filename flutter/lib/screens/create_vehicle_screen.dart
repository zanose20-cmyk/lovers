import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/api_provider.dart';

class CreateVehicleScreen extends StatefulWidget {
  const CreateVehicleScreen({super.key});

  @override
  State<CreateVehicleScreen> createState() => _CreateVehicleScreenState();
}

class _CreateVehicleScreenState extends State<CreateVehicleScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  String _type = 'car';
  int _duration = 30;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(title: const Text('إضافة مركبة جديدة')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.backgroundCardLight),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined, color: AppColors.textHint, size: 40),
                    const SizedBox(height: 8),
                    const Text('صورة المركبة', style: TextStyle(color: AppColors.textHint, fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'اسم المركبة',
                prefixIcon: Icon(Icons.directions_car_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'السعر (عملات)',
                prefixIcon: Icon(Icons.diamond_outlined),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            const Text('نوع المركبة', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _TypeChip(label: 'سيارة', value: 'car', icon: Icons.directions_car, selected: _type == 'car'),
                _TypeChip(label: 'طائرة', value: 'plane', icon: Icons.flight, selected: _type == 'plane'),
                _TypeChip(label: 'يخت', value: 'yacht', icon: Icons.directions_boat, selected: _type == 'yacht'),
                _TypeChip(label: 'هليكوبتر', value: 'helicopter', icon: Icons.flight_takeoff, selected: _type == 'helicopter'),
                _TypeChip(label: 'حصان', value: 'horse', icon: Icons.pets, selected: _type == 'horse'),
                _TypeChip(label: 'عرش', value: 'throne', icon: Icons.workspace_premium, selected: _type == 'throne'),
              ],
            ),
            const SizedBox(height: 16),
            const Text('مدة الاستخدام (أيام)', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _duration.toDouble(),
                    min: 1,
                    max: 365,
                    divisions: 364,
                    label: '$_duration يوم',
                    onChanged: (v) => setState(() => _duration = v.round()),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.backgroundCard, borderRadius: BorderRadius.circular(8)),
                  child: Text('$_duration يوم', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  if (_nameController.text.trim().isEmpty) return;
                  final api = context.read<ApiProvider>().api;
                  try {
                    await api.post('/api/admin/vehicles', body: {
                      'name': _nameController.text,
                      'type': _type,
                      'priceCoins': int.tryParse(_priceController.text) ?? 0,
                      'duration': _duration,
                    });
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('تم إضافة المركبة ${_nameController.text}')),
                      );
                      Navigator.pop(context);
                    }
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('فشل إضافة المركبة')),
                      );
                    }
                  }
                },
                child: const Text('إضافة المركبة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _TypeChip({required String label, required String value, required IconData icon, required bool selected}) {
    return GestureDetector(
      onTap: () => setState(() => _type = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.primary : AppColors.backgroundCardLight, width: selected ? 2 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: selected ? AppColors.primary : AppColors.textHint),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: selected ? AppColors.primary : AppColors.textHint, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}
