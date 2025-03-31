import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../../theme/app_colors.dart';
import '../optimized_image.dart';
import 'package:google_fonts/google_fonts.dart';

/// Content component for EventCard displaying the event image, title and details
class EventCardContent extends StatefulWidget {
  /// The event to display
  final Event event;

  /// Hero tag for transitions
  final String? heroTag;

  /// Whether this is a compact version
  final bool isCompact;

  /// Whether the screen is small
  final bool isSmallScreen;

  /// Whether the screen is very small
  final bool isVerySmallScreen;

  /// Constructor
  const EventCardContent({
    super.key,
    required this.event,
    this.heroTag,
    this.isCompact = false,
    required this.isSmallScreen,
    required this.isVerySmallScreen,
  });

  @override
  State<EventCardContent> createState() => _EventCardContentState();
}

class _EventCardContentState extends State<EventCardContent> {
  bool _isImageLoading = true;

  @override
  Widget build(BuildContext context) {
    // Calculate sizes based on screen size for better mobile optimization
    final imageHeight = widget.isCompact
        ? 120.0
        : (widget.isVerySmallScreen
            ? 150.0
            : (widget.isSmallScreen ? 170.0 : 190.0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Event image with overlays
        _buildEventImage(imageHeight),

        // Event details
        _buildEventDetails(),
      ],
    );
  }

  Widget _buildEventImage(double height) {
    return Stack(
      children: [
        // Event image
        SizedBox(
          height: height,
          child: widget.heroTag != null
              ? Hero(
                  tag: 'event_card_${widget.heroTag!}',
                  child: _buildImage(height),
                )
              : _buildImage(height),
        ),

        // Time badge overlay
        Positioned(
          top: 12,
          left: 12,
          child: _buildTimeBadge(),
        ),

        // Status badge (if event is happening soon or today)
        if (widget.event.isToday || widget.event.isCancelled)
          Positioned(
            top: 12,
            right: 12,
            child: _buildStatusBadge(),
          ),
      ],
    );
  }

  Widget _buildImage(double height) {
    return ClipRRect(
      borderRadius: widget.isCompact
          ? const BorderRadius.vertical(top: Radius.circular(8))
          : BorderRadius.zero,
      child: Stack(
        children: [
          // Placeholder color
          Container(
            height: height,
            color: Colors.grey[900],
          ),

          // Actual image
          if (widget.event.imageUrl.isNotEmpty)
            OptimizedImage(
              imageUrl: widget.event.imageUrl,
              fit: BoxFit.cover,
              height: height,
              width: double.infinity,
            ),

          // Loading state
          if (_isImageLoading && widget.event.imageUrl.isNotEmpty)
            Container(
              height: height,
              color: Colors.black45,
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),

          // Add a separate error handler for when image fails to load
          if (widget.event.imageUrl.isEmpty)
            Container(
              height: height,
              color: Colors.grey[900],
              child: Center(
                child: Icon(
                  Icons.event,
                  color: AppColors.gold.withOpacity(0.7),
                  size: 48,
                ),
              ),
            ),

          // Gradient overlay for text readability
          Container(
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.7),
                ],
                stops: const [0.6, 1.0],
              ),
            ),
          ),

          // Location only (removed title from here to avoid duplication)
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: !widget.isCompact
                ? Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.white.withOpacity(0.9),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.event.location,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.7),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Simulate image loading completion after a delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isImageLoading = false;
        });
      }
    });
  }

  Widget _buildTimeBadge() {
    final bool isToday = widget.event.isToday;
    final bool isTomorrow = _isEventTomorrow();

    String dateText;
    if (isToday) {
      dateText = 'Today';
    } else if (isTomorrow) {
      dateText = 'Tomorrow';
    } else {
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      dateText =
          '${months[widget.event.startDate.month - 1]} ${widget.event.startDate.day}';
    }

    // Format time (9:00 AM)
    final hour = widget.event.startDate.hour % 12 == 0
        ? 12
        : widget.event.startDate.hour % 12;
    final minute = widget.event.startDate.minute.toString().padLeft(2, '0');
    final period = widget.event.startDate.hour >= 12 ? 'PM' : 'AM';

    return Semantics(
      label: 'Event time: $dateText at $hour:$minute $period',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: AppColors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isToday
                ? AppColors.gold.withOpacity(0.5)
                : Colors.white.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date (Today, Tomorrow, or Mar 24)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today,
                  color: isToday ? AppColors.gold : Colors.white,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  dateText,
                  style: GoogleFonts.outfit(
                    color: isToday ? AppColors.gold : Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            // Time (8:00 PM)
            Padding(
              padding: const EdgeInsets.only(top: 2.0, left: 16.0),
              child: Text(
                '$hour:$minute $period',
                style: GoogleFonts.outfit(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isEventTomorrow() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final eventDate = DateTime(widget.event.startDate.year,
        widget.event.startDate.month, widget.event.startDate.day);

    return eventDate.isAtSameMomentAs(tomorrow);
  }

  Widget _buildStatusBadge() {
    final bool isToday = widget.event.isToday;
    final bool isCancelled = widget.event.isCancelled;

    final Color badgeColor = isCancelled
        ? Colors.red.shade800
        : (isToday ? AppColors.gold : Colors.green);

    final String badgeText =
        isCancelled ? 'Cancelled' : (isToday ? 'Today' : 'Soon');

    final IconData badgeIcon = isCancelled
        ? Icons.cancel_outlined
        : (isToday ? Icons.event_available : Icons.event_busy);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeIcon,
            color: Colors.white,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventDetails() {
    // Event title and details section
    return Padding(
      padding: EdgeInsets.all(widget.isVerySmallScreen ? 10.0 : 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title (only place it appears now)
          Text(
            widget.event.title,
            style: GoogleFonts.outfit(
              fontSize:
                  widget.isCompact ? 16 : (widget.isVerySmallScreen ? 18 : 20),
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2, // Better readability
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 8),

          // Time and location details in a more compact format
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                color: AppColors.gold.withOpacity(0.8),
                size: 16,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _getFormattedEventTime(),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // Description - optional based on space
          if (!widget.isCompact &&
              !widget.isVerySmallScreen &&
              widget.event.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                widget.event.description,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                  height: 1.3, // Better readability
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  String _getFormattedEventTime() {
    // Format time (9:00 AM)
    final hour = widget.event.startDate.hour % 12 == 0
        ? 12
        : widget.event.startDate.hour % 12;
    final minute = widget.event.startDate.minute.toString().padLeft(2, '0');
    final period = widget.event.startDate.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period • ${widget.event.location}';
  }
}
