import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/component_style.dart';

/// The different types of cards available in the HIVE UI
enum HiveCardType {
  /// Standard card for general content
  standard,

  /// Card with emphasis, often used for important information
  elevated,

  /// Interactive card with hover/press states
  interactive,

  /// Card for displaying activities or notifications
  activity,

  /// Card for user profiles or user-related information
  profile,

  /// Minimal card with less decoration
  minimal
}

/// A standardized card component following HIVE's design system
class HiveCard extends StatefulWidget {
  /// The content to display inside the card
  final Widget child;

  /// The type of card to display
  final HiveCardType type;

  /// The style variant to apply (standard, important, or special)
  final HiveComponentStyle componentStyle;

  /// Whether to add a gold accent to the card
  final bool addGoldAccent;

  /// The padding inside the card
  final EdgeInsetsGeometry padding;

  /// The margin around the card
  final EdgeInsetsGeometry margin;

  /// Border radius for the card
  final BorderRadius? borderRadius;

  /// Whether the card is interactive
  final bool isInteractive;

  /// Callback when the card is tapped
  final VoidCallback? onTap;

  /// Whether to apply haptic feedback on tap
  final bool hapticFeedback;

  /// Type of haptic feedback to apply
  final HapticFeedbackType feedbackType;

  /// Constructor
  const HiveCard({
    super.key,
    required this.child,
    this.type = HiveCardType.standard,
    this.componentStyle = HiveComponentStyle.standard,
    this.addGoldAccent = false,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(vertical: 8),
    this.borderRadius,
    this.isInteractive = false,
    this.onTap,
    this.hapticFeedback = true,
    this.feedbackType = HapticFeedbackType.light,
  });

  @override
  State<HiveCard> createState() => _HiveCardState();
}

