import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../components/event_capacity_display.dart';
import '../../../components/event_waitlist_info.dart';
import '../../../components/attendance_check_in.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/text_styles.dart';
import '../../../models/event.dart';
import '../../../services/attendance_service.dart';
import '../../../services/event_service.dart';

/// A page for demonstrating event capacity, waitlist and attendance features
class EventCapacityPage extends StatefulWidget {
  /// The ID of the event to display
  final String eventId;
  
  /// Create a new event capacity page
  const EventCapacityPage({
    super.key,
    required this.eventId,
  });

  @override
  State<EventCapacityPage> createState() => _EventCapacityPageState();
}

class _EventCapacityPageState extends State<EventCapacityPage> {
  Event? _event;
  bool _isLoading = true;
  bool _isUserOnWaitlist = false;
  bool _hasPromotion = false;
  bool _attendanceCheckedIn = false;
  String? _errorMessage;
  
  /// Attendance report for the event
  AttendanceReport? _attendanceReport;
  
  /// Current user ID
  String? _currentUserId;
  
  @override
  void initState() {
    super.initState();
    _loadEvent();
    _getCurrentUser();
  }
  
  /// Get the current user
  Future<void> _getCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
      });
    }
  }
  
  /// Load the event data
  Future<void> _loadEvent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final event = await EventService.getEventById(widget.eventId);
      
      if (event == null) {
        setState(() {
          _errorMessage = 'Event not found.';
        });
        return;
      }
      
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final isOnWaitlist = userId != null && event.waitlist.contains(userId);
      
      // Get attendance report
      final attendanceReport = await AttendanceService.getAttendanceReport(widget.eventId);
      
      // Check if user has attendance record
      final hasAttendance = userId != null && 
          event.attendance != null && 
          event.attendance!.containsKey(userId);
      
      setState(() {
        _event = event;
        _isUserOnWaitlist = isOnWaitlist;
        _attendanceReport = attendanceReport;
        _attendanceCheckedIn = hasAttendance;
        
        // For demo purposes, randomly decide if user has a promotion
        // In a real app, this would be determined by Firestore data
        if (userId != null) {
          // Only for demo, check if user is on waitlist
          if (isOnWaitlist) {
            // 30% chance of having a promotion for demo
            final hasPromo = DateTime.now().microsecond % 10 < 3;
            _hasPromotion = hasPromo;
          }
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load event: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  /// Handle RSVP to the event
  Future<void> _handleRsvp(bool attending) async {
    if (_event == null || _currentUserId == null) return;
    
    try {
      final result = await AttendanceService.rsvpToEvent(
        _event!.id,
        _currentUserId!,
        attending,
      );
      
      // Provide haptic feedback
      HapticFeedback.mediumImpact();
      
      // Show result
      String message = '';
      
      switch (result) {
        case RsvpResult.successful:
          message = 'Successfully RSVP\'d to the event!';
          break;
        case RsvpResult.waitlisted:
          message = 'The event is at capacity. You have been added to the waitlist.';
          break;
        case RsvpResult.removed:
          message = 'Your RSVP has been cancelled.';
          break;
        case RsvpResult.failed:
          message = 'Failed to update RSVP status.';
          break;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      
      // Refresh event data
      _loadEvent();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
  
  /// Export attendance data as CSV
  Future<void> _exportAttendance() async {
    if (_event == null) return;
    
    try {
      final csvData = await AttendanceService.exportAttendanceAsCsv(_event!.id);
      
      if (csvData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No attendance data available or permission denied.')),
        );
        return;
      }
      
      // In a real app, this would save the CSV file or share it
      // For demo purposes, just show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance data exported successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting attendance: $e')),
      );
    }
  }
  
  /// Handle when a promotion is confirmed
  void _handlePromotionConfirmed() {
    setState(() {
      _hasPromotion = false;
      _isUserOnWaitlist = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You have been added to the event attendees!')),
    );
    
    // Refresh event data
    _loadEvent();
  }
  
  /// Handle when a promotion expires
  void _handlePromotionExpired() {
    setState(() {
      _hasPromotion = false;
    });
    
    // Refresh event data
    _loadEvent();
  }
  
  /// Handle attendance status change
  void _handleAttendanceStatusChanged(bool checkedIn) {
    setState(() {
      _attendanceCheckedIn = checkedIn;
    });
    
    if (checkedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check-in successful!')),
      );
    }
    
    // Refresh attendance report
    _loadEvent();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Event Details',
          style: TextStyles.titleMedium.copyWith(
            color: AppColors.primaryTextColor,
          ),
        ),
        backgroundColor: AppColors.cardColor,
        elevation: 0,
        actions: [
          // Only show export button for event owners/admins
          if (_event != null && 
              _currentUserId != null && 
              _event!.createdBy == _currentUserId)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Export Attendance',
              onPressed: _exportAttendance,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _errorMessage != null
              ? Center(
                  child: Text(
                    _errorMessage!,
                    style: TextStyles.bodyMedium.copyWith(
                      color: AppColors.errorColor,
                    ),
                  ),
                )
              : _event == null
                  ? const Center(
                      child: Text('Event not found'),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Event title and details
                          Text(
                            _event!.title,
                            style: TextStyles.headingMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _event!.description,
                            style: TextStyles.bodyMedium.copyWith(
                              color: AppColors.secondaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Capacity information
                          const Text(
                            'Event Capacity',
                            style: TextStyles.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          EventCapacityDisplay(
                            event: _event!,
                            isUserOnWaitlist: _isUserOnWaitlist,
                          ),
                          const SizedBox(height: 24),
                          
                          // Attendance statistics for event owner
                          if (_attendanceReport != null && 
                              _currentUserId != null && 
                              _event!.createdBy == _currentUserId) ...[
                            const Text(
                              'Attendance Statistics',
                              style: TextStyles.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            _buildAttendanceStats(),
                            const SizedBox(height: 24),
                          ],
                          
                          // Waitlist information (if on waitlist)
                          if (_currentUserId != null && 
                              (_isUserOnWaitlist || _hasPromotion)) ...[
                            EventWaitlistInfo(
                              event: _event!,
                              currentUserId: _currentUserId!,
                              hasPromotion: _hasPromotion,
                              onPromotionConfirmed: _handlePromotionConfirmed,
                              onPromotionExpired: _handlePromotionExpired,
                            ),
                            const SizedBox(height: 24),
                          ],
                          
                          // Attendance check-in (if attending and not checked in)
                          if (_currentUserId != null && 
                              _event!.attendees.contains(_currentUserId) && 
                              !_attendanceCheckedIn) ...[
                            const Text(
                              'Check In',
                              style: TextStyles.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            AttendanceCheckIn(
                              event: _event!,
                              onCheckInStatusChanged: _handleAttendanceStatusChanged,
                            ),
                            const SizedBox(height: 24),
                          ],
                          
                          // RSVP actions
                          if (_currentUserId != null) ...[
                            const Text(
                              'RSVP',
                              style: TextStyles.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            _buildRsvpButtons(),
                          ],
                        ],
                      ),
                    ),
    );
  }
  
  /// Build attendance statistics widget
  Widget _buildAttendanceStats() {
    if (_attendanceReport == null) return const SizedBox.shrink();
    
    final report = _attendanceReport!;
    final attendanceRate = (report.attendanceRate * 100).toStringAsFixed(1);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.dividerColor,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatItem(
                'RSVPs',
                report.totalRsvps.toString(),
                Icons.people,
              ),
              _buildStatDivider(),
              _buildStatItem(
                'Checked In',
                report.totalCheckedIn.toString(),
                Icons.how_to_reg,
              ),
              _buildStatDivider(),
              _buildStatItem(
                'Waitlist',
                report.totalWaitlisted.toString(),
                Icons.watch_later,
              ),
            ],
          ),
          const Divider(
            color: AppColors.dividerColor,
            height: 32,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.insights,
                color: AppColors.secondaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Attendance Rate: $attendanceRate%',
                style: TextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Build a statistic item
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.primaryColor,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyles.headingSmall,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
  
  /// Build divider for stats
  Widget _buildStatDivider() {
    return Container(
      height: 40,
      width: 1,
      color: AppColors.dividerColor,
    );
  }
  
  /// Build RSVP action buttons
  Widget _buildRsvpButtons() {
    final isAttending = _currentUserId != null && 
        _event != null && 
        _event!.attendees.contains(_currentUserId);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAttending 
                ? 'You are attending this event'
                : _isUserOnWaitlist
                    ? 'You are on the waitlist'
                    : 'Will you attend this event?',
            style: TextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: isAttending ? null : () => _handleRsvp(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: AppColors.backgroundColor,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Attend'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: !isAttending && !_isUserOnWaitlist 
                      ? null 
                      : () => _handleRsvp(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.errorColor,
                    side: const BorderSide(
                      color: AppColors.errorColor,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 