import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Painter for checkered background pattern (Photoshop-style)
class CheckeredBackgroundPainter extends CustomPainter {
  final Color color1;
  final Color color2;
  final double squareSize;

  ui.Image? _patternImage;

  CheckeredBackgroundPainter({
    required this.color1,
    required this.color2,
    this.squareSize = 10.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw checkered pattern using individual rectangles
    // This is simpler and works well for reasonable square sizes

    final paint1 = Paint()..color = color1;
    final paint2 = Paint()..color = color2;

    final numColumns = (size.width / squareSize).ceil();
    final numRows = (size.height / squareSize).ceil();

    for (int row = 0; row < numRows; row++) {
      for (int col = 0; col < numColumns; col++) {
        final isEvenRow = row % 2 == 0;
        final isEvenCol = col % 2 == 0;

        // Alternate colors in checkerboard pattern
        final paint = (isEvenRow == isEvenCol) ? paint1 : paint2;

        final rect = Rect.fromLTWH(
          col * squareSize,
          row * squareSize,
          squareSize,
          squareSize,
        );

        canvas.drawRect(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CheckeredBackgroundPainter oldDelegate) {
    return color1 != oldDelegate.color1 ||
        color2 != oldDelegate.color2 ||
        squareSize != oldDelegate.squareSize;
  }
}

/// Optimized version using shader (for large canvases)
class CheckeredBackgroundPainterOptimized extends CustomPainter {
  final Color color1;
  final Color color2;
  final double squareSize;

  static ui.Image? _cachedPattern;
  static Color? _cachedColor1;
  static Color? _cachedColor2;
  static double? _cachedSize;

  CheckeredBackgroundPainterOptimized({
    required this.color1,
    required this.color2,
    this.squareSize = 10.0,
  });

  Future<ui.Image> _generatePattern() async {
    // Check cache
    if (_cachedPattern != null &&
        _cachedColor1 == color1 &&
        _cachedColor2 == color2 &&
        _cachedSize == squareSize) {
      return _cachedPattern!;
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint1 = Paint()..color = color1;
    final paint2 = Paint()..color = color2;

    final patternSize = squareSize * 2;

    // Create 2x2 square pattern
    canvas.drawRect(
      Rect.fromLTWH(0, 0, squareSize, squareSize),
      paint1,
    );
    canvas.drawRect(
      Rect.fromLTWH(squareSize, 0, squareSize, squareSize),
      paint2,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, squareSize, squareSize, squareSize),
      paint2,
    );
    canvas.drawRect(
      Rect.fromLTWH(squareSize, squareSize, squareSize, squareSize),
      paint1,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      patternSize.toInt(),
      patternSize.toInt(),
    );

    // Cache it
    _cachedPattern = image;
    _cachedColor1 = color1;
    _cachedColor2 = color2;
    _cachedSize = squareSize;

    return image;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // For now, use the simple version
    // The shader version would be implemented here with the generated pattern
    final paint1 = Paint()..color = color1;
    final paint2 = Paint()..color = color2;

    final numColumns = (size.width / squareSize).ceil();
    final numRows = (size.height / squareSize).ceil();

    for (int row = 0; row < numRows; row++) {
      for (int col = 0; col < numColumns; col++) {
        final isEvenRow = row % 2 == 0;
        final isEvenCol = col % 2 == 0;
        final paint = (isEvenRow == isEvenCol) ? paint1 : paint2;

        final rect = Rect.fromLTWH(
          col * squareSize,
          row * squareSize,
          squareSize,
          squareSize,
        );

        canvas.drawRect(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CheckeredBackgroundPainterOptimized oldDelegate) {
    return color1 != oldDelegate.color1 ||
        color2 != oldDelegate.color2 ||
        squareSize != oldDelegate.squareSize;
  }
}