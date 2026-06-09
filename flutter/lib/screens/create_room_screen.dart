import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/rooms_provider.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _titleController = TextEditingController();
  final _passwordController = TextEditingController();
  String _roomType = 'public';
  int _capacity = 12;
  String? _selectedBackground;
  bool _isCreating = false;

  static const _backgrounds = [
    {'key': 'default', 'label': 'افتراضي', 'color': 0xFF1A1A2E},
    {'key': 'vip_gold', 'label': 'VIP ذهبي', 'color': 0xFFFFD700},
    {'key': 'dark_blue', 'label': 'أزرق داكن', 'color': 0xFF0F3460},
    {'key': 'purple', 'label': 'بنفسجي', 'color': 0xFF6A0DAD},
    {'key': 'red', 'label': 'أحمر', 'color': 0xFF8B0000},
    {'key': 'green', 'label': 'أخضر', 'color': 0xFF006400},
    {'key': 'neon_pink', 'label': 'وردي نيون', 'color': 0xFFFF10F0},
    {'key': 'neon_blue', 'label': 'أزرق نيون', 'color': 0xFF00FFFF},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إدخال اسم الغرفة')));
      return;
    }
    setState(() => _isCreating = true);

    try {
      final rp = context.read<RoomsProvider>();
      final room = await rp.createRoom({
        'title': _titleController.text.trim(),
        'type': _roomType,
        if (_roomType == 'private') 'password': _passwordController.text,
        'capacity': _capacity,
        'maxCapacity': _capacity,
        if (_selectedBackground != null && _selectedBackground != 'default') 'background': _selectedBackground,
      });

      if (room != null && room.roomId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم إنشاء الغرفة ${_titleController.text}')));
        Navigator.pushNamed(context, '/room', arguments: room.roomId);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل إنشاء الغرفة')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خطأ في الاتصال')));
      }
    }
    if (mounted) setState(() => _isCreating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(title: const Text('إنشاء غرفة جديدة')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'اسم الغرفة',
                prefixIcon: Icon(Icons.title),
                labelStyle: TextStyle(color: AppColors.textSecondary),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.textHint)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
              ),
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            const Text('نوع الغرفة', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['public', 'private', 'vip', 'agency'].map((t) {
                final labels = {'public': 'عامة', 'private': 'خاصة', 'vip': 'VIP', 'agency': 'وكالة'};
                final icons = {'public': Icons.public, 'private': Icons.lock, 'vip': Icons.diamond, 'agency': Icons.business};
                return GestureDetector(
                  onTap: () => setState(() => _roomType = t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: _roomType == t ? AppColors.primary.withValues(alpha: 0.2) : AppColors.backgroundCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _roomType == t ? AppColors.primary : AppColors.backgroundCardLight),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icons[t] ?? Icons.help_outline, color: _roomType == t ? AppColors.primary : AppColors.textHint, size: 18),
                        const SizedBox(width: 6),
                        Text(labels[t]!, style: TextStyle(color: _roomType == t ? AppColors.primary : AppColors.textHint)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('خلفية الغرفة', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _backgrounds.length,
                itemBuilder: (ctx, i) {
                  final bg = _backgrounds[i];
                  final isSelected = _selectedBackground == bg['key'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedBackground = isSelected ? null : bg['key'] as String),
                    child: Container(
                      width: 70,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: Color(bg['color'] as int),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          bg['label'] as String,
                          style: TextStyle(
                            color: bg['key'] == 'vip_gold' || bg['key'] == 'neon_blue' ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_roomType == 'private') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور',
                  prefixIcon: Icon(Icons.lock_outline),
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.textHint)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ],
            const SizedBox(height: 16),
            const Text('سعة الغرفة', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [6, 8, 12, 16, 20].map((c) => GestureDetector(
                onTap: () => setState(() => _capacity = c),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: _capacity == c ? AppColors.primary.withValues(alpha: 0.2) : AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _capacity == c ? AppColors.primary : AppColors.backgroundCardLight),
                  ),
                  child: Text('$c', style: TextStyle(color: _capacity == c ? AppColors.primary : AppColors.textHint)),
                ),
              )).toList(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCreating ? null : _createRoom,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isCreating
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('إنشاء الغرفة', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
