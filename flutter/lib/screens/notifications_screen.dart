import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/notifications_provider.dart';
import '../models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsProvider>().loadNotifications();
    });
  }

          @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          title: const Text('الإشعارات'),
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textHint,
            tabs: [
              Tab(text: 'الكل'),
              Tab(text: 'غير المقروءة'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                try {
                  await context.read<NotificationsProvider>().markAllRead();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديد الكل كمقروء')));
                  }
                } catch (_) {}
              },
              child: const Text('قراءة الكل', style: TextStyle(color: AppColors.primary, fontSize: 13)),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildNotificationList(filterUnread: false),
            _buildNotificationList(filterUnread: true),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList({required bool filterUnread}) {
    return Consumer<NotificationsProvider>(
      builder: (ctx, np, _) {
        if (np.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = filterUnread
            ? np.notifications.where((n) => !(n.isRead ?? true)).toList()
            : np.notifications;
        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(filterUnread ? Icons.done_all : Icons.notifications_off, color: AppColors.textHint, size: 48),
                const SizedBox(height: 12),
                Text(filterUnread ? 'لا توجد إشعارات غير مقروءة' : 'لا توجد إشعارات', style: const TextStyle(color: AppColors.textHint)),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => np.loadNotifications(),
          color: AppColors.primary,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final notif = list[index];
              final icon = _iconForType(notif.type);
              final color = _colorForType(notif.type);
              final isUnread = !(notif.isRead ?? true);

              return GestureDetector(
                onTap: () {
                  if (isUnread && notif.notifId != null) np.markRead(notif.notifId!);
                  _handleNotificationTap(notif);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isUnread ? AppColors.backgroundCard.withValues(alpha: 0.8) : AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(14),
                    border: isUnread ? Border.all(color: AppColors.primary.withValues(alpha: 0.3)) : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(notif.title ?? '', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(
                              notif.body ?? '',
                              style: TextStyle(color: isUnread ? AppColors.textPrimary : AppColors.textHint, fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(_timeAgo(notif.createdAt), style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
                      if (isUnread)
                        Container(
                          width: 8, height: 8,
                          margin: const EdgeInsets.only(left: 4),
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _handleNotificationTap(NotificationModel notif) {
    final data = notif.data;
    if (data == null) return;
    final context = this.context;
    if (data['roomId'] != null) {
      Navigator.pushNamed(context, '/room', arguments: data['roomId']);
    } else if (data['userId'] != null) {
      Navigator.pushNamed(context, '/profile', arguments: data['userId']);
    } else if (data['postId'] != null) {
      Navigator.pushNamed(context, '/post-comments', arguments: {'postId': data['postId']});
    }
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'gift': return Icons.card_giftcard;
      case 'follow': return Icons.person_add;
      case 'like': return Icons.favorite;
      case 'comment': return Icons.chat_bubble;
      case 'room_invite': return Icons.mic;
      case 'friend_request': return Icons.people;
      case 'achievement': return Icons.emoji_events;
      case 'daily_reward': return Icons.redeem;
      default: return Icons.notifications;
    }
  }

  Color _colorForType(String? type) {
    switch (type) {
      case 'gift': return AppColors.neonPink;
      case 'follow': return AppColors.primary;
      case 'like': return AppColors.error;
      case 'comment': return AppColors.neonBlue;
      case 'room_invite': return AppColors.gold;
      case 'friend_request': return AppColors.success;
      case 'achievement': return AppColors.warning;
      default: return AppColors.textHint;
    }
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}د';
    if (diff.inHours < 24) return '${diff.inHours}س';
    if (diff.inDays < 7) return '${diff.inDays}ي';
    return '${dt.day}/${dt.month}';
  }
}
