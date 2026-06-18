import 'package:flutter/foundation.dart';

// Conditional imports: web gets the html implementation, others get the io one.
import 'screenshot_helper_stub.dart'
    if (dart.library.html) 'screenshot_helper_web.dart'
    if (dart.library.io) 'screenshot_helper_io.dart' as impl;

class ScreenshotHelper {
  ScreenshotHelper._();

  static Future<String?> saveToGallery(Uint8List imageBytes) async {
    try {
      return await impl.saveToGallery(imageBytes, _fileName());
    } catch (e) {
      debugPrint('Save error: $e');
      return null;
    }
  }

  static Future<void> shareImage(Uint8List imageBytes) async {
    try {
      await impl.shareImage(imageBytes, _fileName());
    } catch (e) {
      debugPrint('Share error: $e');
    }
  }

  static String _fileName() {
    final now = DateTime.now();
    return 'fakechat_'
        '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        '_${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}.png';
  }

  static Future<bool> startScreenRecord() async {
    try {
      return await impl.startScreenRecord();
    } catch (e) {
      debugPrint('Start record error: $e');
      return false;
    }
  }

  static void stopScreenRecord() {
    try {
      impl.stopScreenRecord();
    } catch (e) {
      debugPrint('Stop record error: $e');
    }
  }
}
