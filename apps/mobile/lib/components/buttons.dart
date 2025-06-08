import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/component_style.dart';

/// Button sizes for the standardized HiveButton
enum HiveButtonSize {
  /// Small button (height: 36)
  small,

  /// Medium button (height: 44)
  medium,

  /// Large button (height: 54)
  large
}

/// Button variants for the standardized HiveButton
enum HiveButtonVariant {
  /// Filled button with white background
  primary,

  /// Outlined button with white border
  secondary,

  /// Outlined button with white border
  tertiary,

  /// Transparent button with text only
  text
}

/// A standardized button component that follows HIVE's design system
class HiveButton extends StatelessWidget {
  /// The text to display on the button
  final String text;

  /// The callback when the button is pressed
  final VoidCallback? onPressed;

  /// Optional icon to display before the text
  final IconData? icon;

  /// Optional size preset
  final HiveButtonSize size;

  /// Optional variant style
  final HiveButtonVariant variant;

  /// The style variant to apply (standard, important, or special)
  final HiveComponentStyle componentStyle;

  /// Whether the button should expand to fill its parent
  final bool fullWidth;

  /// Whether to apply haptic feedback when pressed
  final bool hapticFeedback;

  /// Type of haptic feedback to apply
  final HapticFeedbackType feedbackType;

  /// Constructor
  const HiveButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.size = HiveButtonSize.medium,
    this.variant = HiveButtonVariant.primary,
    this.componentStyle = HiveComponentStyle.standard,
    this.fullWidth = false,
    this.hapticFeedback = true,
    this.feedbackType = HapticFeedbackType.medium,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate the height based on the size
    final double height = _getButtonHeight();

    // Determine the button style based on the variant
    final ButtonStyle style = _getButtonStyle();

    // Build the button with the appropriate type
    Widget button;
    if (variant == HiveButtonVariant.primary) {
      button = ElevatedButton(
        onPressed: onPressed != null ? _handlePress : null,
        style: style,
        child: _buildButtonContent(),
      );
    } else if (variant == HiveButtonVariant.text) {
      button = TextButton(
        onPressed: onPressed != null ? _handlePress : null,
        style: style,
        child: _buildButtonContent(),
      );
    } else {
      button = OutlinedButton(
        onPressed: onPressed != null ? _handlePress : null,
        style: style,
        child: _buildButtonContent(),
      );
    }

