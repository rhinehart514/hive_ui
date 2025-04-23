import 'dart:ui';
import 'package:flutter/material.dart';

/// Extension on BoxDecoration to add glassmorphism effect
extension GlassmorphismExtension on BoxDecoration {
  /// Adds a glassmorphism effect to the BoxDecoration
  BoxDecoration addGlassEffect({double opacity = 0.2, double blur = 10.0}) {
    return BoxDecoration(
      color: Colors.white.withOpacity(opacity),
      borderRadius: borderRadius,
      border: border,
      boxShadow: boxShadow,
      gradient: gradient,
      image: image,
      backgroundBlendMode: BlendMode.luminosity,
    );
  }
}

/// A pre-built glass container widget
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double opacity;
  final double blur;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.opacity = 0.1,
    this.blur = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
