import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class BackgroundRemoverHelper {
  /// Removes background from [inputBytes] matching either [targetColor] or corner auto-detected color.
  /// [tolerance] ranges from 0.0 to 100.0.
  static Uint8List removeBackground({
    required Uint8List inputBytes,
    Color? targetColor,
    double tolerance = 30.0,
  }) {
    final decoded = img.decodeImage(inputBytes);
    if (decoded == null) return inputBytes;

    // Convert to RGBA if needed
    final src = decoded.numChannels == 4 ? decoded : decoded.convert(numChannels: 4);

    final int targetR;
    final int targetG;
    final int targetB;

    if (targetColor != null) {
      targetR = targetColor.red;
      targetG = targetColor.green;
      targetB = targetColor.blue;
    } else {
      // Auto detect background color from corners
      final cornerColors = [
        src.getPixel(0, 0),
        src.getPixel(src.width - 1, 0),
        src.getPixel(0, src.height - 1),
        src.getPixel(src.width - 1, src.height - 1),
      ];

      // Use top-left corner color as default primary background color
      final primaryCorner = cornerColors[0];
      targetR = primaryCorner.r.toInt();
      targetG = primaryCorner.g.toInt();
      targetB = primaryCorner.b.toInt();
    }

    // Maximum distance in 3D RGB color space is sqrt(255^2 * 3) ~ 441.67
    final maxDist = sqrt(255 * 255 * 3);
    final allowedDist = (tolerance / 100.0) * maxDist;

    for (int y = 0; y < src.height; y++) {
      for (int x = 0; x < src.width; x++) {
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
          // Set alpha to transparent
          pixel.a = 0;
        }
      }
    }

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
}
