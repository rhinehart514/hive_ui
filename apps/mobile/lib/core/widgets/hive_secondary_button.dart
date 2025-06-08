import 'package:flutter/material.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/app_typography.dart';
import 'package:hive_ui/utils/feedback_util.dart';
import 'package:hive_ui/core/widgets/scaling_touch_button.dart';
import 'package:hive_ui/theme/animation_durations.dart';

/// HIVE's standard secondary action button (Outlined style).
///
/// Features subtle border, specific dimensions, 
/// and interaction feedback (scale, haptics) per HIVE standards.
class HiveSecondaryButton extends StatelessWidget {
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

  /// Creates a HiveSecondaryButton following HIVE brand aesthetic guidelines.
  const HiveSecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isFullWidth = false,
    this.isLoading = false,
    this.icon,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null || isLoading;
    final animationDurations = Theme.of(context).extension<AnimationDurations>() ?? 
                             const AnimationDurations();
    
    // Default radius is 24pt for chip-sized buttons (per HIVE specs)
    final buttonRadius = borderRadius ?? BorderRadius.circular(24);
    
    // Text color changes opacity when disabled
    final textColor = isDisabled 
        ? AppColors.textPrimary.withOpacity(0.5) 
        : AppColors.textPrimary;
    
    // Border color
    final borderColor = isDisabled 
        ? AppColors.dark3.withOpacity(0.5) 
        : AppColors.dark3;
        
    // Content inside the button
    Widget buttonContent = isLoading
        ? const SizedBox(
            width: 24, 
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
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
                  style: AppTypography.title2.copyWith(color: textColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
    
    return ScalingTouchButton(
      onTap: isDisabled ? null : () {
        FeedbackUtil.buttonTap();
        onPressed?.call();
      },
      disabled: isDisabled,
      animationDuration: animationDurations.buttonPress,
      animationCurve: AnimationCurves.buttonPress,
      borderRadius: buttonRadius,
      focusColor: AppColors.gold.withOpacity(0.2),
      hoverColor: AppColors.gold.withOpacity(0.1),
      child: Container(
        width: isFullWidth ? double.infinity : null,
        height: 36, // 36pt height per HIVE specs
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: buttonRadius,
          border: Border.all(
            color: borderColor,
            width: 1.0,
          ),
        ),
        child: buttonContent,
      ),
    );
  }
} 