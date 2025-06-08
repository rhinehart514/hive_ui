import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/accessibility/accessibility_providers.dart';
import 'package:hive_ui/core/theme/animation_durations.dart';

/// Provides standardized physics-based animation utilities for HIVE UI.
/// Adheres to the motion standards defined in brand_aesthetic.md:
/// - Physics over tween
/// - Optimal damping ratio (0.7-0.85)
/// - Real-world physics simulation
class PhysicsAnimations {
  /// Default damping ratio for spring animations, providing a natural feel.
  /// Value chosen based on brand_aesthetic.md recommendations (0.7-0.85).
  static const double defaultDampingRatio = 0.8;

  /// Default stiffness for spring animations.
  static const double defaultStiffness = 180.0;

  /// Creates a standard spring simulation based on HIVE's motion guidelines.
  ///
  /// Uses the default damping ratio and stiffness.
  static SpringSimulation createDefaultSpringSimulation(
    double start, 
    double end, 
    double velocity
  ) {
    return SpringSimulation(
      SpringDescription(
        mass: 1,
        stiffness: defaultStiffness,
        damping: _dampingFromRatio(ratio: defaultDampingRatio, stiffness: defaultStiffness),
      ),
      start,
      end,
      velocity,
    );
  }

  /// Creates a custom spring simulation.
  static SpringSimulation createSpringSimulation({
    required double start,
    required double end,
    required double velocity,
    double mass = 1,
    double stiffness = defaultStiffness,
    double dampingRatio = defaultDampingRatio,
  }) {
    return SpringSimulation(
      SpringDescription(
        mass: mass,
        stiffness: stiffness,
        damping: _dampingFromRatio(ratio: dampingRatio, stiffness: stiffness),
      ),
      start,
      end,
      velocity,
    );
  }
  
  /// Utility to calculate damping value from damping ratio and stiffness.
  /// Formula: damping = 2 * sqrt(mass * stiffness) * dampingRatio
  /// Assuming mass = 1 for simplicity in UI animations.
  static double _dampingFromRatio({required double ratio, required double stiffness, double mass = 1}) {
    return ratio * 2.0 * sqrt(mass * stiffness);
  }

  /// Provides a standard physics-based animation controller.
  /// Adapts to reduced motion settings.
  /// Requires [AnimationDurations] to be passed, typically from Theme context.
  /// 
  /// Usage:
  /// ```dart
  /// late final AnimationController _controller;
  /// @override
  /// void initState() {
  ///   super.initState();
  ///   final durations = Theme.of(context).extension<AnimationDurations>()!;
  ///   _controller = PhysicsAnimations.createPhysicsController(this, ref, durations);
  ///   // ... use controller
  /// }
  /// ```
  static AnimationController createPhysicsController(
    TickerProvider vsync,
    WidgetRef ref, 
    AnimationDurations animationDurations,
    {Duration? duration}
  ) {
    final bool reduceMotion = ref.watch(reducedMotionProvider);
    final defaultDuration = animationDurations.contentSlide; 
    
    if (reduceMotion) {
      // Use a shorter, linear animation for reduced motion
      return AnimationController(
        vsync: vsync, 
        duration: duration ?? const Duration(milliseconds: 150), // Fast fade
      );
    } else {
      // Use default duration which implicitly uses spring physics
      // The actual simulation is applied when using _controller.animateWith(...) 
      return AnimationController(
        vsync: vsync, 
        duration: duration ?? defaultDuration, // Base duration for spring
      );
    }
  }

  /// Animates a controller using a standard spring simulation.
  /// Handles reduced motion automatically.
  ///
  /// ```dart
  /// PhysicsAnimations.animateWithSpring(
  ///   controller: _controller,
  ///   ref: ref,
  ///   targetValue: 1.0, // Target animation value
  /// );
  /// ```
  static void animateWithSpring({
    required AnimationController controller,
    required WidgetRef ref,
    required double targetValue,
    double velocity = 0.0,
    double stiffness = defaultStiffness,
    double dampingRatio = defaultDampingRatio,
  }) {
    final bool reduceMotion = ref.read(reducedMotionProvider);
    
    if (reduceMotion) {
      // Simple linear animation for reduced motion
      controller.animateTo(targetValue, curve: Curves.linear);
    } else {
      // Use spring simulation
      final simulation = createSpringSimulation(
        start: controller.value,
        end: targetValue,
        velocity: velocity,
        stiffness: stiffness,
        dampingRatio: dampingRatio,
      );
      controller.animateWith(simulation);
    }
  }
} 