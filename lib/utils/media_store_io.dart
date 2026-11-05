import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

Directory? _dir;
final Expando<String> _names = Expando<String>();   // bytes already on disk -> their file name

Future<void> init() async {
  try {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/chat_media');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    _dir = dir;
  } catch (e) {
    debugPrint('MediaStore: $e');
  }
}

Object? ref(Uint8List bytes) {
  final dir = _dir;
  if (dir == null) return bytes;                    // no folder: keep the old inline way
  final known = _names[bytes];
  if (known != null) return {'file': known};
  try {
    final name = const Uuid().v4();
    File('${dir.path}/$name').writeAsBytesSync(bytes, flush: false);
    _names[bytes] = name;
    return {'file': name};
  } catch (e) {
    debugPrint('MediaStore write: $e');
    return bytes;
  }
}

Uint8List? read(String name) {
  final dir = _dir;
  if (dir == null) return null;
  try {
    final bytes = File('${dir.path}/$name').readAsBytesSync();
    _names[bytes] = name;
    return bytes;
  } catch (e) {
    debugPrint('MediaStore read: $e');
    return null;
  }
}
