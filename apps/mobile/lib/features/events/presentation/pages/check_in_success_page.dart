import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

/// A page that shows a success message after checking in to an event
class CheckInSuccessPage extends StatefulWidget {
  /// The event that was checked in to
  final Event event;

  /// The time the user checked in
  final DateTime checkInTime;

  /// Creates a check-in success page
  const CheckInSuccessPage({
    Key? key,
    required this.event,
    required this.checkInTime,
  }) : super(key: key);

  @override
  State<CheckInSuccessPage> createState() => _CheckInSuccessPageState();
}

class _CheckInSuccessPageState extends State<CheckInSuccessPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _animationController.forward();
    
    // Provide haptic feedback for successful check-in
    HapticFeedback.mediumImpact();
    
    // Auto-navigate back to event details after delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.pop();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success animation
                Lottie.asset(
                  'assets/animations/check_success.json', // Make sure to add this animation asset
                  controller: _animationController,
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                  onLoaded: (composition) {
                    _animationController.duration = composition.duration;
                    _animationController.forward();
                  },
                ),
                const SizedBox(height: 32),
                
                // Success message
                Text(
                  'Check-in Successful!',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Event info
                Text(
                  widget.event.title,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                // Check-in time
                Text(
                  'Checked in at ${_formatTime(widget.checkInTime)}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Back button
                TextButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Return to Event'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.white,
                    textStyle: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Format time like "3:45 PM"
  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
} 