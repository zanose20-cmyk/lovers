import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../providers/posts_provider.dart';
import '../providers/api_provider.dart';
import '../services/auth_provider.dart';
import '../widgets/common_widgets.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentController = TextEditingController();
  final _hashtagController = TextEditingController();
  final _picker = ImagePicker();
  List<String> _hashtags = [];
  List<_MediaItem> _mediaFiles = [];
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

  Future<void> _pickImages() async {
    final files = await _picker.pickMultiImage(imageQuality: 80);
    if (files.isNotEmpty) {
      setState(() {
        _mediaFiles.addAll(files.map((f) => _MediaItem(file: File(f.path), type: 'image')));
      });
    }
  }

  Future<void> _pickVideo() async {
    final file = await _picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(minutes: 5));
    if (file != null) {
      setState(() {
        _mediaFiles.add(_MediaItem(file: File(file.path), type: 'video'));
      });
    }
  }

  Future<List<Map<String, dynamic>>> _uploadMedia() async {
    final api = context.read<ApiProvider>().api;
    final List<Map<String, dynamic>> media = [];
    for (final item in _mediaFiles) {
      try {
        final fileName = item.file.path.split('/').last;
        final bytes = await item.file.readAsBytes();
        final resp = await api.uploadFile(bytes, fileName, 'posts');
        if (resp['url'] != null) {
          media.add({'type': item.type, 'url': resp['url']});
        }
      } catch (_) {}
    }
    return media;
  }

  Future<void> _publish() async {
    if (_contentController.text.trim().isEmpty && _mediaFiles.isEmpty) return;
    setState(() => _posting = true);
    try {
      final media = _mediaFiles.isNotEmpty ? await _uploadMedia() : <Map<String, dynamic>>[];
      final pp = context.read<PostsProvider>();
      final post = await pp.createPost(_contentController.text.trim(), hashtags: _hashtags, media: media.isNotEmpty ? media : null);
      if (post != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نشر المنشور')));
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل النشر')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خطأ في الاتصال')));
      }
    }
    if (mounted) setState(() => _posting = false);
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            if (_mediaFiles.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _mediaFiles.length,
                  itemBuilder: (ctx, i) {
                    final item = _mediaFiles[i];
                    return Stack(
                      children: [
                        Container(
                          width: 120, height: 120,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: AppColors.backgroundCardLight,
                          ),
                          child: item.type == 'image'
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(item.file, fit: BoxFit.cover),
                                )
                              : const Center(
                                  child: Icon(Icons.videocam, color: AppColors.primary, size: 40),
                                ),
                        ),
                        Positioned(
                          top: 4, right: 4,
                          child: GestureDetector(
                            onTap: () => setState(() => _mediaFiles.removeAt(i)),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                              child: const Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                  onPressed: _pickImages,
                  tooltip: 'صور',
                ),
                IconButton(
                  icon: const Icon(Icons.videocam_outlined, color: AppColors.primary),
                  onPressed: _pickVideo,
                  tooltip: 'فيديو',
                ),
                const Spacer(),
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

class _MediaItem {
  final File file;
  final String type;
  const _MediaItem({required this.file, required this.type});
}