    // Apply width constraints if needed
    if (fullWidth) {
      return SizedBox(
        width: double.infinity,
        height: height,
        child: button,
      );
    } else {
      return SizedBox(
        height: height,
        child: button,
      );
    }
  }

  /// Handle the button press with optional haptic feedback
  void _handlePress() {
    if (hapticFeedback) {
      // Get appropriate haptic feedback type
      HapticFeedbackType actualFeedbackType = feedbackType;

      // If not explicitly specified, use style-specific haptic
      if (feedbackType == HapticFeedbackType.medium) {
        switch (componentStyle) {
          case HiveComponentStyle.standard:
            actualFeedbackType = HapticFeedbackType.medium;
            break;
          case HiveComponentStyle.important:
            actualFeedbackType = HapticFeedbackType.medium;
            break;
          case HiveComponentStyle.special:
            actualFeedbackType = HapticFeedbackType.heavy;
            break;
        }
      }

      switch (actualFeedbackType) {
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

    onPressed?.call();
  }

  /// Build the button content (text with optional icon)
  Widget _buildButtonContent() {
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _getIconSize()),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              fontSize: _getTextSize(),
              letterSpacing: _getLetterSpacing(),
            ),
          ),
        ],
      );
    } else {
      return Text(
        text,
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          fontSize: _getTextSize(),
          letterSpacing: _getLetterSpacing(),
        ),
      );
    }
  }

  /// Get the button height based on the size
  double _getButtonHeight() {
    switch (size) {
      case HiveButtonSize.small:
        return 36;
      case HiveButtonSize.medium:
        return 44;
      case HiveButtonSize.large:
        return 54;
    }
  }

  /// Get the text size based on the button size
  double _getTextSize() {
    switch (size) {
      case HiveButtonSize.small:
        return 13;
      case HiveButtonSize.medium:
        return 15;
      case HiveButtonSize.large:
        return 16;
    }
  }

  /// Get the letter spacing based on the component style
  double _getLetterSpacing() {
    switch (componentStyle) {
      case HiveComponentStyle.standard:
        return 0.0;
      case HiveComponentStyle.important:
        return 0.3;
      case HiveComponentStyle.special:
        return 0.5;
    }
  }

  /// Get the icon size based on the button size
  double _getIconSize() {
    switch (size) {
      case HiveButtonSize.small:
        return 16;
      case HiveButtonSize.medium:
        return 18;
      case HiveButtonSize.large:
        return 20;
    }
  }

  /// Get the button style based on the variant and size
  ButtonStyle _getButtonStyle() {
    // Get the border radius based on component style and size
    // Using pill shape (24px) for small buttons, consistent with the design system
    double radius = 24.0;
    
    // For medium and large buttons, adjust if needed based on component style
    if (size != HiveButtonSize.small) {
      radius = componentStyle.getBorderRadius(
        standard: 24.0, // Changed from 12.0 to 24.0 for pill-like shape
        important: 24.0, // Changed from 0.0 to 24.0 to maintain consistency
        special: 24.0,   // Changed from 4.0 to 24.0 to maintain consistency
      );
    }
    
    final BorderRadius borderRadius = BorderRadius.circular(radius);

    switch (variant) {
      case HiveButtonVariant.primary:
        return _getPrimaryButtonStyle(borderRadius);

      case HiveButtonVariant.secondary:
        return _getSecondaryButtonStyle(borderRadius);

      case HiveButtonVariant.tertiary:
        return _getTertiaryButtonStyle(borderRadius);

      case HiveButtonVariant.text:
        return _getTextButtonStyle(borderRadius);
    }
  }

  /// Get primary (filled) button style
  ButtonStyle _getPrimaryButtonStyle(BorderRadius borderRadius) {
    // Default standard style
    Color backgroundColor = Colors.white; // Changed from AppColors.gold to white
    Color foregroundColor = Colors.black;

    // Apply style variations
    if (componentStyle == HiveComponentStyle.important) {
      // For important style, maintain white but with slightly higher opacity
      backgroundColor = Colors.white;
    } else if (componentStyle == HiveComponentStyle.special) {
      backgroundColor = Colors.white.withOpacity(0.9);
      foregroundColor = Colors.black;
    }

    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      disabledBackgroundColor: Colors.grey[800],
      disabledForegroundColor: Colors.grey[500],
      elevation: 0, // No elevation for any style
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      padding: _getPadding(),
    );
  }

  /// Get secondary (outlined) button style
  ButtonStyle _getSecondaryButtonStyle(BorderRadius borderRadius) {
    return OutlinedButton.styleFrom(
      foregroundColor: Colors.white, // Changed from AppColors.gold to white
      disabledForegroundColor: Colors.grey[500],
      side: BorderSide(
        color: Colors.white.withOpacity(0.3), // Use white with opacity
        width: componentStyle.getBorderWidth(),
      ),
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      padding: _getPadding(),
    );
  }

  /// Get tertiary (outlined white) button style
  ButtonStyle _getTertiaryButtonStyle(BorderRadius borderRadius) {
    // Standard white outline, adjust opacity based on style
    double opacity = 0.6;
    if (componentStyle == HiveComponentStyle.important) {
      opacity = 0.7;
    } else if (componentStyle == HiveComponentStyle.special) {
      opacity = 0.8;
    }

    return OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      disabledForegroundColor: Colors.grey[500],
      side: BorderSide(
        color: Colors.white.withOpacity(opacity),
        width: componentStyle.getBorderWidth(),
      ),
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      padding: _getPadding(),
    );
  }

  /// Get text button style
  ButtonStyle _getTextButtonStyle(BorderRadius borderRadius) {
    // Text buttons use white text with style-specific opacities
    Color textColor = Colors.white;
    if (componentStyle == HiveComponentStyle.important ||
        componentStyle == HiveComponentStyle.special) {
      textColor = AppColors.gold;
    }

    return TextButton.styleFrom(
      foregroundColor: textColor,
      disabledForegroundColor: Colors.grey[500],
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      padding: _getPadding(),
    );
  }

  /// Get the button padding based on the size
  EdgeInsetsGeometry _getPadding() {
    switch (size) {
      case HiveButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case HiveButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
      case HiveButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
    }
  }
}

/// Types of haptic feedback for button presses
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
