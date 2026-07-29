import 'dart:typed_data';
import '../models/chat_models.dart';

class SoundEffectHelper {
  static bool _isMuted = true;

  static bool get isMuted => _isMuted;
  static set isMuted(bool value) {
    _isMuted = value;
  }

  static Uint8List? get customSoundBytes => null;
  static String? get customSoundName => null;

  static void setCustomSound(Uint8List? bytes, String? name) {}
  static void clearCustomSound() {}

  /// No-op: all sounds are disabled
  static Future<void> playIncomingSound([Platform platform = Platform.whatsapp]) async {}

  /// No-op: all sounds are disabled
  static Future<void> playOutgoingSound([Platform platform = Platform.whatsapp]) async {}

  /// No-op: all sounds are disabled
  static Future<void> playAudioMessageBytes(Uint8List audioBytes) async {}

  static void dispose() {}
}
