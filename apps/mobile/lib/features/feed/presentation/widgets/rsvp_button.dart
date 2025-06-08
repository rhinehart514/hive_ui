import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/huge_icons.dart';

/// An animated RSVP button that follows the HIVE style system
class RsvpButton extends StatefulWidget {
  /// Whether the user is currently RSVPed to the event
  final bool isRsvped;
  
  /// Callback when the RSVP status changes
  final Function(bool isRsvping) onRsvpChanged;
  
  /// Optional custom text for the button
  final String? rsvpText;
  
  /// Optional custom text for the unreserve action
  final String? unreserveText;
  
  /// Whether the button should be in a loading state
  final bool isLoading;
  
  /// Optional callback when the button is long-pressed
  final VoidCallback? onLongPress;
  
  /// Constructor
  const RsvpButton({
    Key? key,
    required this.isRsvped,
    required this.onRsvpChanged,
    this.rsvpText,
    this.unreserveText,
    this.isLoading = false,
    this.onLongPress,
  }) : super(key: key);

  @override
  State<RsvpButton> createState() => _RsvpButtonState();
}

class _RsvpButtonState extends State<RsvpButton> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Set up animation controller for tap feedback
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
    
    _scaleAnimation = _animationController.drive(CurveTween(curve: Curves.easeInOut));
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _handleTapDown(TapDownDetails details) {
    _animationController.reverse();
    HapticFeedback.lightImpact();
  }
  
  void _handleTapUp(TapUpDetails details) {
    _animationController.forward();
    
    // Only trigger if not loading
    if (!widget.isLoading) {
      _handleRsvpToggle();
    }
  }
  
  void _handleTapCancel() {
    _animationController.forward();
  }
  
  void _handleRsvpToggle() {
    // Provide appropriate haptic feedback based on action
    if (!widget.isRsvped) {
      HapticFeedback.mediumImpact();
    }
    
    widget.onRsvpChanged(!widget.isRsvped);
  }
  
  @override
  Widget build(BuildContext context) {
    final bool isRsvped = widget.isRsvped;
    final bool isLoading = widget.isLoading;
    
    final String buttonText = isRsvped 
        ? (widget.unreserveText ?? 'Going')
        : (widget.rsvpText ?? 'RSVP');
    
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              height: 44,
              constraints: const BoxConstraints(
                minWidth: 120,
              ),
              decoration: BoxDecoration(
                color: isRsvped ? Colors.transparent : Colors.white,
                border: Border.all(
                  color: isRsvped ? Colors.white.withOpacity(0.3) : Colors.transparent,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Center(
                child: isLoading
                    ? _buildLoadingIndicator(isRsvped)
                    : _buildButtonContent(isRsvped, buttonText),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildButtonContent(bool isRsvped, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isRsvped) ...[
          const Icon(
            HugeIcons.strokeRoundedTick01,
            size: 16,
            color: AppColors.white,
          ),
          const SizedBox(width: 8),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isRsvped ? Colors.white : Colors.black,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildLoadingIndicator(bool isRsvped) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          isRsvped ? Colors.white : Colors.black,
        ),
      ),
    );
  }
} 