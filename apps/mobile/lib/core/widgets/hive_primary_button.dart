import 'package:flutter/material.dart';
// import 'package:hive_ui/hive_ui.dart'; // Remove incorrect assumption
import 'package:hive_ui/core/theme/app_colors.dart';
import 'package:hive_ui/core/theme/app_typography.dart';
import 'package:hive_ui/core/haptics/haptic_feedback_manager.dart';
import 'package:hive_ui/core/widgets/scaling_touch_button.dart';
import 'package:hive_ui/core/theme/animation_durations.dart';

/// HIVE's standard action button, adaptable for different styles.
///
/// Implements button specs from brand_aesthetic.md Section 9.1:
/// - Height: 36pt, Radius: 24pt
/// - Primary: Surface gradient background, white text, gold focus/interaction.
/// - Secondary: Transparent background, white text, subtle border on interaction.
/// - Success/Error: Solid color backgrounds.
/// - Interaction: Scale to 98% on press, haptic feedback.
enum HiveButtonStyle {
  /// Standard action: Surface gradient background, white text, gold interaction emphasis.
  primary,
  /// Alternative action: Transparent background, white text, subtle border.
  secondary,
  /// Confirmation action: Success green background, white text.
  success,
  /// Destructive action: Error red background, white text.
  error,
}

class HivePrimaryButton extends StatelessWidget {
  /// The text to display on the button.
  final String text;
  
  /// Called when the button is tapped.
  final VoidCallback? onPressed;
  
  /// Whether the button should take up the full width of its parent.
  final bool isFullWidth;
  
  /// Whether the button is in a loading state.
  final bool isLoading;
  
  /// Optional icon to display before the text.
  final IconData? icon;
  
  /// Optional border radius override (defaults to 24pt per HIVE specs).
  final BorderRadius? borderRadius;
  
  /// Style variant (primary, secondary, success, error).
  final HiveButtonStyle style;

  /// Creates a HivePrimaryButton following HIVE brand aesthetic guidelines.
  const HivePrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isFullWidth = false,
    this.isLoading = false,
    this.icon,
    this.borderRadius,
    this.style = HiveButtonStyle.primary,
  });

  @override
  Widget build(BuildContext context) {
    final HapticFeedbackManager hapticManager = HapticFeedbackManager();
    final bool isDisabled = onPressed == null || isLoading;
    final animationDurations = Theme.of(context).extension<AnimationDurations>() ?? 
                             const AnimationDurations();
    
    // Default radius is 24pt for chip-sized buttons (per HIVE specs)
    final buttonRadius = borderRadius ?? BorderRadius.circular(24);
    
    // Determine colors based on style and state
    Color textColor = AppColors.textPrimary;
    Color loadingIndicatorColor = AppColors.textPrimary;
    Color? focusColor;
    Color? hoverColor;
    BoxDecoration? backgroundDecoration;
    Color? plainBackgroundColor; // Used for non-gradient styles
    Border? border; // For secondary style

    switch (style) {
      case HiveButtonStyle.primary:
        // NEW: Surface gradient background, white text, gold interaction
        backgroundDecoration = BoxDecoration(
          gradient: AppColors.surfaceGradient,
          borderRadius: buttonRadius,
        );
        textColor = isDisabled ? AppColors.textDisabled : AppColors.textPrimary;
        loadingIndicatorColor = AppColors.textPrimary;
        // Gold emphasis for focus/hover (matching secondary style for now)
        focusColor = AppColors.accentGold.withOpacity(0.2);
        hoverColor = AppColors.accentGold.withOpacity(0.1);
        // TODO: Consider adding gold border on press/focus for primary?
        break;

      case HiveButtonStyle.secondary:
        plainBackgroundColor = Colors.transparent; // Use plain color for transparency
        textColor = isDisabled ? AppColors.textDisabled : AppColors.textPrimary;
        loadingIndicatorColor = AppColors.textPrimary;
        focusColor = AppColors.accentGold.withOpacity(0.2);
        hoverColor = AppColors.accentGold.withOpacity(0.1);
        // Define border specifically for secondary style
        border = Border.all(
          color: isDisabled 
              ? AppColors.textPrimary.withOpacity(0.05) 
              : AppColors.textPrimary.withOpacity(0.1),
          width: 1.0,
        );
        break;

      case HiveButtonStyle.success:
        plainBackgroundColor = isDisabled ? AppColors.success.withOpacity(0.5) : AppColors.success;
        textColor = isDisabled ? AppColors.textDisabled : AppColors.textPrimary;
        loadingIndicatorColor = AppColors.textPrimary;
        focusColor = AppColors.success.withOpacity(0.3);
        hoverColor = AppColors.success.withOpacity(0.2);
        break;

      case HiveButtonStyle.error:
        plainBackgroundColor = isDisabled ? AppColors.error.withOpacity(0.5) : AppColors.error;
        textColor = isDisabled ? AppColors.textDisabled : AppColors.textPrimary;
        loadingIndicatorColor = AppColors.textPrimary;
        focusColor = AppColors.error.withOpacity(0.3);
        hoverColor = AppColors.error.withOpacity(0.2);
        break;
    }
        
    // Content inside the button
    Widget buttonContent = isLoading
        ? SizedBox(
            width: 20, // Slightly smaller indicator
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(loadingIndicatorColor),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon, 
                  size: 18, 
                  color: textColor,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  text,
                  style: AppTypography.button.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600, // Consistent weight
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
    
    // For secondary buttons, we can add a custom container with border 
    // since ScalingTouchButton doesn't have a borderColor parameter
    Widget buttonWithBorder = style == HiveButtonStyle.secondary
        ? Container(
            decoration: BoxDecoration(
              borderRadius: buttonRadius,
              border: border,
            ),
            child: buttonContent,
          )
        : buttonContent;
    
    return ScalingTouchButton(
      onTap: isDisabled ? null : () {
        hapticManager.lightTap();
        onPressed?.call();
      },
      disabled: isDisabled,
      backgroundColor: plainBackgroundColor,
      animationDuration: animationDurations.buttonPress,
      animationCurve: AnimationCurves.buttonPress,
      borderRadius: buttonRadius,
      focusColor: focusColor,
      hoverColor: hoverColor,
      child: Container(
        width: isFullWidth ? double.infinity : null,
        height: 36, // 36pt height per HIVE specs
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        alignment: Alignment.center,
        decoration: backgroundDecoration?.copyWith(
           border: border,
        ) ?? BoxDecoration(
          border: border,
          borderRadius: buttonRadius, // Ensure radius is always applied
        ),
        child: buttonWithBorder,
      ),
    );
  }
} 