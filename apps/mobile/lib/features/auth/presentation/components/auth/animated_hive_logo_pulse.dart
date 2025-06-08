import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// An animated HIVE logo with a subtle gold pulse effect radiating outward.
class AnimatedHiveLogoPulse extends StatefulWidget {
  final double size;
  final Duration duration;

  const AnimatedHiveLogoPulse({super.key, this.size = 80.0, this.duration = const Duration(milliseconds: 1500)});

  @override
  State<AnimatedHiveLogoPulse> createState() => _AnimatedHiveLogoPulseState();
}

class _AnimatedHiveLogoPulseState extends State<AnimatedHiveLogoPulse> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    // Start the animation immediately
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Animate(
      controller: _controller,
      effects: [
        CustomEffect(
          duration: widget.duration,
          builder: (context, value, child) {
            final double radius = widget.size * 0.6 * value; // Pulse radius grows
            final double opacity = (1.0 - value).clamp(0.0, 0.5); // Pulse fades out
            return Stack(
              alignment: Alignment.center,
              children: [
                // Outward pulsing glow
                Container(
                  width: widget.size + radius * 2,
                  height: widget.size + radius * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withOpacity(opacity),
                        blurRadius: radius * 1.5,
                        spreadRadius: radius * 0.5,
                      ),
                    ],
                  ),
                ),
                // The logo itself
                child,
              ],
            );
          },
        )
      ],
      child: Hero(
        tag: 'auth_logo', // Keep tag consistent if used elsewhere
        child: Image.asset(
          'assets/images/hivelogo.png', // Ensure correct path
          width: widget.size,
          height: widget.size,
        ),
      ),
    );
  }
} 