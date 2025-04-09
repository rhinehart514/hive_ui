import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/providers/profile_provider.dart';
import 'package:hive_ui/extensions/glassmorphism_extension.dart';
import 'package:hive_ui/theme/glassmorphism_guide.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/core/event_bus/app_event_bus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:confetti/confetti.dart';
import 'package:hive_ui/features/events/presentation/widgets/event_lifecycle_badge.dart';
import 'dart:math' show pi;
import 'dart:ui';
import 'package:hive_ui/features/events/presentation/routing/event_routes.dart';
import 'package:intl/intl.dart';

/// An enhanced event card with optimistic UI updates and real-time event details integration
class EventCardEnhanced extends ConsumerStatefulWidget {
  /// The event to display
  final Event event;
  
  /// Optional hero tag for animations
  final String? heroTag;
  
  const EventCardEnhanced({
    Key? key,
    required this.event,
    this.heroTag,
  }) : super(key: key);

  @override
  ConsumerState<EventCardEnhanced> createState() => _EventCardEnhancedState();
}

class _EventCardEnhancedState extends ConsumerState<EventCardEnhanced> {
  late ConfettiController _confettiController;
  
  // Optimistic UI state
  bool _isRsvping = false;
  bool _optimisticRsvpState = false;
  
  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );
    
    // Initialize RSVP state
    final userId = FirebaseAuth.instance.currentUser?.uid;
    _optimisticRsvpState = userId != null && 
        widget.event.attendees.contains(userId);
  }
  
  @override
  void didUpdateWidget(EventCardEnhanced oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update RSVP state if event attendees changed and we're not in the middle of an operation
    if (oldWidget.event.attendees != widget.event.attendees && !_isRsvping) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      _optimisticRsvpState = userId != null && 
          widget.event.attendees.contains(userId);
    }
  }
  
  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }
  
  // Navigate to the real-time event details page
  void _navigateToEventDetails() {
    HapticFeedback.mediumImpact();
    
    // Use the EventNavigation helper for consistent routing
    EventNavigation.navigateToEventDetails(
      context,
      widget.event,
      heroTag: widget.heroTag,
    );
  }
  
  // Handle RSVP with optimistic updates
  Future<void> _handleRsvp(bool isAttending) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    
    // Store previous state for rollback if needed
    final previousState = _optimisticRsvpState;
    
    // Apply haptic feedback
    HapticFeedback.mediumImpact();
    
    try {
      // Mark as RSVP'ing to prevent state conflicts
      setState(() {
        _isRsvping = true;
        _optimisticRsvpState = isAttending;
      });
      
      // Play confetti if attending
      if (isAttending) {
        _confettiController.play();
      }
      
      // Emit event for other listeners
      AppEventBus().emit(
        RsvpStatusChangedEvent(
          eventId: widget.event.id,
          userId: userId,
          isAttending: isAttending,
        ),
      );
      
      // Perform actual backend operation
      final profileNotifier = ref.read(profileProvider.notifier);
      if (isAttending) {
        await profileNotifier.saveEvent(widget.event);
      } else {
        await profileNotifier.removeEvent(widget.event.id);
      }
      
      // Operation succeeded
      setState(() {
        _isRsvping = false;
      });
    } catch (e) {
      debugPrint('Error handling RSVP: $e');
      
      // Handle errors and revert optimistic update
      if (mounted) {
        setState(() {
          _optimisticRsvpState = previousState;
          _isRsvping = false;
        });
        
        // Emit corrective event
        AppEventBus().emit(
          RsvpStatusChangedEvent(
            eventId: widget.event.id,
            userId: userId,
            isAttending: previousState,
          ),
        );
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating RSVP: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final eventDate = DateTime(date.year, date.month, date.day);
    
    if (eventDate == today) {
      return 'Today';
    } else if (eventDate == tomorrow) {
      return 'Tomorrow';
    }
    
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${months[date.month - 1]} ${date.day}';
  }
  
  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final isRecurring = _isRecurringEvent(event);
    final isMultiDay = _isMultiDayEvent(event);
    final isCollaborative = event.organizer != null;
    
    return GestureDetector(
      onTap: _navigateToEventDetails,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Confetti effect
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2, // Bottom to top
              blastDirectionality: BlastDirectionality.explosive,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.2,
              colors: const [
                AppColors.gold,
                Colors.yellow,
                Colors.orange,
                Colors.white,
              ],
            ),
            
            // Main card content
            Material(
              type: MaterialType.transparency,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.dark3.withOpacity(0.7),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event image with status badge
                    Stack(
                      children: [
                        // Image with hero animation
                        widget.heroTag != null
                          ? Hero(
                              tag: widget.heroTag!,
                              child: _buildEventImage(),
                            )
                          : _buildEventImage(),
                        
                        // Date overlay
                        Positioned(
                          top: 16,
                          left: 16,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      _formatDate(event.startDate),
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatTime(event.startDate),
                                      style: GoogleFonts.inter(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        // Lifecycle state badge overlay
                        Positioned(
                          top: 16,
                          right: 16,
                          child: EventLifecycleBadge(
                            event: event,
                            compact: true,
                          ),
                        ),
                        
                        // Top overlay for event status badge
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Row(
                            children: [
                              // Event type badges - NEW COMPONENT
                              if (isRecurring)
                                _buildEventTypeBadge(
                                  'Recurring',
                                  Icons.repeat,
                                  AppColors.info,
                                ),
                              
                              if (isMultiDay && !isRecurring)
                                _buildEventTypeBadge(
                                  'Multi-day',
                                  Icons.date_range,
                                  AppColors.success,
                                ),
                              
                              if (isCollaborative && !isRecurring && !isMultiDay)
                                _buildEventTypeBadge(
                                  'Collaborative',
                                  Icons.people,
                                  AppColors.warning,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    // Content area
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            event.description,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 16),
                          // Bottom row with location and RSVP button
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: AppColors.grey,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  event.location,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.grey,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // RSVP button
                              _isRsvping
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          AppColors.gold,
                                        ),
                                      ),
                                    )
                                  : InkWell(
                                      onTap: () => _handleRsvp(!_optimisticRsvpState),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _optimisticRsvpState
                                              ? AppColors.gold.withOpacity(0.2)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: _optimisticRsvpState
                                                ? AppColors.gold
                                                : Colors.white30,
                                          ),
                                        ),
                                        child: Text(
                                          _optimisticRsvpState ? 'Going' : 'RSVP',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _optimisticRsvpState
                                                ? AppColors.gold
                                                : Colors.white,
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
              ).addGlassmorphism(
                borderRadius: 16,
                blur: 10.0,
                opacity: 0.2,
                enableGradient: true,
                addGoldAccent: _optimisticRsvpState,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper method to check if event is recurring
  bool _isRecurringEvent(Event event) {
    // This is a simplification - in a real implementation,
    // you would check for recurrence rule properties
    return event.tags.contains('recurring') || event.tags.contains('weekly') || 
           event.tags.contains('monthly') || event.tags.contains('daily');
  }
  
  // Helper method to check if event spans multiple days
  bool _isMultiDayEvent(Event event) {
    return !event.startDate.isSameDay(event.endDate) || 
           event.endDate.difference(event.startDate).inHours > 23;
  }

  // New widget for event type badge
  Widget _buildEventTypeBadge(String text, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Event image with fallback
  Widget _buildEventImage() {
    final eventData = widget.event;
    return eventData.imageUrl.isNotEmpty
        ? Image.network(
            eventData.imageUrl,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey.shade800,
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: Colors.white54,
                    size: 48,
                  ),
                ),
              );
            },
          )
        : Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey.shade800,
            child: const Center(
              child: Icon(
                Icons.event_outlined,
                color: Colors.white54,
                size: 48,
              ),
            ),
          );
  }
}

// Extension to make date comparison easier
extension DateOnlyCompare on DateTime {
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
} 