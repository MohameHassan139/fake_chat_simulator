// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

Future<Uint8List?> readAudioBytes(String path) async {
  final response = await html.window.fetch(path);
  final blob = await response.blob();
  final reader = html.FileReader();
  reader.readAsArrayBuffer(blob);
  await reader.onLoadEnd.first;
  return reader.result as Uint8List?;
}

Future<String?> prepareAudioSource(Uint8List bytes) async {
  final blob = html.Blob([bytes], 'audio/aac');
  return html.Url.createObjectUrlFromBlob(blob);
}
