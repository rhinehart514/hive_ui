import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Glass effect styles with predefined blur intensities
enum GlassStyle {
  /// Subtle blur effect (5px) for control backgrounds
  subtle(5.0),
  
  /// Standard blur effect (10px) for modals and cards
  standard(10.0),
  
  /// Heavy blur effect (15px) for full-screen overlays
  heavy(15.0);
  
  final double blurAmount;
  const GlassStyle(this.blurAmount);
}

/// A reusable container with glassmorphism effect
/// Follows the HIVE glass aesthetic with proper blur, tint, and border
class GlassContainer extends StatelessWidget {
  final Widget child;
  final GlassStyle style;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double? width;
  final double? height;
  final Color? tintColor;
  final double tintOpacity;
  final bool showBorder;
  final double borderWidth;
  final Color? borderColor;
  final BoxShadow? shadow;
  
  const GlassContainer({
    Key? key,
    required this.child,
    this.style = GlassStyle.standard,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = EdgeInsets.zero,
    this.width,
    this.height,
    this.tintColor,
    this.tintOpacity = 0.2,
    this.showBorder = true,
    this.borderWidth = 0.5,
    this.borderColor,
    this.shadow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Default tint is black with configurable opacity
    final Color effectiveTintColor = tintColor ?? AppColors.black;
    final Color effectiveBorderColor = borderColor ?? Colors.white.withOpacity(0.15);
    
    // Optional shadow to apply if provided
    final List<BoxShadow> shadows = shadow != null ? [shadow!] : [];
    
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: style.blurAmount,
            sigmaY: style.blurAmount,
          ),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: effectiveTintColor.withOpacity(tintOpacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: showBorder 
                  ? Border.all(
                      color: effectiveBorderColor,
                      width: borderWidth,
                    ) 
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
  
  /// Convenience method to create a modal-style glass container
  static Widget modal({
    required Widget child,
    double borderRadius = 16.0,
    EdgeInsetsGeometry padding = const EdgeInsets.all(24.0),
  }) {
    return GlassContainer(
      style: GlassStyle.standard,
      borderRadius: borderRadius,
      padding: padding,
      shadow: BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 30,
        spreadRadius: -5,
        offset: const Offset(0, 10),
      ),
      child: child,
    );
  }
  
  /// Convenience method to create a bottom sheet glass container
  static Widget bottomSheet({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(24.0),
  }) {
    return GlassContainer(
      style: GlassStyle.standard,
      borderRadius: 24.0,
      padding: padding,
      showBorder: true,
      shadow: BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 20,
        spreadRadius: -5,
        offset: const Offset(0, -2),
      ),
      child: child,
    );
  }
  
  /// Convenience method to create a subtle control glass container
  static Widget control({
    required Widget child,
    double borderRadius = 12.0,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
  }) {
    return GlassContainer(
      style: GlassStyle.subtle,
      borderRadius: borderRadius,
      padding: padding,
      tintOpacity: 0.1,
      showBorder: true,
      child: child,
    );
  }
} 