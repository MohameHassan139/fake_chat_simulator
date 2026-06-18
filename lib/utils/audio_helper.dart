import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'audio_helper_stub.dart'
    if (dart.library.html) 'audio_helper_web.dart'
    if (dart.library.io) 'audio_helper_io.dart' as impl;

class AudioHelper {
  AudioHelper._();

  static Future<Uint8List?> readAudioBytes(String path) async {
    try {
      return await impl.readAudioBytes(path);
    } catch (e) {
      debugPrint('Read audio bytes error: $e');
      return null;
    }
  }

  static Future<String?> prepareAudioSource(Uint8List bytes) async {
    try {
      return await impl.prepareAudioSource(bytes);
    } catch (e) {
      debugPrint('Prepare audio source error: $e');
      return null;
    }
  }
}
