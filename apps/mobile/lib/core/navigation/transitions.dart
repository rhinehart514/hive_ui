import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'dart:math';

/// Types of navigation feedback
enum NavigationFeedbackType {
  pageTransition,
  tabChange,
  modalOpen,
  modalClose,
  modalDismiss,
  error,
}

/// Navigation transition types for cleaner API
enum TransitionType {
  cupertinoPush,
  cupertinoModal,
  cupertinoFullscreenModal,
  fade,
  slideUp,
  slideLeft,
  brandedSplash,
}

/// Utility class for navigation transitions and feedback
class NavigationTransitions {
  const NavigationTransitions._();

  /// Apply haptic feedback based on navigation type
  static void applyNavigationFeedback({
    NavigationFeedbackType type = NavigationFeedbackType.pageTransition,
  }) {
    try {
      switch (type) {
        case NavigationFeedbackType.pageTransition:
          HapticFeedback.selectionClick();
          break;
        case NavigationFeedbackType.tabChange:
          HapticFeedback.lightImpact();
          break;
        case NavigationFeedbackType.modalOpen:
          HapticFeedback.mediumImpact();
          break;
        case NavigationFeedbackType.modalClose:
          HapticFeedback.lightImpact();
          break;
        case NavigationFeedbackType.modalDismiss:
          HapticFeedback.lightImpact();
          break;
        case NavigationFeedbackType.error:
          HapticFeedback.mediumImpact();
          break;
      }
      // Log navigation feedback
      debugPrint('Applied navigation feedback: $type');
    } catch (e) {
      // Fail silently if haptic feedback fails
      debugPrint('Failed to apply haptic feedback: $e');
    }
  }

  /// Build a page transition with enhanced Apple-style animation including subtle fade
  static CustomTransitionPage<T> buildAppleTransition<T>({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
    TransitionType type = TransitionType.cupertinoPush,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Use different transitions based on type
        switch (type) {
          case TransitionType.cupertinoPush:
            return _buildCupertinoPushTransition(
                animation, secondaryAnimation, child);
          case TransitionType.cupertinoModal:
            return _buildCupertinoModalTransition(
                animation, secondaryAnimation, child);
          case TransitionType.cupertinoFullscreenModal:
            return _buildCupertinoFullscreenModalTransition(
                animation, secondaryAnimation, child);
          case TransitionType.fade:
            return _buildFadeTransition(animation, child);
          case TransitionType.slideUp:
            return _buildSlideUpTransition(
                animation, secondaryAnimation, child);
          case TransitionType.slideLeft:
            return _buildSlideLeftTransition(
                animation, secondaryAnimation, child);
          case TransitionType.brandedSplash:
            return _buildBrandedSplashTransition(
                animation, secondaryAnimation, child);
        }
      },
      // Updated durations to match iOS
      transitionDuration: type == TransitionType.cupertinoModal || 
                         type == TransitionType.cupertinoFullscreenModal
          ? const Duration(milliseconds: 500)  // Modal presentations are slightly longer
          : const Duration(milliseconds: 350), // Standard push transitions
      // Reverse transitions are slightly faster
      reverseTransitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// Creates the iOS-style push navigation transition (horizontal slide with fade and parallax)
  static Widget _buildCupertinoPushTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Define the primary animation curves
    const begin = Offset(1.0, 0.0);
    const end = Offset.zero;
    const curve = Curves.easeOutCubic;

    // Create the slide animation for the new page
    final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
    final slideAnimation = animation.drive(tween);

    // Create a parallax effect for the previous page
    final parallaxTween =
        Tween(begin: Offset.zero, end: const Offset(-0.3, 0.0))
            .chain(CurveTween(curve: Curves.easeOutCubic));
    final parallaxAnimation = secondaryAnimation.drive(parallaxTween);

    // Create fade animation with subtle delay
    final fadeAnimation = Tween(begin: 0.0, end: 1.0)
        .chain(CurveTween(
            curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic)))
        .animate(animation);

    // Create shadow animation
    final shadowAnimation = Tween(begin: 0.0, end: 20.0)
        .chain(CurveTween(
            curve: const Interval(0.0, 0.8, curve: Curves.easeInOut)))
        .animate(animation);

