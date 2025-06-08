import 'package:flutter/material.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';

/// Widget to display the lifecycle state of a space
class LifecycleStateIndicator extends StatelessWidget {
  /// The space entity to display lifecycle state for
  final SpaceEntity space;
  
  /// Show full details
  final bool showDetails;
  
  /// Constructor
  const LifecycleStateIndicator({
    Key? key,
    required this.space,
    this.showDetails = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Skip rendering for active spaces if details not shown
    if (!showDetails && space.lifecycleState == SpaceLifecycleState.active) {
      return const SizedBox.shrink();
    }
    
    final Color stateColor = _getStateColor(space.lifecycleState);
    final IconData stateIcon = _getStateIcon(space.lifecycleState);
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: stateColor.withOpacity(0.15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(stateIcon, size: 16, color: stateColor),
          const SizedBox(width: 6),
          Text(
            space.lifecycleStateDescription,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: stateColor,
            ),
          ),
          if (showDetails && space.lastActivityAt != null) ...[
            const SizedBox(width: 6),
            Text(
              _formatLastActivity(space.lastActivityAt!),
              style: TextStyle(
                fontSize: 10,
                color: stateColor.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  /// Get color based on lifecycle state
  Color _getStateColor(SpaceLifecycleState state) {
    switch (state) {
      case SpaceLifecycleState.created:
        return Colors.blue;
      case SpaceLifecycleState.active:
        return Colors.green;
      case SpaceLifecycleState.dormant:
        return Colors.amber;
      case SpaceLifecycleState.archived:
        return Colors.grey;
    }
  }
  
  /// Get icon based on lifecycle state
  IconData _getStateIcon(SpaceLifecycleState state) {
    switch (state) {
      case SpaceLifecycleState.created:
        return Icons.new_releases_outlined;
      case SpaceLifecycleState.active:
        return Icons.check_circle_outline;
      case SpaceLifecycleState.dormant:
        return Icons.access_time;
      case SpaceLifecycleState.archived:
        return Icons.archive_outlined;
    }
  }
  
  /// Format the last activity date
  String _formatLastActivity(DateTime lastActivity) {
    final now = DateTime.now();
    final difference = now.difference(lastActivity);
    
    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
} 