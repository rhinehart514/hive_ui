import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:hive_ui/features/moderation/domain/entities/content_report_entity.dart';
import 'package:hive_ui/components/moderation/report_button.dart';

/// A standard event card component
/// This is the base template for displaying events in the feed
class StandardEventCard extends ConsumerWidget {
  /// The event to display
  final Event event;
  
  /// Called when the card is tapped
  final Function(Event) onTap;
  
  /// Called when the user RSVPs to this event
  final Function(Event)? onRsvp;
  
  /// Called when the event is reported
  final Function(Event)? onReport;
  
  /// Constructor
  const StandardEventCard({
    super.key,
    required this.event,
    required this.onTap,
    this.onRsvp,
    this.onReport,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formattedDate = DateFormat('E, MMM d • h:mm a').format(event.startDate);
    
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
                    // Date and time with report button
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
                        const Spacer(),
                        _buildReportButton(context),
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

  // Build report button
  Widget _buildReportButton(BuildContext context) {
    return ReportButton(
      contentId: event.id,
      contentType: ReportedContentType.event,
      contentPreview: event.title,
      ownerId: event.createdBy,
      size: 16,
      color: Colors.white54,
    );
  }
} 