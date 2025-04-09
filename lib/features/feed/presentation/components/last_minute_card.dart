import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/models/event.dart';
import 'package:intl/intl.dart';

/// A card component for last-minute events
/// Features countdown visual and urgency CTA
class LastMinuteCard extends ConsumerWidget {
  /// The event to display
  final Event event;
  
  /// Called when the card is tapped
  final Function(Event) onTap;
  
  /// Called when the user RSVPs to this event
  final Function(Event)? onRsvp;
  
  /// Called when the user reports this event
  final Function(Event)? onReport;
  
  /// Time remaining until the event starts
  final Duration timeRemaining;
  
  /// Constructor
  const LastMinuteCard({
    super.key,
    required this.event,
    required this.onTap,
    this.onRsvp,
    this.onReport,
    required this.timeRemaining,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formattedDate = DateFormat('E, MMM d • h:mm a').format(event.startDate);
    final timeRemainingText = _formatTimeRemaining();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.redAccent.withOpacity(0.4),
          width: 1,
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
              // Urgency Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.redAccent.withOpacity(0.3),
                      Colors.redAccent.withOpacity(0.1),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.timer,
                      size: 16,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'STARTING SOON',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.redAccent,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '•',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.redAccent.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeRemainingText,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.redAccent.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
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
                        // Attendee count
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.people_outline,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${event.attendees.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        
                        // RSVP button
                        SizedBox(
                          height: 36,
                          child: ElevatedButton(
                            onPressed: onRsvp != null ? () {
                              HapticFeedback.mediumImpact();
                              onRsvp!(event);
                            } : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            child: Text(
                              'JOIN NOW',
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
  
  /// Format the time remaining string
  String _formatTimeRemaining() {
    if (timeRemaining.inHours > 0) {
      return '${timeRemaining.inHours}h ${timeRemaining.inMinutes.remainder(60)}m remaining';
    } else if (timeRemaining.inMinutes > 0) {
      return '${timeRemaining.inMinutes}m remaining';
    } else {
      return 'Starting now!';
    }
  }
} 