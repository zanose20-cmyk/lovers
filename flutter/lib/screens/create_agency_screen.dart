import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/agencies_provider.dart';
import '../widgets/common_widgets.dart';

class CreateAgencyScreen extends StatefulWidget {
  const CreateAgencyScreen({super.key});

  @override
  State<CreateAgencyScreen> createState() => _CreateAgencyScreenState();
}

class _CreateAgencyScreenState extends State<CreateAgencyScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _creating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _creating = true);
    try {
      final ap = context.read<AgenciesProvider>();
      final agency = await ap.createAgency(_nameController.text.trim(), description: _descController.text.trim());
      if (agency != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إنشاء الوكالة')));
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل الإنشاء')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خطأ في الاتصال')));
      }
    }
    if (mounted) setState(() => _creating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(title: const Text('إنشاء وكالة')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.backgroundCardLight),
              ),
              child: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.textHint, size: 40),
            ),
            const SizedBox(height: 24),
            AppTextField(controller: _nameController, label: 'اسم الوكالة', prefixIcon: Icons.business_outlined),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              maxLines: 4,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'الوصف',
                prefixIcon: Icon(Icons.description_outlined, color: AppColors.textHint),
                labelStyle: TextStyle(color: AppColors.textSecondary),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.textHint)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
              ),
            ),
            const SizedBox(height: 32),
            AppButton(
              label: 'إنشاء الوكالة',
              loading: _creating,
              onPressed: _create,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
