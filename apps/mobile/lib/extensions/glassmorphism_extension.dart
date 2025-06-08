import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:hive_ui/theme/glassmorphism_guide.dart';

/// Extension on [Widget] to add standardized glassmorphism effects
extension GlassmorphismExtension on Widget {
  /// Creates a standardized glassmorphism effect container around the child widget
  /// using the glassmorphism package
  ///
  /// Parameters:
  /// - [borderRadius]: The border radius of the container (default: 16)
  /// - [blur]: The blur sigma (default: 2.0)
  /// - [opacity]: The background opacity (default: 0.4)
  /// - [border]: Whether to add a border (default: true)
  /// - [padding]: Padding inside the container (default: null)
  /// - [margin]: Margin around the container (default: null)
  /// - [enableGradient]: Whether to add a subtle gradient effect (default: true)
  /// - [addGoldAccent]: Whether to add gold accent glow (default: false)
  Widget addGlassmorphism({
    double borderRadius = GlassmorphismGuide.kStandardRadius,
    double blur = GlassmorphismGuide.kStandardBlur,
    double opacity = GlassmorphismGuide.kStandardGlassOpacity,
    bool border = true,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    bool enableGradient = true,
    bool addGoldAccent = false,
  }) {
    // Ensure the widget has valid constraints by using Material widget as a wrapper
    final Widget safeChild = Material(
      type: MaterialType.transparency,
      child: padding != null ? Padding(padding: padding, child: this) : this,
    );

    // Create the glassmorphism effect
    Widget result = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border:
            border ? Border.all(color: Colors.white.withOpacity(0.1)) : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              gradient: enableGradient
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.grey[850]!.withOpacity(opacity + 0.2),
                      ],
                      stops: const [0.1, 1.0],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.grey[850]!.withOpacity(opacity + 0.1),
                        Colors.grey[900]!.withOpacity(opacity + 0.2),
                      ],
                    ),
            ),
            child: safeChild,
          ),
        ),
      ),
    );

    if (addGoldAccent) {
      result = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: GlassmorphismGuide.goldAccentShadows,
        ),
        child: result,
      );
    }

    if (margin != null) {
      result = Padding(
        padding: margin,
        child: result,
      );
    }

    // Wrap in a SizedBox with intrinsic size if no parent constraints
    return result;
  }

  /// Creates a modal-style glassmorphism effect for bottom sheets and dialogs
  /// using the glassmorphism package
  ///
  /// Parameters:
  /// - [borderRadius]: The border radius of the container (default: 20)
  /// - [blur]: The blur sigma (higher for modals) (default: 3.0)
  /// - [opacity]: The background opacity (default: 0.7)
  /// - [padding]: Padding inside the container (default: null)
  /// - [margin]: Margin around the container (default: null)
  /// - [addGoldAccent]: Whether to add gold accent glow (default: true)
  Widget addModalGlassmorphism({
    double borderRadius = GlassmorphismGuide.kModalRadius,
    double blur = GlassmorphismGuide.kModalBlur,
    double opacity = GlassmorphismGuide.kModalGlassOpacity,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    bool addGoldAccent = true,
  }) {
    // Ensure the widget has valid constraints by using Material widget as a wrapper
    final Widget safeChild = Material(
      type: MaterialType.transparency,
      child: padding != null ? Padding(padding: padding, child: this) : this,
    );

    // Create the glassmorphism effect
    Widget result = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.05),
                  Colors.black.withOpacity(opacity),
                ],
                stops: const [0.1, 1.0],
              ),
            ),
            child: safeChild,
          ),
        ),
      ),
    );

    if (addGoldAccent) {
      result = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: GlassmorphismGuide.goldAccentShadows,
        ),
        child: result,
      );
    }

    if (margin != null) {
      result = Padding(
        padding: margin,
        child: result,
      );
    }

    return result;
  }

  /// Creates a header-style glassmorphism effect for app bars and persistent headers
  /// using the glassmorphism package
  ///
  /// Parameters:
  /// - [blur]: The blur sigma (default: 2.5)
  /// - [opacity]: The background opacity (default: 0.5)
  Widget addHeaderGlassmorphism({
    double blur = GlassmorphismGuide.kHeaderBlur,
    double opacity = GlassmorphismGuide.kHeaderGlassOpacity,
    bool border = false,
    bool enableGradient = true,
  }) {
    // Ensure the widget has valid constraints by using Material widget as a wrapper
    final Widget safeChild = Material(
      type: MaterialType.transparency,
      child: this,
    );

    return Container(
      decoration: BoxDecoration(
        border:
            border ? Border.all(color: Colors.white.withOpacity(0.1)) : null,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            gradient: enableGradient
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.05),
                      Colors.black.withOpacity(opacity),
                    ],
                    stops: const [0.1, 1.0],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.black.withOpacity(opacity),
                      Colors.black.withOpacity(opacity),
                    ],
                  ),
          ),
          child: safeChild,
        ),
      ),
    );
  }
}
