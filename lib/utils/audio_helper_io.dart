import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

Future<Uint8List?> readAudioBytes(String path) async {
  final file = File(path);
  if (await file.exists()) {
    return await file.readAsBytes();
  }
  return null;
}

Future<String?> prepareAudioSource(Uint8List bytes) async {
  final tempDir = await getTemporaryDirectory();
  final tempFile = File('${tempDir.path}/temp_audio_${DateTime.now().millisecondsSinceEpoch}.m4a');
  await tempFile.writeAsBytes(bytes);
  return tempFile.path;
}
