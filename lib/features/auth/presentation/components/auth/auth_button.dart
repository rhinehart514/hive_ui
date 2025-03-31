import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// Button variants for authentication screens
enum AuthButtonVariant {
  /// Filled button with white background and black text
  primary,

  /// Outlined button with gold border
  secondary,

  /// Text-only button with gold text
  text,

  /// Social media button with icon
  social
}

/// A standardized button component for authentication screens
class AuthButton extends StatelessWidget {
  /// The text to display on the button
  final String text;

  /// The callback when the button is pressed
  final VoidCallback? onPressed;

  /// Optional icon to display with text
  final Widget? icon;

  /// Button variant style
  final AuthButtonVariant variant;

  /// Whether the button is in loading state
  final bool isLoading;

  /// Whether to add haptic feedback when pressed
  final bool useHapticFeedback;

  /// Creates an AuthButton
  const AuthButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.variant = AuthButtonVariant.primary,
    this.isLoading = false,
    this.useHapticFeedback = true,
  });

  @override
  Widget build(BuildContext context) {
    // Handle haptic feedback and callback
    void handlePress() {
      if (onPressed == null || isLoading) return;

      if (useHapticFeedback) {
        HapticFeedback.mediumImpact();
      }

      onPressed!();
    }

    // Return appropriate button based on variant
    switch (variant) {
      case AuthButtonVariant.primary:
        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading ? null : handlePress,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              disabledBackgroundColor: Colors.white38,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
            ),
            child: isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                : Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        );

      case AuthButtonVariant.secondary:
        return SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: isLoading ? null : handlePress,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.gold,
              side: const BorderSide(color: AppColors.gold),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                    ),
                  )
                : Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gold,
                    ),
                  ),
          ),
        );

      case AuthButtonVariant.text:
        return TextButton(
          onPressed: isLoading ? null : handlePress,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.gold,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                  ),
                )
              : Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gold,
                  ),
                ),
        );

      case AuthButtonVariant.social:
        return SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: isLoading ? null : handlePress,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            icon: isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : icon ?? const SizedBox.shrink(),
            label: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
    }
  }
}
