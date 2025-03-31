import 'package:flutter/material.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:glassmorphism/glassmorphism.dart';

/// A guide for standardized glassmorphism usage across the app
/// Updated for the new HIVE brand aesthetic - minimal, high-contrast with reserved accents
class GlassmorphismGuide {
  // Private constructor to prevent instantiation
  GlassmorphismGuide._();

  // Blur values - more restrained for minimalist aesthetic
  static const double kHeaderBlur = 15; // Reduced blur for cleaner look
  static const double kCardBlur = 10; // More subtle card blur
  static const double kModalBlur = 20; // Modals stand out slightly
  static const double kBottomSheetBlur = 15; // More subtle bottom sheet blur
  static const double kDialogBlur = 15; // More subtle dialog blur
  static const double kToastBlur = 8; // Very subtle toast blur

  // Border values - thinner borders for refined look
  static const double kBorderNone = 0.0;
  static const double kBorderThin = 0.5; // Thinner for subtlety
  static const double kBorderStandard = 1.0; // Reduced standard thickness
  static const double kBorderThick = 1.5; // Less thick for refinement

  // Border radius values - more consistent across elements
  static const double kRadiusNone = 0.0;
  static const double kSmallRadius = 8.0;
  static const double kRadiusXs = 8.0;
  static const double kRadiusSm = 12.0;
  static const double kRadiusMd = 16.0;
  static const double kRadiusLg = 20.0; // Slightly reduced
  static const double kRadiusXl = 28.0; // Slightly reduced
  static const double kRadiusFull = 9999.0;
  static const double kModalRadius = 20.0;

  // Opacity values - more subtle for cleaner look
  static const double kOpacityNone = 0.0;
  static const double kOpacityXs = 0.03; // More subtle
  static const double kOpacitySm = 0.05; // More subtle
  static const double kOpacityMd = 0.08; // More subtle
  static const double kOpacityLg = 0.12; // More subtle
  static const double kOpacityXl = 0.15; // More subtle

  // Glass opacity values - more subtle for cleaner look
  static const double kStandardGlassOpacity = 0.08; // More subtle
  static const double kLightGlassOpacity = 0.05; // More subtle
  static const double kModalGlassOpacity = 0.1; // More subtle
  static const double kHeaderGlassOpacity = 0.08; // More subtle
  static const double kCardGlassOpacity = 0.05; // More subtle

  // Standard values
  static const double kStandardBlur = kCardBlur;
  static const double kStandardBorder = kBorderStandard;
  static const double kStandardRadius = kRadiusMd;
  static const double kStandardOpacity = kOpacityMd;

  // Gradient colors - more subtle, refined gradients
  static LinearGradient get standardGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.05), // More subtle
          Colors.white.withOpacity(0.02), // More subtle
        ],
        stops: const [0.1, 1.0],
      );

  static LinearGradient get borderGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.2), // More subtle
          Colors.white.withOpacity(0.1), // More subtle
        ],
      );

  // Shadow effects - more subtle shadows
  static List<BoxShadow> get goldAccentShadows => [
        BoxShadow(
          color: AppColors.gold.withOpacity(0.05), // Yellow as a whisper
          blurRadius: 8,
          spreadRadius: -2,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.3), // More subtle shadow
          blurRadius: 6,
          spreadRadius: 0,
          offset: const Offset(0, 3), // Smaller offset
        ),
      ];

  // Helper method to create a GlassmorphicContainer
  static Widget createContainer({
    required Widget child,
    required double width,
    required double height,
    double blur = kStandardBlur,
    double borderRadius = kStandardRadius,
    double border = kStandardBorder,
    LinearGradient? linearGradient,
    LinearGradient? borderGradient,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Alignment alignment = Alignment.center,
  }) {
    return GlassmorphicContainer(
      width: width,
      height: height,
      borderRadius: borderRadius,
      blur: blur,
      alignment: alignment,
      border: border,
      linearGradient: linearGradient ?? standardGradient,
      borderGradient: borderGradient ?? GlassmorphismGuide.borderGradient,
      margin: margin,
      padding: padding,
      child: child,
    );
  }

  // Helper method to create a flexible GlassmorphicContainer
  static Widget createFlexContainer({
    required Widget child,
    double blur = kStandardBlur,
    double borderRadius = kStandardRadius,
    double border = kStandardBorder,
    LinearGradient? linearGradient,
    LinearGradient? borderGradient,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Alignment alignment = Alignment.center,
  }) {
    return GlassmorphicFlexContainer(
      borderRadius: borderRadius,
      blur: blur,
      alignment: alignment,
      border: border,
      linearGradient: linearGradient ?? standardGradient,
      borderGradient: borderGradient ?? GlassmorphismGuide.borderGradient,
      margin: margin,
      padding: padding,
      child: child,
    );
  }
}
