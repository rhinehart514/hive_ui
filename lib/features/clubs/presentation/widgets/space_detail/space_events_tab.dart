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
    // Get screen metrics for adaptive layout
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with optional "Create Event" button
        Padding(
          padding: EdgeInsets.fromLTRB(
            isSmallScreen ? 12 : 16, 
            isSmallScreen ? 12 : 16, 
            isSmallScreen ? 12 : 16, 
            8
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Upcoming Events',
                  style: GoogleFonts.inter(
                    color: AppColors.white,
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.25,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isManager && onCreateEvent != null)
                TextButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    onCreateEvent!();
                  },
                  icon: Icon(Icons.add, size: isSmallScreen ? 16 : 18),
                  label: Text(
                    'Create',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 13 : 14,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.gold,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 8 : 12, 
                      vertical: isSmallScreen ? 6 : 8
                    ),
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
                  padding: EdgeInsets.fromLTRB(
                    isSmallScreen ? 12 : 16, 
                    0, 
                    isSmallScreen ? 12 : 16, 
                    16
                  ),
                  // Add cacheExtent for smoother scrolling
                  cacheExtent: 500,
                  // Add clipBehavior for better rendering performance
                  clipBehavior: Clip.hardEdge,
                  // Use physics that match platform conventions
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()
                  ),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    // Use RepaintBoundary for better performance
                    return RepaintBoundary(
                      child: _buildEventCard(events[index], isSmallScreen),
                    );
                  },
                ),
        ),
      ],
    );
  }
  
  Widget _buildEventCard(Event event, bool isSmallScreen) {
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
      padding: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
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
                    height: isSmallScreen ? 100 : 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    // Add placeholder for better loading experience
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: isSmallScreen ? 100 : 120,
                        color: Colors.grey[800],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / 
                                  loadingProgress.expectedTotalBytes!
                                : null,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: isSmallScreen ? 80 : 100,
                      color: Colors.grey[800],
                      child: Center(
                        child: Icon(
                          Icons.event,
                          color: AppColors.white.withOpacity(0.3),
                          size: isSmallScreen ? 24 : 32,
                        ),
                      ),
                    ),
                  ),
                ),
              
              Padding(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date block - smaller on small screens
                    Container(
                      width: isSmallScreen ? 42 : 50,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            dayOfWeek.toUpperCase(),
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: isSmallScreen ? 9 : 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            day,
                            style: GoogleFonts.inter(
                              color: AppColors.white,
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            month.toUpperCase(),
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: isSmallScreen ? 9 : 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(width: isSmallScreen ? 12 : 16),
                    
                    // Event details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Title
                          Text(
                            event.title,
                            style: GoogleFonts.inter(
                              color: AppColors.white,
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          SizedBox(height: isSmallScreen ? 6 : 8),
                          
                          // Time
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                color: AppColors.textSecondary,
                                size: isSmallScreen ? 12 : 14,
                              ),
                              SizedBox(width: isSmallScreen ? 3 : 4),
                              Expanded(
                                child: Text(
                                  endTime.isNotEmpty
                                      ? '$startTime - $endTime'
                                      : startTime,
                                  style: GoogleFonts.inter(
                                    color: AppColors.textSecondary,
                                    fontSize: isSmallScreen ? 11 : 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          
                          // Location if available
                          if (event.location.isNotEmpty) ...[
                            SizedBox(height: isSmallScreen ? 3 : 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  color: AppColors.textSecondary,
                                  size: isSmallScreen ? 12 : 14,
                                ),
                                SizedBox(width: isSmallScreen ? 3 : 4),
                                Expanded(
                                  child: Text(
                                    event.location,
                                    style: GoogleFonts.inter(
                                      color: AppColors.textSecondary,
                                      fontSize: isSmallScreen ? 11 : 12,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          
                          SizedBox(height: isSmallScreen ? 6 : 8),
                          
                          // RSVP status and attendee count in a row that can wrap if needed
                          Wrap(
                            spacing: isSmallScreen ? 6 : 8,
                            runSpacing: isSmallScreen ? 6 : 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              isRsvped
                                  ? _buildRsvpChip('Going', true, isSmallScreen)
                                  : _buildRsvpChip('RSVP', false, isSmallScreen),
                              
                              Text(
                                '$attendeeCount attending',
                                style: GoogleFonts.inter(
                                  color: AppColors.textTertiary,
                                  fontSize: isSmallScreen ? 10 : 12,
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
  
  Widget _buildRsvpChip(String label, bool isActive, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8 : 12, 
        vertical: isSmallScreen ? 3 : 4
      ),
      decoration: BoxDecoration(
        color: isActive ? AppColors.gold.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
        border: Border.all(
          color: isActive ? AppColors.gold : AppColors.textSecondary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: isActive ? AppColors.gold : AppColors.textSecondary,
          fontSize: isSmallScreen ? 10 : 12,
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