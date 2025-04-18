import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for HapticFeedback
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/app_theme.dart'; // Correct import for spacing and radii

class FeedItemCard extends StatelessWidget {
  final Widget? leading;
  final String? title;
  final String? subtitle;
  final String? timeAgo;
  final Widget? content;
  final List<Widget>? actions;
  final VoidCallback? onTap;
  final bool isEvent;
  final EdgeInsets margin;

  const FeedItemCard({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.timeAgo,
    this.content,
    this.actions,
    this.onTap,
    this.isEvent = false,
    this.margin = const EdgeInsets.symmetric(
      vertical: 8,
      horizontal: 16,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          HapticFeedback.lightImpact();
          onTap!();
        }
      },
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          color: AppColors.dark2,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with avatar and info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (leading != null) 
                    leading!,
                  const SizedBox(width: AppTheme.spacing12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title != null)
                          Text(
                            title!,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        if (subtitle != null) ...[
                          const SizedBox(height: AppTheme.spacing4),
                          Text(
                            subtitle!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        if (timeAgo != null) ...[
                          const SizedBox(height: AppTheme.spacing4),
                          Text(
                            timeAgo!,
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              
              // Content
              if (content != null) ...[
                const SizedBox(height: AppTheme.spacing12),
                content!,
              ],
              
              // Actions
              if (actions != null && actions!.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spacing12),
                const Divider(
                  height: 1,
                  thickness: 0.5,
                  color: Color(0x22FFFFFF),
                ),
                const SizedBox(height: AppTheme.spacing12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: actions!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildActionButton(BuildContext context, IconData icon, String label, VoidCallback onPressed) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing12,
          vertical: AppTheme.spacing4,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        ),
        foregroundColor: AppColors.textSecondary,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      onPressed: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
    );
  }
} 