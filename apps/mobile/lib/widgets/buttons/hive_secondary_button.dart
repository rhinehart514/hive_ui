import 'package:flutter/material.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A secondary/outline button styled according to HIVE design guidelines.
class HiveSecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final double height;
  final double? width;

  const HiveSecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.height = 50.0,
    this.width = double.infinity, // Default to full width
  });

  @override
  Widget build(BuildContext context) {
    // Assuming AppColors.gold exists
    const Color foregroundColor = AppColors.gold; 
    final Color sideColor = AppColors.gold.withOpacity(0.6);

    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: foregroundColor,
          side: BorderSide(color: sideColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // Standard HIVE radius
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Text(text),
      ),
    );
  }
} 