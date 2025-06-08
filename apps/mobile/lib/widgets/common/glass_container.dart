import 'package:flutter/material.dart';
import 'dart:ui';

/// A reusable glassmorphism container that creates a frosted glass effect
/// following the HIVE brand aesthetic guidelines.
class GlassContainer extends StatelessWidget {
  /// Child widget to display inside the glass container
  final Widget child;

  /// Blur intensity of the glass effect (5-15 recommended)
  final double blur;

  /// Background opacity (0.0-1.0)
  final double opacity;

  /// Border radius of the container (defaults to 16)
  final double borderRadius;

  /// Whether to add a subtle border to the container
  final bool withBorder;

  /// Whether to add a subtle shadow
  final bool withShadow;

  /// Optional color tint (defaults to black with opacity)
  final Color? tintColor;

  /// The GlassContainer constructor
  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 10,
    this.opacity = 0.2,
    this.borderRadius = 16,
    this.withBorder = true,
    this.withShadow = false,
    this.tintColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: withShadow
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: -10,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              color: tintColor ?? Colors.black.withOpacity(opacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: withBorder
                  ? Border.all(
                      color: Colors.white.withOpacity(0.15),
                      width: 0.5,
                    )
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
} 