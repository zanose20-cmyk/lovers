import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/tasks_provider.dart';
import '../models/daily_task_model.dart';

class DailyTasksScreen extends StatefulWidget {
  const DailyTasksScreen({super.key});

  @override
  State<DailyTasksScreen> createState() => _DailyTasksScreenState();
}

class _DailyTasksScreenState extends State<DailyTasksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TasksProvider>().loadDailyTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(title: const Text('المهام اليومية')),
      body: Consumer<TasksProvider>(
        builder: (ctx, tp, _) {
          if (tp.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: AppColors.premiumGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('تسجيل الدخول المستمر', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text('${tp.loginStreak ?? 0} أيام', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 32),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          7,
                          (i) => Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: i < (tp.loginStreak ?? 0) ? Colors.white.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: i < (tp.loginStreak ?? 0)
                                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                                  : Text('${i + 1}', style: const TextStyle(color: Colors.white54, fontSize: 14)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('المهام', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                ...tp.tasks.map((task) => _TaskCard(task: task)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final DailyTaskModel task;
  const _TaskCard({required this.task});

  IconData _icon() {
    switch (task.type) {
      case 'daily_login': return Icons.login_rounded;
      case 'activity_hours': return Icons.timer_rounded;
      case 'send_gifts': return Icons.card_giftcard_rounded;
      case 'join_rooms': return Icons.mic_rounded;
      case 'invite_friends': return Icons.people_rounded;
      case 'watch_ads': return Icons.play_circle_outline_rounded;
      case 'share_content': return Icons.share_rounded;
      default: return Icons.task_alt;
    }
  }

  Color _color() {
    switch (task.type) {
      case 'daily_login': return AppColors.gold;
      case 'activity_hours': return AppColors.primary;
      case 'send_gifts': return AppColors.neonPink;
      case 'join_rooms': return AppColors.neonBlue;
      case 'invite_friends': return AppColors.success;
      case 'watch_ads': return AppColors.gold;
      case 'share_content': return AppColors.warning;
      default: return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = task.progress ?? 0;
    final t = task.target ?? 1;
    final completed = task.completed ?? false;
    final color = _color();
    final rewardParts = <String>[];
    if ((task.reward?.coins ?? 0) > 0) rewardParts.add('${task.reward!.coins} عملة');
    if ((task.reward?.xp ?? 0) > 0) rewardParts.add('${task.reward!.xp} XP');
    final rewardStr = rewardParts.join(' + ');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(14),
        border: completed ? Border.all(color: color.withValues(alpha: 0.5)) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon(), color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title ?? '', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text('$rewardStr - $p/$t', style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: t > 0 ? p / t : 0,
                    backgroundColor: AppColors.backgroundCardLight,
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: completed && !(task.claimed ?? false)
                ? () async {
                    try {
                      final ok = task.taskId != null ? await context.read<TasksProvider>().claimReward(task.taskId!) : false;
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(ok ? 'تم استلام المكافأة' : 'فشل استلام المكافأة')),
                        );
                      }
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('خطأ في الاتصال')),
                        );
                      }
                    }
                  }
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: completed && !(task.claimed ?? false)
                    ? color.withValues(alpha: 0.2)
                    : AppColors.backgroundCardLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                (task.claimed ?? false) ? 'تم' : (completed ? 'استلام' : 'متابعة'),
                style: TextStyle(
                  color: completed && !(task.claimed ?? false) ? color : AppColors.textHint,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
