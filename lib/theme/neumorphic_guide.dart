import 'package:flutter/material.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A guide for standardized neumorphic styling across the app
/// Provides constants and helper methods for consistent design
class NeumorphicGuide {
  // Private constructor to prevent instantiation
  NeumorphicGuide._();

  // Depth values for different card types
  static const double kStandardDepth = 5.0;
  static const double kSubtleDepth = 3.0;
  static const double kFeaturedDepth = 7.0;
  static const double kModalDepth = 8.0;
  static const double kButtonDepth = 4.0;

  // Intensity values for shadow effect
  static const double kStandardIntensity = 0.12;
  static const double kSubtleIntensity = 0.08;
  static const double kFeaturedIntensity = 0.16;
  static const double kAccentedIntensity = 0.2;
  
  // Border radius values
  static const double kStandardRadius = 16.0;
  static const double kLargeRadius = 24.0;
  static const double kSmallRadius = 12.0;
  static const double kButtonRadius = 8.0;
  static const double kTileRadius = 12.0;
  
  // Standard light sources
  static const Alignment kStandardLightSource = Alignment.topLeft;
  static const Alignment kAlternateLightSource = Alignment.topRight;

  // Animation durations
  static const Duration kPressAnimationDuration = Duration(milliseconds: 150);
  static const Duration kHoverAnimationDuration = Duration(milliseconds: 300);

  // Background colors for different card types
  static const Color kCardBackground = AppColors.cardBackground;
  static const Color kDarkerCardBackground = Color(0xFF0A0A0A);
  static const Color kLighterCardBackground = Color(0xFF151515);
  static const Color kGoldAccentedBackground = Color(0xFF14130E);

  // Border styles
  static Border standardBorder({bool isPressed = false}) {
    return Border.all(
      color: isPressed
          ? Colors.black.withOpacity(0.3)
          : Colors.white.withOpacity(0.03),
      width: 0.5,
    );
  }

  static Border goldAccentBorder({bool isPressed = false}) {
    return Border.all(
      color: isPressed
          ? AppColors.gold.withOpacity(0.05)
          : AppColors.gold.withOpacity(0.1),
      width: 0.5,
    );
  }

  // Shadow styles for different card types
  static List<BoxShadow> getStandardShadows({
    double depth = kStandardDepth,
    double intensity = kStandardIntensity,
    Alignment lightSource = kStandardLightSource,
    bool isPressed = false,
  }) {
    final xOffset = lightSource.x * depth;
    final yOffset = lightSource.y * depth;
    
    final lighterColor = Color.lerp(
      kCardBackground, 
      Colors.white, 
      isPressed ? intensity * 0.2 : intensity * 0.4
    )!;
    
    final darkerColor = Color.lerp(
      Colors.black, 
      Colors.black, 
      isPressed ? 0.9 : 0.8
    )!;
    
    final pressedDepth = isPressed ? depth * 0.3 : depth;

    return [
      // Light shadow
      BoxShadow(
        color: lighterColor,
        offset: Offset(-xOffset * 0.6, -yOffset * 0.6),
        blurRadius: pressedDepth * 2,
        spreadRadius: -1,
      ),
      // Dark shadow
      BoxShadow(
        color: darkerColor,
        offset: Offset(xOffset, yOffset),
        blurRadius: pressedDepth * 1.5,
        spreadRadius: 1,
      ),
    ];
  }

  static List<BoxShadow> getGoldAccentShadows({
    double depth = kFeaturedDepth,
    double intensity = kFeaturedIntensity,
    Alignment lightSource = kStandardLightSource,
    bool isPressed = false,
  }) {
    final standardShadows = getStandardShadows(
      depth: depth,
      intensity: intensity,
      lightSource: lightSource,
      isPressed: isPressed,
    );
    
    // Add a gold glow if not pressed
    if (!isPressed) {
      standardShadows.add(
        BoxShadow(
          color: AppColors.gold.withOpacity(0.05),
          offset: const Offset(0, 0),
          blurRadius: 10,
          spreadRadius: -2,
        ),
      );
    }
    
    return standardShadows;
  }

  // Press animation
  static Widget addPressAnimation({
    required Widget child,
    required bool isPressed,
    Duration duration = kPressAnimationDuration,
    double scale = 0.98,
  }) {
    return AnimatedScale(
      scale: isPressed ? scale : 1.0,
      duration: duration,
      child: child,
    );
  }
  
  // Helper method to create a neumorphic container
  static Widget createNeumorphicContainer({
    required Widget child,
    required double borderRadius,
    Color backgroundColor = kCardBackground,
    double depth = kStandardDepth,
    double intensity = kStandardIntensity,
    Alignment lightSource = kStandardLightSource,
    bool isPressed = false,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    // Apply padding if provided
    Widget wrappedChild = child;
    if (padding != null) {
      wrappedChild = Padding(
        padding: padding,
        child: wrappedChild,
      );
    }
    
    // Create shadow effects
    final shadows = getStandardShadows(
      depth: depth,
      intensity: intensity,
      lightSource: lightSource,
      isPressed: isPressed,
    );
    
    // Create container with black outer edge
    Widget container = Container(
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(borderRadius + 2),
      ),
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: shadows,
          border: standardBorder(isPressed: isPressed),
        ),
        child: wrappedChild,
      ),
    );
    
    // Apply margin if provided
    if (margin != null) {
      container = Padding(
        padding: margin,
        child: container,
      );
    }
    
    return container;
  }
} 