import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/api_provider.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<dynamic> _users = [];
  bool _loading = true;
  int _page = 1;
  bool _hasMore = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers({bool refresh = false}) async {
    if (refresh) { _page = 1; _hasMore = true; }
    if (!_hasMore && !refresh) return;
    try {
      final api = context.read<ApiProvider>().api;
      final search = _searchController.text.trim();
      final params = <String, String>{'page': '$_page', 'limit': '20'};
      if (search.isNotEmpty) params['search'] = search;
      final resp = await api.get('/api/admin/users', queryParams: params);
      if (resp.statusCode == 200 && mounted) {
        final users = resp.data['users'] ?? [];
        setState(() {
          _users = refresh ? users : [..._users, ...users];
          _hasMore = users.length >= 20;
          _page++;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleBan(String userId, bool isBanned) async {
    try {
      final api = context.read<ApiProvider>().api;
      final resp = isBanned
          ? await api.post('/api/admin/users/$userId/unban')
          : await api.post('/api/admin/users/$userId/ban');
      if (resp.statusCode == 200) {
        _loadUsers(refresh: true);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isBanned ? 'تم إلغاء الحظر' : 'تم الحظر')));
      }
    } catch (_) {}
  }

  Future<void> _makeAdmin(String userId) async {
    try {
      final api = context.read<ApiProvider>().api;
      final resp = await api.put('/api/admin/users/$userId', body: {'roles': ['admin']});
      if (resp.statusCode == 200) {
        _loadUsers(refresh: true);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم ترقية المستخدم')));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(title: const Text('إدارة المستخدمين')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _loadUsers(refresh: true),
              decoration: InputDecoration(
                hintText: 'بحث عن مستخدم...',
                hintStyle: const TextStyle(color: AppColors.textHint),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textHint),
                  onPressed: () { _searchController.clear(); _loadUsers(refresh: true); },
                ),
                filled: true,
                fillColor: AppColors.backgroundCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _users.length,
                    itemBuilder: (ctx, i) {
                      final user = _users[i];
                      final isBanned = (user['banned'] is Map) ? user['banned']['isBanned'] == true : user['banned'] == true;
                      final roles = (user['roles'] as List?) ?? [];
                      final isAdmin = roles.contains('admin') || roles.contains('superadmin');
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundCard,
                          borderRadius: BorderRadius.circular(12),
                          border: isBanned ? Border.all(color: AppColors.error.withValues(alpha: 0.5)) : null,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.backgroundCardLight,
                              backgroundImage: user['avatarUrl'] != null ? NetworkImage(user['avatarUrl']) : null,
                              child: user['avatarUrl'] == null ? const Icon(Icons.person, color: AppColors.textHint, size: 20) : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(user['displayName'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                                      if (isAdmin) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                                          child: const Text('ADMIN', style: TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                      if (isBanned) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                                          child: const Text('محظور', style: TextStyle(color: AppColors.error, fontSize: 9, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text('المستوى ${user['level'] ?? 1} | ${user['userId'] ?? ''}', style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: AppColors.textHint, size: 20),
                              onSelected: (v) {
                                if (v == 'ban') _toggleBan(user['userId'], false);
                                if (v == 'unban') _toggleBan(user['userId'], true);
                                if (v == 'admin') _makeAdmin(user['userId']);
                              },
                              itemBuilder: (_) => [
                                if (!isBanned) const PopupMenuItem(value: 'ban', child: Text('حظر', style: TextStyle(color: AppColors.error))),
                                if (isBanned) const PopupMenuItem(value: 'unban', child: Text('إلغاء الحظر', style: TextStyle(color: AppColors.success))),
                                if (!isAdmin) const PopupMenuItem(value: 'admin', child: Text('ترقية لمشرف')),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
