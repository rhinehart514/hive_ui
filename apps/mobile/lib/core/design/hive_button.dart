// ================================
// HIVE BUTTON SYSTEM - OFFICIAL COMPONENT
// Extracted from design_system_test_page.dart after user validation
// ================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// HIVE Button Component System
/// 
/// Implements the official HIVE button design language with validated
/// Gradient Surface treatment and comprehensive interaction states.
/// 
/// Usage:
/// ```dart
/// HiveButton.primary(
///   text: 'Join Space',
///   onPressed: () => handleJoin(),
/// )
/// ```
class HiveButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final HiveButtonVariant variant;
  final HiveButtonSize size;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final bool isLoading;
  final bool showFocusRing;

  const HiveButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = HiveButtonVariant.primary,
    this.size = HiveButtonSize.standard,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.showFocusRing = true,
  });

  /// Primary button with validated Gradient Surface treatment
  static HiveButton primary({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    Widget? leadingIcon,
    Widget? trailingIcon,
    bool isLoading = false,
    HiveButtonSize size = HiveButtonSize.standard,
  }) {
    return HiveButton(
      key: key,
      text: text,
      onPressed: onPressed,
      variant: HiveButtonVariant.primary,
      size: size,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      isLoading: isLoading,
    );
  }

  /// Secondary button variant
  static HiveButton secondary({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    Widget? leadingIcon,
    Widget? trailingIcon,
    bool isLoading = false,
    HiveButtonSize size = HiveButtonSize.standard,
  }) {
    return HiveButton(
      key: key,
      text: text,
      onPressed: onPressed,
      variant: HiveButtonVariant.secondary,
      size: size,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      isLoading: isLoading,
    );
  }

  /// Text-only button variant
  static HiveButton textButton({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    Widget? leadingIcon,
    Widget? trailingIcon,
    bool isLoading = false,
  }) {
    return HiveButton(
      key: key,
      text: text,
      onPressed: onPressed,
      variant: HiveButtonVariant.text,
      size: HiveButtonSize.standard,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      isLoading: isLoading,
      showFocusRing: false,
    );
  }

  /// Icon-only button variant
  static HiveButton icon({
    Key? key,
    required Widget icon,
    required VoidCallback? onPressed,
    bool isLoading = false,
    HiveButtonSize size = HiveButtonSize.standard,
  }) {
    return HiveButton(
      key: key,
      text: '',
      onPressed: onPressed,
      variant: HiveButtonVariant.icon,
      size: size,
      leadingIcon: icon,
      isLoading: isLoading,
    );
  }

  @override
  State<HiveButton> createState() => _HiveButtonState();
}

enum HiveButtonVariant { primary, secondary, text, icon }
enum HiveButtonSize { small, standard, large }

