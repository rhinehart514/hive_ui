import 'dart:ui';
import 'package:flutter/material.dart';

/// A container with a frosted glass effect
class GlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final double border;
  final LinearGradient linearGradient;
  final LinearGradient borderGradient;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? height;
  final double? width;
  final BoxConstraints? constraints;
  
  const GlassmorphicContainer({
    super.key,
    required this.child,
    required this.borderRadius,
    required this.blur,
    required this.border,
    required this.linearGradient,
    required this.borderGradient,
    this.padding,
    this.margin,
    this.height,
    this.width,
    this.constraints,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      height: height,
      width: width,
      constraints: constraints,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blur,
            sigmaY: blur,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: linearGradient,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                width: border,
                color: borderGradient.colors[0].withOpacity(0.4),
              ),
            ),
            child: Padding(
              padding: padding ?? EdgeInsets.zero,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
} 