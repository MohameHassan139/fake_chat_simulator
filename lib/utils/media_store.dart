import 'dart:typed_data';

import 'media_store_stub.dart' if (dart.library.io) 'media_store_io.dart' as impl;

/// Keeps pictures, videos and voice notes out of the Hive database: a saved
/// chat holds a small {'file': name} reference instead of megabytes of bytes.
/// Every edit re-saves the whole chat, so bytes in Hive made each save copy
/// all the media again and made the app slow to open on cheap phones (ANRs).
/// On the web the bytes stay inline, as before.
class MediaStore {
  /// Call once before the chats load.
  static Future<void> init() => impl.init();

  /// What goes into the saved map for [bytes].
  static Object? ref(Uint8List? bytes) => bytes == null ? null : impl.ref(bytes);

  /// The bytes back from a saved value: a file reference, or the old inline bytes.
  static Uint8List? load(dynamic val) {
    if (val == null) return null;
    if (val is Uint8List) return val;
    if (val is Map && val['file'] is String) return impl.read(val['file'] as String);
    if (val is List) return Uint8List.fromList(List<int>.from(val));
    return null;
  }
}
