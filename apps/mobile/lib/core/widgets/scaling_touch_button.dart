import 'package:flutter/material.dart';
import 'package:hive_ui/core/theme/app_colors.dart';
import 'package:hive_ui/utils/feedback_util.dart';

/// A button that scales down to 98% when pressed, following the HIVE brand guidelines.
/// 
/// It also provides haptic feedback on press and implements the proper animation curves,
/// background darkening, and a subtle glow effect on press.
class ScalingTouchButton extends StatefulWidget {
  /// The widget to display inside the button.
  final Widget child;

  /// Called when the button is tapped or activated.
  final VoidCallback? onTap;

  /// Whether the button is disabled.
  final bool disabled;

  /// Background color of the button, transparent by default.
  final Color? backgroundColor;

  /// Optional color that appears on focus
  final Color? focusColor;
  
  /// Optional color that appears on hover
  final Color? hoverColor;

  /// The duration of the scale animation (120ms per HIVE brand specs).
  final Duration animationDuration;

  /// The scale factor when pressed (0.98 per HIVE brand specs).
  final double pressedScale;

  /// The curve for the press animation (ease-out per HIVE brand specs).
  final Curve animationCurve;

  /// Optional border radius for the button.
  final BorderRadius? borderRadius;

  /// Whether to provide haptic feedback on press.
  final bool enableHapticFeedback;

  /// Creates a button that scales when pressed.
  /// 
  /// The [pressedScale] defaults to 0.98 as specified in the HIVE brand aesthetic guidelines.
  /// The [animationDuration] defaults to 120ms as specified in the guidelines.
  /// The [animationCurve] defaults to Curves.easeOut as specified in the guidelines.
  const ScalingTouchButton({
    super.key,
    required this.child,
    this.onTap,
    this.disabled = false,
    this.backgroundColor,
    this.focusColor,
    this.hoverColor,
    this.animationDuration = const Duration(milliseconds: 120),
    this.pressedScale = 0.98,
    this.animationCurve = Curves.easeOut,
    this.borderRadius,
    this.enableHapticFeedback = true,
  });

  @override
  State<ScalingTouchButton> createState() => _ScalingTouchButtonState();
}

class _ScalingTouchButtonState extends State<ScalingTouchButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  bool _isHovered = false;
  bool _isFocused = false;

  AnimationController? _pressAnimationController;
  Animation<double>? _pressAnimation;

  @override
  void initState() {
    super.initState();
    _pressAnimationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _pressAnimation = CurvedAnimation(
      parent: _pressAnimationController!,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pressAnimationController?.dispose();
    super.dispose();
  }

  Color _getBackgroundColor(BuildContext context) {
    final originalColor = widget.backgroundColor ?? Colors.transparent;
    final pressedColor = Color.lerp(originalColor, Colors.black, 0.15);

    final animationValue = _pressAnimation?.value ?? 0.0;

    return Color.lerp(originalColor, pressedColor, animationValue) ?? originalColor;
  }

  BoxDecoration _getBoxDecoration(BuildContext context) {
    final Color bgColor = _getBackgroundColor(context);

    final animationValue = _pressAnimation?.value ?? 0.0;
    // Glow Shadow properties - animate blur and spread
    final double glowOpacity = animationValue * 0.7; // Slightly more opacity for shadow glow
    final Color glowColor = AppColors.accentGold.withOpacity(glowOpacity);
    final double glowBlur = animationValue * 8.0; // Max blur radius of 8
    final double glowSpread = animationValue * 2.0; // Max spread radius of 2

    // Combine hover shadow and press glow shadow
    List<BoxShadow> shadows = [];

    // Add hover shadow if applicable
    if (_isHovered && widget.hoverColor != null && !_isPressed) {
      shadows.add(
        BoxShadow(
          color: widget.hoverColor!,
          blurRadius: 4,
          spreadRadius: 0,
        ),
      );
    }
    
    // Add press glow shadow
    if (animationValue > 0) { // Only add glow if press animation is active
       shadows.add(
         BoxShadow(
           color: glowColor,
           blurRadius: glowBlur,
           spreadRadius: glowSpread,
         ),
       );
    }

    return BoxDecoration(
      color: bgColor,
      borderRadius: widget.borderRadius,
      // Keep focus border logic separate from press glow
      border: _isFocused && widget.focusColor != null 
        ? Border.all(color: widget.focusColor!, width: 2)
        : null,
      // Apply combined shadows
      boxShadow: shadows.isNotEmpty ? shadows : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: widget.borderRadius,
      child: InkWell(
        onTap: widget.disabled ? null : () {
          if (widget.enableHapticFeedback) {
            FeedbackUtil.buttonTap();
          }
          widget.onTap?.call();
        },
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        borderRadius: widget.borderRadius,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTapDown: (_) => _handleTapDown(),
            onTapUp: (_) => _handleTapUp(),
            onTapCancel: () => _handleTapCancel(),
            behavior: HitTestBehavior.opaque,
            child: Focus(
              onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
              child: AnimatedScale(
                scale: _isPressed ? widget.pressedScale : 1.0,
                duration: widget.animationDuration,
                curve: widget.animationCurve,
                child: Opacity(
                  opacity: widget.disabled ? 0.5 : 1.0,
                  child: _pressAnimation != null
                      ? AnimatedBuilder(
                          animation: _pressAnimation!,
                          builder: (context, child) {
                            return Container(
                              decoration: _getBoxDecoration(context),
                              child: child,
                            );
                          },
                          child: widget.child,
                        )
                      : Container(
                          decoration: _getBoxDecoration(context),
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleTapDown() {
    if (widget.disabled) return;
    setState(() {
      _isPressed = true;
    });
    _pressAnimationController?.forward();
  }

  void _handleTapUp() {
    if (!_isPressed || widget.disabled) return;
    _pressAnimationController?.reverse().then((_) {
       if (mounted) {
    setState(() {
      _isPressed = false;
          });
       }
    });
  }

  void _handleTapCancel() {
    if (!_isPressed || widget.disabled) return;
    _pressAnimationController?.reverse().then((_) {
       if (mounted) {
    setState(() {
      _isPressed = false;
          });
       }
    });
  }
} 