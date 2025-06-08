import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';

/// A container widget with a glassmorphic effect
class GlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double borderRadius;
  final double border;
  final Color? borderColor;
  final Color? backgroundColor;

  const GlassmorphicContainer({
    Key? key,
    required this.child,
    this.blur = 10,
    this.opacity = 0.2,
    this.borderRadius = 10,
    this.border = 1,
    this.borderColor,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: (backgroundColor ?? Colors.white).withOpacity(opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              width: border,
              color: borderColor ?? AppColors.gold.withOpacity(0.3),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
} 