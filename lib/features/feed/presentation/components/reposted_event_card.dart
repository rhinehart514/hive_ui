import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/models/repost_item.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:intl/intl.dart';

/// A card component for reposted events
/// Shows the original event along with the reposter's information and comment
class RepostedEventCard extends ConsumerWidget {
  /// The original event
  final Event event;
  
  /// The repost data
  final RepostItem repost;
  
  /// Called when the card is tapped
  final Function(Event) onTap;
  
  /// Called when the user RSVPs to this event
  final Function(Event)? onRsvp;
  
  /// Called when the user reports this event
  final Function(Event)? onReport;
  
  /// Constructor
  const RepostedEventCard({
    super.key,
    required this.event,
    required this.repost,
    required this.onTap,
    this.onRsvp,
    this.onReport,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formattedDate = DateFormat('E, MMM d • h:mm a').format(event.startDate);
    final formattedRepostTime = DateFormat('MMM d').format(repost.repostTime);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap(event);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Repost header with user info
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // User avatar
                    if (repost.reposterProfile.profileImageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          repost.reposterProfile.profileImageUrl!,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 32,
                              height: 32,
                              color: Colors.grey.shade800,
                              child: const Icon(
                                Icons.person,
                                size: 18,
                                color: Colors.white70,
                              ),
                            );
                          },
                        ),
                      )
                    else
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 18,
                          color: Colors.white70,
                        ),
                      ),
                    const SizedBox(width: 10),
                    
                    // User name and repost info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                repost.reposterProfile.displayName,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                              if (repost.reposterProfile.isVerified)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Icon(
                                    Icons.verified,
                                    size: 14,
                                    color: AppColors.yellow.withOpacity(0.8),
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            'Reposted on $formattedRepostTime',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Repost type badge (if not standard)
                    if (repost.type != RepostContentType.standard)
                      _buildRepostTypeBadge(repost.type),
                  ],
                ),
              ),
              
              // Comment if available
              if (repost.comment != null && repost.comment!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Text(
                    repost.comment!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              
              // Divider
              Divider(
                color: Colors.white.withOpacity(0.1),
                height: 1,
              ),
              
              // Event Image
              if (event.imageUrl.isNotEmpty)
                SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: Image.network(
                    event.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.black26,
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.white70,
                        ),
                      );
                    },
                  ),
                ),
              
              // Event Details
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
                          size: 14,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          formattedDate,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Event title
                    Text(
                      event.title,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    // Location
                    if (event.location.isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              event.location,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    
                    // Attendance info and RSVP button
                    Row(
                      children: [
                        // Organizer
                        Text(
                          event.organizerName,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                          ),
                        ),
                        const Spacer(),
                        
                        // RSVP button
                        SizedBox(
                          height: 36,
                          child: TextButton(
                            onPressed: onRsvp != null ? () {
                              HapticFeedback.mediumImpact();
                              onRsvp!(event);
                            } : null,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.yellow,
                              backgroundColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(
                                  color: AppColors.yellow,
                                  width: 1,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            child: Text(
                              'RSVP',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Build a badge for the repost type (recommendation, comment, etc.)
  Widget _buildRepostTypeBadge(RepostContentType type) {
    Color badgeColor;
    String label;
    IconData iconData;
    
    switch (type) {
      case RepostContentType.recommendation:
        badgeColor = Colors.green.shade700;
        label = 'Recommended';
        iconData = Icons.thumb_up;
        break;
      case RepostContentType.critical:
        badgeColor = Colors.orange.shade700;
        label = 'Critical';
        iconData = Icons.warning_amber;
        break;
      case RepostContentType.comment:
        badgeColor = Colors.blue.shade700;
        label = 'Comment';
        iconData = Icons.chat_bubble;
        break;
      default:
        badgeColor = Colors.grey.shade700;
        label = 'Repost';
        iconData = Icons.repeat;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            iconData,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
} 