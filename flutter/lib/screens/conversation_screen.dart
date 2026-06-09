import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../providers/messages_provider.dart';
import '../providers/api_provider.dart';
import '../widgets/report_dialog.dart';

class ConversationScreen extends StatefulWidget {
  final String userId;
  const ConversationScreen({super.key, required this.userId});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessagesProvider>().setCurrentChatUser(widget.userId);
      context.read<MessagesProvider>().loadMessages(widget.userId);
    });
  }

  @override
  void dispose() {
    context.read<MessagesProvider>().setCurrentChatUser(null);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;
    try {
      final api = context.read<ApiProvider>().api;
      final bytes = await file.readAsBytes();
      final resp = await api.uploadFile(bytes, file.name, 'chat');
      if (resp['url'] != null) {
        await context.read<MessagesProvider>().sendMessage(widget.userId, resp['url'], type: 'image');
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل إرسال الصورة')));
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (mounted) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
        }
      });
    }
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
        if (mounted && _scrollController.hasClients) {
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textHint),
            onSelected: (v) {
              if (v == 'report') ReportDialog.show(context, targetType: 'user', targetId: widget.userId);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'report', child: Text('إبلاغ', style: TextStyle(color: Colors.orange))),
            ],
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
                                  child: msg.type == 'image'
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: CachedNetworkImage(
                                            imageUrl: msg.content ?? '',
                                            width: 200,
                                            fit: BoxFit.cover,
                                            placeholder: (_, __) => const SizedBox(width: 200, height: 150, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                                            errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: AppColors.textHint),
                                          ),
                                        )
                                      : Text(
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
                    IconButton(
                      icon: const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
                      onPressed: _sendImage,
                    ),
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
