import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/glassmorphism_guide.dart';
import '../models/event.dart';
import '../models/repost_content_type.dart';
import 'event_card/event_card.dart';
import '../pages/event_details_page.dart';

/// Component for displaying a section of events grouped by time
class EventTimeSection extends StatefulWidget {
  /// Title of the section
  final String title;

  /// Events to display
  final List<Event> events;

  /// Message to display when no events are found
  final String emptyMessage;

  /// Whether the section should scroll horizontally
  final bool horizontalScroll;

  /// Callback when an event is tapped
  final Function(Event)? onEventTap;

  /// Callback when RSVP is tapped
  final Function(Event)? onRsvp;

  /// Callback when repost is tapped
  final Function(Event, String?, RepostContentType)? onRepost;

  /// Callback when club name is tapped
  final Function(String)? onClubTap;

  /// Constructor
  const EventTimeSection({
    super.key,
    required this.title,
    required this.events,
    this.emptyMessage = 'No events found',
    this.horizontalScroll = true,
    this.onEventTap,
    this.onRsvp,
    this.onRepost,
    this.onClubTap,
  });

  @override
  State<EventTimeSection> createState() => _EventTimeSectionState();
}

class _EventTimeSectionState extends State<EventTimeSection> {
  @override
  Widget build(BuildContext context) {
    if (widget.events.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context),
        const SizedBox(height: 8),
        widget.horizontalScroll
            ? _buildHorizontalEventList(context)
            : _buildVerticalEventList(context),
      ],
    );
  }

  /// Build the section header
  Widget _buildSectionHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Text(
            widget.title,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${widget.events.length}',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build a horizontal scrolling list of events
  Widget _buildHorizontalEventList(BuildContext context) {
    return SizedBox(
      height: 280, // Bounded height for horizontal scrolling
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.events.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 16, bottom: 8),
            child: SizedBox(
              width: 280,
              child: _buildEventCard(widget.events[index]),
            ),
          );
        },
      ),
    );
  }

  /// Build a vertical list of events
  Widget _buildVerticalEventList(BuildContext context) {
    // Using Column instead of ListView to avoid nesting scrollable widgets
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.events.map((event) {
        return Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          child: _buildEventCard(event),
        );
      }).toList(),
    );
  }

  /// Build an event card
  Widget _buildEventCard(Event event) {
    return HiveEventCard(
      key: ValueKey(event.id),
      event: event,
      onTap: (event) => widget.onEventTap != null
          ? widget.onEventTap!(event)
          : _navigateToEventDetails(event),
      onRsvp: (event) {
        HapticFeedback.mediumImpact();
        widget.onRsvp?.call(event);
      },
      onRepost: widget.onRepost != null 
          ? (event, comment, type) => widget.onRepost!(event, comment, type)
          : null,
    );
  }

  /// Navigate to event details page
  void _navigateToEventDetails(Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailsPage(
          eventId: event.id,
          event: event,
        ),
      ),
    );
  }

  /// Build the empty state
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(GlassmorphismGuide.kRadiusMd),
              border: Border.all(
                color: AppColors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.event_busy_outlined,
                    size: 48,
                    color: AppColors.white.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.emptyMessage,
                    style: TextStyle(
                      color: AppColors.white.withOpacity(0.7),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
