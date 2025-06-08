import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/app_colors.dart';

/// Defines the visual styles for all feed components to ensure consistency
/// with the HIVE brand aesthetic - specifically targeting the Apple/Discord/Linear style mix.
class FeedTheme {
  // Private constructor to prevent instantiation
  FeedTheme._();

  // Card Styles - Following 8pt grid system
  static const double standardCardRadius = 16.0;
  static const double standardCardPadding = 16.0;
  static const double standardCardMargin = 16.0;
  static const double standardSpacing = 8.0;
  static const double standardBorderWidth = 0.5;
  
  // Touch target minimum size
  static const double minTouchTarget = 48.0;

  // Elevation & Shadow Specs - Following brand aesthetic
  static BoxShadow get subtleShadow => BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 8,
        offset: const Offset(0, 2),
      );

  static BoxShadow get accentedShadow => BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 16,
        offset: const Offset(0, 4),
      );

  static BoxShadow get modalShadow => BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 30,
        spreadRadius: -5,
        offset: const Offset(0, 10),
      );
        
  static BoxShadow get goldAccentShadow => BoxShadow(
        color: AppColors.gold.withOpacity(0.05),
        blurRadius: 8,
        spreadRadius: -2,
      );

  // Glassmorphism Parameters - Following brand aesthetic
  static double get standardBlur => 10.0;
  static double get subtleBlur => 5.0;
  static double get maxBlur => 15.0;

  static Color get tintColor => Colors.black.withOpacity(0.2);
  static Color get borderColor => Colors.white.withOpacity(0.15);

  // Typography - Using the refined style from brand aesthetic
  static TextStyle get displayLarge => GoogleFonts.inter(
        color: AppColors.white,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      );

  static TextStyle get titleLarge => GoogleFonts.inter(
        color: AppColors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
      );

  static TextStyle get titleMedium => GoogleFonts.inter(
        color: AppColors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        color: AppColors.white,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        color: AppColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
      );

  static TextStyle get caption => GoogleFonts.inter(
        color: AppColors.textTertiary,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
      );

  static TextStyle get labelLarge => GoogleFonts.inter(
        color: AppColors.yellow,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      );

  static TextStyle get labelMedium => GoogleFonts.inter(
        color: AppColors.yellow,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      );

  // Animation Constants - Following brand aesthetic motion principles
  static const Duration shortDuration = Duration(milliseconds: 150);
  static const Duration mediumDuration = Duration(milliseconds: 300);
  static const Duration longDuration = Duration(milliseconds: 400);
  
  // Animation Curves
  static const Curve standardCurve = Curves.easeOutQuint;
  static const Curve entranceCurve = Curves.easeOutQuint;
  static const Curve exitCurve = Curves.easeInQuad;
  static const Curve pressAnimationCurve = Curves.easeOut;

  // Interaction Feedback
  static void lightHaptic() => HapticFeedback.lightImpact();
  static void mediumHaptic() => HapticFeedback.mediumImpact();
  static void selectionHaptic() => HapticFeedback.selectionClick();
  static void successHaptic() => HapticFeedback.mediumImpact();

  // Glassmorphism Container Builder - Standard Configuration
  static Widget buildGlassContainer({
    required Widget child,
    double blur = 10.0,
    Color tint = Colors.transparent,
    BorderRadius? borderRadius,
    BoxShadow? shadow,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16.0),
    Color? borderColor,
    double borderWidth = 0.5,
  }) {
    final defaultBorderRadius = BorderRadius.circular(standardCardRadius);
    final effectiveBorderRadius = borderRadius ?? defaultBorderRadius;

    return Container(
      decoration: BoxDecoration(
        borderRadius: effectiveBorderRadius,
        boxShadow: shadow != null ? [shadow] : null,
      ),
      child: ClipRRect(
        borderRadius: effectiveBorderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: tint != Colors.transparent
                  ? tint
                  : Colors.black.withOpacity(0.2),
              borderRadius: effectiveBorderRadius,
              border: borderColor != null
                  ? Border.all(
                      color: borderColor,
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
  
  // Modal Glassmorphism - For dialogs and overlays
  static Widget buildModalGlass({
    required Widget child,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16.0),
    bool addGoldAccent = false,
  }) {
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(24.0);
    
    Widget result = ClipRRect(
      borderRadius: effectiveBorderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: maxBlur, sigmaY: maxBlur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: effectiveBorderRadius,
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
    
    if (addGoldAccent) {
      result = Container(
        decoration: BoxDecoration(
          borderRadius: effectiveBorderRadius,
          boxShadow: [goldAccentShadow],
        ),
        child: result,
      );
    }
    
    return result;
  }
  
  // Card Factory - Creates consistently styled card containers
  static Widget buildStandardCard({
    required Widget child,
    Color backgroundColor = AppColors.cardBackground,
    bool hasBorder = true,
    bool hasGlassmorphism = false,
    double borderRadius = standardCardRadius,
    EdgeInsetsGeometry padding = const EdgeInsets.all(standardCardPadding),
    EdgeInsetsGeometry margin = const EdgeInsets.only(bottom: standardCardMargin),
  }) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: hasGlassmorphism ? Colors.transparent : backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: hasBorder ? Border.all(
          color: Colors.white.withOpacity(0.1),
          width: standardBorderWidth,
        ) : null,
        boxShadow: hasGlassmorphism ? null : [subtleShadow],
      ),
      child: hasGlassmorphism
          ? ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: subtleBlur, sigmaY: subtleBlur),
                child: Container(
                  padding: padding,
                  decoration: BoxDecoration(
                    color: tintColor,
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                  child: child,
                ),
              ),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: Padding(
                padding: padding,
                child: child,
              ),
            ),
    );
  }
  
  // Interactive card press animation wrapper
  static Widget addPressAnimation({
    required Widget child,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    bool enableHaptics = true,
    double scaleAmount = 0.98,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isPressed = false;
        
        return GestureDetector(
          onTap: () {
            if (enableHaptics) selectionHaptic();
            onTap();
          },
          onLongPress: onLongPress != null ? () {
            if (enableHaptics) mediumHaptic();
            onLongPress();
          } : null,
          onTapDown: (_) => setState(() => isPressed = true),
          onTapUp: (_) => setState(() => isPressed = false),
          onTapCancel: () => setState(() => isPressed = false),
          child: AnimatedScale(
            scale: isPressed ? scaleAmount : 1.0,
            duration: shortDuration,
            curve: pressAnimationCurve,
            child: child,
          ),
        );
      },
    );
  }
}
