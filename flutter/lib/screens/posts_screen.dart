import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/posts_provider.dart';

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostsProvider>().loadPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('المنشورات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => Navigator.pushNamed(context, '/create-post'),
          ),
        ],
      ),
      body: Consumer<PostsProvider>(
        builder: (ctx, pp, _) {
          if (pp.isLoading && pp.posts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (pp.error != null && pp.posts.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                const SizedBox(height: 12),
                Text('حدث خطأ', style: const TextStyle(color: AppColors.textHint)),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: () => pp.loadPosts(), child: const Text('إعادة المحاولة')),
              ]),
            );
          }
          if (pp.posts.isEmpty) {
            return const Center(child: Text('لا توجد منشورات بعد', style: TextStyle(color: AppColors.textHint)));
          }
          return RefreshIndicator(
            onRefresh: () => pp.loadPosts(),
            color: AppColors.primary,
            child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pp.posts.length,
            itemBuilder: (context, index) {
              final post = pp.posts[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.backgroundCardLight,
                            backgroundImage: post.authorAvatar != null ? NetworkImage(post.authorAvatar!) as ImageProvider : null,
                            child: post.authorAvatar == null ? const Icon(Icons.person, color: AppColors.textHint, size: 20) : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(post.authorName ?? '', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                                if (post.createdAt != null)
                                  Text(_timeAgo(post.createdAt!), style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_horiz, color: AppColors.textHint, size: 20),
                            onSelected: (v) async {
                              if (v == 'delete' && post.postId != null) {
                                try {
                                  await pp.deletePost(post.postId!);
                                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف المنشور')));
                                } catch (_) {
                                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل الحذف')));
                                }
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(value: 'delete', child: Text('حذف المنشور', style: TextStyle(color: AppColors.error))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (post.content != null && post.content!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(post.content!, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                      ),
                    if (post.hashtags != null && (post.hashtags ?? []).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Wrap(
                          spacing: 6,
                          children: (post.hashtags ?? []).map((h) => Text('#$h', style: const TextStyle(color: AppColors.primary, fontSize: 12))).toList(),
                        ),
                      ),
                    const Divider(color: AppColors.backgroundCardLight, height: 1),
                    Row(
                      children: [
                        _PostAction(
                          icon: Icons.favorite_border,
                          label: '${post.likesCount ?? 0}',
                          onTap: () { if (post.postId != null) pp.likePost(post.postId!); },
                        ),
                        _PostAction(
                          icon: Icons.chat_bubble_outline,
                          label: '${post.commentsCount ?? 0}',
                          onTap: () { if (post.postId != null) _showCommentDialog(context, post.postId!); },
                        ),
                        _PostAction(
                          icon: Icons.share_outlined,
                          label: '${post.sharesCount ?? 0}',
                          onTap: () { if (post.postId != null) pp.sharePost(post.postId!); },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    return 'منذ ${diff.inDays} يوم';
  }

  void _showCommentDialog(BuildContext context, String postId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text('إضافة تعليق', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(hintText: 'اكتب تعليقاً...', hintStyle: TextStyle(color: AppColors.textHint)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: AppColors.textHint))),
          TextButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                try {
                  await context.read<PostsProvider>().commentPost(postId, text);
                  if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال التعليق')));
                } catch (_) {
                  if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل إرسال التعليق')));
                }
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('إرسال', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }
}

class _PostAction extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _PostAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.textHint, size: 18),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