class _HiveButtonState extends State<HiveButton> 
    with TickerProviderStateMixin {
  late AnimationController _pressController;
  late AnimationController _focusController;
  late AnimationController _loadingController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _focusAnimation;
  late Animation<double> _loadingAnimation;
  
  bool _isPressed = false;
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 120), // 120ms per HIVE spec
      vsync: this,
    );
    
    _focusController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
    
    _focusAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _focusController, curve: Curves.easeInOut),
    );
    
    _loadingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.linear),
    );

    if (widget.isLoading) {
      _loadingController.repeat();
    }
  }

  @override
  void didUpdateWidget(HiveButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _loadingController.repeat();
      } else {
        _loadingController.stop();
      }
    }
  }

  @override
  void dispose() {
    _pressController.dispose();
    _focusController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isLoading && widget.onPressed != null) {
      setState(() => _isPressed = true);
      _pressController.forward();
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _pressController.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _pressController.reverse();
  }

  void _handleTap() {
    if (!widget.isLoading && widget.onPressed != null) {
      widget.onPressed!();
    }
  }

  void _handleHover(bool isHovered) {
    setState(() => _isHovered = isHovered);
  }

  void _handleFocusChange(bool isFocused) {
    setState(() => _isFocused = isFocused);
    if (isFocused && widget.showFocusRing) {
      _focusController.forward();
    } else {
      _focusController.reverse();
    }
  }

  double get _buttonHeight {
    switch (widget.size) {
      case HiveButtonSize.small:
        return 32;
      case HiveButtonSize.standard:
        return 36; // HIVE spec: 36pt height
      case HiveButtonSize.large:
        return 44;
    }
  }

  double get _buttonRadius {
    return _buttonHeight / 2; // Perfect pill shape
  }

  EdgeInsets get _buttonPadding {
    switch (widget.size) {
      case HiveButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12);
      case HiveButtonSize.standard:
        return const EdgeInsets.symmetric(horizontal: 16);
      case HiveButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 20);
    }
  }

  BoxDecoration _getButtonDecoration() {
    final isDisabled = widget.onPressed == null;
    
    switch (widget.variant) {
      case HiveButtonVariant.primary:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(_buttonRadius),
          gradient: isDisabled 
            ? null
            : LinearGradient(
                colors: [
                  _isHovered 
                    ? const Color(0xFF2A2A2A) // Brighter on hover
                    : const Color(0xFF1E1E1E), // HIVE surface start
                  _isHovered
                    ? const Color(0xFF333333) // Enhanced gradient depth
                    : const Color(0xFF2A2A2A), // HIVE surface end
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
          color: isDisabled ? const Color(0xFF1E1E1E).withOpacity(0.5) : null,
          border: Border.all(
            color: _isHovered && !isDisabled
              ? Colors.white.withOpacity(0.3) // Brighter border on hover
              : Colors.white.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: _isPressed || isDisabled ? [] : [
            // Standard elevation shadow
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: _isHovered ? 8 : 4,
              offset: Offset(0, _isHovered ? 4 : 2),
            ),
            // Subtle inner glow (Note: Flutter doesn't support inset shadows, but this shows the intent)
            BoxShadow(
              color: Colors.white.withOpacity(_isHovered ? 0.08 : 0.04),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        );
      
      case HiveButtonVariant.secondary:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(_buttonRadius),
          color: Colors.transparent,
          border: Border.all(
            color: _isHovered && !isDisabled
              ? const Color(0xFFFFD700).withOpacity(0.6)
              : Colors.white.withOpacity(0.3),
            width: 1,
          ),
        );
      
      case HiveButtonVariant.text:
      case HiveButtonVariant.icon:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(_buttonRadius),
          color: _isHovered && !isDisabled
            ? Colors.white.withOpacity(0.05)
            : Colors.transparent,
        );
    }
  }

  Color _getTextColor() {
    final isDisabled = widget.onPressed == null;
    
    if (isDisabled) {
      return Colors.white.withOpacity(0.5);
    }
    
    switch (widget.variant) {
      case HiveButtonVariant.primary:
        return Colors.white;
      case HiveButtonVariant.secondary:
      case HiveButtonVariant.text:
      case HiveButtonVariant.icon:
        return _isHovered ? const Color(0xFFFFD700) : Colors.white;
    }
  }

  TextStyle _getTextStyle() {
    return TextStyle(
      fontSize: widget.size == HiveButtonSize.small ? 14 : 16,
      fontWeight: widget.variant == HiveButtonVariant.primary 
        ? FontWeight.w600 
        : FontWeight.w500,
      letterSpacing: 0.16,
      color: _getTextColor(),
      height: 1.2,
    );
  }

  Widget _buildFocusRing(Widget child) {
    if (!widget.showFocusRing) return child;
    
    return AnimatedBuilder(
      animation: _focusAnimation,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_buttonRadius + 4),
            border: Border.all(
              color: const Color(0xFFFFD700).withOpacity(_focusAnimation.value),
              width: 2,
            ),
            boxShadow: _isFocused ? [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.3 * _focusAnimation.value),
                blurRadius: 8,
                offset: const Offset(0, 0),
              ),
            ] : [],
          ),
          padding: const EdgeInsets.all(4),
          child: child,
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return AnimatedBuilder(
      animation: _loadingAnimation,
      builder: (context, _) {
        return Transform.rotate(
          angle: _loadingAnimation.value * 2 * 3.14159,
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(_getTextColor()),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;
    
    Widget buttonChild = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          _buildLoadingIndicator(),
          if (widget.text.isNotEmpty) const SizedBox(width: 8),
        ] else if (widget.leadingIcon != null) ...[
          widget.leadingIcon!,
          if (widget.text.isNotEmpty) const SizedBox(width: 8),
        ],
        if (widget.text.isNotEmpty)
          Text(widget.text, style: _getTextStyle()),
        if (!widget.isLoading && widget.trailingIcon != null) ...[
          if (widget.text.isNotEmpty) const SizedBox(width: 8),
          widget.trailingIcon!,
        ],
      ],
    );

    Widget button = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            height: _buttonHeight,
            constraints: BoxConstraints(
              minWidth: widget.variant == HiveButtonVariant.icon 
                ? _buttonHeight 
                : 88, // Minimum touch target
            ),
            padding: widget.variant == HiveButtonVariant.icon 
              ? EdgeInsets.zero 
              : _buttonPadding,
            decoration: _getButtonDecoration(),
            child: Center(child: buttonChild),
          ),
        );
      },
    );

    return _buildFocusRing(
      MouseRegion(
        onEnter: (_) => _handleHover(true),
        onExit: (_) => _handleHover(false),
        child: Focus(
          onFocusChange: _handleFocusChange,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            onTap: _handleTap,
            child: button,
          ),
        ),
      ),
    );
  }
} 