import 'package:flutter/material.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A pulsing animation for the verified plus badge
class PulsingVerifiedBadge extends StatefulWidget {
  /// Optional callback for when the badge is tapped
  final VoidCallback? onTap;

  const PulsingVerifiedBadge({
    super.key,
    this.onTap,
  });

  @override
  State<PulsingVerifiedBadge> createState() => _PulsingVerifiedBadgeState();
}

class _PulsingVerifiedBadgeState extends State<PulsingVerifiedBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Configure the animation controller for continuous pulsing
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Create a pulse animation that goes from 1.0 to 1.2 and back
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Set the animation to repeat in both directions
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: const Icon(
              Icons.verified,
              size: 18,
              color: AppColors.gold,
            ),
          );
        },
      ),
    );
  }
}
