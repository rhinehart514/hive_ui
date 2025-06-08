import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// An animated HIVE logo with a subtle gold particle field effect.
class AnimatedHiveLogo extends StatefulWidget {
  final double size;

  const AnimatedHiveLogo({super.key, this.size = 80.0});

  @override
  State<AnimatedHiveLogo> createState() => _AnimatedHiveLogoState();
}

class _AnimatedHiveLogoState extends State<AnimatedHiveLogo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(); // Loop the particle animation
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Animate(
      effects: const [FadeEffect(duration: Duration(milliseconds: 800), curve: Curves.easeIn)],
      child: Hero(
        tag: 'auth_logo', // Ensure consistent tag
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Particle field background
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  size: Size.square(widget.size * 1.5), // Slightly larger canvas for particles
                  painter: _GoldParticlePainter(
                    progress: _controller.value,
                    baseColor: AppColors.gold,
                  ),
                );
              },
            ),
            // The actual logo image
            Image.asset(
              'assets/images/hivelogo.png', // Ensure correct path
              width: widget.size,
              height: widget.size,
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for the gold particle field.
class _GoldParticlePainter extends CustomPainter {
  final double progress; // Animation progress (0.0 to 1.0)
  final Color baseColor;
  final int particleCount;
  final math.Random random;

  _GoldParticlePainter({
    required this.progress,
    required this.baseColor,
    this.particleCount = 12, // Default particle count
  }) : random = math.Random(1); // Seeded random for consistency

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < particleCount; i++) {
      // Use seeded random for consistent particle positions
      final initialAngle = random.nextDouble() * 2 * math.pi;
      final initialRadius = random.nextDouble() * maxRadius * 0.8 + maxRadius * 0.2;
      
      // Animate radius and opacity based on progress
      final currentRadius = initialRadius * (1 + math.sin(progress * 2 * math.pi + initialAngle) * 0.1);
      final opacity = (0.5 + math.cos(progress * 2 * math.pi * 2 + initialAngle) * 0.5).clamp(0.1, 0.6);
      final particleSize = (1 + random.nextDouble() * 1.5).clamp(1.0, 2.5);

      final paint = Paint()
        ..color = baseColor.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      final offset = Offset(
        center.dx + currentRadius * math.cos(initialAngle),
        center.dy + currentRadius * math.sin(initialAngle),
      );

      canvas.drawCircle(offset, particleSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GoldParticlePainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
} 