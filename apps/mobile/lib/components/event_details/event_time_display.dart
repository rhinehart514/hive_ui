import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';

/// A component that displays the start and end time of an event
class EventTimeDisplay extends StatelessWidget {
  /// Start date of the event
  final DateTime startDate;

  /// End date of the event
  final DateTime endDate;

  /// Whether to show the year
  final bool showYear;

  /// Whether to show the weekday
  final bool showWeekday;

  /// Whether to show the end time
  final bool showEndTime;

  /// Constructor
  const EventTimeDisplay({
    Key? key,
    required this.startDate,
    required this.endDate,
    this.showYear = false,
    this.showWeekday = true,
    this.showEndTime = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isSameDay = startDate.year == endDate.year &&
        startDate.month == endDate.month &&
        startDate.day == endDate.day;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date heading
        Text(
          _formatDateHeading(),
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        // Time details with icon
        Row(
          children: [
            const Icon(
              Icons.access_time,
              color: AppColors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              _formatTimeRange(isSameDay),
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),

        // Duration information
        const SizedBox(height: 4),
        Row(
          children: [
            const SizedBox(width: 26), // Align with the time text
            Text(
              _formatDuration(),
              style: TextStyle(
                color: AppColors.white.withOpacity(0.7),
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Format the date heading
  String _formatDateHeading() {
    final DateFormat dateFormat = DateFormat(showWeekday
        ? (showYear ? 'EEEE, MMMM d, yyyy' : 'EEEE, MMMM d')
        : (showYear ? 'MMMM d, yyyy' : 'MMMM d'));

    return dateFormat.format(startDate);
  }

  /// Format the time range
  String _formatTimeRange(bool isSameDay) {
    final startTime = DateFormat('h:mm a').format(startDate);
    final endTime = DateFormat('h:mm a').format(endDate);

    if (isSameDay) {
      return '$startTime to $endTime';
    } else if (showEndTime) {
      return '$startTime to ${DateFormat('MMM d, h:mm a').format(endDate)}';
    } else {
      return 'Starts at $startTime';
    }
  }

  /// Format the event duration
  String _formatDuration() {
    final duration = endDate.difference(startDate);

    if (duration.inDays > 0) {
      final days = duration.inDays;
      final hours = duration.inHours % 24;
      if (hours == 0) {
        return '$days ${days == 1 ? 'day' : 'days'}';
      } else {
        return '$days ${days == 1 ? 'day' : 'days'} and $hours ${hours == 1 ? 'hour' : 'hours'}';
      }
    } else {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;

      if (hours == 0) {
        return '$minutes ${minutes == 1 ? 'minute' : 'minutes'}';
      } else if (minutes == 0) {
        return '$hours ${hours == 1 ? 'hour' : 'hours'}';
      } else {
        return '$hours ${hours == 1 ? 'hour' : 'hours'} and $minutes ${minutes == 1 ? 'minute' : 'minutes'}';
      }
    }
  }
}
