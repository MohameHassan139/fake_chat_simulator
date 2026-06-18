// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter, uri_does_not_exist
import 'dart:js_util' as js_util;
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

html.MediaRecorder? _mediaRecorder;
List<html.Blob> _chunks = [];
html.MediaStream? _stream;

Future<bool> startScreenRecord() async {
  try {
    final mediaDevices = html.window.navigator.mediaDevices;
    if (mediaDevices == null) return false;

    // Ask browser for display media stream (tab/screen/window share)
    final promise = js_util.callMethod(
      mediaDevices,
      'getDisplayMedia',
      [
        js_util.jsify({'video': true, 'audio': false})
      ],
    );
    final displayMedia = await js_util.promiseToFuture(promise);
    _stream = displayMedia as html.MediaStream;
    _chunks = [];

    _mediaRecorder = html.MediaRecorder(_stream!, {'mimeType': 'video/webm;codecs=vp9'});
    _mediaRecorder!.addEventListener('dataavailable', (html.Event event) {
      final html.BlobEvent blobEvent = event as html.BlobEvent;
      final data = blobEvent.data;
      if (data != null) {
        _chunks.add(data);
      }
    });

    _mediaRecorder!.addEventListener('stop', (html.Event event) {
      if (_chunks.isNotEmpty) {
        final blob = html.Blob(_chunks, 'video/webm');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', 'fakechat_recording_${DateTime.now().millisecondsSinceEpoch}.webm')
          ..click();
        html.Url.revokeObjectUrl(url);
      }
    });

    _mediaRecorder!.start();
    return true;
  } catch (e) {
    debugPrint('Web screen record error: $e');
    return false;
  }
}

void stopScreenRecord() {
  try {
    _mediaRecorder?.stop();
    _stream?.getTracks().forEach((track) => track.stop());
  } catch (e) {
    debugPrint('Error stopping web recorder: $e');
  }
}
