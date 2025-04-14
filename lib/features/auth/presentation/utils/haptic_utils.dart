import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'animation_constants.dart';

/// Utility class for standardized haptic feedback throughout the app
/// Following Apple's Human Interface Guidelines for haptics
class HapticUtils {
  /// Provides light impact haptic feedback
  /// Use for subtle interactions like:
  /// - Selection changes
  /// - Minor UI transitions
  /// - Small control value changes
  static void lightImpact() {
    HapticFeedback.lightImpact();
  }
  
  /// Provides medium impact haptic feedback
  /// Use for standard interactions like:
  /// - Button presses
  /// - Tab changes
  /// - Toggling UI elements
  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }
  
  /// Provides heavy impact haptic feedback
  /// Use for significant interactions like:
  /// - Completing major actions
  /// - Significant UI changes
  /// - Error states
  static void heavyImpact() {
    HapticFeedback.heavyImpact();
  }
  
  /// Provides selection click haptic feedback
  /// Use specifically for:
  /// - Selection interactions
  /// - Dropdown selections
  /// - Radio button/checkbox changes
  static void selectionClick() {
    HapticFeedback.selectionClick();
  }

  /// Provides vibration pattern haptic feedback
  /// Use for custom notifications or special events
  /// @param duration - duration in milliseconds
  static void vibrate({int duration = 100}) {
    HapticFeedback.vibrate();
  }

  /// Sequential haptic feedback for success state
  /// Creates a pleasing double-tap success pattern
  static void successFeedback() {
    HapticFeedback.lightImpact();
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.mediumImpact();
    });
  }

  /// Sequential haptic feedback for error state
  /// Creates a more noticeable error pattern
  static void errorFeedback() {
    HapticFeedback.mediumImpact();
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.heavyImpact();
    });
  }
  
  /// Sequential haptic feedback for warning state
  /// Creates a pattern suitable for warnings
  static void warningFeedback() {
    HapticFeedback.lightImpact();
    Future.delayed(const Duration(milliseconds: 150), () {
      HapticFeedback.lightImpact();
    });
  }
  
  /// Provides haptic feedback for page transitions
  /// Different feedback based on direction of navigation
  static void pageTransition({bool forward = true}) {
    if (forward) {
      mediumImpact();
    } else {
      lightImpact();
    }
  }
  
  /// Shows a consistent error snackbar with appropriate haptic feedback
  static void showErrorSnackBar(BuildContext context, String message) {
    errorFeedback();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: AnimationConstants.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
} 