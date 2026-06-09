import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../theme/app_theme.dart';
import '../providers/rooms_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _loadRoom();
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
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
                  return _SeatWidget(
                    seatIndex: index,
                    displayName: seat?.displayName,
                    isOccupied: isOccupied,
                    isMuted: seat?.isMuted ?? false,
                    isLocked: seat?.isLocked ?? false,
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
                  Text(_room?.title ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
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
