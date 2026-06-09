import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/messages_provider.dart';

class ConversationScreen extends StatefulWidget {
  final String userId;
  const ConversationScreen({super.key, required this.userId});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessagesProvider>().loadMessages(widget.userId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    try {
      final ok = await context.read<MessagesProvider>().sendMessage(widget.userId, text);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل إرسال الرسالة')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطأ في الاتصال')),
        );
      }
    }
    if (mounted) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Row(
          children: [
            Stack(
              children: [
                const CircleAvatar(radius: 18, backgroundColor: AppColors.backgroundCardLight, child: Icon(Icons.person, size: 18, color: AppColors.textHint)),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 10, height: 10,
                    decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Consumer<MessagesProvider>(
              builder: (ctx, mp, _) {
                final conv = mp.conversations.where((c) => c.user?['userId'] == widget.userId).firstOrNull;
                final userName = conv?.user?['displayName'] ?? 'المستخدم';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone, color: AppColors.success),
            onPressed: () {
              final mp = context.read<MessagesProvider>();
              final conv = mp.conversations.where((c) => c.user?['userId'] == widget.userId).firstOrNull;
              final userName = conv?.user?['displayName'] ?? 'مستخدم';
              Navigator.pushNamed(context, '/voice-room', arguments: {
                'server': 'https://meet.jit.si',
                'roomName': 'chat_${widget.userId}',
                'displayName': userName,
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam, color: AppColors.primary),
            onPressed: () {
              final mp = context.read<MessagesProvider>();
              final conv = mp.conversations.where((c) => c.user?['userId'] == widget.userId).firstOrNull;
              final userName = conv?.user?['displayName'] ?? 'مستخدم';
              Navigator.pushNamed(context, '/jitsi-room', arguments: {
                'server': 'https://meet.jit.si',
                'roomName': 'video_${widget.userId}',
                'displayName': userName,
              });
            },
          ),
        ],
      ),
      body: Consumer<MessagesProvider>(
        builder: (ctx, mp, _) {
          return Column(
            children: [
              Expanded(
                child: mp.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : mp.messages.isEmpty
                        ? const Center(
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.chat_bubble_outline, color: AppColors.textHint, size: 48),
                              SizedBox(height: 12),
                              Text('لا توجد رسائل بعد', style: TextStyle(color: AppColors.textHint, fontSize: 16)),
                              SizedBox(height: 4),
                              Text('ابدأ المحادثة الآن!', style: TextStyle(color: AppColors.textHint, fontSize: 12)),
                            ]),
                          )
                        : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: mp.messages.length,
                        itemBuilder: (context, index) {
                          final msg = mp.messages[index];
                          final isMe = msg.fromUserId != widget.userId;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isMe ? AppColors.primary.withValues(alpha: 0.2) : AppColors.backgroundCard,
                                    borderRadius: BorderRadius.circular(16).copyWith(
                                      bottomRight: isMe ? const Radius.circular(4) : Radius.circular(16),
                                      bottomLeft: !isMe ? const Radius.circular(4) : Radius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    msg.content ?? '',
                                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                if (msg.createdAt != null)
                                  Text(
                                    _formatTime(msg.createdAt!),
                                    style: const TextStyle(color: AppColors.textHint, fontSize: 10),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'اكتب رسالة...',
                          hintStyle: const TextStyle(color: AppColors.textHint),
                          filled: true,
                          fillColor: AppColors.backgroundDark,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        style: const TextStyle(color: AppColors.textPrimary),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
