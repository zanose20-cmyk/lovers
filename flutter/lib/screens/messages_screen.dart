import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/messages_provider.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessagesProvider>().loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(title: const Text('المحادثات')),
      body: Consumer<MessagesProvider>(
        builder: (ctx, mp, _) {
          if (mp.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (mp.conversations.isEmpty) {
            return const Center(child: Text('لا توجد محادثات', style: TextStyle(color: AppColors.textHint)));
          }
          return RefreshIndicator(
            onRefresh: () => mp.loadConversations(),
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: mp.conversations.length,
              itemBuilder: (context, index) {
              final conv = mp.conversations[index];
              final userName = conv.user?['displayName'] ?? 'مستخدم';
              final userAvatar = conv.user?['avatarUrl'];
              final lastMsg = conv.lastMessage?.content ?? '';
              final unread = conv.unread ?? 0;
              final timeAgo = conv.lastMessage?.createdAt != null
                  ? _timeAgo(conv.lastMessage!.createdAt!)
                  : '';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: InkWell(
                  onTap: () => Navigator.pushNamed(
                    context, '/conversation',
                    arguments: conv.user?['userId'] ?? '',
                  ),
                  borderRadius: BorderRadius.circular(14),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: AppColors.backgroundCardLight,
                            backgroundImage: userAvatar != null
                                ? NetworkImage(userAvatar) as ImageProvider
                                : null,
                            child: userAvatar == null
                                ? const Icon(Icons.person, color: AppColors.textHint, size: 26)
                                : null,
                          ),
                          Positioned(
                            bottom: 0, right: 0,
                            child: Container(
                              width: 12, height: 12,
                              decoration: BoxDecoration(
                                color: unread > 0 ? AppColors.success : AppColors.textHint,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.backgroundDark, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(userName, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                                const Spacer(),
                                Text(timeAgo, style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lastMsg,
                              style: TextStyle(color: unread > 0 ? AppColors.textPrimary : AppColors.textHint, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (unread > 0)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
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
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
