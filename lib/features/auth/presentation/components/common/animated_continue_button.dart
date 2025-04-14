import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/theme/app_theme.dart';
import 'package:hive_ui/features/auth/presentation/utils/animation_constants.dart';

/// A reusable animated continue button with Apple-style animations
class AnimatedContinueButton extends StatefulWidget {
  /// The button text
  final String text;
  
  /// Whether the button is enabled
  final bool isEnabled;
  
  /// Function to call when button is tapped
  final VoidCallback? onPressed;
  
  /// Button width - defaults to double.infinity
  final double? width;
  
  /// Button height - defaults to AppTheme.spacing56
  final double? height;

  /// Custom animation duration
  final Duration animationDuration;

  const AnimatedContinueButton({
    Key? key,
    this.text = 'Continue',
    required this.isEnabled,
    this.onPressed,
    this.width = double.infinity,
    this.height,
    this.animationDuration = const Duration(milliseconds: 250),
  }) : super(key: key);

  @override
  State<AnimatedContinueButton> createState() => _AnimatedContinueButtonState();
}

class _AnimatedContinueButtonState extends State<AnimatedContinueButton> 
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AnimationConstants.interactiveCurve,
      ),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.isEnabled && !_isPressed) {
      _isPressed = true;
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.isEnabled && _isPressed) {
      _isPressed = false;
      _controller.reverse();
      
      // Provide haptic feedback
      HapticFeedback.mediumImpact();
      
      // Call onPressed handler
      if (widget.onPressed != null) {
        widget.onPressed!();
      }
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      _isPressed = false;
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttonHeight = widget.height ?? AppTheme.spacing56;
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isEnabled ? _scaleAnimation.value : 1.0,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedContainer(
          duration: AnimationConstants.standardDuration,
          curve: AnimationConstants.standardCurve,
          width: widget.width,
          height: buttonHeight,
          decoration: BoxDecoration(
            color: widget.isEnabled ? Colors.white : Colors.white12,
            borderRadius: BorderRadius.circular(buttonHeight / 2),
            boxShadow: widget.isEnabled ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ] : null,
          ),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: AnimationConstants.standardDuration,
              curve: AnimationConstants.standardCurve,
              style: GoogleFonts.inter(
                color: widget.isEnabled ? Colors.black : Colors.white38,
                fontWeight: FontWeight.w600,
                fontSize: 16,
                letterSpacing: 0.2,
              ),
              child: Text(widget.text),
            ),
          ),
        ),
      ),
    );
  }
} 