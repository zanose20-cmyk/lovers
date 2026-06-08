import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/posts_provider.dart';
import '../widgets/common_widgets.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentController = TextEditingController();
  final _hashtagController = TextEditingController();
  List<String> _hashtags = [];
  bool _posting = false;

  @override
  void dispose() {
    _contentController.dispose();
    _hashtagController.dispose();
    super.dispose();
  }

  void _addHashtag() {
    final tag = _hashtagController.text.trim();
    if (tag.isNotEmpty && !_hashtags.contains(tag)) {
      setState(() => _hashtags.add(tag));
      _hashtagController.clear();
    }
  }

  Future<void> _publish() async {
    if (_contentController.text.trim().isEmpty) return;
    setState(() => _posting = true);
    final pp = context.read<PostsProvider>();
    final post = await pp.createPost(_contentController.text.trim(), hashtags: _hashtags);
    if (post != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نشر المنشور')));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل النشر')));
    }
    setState(() => _posting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('منشور جديد'),
        actions: [
          TextButton(
            onPressed: _posting ? null : _publish,
            child: _posting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('نشر', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _contentController,
              maxLines: 8,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
              decoration: const InputDecoration(
                hintText: 'ماذا تريد أن تقول؟',
                hintStyle: TextStyle(color: AppColors.textHint),
                border: InputBorder.none,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: AppTextField(controller: _hashtagController, label: 'هاشتاغ'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: AppColors.primary),
                  onPressed: _addHashtag,
                ),
              ],
            ),
            if (_hashtags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: _hashtags.map((h) => Chip(
                  label: Text('#$h', style: const TextStyle(color: Colors.white, fontSize: 12)),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.3),
                  deleteIcon: const Icon(Icons.close, size: 14, color: Colors.white),
                  onDeleted: () => setState(() => _hashtags.remove(h)),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
