import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// Represents the user's relationship to a space
enum SpaceAffiliationState {
  /// Not affiliated (can join or watch)
  none,
  
  /// Watching/observing the space (lightweight affiliation)
  observing,
  
  /// Joined as a member
  member,
  
  /// Joined as a builder (can create content)
  builder,
  
  /// Request pending (for private spaces)
  pending
}

/// Button for space affiliation actions with different visual states
class SpaceAffiliationButton extends StatefulWidget {
  /// Current affiliation state of the user with this space
  final SpaceAffiliationState state;
  
  /// Callback when user wants to change affiliation (join, leave, etc)
  final Function(SpaceAffiliationState newState) onAffiliationChange;
  
  /// Whether the space is private (requires approval)
  final bool isPrivate;
  
  /// Optional custom label for the button
  final String? customLabel;
  
  /// Optional tooltip text
  final String? tooltip;
  
  /// Whether to show the pill shape or use a more subtle style
  final bool usePrimaryStyle;

  const SpaceAffiliationButton({
    Key? key,
    required this.state,
    required this.onAffiliationChange,
    this.isPrivate = false,
    this.customLabel,
    this.tooltip,
    this.usePrimaryStyle = true,
  }) : super(key: key);

  @override
  State<SpaceAffiliationButton> createState() => _SpaceAffiliationButtonState();
}

class _SpaceAffiliationButtonState extends State<SpaceAffiliationButton> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }
  
  // Get button styles based on affiliation state
  ButtonStyle _getButtonStyle() {
    // Base border radius for all buttons (pill shape)
    final BorderRadius borderRadius = BorderRadius.circular(24);
    
    // Different styling based on state
    switch (widget.state) {
      case SpaceAffiliationState.none:
        // Primary join button - white with black text
        return ButtonStyle(
          backgroundColor: MaterialStateProperty.all(
            widget.usePrimaryStyle ? Colors.white : Colors.transparent,
          ),
          foregroundColor: MaterialStateProperty.all(
            widget.usePrimaryStyle ? Colors.black : Colors.white,
          ),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: borderRadius,
              side: widget.usePrimaryStyle 
                  ? BorderSide.none 
                  : const BorderSide(color: Colors.white30, width: 1),
            ),
          ),
          overlayColor: MaterialStateProperty.all(
            widget.usePrimaryStyle ? Colors.grey[300] : Colors.white10, 
          ),
          padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        );
        
      case SpaceAffiliationState.observing:
        // Watching state - subtle gold accent
        return ButtonStyle(
          backgroundColor: MaterialStateProperty.all(Colors.transparent),
          foregroundColor: MaterialStateProperty.all(AppColors.gold),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: borderRadius,
              side: BorderSide(color: AppColors.gold.withOpacity(0.5), width: 1),
            ),
          ),
          overlayColor: MaterialStateProperty.all(AppColors.gold.withOpacity(0.1)),
          padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        );
        
      case SpaceAffiliationState.member:
        // Member state - gold filled
        return ButtonStyle(
          backgroundColor: MaterialStateProperty.all(
            widget.usePrimaryStyle ? AppColors.gold : Colors.transparent,
          ),
          foregroundColor: MaterialStateProperty.all(
            widget.usePrimaryStyle ? Colors.black : AppColors.gold,
          ),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: borderRadius,
              side: widget.usePrimaryStyle 
                  ? BorderSide.none 
                  : const BorderSide(color: AppColors.gold, width: 1),
            ),
          ),
          overlayColor: MaterialStateProperty.all(
            widget.usePrimaryStyle 
                ? AppColors.gold.withOpacity(0.8) 
                : AppColors.gold.withOpacity(0.1),
          ),
          padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        );
        
      case SpaceAffiliationState.builder:
        // Builder state - gold with glow
        return ButtonStyle(
          backgroundColor: MaterialStateProperty.all(AppColors.gold),
          foregroundColor: MaterialStateProperty.all(Colors.black),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: borderRadius,
            ),
          ),
          overlayColor: MaterialStateProperty.all(AppColors.gold.withOpacity(0.8)),
          padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        );
        
      case SpaceAffiliationState.pending:
        // Pending state - gray with subtle styling
        return ButtonStyle(
          backgroundColor: MaterialStateProperty.all(Colors.grey[800]),
          foregroundColor: MaterialStateProperty.all(Colors.white70),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: borderRadius,
              side: const BorderSide(color: Colors.white30, width: 1),
            ),
          ),
          overlayColor: MaterialStateProperty.all(Colors.transparent),
          padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        );
    }
  }
  
  // Get button text based on affiliation state
  String _getButtonText() {
    if (widget.customLabel != null) {
      return widget.customLabel!;
    }
    
    switch (widget.state) {
      case SpaceAffiliationState.none:
        return widget.isPrivate ? 'Request to Join' : 'Join';
      case SpaceAffiliationState.observing:
        return 'Watching';
      case SpaceAffiliationState.member:
        return 'Member';
      case SpaceAffiliationState.builder:
        return 'Builder';
      case SpaceAffiliationState.pending:
        return 'Request Pending';
    }
  }
  
  // Get next state when button is pressed
  SpaceAffiliationState _getNextState() {
    switch (widget.state) {
      case SpaceAffiliationState.none:
        return widget.isPrivate ? SpaceAffiliationState.pending : SpaceAffiliationState.member;
      case SpaceAffiliationState.observing:
        return SpaceAffiliationState.member;
      case SpaceAffiliationState.member:
      case SpaceAffiliationState.builder:
        return SpaceAffiliationState.none;
      case SpaceAffiliationState.pending:
        return SpaceAffiliationState.none; // Cancel request
    }
  }
  
  // Get icon based on affiliation state
  IconData? _getButtonIcon() {
    switch (widget.state) {
      case SpaceAffiliationState.none:
        return Icons.add;
      case SpaceAffiliationState.observing:
        return Icons.visibility;
      case SpaceAffiliationState.member:
        return Icons.check;
      case SpaceAffiliationState.builder:
        return Icons.build;
      case SpaceAffiliationState.pending:
        return Icons.hourglass_empty;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: _buildButton(),
        );
      },
    );
  }
  
  Widget _buildButton() {
    // For builder state, add a glow effect
    if (widget.state == SpaceAffiliationState.builder && widget.usePrimaryStyle) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: _buildButtonContent(),
      );
    }
    
    return _buildButtonContent();
  }
  
  Widget _buildButtonContent() {
    final buttonText = _getButtonText();
    final buttonIcon = _getButtonIcon();
    
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isPressed = true;
        });
        _animController.forward();
        HapticFeedback.selectionClick();
      },
      onTapUp: (_) {
        setState(() {
          _isPressed = false;
        });
        _animController.reverse();
      },
      onTapCancel: () {
        setState(() {
          _isPressed = false;
        });
        _animController.reverse();
      },
      onTap: () {
        final nextState = _getNextState();
        widget.onAffiliationChange(nextState);
      },
      child: Tooltip(
        message: widget.tooltip ?? buttonText,
        child: TextButton.icon(
          style: _getButtonStyle(),
          icon: buttonIcon != null ? Icon(buttonIcon) : const SizedBox.shrink(),
          label: Text(
            buttonText,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          onPressed: null, // Gesture detector handles the press
        ),
      ),
    );
  }
}

/// Floating button to become a builder for a space
class BecomeBuilderButton extends StatelessWidget {
  final VoidCallback onTap;
  
  const BecomeBuilderButton({
    Key? key,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.gold.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.build,
              color: AppColors.gold,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Help Lead This Space',
              style: GoogleFonts.inter(
                color: AppColors.gold,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 