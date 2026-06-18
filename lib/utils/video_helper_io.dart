import 'dart:io' as io;
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

Future<String?> prepareVideoSource(Uint8List bytes) async {
  final tempDir = await getTemporaryDirectory();
  final tempFile = io.File('${tempDir.path}/temp_video_${DateTime.now().millisecondsSinceEpoch}.mp4');
  await tempFile.writeAsBytes(bytes);
  return tempFile.path;
}
