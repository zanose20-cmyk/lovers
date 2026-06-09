import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/api_provider.dart';

class ReportDialog extends StatefulWidget {
  final String targetType;
  final String targetId;

  const ReportDialog({super.key, required this.targetType, required this.targetId});

  static Future<void> show(BuildContext context, {required String targetType, required String targetId}) {
    return showDialog(
      context: context,
      builder: (_) => ReportDialog(targetType: targetType, targetId: targetId),
    );
  }

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  String _reason = 'spam';
  final _descController = TextEditingController();
  bool _submitting = false;

  final _reasons = [
    {'value': 'spam', 'label': 'رسائل مزعجة / سبام'},
    {'value': 'harassment', 'label': 'إزعاج / تحرش'},
    {'value': 'inappropriate', 'label': 'محتوى غير لائق'},
    {'value': 'impersonation', 'label': 'انتحال شخصية'},
    {'value': 'scam', 'label': 'نصب / احتيال'},
    {'value': 'other', 'label': 'سبب آخر'},
  ];

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final api = context.read<ApiProvider>().api;
      final resp = await api.post('/api/reports', body: {
        'targetType': widget.targetType,
        'targetId': widget.targetId,
        'reason': _reason,
        'description': _descController.text.trim(),
      });
      if (mounted) {
        if (resp.statusCode == 200) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الإبلاغ بنجاح')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp.data['error'] ?? 'فشل الإبلاغ')));
        }
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خطأ في الاتصال')));
    }
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.backgroundCard,
      title: const Text('إبلاغ', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ..._reasons.map((r) => RadioListTile<String>(
              value: r['value']!,
              groupValue: _reason,
              onChanged: (v) => setState(() => _reason = v!),
              title: Text(r['label']!, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
            )),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 3,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'تفاصيل إضافية (اختياري)',
                hintStyle: const TextStyle(color: AppColors.textHint),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.backgroundCardLight)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: AppColors.textHint))),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          child: _submitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('إبلاغ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
