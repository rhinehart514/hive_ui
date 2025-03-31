import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/theme/app_colors.dart' as app_colors;
import 'package:intl/intl.dart';
import 'package:hive_ui/theme/huge_icons.dart';
import 'package:hive_ui/theme/app_icons.dart';
import 'event_details/event_image.dart';

/// A swipeable card that displays event information
/// Used in the Tinder-like feed interface
class SwipeableEventCard extends StatefulWidget {
  final Event event;
  final Function(Event) onRSVP;
  final Function(Event) onShare;
  final Function(Event) onView;
  final Function(Event, DismissDirection) onSwipe;
  final int attendeeCount;

  const SwipeableEventCard({
    super.key,
    required this.event,
    required this.onRSVP,
    required this.onShare,
    required this.onView,
    required this.onSwipe,
    this.attendeeCount = 0,
  });

  @override
  State<SwipeableEventCard> createState() => _SwipeableEventCardState();
}

class _SwipeableEventCardState extends State<SwipeableEventCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Track press state
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller for press feedback
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: SizedBox(
            width: MediaQuery.of(context).size.width - 32,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: Dismissible(
                key: Key('event-${widget.event.id}'),
                direction: DismissDirection.horizontal,
                onDismissed: (direction) {
                  widget.onSwipe(widget.event, direction);
                },
                background: _buildSwipeBackground(SwipeDirection.left),
                secondaryBackground:
                    _buildSwipeBackground(SwipeDirection.right),
                child: GestureDetector(
                  onTapDown: (_) {
                    setState(() {
                      _isPressed = true;
                      _animationController.forward();
                    });
                  },
                  onTapUp: (_) {
                    setState(() {
                      _isPressed = false;
                      _animationController.reverse();
                    });
                    widget.onView(widget.event);
                  },
                  onTapCancel: () {
                    setState(() {
                      _isPressed = false;
                      _animationController.reverse();
                    });
                  },
                  child: _buildCardContent(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardContent() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFFEEBA2A).withOpacity(0.1),
            blurRadius: 16,
            spreadRadius: -2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show image first if available
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: EventImage(
                event: widget.event,
                height: 240,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            _buildCardHeader(),

            // Event title
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                widget.event.title,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Event description
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                widget.event.description,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: Colors.white.withOpacity(0.9),
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Event metadata
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date and time
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: app_colors.AppColors.gold,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMM d • h:mm a')
                            .format(widget.event.startDate),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Location
                  Row(
                    children: [
                      Icon(
                        widget.event.location.toLowerCase().contains('zoom')
                            ? Icons.videocam
                            : Icons.location_on,
                        size: 16,
                        color: app_colors.AppColors.gold,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.event.location,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
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

            const Divider(
              color: Color(0x22FFFFFF),
              height: 1,
              thickness: 1,
            ),

            // Action buttons
            _buildActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Organizer profile picture
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                widget.event.organizerName.isNotEmpty
                    ? widget.event.organizerName[0].toUpperCase()
                    : '?',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Organizer details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.event.organizerName,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.verified,
                      color: app_colors.AppColors.gold,
                      size: 14,
                    ),
                  ],
                ),
                Text(
                  DateFormat('MMMM d, yyyy').format(widget.event.startDate),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),

          // Time pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Text(
              DateFormat('h:mm a').format(widget.event.startDate),
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Attendee count with people icon
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: app_colors.AppColors.cardBackground.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      HugeIcons.people,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatAttendeeCount(widget.attendeeCount),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // RSVP button
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  widget.onRSVP(widget.event);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        HugeIcons.add,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'RSVP',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Additional action buttons
          Row(
            children: [
              // Join Discussion button
              _buildActionButton(
                icon: AppIcons.message,
                label: 'Join Discussion',
                onTap: () {
                  HapticFeedback.selectionClick();
                  // Navigate to discussion page
                },
              ),
              const SizedBox(width: 12),
              // Boost button
              _buildActionButton(
                icon: Icons.rocket_launch_outlined,
                label: 'Boost',
                onTap: () {
                  HapticFeedback.selectionClick();
                  // Handle boost functionality
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Format attendee count according to rules
  String _formatAttendeeCount(int count) {
    if (count < 10) {
      return '<10';
    } else if (count >= 25) {
      return '$count 🔥';
    } else {
      return count.toString();
    }
  }

  Widget _buildSwipeBackground(SwipeDirection direction) {
    final isLeft = direction == SwipeDirection.left;
    final icon = isLeft ? Icons.close : Icons.event_available;
    final label = isLeft ? 'Skip' : 'RSVP';
    final backgroundColor = isLeft
        ? Colors.red.withOpacity(0.2)
        : app_colors.AppColors.gold.withOpacity(0.2);
    final textColor = isLeft ? Colors.red : app_colors.AppColors.gold;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: textColor,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

enum SwipeDirection {
  left,
  right,
}
