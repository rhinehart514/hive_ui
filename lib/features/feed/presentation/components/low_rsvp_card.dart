import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/models/event.dart';
import 'package:intl/intl.dart';

/// A card component for events with low RSVPs
/// Features a "Just getting started" hint to boost curiosity
class LowRsvpCard extends ConsumerWidget {
  /// The event to display
  final Event event;
  
  /// Called when the card is tapped
  final Function(Event) onTap;
  
  /// Called when the user RSVPs to this event
  final Function(Event)? onRsvp;
  
  /// Called when the user reports this event
  final Function(Event)? onReport;
  
  /// Space or organization name
  final String spaceName;
  
  /// Constructor
  const LowRsvpCard({
    super.key,
    required this.event,
    required this.onTap,
    required this.spaceName,
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
          color: const Color(0xFF5E5CE6).withOpacity(0.3), // Purple tint
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
              // "Just getting started" banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF5E5CE6).withOpacity(0.2),
                      Colors.transparent,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: Color(0xFF5E5CE6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'JUST GETTING STARTED',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF5E5CE6),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '• Be an early joiner',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF5E5CE6).withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                    // Space name and date
                    Row(
                      children: [
                        Text(
                          spaceName,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF5E5CE6).withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formattedDate,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Event title
                    Text(
                      event.title,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    // Description snippet
                    if (event.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          event.description.length > 100
                              ? '${event.description.substring(0, 100)}...'
                              : event.description,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    
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
                    const SizedBox(height: 16),
                    
                    // Join info and RSVP button
                    Row(
                      children: [
                        // Current join count
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5E5CE6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.people_outline,
                                size: 14,
                                color: Color(0xFF5E5CE6),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${event.attendees.length} joined',
                                style: const TextStyle(
                                  color: Color(0xFF5E5CE6),
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
                          child: TextButton(
                            onPressed: onRsvp != null ? () {
                              HapticFeedback.mediumImpact();
                              onRsvp!(event);
                            } : null,
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF5E5CE6),
                              backgroundColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(
                                  color: Color(0xFF5E5CE6),
                                  width: 1,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            child: Text(
                              'JOIN GROUP',
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
} 