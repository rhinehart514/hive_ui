import 'package:flutter/material.dart';
import 'package:hive_ui/core/theme/app_colors.dart';
import 'package:hive_ui/core/theme/app_typography.dart';
import 'package:hive_ui/core/widgets/glass_layer.dart';

/// A standardized dialog component for HIVE UI.
///
/// Conforms to the HIVE brand aesthetic using glassmorphism,
/// standard typography, and spacing.
class HiveDialog extends StatelessWidget {
  /// The title widget displayed at the top of the dialog.
  /// Typically a Text widget, but can be any widget.
  final Widget? title;

  /// The main content widget of the dialog.
  final Widget content;

  /// A list of actions (usually buttons) displayed at the bottom of the dialog.
  /// It's recommended to use [HivePrimaryButton] and [HiveSecondaryButton].
  final List<Widget>? actions;

  /// Padding around the title, content, and actions.
  /// Defaults to EdgeInsets.all(24.0).
  final EdgeInsets padding;

  /// Spacing between the title, content, and actions. Defaults to 16.0.
  final double spacing;

  /// The background blur intensity for the glass effect. Defaults to 15.0.
  final double blurSigma;

  /// The corner radius of the dialog. Defaults to 20.0.
  final double cornerRadius;

  const HiveDialog({
    super.key,
    this.title,
    required this.content,
    this.actions,
    this.padding = const EdgeInsets.all(24.0),
    this.spacing = 16.0,
    this.blurSigma = 15.0,
    this.cornerRadius = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [];

    // Add title if provided
    if (title != null) {
      children.add(
        DefaultTextStyle(
          style: AppTypography.headlineMedium.copyWith(color: AppColors.textPrimary),
          textAlign: TextAlign.center,
          child: title!,
        ),
      );
      children.add(SizedBox(height: spacing));
    }

    // Add content
    children.add(
      DefaultTextStyle(
        style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        textAlign: TextAlign.center,
        child: content,
      ),
    );

    // Add actions if provided
    if (actions != null && actions!.isNotEmpty) {
      children.add(SizedBox(height: spacing * 1.5)); // More space before actions
      children.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center, // Center actions
          // Apply spacing between actions if there are multiple
          children: actions!.length > 1
              ? List.generate(actions!.length * 2 - 1, (index) {
                  if (index.isEven) {
                    // Use Flexible for buttons to prevent overflow
                    return Flexible(child: actions![index ~/ 2]); 
                  } else {
                    return SizedBox(width: spacing / 2); // Half spacing between buttons
                  }
                })
              : [Flexible(child: actions!.first)], // Single action
        ),
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent, // Dialog itself is transparent
      elevation: 0, // No elevation, handled by glass effect/shadow
      insetPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0), // Standard padding
      child: GlassLayer( // Apply the glass effect
        blurAmount: blurSigma,
        borderRadius: BorderRadius.circular(cornerRadius),
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min, // Shrink wrap content
            crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch children horizontally
            children: children,
          ),
        ),
      ),
    );
  }
} 