import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../theme/app_theme.dart';
import '../providers/rooms_provider.dart';
import '../providers/tasks_provider.dart';
import '../providers/messages_provider.dart';
import '../providers/wallet_provider.dart';
import '../models/room_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late final AnimationController _navAnimController;

  final List<Widget> _pages = [
    const _HomePage(),
    const _RoomsTab(),
    const _ExploreTab(),
    const _MessagesTab(),
    const _ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    _navAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoomsProvider>().loadRooms(type: 'public');
      context.read<TasksProvider>().loadDailyTasks();
      context.read<MessagesProvider>().loadConversations();
      final auth = context.read<AuthProvider>();
      if (auth.user != null) {
        final chargeLevel = auth.user!['chargeLevel'];
        context.read<WalletProvider>().setBalance((chargeLevel as num?)?.toInt() ?? 0);
        final userId = auth.user!['userId'] as String?;
        if (userId != null) {
          context.read<MessagesProvider>().listenForMessages(userId);
        }
      }
    });
  }

  @override
  void dispose() {
    _navAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        child: _pages[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.backgroundCard.withValues(alpha: 0.95),
              AppColors.backgroundDark,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: -5,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'الرئيسية'),
                _buildNavItem(1, Icons.mic_rounded, 'الغرف'),
                _buildExploreButton(2),
                _buildNavItem(3, Icons.chat_rounded, 'المحادثات'),
                _buildNavItem(4, Icons.person_rounded, 'حسابي'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    int badgeCount = 0;
    if (index == 3) {
      try {
        final mp = context.read<MessagesProvider>();
        badgeCount = mp.unreadCount;
      } catch (_) {}
    }
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _currentIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppColors.primary : AppColors.textHint,
                  size: 24,
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -4, right: -8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                      child: Text('$badgeCount', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textHint,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExploreButton(int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        setState(() => _currentIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: isSelected ? const LinearGradient(
            colors: AppColors.premiumGradient,
          ) : null,
          color: isSelected ? null : AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ] : [],
        ),
        child: Icon(
          Icons.explore_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}

class _HomePage extends StatefulWidget {
  const _HomePage();

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  Future<void> _onRefresh() async {
    try {
      await Future.wait([
        context.read<RoomsProvider>().loadRooms(type: 'public'),
        context.read<TasksProvider>().loadDailyTasks(),
        context.read<MessagesProvider>().loadConversations(),
      ]);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final balance = user?['chargeLevel'] ?? 0;
    final displayName = user?['displayName'] ?? 'مستخدم';
    final level = user?['level'] ?? 1;
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.primary,
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('LOVERS', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: 2)),
                    const SizedBox(width: 8),
                    Text(displayName, style: const TextStyle(fontSize: 14, color: AppColors.textHint)),
                  ],
                ),
                Row(
                  children: [
                    _IconButton(Icons.notifications_outlined, () => Navigator.pushNamed(context, '/notifications')),
                    const SizedBox(width: 8),
                    _IconButton(Icons.settings_outlined, () => Navigator.pushNamed(context, '/settings')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Balance Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppColors.premiumGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 2)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('رصيد المحفظة', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.diamond_rounded, color: Colors.white, size: 28),
                      const SizedBox(width: 8),
                      Text('$balance', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/wallet'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.add, color: Colors.white, size: 18),
                              SizedBox(width: 4),
                              Text('شحن', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _BalanceBadge(title: 'المستوى $level', color: AppColors.neonBlue),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            const Text('إجراءات سريعة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Row(
              children: [
                _QuickActionButton(icon: Icons.add_circle_outline, label: 'غرفة جديدة', color: AppColors.primary, onTap: () => Navigator.pushNamed(context, '/create-room')),
                const SizedBox(width: 12),
                _QuickActionButton(icon: Icons.card_giftcard_outlined, label: 'متجر الهدايا', color: AppColors.neonPink, onTap: () => Navigator.pushNamed(context, '/store')),
                const SizedBox(width: 12),
                _QuickActionButton(icon: Icons.diamond_outlined, label: 'VIP', color: AppColors.gold, onTap: () => Navigator.pushNamed(context, '/vip')),
              ],
            ),
            const SizedBox(height: 24),

            // Trending Rooms
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('الغرف الرائجة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                TextButton(onPressed: () => Navigator.pushNamed(context, '/rooms-list'), child: const Text('عرض الكل', style: TextStyle(color: AppColors.primary))),
              ],
            ),
            const SizedBox(height: 12),
            Consumer<RoomsProvider>(
              builder: (ctx, rp, _) {
                final rooms = rp.rooms.take(5).toList();
                if (rooms.isEmpty) {
                  return const SizedBox(
                    height: 150,
                    child: Center(child: Text('لا توجد غرف', style: TextStyle(color: AppColors.textHint))),
                  );
                }
                return SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: rooms.length,
                    itemBuilder: (context, index) => _TrendingRoomCard(room: rooms[index]),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Daily Tasks
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('المهام اليومية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                TextButton(onPressed: () => Navigator.pushNamed(context, '/daily-tasks'), child: const Text('المزيد', style: TextStyle(color: AppColors.primary))),
              ],
            ),
            const SizedBox(height: 12),
            Consumer<TasksProvider>(
              builder: (ctx, tp, _) {
                final tasks = tp.tasks.take(3).toList();
                if (tasks.isEmpty) {
                  return const SizedBox(height: 80, child: Center(child: Text('لا توجد مهام', style: TextStyle(color: AppColors.textHint))));
                }
                return Column(
                  children: tasks.map((t) => _DailyTaskCard(
                    title: t.title ?? '',
                    reward: '${t.reward?.coins ?? 0} عملة',
                    progress: t.progress ?? 0,
                    target: t.target ?? 1,
                  )).toList(),
                );
              },
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _RoomsTab extends StatelessWidget {
  const _RoomsTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('الغرف الصوتية', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.read<RoomsProvider>().loadRooms(type: 'public'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundCard,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.public, color: AppColors.primary, size: 16),
                            SizedBox(width: 4),
                            Text('عامة', style: TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _IconButton(Icons.add, () => Navigator.pushNamed(context, '/create-room')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<RoomsProvider>(
                builder: (ctx, rp, _) {
                  if (rp.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (rp.rooms.isEmpty) {
                    return const Center(child: Text('لا توجد غرف', style: TextStyle(color: AppColors.textHint)));
                  }
                  return ListView.builder(
                    itemCount: rp.rooms.length,
                    itemBuilder: (context, index) => _RoomListItem(room: rp.rooms[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExploreTab extends StatelessWidget {
  const _ExploreTab();

  final List<_ExploreItem> _items = const [
    _ExploreItem(Icons.person, 'مستخدمين جدد', '/friend-requests'),
    _ExploreItem(Icons.mic, 'غرف نشطة', '/rooms-list'),
    _ExploreItem(Icons.card_giftcard, 'الهدايا', '/store'),
    _ExploreItem(Icons.people, 'وكالات', '/agencies'),
    _ExploreItem(Icons.emoji_events, 'المتداول', '/posts'),
    _ExploreItem(Icons.trending_up, 'التصنيف', '/vip'),
    _ExploreItem(Icons.post_add, 'منشورات', '/posts'),
    _ExploreItem(Icons.workspace_premium, 'VIP', '/vip'),
    _ExploreItem(Icons.directions_car, 'مركبات', '/vehicles-store'),
    _ExploreItem(Icons.more_horiz, 'المزيد', '/settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('استكشاف', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            TextField(
              onSubmitted: (q) {
                if (q.trim().isNotEmpty) {
                  Navigator.pushNamed(context, '/search', arguments: q.trim());
                }
              },
              decoration: InputDecoration(
                hintText: 'ابحث عن مستخدمين، غرف، هاشتاغ...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint),
                suffixIcon: const Icon(Icons.search, color: AppColors.primary, size: 20),
                filled: true,
                fillColor: AppColors.backgroundCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return GestureDetector(
                    onTap: () => Navigator.pushNamed(context, item.route),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.backgroundCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.backgroundCardLight),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(item.icon, size: 40, color: AppColors.primary),
                          const SizedBox(height: 8),
                          Text(item.label, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExploreItem {
  final IconData icon; final String label; final String route;
  const _ExploreItem(this.icon, this.label, this.route);
}

class _MessagesTab extends StatelessWidget {
  const _MessagesTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('المحادثات', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                _IconButton(Icons.edit_outlined, () => Navigator.pushNamed(context, '/messages')),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<MessagesProvider>(
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
                      itemCount: mp.conversations.length,
                      itemBuilder: (context, index) {
                        final conv = mp.conversations[index];
                        return _ConversationItem(
                          name: conv.user?['displayName'] ?? 'مستخدم',
                          lastMsg: conv.lastMessage?.content ?? '',
                          unread: conv.unread ?? 0,
                          onTap: () => Navigator.pushNamed(context, '/conversation', arguments: conv.user?['userId'] ?? ''),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final name = user?['displayName'] ?? 'زائر';
    final level = user?['level'] ?? 1;
    final avatar = user?['avatarUrl'];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.backgroundCardLight,
              backgroundImage: avatar != null ? NetworkImage(avatar) as ImageProvider : null,
              child: avatar == null ? const Icon(Icons.person, size: 50, color: AppColors.textHint) : null,
            ),
            const SizedBox(height: 12),
            Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('المستوى $level', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatItem(value: '${user?['followersCount'] ?? 0}', label: 'متابع'),
                _StatItem(value: '${user?['followingCount'] ?? 0}', label: 'متابَع'),
                _StatItem(value: '${user?['friendsCount'] ?? 0}', label: 'أصدقاء'),
              ],
            ),
            const SizedBox(height: 24),
            _ProfileMenuItem(icon: Icons.person_outline, title: 'الملف الشخصي', onTap: () => Navigator.pushNamed(context, '/profile', arguments: user?['userId'])),
            _ProfileMenuItem(icon: Icons.wallet_outlined, title: 'المحفظة', onTap: () => Navigator.pushNamed(context, '/wallet')),
            _ProfileMenuItem(icon: Icons.diamond_outlined, title: 'VIP', onTap: () => Navigator.pushNamed(context, '/vip')),
            _ProfileMenuItem(icon: Icons.directions_car_outlined, title: 'المركبات', onTap: () => Navigator.pushNamed(context, '/vehicles-store')),
            _ProfileMenuItem(icon: Icons.business_outlined, title: 'الوكالات', onTap: () => Navigator.pushNamed(context, '/agencies')),
            _ProfileMenuItem(icon: Icons.people_outline, title: 'طلبات الصداقة', onTap: () => Navigator.pushNamed(context, '/friend-requests')),
            _ProfileMenuItem(icon: Icons.post_add_outlined, title: 'المنشورات', onTap: () => Navigator.pushNamed(context, '/posts')),
            _ProfileMenuItem(icon: Icons.task_alt_outlined, title: 'المهام اليومية', onTap: () => Navigator.pushNamed(context, '/daily-tasks')),
            _ProfileMenuItem(icon: Icons.settings_outlined, title: 'الإعدادات', onTap: () => Navigator.pushNamed(context, '/settings')),
            _ProfileMenuItem(icon: Icons.logout_rounded, title: 'تسجيل الخروج', isDestructive: true, onTap: () => _logout(context, auth)),
          ],
        ),
      ),
    );
  }

  void _logout(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              auth.logout();
              Navigator.pop(ctx);
              if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }
}

// Supporting Widgets
class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconButton(this.icon, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 22),
      ),
    );
  }
}

class _BalanceBadge extends StatelessWidget {
  final String title;
  final Color color;
  const _BalanceBadge({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(title, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _QuickActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendingRoomCard extends StatelessWidget {
  final RoomModel room;
  const _TrendingRoomCard({required this.room});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/room', arguments: room.roomId),
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.backgroundCard, AppColors.backgroundCardLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.backgroundCardLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.mic, color: AppColors.primary, size: 20),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.fiber_manual_record, color: AppColors.success, size: 8),
                      SizedBox(width: 2),
                      Text('مباشر', style: TextStyle(color: AppColors.success, fontSize: 9, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(room.title ?? 'غرفة', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.people, color: AppColors.textHint, size: 14),
                const SizedBox(width: 4),
                Text('${room.occupiedSeats}/${room.capacity ?? 12}', style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomListItem extends StatelessWidget {
  final RoomModel room;
  const _RoomListItem({required this.room});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/room', arguments: room.roomId),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.mic, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(room.title ?? 'غرفة', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('${room.occupiedSeats}/${room.capacity ?? 12}', style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('انضمام', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationItem extends StatelessWidget {
  final String name; final String lastMsg; final int unread; final VoidCallback onTap;
  const _ConversationItem({required this.name, required this.lastMsg, required this.unread, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.backgroundCardLight,
              child: Icon(Icons.person, color: AppColors.textHint, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(lastMsg, style: TextStyle(color: unread > 0 ? AppColors.textPrimary : AppColors.textHint, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
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
  }
}

class _StatItem extends StatelessWidget {
  final String value; final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppColors.textHint, fontSize: 13)),
      ],
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon; final String title; final bool isDestructive; final VoidCallback onTap;
  const _ProfileMenuItem({required this.icon, required this.title, this.isDestructive = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.all(14),
          backgroundColor: isDestructive ? AppColors.error.withValues(alpha: 0.1) : AppColors.backgroundCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          children: [
            Icon(icon, color: isDestructive ? AppColors.error : AppColors.textPrimary, size: 22),
            const SizedBox(width: 12),
            Text(title, style: TextStyle(color: isDestructive ? AppColors.error : AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _DailyTaskCard extends StatelessWidget {
  final String title; final String reward; final int progress; final int target;
  const _DailyTaskCard({required this.title, required this.reward, required this.progress, required this.target});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.task_alt, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text('$reward - $progress/$target', style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
