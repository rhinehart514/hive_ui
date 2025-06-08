import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Enum for haptic feedback types
enum HapticFeedbackType { light, medium, heavy, selection, vibrate }

/// A widget that detects swipe gestures and provides haptic feedback
/// for a more natural and frictionless user experience
class SwipeDetector extends StatefulWidget {
  /// Child widget to wrap with swipe detection
  final Widget child;

  /// Function called when user swipes right
  final VoidCallback? onSwipeRight;

  /// Function called when user swipes left
  final VoidCallback? onSwipeLeft;

  /// Function called when user swipes up
  final VoidCallback? onSwipeUp;

  /// Function called when user swipes down
  final VoidCallback? onSwipeDown;

  /// Minimum distance to trigger swipe detection
  final double swipeThreshold;

  /// Control whether to provide haptic feedback on detection
  final bool enableHapticFeedback;

  /// Type of haptic feedback to use
  final HapticFeedbackType hapticFeedbackType;

  /// Whether to enable horizontal swipes
  final bool enableHorizontalSwipes;

  /// Whether to enable vertical swipes
  final bool enableVerticalSwipes;

  const SwipeDetector({
    super.key,
    required this.child,
    this.onSwipeRight,
    this.onSwipeLeft,
    this.onSwipeUp,
    this.onSwipeDown,
    this.swipeThreshold = 20.0,
    this.enableHapticFeedback = true,
    this.hapticFeedbackType = HapticFeedbackType.light,
    this.enableHorizontalSwipes = true,
    this.enableVerticalSwipes = true,
  });

  @override
  State<SwipeDetector> createState() => _SwipeDetectorState();
}

class _SwipeDetectorState extends State<SwipeDetector> {
  Offset _dragStartPosition = Offset.zero;
  bool _isDragging = false;

  // Used to prevent accidental triggers
  bool _hasTriggeredAction = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart:
          widget.enableHorizontalSwipes ? _onDragStart : null,
      onHorizontalDragUpdate:
          widget.enableHorizontalSwipes ? _onHorizontalDragUpdate : null,
      onHorizontalDragEnd: widget.enableHorizontalSwipes ? _onDragEnd : null,
      onVerticalDragStart: widget.enableVerticalSwipes ? _onDragStart : null,
      onVerticalDragUpdate:
          widget.enableVerticalSwipes ? _onVerticalDragUpdate : null,
      onVerticalDragEnd: widget.enableVerticalSwipes ? _onDragEnd : null,
      child: widget.child,
    );
  }

  void _onDragStart(DragStartDetails details) {
    setState(() {
      _dragStartPosition = details.localPosition;
      _isDragging = true;
      _hasTriggeredAction = false;
    });
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_isDragging || _hasTriggeredAction) return;

    final dragDistance = details.localPosition.dx - _dragStartPosition.dx;
    final dragAbsDistance = dragDistance.abs();

    if (dragAbsDistance >= widget.swipeThreshold) {
      _hasTriggeredAction = true;

      if (dragDistance > 0) {
        // Swipe right
        if (widget.onSwipeRight != null) {
          _triggerFeedback();
          widget.onSwipeRight!();
        }
      } else {
        // Swipe left
        if (widget.onSwipeLeft != null) {
          _triggerFeedback();
          widget.onSwipeLeft!();
        }
      }
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (!_isDragging || _hasTriggeredAction) return;

    final dragDistance = details.localPosition.dy - _dragStartPosition.dy;
    final dragAbsDistance = dragDistance.abs();

    if (dragAbsDistance >= widget.swipeThreshold) {
      _hasTriggeredAction = true;

      if (dragDistance > 0) {
        // Swipe down
        if (widget.onSwipeDown != null) {
          _triggerFeedback();
          widget.onSwipeDown!();
        }
      } else {
        // Swipe up
        if (widget.onSwipeUp != null) {
          _triggerFeedback();
          widget.onSwipeUp!();
        }
      }
    }
  }

  void _onDragEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
  }

  void _triggerFeedback() {
    if (!widget.enableHapticFeedback) return;

    switch (widget.hapticFeedbackType) {
      case HapticFeedbackType.light:
        HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticFeedbackType.heavy:
        HapticFeedback.heavyImpact();
        break;
      case HapticFeedbackType.selection:
        HapticFeedback.selectionClick();
        break;
      case HapticFeedbackType.vibrate:
        HapticFeedback.vibrate();
        break;
    }
  }
}

/// Extension to easily add swipe to go back navigation
extension SwipeNavigationExtension on Widget {
  /// Adds swipe right to go back navigation to a widget
  Widget addSwipeToGoBack(BuildContext context) {
    return SwipeDetector(
      onSwipeRight: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      enableVerticalSwipes: false,
      child: this,
    );
  }
}
