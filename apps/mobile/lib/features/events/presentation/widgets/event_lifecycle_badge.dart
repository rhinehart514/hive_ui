import 'package:flutter/material.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A widget that displays the lifecycle state of an event
/// with appropriate styling based on the state
class EventLifecycleBadge extends StatelessWidget {
  /// The event to display the lifecycle state for
  final Event event;
  
  /// Whether to use a compact layout
  final bool compact;
  
  /// Additional style override
  final BadgeStyle? style;

  /// Creates an event lifecycle badge
  const EventLifecycleBadge({
    Key? key,
    required this.event,
    this.compact = false,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the current state of the event
    final state = event.currentState;
    final isCancelled = event.isCancelled;
    
    // Define style based on state
    final BadgeStyle badgeStyle = style ?? _getStyleForState(state, isCancelled);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: badgeStyle.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: badgeStyle.borderColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badgeStyle.icon != null && !compact) ...[
            Icon(
              badgeStyle.icon,
              size: 14,
              color: badgeStyle.textColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            _getTextForState(state, isCancelled, compact),
            style: TextStyle(
              color: badgeStyle.textColor,
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Get the appropriate badge style for the event state
  BadgeStyle _getStyleForState(EventLifecycleState state, bool isCancelled) {
    if (isCancelled) {
      return BadgeStyle(
        backgroundColor: AppColors.error.withOpacity(0.2),
        borderColor: AppColors.error.withOpacity(0.5),
        textColor: AppColors.error,
        icon: Icons.cancel_outlined,
      );
    }
    
    switch (state) {
      case EventLifecycleState.draft:
        return BadgeStyle(
          backgroundColor: AppColors.grey.withOpacity(0.2),
          borderColor: AppColors.grey.withOpacity(0.5),
          textColor: AppColors.grey,
          icon: Icons.edit_outlined,
        );
      
      case EventLifecycleState.published:
        return BadgeStyle(
          backgroundColor: AppColors.gold.withOpacity(0.2),
          borderColor: AppColors.gold.withOpacity(0.5),
          textColor: AppColors.gold,
          icon: Icons.event_available_outlined,
        );
      
      case EventLifecycleState.live:
        return BadgeStyle(
          backgroundColor: AppColors.success.withOpacity(0.2),
          borderColor: AppColors.success.withOpacity(0.5),
          textColor: AppColors.success,
          icon: Icons.live_tv_outlined,
        );
      
      case EventLifecycleState.completed:
        return BadgeStyle(
          backgroundColor: AppColors.info.withOpacity(0.2),
          borderColor: AppColors.info.withOpacity(0.5),
          textColor: AppColors.info,
          icon: Icons.check_circle_outline,
        );
      
      case EventLifecycleState.archived:
        return BadgeStyle(
          backgroundColor: AppColors.grey.withOpacity(0.2),
          borderColor: AppColors.grey.withOpacity(0.5),
          textColor: AppColors.grey,
          icon: Icons.archive_outlined,
        );
    }
  }
  
  /// Get the display text for the event state
  String _getTextForState(EventLifecycleState state, bool isCancelled, bool compact) {
    if (isCancelled) {
      return compact ? 'Cancelled' : 'Cancelled';
    }
    
    switch (state) {
      case EventLifecycleState.draft:
        return compact ? 'Draft' : 'Draft';
      
      case EventLifecycleState.published:
        return compact ? 'Upcoming' : 'Upcoming';
      
      case EventLifecycleState.live:
        return compact ? 'Live' : 'Happening Now';
      
      case EventLifecycleState.completed:
        return compact ? 'Completed' : 'Recently Ended';
      
      case EventLifecycleState.archived:
        return compact ? 'Archived' : 'Archived';
    }
  }
}

/// Styling information for the event lifecycle badge
class BadgeStyle {
  /// Background color of the badge
  final Color backgroundColor;
  
  /// Border color of the badge
  final Color borderColor;
  
  /// Text color for the badge
  final Color textColor;
  
  /// Optional icon to display
  final IconData? icon;
  
  /// Creates a badge style
  const BadgeStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    this.icon,
  });
} 