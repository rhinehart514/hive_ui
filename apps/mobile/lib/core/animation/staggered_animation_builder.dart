import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'; // Added for Ticker and TickerProvider
import '../animation/animation_constants.dart';

/// Helper class to build staggered animations for lists of items
/// Used primarily for feed content to create an engaging loading experience
class StaggeredAnimationBuilder {
  /// Wraps a list item with a staggered animation
  /// [index] The item's position in the list
  /// [child] The widget to be animated
  /// [direction] Optional direction of the animation
  /// Returns an animated widget
  static Widget buildAnimatedItem({
    required int index,
    required Widget child,
    StaggerDirection direction = StaggerDirection.bottomToTop,
  }) {
    return AnimatedBuilder(
      animation: _getStaggeredAnimation(index),
      builder: (context, _) {
        final Animation<double> animation = _getStaggeredAnimation(index);
        
        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
            ),
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: _getOffsetForDirection(direction),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: const Interval(0.0, 0.5, curve: AnimationConstants.standardCurve),
              ),
            ),
            child: child,
          ),
        );
      },
    );
  }
  
  /// Creates an animation controller for a specific item based on its index
  /// Automatically handles staggered timing with appropriate delays
  static Animation<double> _getStaggeredAnimation(int index) {
    // Using a globally accessible animation controller or provider would be better
    // This is a simplified version for illustration
    final controller = AnimationController(
      vsync: _FakeTickerProvider(),
      duration: AnimationConstants.medium,
    );
    
    // Delay based on item position
    Future.delayed(
      AnimationConstants.staggerDelay * index,
      () => controller.forward(),
    );
    
    return controller;
  }
  
  /// Returns the appropriate starting offset based on animation direction
  static Offset _getOffsetForDirection(StaggerDirection direction) {
    switch (direction) {
      case StaggerDirection.bottomToTop:
        return const Offset(0.0, 0.25);
      case StaggerDirection.topToBottom:
        return const Offset(0.0, -0.25);
      case StaggerDirection.rightToLeft:
        return const Offset(0.25, 0.0);
      case StaggerDirection.leftToRight:
        return const Offset(-0.25, 0.0);
      case StaggerDirection.scale:
        return Offset.zero; // No offset for scale animation
    }
  }
}

/// Directions for staggered animations
enum StaggerDirection {
  bottomToTop,
  topToBottom,
  rightToLeft,
  leftToRight,
  scale,
}

/// Temporary ticker provider for illustration
/// In real implementation, use a StatefulWidget's TickerProviderStateMixin
class _FakeTickerProvider extends TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

/// Example usage (in a ListView.builder):
/// 
/// ListView.builder(
///   itemCount: items.length,
///   itemBuilder: (context, index) {
///     return StaggeredAnimationBuilder.buildAnimatedItem(
///       index: index,
///       child: YourCardWidget(item: items[index]),
///     );
///   },
/// ); 