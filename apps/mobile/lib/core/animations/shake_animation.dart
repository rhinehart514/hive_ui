import 'dart:math';

import 'package:flutter/material.dart';

/// A widget that shakes its child horizontally when triggered.
///
/// Based on the pattern from: https://alitalhacoban.medium.com/add-error-shake-effect-to-textfields-flutter-7e8e549e96b5
class ShakeAnimation extends StatefulWidget {
  /// The widget below this widget in the tree.
  final Widget child;

  /// The horizontal distance the widget will travel during the shake.
  final double shakeOffset;

  /// The number of times the widget will shake back and forth.
  final int shakeCount;

  /// The total duration of the shake animation.
  final Duration shakeDuration;

  /// Creates a ShakeAnimation widget.
  ///
  /// Requires a [GlobalKey<ShakeAnimationState>] to trigger the shake externally
  /// via `key.currentState?.shake()`.
  const ShakeAnimation({
    required Key key, // Key is required to trigger the shake
    required this.child,
    this.shakeOffset = 10.0, // Default offset
    this.shakeCount = 3,     // Default count (matches HIVE spec)
    this.shakeDuration = const Duration(milliseconds: 400), // Default duration (matches HIVE spec)
  }) : super(key: key);

  @override
  ShakeAnimationState createState() => ShakeAnimationState();
}

/// State for the ShakeAnimation widget, manages the animation controller.
/// Exposes the [shake] method to trigger the animation.
class ShakeAnimationState extends State<ShakeAnimation> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.shakeDuration,
      vsync: this,
    );
    _controller.addStatusListener(_updateStatus);
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_updateStatus);
    _controller.dispose();
    super.dispose();
  }

  void _updateStatus(AnimationStatus status) {
    // Reset the controller when the animation completes
    if (status == AnimationStatus.completed) {
      _controller.reset();
    }
  }

  /// Triggers the shake animation.
  void shake() {
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        // Calculate the horizontal offset using a sine wave
        final sineValue = sin(widget.shakeCount * 2 * pi * _controller.value);
        return Transform.translate(
          // Apply the horizontal translation based on the sine wave and offset
          offset: Offset(sineValue * widget.shakeOffset, 0),
          child: child,
        );
      },
    );
  }
} 