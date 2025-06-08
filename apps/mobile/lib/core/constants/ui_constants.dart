import 'package:flutter/material.dart';

/// Defines standard UI constants like animation durations and curves for HIVE.
class UIConstants {

  // --- Durations (Based on hive_motion_standards) ---
  static const Duration durationMicroInteraction = Duration(milliseconds: 150);
  static const Duration durationTapFeedback = Duration(milliseconds: 150);
  static const Duration durationShort = Duration(milliseconds: 200);
  static const Duration durationMedium = Duration(milliseconds: 300);
  static const Duration durationStandard = Duration(milliseconds: 350); // e.g., Page transitions
  static const Duration durationLong = Duration(milliseconds: 500); // e.g., Modals

  // Specific animation durations
  static const Duration shakeDuration = Duration(milliseconds: 400);

  // --- Curves (Based on hive_motion_standards) ---
  /// Standard curve for most UI transitions (Material Standard)
  static const Curve standardCurve = Curves.easeInOut; // cubic-bezier(0.4, 0, 0.2, 1)
  
  /// Decelerate curve for elements settling into place.
  static const Curve decelerateCurve = Curves.easeOut; // cubic-bezier(0.0, 0, 0.2, 1)
  
  /// Accelerate curve for elements leaving the screen.
  static const Curve accelerateCurve = Curves.easeIn; // cubic-bezier(0.4, 0, 1, 1)

  /// Sharp curve for quick interactions.
  static const Curve sharpCurve = Curves.easeOutExpo;

  // --- Shake Animation Parameters ---
  static const double shakeHz = 5.0;
  static const double shakeAmount = 4.0;

  /// Button border radius for circular buttons
  static const double kCircularButtonRadius = 24.0;

  /// Minimum tap target size (for accessibility)
  static const double kMinTapTargetSize = 48.0;

  /// Default padding for content

  // Prevent instantiation
  UIConstants._();
} 