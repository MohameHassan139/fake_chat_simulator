// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

Future<String?> saveToGallery(Uint8List bytes, String fileName) async {
  try {
    _triggerDownload(bytes, fileName);
    return fileName;
  } catch (e) {
    debugPrint('Web save error: $e');
    return null;
  }
}

Future<void> shareImage(Uint8List bytes, String fileName) async {
  _triggerDownload(bytes, fileName);
}

void _triggerDownload(Uint8List bytes, String fileName) {
  final blob = html.Blob([bytes], 'image/png');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}
