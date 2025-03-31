import 'package:flutter/material.dart';
import 'dart:math' as math;

class HiveProgressIndicator extends StatelessWidget {
  final double progress;
  final double size;
  final Color? color;
  final Widget? child;

  const HiveProgressIndicator({
    super.key,
    required this.progress,
    this.size = 120,
    this.color,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _HiveProgressPainter(
          progress: progress,
          color: color ?? const Color(0xFFEEBA2A),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _HiveProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  _HiveProgressPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    // Draw background track
    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      2 * math.pi,
      false,
      trackPaint,
    );

    // Draw progress with gradient
    final progressPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          color.withOpacity(0.5),
          color,
        ],
        stops: const [0.0, 1.0],
        startAngle: startAngle,
        endAngle: startAngle + (2 * math.pi),
        transform: const GradientRotation(startAngle),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );

    // Draw hexagonal points
    const pointCount = 6;
    const angleStep = 2 * math.pi / pointCount;
    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (var i = 0; i < pointCount; i++) {
      final angle = startAngle + (i * angleStep);
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      if (i * angleStep <= sweepAngle) {
        canvas.drawCircle(point, 4, pointPaint);
      } else {
        canvas.drawCircle(
          point,
          4,
          Paint()..color = Colors.white.withOpacity(0.2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_HiveProgressPainter oldDelegate) =>
      progress != oldDelegate.progress || color != oldDelegate.color;
}
