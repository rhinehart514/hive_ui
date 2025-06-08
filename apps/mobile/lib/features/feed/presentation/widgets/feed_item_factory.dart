import 'package:flutter/material.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/models/repost_content_type.dart';
import 'package:hive_ui/models/space_recommendation_simple.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/theme/app_colors.dart';
import '../../../../components/event_card/event_card.dart';

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
        final event = data as Event;
        return HiveEventCard(
          key: ValueKey('event_${event.id}'),
          event: event,
          onTap: onNavigateToEventDetails != null ? (e) => onNavigateToEventDetails(e) : null,
          onRsvp: onRsvpToEvent != null ? (e) => onRsvpToEvent(e) : null,
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
                  
                  HiveEventCard(
                    key: ValueKey('reposted_event_${event.id}'),
                    event: event,
                    isRepost: true,
                    repostedBy: reposter,
                    repostTimestamp: repostTime,
                    quoteText: comment,
                    repostType: contentType,
                    onTap: onNavigateToEventDetails != null ? (e) => onNavigateToEventDetails(e) : null,
                    onRsvp: onRsvpToEvent != null ? (e) => onRsvpToEvent(e) : null,
                    onRepost: onRepost,
                    isQuoted: contentType == RepostContentType.quote,
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
    Future.delayed(const Duration(milliseconds: 500 + 1000), () {
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