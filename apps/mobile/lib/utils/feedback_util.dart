import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode

/// A utility class that provides consistent haptic and visual feedback
/// throughout the app for a frictionless user experience
class FeedbackUtil {
  /// Private constructor to prevent instantiation
  FeedbackUtil._();

  /// Provides light haptic feedback, typically for button taps.
  static Future<void> lightTap() async {
    if (kDebugMode) {
      debugPrint('HAPTIC: Attempting lightTap');
    }
    try {
      await HapticFeedback.lightImpact();
    } catch (e) {
      // Handle potential errors, e.g., on platforms without haptics
      if (kDebugMode) {
        debugPrint('HAPTIC: lightTap failed - $e');
      }
    }
  }

  /// Provides medium haptic feedback, typically for deep presses or significant actions.
  static Future<void> mediumTap() async {
    if (kDebugMode) {
      debugPrint('HAPTIC: Attempting mediumTap');
    }
    try {
      await HapticFeedback.mediumImpact();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('HAPTIC: mediumTap failed - $e');
      }
    }
  }

  /// Provides haptic feedback indicating a successful operation.
  static Future<void> successHaptic() async {
    if (kDebugMode) {
      debugPrint('HAPTIC: Attempting success');
    }
    try {
      await HapticFeedback.heavyImpact(); // Use heavy impact as a proxy for success
      // Or potentially a custom pattern if available/needed
    } catch (e) {
      if (kDebugMode) {
        debugPrint('HAPTIC: successHaptic failed - $e');
      }
    }
  }

  /// Provides haptic feedback indicating an error or alert (Dual tap).
  /// Matches HIVE spec: notificationError
  static Future<void> errorHaptic() async {
    if (kDebugMode) {
      debugPrint('HAPTIC: Attempting error (Dual Tap)');
    }
    try {
      // Simulate dual tap: vibrate - short pause - vibrate
      // Note: HapticFeedback doesn't directly support dual tap patterns.
      // We simulate it with two heavy impacts with a small delay.
      // This might not feel identical to system notifications on all platforms.
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 50)); // Short delay
      await HapticFeedback.heavyImpact();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('HAPTIC: errorHaptic failed - $e');
      }
    }
  }

  /// Provides haptic feedback specifically for standard button taps.
  /// Currently maps to lightTap, can be customized later if needed.
  static Future<void> buttonTap() async {
    // For now, standard button taps use light impact
    await lightTap();
  }

  /// Used for toggle actions (switching UI elements on/off)
  static void toggle() {
    HapticFeedback.selectionClick();
  }

  /// Used for successful operations
  static void success({BuildContext? context}) {
    HapticFeedback.lightImpact();

    if (context != null) {
      _showSuccessAnimation(context);
    }
  }

  /// Used for error or warning situations
  static void error({BuildContext? context}) {
    HapticFeedback.heavyImpact();

    if (context != null) {
      _showErrorAnimation(context);
    }
  }

  /// Used for navigation events
  static void navigate() {
    HapticFeedback.mediumImpact();
  }

  /// Used for selection or toggling UI elements
  static void selection() {
    HapticFeedback.selectionClick();
  }

  /// Used for sliding/swipe operations
  static void slide() {
    HapticFeedback.lightImpact();
  }

  /// Used for card press actions
  static void cardPress() {
    HapticFeedback.mediumImpact();
  }

  /// Used for long press actions
  static void longPress() {
    HapticFeedback.heavyImpact();
  }

  /// Used for dismissing/deleting items
  static void dismiss() {
    HapticFeedback.mediumImpact();
  }

  /// Shows a subtle success animation overlay
  static void _showSuccessAnimation(BuildContext context) {
    // Use the Overlay system to show a brief success animation
    final overlayState = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) {
        return const Positioned(
          bottom: 50.0,
          left: 0,
          right: 0,
          child: Center(
            child: _FeedbackAnimationWidget(
              color: Colors.green,
              icon: Icons.check_circle_outline,
            ),
          ),
        );
      },
    );

    overlayState.insert(overlayEntry);

    // Remove after animation completes
    Future.delayed(const Duration(milliseconds: 1500), () {
      overlayEntry.remove();
    });
  }

  /// Shows a subtle error animation overlay
  static void _showErrorAnimation(BuildContext context) {
    // Use the Overlay system to show a brief error animation
    final overlayState = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) {
        return const Positioned(
          bottom: 50.0,
          left: 0,
          right: 0,
          child: Center(
            child: _FeedbackAnimationWidget(
              color: Colors.red,
              icon: Icons.error_outline,
            ),
          ),
        );
      },
    );

    overlayState.insert(overlayEntry);

    // Remove after animation completes
    Future.delayed(const Duration(milliseconds: 1500), () {
      overlayEntry.remove();
    });
  }

  /// Shows a toast message with optional feedback
  static void showToast({
    required BuildContext context,
    required String message,
    bool isError = false,
    bool isSuccess = false,
    Duration duration = const Duration(seconds: 2),
  }) {
    if (isError) {
      error();
    } else if (isSuccess) {
      success();
    } else {
      selection();
    }

    final overlayState = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          bottom: 50.0,
          left: 20.0,
          right: 20.0,
          child: SafeArea(
            child: _FeedbackToastWidget(
              message: message,
              isError: isError,
              isSuccess: isSuccess,
            ),
          ),
        );
      },
    );

    overlayState.insert(overlayEntry);

    // Remove after duration
    Future.delayed(duration, () {
      overlayEntry.remove();
    });
  }
}

/// A private widget for feedback animations
class _FeedbackAnimationWidget extends StatefulWidget {
  final Color color;
  final IconData icon;

  const _FeedbackAnimationWidget({
    required this.color,
    required this.icon,
  });

  @override
  _FeedbackAnimationWidgetState createState() =>
      _FeedbackAnimationWidgetState();
}

class _FeedbackAnimationWidgetState extends State<_FeedbackAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
        reverseCurve: const Interval(0.7, 1.0, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
        reverseCurve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // Auto-reverse after delay
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.icon,
                    color: widget.color,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A private widget for toast messages
class _FeedbackToastWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final bool isSuccess;

  const _FeedbackToastWidget({
    required this.message,
    this.isError = false,
    this.isSuccess = false,
  });

  @override
  _FeedbackToastWidgetState createState() => _FeedbackToastWidgetState();
}

class _FeedbackToastWidgetState extends State<_FeedbackToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.forward();

    // Start reverse animation shortly before overlay is removed
    Future.delayed(const Duration(milliseconds: 1700), () {
      if (mounted) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color statusColor = widget.isError
        ? Colors.red
        : (widget.isSuccess ? Colors.green : Colors.blue);

    final IconData statusIcon = widget.isError
        ? Icons.error_outline
        : (widget.isSuccess ? Icons.check_circle_outline : Icons.info_outline);

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                statusIcon,
                color: statusColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
