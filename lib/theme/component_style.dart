import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/glassmorphism_guide.dart';

/// The style variant to apply to HIVE UI components based on context.
/// Updated for the new minimalist, high-contrast HIVE aesthetic.
enum HiveComponentStyle {
  /// Clean, minimal Apple-inspired feel (default)
  /// Used for core app functionality and standard UI elements
  standard,

  /// Subtle contrast enhancement for important elements
  /// Used for new features, community-focused areas, and student-exclusive functionality
  important,

  /// Special styling for hidden and experimental features
  /// Used for power user features, hidden functionality, and experimental features
  special,
}

/// Extension methods for [HiveComponentStyle] to get style-specific values
extension HiveComponentStyleExtension on HiveComponentStyle {
  /// Get the appropriate border radius based on the style
  double getBorderRadius(
      {double? standard, double? important, double? special}) {
    switch (this) {
      case HiveComponentStyle.standard:
        return standard ?? 16.0; // Moderate rounding for standard
      case HiveComponentStyle.important:
        return important ?? 12.0; // Slightly sharper for important
      case HiveComponentStyle.special:
        return special ?? 8.0; // Sharper edges for special
    }
  }

  /// Get the appropriate blur value based on the style
  double getBlurValue({double? standard, double? important, double? special}) {
    switch (this) {
      case HiveComponentStyle.standard:
        return standard ?? 10.0; // Reduced blur for cleaner look
      case HiveComponentStyle.important:
        return important ?? 12.0; // Slightly more blur for emphasis
      case HiveComponentStyle.special:
        return special ?? 15.0; // More blur for special elements
    }
  }

  /// Get the appropriate opacity value based on the style
  double getOpacityValue(
      {double? standard, double? important, double? special}) {
    switch (this) {
      case HiveComponentStyle.standard:
        return standard ?? 0.05; // Very subtle opacity
      case HiveComponentStyle.important:
        return important ?? 0.08; // Slightly more visible
      case HiveComponentStyle.special:
        return special ?? 0.12; // More visible for special elements
    }
  }

  /// Get the appropriate animation duration based on the style
  Duration getAnimationDuration(
      {Duration? standard, Duration? important, Duration? special}) {
    switch (this) {
      case HiveComponentStyle.standard:
        return standard ??
            const Duration(milliseconds: 300); // Quicker, more precise
      case HiveComponentStyle.important:
        return important ??
            const Duration(milliseconds: 250); // Faster for emphasis
      case HiveComponentStyle.special:
        return special ??
            const Duration(milliseconds: 200); // Fastest for special
    }
  }

  /// Get the appropriate animation curve based on the style
  Curve getAnimationCurve({Curve? standard, Curve? important, Curve? special}) {
    switch (this) {
      case HiveComponentStyle.standard:
        return standard ?? Curves.easeOutQuart; // Precise, refined motion
      case HiveComponentStyle.important:
        return important ?? Curves.easeOut; // Clean motion for emphasis
      case HiveComponentStyle.special:
        return special ??
            const Cubic(0.2, 0.0, 0.0, 1.0); // Sharp for special elements
    }
  }

  /// Get the appropriate color alpha for gold accent based on the style
  double getGoldAccentOpacity() {
    switch (this) {
      case HiveComponentStyle.standard:
        return 0.2; // Very subtle gold for standard
      case HiveComponentStyle.important:
        return 0.3; // More visible for important
      case HiveComponentStyle.special:
        return 0.4; // Most visible for special
    }
  }

  /// Get the border width based on the style
  double getBorderWidth() {
    switch (this) {
      case HiveComponentStyle.standard:
        return 0.5; // Thinner borders for standard
      case HiveComponentStyle.important:
        return 0.75; // Slightly thicker for important
      case HiveComponentStyle.special:
        return 1.0; // Thickest for special
    }
  }

  /// Get haptic feedback type based on component style
  HapticFeedbackType getHapticFeedbackType() {
    switch (this) {
      case HiveComponentStyle.standard:
        return HapticFeedbackType.light; // Subtle feedback for standard
      case HiveComponentStyle.important:
        return HapticFeedbackType.medium; // Medium for important
      case HiveComponentStyle.special:
        return HapticFeedbackType.heavy; // Strong for special
    }
  }

  /// Should add gold accent based on style
  bool shouldAddGoldAccent() {
    // Only special elements get gold by default
    return this == HiveComponentStyle.special;
  }
}

/// Helper class for animations based on the HIVE brand aesthetic
class HiveAnimations {
  // Standard durations - quicker, more precise
  static const Duration standard = Duration(milliseconds: 300);
  static const Duration quick = Duration(milliseconds: 200);

  // Curves - refined, precise
  static const Curve easeOut = Curves.easeOutQuart;
  static const Curve easeIn = Curves.easeInQuart;

  // Special curves
  static const Curve emphasis = Curves.easeOut;
  static const Curve special = Cubic(0.2, 0.0, 0.0, 1.0);

