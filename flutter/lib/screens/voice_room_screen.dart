import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../config/app_config.dart';
import '../services/socket_service.dart';

class VoiceRoomScreen extends StatefulWidget {
  final String server;
  final String roomName;
  final String displayName;
  final String? email;
  final String? jwtToken;

  VoiceRoomScreen({
    required this.server,
    required this.roomName,
    this.displayName = 'مستخدم',
    this.email,
    this.jwtToken,
  });

  @override
  State<VoiceRoomScreen> createState() => _VoiceRoomScreenState();
}

class _VoiceRoomScreenState extends State<VoiceRoomScreen> {
  final SocketService _socketService = SocketService();
  Map? _currentGift;
  bool _showGiftOverlay = false;
  bool _showControls = true;
  late final WebViewController _controller;
  bool _isLoading = true;
  int _callSeconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initWebView();
    _connectSocket();
  }

  void _initWebView() {
    final room = Uri.encodeComponent(widget.roomName.replaceAll(RegExp(r'[^a-zA-Z0-9-\s]'), ''));
    final server = widget.server.replaceAll(RegExp(r'/$'), '');

    final config = <String, String>{
      'config.disableInviteFunctions': 'true',
      'config.enableWelcomePage': 'false',
      'config.prejoinPageEnabled': 'false',
      'config.toolbarButtons': r'["microphone","raisehand"]',
      'userInfo.displayName': widget.displayName,
    };

    String url;
    if (widget.jwtToken != null) {
      url = '$server/$room?jwt=${widget.jwtToken}#${config.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';
    } else {
      url = '$server/$room#${config.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          if (mounted) setState(() => _isLoading = true);
        },
        onPageFinished: (_) {
          if (mounted) {
            setState(() => _isLoading = false);
            _timer = Timer.periodic(const Duration(seconds: 1), (_) {
              if (mounted) setState(() => _callSeconds++);
            });
          }
        },
        onWebResourceError: (err) {
          if (mounted) {
            _timer?.cancel();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('خطأ في الاتصال: ${err.description}')),
            );
          }
        },
      ))
      ..loadRequest(Uri.parse(url));
  }

  void _connectSocket() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('server_token');
      if (token != null) {
        _socketService.connect(AppConfig.serverUrl, token);
        _socketService.on('gift.sent', _onGiftReceived);
        _socketService.on('roomGift', _onGiftReceived);
        _socketService.on('call.ended', (_) { if (mounted) Navigator.pop(context); });
      }
    } catch (e) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    try { _socketService.dispose(); } catch (e) {}
    super.dispose();
  }

  String get _formattedTime {
    final h = _callSeconds ~/ 3600;
    final m = (_callSeconds % 3600) ~/ 60;
    final s = _callSeconds % 60;
    if (h > 0) return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
          GestureDetector(
            onTap: () => setState(() => _showControls = !_showControls),
            child: AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.call_end, color: Colors.red, size: 32),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54, borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.mic, color: Colors.white, size: 14),
                              const SizedBox(width: 6),
                              Text(_formattedTime, style: const TextStyle(color: Colors.white, fontSize: 16)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_showGiftOverlay && _currentGift != null)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.8),
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(seconds: 1),
                    builder: (ctx, value, child) => Opacity(
                      opacity: value,
                      child: Transform.scale(scale: value, child: child),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_currentGift!['senderName'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 16)),
                        const SizedBox(height: 8),
                        Icon(_giftIcon(_currentGift!['gift'] ?? ''), color: Colors.amber, size: 80),
                        const SizedBox(height: 8),
                        Text(_currentGift!['gift'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _onGiftReceived(dynamic payload) {
    if (!mounted) return;
    try {
      setState(() {
        _currentGift = Map.from(payload as Map);
        _showGiftOverlay = true;
      });
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) setState(() { _showGiftOverlay = false; _currentGift = null; });
      });
    } catch (e) {}
  }

  IconData _giftIcon(String name) {
    switch (name.toLowerCase()) {
      case 'rose': case 'roses': return Icons.local_florist;
      case 'diamond': case 'diamonds': return Icons.diamond;
      case 'heart': case 'hearts': return Icons.favorite;
      case 'crown': return Icons.workspace_premium;
      default: return Icons.card_giftcard;
    }
  }
}