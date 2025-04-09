import 'dart:ui';
import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/providers/profile_provider.dart';
import 'package:hive_ui/components/shared/event_header.dart';
import 'package:hive_ui/components/shared/event_content.dart';
import 'package:hive_ui/components/event_details/event_action_bar.dart';
import 'package:hive_ui/services/interactions/interaction_service.dart';
import 'package:hive_ui/models/interactions/interaction.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart';
import 'package:hive_ui/features/events/domain/providers/event_stream_provider.dart';
import 'package:hive_ui/core/event_bus/app_event_bus.dart';
import 'package:confetti/confetti.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_ui/models/repost_content_type.dart';
import 'package:hive_ui/features/events/presentation/widgets/event_lifecycle_badge.dart';
import 'package:hive_ui/features/events/presentation/widgets/event_lifecycle_manager.dart';
import 'package:hive_ui/features/events/presentation/widgets/calendar_export_button.dart';
import 'package:hive_ui/features/events/presentation/widgets/event_priority_indicator.dart';
import 'package:hive_ui/features/events/presentation/widgets/attendance_tracker.dart';
import 'package:hive_ui/models/attendance_record.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Real-time event details page that uses Firestore streaming for live updates
class EventDetailPageRealtime extends ConsumerStatefulWidget {
  /// Event ID to display
  final String eventId;
  
  /// Optional hero tag for animations
  final String? heroTag;
  
  /// Initial event data (optional - will be replaced by streamed data)
  final Event? initialEventData;

  const EventDetailPageRealtime({
    Key? key,
    required this.eventId,
    this.heroTag,
    this.initialEventData,
  }) : super(key: key);

  @override
  ConsumerState<EventDetailPageRealtime> createState() => _EventDetailPageRealtimeState();
}

