import 'package:flutter/material.dart';
import 'package:hive_ui/theme/text_theme.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/models/activity.dart';

class ActivityCard extends StatelessWidget {
  final Activity activity;
  final VoidCallback? onTap;

  const ActivityCard({
    super.key,
    required this.activity,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.textPrimary.withOpacity(0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  activity.iconData,
                  color: activity.typeColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    activity.title,
                    style: TextStyles.titleMedium,
                  ),
                ),
                Text(
                  activity.timeAgo,
                  style: TextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              activity.subtitle,
              style: TextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
