import 'package:flutter/material.dart';
import '../animation/animation_constants.dart';

/// Standardized page transitions for HIVE
/// Ensures consistent navigation experience throughout the app
class HivePageTransition extends PageRouteBuilder {
  final Widget page;
  final TransitionType transitionType;

  HivePageTransition({
    required this.page,
    this.transitionType = TransitionType.rightToLeft,
  }) : super(
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              page,
          transitionDuration: AnimationConstants.medium,
          reverseTransitionDuration: AnimationConstants.short,
        );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curve = CurvedAnimation(
      parent: animation,
      curve: AnimationConstants.standardCurve,
    );

    switch (transitionType) {
      case TransitionType.fade:
        return FadeTransition(opacity: curve, child: child);

      case TransitionType.rightToLeft:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curve),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.3, end: 1.0).animate(curve),
            child: child,
          ),
        );

      case TransitionType.leftToRight:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1.0, 0.0),
            end: Offset.zero,
          ).animate(curve),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.3, end: 1.0).animate(curve),
            child: child,
          ),
        );

      case TransitionType.bottomToTop:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(curve),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.3, end: 1.0).animate(curve),
            child: child,
          ),
        );

      case TransitionType.scale:
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.95,
            end: 1.0,
          ).animate(curve),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curve),
            child: child,
          ),
        );

      default:
        return FadeTransition(opacity: curve, child: child);
    }
  }
}

// Supported transition types
enum TransitionType {
  fade,
  rightToLeft,
  leftToRight,
  bottomToTop,
  scale,
} 