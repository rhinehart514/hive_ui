import 'package:flutter/material.dart';
import 'animation_constants.dart';

/// Utility class providing entrance animation widgets that follow HIVE's design language
class EntranceAnimations {
  /// Creates a staggered fade-in animation for a list of widgets
  /// 
  /// [children] - The list of widgets to animate
  /// [delay] - Delay before animations start
  /// [itemDelay] - Delay between each item's animation
  /// [duration] - Duration of each animation
  /// [curve] - Animation curve to use
  /// [direction] - Direction of the entrance (bottom, left, right, top)
  static List<Widget> staggeredFadeIn({
    required List<Widget> children,
    Duration delay = const Duration(milliseconds: 100),
    Duration itemDelay = const Duration(milliseconds: 50),
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOut,
    EntranceDirection direction = EntranceDirection.bottom,
  }) {
    return List.generate(
      children.length,
      (index) {
        final itemDelayDuration = Duration(
          milliseconds: delay.inMilliseconds + (index * itemDelay.inMilliseconds),
        );
        
        return FadeSlideTransition(
          delay: itemDelayDuration,
          duration: duration,
          curve: curve,
          direction: direction,
          child: children[index],
        );
      },
    );
  }

  /// Creates a crossfade animation for switching between widgets
  /// 
  /// [current] - Current widget to display
  /// [previous] - Previous widget to fade out
  /// [duration] - Duration of the crossfade animation
  static Widget crossFade({
    required Widget current,
    Widget? previous,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return AnimatedSwitcher(
      duration: duration,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: current,
    );
  }
}

/// Represents the direction of entrance animations
enum EntranceDirection {
  /// Animation enters from bottom
  bottom,
  
  /// Animation enters from left
  left,
  
  /// Animation enters from right
  right,
  
  /// Animation enters from top
  top,
}

/// A widget that combines fade and slide transitions for entrances
class FadeSlideTransition extends StatefulWidget {
  /// The child widget to animate
  final Widget child;
  
  /// Delay before animation starts
  final Duration delay;
  
  /// Duration of the animation
  final Duration duration;
  
  /// Animation curve
  final Curve curve;
  
  /// Direction of the entrance
  final EntranceDirection direction;
  
  /// Distance to slide from (in logical pixels)
  final double slideOffset;

  /// Creates a FadeSlideTransition widget
  const FadeSlideTransition({
    Key? key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOut,
    this.direction = EntranceDirection.bottom,
    this.slideOffset = 20.0,
  }) : super(key: key);

  @override
  State<FadeSlideTransition> createState() => _FadeSlideTransitionState();
}

class _FadeSlideTransitionState extends State<FadeSlideTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    // Calculate slide offset based on direction
    final Offset beginOffset = _getOffsetFromDirection();
    
    _slideAnimation = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    // Start animation after delay
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  Offset _getOffsetFromDirection() {
    switch (widget.direction) {
      case EntranceDirection.bottom:
        return Offset(0, widget.slideOffset / 100);
      case EntranceDirection.top:
        return Offset(0, -widget.slideOffset / 100);
      case EntranceDirection.left:
        return Offset(-widget.slideOffset / 100, 0);
      case EntranceDirection.right:
        return Offset(widget.slideOffset / 100, 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// A widget that animates its child with a scale and fade effect
class ScaleFadeTransition extends StatefulWidget {
  /// The child widget to animate
  final Widget child;
  
  /// Delay before animation starts
  final Duration delay;
  
  /// Duration of the animation
  final Duration duration;
  
  /// Animation curve
  final Curve curve;
  
  /// Initial scale value
  final double beginScale;

  /// Creates a ScaleFadeTransition widget
  const ScaleFadeTransition({
    Key? key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 350),
    this.curve = AnimationConstants.interactiveCurve,
    this.beginScale = 0.95,
  }) : super(key: key);

  @override
  State<ScaleFadeTransition> createState() => _ScaleFadeTransitionState();
}

class _ScaleFadeTransitionState extends State<ScaleFadeTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    _scaleAnimation = Tween<double>(
      begin: widget.beginScale,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    // Start animation after delay
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
} 