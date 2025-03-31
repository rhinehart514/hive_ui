import 'package:flutter/material.dart';
import 'package:hive_ui/theme/text_theme.dart';
import 'package:hive_ui/theme/app_colors.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final double opacity;

  const StatCard({
    Key? key,
    required this.label,
    required this.value,
    this.color = Colors.white,
    this.opacity = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textPrimary.withOpacity(0.1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyles.bodyMedium.copyWith(
              color: color.withOpacity(opacity),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyles.bodyMedium.copyWith(
              color: color.withOpacity(opacity),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
