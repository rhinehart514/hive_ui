import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'animation_constants.dart';

/// Utilities for creating glassmorphism effects in the UI
class GlassmorphismUtils {
  /// Standard blur amount for glass effects
  static const double standardBlur = 10.0;
  
  /// Lighter blur for subtle effects
  static const double subtleBlur = 5.0;
  
  /// Stronger blur for more pronounced effects
  static const double strongBlur = 20.0;
  
  /// Standard opacity for glass effects
  static const double standardOpacity = 0.15;
  
  /// Creates a standard glass container decoration
  static BoxDecoration glassDecoration({
    double borderRadius = 24.0,
    Color borderColor = Colors.white,
    double borderWidth = 0.5,
    double opacity = standardOpacity,
  }) {
    return BoxDecoration(
      color: Colors.white.withOpacity(opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor.withOpacity(0.2),
        width: borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          spreadRadius: -5,
        ),
      ],
    );
  }
  
  /// Creates a monochrome container decoration
  static BoxDecoration monochromeDecoration({
    double borderRadius = 24.0,
    bool isSelected = false,
    double opacity = 0.1,
  }) {
    return BoxDecoration(
      color: isSelected 
          ? Colors.white.withOpacity(0.9) 
          : Colors.white.withOpacity(opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: isSelected 
            ? Colors.transparent 
            : Colors.white.withOpacity(0.2),
        width: 0.5,
      ),
      boxShadow: isSelected ? [
        BoxShadow(
          color: Colors.white.withOpacity(0.15),
          blurRadius: 12,
          spreadRadius: -2,
          offset: const Offset(0, 2),
        ),
      ] : null,
    );
  }
}

/// Extension method to add glassmorphism to any widget
extension GlassmorphismExtension on Widget {
  /// Wraps the widget in a glassmorphism container
  Widget withGlass({
    double borderRadius = 24.0,
    double blur = GlassmorphismUtils.standardBlur,
    double opacity = GlassmorphismUtils.standardOpacity,
    Color borderColor = Colors.white,
    double borderWidth = 0.5,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: GlassmorphismUtils.glassDecoration(
            borderRadius: borderRadius,
            borderColor: borderColor,
            borderWidth: borderWidth,
            opacity: opacity,
          ),
          child: this,
        ),
      ),
    );
  }
  
  /// Wraps the widget in a monochrome container
  Widget withMonochrome({
    double borderRadius = 24.0,
    bool isSelected = false,
    double opacity = 0.1,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
    bool enableAnimation = true,
    Duration duration = const Duration(milliseconds: 350),
  }) {
    Widget result = Container(
      padding: padding,
      decoration: GlassmorphismUtils.monochromeDecoration(
        borderRadius: borderRadius,
        isSelected: isSelected,
        opacity: opacity,
      ),
      child: this,
    );
    
    if (enableAnimation) {
      return AnimatedContainer(
        duration: duration,
        curve: AnimationConstants.standardCurve,
        child: result,
      );
    }
    
    return result;
  }
} 