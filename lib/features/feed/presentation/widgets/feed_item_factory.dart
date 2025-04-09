import 'package:flutter/material.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/models/repost_content_type.dart';
import 'package:hive_ui/models/space_recommendation_simple.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/providers/auth_provider.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// Factory class for creating feed item widgets
class FeedItemFactory {
  /// Creates the appropriate widget for a feed item based on its type
  static Widget createFeedItem(
    WidgetRef ref,
    Map<String, dynamic> item,
    {
      Function(Event)? onNavigateToEventDetails,
      Function(Event)? onRsvpToEvent,
      Function(Event, String?, RepostContentType)? onRepost,
    }
  ) {
    final type = item['type'] as String;
    final data = item['data'];

    switch (type) {
      case 'event':
        return _buildGlassEventCard(
          ref,
          data as Event,
          onNavigateToEventDetails: onNavigateToEventDetails,
          onRsvpToEvent: onRsvpToEvent,
        );
      case 'repost':
        return _buildRepostCard(
          ref,
          event: data.event as Event,
          reposter: data.reposterProfile,
          repostTime: data.repostTime,
          comment: data.comment,
          contentType: data.contentType as RepostContentType,
          onNavigateToEventDetails: onNavigateToEventDetails,
          onRsvpToEvent: onRsvpToEvent,
          onRepost: onRepost,
        );
      case 'recommendation':
        return _buildSpaceRecommendationCard(
          ref,
          data as SpaceRecommendationSimple,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  /// Build an event card with glassmorphism effect adhering to HIVE UI standards
  static Widget _buildGlassEventCard(
    WidgetRef ref,
    Event event, 
    {
      Function(Event)? onNavigateToEventDetails,
      Function(Event)? onRsvpToEvent,
    }
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.white.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                onNavigateToEventDetails?.call(event);
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildEventStateIndicator(event),
                        const Spacer(),
                        _buildEventDateBadge(event),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    ShineText(
                      text: event.title,
                      style: GoogleFonts.inter(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      event.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                        letterSpacing: 0.1,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              color: AppColors.textTertiary,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              event.formattedTimeRange,
                              style: GoogleFonts.inter(
                                color: AppColors.textTertiary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                        
                        _buildRsvpButton(ref, event, onRsvpToEvent: onRsvpToEvent),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build the standard event card (for backward compatibility)
  static Widget _buildEventCard(Event event) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          // Event tap handler will be added later
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: GoogleFonts.inter(
                  color: AppColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.25,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                event.description,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    event.formattedTimeRange,
                    style: GoogleFonts.inter(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.2,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      // RSVP handler will be added later
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ).copyWith(
                      overlayColor: MaterialStateProperty.resolveWith<Color?>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.pressed)) {
                            return AppColors.primary.withOpacity(0.15);
                          }
                          return null;
                        },
                      ),
                    ),
                    child: Text(
                      'RSVP',
                      style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildRepostCard(
    WidgetRef ref,
    {
    required Event event,
    required dynamic reposter,
    required DateTime repostTime,
    String? comment,
    required RepostContentType contentType,
    Function(Event)? onNavigateToEventDetails,
    Function(Event)? onRsvpToEvent,
    Function(Event, String?, RepostContentType)? onRepost,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 0.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.repeat, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Reposted by ${reposter?.displayName ?? "Someone"}',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                  
                  if (comment != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.white.withOpacity(0.05),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        comment,
                        style: GoogleFonts.inter(
                          color: AppColors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  _buildGlassEventCard(
                    ref,
                    event,
                    onNavigateToEventDetails: onNavigateToEventDetails,
                    onRsvpToEvent: onRsvpToEvent,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildSpaceRecommendationCard(
    WidgetRef ref,
    SpaceRecommendationSimple space
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 0.5,
              ),
            ),
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                // Space tap handler will be added later
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.group, size: 14, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                'RECOMMENDED',
                                style: GoogleFonts.inter(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${(space.score * 100).round()}% match',
                            style: GoogleFonts.inter(
                              color: AppColors.white.withOpacity(0.8),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ShineText(
                      text: space.name,
                      style: GoogleFonts.inter(
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      space.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          space.category,
                          style: GoogleFonts.inter(
                            color: AppColors.textTertiary,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.2,
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            // Join space handler will be added later
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary, width: 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: Text(
                            'View Space',
                            style: GoogleFonts.inter(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // Helper widgets for event cards
  
  /// Build an event state indicator - Updated styling
  static Widget _buildEventStateIndicator(Event event) {
    Color bgColor = AppColors.grey.withOpacity(0.2);
    Color textColor = AppColors.grey;
    String stateText = 'Upcoming';
    IconData icon = Icons.event_available_outlined;
    
    if (event.isCancelled) {
      bgColor = AppColors.error.withOpacity(0.15);
      textColor = AppColors.error;
      stateText = 'Cancelled';
      icon = Icons.cancel_outlined;
    } else if (event.isLive) {
      bgColor = AppColors.success.withOpacity(0.15);
      textColor = AppColors.success;
      stateText = 'Live Now';
      icon = Icons.sensors_rounded;
    } else if (event.isPast) {
      bgColor = AppColors.grey.withOpacity(0.15);
      textColor = AppColors.textTertiary;
      stateText = 'Past';
      icon = Icons.history_rounded;
    } else if (event.isToday) {
      bgColor = AppColors.primary.withOpacity(0.15);
      textColor = AppColors.primary;
      stateText = 'Today';
      icon = Icons.star_border_rounded;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            stateText.toUpperCase(),
            style: GoogleFonts.inter(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build an event date badge - Updated styling
  static Widget _buildEventDateBadge(Event event) {
    final dateFormat = "${_getMonthAbbreviation(event.startDate.month)} ${event.startDate.day}";
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(
            dateFormat,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Get month abbreviation from month number
  static String _getMonthAbbreviation(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
  
  /// Build RSVP button - Updated styling
  static Widget _buildRsvpButton(WidgetRef ref, Event event, {Function(Event)? onRsvpToEvent}) {
    final currentUserId = ref.watch(currentUserIdProvider);
    bool isRsvpd = false;
    if (currentUserId != null) {
      isRsvpd = event.attendees.contains(currentUserId);
    }

    final bgColor = isRsvpd ? AppColors.primary.withOpacity(0.8) : AppColors.white.withOpacity(0.1);
    final fgColor = isRsvpd ? AppColors.black : AppColors.primary;
    final text = isRsvpd ? 'GOING' : 'RSVP';

    return ElevatedButton(
      onPressed: () {
        HapticFeedback.mediumImpact();
        onRsvpToEvent?.call(event);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: const Size(0, 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: !isRsvpd 
              ? BorderSide(color: AppColors.primary.withOpacity(0.7), width: 1) 
              : BorderSide.none,
        ),
        elevation: 0,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ).copyWith(
        overlayColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.pressed)) {
              return fgColor.withOpacity(0.1);
            }
            return null;
          },
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// A text widget with a shine/glow effect for titles
class ShineText extends StatefulWidget {
  final String text;
  final TextStyle style;
  
  const ShineText({
    Key? key,
    required this.text,
    required this.style,
  }) : super(key: key);
  
  @override
  State<ShineText> createState() => _ShineTextState();
}

class _ShineTextState extends State<ShineText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _animation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    
    // Auto-play animation after random delay
    Future.delayed(Duration(milliseconds: 500 + 1000), () {
      if (mounted) {
        _controller.repeat(reverse: false);
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                widget.style.color!,
                AppColors.primary.withOpacity(0.9),
                widget.style.color!,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              transform: GradientRotation(_animation.value * 0.2),
            ).createShader(bounds);
          },
          child: Text(
            widget.text,
            style: widget.style,
          ),
        );
      },
    );
  }
} 