import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/event.dart';
import '../../theme/app_colors.dart';
import '../../theme/huge_icons.dart';
import '../../models/repost_content_type.dart';
import '../event_card/repost_options_card.dart';

/// A component that displays action buttons for the event
class EventActionBar extends StatelessWidget {
  /// The event
  final Event event;

  /// Whether the user has RSVP'd to this event
  final bool isRsvpd;

  /// Callback when the RSVP button is tapped
  final Function(bool) onRsvpTap;

  /// Callback when the Add to Calendar button is tapped
  final VoidCallback onAddToCalendarTap;
  
  /// Callback when the user reposts the event
  final Function(Event, String?, RepostContentType)? onRepost;
  
  /// Whether the user follows the event's club
  final bool followsClub;
  
  /// List of boost timestamps for today (to check if already boosted)
  final List<DateTime> todayBoosts;

  /// Constructor
  const EventActionBar({
    Key? key,
    required this.event,
    required this.isRsvpd,
    required this.onRsvpTap,
    required this.onAddToCalendarTap,
    this.onRepost,
    this.followsClub = false,
    this.todayBoosts = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isCancelled = event.isCancelled;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.black.withOpacity(0.5),
        border: Border(
          top: BorderSide(
            color: AppColors.white.withOpacity(0.1),
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // RSVP button
            Flexible(
              child: GestureDetector(
                onTap: isCancelled
                    ? null
                    : () {
                        HapticFeedback.mediumImpact();
                        onRsvpTap(isRsvpd);
                      },
                child: Container(
                  decoration: BoxDecoration(
                    color: isCancelled
                        ? AppColors.error.withOpacity(0.15)
                        : (isRsvpd
                            ? AppColors.white.withOpacity(0.15)
                            : Colors.black.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isCancelled ? AppColors.error : AppColors.white,
                      width: 1,
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isRsvpd
                                ? Icons.check_circle
                                : Icons.add_circle_outline,
                            color: AppColors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              isRsvpd ? "I'm Going" : "RSVP",
                              style: const TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Action buttons on the right
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Repost button
                if (!isCancelled && onRepost != null)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      // Show repost options
                      context.showRepostOptions(
                        event: event,
                        onRepostSelected: onRepost!,
                        followsClub: followsClub,
                        todayBoosts: todayBoosts,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.white.withOpacity(0.15),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            HugeIcons.rocket,
                            color: AppColors.yellow.withOpacity(0.8),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Repost',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                
                if (!isCancelled && onRepost != null) const SizedBox(width: 8),

                // Add to Calendar button
                if (!isCancelled)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      onAddToCalendarTap();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.white.withOpacity(0.15),
                          width: 0.5,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            color: AppColors.white,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Calendar',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),

                if (!isCancelled) const SizedBox(width: 8),

                // Attendee count with consistent styling
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.white.withOpacity(0.15),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.people_outline,
                        color: AppColors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatAttendeeCount(event.attendees.length),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Format attendee count
  String _formatAttendeeCount(int count) {
    if (count == 0) return 'No RSVPs';
    if (count == 1) return '1 going';
    if (count < 1000) return '$count going';

    return '${(count / 1000).toStringAsFixed(1)}k going';
  }
}
