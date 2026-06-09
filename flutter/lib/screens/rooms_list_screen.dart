import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/rooms_provider.dart';
import '../models/room_model.dart';
import '../widgets/common_widgets.dart';

class RoomsListScreen extends StatefulWidget {
  const RoomsListScreen({super.key});

  @override
  State<RoomsListScreen> createState() => _RoomsListScreenState();
}

class _RoomsListScreenState extends State<RoomsListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoomsProvider>().loadRooms(type: 'public');
    });
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
        title: const Text('الغرف الصوتية'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          onTap: (i) {
            final types = ['public', 'private', 'vip', 'agency'];
            context.read<RoomsProvider>().loadRooms(type: types[i]);
          },
          tabs: const [
            Tab(text: 'عامة'),
            Tab(text: 'خاصة'),
            Tab(text: 'VIP'),
            Tab(text: 'وكالات'),
          ],
        ),
      ),
      body: Consumer<RoomsProvider>(
        builder: (ctx, rp, _) {
          if (rp.isLoading && rp.rooms.isEmpty) {
            return ShimmerList(itemCount: 6, itemHeight: 100);
          }
          if (rp.error != null && rp.rooms.isEmpty) {
            return ProfessionalEmptyState(
              icon: Icons.error_outline,
              title: 'حدث خطأ',
              subtitle: rp.error ?? 'حدث خطأ غير متوقع',
              actionLabel: 'إعادة المحاولة',
              onAction: () => rp.loadRooms(type: 'public'),
            );
          }
          if (rp.rooms.isEmpty) {
            return const ProfessionalEmptyState(
              icon: Icons.meeting_room_outlined,
              title: 'لا توجد غرف',
              subtitle: 'لم يتم إنشاء أي غرف بعد. كن أول من ينشئ غرفة!',
              actionLabel: 'إنشاء غرفة',
            );
          }
          return RefreshIndicator(
            onRefresh: () => rp.loadRooms(type: ['public', 'private', 'vip', 'agency'][_tabController.index]),
            color: AppColors.primary,
            child: _RoomList(rooms: rp.rooms),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/create-room'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _RoomList extends StatelessWidget {
  final List<RoomModel> rooms;
  const _RoomList({required this.rooms});

  @override
  Widget build(BuildContext context) {
    if (rooms.isEmpty) {
      return const Center(child: Text('لا توجد غرف', style: TextStyle(color: AppColors.textHint)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final room = rooms[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                        Text(room.title ?? 'غير معروف', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.person, color: AppColors.textHint, size: 14),
                            const SizedBox(width: 4),
                            Text('المالك: ${room.ownerName ?? 'غير معروف'}', style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
                            const SizedBox(width: 12),
                            const Icon(Icons.people, color: AppColors.textHint, size: 14),
                            const SizedBox(width: 4),
                            Text('${room.occupiedSeats}/${room.capacity ?? 12}', style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.fiber_manual_record, color: AppColors.success, size: 8),
                        SizedBox(width: 4),
                        Text('مباشر', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ...List.generate(
                    room.seats?.where((s) => s.userId != null).length.clamp(0, 5) ?? 0,
                    (i) => Align(
                      widthFactor: 0.7,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.backgroundCardLight,
                        child: const Icon(Icons.person, size: 14, color: AppColors.textHint),
                      ),
                    ),
                  ),
                  if ((room.seats?.where((s) => s.userId != null).length ?? 0) > 5) ...[
                    const SizedBox(width: 8),
                    Text('+${(room.seats?.where((s) => s.userId != null).length ?? 0) - 5}', style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/room', arguments: room.roomId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('انضمام'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
