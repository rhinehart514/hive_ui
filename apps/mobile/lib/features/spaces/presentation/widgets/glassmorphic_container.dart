import 'dart:ui';
import 'package:flutter/material.dart';

/// A container with a glassmorphic effect
class GlassMorphicContainer extends StatelessWidget {
  /// Child widget
  final Widget child;
  
  /// Border radius
  final BorderRadius borderRadius;
  
  /// Blur amount
  final double blur;
  
  /// Opacity of the background
  final double opacity;
  
  /// Container border
  final Border? border;
  
  /// Container color
  final Color? color;
  
  /// Container gradient
  final Gradient? gradient;
  
  /// Constructor
  const GlassMorphicContainer({
    super.key,
    required this.child,
    required this.borderRadius,
    this.blur = 10,
    this.opacity = 0.2,
    this.border,
    this.color,
    this.gradient,
  });
  
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: color ?? Colors.white.withOpacity(opacity),
            borderRadius: borderRadius,
            border: border,
            gradient: gradient,
          ),
          child: child,
        ),
      ),
    );
  }
} 