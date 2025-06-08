import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Button variants for authentication screens
enum AuthButtonVariant {
  /// Filled button with white background and black text
  primary,

  /// Outlined button with white border
  secondary,

  /// Text-only button with white text
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
          height: 36, // Chip-sized height
          child: ElevatedButton(
            onPressed: isLoading ? null : handlePress,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              disabledBackgroundColor: Colors.white38,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24), // Using pill shape radius
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Chip-sized padding
              elevation: 0,
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20, // Reduced for smaller button
                    width: 20, // Reduced for smaller button
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
          height: 36, // Chip-sized height
          child: OutlinedButton(
            onPressed: isLoading ? null : handlePress,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white, // Changed from gold to white
              side: BorderSide(color: Colors.white.withOpacity(0.3)), // Changed from gold to white with opacity
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24), // Using pill shape radius
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Chip-sized padding
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20, // Reduced for smaller button
                    width: 20, // Reduced for smaller button
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white), // Changed from gold to white
                    ),
                  )
                : Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white, // Changed from gold to white
                    ),
                  ),
          ),
        );

      case AuthButtonVariant.text:
        return TextButton(
          onPressed: isLoading ? null : handlePress,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white, // Changed from gold to white
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white), // Changed from gold to white
                  ),
                )
              : Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white, // Changed from gold to white
                  ),
                ),
        );

      case AuthButtonVariant.social:
        return SizedBox(
          width: double.infinity,
          height: 36, // Chip-sized height
          child: OutlinedButton.icon(
            onPressed: isLoading ? null : handlePress,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24), // Using pill shape radius
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Chip-sized padding
            ),
            icon: isLoading
                ? const SizedBox(
                    height: 20, // Reduced for smaller button
                    width: 20, // Reduced for smaller button
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
