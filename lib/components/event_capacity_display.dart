import 'package:flutter/material.dart';
import '../models/event.dart';
import '../constants/app_colors.dart';
import '../constants/text_styles.dart';

/// A component that displays event capacity information
class EventCapacityDisplay extends StatelessWidget {
  /// The event to display capacity information for
  final Event event;
  
  /// Whether the current user is on the waitlist
  final bool isUserOnWaitlist;
  
  /// Whether to show the waitlist details
  final bool showWaitlist;
  
  /// Create a new event capacity display
  const EventCapacityDisplay({
    super.key,
    required this.event,
    this.isUserOnWaitlist = false,
    this.showWaitlist = true,
  });

  @override
  Widget build(BuildContext context) {
    // If no capacity, nothing to display
    if (event.capacity == null) return const SizedBox.shrink();
    
    final attendeesCount = event.attendees.length;
    final waitlistCount = event.waitlist.length;
    final hasWaitlist = waitlistCount > 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Capacity indicator
        Row(
          children: [
            Icon(
              _getCapacityIcon(attendeesCount, event.capacity!),
              size: 16,
              color: _getCapacityColor(attendeesCount, event.capacity!),
            ),
            const SizedBox(width: 8),
            Text(
              '$attendeesCount/${event.capacity} attendees',
              style: TextStyles.bodyMedium.copyWith(
                color: _getCapacityColor(attendeesCount, event.capacity!),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        
        // Space
        if (hasWaitlist && showWaitlist) const SizedBox(height: 4),
        
        // Waitlist info
        if (hasWaitlist && showWaitlist)
          Row(
            children: [
              const Icon(
                Icons.people_outline,
                size: 16,
                color: AppColors.warningColor,
              ),
              const SizedBox(width: 8),
              Text(
                '$waitlistCount people on waitlist',
                style: TextStyles.bodySmall.copyWith(
                  color: AppColors.warningColor,
                ),
              ),
            ],
          ),
          
        // User waitlist status
        if (isUserOnWaitlist)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppColors.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.warningColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 14,
                    color: AppColors.warningColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'You are on the waitlist',
                    style: TextStyles.bodySmall.copyWith(
                      color: AppColors.warningColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
  
  /// Get the appropriate icon for the capacity
  IconData _getCapacityIcon(int attendees, int capacity) {
    final ratio = attendees / capacity;
    
    if (ratio >= 0.9) {
      return Icons.people_alt;
    } else if (ratio >= 0.7) {
      return Icons.group;
    } else {
      return Icons.groups_outlined;
    }
  }
  
  /// Get the appropriate color for the capacity
  Color _getCapacityColor(int attendees, int capacity) {
    final ratio = attendees / capacity;
    
    if (ratio >= 0.9) {
      return AppColors.warningColor;
    } else if (ratio >= 0.7) {
      return AppColors.secondaryColor;
    } else {
      return AppColors.primaryTextColor;
    }
  }
} 