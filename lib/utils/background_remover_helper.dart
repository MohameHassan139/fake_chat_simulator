import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_background_remover/image_background_remover.dart';

class BackgroundRemoverHelper {
  static bool _ortInitialized = false;

  /// Attempts AI-based background removal using ONNX model from `image_background_remover`.
  /// Returns PNG bytes of the foreground, or null if failed / unsupported.
  static Future<Uint8List?> removeBackgroundAI(Uint8List inputBytes) async {
    try {
      if (!_ortInitialized) {
        BackgroundRemover.instance.initializeOrt();
        _ortInitialized = true;
      }
      final ui.Image resultImage = await BackgroundRemover.instance.removeBg(inputBytes);
      final byteData = await resultImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;
      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('AI background removal unavailable or failed: $e');
      return null;
    }
  }

  /// Removes background using boundary-connected flood fill (BFS starting from image edges).
  /// This ensures that matching background colors isolated inside subject details (like eyes, teeth, clothes)
  /// are NOT removed.
  static Uint8List removeBackgroundSmartFloodFill({
    required Uint8List inputBytes,
    Color? targetColor,
    double tolerance = 30.0,
  }) {
    final decoded = img.decodeImage(inputBytes);
    if (decoded == null) return inputBytes;

    final src = decoded.numChannels == 4 ? decoded : decoded.convert(numChannels: 4);
    final width = src.width;
    final height = src.height;

    final int targetR;
    final int targetG;
    final int targetB;

    if (targetColor != null) {
      targetR = targetColor.red;
      targetG = targetColor.green;
      targetB = targetColor.blue;
    } else {
      // Sample average corner colors
      final corners = [
        src.getPixel(0, 0),
        src.getPixel(width - 1, 0),
        src.getPixel(0, height - 1),
        src.getPixel(width - 1, height - 1),
      ];
      int sumR = 0, sumG = 0, sumB = 0;
      for (final c in corners) {
        sumR += c.r.toInt();
        sumG += c.g.toInt();
        sumB += c.b.toInt();
      }
      targetR = sumR ~/ corners.length;
      targetG = sumG ~/ corners.length;
      targetB = sumB ~/ corners.length;
    }

    final maxDist = sqrt(255 * 255 * 3);
    final allowedDist = (tolerance / 100.0) * maxDist;

    final visited = List<bool>.filled(width * height, false);
    final queue = Queue<int>();

    void tryEnqueue(int x, int y) {
      if (x < 0 || x >= width || y < 0 || y >= height) return;
      final idx = y * width + x;
      if (visited[idx]) return;

      final pixel = src.getPixel(x, y);
      final pr = pixel.r.toInt();
      final pg = pixel.g.toInt();
      final pb = pixel.b.toInt();

      final dist = sqrt(
        (pr - targetR) * (pr - targetR) +
        (pg - targetG) * (pg - targetG) +
        (pb - targetB) * (pb - targetB),
      );

      if (dist <= allowedDist) {
        visited[idx] = true;
        pixel.a = 0;
        queue.add(idx);
      }
    }

    // Enqueue all 4 border edges
    for (int x = 0; x < width; x++) {
      tryEnqueue(x, 0);
      tryEnqueue(x, height - 1);
    }
    for (int y = 0; y < height; y++) {
      tryEnqueue(0, y);
      tryEnqueue(width - 1, y);
    }

    // BFS Expansion
    while (queue.isNotEmpty) {
      final currIdx = queue.removeFirst();
      final cx = currIdx % width;
      final cy = currIdx ~/ width;

      tryEnqueue(cx + 1, cy);
      tryEnqueue(cx - 1, cy);
      tryEnqueue(cx, cy + 1);
      tryEnqueue(cx, cy - 1);
    }

    // Apply edge anti-aliasing / soft feathering
    _applyFeathering(src, visited, width, height);

    return Uint8List.fromList(img.encodePng(src));
  }

  /// Removes background by matching target color across all pixels (Chroma key mode).
  static Uint8List removeBackgroundGlobalColor({
    required Uint8List inputBytes,
    required Color targetColor,
    double tolerance = 30.0,
  }) {
    final decoded = img.decodeImage(inputBytes);
    if (decoded == null) return inputBytes;

    final src = decoded.numChannels == 4 ? decoded : decoded.convert(numChannels: 4);
    final width = src.width;
    final height = src.height;

    final targetR = targetColor.red;
    final targetG = targetColor.green;
    final targetB = targetColor.blue;

    final maxDist = sqrt(255 * 255 * 3);
    final allowedDist = (tolerance / 100.0) * maxDist;
    final visited = List<bool>.filled(width * height, false);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = src.getPixel(x, y);
        final pr = pixel.r.toInt();
        final pg = pixel.g.toInt();
        final pb = pixel.b.toInt();

        final dist = sqrt(
          (pr - targetR) * (pr - targetR) +
          (pg - targetG) * (pg - targetG) +
          (pb - targetB) * (pb - targetB),
        );

        if (dist <= allowedDist) {
          final idx = y * width + x;
          visited[idx] = true;
          pixel.a = 0;
        }
      }
    }

    _applyFeathering(src, visited, width, height);

    return Uint8List.fromList(img.encodePng(src));
  }

  /// Automatically sample corner colors of an image to suggest background key color
  static Color autoDetectCornerColor(Uint8List inputBytes) {
    final decoded = img.decodeImage(inputBytes);
    if (decoded == null) return Colors.white;

    final pixel = decoded.getPixel(0, 0);
    return Color.fromARGB(
      255,
      pixel.r.toInt(),
      pixel.g.toInt(),
      pixel.b.toInt(),
    );
  }

  static void _applyFeathering(img.Image src, List<bool> erasedMask, int width, int height) {
    // Soften 1-px border around erased pixels for smooth anti-aliased sticker edges
    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        final idx = y * width + x;
        if (erasedMask[idx]) continue;

        // Count adjacent erased neighbors
        int erasedNeighbors = 0;
        if (erasedMask[idx - 1]) erasedNeighbors++;
        if (erasedMask[idx + 1]) erasedNeighbors++;
        if (erasedMask[idx - width]) erasedNeighbors++;
        if (erasedMask[idx + width]) erasedNeighbors++;

        if (erasedNeighbors > 0) {
          final pixel = src.getPixel(x, y);
          final currentAlpha = pixel.a.toInt();
          final newAlpha = (currentAlpha * (1.0 - (erasedNeighbors * 0.18))).clamp(50, 255).toInt();
          pixel.a = newAlpha;
        }
      }
    }
  }
}
