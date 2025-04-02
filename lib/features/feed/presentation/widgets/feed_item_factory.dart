import 'package:flutter/material.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/models/repost_content_type.dart';
import 'package:hive_ui/models/space_recommendation_simple.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Factory class for creating feed item widgets
class FeedItemFactory {
  // Brand colors
  static const Color black = Color(0xFF0A0A0A);
  static const Color white = Color(0xFFFFFFFF);
  static const Color secondaryText = Color(0xFFBFBFBF);
  static const Color tertiaryText = Color(0xFF808080);
  static const Color yellow = Color(0xFFFFD700);

  /// Creates the appropriate widget for a feed item based on its type
  static Widget createFeedItem(Map<String, dynamic> item) {
    final type = item['type'] as String;
    final data = item['data'];

    switch (type) {
      case 'event':
        return _buildEventCard(data as Event);
      case 'repost':
        return _buildRepostCard(
          event: data.event as Event,
          reposter: data.reposterProfile,
          repostTime: data.repostTime,
          comment: data.comment,
          contentType: data.contentType as RepostContentType,
        );
      case 'recommendation':
        return _buildSpaceRecommendationCard(data as SpaceRecommendationSimple);
      default:
        return const SizedBox.shrink(); // Empty widget for unknown types
    }
  }

  static Widget _buildEventCard(Event event) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          // Event tap handler will be added later
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: GoogleFonts.inter(
                  color: white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.25,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                event.description,
                style: GoogleFonts.inter(
                  color: secondaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    event.formattedTimeRange,
                    style: GoogleFonts.inter(
                      color: tertiaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.2,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      // RSVP handler will be added later
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: yellow,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ).copyWith(
                      overlayColor: MaterialStateProperty.resolveWith<Color?>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.pressed)) {
                            return yellow.withOpacity(0.15);
                          }
                          return null;
                        },
                      ),
                    ),
                    child: Text(
                      'RSVP',
                      style: GoogleFonts.inter(
                        color: yellow,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildRepostCard({
    required Event event,
    required dynamic reposter,
    required DateTime repostTime,
    String? comment,
    required RepostContentType contentType,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.repeat, size: 16, color: yellow),
                const SizedBox(width: 8),
                Text(
                  'Reposted by ${reposter?.displayName ?? "Someone"}',
                  style: GoogleFonts.inter(
                    color: secondaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
            if (comment != null) ...[
              const SizedBox(height: 8),
              Text(
                comment,
                style: GoogleFonts.inter(
                  color: white,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                ),
              ),
            ],
            const SizedBox(height: 8),
            _buildEventCard(event),
          ],
        ),
      ),
    );
  }

  static Widget _buildSpaceRecommendationCard(SpaceRecommendationSimple space) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          // Space tap handler will be added later
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.group, size: 16, color: yellow),
                  const SizedBox(width: 8),
                  Text(
                    'Recommended Space',
                    style: GoogleFonts.inter(
                      color: secondaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(space.score * 100).round()}% match',
                    style: GoogleFonts.inter(
                      color: tertiaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                space.name,
                style: GoogleFonts.inter(
                  color: white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.25,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                space.description,
                style: GoogleFonts.inter(
                  color: secondaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                space.category,
                style: GoogleFonts.inter(
                  color: tertiaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 