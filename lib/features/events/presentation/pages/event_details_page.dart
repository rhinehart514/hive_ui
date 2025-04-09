import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../components/event_action_menu.dart';
import '../widgets/glass_container.dart';
import '../widgets/event_action_bar_adapter.dart';
import '../../../../extensions/repost_extension.dart';
import '../../../../models/event.dart';
import '../../../../models/event_status.dart';
import '../../../../models/repost_content_type.dart';
import '../../../../services/event_edit_service.dart';
import '../../../../theme/app_colors.dart';

/// Event details page
class EventDetailsPage extends ConsumerStatefulWidget {
  /// The event ID to display
  final String? eventId;
  
  /// The event to display
  final Event? event;
  
  /// If true, this event was opened from a push notification
  final bool fromPush;
  
  /// If true, show a preview version of the details
  final bool isPreview;

  /// Constructor
  const EventDetailsPage({
    Key? key,
    this.eventId,
    this.event,
    this.fromPush = false,
    this.isPreview = false,
  }) : super(key: key);

  @override
  ConsumerState<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends ConsumerState<EventDetailsPage> {
  Event? _event;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _isRsvpd = false;
  bool _isRsvpLoading = false;
  bool _isEventOwner = false;
  
  @override
  void initState() {
    super.initState();
    _loadEvent();
  }
  
  Future<void> _loadEvent() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });
    
    try {
      // If the event is provided directly, use it
      if (widget.event != null) {
        _event = widget.event;
        _checkIsOwner();
        _checkRsvpStatus();
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // Otherwise load by ID
      if (widget.eventId == null) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'No event ID provided';
        });
        return;
      }
      
      // Fetch the event from Firestore
      final eventDoc = await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .get();
      
      if (!eventDoc.exists) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Event not found';
        });
        return;
      }
      
      // Parse the event data
      final eventData = eventDoc.data() as Map<String, dynamic>;
      _event = Event.fromJson({...eventData, 'id': widget.eventId});
      
      _checkIsOwner();
      _checkRsvpStatus();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Error loading event: $e';
      });
    }
  }
  
  void _checkIsOwner() {
    if (_event == null) return;
    
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _isEventOwner = false;
      return;
    }
    
    _isEventOwner = _event!.createdBy == currentUser.uid;
  }
  
  void _checkRsvpStatus() {
    if (_event == null) return;
    
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _isRsvpd = false;
      return;
    }
    
    _isRsvpd = _event!.attendees.contains(currentUser.uid);
  }
  
  Future<void> _handleRsvp(bool isAttending) async {
    if (_event == null) return;
    
    // Check if user is logged in
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to RSVP')),
      );
      return;
    }
    
    setState(() {
      _isRsvpLoading = true;
    });
    
    try {
      // Update Firestore
      final eventRef = FirebaseFirestore.instance
          .collection('events')
          .doc(_event!.id);
      
      if (isAttending) {
        await eventRef.update({
          'attendees': FieldValue.arrayUnion([currentUser.uid]),
        });
      } else {
        await eventRef.update({
          'attendees': FieldValue.arrayRemove([currentUser.uid]),
        });
      }
      
      // Update local state
      setState(() {
        _isRsvpd = isAttending;
        _isRsvpLoading = false;
        
        // Update the event object
        final updatedAttendees = List<String>.from(_event!.attendees);
        if (isAttending) {
          updatedAttendees.add(currentUser.uid);
        } else {
          updatedAttendees.remove(currentUser.uid);
        }
        
        _event = _event!.copyWith(
          attendees: updatedAttendees,
          isAttending: isAttending,
        );
      });
      
      // Add haptic feedback
      HapticFeedback.mediumImpact();
      
    } catch (e) {
      setState(() {
        _isRsvpLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update RSVP: $e')),
      );
    }
  }
  
  void _handleEditEvent() {
    if (_event == null) return;
    
    // Navigate to edit page (implementation depends on your routing)
    context.push('/events/edit/${_event!.id}');
  }
  
  Future<void> _handleCancelEvent() async {
    if (_event == null) return;
    
    // Show confirmation dialog
    final shouldCancel = await EventEditService.showCancelConfirmation(context);
    if (!shouldCancel) return;
    
    // Proceed with cancellation
    try {
      await EventEditService.cancelEvent(_event!);
      
      // Update the local event object
      setState(() {
        _event = _event!.copyWith(
          status: EventStatus.cancelled.value,
        );
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event cancelled successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel event: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  
  void _handleRepostTap() {
    if (_event == null) return;
    
    // Add haptic feedback
    HapticFeedback.mediumImpact();
    
    // Show repost options
    context.showRepostOptions(
      event: _event!,
      onRepostSelected: _handleRepostSelected,
    );
  }
  
  Future<void> _handleRepostSelected(Event event, String? commentText, RepostContentType type) async {
    try {
      // Implementation of repost logic
      // For now just show a success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event reposted successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error reposting event: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to repost: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  
  void _handleShowOptions() {
    if (_event == null) return;
    
    // Add haptic feedback
    HapticFeedback.mediumImpact();
    
    // Show options menu
    EventActionMenu.show(
      context: context,
      event: _event!,
      isEventOwner: _isEventOwner,
      isCanceled: _event!.status == EventStatus.cancelled.value,
      onEditTap: _isEventOwner ? _handleEditEvent : null,
      onCancelTap: _isEventOwner ? _handleCancelEvent : null,
      onShareTap: _handleRepostTap,
      onReportTap: () {
        // Implement report functionality
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report functionality not implemented yet')),
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.dark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
          ),
        ),
      );
    }
    
    if (_hasError) {
      return Scaffold(
        backgroundColor: AppColors.dark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'An error occurred',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadEvent,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_event == null) {
      return Scaffold(
        backgroundColor: AppColors.dark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: Text(
            'Event not found',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
      );
    }
    
    final isCancelled = _event!.status == EventStatus.cancelled.value;
    
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _hasValidImage()
                  ? Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(_getSafeImageUrl()),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                    )
                  : Container(
                      color: AppColors.dark2,
                      child: Center(
                        child: Icon(
                          Icons.event,
                          size: 48,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: _handleShowOptions,
                tooltip: 'More options',
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title with cancelled indicator if needed
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _event!.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isCancelled)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'CANCELLED',
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Organizer
                  Row(
                    children: [
                      const Icon(
                        Icons.people,
                        color: AppColors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _event!.organizerName,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Date and time
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: AppColors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDateRange(_event!.startDate, _event!.endDate),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Location
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: AppColors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _event!.location,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Action bar
                  EventActionBarAdapter(
                    event: _event!,
                    isRsvpd: _isRsvpd,
                    isLoading: _isRsvpLoading,
                    followsClub: false,
                    isEventOwner: _isEventOwner,
                    onRsvp: isCancelled ? null : _handleRsvp,
                    onAddToCalendar: () {
                      // Add calendar functionality here
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Calendar feature not implemented yet')),
                      );
                    },
                    onRepost: _handleRepostTap,
                    onEditTap: _isEventOwner ? _handleEditEvent : null,
                    onCancelTap: _isEventOwner ? _handleCancelEvent : null,
                  ),
                  const SizedBox(height: 24),
                  
                  // Description
                  const Text(
                    'About',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GlassmorphicContainer(
                    borderRadius: 16,
                    blur: 10,
                    opacity: 0.2,
                    border: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        _event!.description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Category and tags
                  if (_event!.tags.isNotEmpty) ...[
                    const Text(
                      'Tags',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text(_event!.category),
                          backgroundColor: AppColors.gold.withOpacity(0.2),
                          labelStyle: const TextStyle(color: AppColors.gold),
                        ),
                        ..._event!.tags.map((tag) => Chip(
                          label: Text(tag),
                          backgroundColor: AppColors.dark3,
                          labelStyle: const TextStyle(color: Colors.white),
                        )),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDateRange(DateTime start, DateTime end) {
    // Format date range based on whether it's the same day
    final startDate = start.toString().split(' ')[0];
    final endDate = end.toString().split(' ')[0];
    
    final startTime = _formatTime(start);
    final endTime = _formatTime(end);
    
    if (startDate == endDate) {
      // Same day
      return '${_formatDate(start)} · $startTime - $endTime';
    } else {
      // Different days
      return '${_formatDate(start)} $startTime - ${_formatDate(end)} $endTime';
    }
  }
  
  String _formatDate(DateTime date) {
    // Format as "Mon, Jan 1"
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    final dayOfWeek = days[date.weekday - 1];
    final month = months[date.month - 1];
    final day = date.day;
    
    return '$dayOfWeek, $month $day';
  }
  
  String _formatTime(DateTime date) {
    // Format as "1:30 PM"
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour < 12 ? 'AM' : 'PM';
    
    return '$hour:$minute $period';
  }

  // Helper method to check if event has a valid image
  bool _hasValidImage() {
    return _event != null && _event!.imageUrl.isNotEmpty;
  }

  // Helper method to get a safe image URL
  String _getSafeImageUrl() {
    if (_event == null || _event!.imageUrl.isEmpty) {
      return '';
    }
    return _event!.imageUrl;
  }
} 