import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hive_ui/constants/app_colors.dart'; // Assuming AppColors exist

/// A loading indicator featuring a pulsating hexagonal ripple effect.
/// Adheres to HIVE brand aesthetic with gold accent on dark background.
class HexagonalRippleLoader extends StatefulWidget {
  const HexagonalRippleLoader({super.key});

  @override
  State<HexagonalRippleLoader> createState() => _HexagonalRippleLoaderState();
}

class _HexagonalRippleLoaderState extends State<HexagonalRippleLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _radiusAnimation;
  late Animation<double> _opacityAnimation;

  // Standard HIVE animation duration
  static const Duration _animationDuration = Duration(milliseconds: 1500); 

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _animationDuration,
    )..repeat(); // Loop the animation

    // Ripple expands outwards
    _radiusAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        // Start slow, accelerate, then slow down - creates a ripple pulse
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOutSine), 
      ),
    );

    // Ripple fades out as it expands
    _opacityAnimation = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        // Fade starts slightly after expansion begins and completes before the end
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut), 
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Centered full-screen overlay behavior
    return Semantics(
      label: "Loading feed", // Accessibility
      child: Container(
        color: AppColors.backgroundColor.withOpacity(0.85), // Use correct dark background color
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(100, 100), // Base size of the painter area
                painter: _HexagonRipplePainter(
                  progress: _radiusAnimation.value,
                  opacity: _opacityAnimation.value,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HexagonRipplePainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final double opacity;   // 0.0 to 1.0 (or higher if needed by animation)

  _HexagonRipplePainter({required this.progress, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return; // Don't paint if invisible

    final Paint paint = Paint()
      ..color = AppColors.primaryColor.withOpacity(math.max(0, opacity)) // Use correct gold accent color
      ..style = PaintingStyle.stroke
      // Stroke width decreases as the ripple expands
      ..strokeWidth = math.max(0.5, 2.0 * (1.0 - progress)); 

    final double maxRadius = size.width / 2 * 0.8; // Ripple expands to 80% of the available size
    final double currentRadius = maxRadius * progress;
    final Path hexagonPath = _createHexagonPath(size.center(Offset.zero), currentRadius);

    canvas.drawPath(hexagonPath, paint);
  }

  Path _createHexagonPath(Offset center, double radius) {
    final Path path = Path();
    const int sides = 6;
    const double angle = (math.pi * 2) / sides;

    // Start angle adjustment to make the hexagon point upwards
    const double startAngle = -math.pi / 2; 

    Offset startPoint = Offset(
      center.dx + radius * math.cos(startAngle),
      center.dy + radius * math.sin(startAngle),
    );
    path.moveTo(startPoint.dx, startPoint.dy);

    for (int i = 1; i <= sides; i++) {
      double currentAngle = startAngle + i * angle;
      Offset nextPoint = Offset(
        center.dx + radius * math.cos(currentAngle),
        center.dy + radius * math.sin(currentAngle),
      );
      path.lineTo(nextPoint.dx, nextPoint.dy);
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _HexagonRipplePainter oldDelegate) {
    // Repaint only if progress or opacity changes
    return oldDelegate.progress != progress || oldDelegate.opacity != opacity;
  }
} 