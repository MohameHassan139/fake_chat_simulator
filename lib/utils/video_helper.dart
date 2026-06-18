import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'video_helper_stub.dart'
    if (dart.library.html) 'video_helper_web.dart'
    if (dart.library.io) 'video_helper_io.dart' as impl;

class VideoHelper {
  VideoHelper._();

  static Future<String?> prepareVideoSource(Uint8List bytes) async {
    try {
      return await impl.prepareVideoSource(bytes);
    } catch (e) {
      debugPrint('Prepare video source error: $e');
      return null;
    }
  }
}
