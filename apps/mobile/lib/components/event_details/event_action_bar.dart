import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/event.dart';
import '../../theme/app_colors.dart';
import '../../models/repost_content_type.dart';
import '../event_card/repost_options_card.dart';
import '../../features/moderation/domain/entities/content_report_entity.dart';
import '../moderation/report_dialog.dart';

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
  
  /// Whether the RSVP operation is in progress
  final bool isLoading;
  
  /// Whether the current user is the event owner and can edit/cancel
  final bool isEventOwner;
  
  /// Callback when edit event is tapped
  final VoidCallback? onEditTap;
  
  /// Callback when cancel event is tapped
  final VoidCallback? onCancelTap;

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
    this.isLoading = false,
    this.isEventOwner = false,
    this.onEditTap,
    this.onCancelTap,
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
                onTap: isCancelled || isLoading
                    ? null
                    : () {
                        HapticFeedback.mediumImpact();
                        onRsvpTap(!isRsvpd);
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
                          if (isLoading)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.white,
                                ),
                              ),
                            )
                          else
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
                              isLoading
                                ? "Updating..."
                                : (isRsvpd ? "I'm Going" : "RSVP"),
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
                // Add edit/manage event button for event owners
                if (isEventOwner && onEditTap != null && onCancelTap != null)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          HapticFeedback.mediumImpact();
                          onEditTap!();
                          break;
                        case 'cancel':
                          HapticFeedback.mediumImpact();
                          onCancelTap!();
                          break;
                      }
                    },
                    position: PopupMenuPosition.over,
                    offset: const Offset(0, -120),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: AppColors.white.withOpacity(0.1),
                        width: 0.5,
                      ),
                    ),
                    color: AppColors.cardBackground.withOpacity(0.95),
                    elevation: 8,
                    icon: Container(
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
                            event.isCancelled ? Icons.error_outline : Icons.settings,
                            color: event.isCancelled ? AppColors.error : AppColors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Manage',
                            style: TextStyle(
                              color: event.isCancelled ? AppColors.error : AppColors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    itemBuilder: (context) => [
                      if (!event.isCancelled)
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: AppColors.white, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Edit Event',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (!event.isCancelled)
                        const PopupMenuItem<String>(
                          value: 'cancel',
                          child: Row(
                            children: [
                              Icon(Icons.event_busy, color: AppColors.error, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Cancel Event',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                
                // More options button for all users
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'calendar':
                        HapticFeedback.mediumImpact();
                        onAddToCalendarTap();
                        break;
                      case 'share':
                        HapticFeedback.mediumImpact();
                        // Implement share functionality here
                        break;
                      case 'repost':
                        HapticFeedback.mediumImpact();
                        if (onRepost != null) {
                          // Show repost options
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (context) {
                              return RepostOptionsCard(
                                event: event,
                                onRepostSelected: (event, comment, type) {
                                  Navigator.of(context).pop();
                                  onRepost!(event, comment, type);
                                },
                                followsClub: followsClub,
                                todayBoosts: todayBoosts,
                              );
                            },
                          );
                        }
                        break;
                      case 'report':
                        HapticFeedback.mediumImpact();
                        // Show report dialog
                        showReportDialog(
                          context,
                          contentId: event.id,
                          contentType: ReportedContentType.event,
                          contentPreview: '${event.title} - ${event.description.substring(0, event.description.length > 50 ? 50 : event.description.length)}...',
                          ownerId: event.createdBy,
                        );
                        break;
                    }
                  },
                  position: PopupMenuPosition.over,
                  offset: const Offset(0, -175),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: AppColors.white.withOpacity(0.1),
                      width: 0.5,
                    ),
                  ),
                  color: AppColors.cardBackground.withOpacity(0.95),
                  elevation: 8,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground.withOpacity(0.3),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.white.withOpacity(0.15),
                        width: 0.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.more_horiz,
                      color: AppColors.white,
                      size: 18,
                    ),
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem<String>(
                      value: 'calendar',
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: AppColors.white, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Add to Calendar',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share, color: AppColors.white, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Share',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onRepost != null)
                      const PopupMenuItem<String>(
                        value: 'repost',
                        child: Row(
                          children: [
                            Icon(Icons.repeat, color: AppColors.white, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Repost',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Add report option
                    const PopupMenuItem<String>(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.flag_outlined, color: AppColors.warning, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Report Event',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