class _EventDetailPageRealtimeState extends ConsumerState<EventDetailPageRealtime>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;
  late ConfettiController _confettiController;
  double _scrollOffset = 0.0;
  bool _hasLoggedView = false;
  
  // Optimistic UI update for RSVP
  bool _isRsvping = false;
  bool _optimisticRsvpState = false;
  
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    // Start the entrance animation
    _animationController.forward();
    
    // Initialize optimistic RSVP state based on profile data
    if (widget.initialEventData != null) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      _optimisticRsvpState = userId != null && 
          widget.initialEventData!.attendees.contains(userId);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _animationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset.clamp(0, 150);
    });
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
          eventId: widget.eventId,
          userId: userId,
          isAttending: isAttending,
        ),
      );
      
      // Perform actual backend operation
      final profileNotifier = ref.read(profileProvider.notifier);
      if (isAttending) {
        await profileNotifier.saveEvent(
          // Use current event data from stream if available
          ref.read(singleEventStreamProvider(widget.eventId)).value ?? 
              widget.initialEventData!
        );
      } else {
        await profileNotifier.removeEvent(widget.eventId);
      }
      
      // Log interaction
      _logRsvpInteraction();
      
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
            eventId: widget.eventId,
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
  
  void _handleAddToCalendar(Event event) async {
    try {
      // For this example, we'll just show a success message
      // In the real implementation, this would call EventService.addToCalendar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event added to calendar'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Calendar error: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
  
  void _handleRepost(Event event) {
    // Implement repost functionality
    HapticFeedback.mediumImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Event reposted to your profile'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    // Emit content reposted event
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      AppEventBus().emit(
        ContentRepostedEvent(
          contentId: event.id,
          contentType: 'event',
          userId: userId,
        ),
      );
    }
  }

  void _logViewInteraction() {
    try {
      final user = ref.read(currentUserProvider);
      if (user.isNotEmpty == false) return;

      InteractionService.logInteraction(
        userId: user.id,
        entityId: widget.eventId,
        entityType: EntityType.event,
        action: InteractionAction.view,
        metadata: {
          'view_type': 'details_realtime',
        },
      );
    } catch (e) {
      debugPrint('Error logging view interaction: $e');
    }
  }

  void _logRsvpInteraction() {
    try {
      final user = ref.read(currentUserProvider);
      if (user.isNotEmpty == false) return;

      InteractionService.logInteraction(
        userId: user.id,
        entityId: widget.eventId,
        entityType: EntityType.event,
        action: InteractionAction.rsvp,
      );
    } catch (e) {
      debugPrint('Error logging RSVP interaction: $e');
    }
  }

  // New method to handle attendance updates
  void _handleAttendanceUpdate(Map<String, AttendanceRecord> updatedAttendance) {
    // In a real app, this would update Firestore
    // For now, just show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Attendance updated'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use AsyncValue to handle loading, error, and data states
    final asyncEvent = ref.watch(singleEventStreamProvider(widget.eventId));
    
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: asyncEvent.when(
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(error),
        data: (event) {
          // Use the streamed event data or fall back to initial data
          final eventData = event ?? widget.initialEventData;
          if (eventData == null) {
            return _buildErrorState('Event not found');
          }
          
          // Check if the user is attending
          final userId = FirebaseAuth.instance.currentUser?.uid;
          final isAttending = userId != null && 
              (eventData.attendees.contains(userId) || _optimisticRsvpState);
          
          // Is user the creator or have admin rights?
          final isCreator = userId != null && eventData.createdBy == userId;
          
          return NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 240,
                  floating: false,
                  pinned: true,
                  automaticallyImplyLeading: false,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  flexibleSpace: _buildEventHeader(eventData),
                  leading: BackButton(
                    color: Colors.white.withOpacity(
                      0.5 + (_scrollOffset / 150) * 0.5,
                    ),
                  ),
                  actions: [
                    // Only show if user is attending
                    if (isAttending)
                      IconButton(
                        icon: const Icon(Icons.calendar_today_outlined),
                        color: Colors.white.withOpacity(
                          0.5 + (_scrollOffset / 150) * 0.5,
                        ),
                        onPressed: () => _handleAddToCalendar(eventData),
                        tooltip: 'Add to Calendar',
                      ),
                    IconButton(
                      icon: const Icon(Icons.share_outlined),
                      color: Colors.white.withOpacity(
                        0.5 + (_scrollOffset / 150) * 0.5,
                      ),
                      onPressed: () {
                        // Implement share functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Sharing event...'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      tooltip: 'Share Event',
                    ),
                  ],
                ),
              ];
            },
            body: _buildEventBody(eventData, isAttending, isCreator),
          );
        },
      ),
      // Position confetti controller at the top center
      floatingActionButtonLocation: FloatingActionButtonLocation.centerTop,
      floatingActionButton: ConfettiWidget(
        confettiController: _confettiController,
        blastDirection: pi / 2, // straight up
        emissionFrequency: 0.05,
        numberOfParticles: 20,
        maxBlastForce: 20,
        minBlastForce: 5,
        gravity: 0.1,
        colors: const [
          AppColors.gold,
          AppColors.goldLight,
          Colors.white,
        ],
      ),
    );
  }
  
  // Build loading state
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
              strokeWidth: 2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading event details...',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
  
  // Build error state
  Widget _buildErrorState(dynamic error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 60,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load event',
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Refresh the event
              ref.refresh(singleEventStreamProvider(widget.eventId));
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
  
  // Build event header with hero animation and blur
  Widget _buildEventHeader(Event event) {
    return FlexibleSpaceBar(
      background: Stack(
        fit: StackFit.expand,
        children: [
          // Hero image
          widget.heroTag != null
              ? Hero(
                  tag: widget.heroTag!,
                  child: Image.network(
                    event.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.dark2,
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColors.grey,
                          size: 80,
                        ),
                      ),
                    ),
                  ),
                )
              : Image.network(
                  event.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppColors.dark2,
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: AppColors.grey,
                        size: 80,
                      ),
                    ),
                  ),
                ),
          
          // Gradient overlay for better text contrast
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                  Colors.black.withOpacity(0.8),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          
          // Main event info
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status badges
                Row(
                  children: [
                    // Event lifecycle state badge
                    EventLifecycleBadge(event: event),
                    
                    const SizedBox(width: 8),
                    
                    // Event priority/urgency indicator
                    if (event.currentState == EventLifecycleState.published)
                      EventPriorityIndicator(
                        event: event,
                        showLabel: true, 
                        size: 18,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Event title
                Text(
                  event.title,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                
                // Organizer
                Row(
                  children: [
                    const Icon(Icons.people_outline, 
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      event.organizerName,
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Build the main event details body
  Widget _buildEventBody(Event event, bool isAttending, bool isCreator) {
    return Container(
      color: AppColors.dark,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 24),
          
          // Date and Location
          _buildDateLocationSection(event),
          const SizedBox(height: 24),
          
          // Action buttons row
          _buildActionButtons(event, isAttending, isCreator),
          const SizedBox(height: 24),
          
          // Description section
          _buildDescriptionSection(event),
          const SizedBox(height: 32),
          
          // Attendance section (for event creator)
          if (isCreator || event.currentState == EventLifecycleState.live || 
              event.currentState == EventLifecycleState.completed)
            AttendanceTracker(
              event: event,
              canManageAttendance: isCreator,
              onAttendanceUpdated: _handleAttendanceUpdate,
            ),
          const SizedBox(height: 24),
          
          // Event lifecycle manager (admin only)
          if (isCreator)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: EventLifecycleManager(
                event: event,
                onStateChanged: (newState) {
                  // In a real app, this would refresh the stream
                  // which would automatically update the UI
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Event state updated'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
  
  // Build date and location section
  Widget _buildDateLocationSection(Event event) {
    final DateFormat dateFormat = DateFormat('E, MMM d, yyyy');
    final DateFormat timeFormat = DateFormat('h:mm a');
    
    final startDateStr = dateFormat.format(event.startDate);
    final startTimeStr = timeFormat.format(event.startDate);
    
    final endDateStr = dateFormat.format(event.endDate);
    final endTimeStr = timeFormat.format(event.endDate);
    
    final isSameDay = event.startDate.year == event.endDate.year && 
                     event.startDate.month == event.endDate.month && 
                     event.startDate.day == event.endDate.day;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date and time
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.dark2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.gold,
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      event.startDate.day.toString(),
                      style: GoogleFonts.inter(
                        color: AppColors.gold,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat('MMM').format(event.startDate),
                      style: GoogleFonts.inter(
                        color: AppColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSameDay 
                          ? startDateStr 
                          : 'From $startDateStr to $endDateStr',
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isSameDay 
                          ? '$startTimeStr - $endTimeStr' 
                          : 'Starts: $startTimeStr, Ends: $endTimeStr',
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              CalendarExportButton(
                event: event,
                onExportComplete: (success) {
                  // Handle export completion
                },
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Location
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.dark2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Location',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.dark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      event.location.contains('zoom.') || 
                              event.location.contains('meet.') || 
                              event.location.contains('http')
                          ? Icons.videocam_outlined
                          : Icons.location_on_outlined,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.location,
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                          ),
                        ),
                        if (event.location.contains('zoom.') || 
                            event.location.contains('meet.') || 
                            event.location.contains('http'))
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Virtual Event',
                              style: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (event.location.contains('zoom.') || 
                          event.location.contains('meet.') || 
                          event.location.contains('http')) {
                        // Launch URL
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Opening meeting link...'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } else {
                        // Open map
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Opening location in maps...'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    icon: Icon(
                      event.location.contains('zoom.') || 
                              event.location.contains('meet.') || 
                              event.location.contains('http')
                          ? Icons.videocam_outlined
                          : Icons.directions_outlined,
                      size: 16,
                    ),
                    label: Text(
                      event.location.contains('zoom.') || 
                              event.location.contains('meet.') || 
                              event.location.contains('http')
                          ? 'Join'
                          : 'Directions',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      minimumSize: const Size(100, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // Build action buttons row
  Widget _buildActionButtons(Event event, bool isAttending, bool isCreator) {
    return Row(
      children: [
        // RSVP button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isRsvping 
                ? null 
                : () => _handleRsvp(!isAttending),
            icon: _isRsvping
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isAttending ? AppColors.textDark : AppColors.gold,
                      ),
                    ),
                  )
                : Icon(
                    isAttending
                        ? Icons.check_circle_outline
                        : Icons.calendar_today_outlined,
                    size: 18,
                  ),
            label: Text(
              _isRsvping
                  ? 'Updating...'
                  : isAttending
                      ? 'I\'m Going'
                      : 'RSVP',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isAttending ? AppColors.gold : Colors.transparent,
              foregroundColor: isAttending ? AppColors.textDark : AppColors.gold,
              side: isAttending 
                  ? null 
                  : BorderSide(color: AppColors.gold),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Share button
        IconButton(
          onPressed: () {
            // Implement share functionality
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sharing event...'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          icon: const Icon(Icons.share_outlined),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.dark2,
            foregroundColor: AppColors.textSecondary,
            padding: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 0.5,
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Add to Calendar button
        isAttending
            ? IconButton(
                onPressed: () => _handleAddToCalendar(event),
                icon: const Icon(Icons.calendar_today_outlined),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.dark2,
                  foregroundColor: AppColors.textSecondary,
                  padding: const EdgeInsets.all(12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                      width: 0.5,
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ],
    );
  }
  
  // Build description section
  Widget _buildDescriptionSection(Event event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.dark2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 0.5,
            ),
          ),
          child: Text(
            event.description,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
} 