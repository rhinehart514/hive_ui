import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animation durations following HIVE brand aesthetic guidelines.
/// 
/// As per the animation specifications:
/// - 150-200ms for micro-interactions
/// - 300-350ms for page transitions
/// - 400-500ms maximum for modals
class AnimationDurations extends ThemeExtension<AnimationDurations> {
  /// Micro-interactions (button press, selection toggle): 150ms
  final Duration microInteraction;
  
  /// Button press shrink/expand: 120ms
  final Duration buttonPress;
  
  /// Tap feedback: 150ms
  final Duration tapFeedback;
  
  /// Deep press feedback: 200ms
  final Duration deepPress;
  
  /// Surface fade (Modal entrance, overlay fade): 300ms
  final Duration surfaceFade;
  
  /// Page transitions (push/pop): 320ms
  final Duration pageTransition;
  
  /// Content slide (Feed → Space): 400ms
  final Duration contentSlide;
  
  /// Error shake animation: 400ms
  final Duration errorShake;

  /// Creates a set of animation durations with predefined values from HIVE brand guidelines.
  const AnimationDurations({
    this.microInteraction = const Duration(milliseconds: 150),
    this.buttonPress = const Duration(milliseconds: 120),
    this.tapFeedback = const Duration(milliseconds: 150),
    this.deepPress = const Duration(milliseconds: 200),
    this.surfaceFade = const Duration(milliseconds: 300),
    this.pageTransition = const Duration(milliseconds: 320),
    this.contentSlide = const Duration(milliseconds: 400),
    this.errorShake = const Duration(milliseconds: 400),
  });

  @override
  AnimationDurations copyWith({
    Duration? microInteraction,
    Duration? buttonPress,
    Duration? tapFeedback,
    Duration? deepPress,
    Duration? surfaceFade,
    Duration? pageTransition,
    Duration? contentSlide,
    Duration? errorShake,
  }) {
    return AnimationDurations(
      microInteraction: microInteraction ?? this.microInteraction,
      buttonPress: buttonPress ?? this.buttonPress,
      tapFeedback: tapFeedback ?? this.tapFeedback,
      deepPress: deepPress ?? this.deepPress,
      surfaceFade: surfaceFade ?? this.surfaceFade,
      pageTransition: pageTransition ?? this.pageTransition,
      contentSlide: contentSlide ?? this.contentSlide,
      errorShake: errorShake ?? this.errorShake,
    );
  }

  @override
  ThemeExtension<AnimationDurations> lerp(
    covariant ThemeExtension<AnimationDurations>? other, 
    double t
  ) {
    if (other is! AnimationDurations) {
      return this;
    }
    
    // Linear interpolation of durations is not typically useful
    // but we implement it for completeness
    return AnimationDurations(
      microInteraction: _lerpDuration(microInteraction, other.microInteraction, t),
      buttonPress: _lerpDuration(buttonPress, other.buttonPress, t),
      tapFeedback: _lerpDuration(tapFeedback, other.tapFeedback, t),
      deepPress: _lerpDuration(deepPress, other.deepPress, t),
      surfaceFade: _lerpDuration(surfaceFade, other.surfaceFade, t),
      pageTransition: _lerpDuration(pageTransition, other.pageTransition, t),
      contentSlide: _lerpDuration(contentSlide, other.contentSlide, t),
      errorShake: _lerpDuration(errorShake, other.errorShake, t),
    );
  }
  
  /// Linearly interpolate between two durations.
  Duration _lerpDuration(Duration a, Duration b, double t) {
    return Duration(
      microseconds: (a.inMicroseconds + (b.inMicroseconds - a.inMicroseconds) * t).round(),
    );
  }
}

/// Animation curves following HIVE brand aesthetic guidelines.
class AnimationCurves {
  /// Standard ease-in-out curve for general transitions
  static const standard = Curves.easeInOut;
  
  /// Surface fade curve (modal entrance, overlay fade)
  static const surfaceFade = Cubic(0.4, 0.0, 0.2, 1.0);
  
  /// Content slide curve (feed to space or modal to full view)
  static const contentSlide = Cubic(0.0, 0.0, 0.2, 1.0);
  
  /// Tap feedback curve
  static const tapFeedback = Cubic(0.4, 0.0, 1.0, 1.0);
  
  /// Deep press curve
  static const deepPress = Cubic(0.2, 0.0, 0.2, 1.0);
  
  /// Page push/pop curve (mirrors UIKit native nav transition)
  static const pageTransition = Cubic(0.25, 0.8, 0.30, 1.0);
  
  /// Button press curve
  static const buttonPress = Curves.easeOut;
  
  /// Selection toggle curve
  static const selectionToggle = Curves.easeInOut;
  
  /// Spring curve for physics-based animations (damping ratio: 0.7-0.85)
  static const spring = SpringCurve(
    mass: 1.0,
    stiffness: 100.0,
    damping: 15.0,
  );
  
  AnimationCurves._(); // Private constructor to prevent instantiation
}

/// A custom curve that simulates spring physics.
/// Provides the optimal damping ratio (0.7-0.85) specified in the brand guidelines.
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
    // Simple approximation of spring motion for a curve
    final omega = math.sqrt(stiffness / mass);
    final zeta = damping / (2 * math.sqrt(stiffness * mass));
    
    // Underdamped case (0 < zeta < 1)
    if (zeta < 1) {
      final omegaD = omega * math.sqrt(1 - zeta * zeta);
      const A = 1.0;
      final expTerm = math.exp(-zeta * omega * t);
      
      return 1 - expTerm * (A * math.cos(omegaD * t) + 
          (zeta * omega / omegaD) * A * math.sin(omegaD * t));
    } else {
      // Fall back to standard easeOutQuart for overdamped case
      return 1 - math.pow(1 - t, 4).toDouble();
    }
  }
} 