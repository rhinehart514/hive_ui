import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animation constants for the HIVE UI
/// These values help create a consistent motion system across the app
class AnimationConstants {
  /// Duration for standard interactions (buttons, toggles)
  static const Duration standardDuration = Duration(milliseconds: 300);
  
  /// Duration for page transitions
  static const Duration pageTransitionDuration = Duration(milliseconds: 350);
  
  /// Duration for microinteractions (ripples, highlights)
  static const Duration microDuration = Duration(milliseconds: 150);
  
  /// Alias for microDuration to maintain backward compatibility
  static Duration get quickDuration => microDuration;
  
  /// Duration for elaborate transitions (dialogs, cards)
  static const Duration elaborateDuration = Duration(milliseconds: 400);
  
  /// Standard curve for most animations - matches HIVE's "Purposeful Motion" principle
  static const Curve standardCurve = Curves.easeOutCubic;
  
  /// Deceleration curve - for elements entering the screen
  static const Curve entranceCurve = Curves.easeOutCubic;
  
  /// Acceleration curve - for elements leaving the screen
  static const Curve exitCurve = Curves.easeInCubic;
  
  /// Curve for interactive elements - more responsive feel
  static const Curve interactiveCurve = Curves.easeOut;
  
  /// Curve for emphasis animations - dramatic motion
  static const Curve emphasisCurve = Curves.easeInOutCubic;
  
  /// Curve for subtle animations - gentle motion
  static const Curve subtleCurve = Curves.easeInOut;
  
  /// Spring curve - for bouncy animations (use sparingly per HIVE brand guidelines)
  static const Curve springCurve = SpringCurve(mass: 1.0, stiffness: 100.0, damping: 15.0);
  
  /// Default delay between staggered animations
  static const Duration staggerDelay = Duration(milliseconds: 50);
  
  /// Initial delay before animation sequence begins
  static const Duration initialDelay = Duration(milliseconds: 100);
  
  /// Scaling factor for hover/focus states
  static const double hoverScale = 1.03;
  
  /// Scaling factor for press states
  static const double pressScale = 0.97;
  
  /// Distance for standard slide transitions (in logical pixels)
  static const double slideDistance = 20.0;
  
  /// Opacity value for disabled states
  static const double disabledOpacity = 0.6;
  
  /// HIVE brand colors for UI states
  static const Color accentColor = Color(0xFFEEB700); // HIVE yellow
  static const Color deepSurfaceColor = Colors.black; // HIVE pure black (for overlays only)
  static const Color primaryTextColor = Color(0xFFE0E0E0); // HIVE off-white
  static const Color secondarySurfaceColor = Color(0xFF1E1E1E);
}

/// A curve that simulates spring physics for natural motion
class SpringCurve extends Curve {
  final double mass;
  final double stiffness;
  final double damping;
  
  const SpringCurve({
    required this.mass,
    required this.stiffness,
    required this.damping,
  });
  
  @override
  double transform(double t) {
    // Simple dampened spring equation: x = e^(-dt) * cos(wt)
    // where d = damping/(2*mass), w = sqrt(stiffness/mass - d*d)
    final dampingRatio = damping / (2 * mass);
    final angularFreq = math.sqrt(stiffness / mass - dampingRatio * dampingRatio);
    
    // Calculate the position using the dampened spring equation
    return 1.0 - math.exp(-dampingRatio * t) * math.cos(angularFreq * t);
  }
}

/// Extension method to provide animation methods on widgets
extension AnimationExtensions on Widget {
  /// Slide in animation with fade
  Widget slideIn({
    bool show = true,
    Duration? duration,
    Offset begin = const Offset(0.0, 0.2),
    Offset end = Offset.zero,
  }) {
    return AnimatedSlide(
      offset: show ? end : begin,
      duration: duration ?? AnimationConstants.standardDuration,
      curve: show ? AnimationConstants.entranceCurve : AnimationConstants.exitCurve,
      child: this,
    );
  }
} 