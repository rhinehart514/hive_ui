import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/features/auth/presentation/utils/animation_constants.dart';

/// A selection item with HIVE brand animations for onboarding and other selection UIs
class AnimatedSelectionItem extends StatefulWidget {
  /// The text to display
  final String text;
  
  /// Whether this item is selected
  final bool isSelected;
  
  /// Function to call when item is tapped
  final VoidCallback onTap;
  
  /// Optional custom style for the item when selected
  final TextStyle? selectedTextStyle;
  
  /// Optional custom style for the item when not selected
  final TextStyle? unselectedTextStyle;
  
  /// Border radius - defaults to 24
  final double borderRadius;
  
  /// Horizontal padding - defaults to 20
  final double horizontalPadding;
  
  /// Vertical padding - defaults to 12
  final double verticalPadding;

  const AnimatedSelectionItem({
    Key? key,
    required this.text,
    required this.isSelected,
    required this.onTap,
    this.selectedTextStyle,
    this.unselectedTextStyle,
    this.borderRadius = 24,
    this.horizontalPadding = 20,
    this.verticalPadding = 12,
  }) : super(key: key);

  @override
  State<AnimatedSelectionItem> createState() => _AnimatedSelectionItemState();
}

class _AnimatedSelectionItemState extends State<AnimatedSelectionItem> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AnimationConstants.microDuration,
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
    if (!_isPressed) {
      _isPressed = true;
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isPressed) {
      _isPressed = false;
      _controller.reverse();
      HapticFeedback.selectionClick();
      widget.onTap();
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
    // Standard text styles following HIVE brand guidelines
    final defaultSelectedTextStyle = GoogleFonts.inter(
      color: Colors.black,
      fontWeight: FontWeight.w600,
      fontSize: 15,
    );
    
    final defaultUnselectedTextStyle = GoogleFonts.inter(
      color: AppColors.white,
      fontWeight: FontWeight.w600,
      fontSize: 15,
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
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
          padding: EdgeInsets.symmetric(
            horizontal: widget.horizontalPadding,
            vertical: widget.verticalPadding,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected ? AppColors.gold : AnimationConstants.deepSurfaceColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: widget.isSelected 
                ? Colors.transparent 
                : AppColors.white.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: widget.isSelected ? [
              BoxShadow(
                color: AppColors.gold.withOpacity(0.2),
                offset: const Offset(0, 2),
                blurRadius: 4,
              )
            ] : null,
          ),
          child: Text(
            widget.text,
            style: widget.isSelected 
                ? (widget.selectedTextStyle ?? defaultSelectedTextStyle)
                : (widget.unselectedTextStyle ?? defaultUnselectedTextStyle),
          ),
        ),
      ),
    );
  }
} 