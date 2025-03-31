import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// Models
import 'package:hive_ui/models/club.dart';
import 'package:hive_ui/models/event.dart';

// Theme and Styling
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/extensions/box_decoration_extensions.dart';

/// A horizontal strip that displays live content (upcoming events, social proof, highlights)
/// Used as the first content after the header in club space
class ClubLiveStrip extends StatelessWidget {
  final Club club;
  final List<Event>? events;
  final VoidCallback? onEventTap;
  final VoidCallback? onSocialProofTap;
  final VoidCallback? onHighlightTap;
  final EdgeInsets padding;

  const ClubLiveStrip({
    Key? key,
    required this.club,
    this.events,
    this.onEventTap,
    this.onSocialProofTap,
    this.onHighlightTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: SizedBox(
        height: 150,
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          children: _buildLiveItems(),
        ),
      ),
    );
  }

  List<Widget> _buildLiveItems() {
    final items = <Widget>[];

    // Priority order: Upcoming Event > Social Proof > Highlight
    if (_hasUpcomingEvents()) {
      items.add(_buildEventTile());
    }

    if (_hasSocialProof()) {
      items.add(_buildSocialProofTile());
    }

    if (items.isEmpty || items.length < 2) {
      items.add(_buildHighlightTile());
    }

    // If still no items, add an empty state tile
    if (items.isEmpty) {
      items.add(_buildEmptyStateTile());
    }

    return items;
  }

  bool _hasUpcomingEvents() {
    return events != null && events!.isNotEmpty;
  }

  bool _hasSocialProof() {
    return club.followersCount > 0 || club.memberCount > 0;
  }

  Widget _buildEventTile() {
    // Use the first upcoming event
    final event = events!.first;
    final DateTime eventDate =
        event.startDate; // Using startDate instead of date

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onEventTap?.call();
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.cardBackground,
        ).addGlassmorphism(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event header with date
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.event,
                          size: 14,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Upcoming',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.gold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatEventDate(eventDate),
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Event title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                event.title,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const Spacer(),

            // RSVP and info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  if (event.attendees
                          .isNotEmpty) // Using attendees instead of attendeeCount
                    Text(
                      '${event.attendees.length} attending',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'RSVP',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialProofTile() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onSocialProofTap?.call();
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.cardBackground,
        ).addGlassmorphism(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.people_outline,
                      size: 14,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Community',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Member count and info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${club.memberCount} members',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${club.followersCount} followers',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Avatars of some members (mockup)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  for (int i = 0; i < 4; i++)
                    Container(
                      width: 30,
                      height: 30,
                      margin: EdgeInsets.only(left: i > 0 ? -8 : 0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[800],
                        border: Border.all(color: AppColors.black, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          String.fromCharCode(65 + i),
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    '+ more',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightTile() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onHighlightTap?.call();
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.cardBackground,
          image: club.bannerUrl != null
              ? DecorationImage(
                  image: NetworkImage(club.bannerUrl!),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.6),
                    BlendMode.darken,
                  ),
                )
              : null,
        ).addGlassmorphism(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_outline,
                      size: 14,
                      color: Colors.purple,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Highlight',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Footer with club description
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About ${club.name}',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getTruncatedDescription(club.description),
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateTile() {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.cardBackground,
      ).addGlassmorphism(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.upcoming_outlined,
            size: 32,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            'No upcoming events',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Check back later for updates',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _formatEventDate(DateTime date) {
    final now = DateTime.now();

    if (date.year == now.year && date.month == now.month) {
      if (date.day == now.day) {
        return 'Today';
      } else if (date.day == now.day + 1) {
        return 'Tomorrow';
      }
    }

    // Format as "Mon, Jan 1"
    return '${_getWeekday(date.weekday)}, ${_getMonth(date.month)} ${date.day}';
  }

  String _getWeekday(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }

  String _getMonth(int month) {
    switch (month) {
      case 1:
        return 'Jan';
      case 2:
        return 'Feb';
      case 3:
        return 'Mar';
      case 4:
        return 'Apr';
      case 5:
        return 'May';
      case 6:
        return 'Jun';
      case 7:
        return 'Jul';
      case 8:
        return 'Aug';
      case 9:
        return 'Sep';
      case 10:
        return 'Oct';
      case 11:
        return 'Nov';
      case 12:
        return 'Dec';
      default:
        return '';
    }
  }

  String _getTruncatedDescription(String description) {
    if (description.length <= 100) return description;
    return '${description.substring(0, 100)}...';
  }
}
