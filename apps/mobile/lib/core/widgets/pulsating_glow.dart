import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A widget that adds a subtle pulsating border effect around its child.
/// Designed for HIVE elements needing to indicate readiness or focus with a sleek look.
class PulsatingGlow extends StatelessWidget {
  /// The widget to apply the glow effect to.
  final Widget child;
  
  /// The color of the pulsating glow.
  final Color glowColor;
  
  /// Whether the pulsation is currently active.
  final bool isActive;
  
  /// The maximum blur radius of the glow.
  @Deprecated('No longer used, effect is border-based') 
  final double maxBlurRadius; // Kept for parameter compatibility if needed
  
  /// The duration of one pulse cycle.
  final Duration duration;

  const PulsatingGlow({
    super.key,
    required this.child,
    required this.glowColor,
    this.isActive = false,
    this.maxBlurRadius = 12.0, // Default value, but unused
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  Widget build(BuildContext context) {
    // If not active, just return the child without any effects.
    if (!isActive) {
      return child;
    }

    return Animate(
      key: ValueKey(isActive), // Keep key to trigger rebuild on isActive change
      effects: [
              CustomEffect(
                  duration: duration,
                  builder: (context, value, child) {
            // Animate border opacity for a sleek pulse
            // Use a curve that fades in/out smoothly, peaking in the middle
            final double opacityValue = (1 - (value - 0.5).abs() * 2);
            final double currentOpacity = opacityValue * 0.8; // Max opacity 80%

            // Animate border width slightly (optional, can be removed if too much)
            // final double currentWidth = 1.0 + (value * 1.0); // Animates width from 1.0 to 2.0
            const double currentWidth = 1.5; // Keep a fixed width for simplicity

                    return Container(
                      decoration: BoxDecoration(
                // Apply pulsating border
                border: Border.all(
                  color: glowColor.withOpacity(currentOpacity.clamp(0.0, 1.0)),
                  width: currentWidth,
                ),
                // Assuming the child might have its own shape, 
                // we might need to clip or match the border radius.
                // For simplicity now, let's assume a circular shape for test.
                shape: BoxShape.circle, // Example: If child is always circular
                // borderRadius: BorderRadius.circular(12), // Example: Match radius
                      ),
                      child: child, // The original child widget
                    );
                  },
                ),
      ],
      onComplete: (controller) {
        // Loop the animation ONLY if the widget is still active
        // No need for mounted check in StatelessWidget
        // We rely on the Animate widget being rebuilt/disposed if isActive changes
        if (isActive) {
           controller.forward(from: 0);
        }
      },
      child: child, // Pass the child to the Animate widget
    );
  }
} 