import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/models/event.dart';
import 'package:intl/intl.dart';

/// A tab to display events for a space
class SpaceEventsTab extends StatelessWidget {
  final List<Event> events;
  final Function(Event) onEventTap;
  final VoidCallback? onCreateEvent;
  final bool isManager;
  final Map<String, bool>? rsvpStatuses; // Map of event IDs to RSVP status
  
  const SpaceEventsTab({
    Key? key,
    required this.events,
    required this.onEventTap,
    this.onCreateEvent,
    this.isManager = false,
    this.rsvpStatuses,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with optional "Create Event" button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Upcoming Events',
                style: GoogleFonts.inter(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.25,
                ),
              ),
              if (isManager && onCreateEvent != null)
                TextButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    onCreateEvent!();
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Create'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.gold,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ).copyWith(
                    overlayColor: MaterialStateProperty.resolveWith<Color?>(
                      (Set<MaterialState> states) {
                        if (states.contains(MaterialState.pressed)) {
                          return AppColors.gold.withOpacity(0.15);
                        }
                        return null;
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        // Events list
        Expanded(
          child: events.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(0),
                  itemCount: events.length,
                  itemBuilder: (context, index) => _buildEventCard(events[index]),
                ),
        ),
      ],
    );
  }
  
  Widget _buildEventCard(Event event) {
    // Get formatted date strings
    final DateTime eventDate = event.startDate;
    final String dayOfWeek = DateFormat('E').format(eventDate);
    final String day = DateFormat('d').format(eventDate);
    final String month = DateFormat('MMM').format(eventDate);
    final String startTime = DateFormat('h:mm a').format(eventDate);
    final String endTime = event.endDate != null 
        ? DateFormat('h:mm a').format(event.endDate) 
        : '';
    
    // Determine RSVP status from the provided map or default to false
    final bool isRsvped = rsvpStatuses != null ? 
        (rsvpStatuses![event.id] ?? false) : false;
    
    // Get attendee count from event.attendees
    final int attendeeCount = event.attendees.length;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onEventTap(event);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.cardBorder,
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event image if available
              if (event.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Image.network(
                    event.imageUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 80,
                      color: Colors.grey[800],
                      child: Center(
                        child: Icon(
                          Icons.event,
                          color: AppColors.white.withOpacity(0.3),
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date block
                    Container(
                      width: 50,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            dayOfWeek.toUpperCase(),
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            day,
                            style: GoogleFonts.inter(
                              color: AppColors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            month.toUpperCase(),
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Event details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            event.title,
                            style: GoogleFonts.inter(
                              color: AppColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Time
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                color: AppColors.textSecondary,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                endTime.isNotEmpty
                                    ? '$startTime - $endTime'
                                    : startTime,
                                style: GoogleFonts.inter(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                          
                          // Location if available
                          if (event.location.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  color: AppColors.textSecondary,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    event.location,
                                    style: GoogleFonts.inter(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          
                          const SizedBox(height: 8),
                          
                          // RSVP status
                          Row(
                            children: [
                              isRsvped
                                  ? _buildRsvpChip('Going', true)
                                  : _buildRsvpChip('RSVP', false),
                              
                              const SizedBox(width: 8),
                              
                              // Attendee count
                              Text(
                                '$attendeeCount attending',
                                style: GoogleFonts.inter(
                                  color: AppColors.textTertiary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
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
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildRsvpChip(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? AppColors.gold.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? AppColors.gold : AppColors.textSecondary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: isActive ? AppColors.gold : AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_outlined,
            size: 48,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No upcoming events',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for events from this space',
            style: GoogleFonts.inter(
              color: AppColors.textTertiary,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          if (isManager && onCreateEvent != null) ...[
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                onCreateEvent!();
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create Event'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.gold,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ).copyWith(
                overlayColor: MaterialStateProperty.resolveWith<Color?>(
                  (Set<MaterialState> states) {
                    if (states.contains(MaterialState.pressed)) {
                      return AppColors.gold.withOpacity(0.15);
                    }
                    return null;
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
} 