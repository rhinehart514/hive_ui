import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/swipe_detector.dart';

/// Extension to add swipe navigation to widgets with paged content
extension SwipeNavigationExtension on Widget {
  /// Wraps a widget with horizontal swipe detection for navigating between pages
  Widget addHorizontalSwipeNavigation({
    required VoidCallback onSwipeLeft,
    required VoidCallback onSwipeRight,
    double swipeThreshold = 50.0,
    bool enableHapticFeedback = true,
    HapticFeedbackType hapticFeedbackType = HapticFeedbackType.medium,
  }) {
    return SwipeDetector(
      onSwipeLeft: onSwipeLeft,
      onSwipeRight: onSwipeRight,
      enableVerticalSwipes: false,
      swipeThreshold: swipeThreshold,
      enableHapticFeedback: enableHapticFeedback,
      hapticFeedbackType: hapticFeedbackType,
      child: this,
    );
  }

  /// Connects a widget to a PageController for swipe navigation
  Widget addPageSwipeNavigation({
    required PageController pageController,
    required int pageCount,
    bool enableHapticFeedback = true,
    HapticFeedbackType hapticFeedbackType = HapticFeedbackType.medium,
  }) {
    return SwipeDetector(
      onSwipeLeft: () {
        if (pageController.page!.round() < pageCount - 1) {
          if (enableHapticFeedback) {
            HapticFeedback.mediumImpact();
          }
          pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      },
      onSwipeRight: () {
        if (pageController.page!.round() > 0) {
          if (enableHapticFeedback) {
            HapticFeedback.mediumImpact();
          }
          pageController.previousPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      },
      enableVerticalSwipes: false,
      swipeThreshold: 50.0,
      enableHapticFeedback: enableHapticFeedback,
      hapticFeedbackType: hapticFeedbackType,
      child: this,
    );
  }
}
