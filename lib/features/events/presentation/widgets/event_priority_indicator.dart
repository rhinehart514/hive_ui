import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/models/event.dart';
import 'package:google_fonts/google_fonts.dart';

/// A visual indicator that shows the urgency/proximity of an event
/// The color and intensity changes as the event gets closer
class EventPriorityIndicator extends StatelessWidget {
  /// The event to indicate priority for
  final Event event;
  
  /// The size of the indicator
  final double size;
  
  /// Whether to show the label
  final bool showLabel;
  
  /// Creates an event priority indicator
  const EventPriorityIndicator({
    Key? key,
    required this.event,
    this.size = 24.0,
    this.showLabel = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate how soon the event is
    final urgencyLevel = _calculateUrgencyLevel();
    final color = _getColorForUrgency(urgencyLevel);
    final label = _getLabelForUrgency(urgencyLevel);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated pulse if very urgent
        _buildIndicator(color, urgencyLevel),
        
        if (showLabel && label != null) ...[
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
  
  /// Build the indicator with optional animation
  Widget _buildIndicator(Color color, double urgencyLevel) {
    // For high urgency (>0.8), add a pulse animation
    if (urgencyLevel > 0.8) {
      return TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.8, end: 1.1),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: _buildCircleIndicator(color, urgencyLevel),
          );
        },
      );
    } else {
      return _buildCircleIndicator(color, urgencyLevel);
    }
  }
  
  /// Build the actual circle indicator
  Widget _buildCircleIndicator(Color color, double urgencyLevel) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.2),
        border: Border.all(
          color: color,
          width: 2,
        ),
        boxShadow: urgencyLevel > 0.5 ? [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ] : null,
      ),
      child: Center(
        child: Icon(
          _getIconForUrgency(urgencyLevel),
          size: size * 0.6,
          color: color,
        ),
      ),
    );
  }
  
  /// Calculate a value from 0-1 representing how urgent/close the event is
  double _calculateUrgencyLevel() {
    final now = DateTime.now();
    
    // If event is in the past, no urgency
    if (event.startDate.isBefore(now)) {
      return 0.0;
    }
    
    final difference = event.startDate.difference(now);
    
    // Different timescales based on how far away the event is
    if (difference.inDays > 14) {
      // More than two weeks away - minimal urgency
      return 0.1;
    } else if (difference.inDays > 7) {
      // 1-2 weeks away - low urgency
      return 0.2;
    } else if (difference.inDays > 3) {
      // 3-7 days away - moderate urgency
      return 0.4;
    } else if (difference.inDays > 1) {
      // 1-3 days away - increased urgency
      return 0.6;
    } else if (difference.inHours > 6) {
      // 6-24 hours away - high urgency
      return 0.8;
    } else if (difference.inHours > 2) {
      // 2-6 hours away - very high urgency
      return 0.9;
    } else {
      // Less than 2 hours away - maximum urgency
      return 1.0;
    }
  }
  
  /// Get the appropriate color based on urgency level
  Color _getColorForUrgency(double urgencyLevel) {
    if (urgencyLevel < 0.3) {
      return AppColors.grey; // Low urgency - grey
    } else if (urgencyLevel < 0.6) {
      return AppColors.info; // Medium urgency - blue
    } else if (urgencyLevel < 0.9) {
      return AppColors.warning; // High urgency - amber
    } else {
      return AppColors.gold; // Very high urgency - gold
    }
  }
  
  /// Get the appropriate icon based on urgency level
  IconData _getIconForUrgency(double urgencyLevel) {
    if (urgencyLevel < 0.3) {
      return Icons.calendar_month_outlined; // Low urgency
    } else if (urgencyLevel < 0.6) {
      return Icons.calendar_today_outlined; // Medium urgency
    } else if (urgencyLevel < 0.9) {
      return Icons.access_time_filled_outlined; // High urgency
    } else {
      return Icons.priority_high; // Very high urgency
    }
  }
  
  /// Get a label based on urgency level
  String? _getLabelForUrgency(double urgencyLevel) {
    if (!showLabel) return null;
    
    if (urgencyLevel < 0.3) {
      return 'Upcoming';
    } else if (urgencyLevel < 0.6) {
      return 'Soon';
    } else if (urgencyLevel < 0.9) {
      return 'Happening Soon';
    } else {
      return 'Starting Soon!';
    }
  }
} 