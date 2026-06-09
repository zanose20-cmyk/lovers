import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_provider.dart';
import '../services/socket_service.dart';
import '../config/app_config.dart';
import '../theme/app_theme.dart';
import '../providers/rooms_provider.dart';
import '../providers/api_provider.dart';
import '../models/room_model.dart';

class RoomScreen extends StatefulWidget {
  final String roomId;
  const RoomScreen({super.key, required this.roomId});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  RoomModel? _room;
  bool _isLoading = true;
  bool _isMuted = false;
  bool _isDeafened = false;
  final _socketService = SocketService();

  @override
  void initState() {
    super.initState();
    _loadRoom().then((_) => _joinRoom());
    _connectSocket();
  }

  Future<void> _connectSocket() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('server_token');
      if (token != null && mounted) {
        _socketService.connect(AppConfig.serverUrl, token);
        _socketService.on('userJoined', (data) { if (mounted) _loadRoom(); });
        _socketService.on('userLeft', (data) { if (mounted) _loadRoom(); });
        _socketService.on('userRemoved', (data) { if (mounted) _loadRoom(); });
        _socketService.on('admin:kicked', (data) { if (mounted) _loadRoom(); });
        _socketService.on('admin:banned', (data) { if (mounted) _loadRoom(); });
        _socketService.on('userMuted', (data) { if (mounted) _loadRoom(); });
      }
    } catch (_) {}
  }

  Future<void> _loadRoom() async {
    try {
      final rp = context.read<RoomsProvider>();
      await rp.loadRoom(widget.roomId);
      if (mounted) setState(() { _room = rp.currentRoom; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _joinRoom() async {
    try {
      final rp = context.read<RoomsProvider>();
      await rp.joinRoom(widget.roomId);
      await _loadRoom();
    } catch (_) {}
  }

  Future<void> _joinVoice() async {
    try {
      final rp = context.read<RoomsProvider>();
      final auth = context.read<AuthProvider>();
      final voiceAccess = await rp.getVoiceAccess(widget.roomId);
      if (voiceAccess != null && mounted) {
        final engine = voiceAccess['engine'] as String?;
        if (engine == 'jitsi') {
          Navigator.pushNamed(context, '/jitsi-room', arguments: {
            'server': voiceAccess['server'],
            'roomName': voiceAccess['roomName'],
            'displayName': auth.user?['displayName'] ?? 'مستخدم',
            'token': auth.token,
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطأ في الاتصال بالغرفة')),
        );
      }
    }
  }

  Future<void> _leaveRoom() async {
    try {
      final rp = context.read<RoomsProvider>();
      final ok = await rp.leaveRoom(widget.roomId);
      if (ok && mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _socketService.dispose();
    super.dispose();
  }

  void _kickUser(String userId) {
    _socketService.emit('admin:kick', {'roomId': widget.roomId, 'userId': userId});
  }

  void _banUser(String userId) {
    _socketService.emit('admin:ban', {'roomId': widget.roomId, 'userId': userId});
  }

  void _muteUser(String userId, bool muted) {
    _socketService.emit('seat:mute', {'roomId': widget.roomId, 'userId': userId, muted: !muted});
  }

  void _muteAll() {
    final seats = _room?.seats ?? [];
    for (final seat in seats) {
      if (seat.userId != null && !(seat.isMuted ?? false)) {
        _muteUser(seat.userId!, false);
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم كتم جميع المستخدمين')));
  }

  void _unmuteAll() {
    final seats = _room?.seats ?? [];
    for (final seat in seats) {
      if (seat.userId != null && (seat.isMuted ?? false)) {
        _muteUser(seat.userId!, true);
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إلغاء الكتم للجميع')));
  }

  void _showRoomSettings() {
    final titleController = TextEditingController(text: _room?.title ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: AppColors.textHint, borderRadius: BorderRadius.circular(2))),
            const Text('إعدادات الغرفة', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: titleController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'اسم الغرفة',
                labelStyle: const TextStyle(color: AppColors.textHint),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.backgroundCardLight)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  final newTitle = titleController.text.trim();
                  if (newTitle.isEmpty) return;
                  try {
                    final api = context.read<ApiProvider>().api;
                    final resp = await api.put('/api/rooms/${widget.roomId}/settings', body: {'title': newTitle});
                    if (resp.statusCode == 200) {
                      _loadRoom();
                      if (mounted) Navigator.pop(ctx);
                    }
                  } catch (_) {}
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('حفظ', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showAdminMenu(String targetUserId, String displayName, bool isMuted) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: AppColors.textHint, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text(displayName, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(isMuted ? Icons.mic : Icons.mic_off, color: isMuted ? AppColors.success : AppColors.error),
              title: Text(isMuted ? 'إلغاء الكتم' : 'كتم الصوت'),
              onTap: () {
                Navigator.pop(ctx);
                _muteUser(targetUserId, isMuted);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_remove, color: AppColors.error),
              title: const Text('طرد من الغرفة', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(ctx);
                _kickUser(targetUserId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: AppColors.error),
              title: const Text('حظر من الغرفة', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(ctx);
                _banUser(targetUserId);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final auth = context.read<AuthProvider>();
    final isOwner = _room?.ownerId == auth.user?['userId'];
    final isAdmin = (auth.user?['roles'] as List?)?.contains('admin') == true;
    final canManage = isOwner || isAdmin;
    final seats = _room?.seats ?? [];
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.fiber_manual_record, color: AppColors.success, size: 10),
                        SizedBox(width: 4),
                        Text('مباشر', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: _room?.capacity ?? 12,
                itemBuilder: (context, index) {
                  final seat = index < seats.length ? seats[index] : null;
                  final isOccupied = seat?.userId != null;
                  final isSeatMuted = seat?.isMuted ?? false;
                  return GestureDetector(
                    onLongPress: (canManage && isOccupied && seat?.userId != null && seat?.userId != auth.user?['userId'])
                        ? () => _showAdminMenu(seat!.userId!, seat.displayName ?? 'مستخدم', isSeatMuted)
                        : null,
                    child: _SeatWidget(
                      seatIndex: index,
                      displayName: seat?.displayName,
                      isOccupied: isOccupied,
                      isMuted: isSeatMuted,
                      isLocked: seat?.isLocked ?? false,
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_room?.title ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                      if (canManage) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _showRoomSettings,
                          child: const Icon(Icons.settings, color: AppColors.textHint, size: 20),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ControlButton(
                        icon: Icons.mic,
                        label: 'كتم',
                        isActive: _isMuted,
                        onTap: () => setState(() => _isMuted = !_isMuted),
                      ),
                      _ControlButton(
                        icon: Icons.headphones,
                        label: 'إسكات',
                        isActive: _isDeafened,
                        onTap: () => setState(() => _isDeafened = !_isDeafened),
                      ),
                      _ControlButton(
                        icon: Icons.phone_in_talk,
                        label: 'انضمام',
                        color: AppColors.success,
                        onTap: _joinVoice,
                      ),
                      _ControlButton(
                        icon: Icons.card_giftcard,
                        label: 'هدية',
                        color: AppColors.neonPink,
                        onTap: () => Navigator.pushNamed(context, '/store'),
                      ),
                    ],
                  ),
                  if (canManage) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ControlButton(
                          icon: Icons.volume_off,
                          label: 'كتم الكل',
                          color: AppColors.error,
                          onTap: _muteAll,
                        ),
                        _ControlButton(
                          icon: Icons.volume_up,
                          label: 'إلغاء الكل',
                          color: AppColors.success,
                          onTap: _unmuteAll,
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _leaveRoom,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error.withValues(alpha: 0.2),
                        foregroundColor: AppColors.error,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('مغادرة الغرفة'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeatWidget extends StatelessWidget {
  final int seatIndex; final String? displayName;
  final bool isOccupied; final bool isMuted; final bool isLocked;
  const _SeatWidget({required this.seatIndex, this.displayName, required this.isOccupied, required this.isMuted, required this.isLocked});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isOccupied ? AppColors.backgroundCardLight : AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isOccupied ? AppColors.success.withValues(alpha: 0.5) : AppColors.backgroundCardLight),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isLocked ? Icons.lock : (isOccupied ? Icons.person : Icons.person_add_alt),
            color: isOccupied ? AppColors.success : (isLocked ? AppColors.error : AppColors.textHint),
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            displayName ?? '${seatIndex + 1}',
            style: TextStyle(
              color: isOccupied ? AppColors.textPrimary : AppColors.textHint,
              fontSize: 10, fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (isOccupied && isMuted)
            const Icon(Icons.mic_off, color: AppColors.error, size: 12),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon; final String label;
  final bool isActive; final Color? color; final VoidCallback onTap;
  const _ControlButton({required this.icon, required this.label, this.isActive = false, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = color ?? (isActive ? AppColors.primary : AppColors.textHint);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: c, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: c, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
