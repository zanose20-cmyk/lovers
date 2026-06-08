import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/auth_provider.dart';
import '../providers/api_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  String _gender = 'male';
  int _age = 25;
  String _country = 'السعودية';
  String? _avatarUrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController.text = user?['displayName'] ?? '';
    _bioController.text = user?['bio'] ?? '';
    _gender = user?['gender'] ?? 'male';
    _age = user?['age'] ?? 25;
    _country = user?['country'] ?? 'السعودية';
    _avatarUrl = user?['avatarUrl'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512);
    if (image != null) {
      setState(() => _avatarUrl = image.path);
    }
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final api = context.read<ApiProvider>().api;
      final resp = await api.put('/api/users/me', body: {
        'displayName': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'gender': _gender,
        'age': _age,
        'country': _country,
      });
      if (resp.statusCode == 200 && resp.data['ok'] == true && mounted) {
        final updated = resp.data['user'] as Map<String, dynamic>?;
        if (updated != null) {
          context.read<AuthProvider>().setUser(updated);
        }
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ التغييرات')));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الحفظ: $e')));
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('تعديل الملف الشخصي'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('حفظ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: AppColors.backgroundCardLight,
                    backgroundImage: _avatarUrl != null && _avatarUrl!.startsWith('http')
                        ? NetworkImage(_avatarUrl!) as ImageProvider
                    : (_avatarUrl != null ? FileImage(File(_avatarUrl!)) as ImageProvider : null),
                    child: _avatarUrl == null ? const Icon(Icons.person, size: 60, color: AppColors.textHint) : null,
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            AppTextField(controller: _nameController, label: 'اسم المستخدم', prefixIcon: Icons.person_outline),
            const SizedBox(height: 16),
            TextField(
              controller: _bioController,
              maxLines: 3,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'السيرة الذاتية',
                prefixIcon: Icon(Icons.info_outline, color: AppColors.textHint),
                labelStyle: TextStyle(color: AppColors.textSecondary),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.textHint)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _country,
              dropdownColor: AppColors.backgroundCard,
              decoration: const InputDecoration(
                labelText: 'الدولة',
                prefixIcon: Icon(Icons.public, color: AppColors.textHint),
                labelStyle: TextStyle(color: AppColors.textSecondary),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.textHint)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
              ),
              style: const TextStyle(color: AppColors.textPrimary),
              items: ['السعودية', 'الإمارات', 'الكويت', 'قطر', 'عمان', 'البحرين', 'مصر', 'الأردن', 'العراق', 'فلسطين', 'لبنان', 'سوريا', 'اليمن', 'ليبيا', 'تونس', 'الجزائر', 'المغرب', 'السودان']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _country = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              dropdownColor: AppColors.backgroundCard,
              decoration: const InputDecoration(
                labelText: 'الجنس',
                prefixIcon: Icon(Icons.wc, color: AppColors.textHint),
                labelStyle: TextStyle(color: AppColors.textSecondary),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.textHint)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
              ),
              style: const TextStyle(color: AppColors.textPrimary),
              items: const [
                DropdownMenuItem(value: 'male', child: Text('ذكر')),
                DropdownMenuItem(value: 'female', child: Text('أنثى')),
                DropdownMenuItem(value: 'other', child: Text('أخرى')),
              ],
              onChanged: (v) => setState(() => _gender = v!),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'العمر',
                prefixIcon: Icon(Icons.cake, color: AppColors.textHint),
                labelStyle: TextStyle(color: AppColors.textSecondary),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.textHint)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
              ),
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textPrimary),
              controller: TextEditingController(text: _age.toString()),
              onChanged: (v) => _age = int.tryParse(v) ?? 25,
            ),
          ],
        ),
      ),
    );
  }
}
