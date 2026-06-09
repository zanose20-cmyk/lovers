import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _enabled = true;

  bool get enabled => _enabled;

  void setEnabled(bool value) => _enabled = value;

  Future<void> playGiftSound(String giftKey) async {
    if (!_enabled) return;
    try {
      await _player.play(AssetSource('sounds/gift_$giftKey.mp3'));
    } catch (_) {
      // Fallback to default gift sound
      try {
        await _player.play(AssetSource('sounds/gift_default.mp3'));
      } catch (_) {}
    }
  }

  Future<void> playDefaultGiftSound() async {
    if (!_enabled) return;
    try {
      await _player.play(AssetSource('sounds/gift_default.mp3'));
    } catch (_) {}
  }

  Future<void> playJoinSound() async {
    if (!_enabled) return;
    try {
      await _player.play(AssetSource('sounds/join.mp3'));
    } catch (_) {}
  }

  Future<void> playNotificationSound() async {
    if (!_enabled) return;
    try {
      await _player.play(AssetSource('sounds/notification.mp3'));
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
