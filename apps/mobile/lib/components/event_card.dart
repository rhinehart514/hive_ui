import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/huge_icons.dart';
import 'package:intl/intl.dart';
import 'event_details/event_image.dart';

enum EventStatus {
  upcoming,
  inProgress,
  completed,
  cancelled,
}

/// Card component for displaying an event in lists and feeds
/// Optimized for mobile devices with scrollable content
class EventCard extends ConsumerStatefulWidget {
  /// The event to display
  final Event event;

  /// Called when the card is tapped
  final VoidCallback? onTap;

  /// Called when the user RSVPs to the event
  final Function(Event)? onRsvp;

  /// Whether this is a featured event (highlighted visually)
  final bool isFeatured;

  /// Whether this event has been RSVP'd to by the user
  final bool isRsvped;

  /// Custom hero tag for transitions
  final String? heroTag;

  /// Constructor
  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.onRsvp,
    this.isFeatured = false,
    this.isRsvped = false,
    this.heroTag,
  });

  @override
  ConsumerState<EventCard> createState() => _EventCardState();
}

class _EventCardState extends ConsumerState<EventCard>
    with SingleTickerProviderStateMixin {
  // Animation controller for touch interactions and transitions
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    // Setup animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('E, MMM d');
    final timeFormat = DateFormat('h:mm a');
    final formattedDate = dateFormat.format(widget.event.startDate);
    final formattedTime = timeFormat.format(widget.event.startDate);

    // Get screen dimensions to make card more responsive
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    // Adaptive sizes based on screen width
    final double imageHeight = isSmallScreen ? 130.0 : 150.0;
    final double contentPadding = isSmallScreen ? 10.0 : 12.0;
    final double iconSize = isSmallScreen ? 14.0 : 16.0;
    final double fontSize = isSmallScreen ? 12.0 : 14.0;
    final double titleFontSize = isSmallScreen ? 15.0 : 16.0;

    return InkWell(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onTap?.call();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        // Use constraints instead of fixed height to allow content to determine size
        constraints: const BoxConstraints(
          maxHeight: 320,
        ),
        margin: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 8 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isFeatured
                ? AppColors.gold.withOpacity(0.5)
                : AppColors.cardBorder,
            width: widget.isFeatured ? 1.5 : 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min, // Prevent Column from expanding unnecessarily
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Host/Organizer at the top
            if (widget.event.organizerName.isNotEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  contentPadding,
                  contentPadding * 0.8,
                  contentPadding,
                  contentPadding * 0.4,
                ),
                child: Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.user,
                      size: iconSize,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.event.organizerName,
                        style: AppTheme.bodyMedium.copyWith(
                          fontSize: fontSize,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            // Event image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: EventImage(
                event: widget.event,
                height: imageHeight,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            // Content area - Make scrollable when needed
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.all(contentPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title - handle overflow and limit lines
                    Text(
                      widget.event.title,
                      style: AppTheme.titleMedium.copyWith(
                        fontSize: titleFontSize,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    SizedBox(height: contentPadding * 0.5),

                    // Date & Time information
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HugeIcon(
                          icon: HugeIcons.calendar,
                          size: iconSize,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formattedDate,
                          style: AppTheme.bodyMedium.copyWith(
                            fontSize: fontSize,
                          ),
                        ),
                        SizedBox(width: contentPadding),
                        HugeIcon(
                          icon: HugeIcons.clock,
                          size: iconSize,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formattedTime,
                          style: AppTheme.bodyMedium.copyWith(
                            fontSize: fontSize,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: contentPadding * 0.5),

                    // Location with single line
                    Row(
                      children: [
                        HugeIcon(
                          icon: Icons.location_on,
                          size: iconSize,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.event.location,
                            style: AppTheme.bodyMedium.copyWith(
                              fontSize: fontSize,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Action bar - fixed at bottom of card, outside of scroll area
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: contentPadding,
                vertical: contentPadding * 0.5,
              ),
              child: Center(
                child: SizedBox(
                  width: isSmallScreen ? 120 : 140, // Narrower RSVP button
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      widget.onRsvp?.call(widget.event);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          widget.isRsvped ? AppColors.success : AppColors.gold,
                      foregroundColor:
                          widget.isRsvped ? Colors.white : Colors.black,
                      padding: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 6 : 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: Size.fromHeight(isSmallScreen ? 30 : 34),
                    ),
                    child: Text(
                      widget.isRsvped ? 'Going' : 'RSVP',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: fontSize,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
