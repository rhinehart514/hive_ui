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
import 'package:hive_ui/features/feed/presentation/widgets/quote_post_button.dart';
import 'package:hive_ui/features/feed/presentation/widgets/repost_button.dart';
import 'package:hive_ui/features/feed/presentation/widgets/boost_dialog.dart';
import 'package:hive_ui/features/auth/providers/role_providers.dart';
import 'package:hive_ui/features/feed/presentation/providers/boost_provider.dart';
import 'package:intl/intl.dart';
import 'package:hive_ui/features/feed/presentation/widgets/feed_item_card.dart';

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
          onRepost: onRepost,
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
      Function(Event, String?, RepostContentType)? onRepost,
    }
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.dark2,
              borderRadius: BorderRadius.circular(8),
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
              borderRadius: BorderRadius.circular(8),
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
                    
                    const SizedBox(height: 24),
                    
                    ShineText(
                      text: event.title,
                      style: GoogleFonts.inter(
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.0,
                        height: 1.5,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Text(
                      event.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.6,
                        letterSpacing: 0.1,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
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
                            const SizedBox(width: 8),
                            Text(
                              event.formattedTimeRange,
                              style: GoogleFonts.inter(
                                color: AppColors.textTertiary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.0,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                        
                        _buildRsvpButton(ref, event, onRsvpToEvent: onRsvpToEvent),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    _buildEngagementActions(ref, event, onRepost: onRepost),
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

    // Use white background with black text per brand aesthetic
    final bgColor = isRsvpd ? AppColors.white : Colors.transparent;
    final fgColor = isRsvpd ? AppColors.black : AppColors.white;
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
        minimumSize: const Size(0, 36), // Height 36px per brand aesthetic for chip-sized buttons
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24), // Pill shape (24px) per brand aesthetic
          side: !isRsvpd 
              ? BorderSide(color: AppColors.white.withOpacity(0.3), width: 1) 
              : BorderSide.none,
        ),
        elevation: 0,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ).copyWith(
        overlayColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.pressed)) {
              // Subtle scale down animation will be handled by global button theme
              return isRsvpd ? Colors.grey.withOpacity(0.1) : AppColors.white.withOpacity(0.1);
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

  /// Build engagement action buttons (Repost, Quote, Boost)
  static Widget _buildEngagementActions(
    WidgetRef ref,
    Event event,
    {
      Function(Event, String?, RepostContentType)? onRepost,
    }
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Repost button
        FeedRepostButton(
          event: event,
          onRepost: (event, comment, type) {
            onRepost?.call(event, comment, type);
          },
          size: 36,
        ),
        
        // Quote post button
        QuotePostButton(
          event: event,
          size: 36,
          onQuotePosted: () {
            // Notify feed of new quote post
            if (onRepost != null) {
              onRepost(event, null, RepostContentType.quote);
            }
          }
        ),
        
        // Boost button (for builders)
        _buildBoostButton(ref, event),
      ],
    );
  }
  
  /// Build a boost button (only enabled for builders)
  static Widget _buildBoostButton(WidgetRef ref, Event event) {
    // Check if user is a builder
    final isBuilder = ref.watch(isBuilderProvider);
    
    // Check if we can boost (don't already have an active boost)
    final canBoost = ref.watch(canBoostProvider);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: (isBuilder && canBoost) ? () {
          // Show boost dialog for builders
          HapticFeedback.mediumImpact();
          
          BoostDialog.show(
            context: ref.context,
            event: event,
            onBoost: (event, durationHours) {
              _handleBoost(ref, event, durationHours);
            },
          );
        } : null,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
            border: Border.all(
              color: isBuilder 
                ? (canBoost ? AppColors.gold.withOpacity(0.3) : Colors.grey.withOpacity(0.3))
                : AppColors.textTertiary.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.rocket_launch_outlined,
              color: isBuilder
                ? (canBoost ? AppColors.gold : Colors.grey.withOpacity(0.5))
                : AppColors.textTertiary.withOpacity(0.5),
              size: 18,
            ),
          ),
        ),
      ),
    );
  }

  /// Handle boost action
  static void _handleBoost(WidgetRef ref, Event event, int durationHours) {
    // Use the boost provider to boost the event
    ref.read(boostProvider.notifier).boostEvent(event, durationHours);
    
    // Show feedback to the user
    ScaffoldMessenger.of(ref.context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.rocket_launch,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text('Boosted for $durationHours hours: ${event.title}'),
          ],
        ),
        backgroundColor: AppColors.gold.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

/// Creates an event card with Twitter/X-like styling
Widget buildEventCard(
  BuildContext context,
  Event event,
  bool isRsvped,
  VoidCallback onRsvpTap,
  VoidCallback onCardTap,
) {
  // Format the time in a concise way
  final formattedTime = _formatEventTime(event);
  
  // Create the actions for the card
  final actions = [
    FeedItemCard.buildActionButton(
      context, 
      Icons.event_available,
      isRsvped ? 'Going' : 'RSVP',
      onRsvpTap,
    ),
    FeedItemCard.buildActionButton(
      context, 
      Icons.repeat_rounded,
      'Repost',
      () => HapticFeedback.lightImpact(),
    ),
    FeedItemCard.buildActionButton(
      context, 
      Icons.bookmark_border_rounded,
      'Save',
      () => HapticFeedback.lightImpact(),
    ),
  ];
  
  return FeedItemCard(
    leading: CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.dark2,
      backgroundImage: event.imageUrl != null && event.imageUrl!.isNotEmpty
          ? NetworkImage(event.imageUrl!)
          : null,
      child: event.imageUrl == null || event.imageUrl!.isEmpty
          ? const Icon(Icons.event, color: AppColors.textSecondary)
          : null,
    ),
    title: event.title,
    subtitle: event.location,
    timeAgo: formattedTime,
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (event.description != null && event.description!.isNotEmpty)
          Text(
            event.description!,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    ),
    actions: actions,
    onTap: onCardTap,
    isEvent: true,
  );
}

/// Helper method to format event time in a concise Twitter-like way
String _formatEventTime(Event event) {
  if (event.startDate == null) return '';

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  final startDate = DateTime(
    event.startDate.year,
    event.startDate.month,
    event.startDate.day,
  );
  
  // Get just the time portion (e.g., "3:45 PM")
  final timeFormat = DateFormat('h:mm a');
  final startTimeStr = timeFormat.format(event.startDate);
  
  // For events today
  if (startDate.isAtSameMomentAs(today)) {
    return 'Today at $startTimeStr';
  }
  
  // For events tomorrow
  if (startDate.isAtSameMomentAs(tomorrow)) {
    return 'Tomorrow at $startTimeStr';
  }
  
  // For events within a week
  final difference = startDate.difference(today).inDays;
  if (difference > 0 && difference < 7) {
    final dayFormat = DateFormat('EEEE'); // Full day name
    return '${dayFormat.format(event.startDate)} at $startTimeStr';
  }
  
  // For other events
  final dateFormat = DateFormat('MMM d');
  return '${dateFormat.format(event.startDate)} at $startTimeStr';
} 