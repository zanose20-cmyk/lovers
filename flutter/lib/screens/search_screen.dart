import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/api_provider.dart';

class SearchScreen extends StatefulWidget {
  final String initialQuery;
  const SearchScreen({super.key, this.initialQuery = ''});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late TextEditingController _controller;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _hashtags = [];
  bool _loading = false;
  String _mode = 'users';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    if (widget.initialQuery.isNotEmpty) _search();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    setState(() => _loading = true);
    final api = context.read<ApiProvider>().api;
    try {
      final resp = await api.get('/api/users/search', queryParams: {'q': q});
      if (resp.statusCode == 200) {
        _users = (resp.data['users'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        _hashtags = (resp.data['hashtags'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          onSubmitted: (_) => _search(),
          decoration: const InputDecoration(
            hintText: 'بحث...',
            hintStyle: TextStyle(color: AppColors.textHint),
            border: InputBorder.none,
          ),
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _search,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty && _hashtags.isEmpty
              ? Center(child: Text(
                  widget.initialQuery.isEmpty ? 'ابحث عن مستخدمين أو هاشتاغات' : 'لا توجد نتائج',
                  style: const TextStyle(color: AppColors.textHint),
                ))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_hashtags.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text('الهاشتاغات', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _hashtags.map((h) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundCard,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('#${h['tag'] ?? ''}', style: const TextStyle(color: AppColors.primary)),
                        )).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_users.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text('المستخدمين', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      ..._users.map((u) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundCard,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: InkWell(
                          onTap: () => Navigator.pushNamed(context, '/profile', arguments: u['userId']),
                          borderRadius: BorderRadius.circular(14),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.backgroundCardLight,
                                backgroundImage: u['avatarUrl'] != null ? NetworkImage(u['avatarUrl']) : null,
                                child: u['avatarUrl'] == null ? const Icon(Icons.person, color: AppColors.textHint) : null,
                              ),
                              const SizedBox(width: 12),
                              Text(u['displayName'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                        ),
                      )),
                    ],
                  ],
                ),
    );
  }
}