    // Apply parallax effect to the entire stack
    return SlideTransition(
      position: parallaxAnimation,
      child: Stack(
        children: [
          // The new page slides in with shadow and fade
          AnimatedBuilder(
            animation: shadowAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: shadowAnimation.value,
                      offset: const Offset(-5, 0),
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: SlideTransition(
              position: slideAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Creates the iOS-style modal sheet transition (slide up from bottom)
  static Widget _buildCupertinoModalTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Define the primary animation with spring curve
    const begin = Offset(0.0, 1.0);
    const end = Offset.zero;
    
    // Create the slide animation with spring physics
    final slideAnimation = CurvedAnimation(
      parent: animation,
      curve: const SpringCurve(
        mass: 1.0,
        stiffness: 1000.0,
        damping: 500.0,
      ),
    );

    final offsetAnimation = Tween(begin: begin, end: end).animate(slideAnimation);

    // Create a dimming effect for the background with subtle blur
    final fadeAnimation = Tween(begin: 0.0, end: 0.5)
        .chain(CurveTween(curve: Curves.easeOutCubic))
        .animate(animation);

    // Create scale effect for background
    final scaleAnimation = Tween(begin: 1.0, end: 0.92)
        .chain(CurveTween(curve: Curves.easeOutCubic))
        .animate(animation);

    return Stack(
      children: [
        // Scale and dim the background
        ScaleTransition(
          scale: scaleAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: Container(color: Colors.black),
          ),
        ),
        // The modal slides in from the bottom with spring physics
        SlideTransition(
          position: offsetAnimation,
          child: child,
        ),
      ],
    );
  }

  /// Creates the iOS-style fullscreen modal transition (slide up with scaling background)
  static Widget _buildCupertinoFullscreenModalTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Define the primary animation
    const begin = Offset(0.0, 1.0);
    const end = Offset.zero;
    const curve = Curves.easeOutCubic;

    // Create the slide animation
    final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
    final slideAnimation = animation.drive(tween);

    // Create a scaling effect for the background
    final scaleAnimation = Tween(begin: 1.0, end: 0.92)
        .chain(CurveTween(curve: Curves.easeOutCubic))
        .animate(animation);

    // Create a dimming effect for the background
    final darkenAnimation = Tween(begin: 0.0, end: 0.1)
        .chain(CurveTween(curve: Curves.easeOutCubic))
        .animate(animation);

    // Apply combined animation
    return Stack(
      children: [
        // Scale and dim the background
        AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            return ScaleTransition(
              scale: scaleAnimation,
              child: Container(
                color: Colors.black.withOpacity(darkenAnimation.value),
              ),
            );
          },
        ),
        // The new page slides in
        SlideTransition(
          position: slideAnimation,
          child: child,
        ),
      ],
    );
  }

  /// Creates a simple fade transition
  static Widget _buildFadeTransition(
    Animation<double> animation,
    Widget child,
  ) {
    final fadeAnimation = Tween(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(animation);

    return FadeTransition(
      opacity: fadeAnimation,
      child: child,
    );
  }

  /// Special tab transition for smooth tab switching with subtle motion
  static Widget buildTabTransition({
    required BuildContext context,
    required int previousIndex,
    required int currentIndex,
    required Widget child,
  }) {
    // Calculate the direction of the transition
    final isForward = currentIndex > previousIndex;
    final transitionOffset = isForward ? 0.02 : -0.02;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: transitionOffset, end: 0.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, value * MediaQuery.of(context).size.height),
          child: Opacity(
            opacity: 1.0 - value.abs() * 3, // Subtle fade
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  /// Creates the slide up transition
  static Widget _buildSlideUpTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(0.0, 1.0);
    const end = Offset.zero;
    final tween = Tween(begin: begin, end: end)
        .chain(CurveTween(curve: Curves.easeOutCubic));
    final offsetAnimation = animation.drive(tween);

    return SlideTransition(
      position: offsetAnimation,
      child: child,
    );
  }

  /// Creates the slide left transition
  static Widget _buildSlideLeftTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(1.0, 0.0);
    const end = Offset.zero;
    final tween = Tween(begin: begin, end: end)
        .chain(CurveTween(curve: Curves.easeOutCubic));
    final offsetAnimation = animation.drive(tween);

    return SlideTransition(
      position: offsetAnimation,
      child: child,
    );
  }

  /// Creates the branded splash transition
  static Widget _buildBrandedSplashTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Scale animation for the hexagon
    final scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 15.0, // Large enough to cover the screen
    ).animate(CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));

    // Fade animation for the content
    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    ));

    return Stack(
      children: [
        // Growing hexagon splash in the center
        Center(
          child: AnimatedBuilder(
            animation: scaleAnimation,
            builder: (context, _) {
              return Container(
                width: MediaQuery.of(context).size.width * scaleAnimation.value,
                height:
                    MediaQuery.of(context).size.width * scaleAnimation.value,
                decoration: BoxDecoration(
                  color: AppColors.black,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.yellow,
                    width: 2.0,
                  ),
                ),
              );
            },
          ),
        ),

        // Fade in the actual page content
        FadeTransition(
          opacity: fadeAnimation,
          child: child,
        ),
      ],
    );
  }
}

/// Custom spring curve for more natural iOS-like animations
class SpringCurve extends Curve {
  final double mass;
  final double stiffness;
  final double damping;

  const SpringCurve({
    this.mass = 1.0,
    this.stiffness = 1000.0,
    this.damping = 500.0,
  });

  @override
  double transform(double t) {
    final oscillation = exp(-damping * t / (2 * mass));
    final frequency = sqrt(stiffness / mass - pow(damping / (2 * mass), 2));
    return 1.0 - oscillation * cos(frequency * t);
  }
}
