import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/event.dart';
import '../../theme/app_colors.dart';
import '../optimized_image.dart';

/// A shared component for displaying event headers consistently across the app
class EventHeader extends StatelessWidget {
  /// The event to display
  final Event event;

  /// Optional hero tag for transitions
  final String? heroTag;

  /// Height of the image in pixels
  final double imageHeight;

  /// Whether to show the full date (vs. relative date)
  final bool showFullDate;

  /// Whether to show the organizer
  final bool showOrganizer;

  /// Called when the header is tapped
  final VoidCallback? onTap;

  /// Constructor
  const EventHeader({
    Key? key,
    required this.event,
    this.heroTag,
    this.imageHeight = 200,
    this.showFullDate = false,
    this.showOrganizer = true,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          HapticFeedback.selectionClick();
          onTap!();
        }
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Event image
            Stack(
              children: [
                // Image
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: SizedBox(
                    height: imageHeight,
                    child: _buildEventImage(),
                  ),
                ),

                // Gradient overlay for better text contrast
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                ),

                // Event date and location overlay
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.yellow.withOpacity(0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          _formatEventDate(),
                          style: GoogleFonts.inter(
                            color: AppColors.yellow,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Location with icon
                      if (event.location.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              _isVirtualEvent(event.location)
                                  ? Icons.videocam_outlined
                                  : Icons.location_on_outlined,
                              color: AppColors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.location,
                                style: GoogleFonts.inter(
                                  color: AppColors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                      if (showOrganizer && event.organizerName.isNotEmpty) ...[
                        const SizedBox(height: 4),

                        // Organizer
                        Text(
                          'by ${event.organizerName}',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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

  /// Build the event image with hero animation if tag is provided
  Widget _buildEventImage() {
    // Check if the image URL is empty or invalid
    final safeUrl = event.safeImageUrl;
    
    final Widget imageWidget = safeUrl.isNotEmpty
        ? OptimizedImage(
            imageUrl: safeUrl,
            width: double.infinity,
            height: imageHeight,
            fit: BoxFit.cover,
          )
        : Container(
            width: double.infinity,
            height: imageHeight,
            color: AppColors.cardBackground,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/hivelogo.png',
                    width: 80,
                    height: 80,
                    color: AppColors.gold.withOpacity(0.7),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "No image available",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );

    if (heroTag != null) {
      return Material(
        type: MaterialType.transparency,
        child: Hero(
          tag: 'event_header_${heroTag!}',
          child: imageWidget,
        ),
      );
    }

    return imageWidget;
  }

  /// Format the event date based on the showFullDate flag
  String _formatEventDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final eventDate = DateTime(
        event.startDate.year, event.startDate.month, event.startDate.day);

    if (!showFullDate) {
      // For compact display, just show "Today", "Tomorrow", or the date
      if (eventDate.isAtSameMomentAs(today)) {
        return 'Today';
      } else if (eventDate.isAtSameMomentAs(tomorrow)) {
        return 'Tomorrow';
      } else {
        return DateFormat('MMM d').format(event.startDate);
      }
    } else {
      // Full date format includes time
      final timeFormat = DateFormat('h:mm a');

      if (eventDate.isAtSameMomentAs(today)) {
        return 'Today at ${timeFormat.format(event.startDate)}';
      } else if (eventDate.isAtSameMomentAs(tomorrow)) {
        return 'Tomorrow at ${timeFormat.format(event.startDate)}';
      } else {
        return '${DateFormat('EEEE, MMM d').format(event.startDate)} at ${timeFormat.format(event.startDate)}';
      }
    }
  }

  /// Check if the event is virtual based on the location text
  bool _isVirtualEvent(String location) {
    final locationLower = location.toLowerCase();
    return locationLower.contains('zoom') ||
        locationLower.contains('virtual') ||
        locationLower.contains('online') ||
        locationLower.contains('teams') ||
        locationLower.contains('meet') ||
        locationLower.contains('webinar');
  }
}
