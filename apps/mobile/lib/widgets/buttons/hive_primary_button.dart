import 'package:flutter/material.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A primary button styled according to HIVE design guidelines.
class HivePrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;
  final double? width;

  const HivePrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.height = 50.0,
    this.width = double.infinity, // Default to full width
  });

  @override
  Widget build(BuildContext context) {
    // Assuming AppColors.gold and AppColors.black exist
    const backgroundColor = AppColors.gold; // Fallback to AppColors.gold
    const foregroundColor = AppColors.black;
    final disabledBackgroundColor = AppColors.gold.withOpacity(0.5); // Fallback to AppColors.gold

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: disabledBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // Standard HIVE radius
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: foregroundColor,
                ),
              )
            : Text(text),
      ),
    );
  }
} 