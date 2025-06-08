import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Navigation transitions inspired by Apple's fluid UI
class NavigationTransitions {
  /// Provides a smooth page transition with scale and fade effects
  static Widget buildPageTransition({
    required BuildContext context,
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
  }) {
    // The primary animation (entering page)
    final primaryCurve = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeIn,
    );

    // The secondary animation (exiting page)
    final secondaryCurve = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
    );

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.08),
        end: Offset.zero,
      ).animate(primaryCurve),
      child: FadeTransition(
        opacity: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(primaryCurve),
        child: FadeTransition(
          opacity: Tween<double>(
            begin: 1.0,
            end: 0.5,
          ).animate(secondaryCurve),
          child: child,
        ),
      ),
    );
  }

  /// Provides a horizontal slide transition (for tab changes)
  static Widget buildTabTransition({
    required BuildContext context,
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
    required bool reverse,
  }) {
    // Determine direction based on reverse flag
    final slideBegin = reverse ? const Offset(-0.2, 0) : const Offset(0.2, 0);

    // The primary animation (entering page)
    final primaryCurve = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );

    return SlideTransition(
      position: Tween<Offset>(
        begin: slideBegin,
        end: Offset.zero,
      ).animate(primaryCurve),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  /// Apply haptic feedback based on navigation action
  static void applyNavigationFeedback({
    required NavigationFeedbackType type,
  }) {
    switch (type) {
      case NavigationFeedbackType.tabChange:
        HapticFeedback.selectionClick();
        break;
      case NavigationFeedbackType.pageTransition:
        HapticFeedback.lightImpact();
        break;
      case NavigationFeedbackType.modalPresent:
        HapticFeedback.mediumImpact();
        break;
      case NavigationFeedbackType.modalDismiss:
        HapticFeedback.selectionClick();
        break;
      case NavigationFeedbackType.error:
        HapticFeedback.vibrate();
        break;
    }
  }
}

/// Types of navigation actions for haptic feedback
enum NavigationFeedbackType {
  tabChange, // Light feedback for changing tabs
  pageTransition, // Light impact for page transitions
  modalPresent, // Medium impact for modal presentation
  modalDismiss, // Selection click for modal dismissal
  error, // Vibration for error states
}

/// Page route that uses the custom transition animations
class ApplePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  @override
  final bool fullscreenDialog;

  ApplePageRoute({
    required this.page,
    this.fullscreenDialog = false,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return NavigationTransitions.buildPageTransition(
              context: context,
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            );
          },
          fullscreenDialog: fullscreenDialog,
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // On page change, apply subtle haptic feedback
    if (animation.status == AnimationStatus.forward) {
      NavigationTransitions.applyNavigationFeedback(
        type: fullscreenDialog
            ? NavigationFeedbackType.modalPresent
            : NavigationFeedbackType.pageTransition,
      );
    }

    return super
        .buildTransitions(context, animation, secondaryAnimation, child);
  }
}
