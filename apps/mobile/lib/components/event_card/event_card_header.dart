import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/event.dart';
import '../../theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

/// Header component for the EventCard displaying organizer information
class EventCardHeader extends StatelessWidget {
  /// The event to display
  final Event event;

  /// Whether the screen is small
  final bool isSmallScreen;

  /// Whether the screen is very small
  final bool isVerySmallScreen;

  /// Constructor
  const EventCardHeader({
    super.key,
    required this.event,
    required this.isSmallScreen,
    required this.isVerySmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate dynamic padding based on screen size
    final horizontalPadding =
        isVerySmallScreen ? 8.0 : (isSmallScreen ? 12.0 : 16.0);
    final verticalPadding =
        isVerySmallScreen ? 8.0 : (isSmallScreen ? 10.0 : 12.0);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding / 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Organizer avatar
          _buildAvatar(),

          const SizedBox(width: 12),

          // Organizer info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.organizerName,
                  style: GoogleFonts.outfit(
                    fontSize: isVerySmallScreen ? 13 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // Date display
                Text(
                  _getFormattedDate(),
                  style: GoogleFonts.inter(
                    fontSize: isVerySmallScreen ? 11 : 12,
                    color: Colors.white.withOpacity(0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // More options button
          _buildMoreButton(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final size = isVerySmallScreen ? 28.0 : 32.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[900],
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withOpacity(0.15),
            blurRadius: 8,
            spreadRadius: -2,
          ),
        ],
        border: Border.all(
          color: AppColors.gold.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: ClipOval(
        child: _buildFallbackIcon(),
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return Icon(
      Icons.group,
      color: AppColors.gold,
      size: isVerySmallScreen ? 14 : 16,
    );
  }

  Widget _buildMoreButton() {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        // Options menu would go here
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Icon(
          Icons.more_vert,
          color: Colors.white.withOpacity(0.6),
          size: 18,
        ),
      ),
    );
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final eventDate = event.startDate;

    // If event is today
    if (eventDate.year == now.year &&
        eventDate.month == now.month &&
        eventDate.day == now.day) {
      return 'Today';
    }

    // If event is tomorrow
    final tomorrow = now.add(const Duration(days: 1));
    if (eventDate.year == tomorrow.year &&
        eventDate.month == tomorrow.month &&
        eventDate.day == tomorrow.day) {
      return 'Tomorrow';
    }

    // Format as Mar 24
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
    return '${months[eventDate.month - 1]} ${eventDate.day}';
  }
}
