import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/api_provider.dart';

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _received = [];
  List<Map<String, dynamic>> _sent = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    final api = context.read<ApiProvider>().api;
    try {
      final resp = await api.get('/api/friends/requests');
      if (resp.statusCode == 200) {
        _received = (resp.data['received'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
        _sent = (resp.data['sent'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _accept(String requestId) async {
    final api = context.read<ApiProvider>().api;
    try {
      await api.post('/api/friends/accept', body: {'requestId': requestId});
      _received.removeWhere((r) => r['requestId'] == requestId);
      if (mounted) setState(() {});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم قبول الطلب')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل قبول الطلب')));
    }
  }

  Future<void> _reject(String requestId) async {
    final api = context.read<ApiProvider>().api;
    try {
      await api.post('/api/friends/reject', body: {'requestId': requestId});
      _received.removeWhere((r) => r['requestId'] == requestId);
      if (mounted) setState(() {});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم رفض الطلب')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل رفض الطلب')));
    }
  }

  Future<void> _cancel(String requestId) async {
    final api = context.read<ApiProvider>().api;
    try {
      await api.post('/api/friends/cancel', body: {'requestId': requestId});
      _sent.removeWhere((r) => r['requestId'] == requestId);
      if (mounted) setState(() {});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إلغاء الطلب')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل إلغاء الطلب')));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('طلبات الصداقة'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          tabs: [
            Tab(text: 'المستلمة (${_received.length})'),
            Tab(text: 'المرسلة (${_sent.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _RequestsList(items: _received, onAccept: _accept, onReject: _reject),
                _RequestsList(items: _sent, onCancel: _cancel, sent: true),
              ],
            ),
    );
  }
}

class _RequestsList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final void Function(String)? onAccept;
  final void Function(String)? onReject;
  final void Function(String)? onCancel;
  final bool sent;

  const _RequestsList({required this.items, this.onAccept, this.onReject, this.onCancel, this.sent = false});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('لا توجد طلبات', style: TextStyle(color: AppColors.textHint)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final user = item['user'] as Map<String, dynamic>?;
        final name = user?['displayName'] ?? 'مستخدم';
        final avatarUrl = user?['avatarUrl'] as String?;
        final time = item['createdAt']?.toString() ?? '';
        final id = item['requestId'] as String? ?? '';
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.backgroundCardLight,
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? Icon(Icons.person, color: AppColors.textHint, size: 24)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                    if (time.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(time, style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
                    ],
                  ],
                ),
              ),
              if (!sent) ...[
                GestureDetector(
                  onTap: () => onAccept?.call(id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('قبول', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => onReject?.call(id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('رفض', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('معلق', style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => onCancel?.call(id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('إلغاء', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}