class _HiveCardState extends State<HiveCard>
    with SingleTickerProviderStateMixin {
  /// Whether the card is being pressed
  bool _isPressed = false;

  /// Controller for scale animation
  late AnimationController _scaleController;

  /// Animation for scaling when pressed
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller with style-appropriate duration
    _scaleController = AnimationController(
      vsync: this,
      duration: widget.componentStyle.getAnimationDuration(
        standard: const Duration(milliseconds: 150),
        important: const Duration(milliseconds: 100),
        special: const Duration(milliseconds: 80),
      ),
    );

    // Create scale animation with style-appropriate curve
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98, // Slightly smaller when pressed
    ).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: widget.componentStyle.getAnimationCurve(),
      ),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  /// Apply haptic feedback based on feedback type
  void _applyHapticFeedback() {
    if (!widget.hapticFeedback) return;

    // Get appropriate haptic feedback type
    HapticFeedbackType feedbackType;
    if (widget.feedbackType != HapticFeedbackType.light) {
      feedbackType = widget.feedbackType;
    } else {
      // Convert from component style to haptic feedback type
      switch (widget.componentStyle) {
        case HiveComponentStyle.standard:
          feedbackType = HapticFeedbackType.medium;
          break;
        case HiveComponentStyle.important:
          feedbackType = HapticFeedbackType.medium;
          break;
        case HiveComponentStyle.special:
          feedbackType = HapticFeedbackType.heavy;
          break;
      }
    }

    switch (feedbackType) {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine whether the card should respond to interaction
    final bool shouldHaveInteraction =
        widget.isInteractive || widget.onTap != null;

    // If interactive, wrap in gesture detector and animated builder
    Widget cardContent = _buildCardContent();

    if (shouldHaveInteraction) {
      cardContent = GestureDetector(
        onTapDown: (_) {
          setState(() {
            _isPressed = true;
            _scaleController.forward();
          });
        },
        onTapUp: (_) {
          setState(() {
            _isPressed = false;
            _scaleController.reverse();
          });
        },
        onTapCancel: () {
          setState(() {
            _isPressed = false;
            _scaleController.reverse();
          });
        },
        onTap: () {
          _applyHapticFeedback();
          widget.onTap?.call();
        },
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }

  /// Build the card content with appropriate styling
  Widget _buildCardContent() {
    // Get the style-appropriate border radius
    final BorderRadius borderRadius = widget.borderRadius ??
        BorderRadius.circular(widget.componentStyle.getBorderRadius(
          standard: 12, // Default for HiveCard
          important: 0, // Sharp corners for important
          special: 4, // Minimal rounding for special
        ));

    return Container(
      margin: widget.margin,
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        child: Container(
          decoration: _getCardDecoration(borderRadius),
          child: Padding(
            padding: widget.padding,
            child: widget.child,
          ),
        ),
      ),
    );
  }

  /// Get card decoration based on type and states
  BoxDecoration _getCardDecoration(BorderRadius borderRadius) {
    // Base decoration properties
    final Color backgroundColor = _getBackgroundColor();
    final Color borderColor = _getBorderColor();
    final List<BoxShadow> shadows = _getShadows();

    return BoxDecoration(
      color: backgroundColor,
      borderRadius: borderRadius,
      border: Border.all(
        color: borderColor,
        width: widget.componentStyle.getBorderWidth(),
      ),
      boxShadow: shadows,
    );
  }

  /// Get background color based on card type and component style
  Color _getBackgroundColor() {
    // Apply style-specific color modifiers
    final double opacity =
        widget.componentStyle == HiveComponentStyle.standard ? 0.95 : 0.9;

    switch (widget.type) {
      case HiveCardType.elevated:
        return AppColors.grey800;
      case HiveCardType.minimal:
        return Colors.transparent;
      case HiveCardType.interactive:
        return _isPressed ? AppColors.grey700 : AppColors.grey800;
      case HiveCardType.standard:
        return AppColors.grey800.withOpacity(opacity);
      case HiveCardType.activity:
        return AppColors.grey800.withOpacity(opacity - 0.05);
      case HiveCardType.profile:
        return AppColors.grey800.withOpacity(opacity);
    }
  }

  /// Get border color based on card type, component style, and state
  Color _getBorderColor() {
    // If gold accent is enabled or non-standard style, use gold with appropriate opacity
    final bool shouldUseGold = widget.addGoldAccent ||
        widget.componentStyle != HiveComponentStyle.standard;

    if (shouldUseGold) {
      return AppColors.gold.withOpacity(
          widget.componentStyle.getGoldAccentOpacity() *
              (_isPressed ? 0.8 : 1.0));
    }

    // Otherwise, use default colors based on type
    switch (widget.type) {
      case HiveCardType.elevated:
        return Colors.white.withOpacity(0.12);
      case HiveCardType.interactive:
        return _isPressed
            ? Colors.white.withOpacity(0.15)
            : Colors.white.withOpacity(0.08);
      case HiveCardType.standard:
      case HiveCardType.activity:
      case HiveCardType.profile:
        return Colors.white.withOpacity(0.08);
      case HiveCardType.minimal:
        return Colors.transparent;
    }
  }

  /// Get shadows based on card type and component style
  List<BoxShadow> _getShadows() {
    // For minimal cards, don't use shadows
    if (widget.type == HiveCardType.minimal) {
      return [];
    }

    // For special style, use more pronounced shadows
    if (widget.componentStyle == HiveComponentStyle.special) {
      return [
        BoxShadow(
          color: widget.addGoldAccent
              ? AppColors.gold.withOpacity(0.15)
              : Colors.black.withOpacity(0.2),
          blurRadius: 12,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ];
    }

    // For important style, use slightly enhanced shadows
    if (widget.componentStyle == HiveComponentStyle.important) {
      return [
        BoxShadow(
          color: widget.addGoldAccent
              ? AppColors.gold.withOpacity(0.1)
              : Colors.black.withOpacity(0.15),
          blurRadius: 8,
          spreadRadius: 0,
          offset: const Offset(0, 3),
        ),
      ];
    }

    // For standard style, use subtle shadows
    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 6,
        spreadRadius: 0,
        offset: const Offset(0, 2),
      ),
    ];
  }
}

/// Types of haptic feedback for card interactions
enum HapticFeedbackType {
  /// Light impact
  light,

  /// Medium impact
  medium,

  /// Heavy impact
  heavy,

  /// Selection click
  selection
}
