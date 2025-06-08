import 'package:flutter/material.dart';

/// Extension for adding glassmorphism effects to BoxDecoration
extension GlassmorphismBoxDecorationExtension on BoxDecoration {
  /// Adds glassmorphism effect to a BoxDecoration
  ///
  /// Parameters:
  /// - [blur]: The blur amount (default: 5.0)
  /// - [opacity]: The opacity of the glass effect (default: 0.1)
  /// - [borderRadius]: Border radius to use for clipping (default: uses the decoration's borderRadius)
  /// - [addGoldAccent]: Whether to add a gold accent shadow (default: false)
  BoxDecoration addGlassmorphism({
    double blur = 5.0,
    double opacity = 0.1,
    double? borderRadius,
    bool addGoldAccent = false,
  }) {
    // Create a new decoration that includes the glass effect properties
    return BoxDecoration(
      color: color,
      borderRadius: this.borderRadius,
      border: border ?? Border.all(color: Colors.white.withOpacity(0.1)),
      gradient: gradient ??
          LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.05),
              Colors.black.withOpacity(opacity + 0.2),
            ],
          ),
      boxShadow: addGoldAccent
          ? [
              BoxShadow(
                color: Colors.amber.withOpacity(0.2),
                blurRadius: blur * 2,
                spreadRadius: 1,
              ),
              ...?boxShadow,
            ]
          : boxShadow,
      image: image,
      backgroundBlendMode: backgroundBlendMode,
    );
  }
}
