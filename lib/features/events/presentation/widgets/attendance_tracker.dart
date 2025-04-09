import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/models/event.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/models/attendance_record.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/events/domain/providers/event_repository_provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;

/// A widget that displays and manages event attendance
class AttendanceTracker extends ConsumerStatefulWidget {
  /// The event to track attendance for
  final Event event;
  
  /// Whether the user has permission to manage attendance
  final bool canManageAttendance;
  
  /// Callback when attendance is updated
  final Function(Map<String, AttendanceRecord>)? onAttendanceUpdated;

  /// Creates an attendance tracker
  const AttendanceTracker({
    Key? key,
    required this.event,
    this.canManageAttendance = false,
    this.onAttendanceUpdated,
  }) : super(key: key);

  @override
  ConsumerState<AttendanceTracker> createState() => _AttendanceTrackerState();
}

class _AttendanceTrackerState extends ConsumerState<AttendanceTracker> {
  bool _isUpdatingAttendance = false;
  bool _isGeneratingCode = false;
  String? _checkInCode;
  final TextEditingController _codeController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  /// Get attendance percentage as a ratio
  double get _attendanceRatio {
    final attendees = widget.event.attendees.length;
    final attended = widget.event.attendance?.length ?? 0;
    
    return attendees > 0 ? (attended / attendees).clamp(0.0, 1.0) : 0.0;
  }

  /// Generate a random check-in code
  Future<void> _generateCheckInCode() async {
    if (_isGeneratingCode) return;
    
    setState(() {
      _isGeneratingCode = true;
    });
    
    try {
      HapticFeedback.mediumImpact();
      
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }
      
      // Use the repository to generate a code
      final eventRepository = ref.read(eventRepositoryProvider);
      final code = await eventRepository.generateCheckInCode(widget.event.id, userId);
      
      setState(() {
        _checkInCode = code;
        _isGeneratingCode = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating code: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
        
        setState(() {
          _isGeneratingCode = false;
        });
      }
    }
  }

  /// Handle user check-in
  Future<void> _checkIn() async {
    if (_isUpdatingAttendance) return;
    
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isUpdatingAttendance = true;
    });
    
    try {
      HapticFeedback.mediumImpact();
      
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }
      
      final enteredCode = _codeController.text.trim();
      
      // Use the repository to validate the check-in code
      final eventRepository = ref.read(eventRepositoryProvider);
      final isCodeValid = await eventRepository.validateCheckInCode(widget.event.id, enteredCode);
      
      if (isCodeValid) {
        // Create an attendance record
        final attendanceRecord = AttendanceRecord(
          userId: userId,
          checkedInAt: DateTime.now(),
          verificationMethod: VerificationMethod.manual,
          notes: 'Checked in via code',
        );
        
        // Record the attendance
        final success = await eventRepository.recordAttendance(widget.event.id, attendanceRecord);
        
        if (success) {
          // Create a copy of the current attendance map or a new one if null
          final updatedAttendance = {...widget.event.attendance ?? {}};
          
          // Add the attendance record to the local state
          updatedAttendance[userId] = attendanceRecord;
          
          // Notify the parent
          widget.onAttendanceUpdated?.call(updatedAttendance);
          
          // Clear the input
          _codeController.clear();
          
          if (mounted) {
            // Navigate to success page
            context.pushNamed(
              'event_check_in_success',
              pathParameters: {'eventId': widget.event.id},
              extra: {
                'event': widget.event,
                'checkInTime': attendanceRecord.checkedInAt,
              },
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to record attendance. Please try again.'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid check-in code. Please try again.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking in: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingAttendance = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final hasCheckedIn = userId != null && widget.event.attendance != null && 
                        widget.event.attendance!.containsKey(userId);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title section
        Text(
          'Attendance',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        
        // Stats card
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
              // Attendance progress bar
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Progress label
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Check-in Progress',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '${(widget.event.attendance?.length ?? 0)}/${widget.event.attendees.length}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.gold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _attendanceRatio,
                            backgroundColor: AppColors.dark,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                            minHeight: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Admin - Generate check-in code
              if (widget.canManageAttendance) ...[
                _checkInCode != null
                    ? _buildActiveCodeWidget()
                    : _buildGenerateCodeButton(),
                const SizedBox(height: 16),
              ],
              
              // Attendee - Check-in form
              if (!widget.canManageAttendance && !hasCheckedIn) ...[
                _buildCheckInForm(),
              ],
              
              // Attendee - Already checked in
              if (!widget.canManageAttendance && hasCheckedIn) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.success.withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'You\'ve checked in!',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Checked in at ${_formatTime(widget.event.attendance![userId!]!.checkedInAt)}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
  
  // Format time like "3:45 PM"
  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
  
  // Widget for showing the active check-in code
  Widget _buildActiveCodeWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dark3,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.gold.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Active Check-in Code',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.gold,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _checkInCode!,
                  style: GoogleFonts.robotoMono(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold,
                    letterSpacing: 2,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, color: AppColors.gold),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _checkInCode!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Code copied to clipboard'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _generateCheckInCode,
            icon: const Icon(Icons.refresh),
            label: const Text('Generate New Code'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
  
  // Widget for generating a new check-in code
  Widget _buildGenerateCodeButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isGeneratingCode ? null : _generateCheckInCode,
        icon: _isGeneratingCode
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.black),
                ),
              )
            : const Icon(Icons.qr_code),
        label: Text(_isGeneratingCode ? 'Generating...' : 'Generate Check-in Code'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.black,
          padding: const EdgeInsets.symmetric(vertical: 12),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
  
  // Widget for attendee check-in
  Widget _buildCheckInForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter check-in code:',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    hintText: '000000',
                    hintStyle: GoogleFonts.inter(
                      color: AppColors.textSecondary.withOpacity(0.5),
                    ),
                    filled: true,
                    fillColor: AppColors.dark,
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppColors.grey.withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppColors.grey.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppColors.gold,
                        width: 1.5,
                      ),
                    ),
                  ),
                  style: GoogleFonts.robotoMono(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the check-in code';
                    }
                    if (value.length != 4 && value.length != 6) {
                      return 'Please enter a valid code';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isUpdatingAttendance ? null : _checkIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  minimumSize: const Size(120, 52),
                ),
                child: _isUpdatingAttendance
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.black),
                        ),
                      )
                    : const Text('Check In'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Code provided by event organizer',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
} 