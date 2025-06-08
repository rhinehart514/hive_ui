import 'package:flutter/material.dart';
import 'package:hive_ui/core/widgets/hive_dialog.dart';

/// Displays a standardized HIVE dialog with a custom entrance/exit animation.
///
/// Uses [showGeneralDialog] for customization.
Future<T?> showHiveDialog<T>({
  required BuildContext context,
  required Widget content,
  Widget? title,
  List<Widget>? actions,
  bool barrierDismissible = true,
  Color barrierColor = Colors.black54, // Standard dimming
  Duration transitionDuration = const Duration(milliseconds: 400), // HIVE standard
  double cornerRadius = 20.0,
  double blurSigma = 15.0,
  EdgeInsets padding = const EdgeInsets.all(24.0),
  double spacing = 16.0,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: barrierColor,
    transitionDuration: transitionDuration,
    pageBuilder: (BuildContext buildContext, Animation<double> animation,
        Animation<double> secondaryAnimation) {
      // The dialog widget itself
      return HiveDialog(
        title: title,
        content: content,
        actions: actions,
        padding: padding,
        spacing: spacing,
        blurSigma: blurSigma,
        cornerRadius: cornerRadius,
      );
    },
    transitionBuilder: (BuildContext context, Animation<double> animation,
        Animation<double> secondaryAnimation, Widget child) {
      // HIVE Standard Z-zoom entrance/exit animation (Fade + Scale)
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic, // HIVE standard curve
        reverseCurve: Curves.easeInCubic,
      );

      return ScaleTransition(
        scale: Tween<double>(begin: 0.85, end: 1.0).animate(curvedAnimation),
        child: FadeTransition(
          opacity: curvedAnimation,
          child: child,
        ),
      );
    },
  );
} 