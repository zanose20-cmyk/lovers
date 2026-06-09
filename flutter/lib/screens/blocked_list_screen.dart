import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class BlockedListScreen extends StatefulWidget {
  const BlockedListScreen({super.key});

  @override
  State<BlockedListScreen> createState() => _BlockedListScreenState();
}

class _BlockedListScreenState extends State<BlockedListScreen> {
  List<Map<String, dynamic>> _blocked = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = context.read<ApiService>();
      final resp = await api.get('/api/users/me/blocked');
      if (resp.statusCode == 200) {
        final data = resp.data;
        setState(() {
          _blocked = List<Map<String, dynamic>>.from(data['blocked'] ?? []);
          _loading = false;
        });
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _unblock(String userId) async {
    try {
      final api = context.read<ApiService>();
      await api.post('/api/users/$userId/unblock');
      setState(() => _blocked.removeWhere((u) => u['userId'] == userId));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم فك الحظر')));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(title: const Text('المحظورون')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _blocked.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.block, color: AppColors.textHint, size: 48),
                      SizedBox(height: 12),
                      Text('لا يوجد مستخدمون محظورون', style: TextStyle(color: AppColors.textHint)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _blocked.length,
                  itemBuilder: (ctx, i) {
                    final u = _blocked[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundCard,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.backgroundCardLight,
                            backgroundImage: u['avatarUrl'] != null ? NetworkImage(u['avatarUrl']) : null,
                            child: u['avatarUrl'] == null
                                ? const Icon(Icons.person, color: AppColors.textHint)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(u['displayName'] ?? 'مستخدم', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                                if (u['country'] != null)
                                  Text(u['country'], style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => _unblock(u['userId']),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.success,
                              side: const BorderSide(color: AppColors.success),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('فك الحظر'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
