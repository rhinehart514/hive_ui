import 'package:flutter/material.dart';

/// Standardized animation durations for HIVE UI
/// Based on the HIVE Brand Aesthetic guide (brand_aesthetic.md Section 6.1)
/// 
/// Implements animation durations as a ThemeExtension for easy access
/// throughout the application.
class AnimationDurations extends ThemeExtension<AnimationDurations> {
  // Standard durations per brand specs
  
  /// Surface Fade: 300ms (Modal entrance, overlay fade)
  final Duration surfaceFade;
  
  /// Content Slide: 400ms (Feed → Space or Modal → Full View)
  final Duration contentSlide;
  
  /// Tap Feedback: 150ms (Button/card tap)
  final Duration tapFeedback;
  
  /// Deep Press: 200ms (Long-hold feedback)
  final Duration deepPress;
  
  /// Page push/pop: 320ms (Mirrors UIKit native nav transition)
  final Duration pageTransition;
  
  /// Button press: 120ms (Must end before finger lifts—feels instant)
  final Duration buttonPress;
  
  /// Selection toggle: 150ms (Use opacity fade + 4pt scale bump)
  final Duration selectionToggle;
  
  /// Error shake: 400ms total (3× 50pt shakes, spring damping 0.45)
  final Duration errorShake;
  
  /// Microinteraction duration: 300ms (e.g., Join Space ripple)
  final Duration microinteraction;
  
  /// Short duration for subtle effects: 200ms
  final Duration short;
  
  /// Reduced motion durations - used when reduced motion is enabled
  final Duration reducedMotion;
  
  const AnimationDurations({
    this.surfaceFade = const Duration(milliseconds: 300),
    this.contentSlide = const Duration(milliseconds: 400),
    this.tapFeedback = const Duration(milliseconds: 150),
    this.deepPress = const Duration(milliseconds: 200),
    this.pageTransition = const Duration(milliseconds: 320),
    this.buttonPress = const Duration(milliseconds: 120),
    this.selectionToggle = const Duration(milliseconds: 150),
    this.errorShake = const Duration(milliseconds: 400),
    this.microinteraction = const Duration(milliseconds: 300),
    this.short = const Duration(milliseconds: 200),
    this.reducedMotion = const Duration(milliseconds: 150),
  });

  @override
  AnimationDurations copyWith({
    Duration? surfaceFade,
    Duration? contentSlide,
    Duration? tapFeedback,
    Duration? deepPress,
    Duration? pageTransition,
    Duration? buttonPress,
    Duration? selectionToggle,
    Duration? errorShake,
    Duration? microinteraction,
    Duration? short,
    Duration? reducedMotion,
  }) {
    return AnimationDurations(
      surfaceFade: surfaceFade ?? this.surfaceFade,
      contentSlide: contentSlide ?? this.contentSlide,
      tapFeedback: tapFeedback ?? this.tapFeedback,
      deepPress: deepPress ?? this.deepPress,
      pageTransition: pageTransition ?? this.pageTransition,
      buttonPress: buttonPress ?? this.buttonPress,
      selectionToggle: selectionToggle ?? this.selectionToggle,
      errorShake: errorShake ?? this.errorShake,
      microinteraction: microinteraction ?? this.microinteraction,
      short: short ?? this.short,
      reducedMotion: reducedMotion ?? this.reducedMotion,
    );
  }

  @override
  AnimationDurations lerp(ThemeExtension<AnimationDurations>? other, double t) {
    if (other is! AnimationDurations) {
      return this;
    }
    
    // Duration lerp helper - can't use standard Duration lerp
    Duration lerpDuration(Duration a, Duration b, double t) {
      return Duration(
        microseconds: (a.inMicroseconds + (b.inMicroseconds - a.inMicroseconds) * t)
            .round()
            .clamp(0, double.maxFinite.toInt()),
      );
    }
    
    return AnimationDurations(
      surfaceFade: lerpDuration(surfaceFade, other.surfaceFade, t),
      contentSlide: lerpDuration(contentSlide, other.contentSlide, t),
      tapFeedback: lerpDuration(tapFeedback, other.tapFeedback, t),
      deepPress: lerpDuration(deepPress, other.deepPress, t),
      pageTransition: lerpDuration(pageTransition, other.pageTransition, t), 
      buttonPress: lerpDuration(buttonPress, other.buttonPress, t),
      selectionToggle: lerpDuration(selectionToggle, other.selectionToggle, t),
      errorShake: lerpDuration(errorShake, other.errorShake, t),
      microinteraction: lerpDuration(microinteraction, other.microinteraction, t),
      short: lerpDuration(short, other.short, t),
      reducedMotion: lerpDuration(reducedMotion, other.reducedMotion, t),
    );
  }
  
  /// Helper method to get reduced motion durations if needed
  /// Use this to adapt animations based on accessibility settings
  AnimationDurations getReducedMotion() {
    return AnimationDurations(
      surfaceFade: reducedMotion,
      contentSlide: reducedMotion,
      tapFeedback: reducedMotion,
      deepPress: reducedMotion,
      pageTransition: reducedMotion,
      buttonPress: reducedMotion,
      selectionToggle: reducedMotion,
      errorShake: reducedMotion,
      microinteraction: reducedMotion,
      short: reducedMotion,
      reducedMotion: reducedMotion,
    );
  }
}

/// Animation curves matching HIVE brand specifications 
/// Based on the HIVE Brand Aesthetic guide (brand_aesthetic.md Section 6.1)
class AnimationCurves {
  // Standard curves per brand specs
  
  /// Surface Fade: cubic-bezier(0.4, 0, 0.2, 1) (Modal entrance, overlay fade)
  static const Cubic surfaceFade = Cubic(0.4, 0.0, 0.2, 1.0);
  
  /// Content Slide: cubic-bezier(0.0, 0, 0.2, 1) (Feed → Space or Modal → Full View)
  static const Cubic contentSlide = Cubic(0.0, 0.0, 0.2, 1.0);
  
  /// Tap Feedback: cubic-bezier(0.4, 0, 1, 1) (Button/card tap)
  static const Cubic tapFeedback = Cubic(0.4, 0.0, 1.0, 1.0);
  
  /// Deep Press: cubic-bezier(0.2, 0, 0.2, 1) (Long-hold feedback)
  static const Cubic deepPress = Cubic(0.2, 0.0, 0.2, 1.0);
  
  /// Page push/pop: cubic-bezier(0.25, 0.8, 0.30, 1) (Mirrors UIKit native nav transition)
  static const Cubic pageTransition = Cubic(0.25, 0.8, 0.30, 1.0);
  
  /// Button press: ease-out (Must end before finger lifts—feels instant)
  static const Cubic buttonPress = Curves.easeOut;
  
  /// Selection toggle: ease-in-out (Use opacity fade + 4pt scale bump)
  static const Cubic selectionToggle = Curves.easeInOut;
  
  /// Standard spring configuration with optimal damping ratio (0.7-0.85)
  static const SpringDescription standardSpring = SpringDescription(
    mass: 1.0,
    stiffness: 500.0,
    damping: 25.0, // Results in ~0.75 damping ratio
  );
  
  /// Error shake spring with specific damping ratio (0.45)
  static const SpringDescription errorShakeSpring = SpringDescription(
    mass: 1.0,
    stiffness: 500.0,
    damping: 15.0, // Results in ~0.45 damping ratio
  );
} 