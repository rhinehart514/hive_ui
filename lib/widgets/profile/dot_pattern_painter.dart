import 'package:flutter/material.dart';
import 'dart:ui';

/// A custom painter that draws a pattern of dots on the canvas.
/// Used for creating subtle background patterns.
class DotPatternPainter extends CustomPainter {
  final Color color;
  final double spacingX;
  final double spacingY;
  final double dotSize;

  const DotPatternPainter({
    required this.color,
    required this.spacingX,
    required this.spacingY,
    required this.dotSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = dotSize;

    for (double x = 0; x < size.width; x += spacingX) {
      for (double y = 0; y < size.height; y += spacingY) {
        canvas.drawPoints(
          PointMode.points,
          [Offset(x, y)],
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(DotPatternPainter oldDelegate) =>
      color != oldDelegate.color ||
      spacingX != oldDelegate.spacingX ||
      spacingY != oldDelegate.spacingY ||
      dotSize != oldDelegate.dotSize;
}
