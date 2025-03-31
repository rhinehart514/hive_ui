import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/event.dart';
import '../../models/repost_content_type.dart';
import '../../theme/app_colors.dart';

/// A component that displays the content portion of an event (title, description, actions)
class EventContent extends StatefulWidget {
  /// The event to display
  final Event event;

  /// Whether this is a compact view (for reposts)
  final bool isCompact;

  /// Whether to show the full description (vs truncated)
  final bool showFullDescription;

  /// Called when the RSVP button is tapped
  final Function(Event)? onRsvp;

  /// Called when the Repost button is tapped
  final Function(Event, String?, RepostContentType)? onRepost;

  /// Constructor
  const EventContent({
    Key? key,
    required this.event,
    this.isCompact = false,
    this.showFullDescription = false,
    this.onRsvp,
    this.onRepost,
  }) : super(key: key);

  @override
  State<EventContent> createState() => _EventContentState();
}

class _EventContentState extends State<EventContent> {
  bool _isRsvped = false;

  @override
  void initState() {
    super.initState();
    // Normally we would check if the event is already RSVPed by the user here
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 0,
        vertical: 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event title
          Text(
            widget.event.title,
            style: GoogleFonts.outfit(
              fontSize: widget.isCompact ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 8),

          // Event description - only if not compact
          if (!widget.isCompact)
            Text(
              widget.event.description,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              maxLines: widget.showFullDescription ? null : 3,
              overflow: widget.showFullDescription
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
            ),

          // Action Bar
          if (!widget.isCompact)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  // RSVP Button
                  if (widget.onRsvp != null) _buildRsvpButton(),

                  const Spacer(),

                  // Attendee count
                  _buildAttendeeCount(),

                  const SizedBox(width: 12),

                  // Repost Button
                  if (widget.onRepost != null) _buildRepostButton(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRsvpButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        setState(() {
          _isRsvped = !_isRsvped;
        });
        widget.onRsvp?.call(widget.event);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _isRsvped
              ? AppColors.yellow.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                _isRsvped ? AppColors.yellow : AppColors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isRsvped ? Icons.check_circle_outline : Icons.add_circle_outline,
              color: _isRsvped ? AppColors.yellow : AppColors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              _isRsvped ? 'Going' : 'RSVP',
              style: GoogleFonts.inter(
                color: _isRsvped ? AppColors.yellow : AppColors.white,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendeeCount() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.people_outline,
            color: AppColors.textSecondary,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            _formatAttendeeCount(widget.event.attendees.length),
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepostButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        // The repost dialog would be shown here
        widget.onRepost?.call(widget.event, null, RepostContentType.standard);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.repeat,
          color: AppColors.white.withOpacity(0.6),
          size: 20,
        ),
      ),
    );
  }

  String _formatAttendeeCount(int count) {
    if (count == 0) {
      return 'No Attendees';
    } else if (count == 1) {
      return '1 Attendee';
    } else if (count < 1000) {
      return '$count Attendees';
    } else {
      // Format to k for thousands (e.g., 1.5k)
      final k = (count / 1000).toStringAsFixed(1);
      return '${k}k Attendees';
    }
  }
}
