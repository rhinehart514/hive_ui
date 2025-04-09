import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/text_styles.dart';
import '../services/attendance_service.dart';
import '../models/event.dart';

/// A component for checking in to an event with location verification
class AttendanceCheckIn extends StatefulWidget {
  /// The event to check in to
  final Event event;
  
  /// Callback when check-in status changes
  final Function(bool)? onCheckInStatusChanged;
  
  /// Create a new attendance check-in component
  const AttendanceCheckIn({
    super.key,
    required this.event,
    this.onCheckInStatusChanged,
  });

  @override
  State<AttendanceCheckIn> createState() => _AttendanceCheckInState();
}

class _AttendanceCheckInState extends State<AttendanceCheckIn> {
  bool _isLoading = false;
  bool _isCheckedIn = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _checkIfAlreadyCheckedIn();
  }
  
  /// Check if the user is already checked in
  Future<void> _checkIfAlreadyCheckedIn() async {
    const userId = 'current-user-id'; // Replace with actual user ID
    final hasAttendance = widget.event.attendance?.containsKey(userId) ?? false;
    
    setState(() {
      _isCheckedIn = hasAttendance;
    });
  }
  
  /// Check in to the event
  Future<void> _checkIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      const userId = 'current-user-id'; // Replace with actual user ID
      
      // Verify location and check in
      final successful = await AttendanceService.checkInUserWithLocation(
        widget.event.id,
        userId,
      );
      
      if (successful) {
        setState(() {
          _isCheckedIn = true;
        });
        
        // Provide haptic feedback for successful check-in
        HapticFeedback.mediumImpact();
        
        // Notify parent
        widget.onCheckInStatusChanged?.call(true);
      } else {
        setState(() {
          _errorMessage = 'Unable to verify your location. Please ensure you are at the event venue.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred during check-in. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          // Header
          const Text(
            'Attendance Check-in',
            style: TextStyles.titleMedium,
          ),
          const SizedBox(height: 8),
          
          // Description
          Text(
            'Check in to confirm your attendance. This requires location verification.',
            style: TextStyles.bodyMedium.copyWith(
              color: AppColors.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 16),
          
          // Error message
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.errorColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyles.bodySmall.copyWith(
                        color: AppColors.errorColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Check-in button or success message
          if (_isCheckedIn)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: AppColors.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.successColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.successColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'You\'re Checked In!',
                          style: TextStyles.titleSmall.copyWith(
                            color: AppColors.successColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Your attendance has been recorded.',
                          style: TextStyles.bodySmall.copyWith(
                            color: AppColors.successColor.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _checkIn,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.location_on),
                label: Text(_isLoading ? 'Verifying Location...' : 'Check In Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.backgroundColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ),
        ],
      ),
    );
  }
} 