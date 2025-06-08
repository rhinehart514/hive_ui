import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/glassmorphism_guide.dart';

/// Shows a dialog with a glassmorphism effect
Future<void> showGlassDialog({
  required BuildContext context,
  required String title,
  required String body,
  required String primaryButtonText,
  required VoidCallback primaryAction,
  String? secondaryButtonText,
  VoidCallback? secondaryAction,
  Color? primaryButtonColor,
}) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(GlassmorphismGuide.kModalRadius),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(GlassmorphismGuide.kModalRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: GlassmorphismGuide.kDialogBlur,
                  sigmaY: GlassmorphismGuide.kDialogBlur,
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(GlassmorphismGuide.kModalRadius),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: GlassmorphismGuide.kBorderThin,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Body text
                      Text(
                        body,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (secondaryButtonText != null && secondaryAction != null)
                            TextButton(
                              onPressed: secondaryAction,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                foregroundColor: Colors.white,
                              ),
                              child: Text(secondaryButtonText),
                            ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: primaryAction,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              backgroundColor: primaryButtonColor ?? AppColors.gold,
                              foregroundColor: primaryButtonColor != null && primaryButtonColor == AppColors.error
                                  ? Colors.white
                                  : Colors.black,
                            ),
                            child: Text(primaryButtonText),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
} 