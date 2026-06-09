import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../theme/app_theme.dart';
import '../providers/api_provider.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isFollowing = false;
  bool _isOwner = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  Future<void> _loadProfile() async {
    final auth = context.read<AuthProvider>();
    if (widget.userId == null || widget.userId == auth.user?['userId']) {
      _profile = auth.user;
      _isOwner = true;
    } else {
      _isOwner = false;
      _loading = true;
      setState(() {});
      try {
        final api = context.read<ApiProvider>().api;
        final resp = await api.get('/api/users/${widget.userId}');
        if (!mounted) return;
        if (resp.statusCode == 200) {
          _profile = resp.data['user'] as Map<String, dynamic>?;
          final myFriends = auth.user?['friends'] as List? ?? [];
          _isFollowing = myFriends.contains(widget.userId);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل تحميل الملف الشخصي')),
          );
        }
      }
      _loading = false;
    }
    if (mounted) setState(() {});
  }

  Future<void> _toggleFollow() async {
    final api = context.read<ApiProvider>().api;
    setState(() => _isFollowing = !_isFollowing);
    try {
      await api.post('/api/users/${widget.userId}/${_isFollowing ? 'follow' : 'unfollow'}');
    } catch (_) {
      if (mounted) setState(() => _isFollowing = !_isFollowing);
    }
  }

  void _startChat() {
    Navigator.pushNamed(context, '/conversation', arguments: widget.userId);
  }

  Future<void> _blockUser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text('حظر المستخدم', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('هل تريد حظر هذا المستخدم؟ لن تتمكن من رؤية محتوى بعضكما.', style: TextStyle(color: AppColors.textHint)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حظر', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    try {
      final api = context.read<ApiProvider>().api;
      final resp = await api.post('/api/users/${widget.userId}/block');
      if (resp.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحظر بنجاح')));
        Navigator.pop(context);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = _profile ?? auth.user;
    final name = user?['displayName'] ?? 'زائر';
    final avatar = user?['avatarUrl'];
    final bio = user?['bio'] ?? '';
    final country = user?['country'];
    final age = user?['age'];
    final level = user?['level'] ?? 1;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(_isOwner ? 'الملف الشخصي' : name),
        actions: [
          if (!_isOwner)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
              onSelected: (v) {
                if (v == 'block') _blockUser();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'block',
                  child: Text('حظر المستخدم', style: TextStyle(color: AppColors.error)),
                ),
              ],
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: AppColors.backgroundCardLight,
                  backgroundImage: avatar != null ? NetworkImage(avatar) as ImageProvider : null,
                  child: avatar == null ? const Icon(Icons.person, size: 60, color: AppColors.textHint) : null,
                ),
                if (_isOwner)
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            if (bio.isNotEmpty)
              Text(bio, style: const TextStyle(color: AppColors.textHint, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            if (country != null || age != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (country != null) ...[
                    const Icon(Icons.public, color: AppColors.textHint, size: 14),
                    const SizedBox(width: 4),
                    Text(country, style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
                  ],
                  if (country != null && age != null) const SizedBox(width: 12),
                  if (age != null) ...[
                    const Icon(Icons.cake, color: AppColors.textHint, size: 14),
                    const SizedBox(width: 4),
                    Text('$age سنة', style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
                  ],
                ],
              ),
            const SizedBox(height: 16),

            _isOwner
                ? SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/edit-profile'),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('تعديل الملف الشخصي'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.backgroundCard,
                        foregroundColor: AppColors.textPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _startChat,
                          icon: const Icon(Icons.message_outlined, size: 18),
                          label: const Text('مراسلة', style: TextStyle(fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _toggleFollow,
                          icon: Icon(_isFollowing ? Icons.person_remove_outlined : Icons.person_add_outlined, size: 18),
                          label: Text(_isFollowing ? 'إلغاء المتابعة' : 'متابعة', style: const TextStyle(fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isFollowing ? AppColors.backgroundCard : AppColors.primary.withValues(alpha: 0.8),
                            foregroundColor: _isFollowing ? AppColors.textPrimary : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _InfoCard(icon: Icons.people, label: 'متابعون', value: '${user?['followersCount'] ?? 0}'),
                _InfoCard(icon: Icons.person_add, label: 'متابَع', value: '${user?['followingCount'] ?? 0}'),
                _InfoCard(icon: Icons.favorite, label: 'أصدقاء', value: '${user?['friendsCount'] ?? 0}'),
              ],
            ),
            const SizedBox(height: 24),
            _InfoRow(label: 'المستوى', value: '$level'),
            _InfoRow(label: 'الهدايا المرسلة', value: '${user?['giftsSentCount'] ?? 0}'),
            _InfoRow(label: 'الهدايا المستلمة', value: '${user?['giftsReceivedCount'] ?? 0}'),
            if (user?['roles'] != null)
              _InfoRow(label: 'الرتب', value: (user!['roles'] as List).join(', ')),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon; final String label; final String value;
  const _InfoCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
          Text(label, style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label; final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textHint, fontSize: 14)),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}
