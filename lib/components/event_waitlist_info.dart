import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/text_styles.dart';
import '../services/attendance_service.dart';
import '../models/event.dart';

/// Component to display waitlist information and handle promotions
class EventWaitlistInfo extends StatefulWidget {
  /// The event to display waitlist information for
  final Event event;
  
  /// User ID of the current user
  final String currentUserId;
  
  /// Whether a promotion is available for the current user
  final bool hasPromotion;
  
  /// Callback when the user confirms a promotion
  final Function()? onPromotionConfirmed;
  
  /// Callback when the promotion expires
  final Function()? onPromotionExpired;
  
  /// Create a new waitlist info component
  const EventWaitlistInfo({
    super.key,
    required this.event,
    required this.currentUserId,
    this.hasPromotion = false,
    this.onPromotionConfirmed,
    this.onPromotionExpired,
  });

  @override
  State<EventWaitlistInfo> createState() => _EventWaitlistInfoState();
}

class _EventWaitlistInfoState extends State<EventWaitlistInfo> {
  bool _isConfirming = false;
  bool _isExpired = false;
  String? _errorMessage;
  
  /// Timer for promotion countdown
  Duration _remainingTime = const Duration(minutes: 5);
  late final PromotionTimer _timer;
  
  @override
  void initState() {
    super.initState();
    
    if (widget.hasPromotion) {
      _startPromotionTimer();
    }
  }
  
  @override
  void dispose() {
    if (widget.hasPromotion) {
      _timer.cancel();
    }
    super.dispose();
  }
  
  /// Start the countdown timer for the promotion
  void _startPromotionTimer() {
    _timer = PromotionTimer(
      onTick: (remaining) {
        setState(() {
          _remainingTime = remaining;
        });
      },
      onComplete: () {
        setState(() {
          _isExpired = true;
        });
        
        // Notify parent
        widget.onPromotionExpired?.call();
      },
      duration: const Duration(minutes: 5),
    );
    
    _timer.start();
  }
  
  /// Format the remaining time as MM:SS
  String _formatRemainingTime() {
    final minutes = _remainingTime.inMinutes;
    final seconds = _remainingTime.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
  
  /// Confirm the promotion
  Future<void> _confirmPromotion() async {
    setState(() {
      _isConfirming = true;
      _errorMessage = null;
    });
    
    try {
      final successful = await AttendanceService.confirmWaitlistPromotion(
        widget.event.id,
        widget.currentUserId,
      );
      
      if (successful) {
        // Provide haptic feedback
        HapticFeedback.mediumImpact();
        
        // Notify parent
        widget.onPromotionConfirmed?.call();
      } else {
        setState(() {
          _errorMessage = 'Unable to confirm your spot. The promotion may have expired.';
          _isExpired = true;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred while confirming. Please try again.';
      });
    } finally {
      setState(() {
        _isConfirming = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isOnWaitlist = widget.event.waitlist.contains(widget.currentUserId);
    final waitlistPosition = isOnWaitlist 
        ? widget.event.waitlist.indexOf(widget.currentUserId) + 1 
        : null;
    
    if (!isOnWaitlist && !widget.hasPromotion) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.hasPromotion 
            ? AppColors.warningColor.withOpacity(0.1)
            : AppColors.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.hasPromotion 
              ? AppColors.warningColor.withOpacity(0.3)
              : AppColors.dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                widget.hasPromotion 
                    ? Icons.notification_important
                    : Icons.people_outline,
                color: widget.hasPromotion 
                    ? AppColors.warningColor
                    : AppColors.primaryTextColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                widget.hasPromotion
                    ? 'Spot Available!'
                    : 'Waitlist Status',
                style: TextStyles.titleMedium.copyWith(
                  color: widget.hasPromotion 
                      ? AppColors.warningColor
                      : AppColors.primaryTextColor,
                ),
              ),
              if (widget.hasPromotion) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _isExpired
                        ? AppColors.errorColor
                        : AppColors.warningColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _isExpired
                        ? 'Expired'
                        : _formatRemainingTime(),
                    style: TextStyles.bodySmall.copyWith(
                      color: AppColors.backgroundColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          
          // Description
          Text(
            widget.hasPromotion
                ? 'A spot has opened up for you! Confirm within the time limit to secure your place at this event.'
                : 'You are on the waitlist for this event. You will be notified if a spot becomes available.',
            style: TextStyles.bodyMedium.copyWith(
              color: widget.hasPromotion
                  ? AppColors.primaryTextColor
                  : AppColors.secondaryTextColor,
            ),
          ),
          
          // Waitlist position
          if (waitlistPosition != null && !widget.hasPromotion) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.format_list_numbered,
                    size: 16,
                    color: AppColors.secondaryTextColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Position: $waitlistPosition of ${widget.event.waitlist.length}',
                    style: TextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Error message
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
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
          ],
          
          // Action button for promotion
          if (widget.hasPromotion && !_isExpired) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isConfirming ? null : _confirmPromotion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warningColor,
                  foregroundColor: AppColors.backgroundColor,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: _isConfirming
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.backgroundColor,
                          ),
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Confirm My Spot Now'),
              ),
            ),
          ],
          
          // Expired message
          if (widget.hasPromotion && _isExpired && _errorMessage == null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.errorColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.timer_off,
                    color: AppColors.errorColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Time expired! This spot has been offered to the next person on the waitlist.',
                      style: TextStyles.bodyMedium.copyWith(
                        color: AppColors.errorColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Timer class for promotion countdown
class PromotionTimer {
  /// Callback for each tick
  final Function(Duration) onTick;
  
  /// Callback when timer completes
  final Function() onComplete;
  
  /// Duration of the timer
  final Duration duration;
  
  /// Current timer instance
  Timer? _timer;
  
  /// Remaining time
  Duration _remaining;
  
  /// Create a promotion timer
  PromotionTimer({
    required this.onTick,
    required this.onComplete,
    required this.duration,
  }) : _remaining = duration;
  
  /// Start the timer
  void start() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remaining = Duration(seconds: _remaining.inSeconds - 1);
      
      // Notify listener of tick
      onTick(_remaining);
      
      // Check if timer is complete
      if (_remaining.inSeconds <= 0) {
        cancel();
        onComplete();
      }
    });
  }
  
  /// Cancel the timer
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
} 