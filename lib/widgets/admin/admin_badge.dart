import 'package:flutter/material.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A badge that indicates that a user has admin privileges
class AdminBadge extends StatelessWidget {
  /// Size of the badge
  final double size;

  /// Color of the badge icon
  final Color? color;

  /// Show a tooltip when hovering
  final bool showTooltip;

  /// Custom tooltip text
  final String? tooltipText;

  const AdminBadge({
    super.key,
    this.size = 16.0,
    this.color,
    this.showTooltip = true,
    this.tooltipText,
  });

  @override
  Widget build(BuildContext context) {
    final badge = Icon(
      Icons.admin_panel_settings,
      size: size,
      color: color ?? AppColors.gold,
    );

    if (showTooltip) {
      return Tooltip(
        message: tooltipText ?? 'Admin User',
        child: badge,
      );
    }

    return badge;
  }
}
