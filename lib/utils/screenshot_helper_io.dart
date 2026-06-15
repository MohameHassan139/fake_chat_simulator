import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';

Future<String?> saveToGallery(Uint8List bytes, String fileName) async {
  try {
    if (Platform.isAndroid || Platform.isIOS) {
      if (Platform.isIOS) {
        await Permission.photos.request();
      } else if (Platform.isAndroid) {
        await Permission.storage.request();
      }

      final result = await ImageGallerySaverPlus.saveImage(
        bytes,
        name: fileName.replaceAll('.png', ''),
      );
      if (result != null && (result['isSuccess'] == true || result['isSuccess'] == 'true')) {
        final path = result['filePath'];
        return path is String ? path : 'Gallery';
      }
      return null;
    } else {
      final dir = await _outputDir();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      debugPrint('Screenshot saved: ${file.path}');
      return file.path;
    }
  } catch (e) {
    debugPrint('Save error: $e');
    return null;
  }
}

Future<void> shareImage(Uint8List bytes, String fileName) async {
  try {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'image/png')],
      text: 'Created with FakeChatStudio',
    );
  } catch (e) {
    debugPrint('Share error: $e');
  }
}

Future<Directory> _outputDir() async {
  if (Platform.isAndroid) {
    try {
      final dir = Directory('/storage/emulated/0/Pictures/FakeChatStudio');
      if (!await dir.exists()) await dir.create(recursive: true);
      return dir;
    } catch (_) {}
  }
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    try {
      final dir = await getDownloadsDirectory();
      if (dir != null) {
        final subDir = Directory('${dir.path}/FakeChatStudio');
        if (!await subDir.exists()) await subDir.create(recursive: true);
        return subDir;
      }
    } catch (_) {}
  }
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory('${docs.path}/FakeChatStudio');
  if (!await dir.exists()) await dir.create(recursive: true);
  return dir;
}