  /// Creates a fade-in animation based on the component style
  static Animation<double> createFadeIn(
    AnimationController controller, {
    HiveComponentStyle style = HiveComponentStyle.standard,
    double begin = 0.0,
    double end = 1.0,
  }) {
    return Tween<double>(begin: begin, end: end).animate(
      CurvedAnimation(
        parent: controller,
        curve: style.getAnimationCurve(),
        reverseCurve: easeIn,
      ),
    );
  }

  /// Creates a slide-up animation based on the component style
  static Animation<Offset> createSlideUp(
    AnimationController controller, {
    HiveComponentStyle style = HiveComponentStyle.standard,
    Offset begin = const Offset(0, 0.1), // Reduced slide distance
    Offset end = Offset.zero,
  }) {
    return Tween<Offset>(begin: begin, end: end).animate(
      CurvedAnimation(
        parent: controller,
        curve: style.getAnimationCurve(),
        reverseCurve: easeIn,
      ),
    );
  }

  /// Creates a scale animation based on the component style
  static Animation<double> createScale(
    AnimationController controller, {
    HiveComponentStyle style = HiveComponentStyle.standard,
    double begin = 0.98, // Subtle scale change
    double end = 1.0,
  }) {
    return Tween<double>(begin: begin, end: end).animate(
      CurvedAnimation(
        parent: controller,
        curve: style.getAnimationCurve(),
        reverseCurve: easeIn,
      ),
    );
  }
}

/// Helper class for determining which component style to use based on context
class HiveComponentStyleHelper {
  /// Determines if a component should use important style based on the feature context
  static bool shouldUseImportantStyle({
    required BuildContext context,
    bool isNewFeature = false,
    bool isCommunityFeature = false,
    bool isStudentExclusive = false,
  }) {
    // If any of the important contexts are true, use important style
    if (isNewFeature || isCommunityFeature || isStudentExclusive) {
      return true;
    }

    // Additional context-based logic can be added here

    // Default to standard
    return false;
  }

  /// Determines if a component should use special style based on the feature context
  static bool shouldUseSpecialStyle({
    required BuildContext context,
    bool isPowerUserFeature = false,
    bool isHiddenFeature = false,
    bool isExperimentalFeature = false,
  }) {
    // If any of the special contexts are true, use special style
    if (isPowerUserFeature || isHiddenFeature || isExperimentalFeature) {
      return true;
    }

    // Additional context-based logic can be added here

    // Default to standard
    return false;
  }

  /// Gets the appropriate component style based on the feature context
  static HiveComponentStyle getComponentStyle({
    required BuildContext context,
    bool isNewFeature = false,
    bool isCommunityFeature = false,
    bool isStudentExclusive = false,
    bool isPowerUserFeature = false,
    bool isHiddenFeature = false,
    bool isExperimentalFeature = false,
  }) {
    // Check for special style first
    if (shouldUseSpecialStyle(
      context: context,
      isPowerUserFeature: isPowerUserFeature,
      isHiddenFeature: isHiddenFeature,
      isExperimentalFeature: isExperimentalFeature,
    )) {
      return HiveComponentStyle.special;
    }

    // Then check for important style
    if (shouldUseImportantStyle(
      context: context,
      isNewFeature: isNewFeature,
      isCommunityFeature: isCommunityFeature,
      isStudentExclusive: isStudentExclusive,
    )) {
      return HiveComponentStyle.important;
    }

    // Default to standard
    return HiveComponentStyle.standard;
  }
}

/// Extension on Widget to add glassmorphism effects based on HiveComponentStyle
extension GlassmorphismExtension on Widget {
  /// Adds glassmorphism effect to a widget based on the component style
  Widget addStyledGlassmorphism({
    HiveComponentStyle style = HiveComponentStyle.standard,
    double? borderRadius,
    double? blur,
    double? opacity,
    bool addGoldAccent = false,
  }) {
    // Use style-specific values or provided overrides
    final double actualBorderRadius = borderRadius ?? style.getBorderRadius();
    final double actualBlur = blur ?? style.getBlurValue();
    final double actualOpacity = opacity ?? style.getOpacityValue();
    final bool shouldAddGold = addGoldAccent || style.shouldAddGoldAccent();

    // Create a glassmorphic container with the appropriate styling
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(actualBorderRadius),
        boxShadow: shouldAddGold ? GlassmorphismGuide.goldAccentShadows : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(actualBorderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: actualBlur, sigmaY: actualBlur),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(actualOpacity),
              borderRadius: BorderRadius.circular(actualBorderRadius),
              border: Border.all(
                color: shouldAddGold
                    ? AppColors.gold.withOpacity(style.getGoldAccentOpacity())
                    : Colors.white.withOpacity(0.1),
                width: style.getBorderWidth(),
              ),
            ),
            child: this,
          ),
        ),
      ),
    );
  }
}

/// Types of haptic feedback to apply to user interactions
enum HapticFeedbackType {
  /// Light impact for subtle feedback
  light,

  /// Medium impact for standard interactions
  medium,

  /// Heavy impact for significant actions or secret features
  heavy,

  /// Selection click for navigation or selection actions
  selection,
}
