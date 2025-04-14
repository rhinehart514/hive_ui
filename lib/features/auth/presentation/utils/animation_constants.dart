import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Animation constants following Apple-like design principles
class AnimationConstants {
  /// Standard durations
  static const Duration quickDuration = Duration(milliseconds: 200);
  static const Duration standardDuration = Duration(milliseconds: 350);
  static const Duration slowDuration = Duration(milliseconds: 500);
  
  /// Standard curves
  /// Deceleration curve - for elements entering the screen
  static const Curve entranceCurve = Curves.easeOutCubic;
  /// Acceleration curve - for elements leaving the screen
  static const Curve exitCurve = Curves.easeInCubic;
  /// Standard curve - for most animations
  static const Curve standardCurve = Curves.easeInOutCubic;
  
  /// Interactive feedback curve - for button presses, etc.
  static const Curve interactiveCurve = Curves.easeOut;
  
  /// Spring curve - for bouncy animations
  static final Curve springCurve = SpringCurve(mass: 1.0, stiffness: 100.0, damping: 15.0);
  
  /// Color constants for animations
  /// Primary background for selected items (pure white for highest contrast)
  static const Color selectedItemColor = Colors.white;
  /// Secondary background for unselected items (pure black for highest contrast)
  static const Color unselectedItemColor = Colors.black;
  /// Border color for unselected items
  static final Color unselectedBorderColor = Colors.white.withOpacity(0.2);
  /// Glow color for selected items
  static final Color selectedGlowColor = Colors.white.withOpacity(0.2);
  /// Disabled item color
  static final Color disabledColor = Colors.white.withOpacity(0.12);
  /// Disabled text color
  static final Color disabledTextColor = Colors.white.withOpacity(0.38);
  /// Accent color for success states
  static const Color successColor = Color(0xFF4CD964);
  /// Accent color for error states
  static const Color errorColor = Color(0xFFFF3B30);
}

/// Custom spring curve that mimics iOS spring animations
class SpringCurve extends Curve {
  final double mass;
  final double stiffness;
  final double damping;
  
  SpringCurve({
    required this.mass,
    required this.stiffness,
    required this.damping,
  });
  
  @override
  double transform(double t) {
    // Simple spring simulation
    final omega = math.sqrt(stiffness / mass);
    final zeta = damping / (2 * math.sqrt(stiffness * mass));
    
    if (zeta < 1.0) {
      // Underdamped
      final omega_d = omega * math.sqrt(1.0 - zeta * zeta);
      final A = 1.0;
      final B = zeta * omega / omega_d;
      
      return 1.0 - math.exp(-zeta * omega * t) * (A * math.cos(omega_d * t) + B * math.sin(omega_d * t));
    } else {
      // Critically damped or overdamped
      return 1.0 - (1.0 + t * omega) * math.exp(-t * omega);
    }
  }
}

/// Extension methods for applying consistent animations
extension AnimationExtensions on Widget {
  /// Creates a fade transition with Apple-like timing
  Widget fadeTransition({
    bool show = true, 
    Duration duration = const Duration(milliseconds: 350)
  }) {
    return AnimatedOpacity(
      opacity: show ? 1.0 : 0.0,
      duration: duration,
      curve: AnimationConstants.standardCurve,
      child: this,
    );
  }
  
  /// Creates a scale transition with Apple-like timing
  Widget scaleTransition({
    bool show = true, 
    Duration duration = const Duration(milliseconds: 350),
    double begin = 0.95,
    double end = 1.0
  }) {
    return AnimatedScale(
      scale: show ? end : begin,
      duration: duration,
      curve: AnimationConstants.standardCurve,
      child: this,
    );
  }
  
  /// Adds a subtle highlight effect to items when they're active
  Widget withHighlight({
    required bool isActive,
    Duration duration = const Duration(milliseconds: 350),
    Color activeColor = Colors.white,
    Color inactiveColor = Colors.transparent,
    double borderRadius = 8.0,
  }) {
    return AnimatedContainer(
      duration: duration,
      curve: AnimationConstants.standardCurve,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: isActive ? [
          BoxShadow(
            color: activeColor.withOpacity(0.15),
            blurRadius: 16,
            spreadRadius: 1,
          )
        ] : null,
      ),
      child: this,
    );
  }
} 