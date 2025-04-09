import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/event.dart';
import '../../models/user_profile.dart';
import '../../models/repost_content_type.dart';
import '../../theme/app_colors.dart';
import '../../theme/huge_icons.dart';
import '../../services/event_service.dart';
import '../../providers/profile_provider.dart';
import '../../providers/reposted_events_provider.dart';
import '../../components/optimized_image.dart';
import 'repost_options_card.dart';
import 'package:go_router/go_router.dart';
import '../../providers/feed_provider.dart';
import '../../services/feed/feed_analytics.dart';
import '../../components/moderation/report_button.dart';
import '../../features/moderation/domain/entities/content_report_entity.dart';

/// A premium event card component that follows HIVE's brand aesthetic:
/// - Black/white core with layered visual depth
/// - Subtle glassmorphism with soft borders and backdrop blur
/// - Rounded geometry (BorderRadius.circular(24))
/// - Sleek, high-end Apple-like presentation with proper spacing
/// - Interaction polish: scale animations, haptic feedback
class HiveEventCard extends ConsumerStatefulWidget {
  /// The event to display
  final Event event;
  
  /// Whether this is a reposted event card
  final bool isRepost;
  
  /// User who reposted this event (if isRepost is true)
  final UserProfile? repostedBy;
  
  /// Timestamp of the repost (if isRepost is true)
  final DateTime? repostTimestamp;
  
  /// Text of the quote (if this is a quoted repost)
  final String? quoteText;
  
  /// Type of repost (standard, quote, etc.)
  final RepostContentType repostType;
  
  /// Called when the card is tapped
  final Function(Event)? onTap;

  /// Called when the user RSVPs to the event
  final Function(Event)? onRsvp;

  /// Called when the user reposts the event
  final Function(Event, String?, RepostContentType)? onRepost;
  
  /// Called when the user reports the event
  final Function(Event)? onReport;
  
  /// Whether the user follows the club associated with this event
  final bool followsClub;
  
  /// List of boost timestamps for today (to check if already boosted)
  final List<DateTime> todayBoosts;

  /// Whether this card is being displayed as part of a quote
  final bool isQuoted;

  /// Constructor
  const HiveEventCard({
    Key? key,
    required this.event,
    this.isRepost = false,
    this.repostedBy,
    this.repostTimestamp,
    this.quoteText,
    this.repostType = RepostContentType.standard,
    this.onTap,
    this.onRsvp,
    this.onRepost,
    this.onReport,
    this.followsClub = false,
    this.todayBoosts = const [],
    this.isQuoted = false,
  }) : super(key: key);

  @override
  ConsumerState<HiveEventCard> createState() => _HiveEventCardState();
}

class _HiveEventCardState extends ConsumerState<HiveEventCard> 
    with SingleTickerProviderStateMixin {
  // Animation controller for interactions
  late AnimationController _animationController;
  
  // Track local RSVP state
  bool _isRsvped = false;
  
  // Track if card is being pressed
  bool _isPressed = false;
  
  // Track if repost button is scaling
  bool _isRepostScaling = false;
  
  // Track if analytics has been logged
  bool _hasLoggedView = false;
  
  // Track previous repost state for animation
  bool _wasReposted = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Initialize the previous repost state
    _wasReposted = widget.isRepost && widget.repostedBy != null;
    
    // Check if the current user is already RSVP'd to this event
    _checkRsvpStatus();
  }
  
  @override
  void didUpdateWidget(HiveEventCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update the previous repost state
    final isCurrentlyReposted = widget.isRepost && widget.repostedBy != null;
    _wasReposted = oldWidget.isRepost && oldWidget.repostedBy != null;
    
    // If the repost state changed from false to true, play the animation
    if (isCurrentlyReposted && !_wasReposted) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Check if user has RSVP'd to this event
  Future<void> _checkRsvpStatus() async {
    try {
      final currentUser = ref.read(profileProvider).profile;
      if (currentUser != null) {
        final isRsvped = await EventService.getEventRsvpStatus(widget.event.id);
        if (mounted) {
          setState(() {
            _isRsvped = isRsvped;
          });
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }
  
  // Check if current user has reposted this event
  bool _hasUserReposted() {
    try {
      final currentUser = ref.watch(profileProvider).profile;
      if (currentUser != null) {
        final repostedEvents = ref.watch(repostedEventsProvider);
        return repostedEvents.any((repost) => 
          repost.event.id == widget.event.id && 
          repost.repostedBy.id == currentUser.id
        );
      }
    } catch (e) {
      debugPrint('Error checking if user reposted: $e');
    }
    return false;
  }
  
  // Get repost count for this event
  int _getRepostCount() {
    try {
      final repostedEvents = ref.watch(repostedEventsProvider);
      return repostedEvents.where((repost) => repost.event.id == widget.event.id).length;
    } catch (e) {
      debugPrint('Error getting repost count: $e');
      return 0;
    }
  }
  
  // Log view interaction for analytics
  void _logViewInteraction() {
    try {
      FeedAnalytics.trackEventView(widget.event);
    } catch (e) {
      // Handle error silently
    }
  }

  // Handle card tap with haptic feedback
  void _handleTap() {
    HapticFeedback.selectionClick();
    
    // Navigate to event details using router with relative path
    final context = this.context;
    if (context.mounted) {
      GoRouter.of(context).push(
        'event/${widget.event.id}',  // Use relative path instead of absolute
        extra: {'event': widget.event},
      );
    }
  }

  // Handle RSVP with animation and haptic feedback
  void _handleRsvp() async {
    if (widget.onRsvp != null) {
      HapticFeedback.mediumImpact();
      
      // Store previous state for possible rollback
      final previousRsvpState = _isRsvped;
      
      try {
        // Play animation
        _animationController.forward().then((_) {
          _animationController.reverse();
        });
        
        // Update local state immediately for responsive feel
        setState(() {
          _isRsvped = !_isRsvped;
        });
        
        // Call the callback with the event - this should trigger the backend update
        await widget.onRsvp!(widget.event);
      } catch (e) {
        // If there's an error, revert the local state
        if (mounted) {
          debugPrint('Error in _handleRsvp: $e - reverting UI state');
          setState(() {
            _isRsvped = previousRsvpState;
          });
          
          // Revert animation if needed
          if (_animationController.status == AnimationStatus.completed) {
            _animationController.reverse();
          }
          
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to update RSVP status'),
              backgroundColor: Colors.red.shade900,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }
  
  // Handle repost with animation and haptic feedback
  void _handleRepost() {
    HapticFeedback.lightImpact();
    
    // Show repost options bottom sheet
    if (widget.onRepost != null) {
      // No longer need to check authentication here as it's handled in the parent
      context.showRepostOptions(
        event: widget.event,
        onRepostSelected: (event, comment, contentType) async {
          // Call the callback
          if (widget.onRepost != null) {
            await widget.onRepost!(event, comment, contentType);
            
            // Just trigger the animation without showing a duplicate message
            if (mounted) {
              // Trigger a confetti animation or other visual feedback
              _animationController.forward().then((_) {
                _animationController.reverse();
              });
            }
          }
        },
        followsClub: widget.followsClub,
        todayBoosts: widget.todayBoosts,
      );
      
      setState(() {
        _isRepostScaling = false;
      });
    }
  }
  
  // Trigger scale animation for repost button
  void _triggerRepostScale(bool isScaling) {
    setState(() {
      _isRepostScaling = isScaling;
    });
  }

  // Handle report button tap
  void _handleReport() {
    HapticFeedback.mediumImpact();
    if (widget.onReport != null) {
      widget.onReport!(widget.event);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Log view when visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasLoggedView) {
        _logViewInteraction();
        _hasLoggedView = true;
      }
    });

    // Check if the card is reposted
    final isReposted = widget.isRepost && widget.repostedBy != null;
    final isQuote = isReposted && widget.repostType == RepostContentType.quote && widget.quoteText != null && widget.quoteText!.isNotEmpty;

    // Apply different styling if this is a quoted card
    final margin = widget.isQuoted 
        ? const EdgeInsets.all(0)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    final borderRadius = widget.isQuoted ? 12.0 : 24.0;

    // Wrap the card with Dismissible for swipe-to-dismiss functionality
    return Dismissible(
      key: ValueKey('dismissible_${widget.event.id}'),
      direction: DismissDirection.endToStart, // Only allow right to left swipe
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        color: Colors.red.shade900,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.not_interested,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Not Interested',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        // Confirm the dismissal with haptic feedback
        HapticFeedback.mediumImpact();
        
        // Show a snackbar to confirm
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Event removed from your feed',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.black.withOpacity(0.8),
            action: SnackBarAction(
              label: 'UNDO',
              textColor: AppColors.gold,
              onPressed: () {
                // Refresh feed to bring item back (provider implementation)
                ref.read(feedStateProvider.notifier).refreshFeed();
              },
            ),
          ),
        );
        
        // Return true to confirm dismiss
        return true;
      },
      onDismissed: (direction) {
        // Call the provider to hide this event from the feed
        ref.read(feedStateProvider.notifier).hideEvent(widget.event.id);
      },
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User repost status - show if current user has reposted this event
            Builder(
              builder: (context) {
                final hasReposted = _hasUserReposted();
                final repostCount = _getRepostCount();
                
                if (!hasReposted || repostCount == 0) {
                  return const SizedBox.shrink();
                }
                
                final repostText = repostCount > 1 
                  ? 'You and ${repostCount - 1} other${repostCount > 2 ? 's' : ''} reposted' 
                  : 'You reposted';
                
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.repeat_rounded,
                        size: 14,
                        color: AppColors.gold.withOpacity(0.8),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        repostText,
                        style: GoogleFonts.inter(
                          color: AppColors.white.withOpacity(0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }
            ),
            
            // Show repost header if this is a repost with animation
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.5),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: isReposted
                  ? isQuote 
                      ? _QuoteRepostHeader(
                          key: ValueKey('quote_${widget.event.id}'),
                          user: widget.repostedBy!,
                          time: widget.repostTimestamp ?? DateTime.now(),
                          quoteText: widget.quoteText!,
                          event: widget.event,
                          onEventTap: widget.onTap != null ? () => widget.onTap!(widget.event) : null,
                        )
                      : _RepostHeader(
                          key: ValueKey('repost_${widget.event.id}'),
                          user: widget.repostedBy!,
                          time: widget.repostTimestamp ?? DateTime.now(),
                          repostType: widget.repostType,
                        )
                  : const SizedBox.shrink(key: ValueKey('no_repost')),
            ),
            
            // Only show the main card if this is not a quote repost
            // For quote reposts, the quoted event is shown in the header
            if (!isQuote)
              AnimatedScale(
                scale: _isPressed ? 0.98 : 1.0,
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                child: GestureDetector(
                  onTap: () {
                    // Navigate to event details using the correct nested path
                    if (context.mounted) {
                      context.push('/home/event/${widget.event.id}', extra: {
                        'event': widget.event,
                        'heroTag': 'event-card-${widget.event.id}',
                      });
                    }
                  },
                  onTapDown: (_) => setState(() => _isPressed = true),
                  onTapUp: (_) => setState(() => _isPressed = false),
                  onTapCancel: () => setState(() => _isPressed = false),
                  child: _EventCardBody(
                    event: widget.event,
                    isRsvped: _isRsvped,
                    isRepostScaling: _isRepostScaling,
                    onRsvp: _handleRsvp,
                    onRepostScale: _triggerRepostScale,
                    onRepost: _handleRepost,
                    followsClub: widget.followsClub,
                    todayBoosts: widget.todayBoosts,
                    margin: margin,
                    borderRadius: borderRadius,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Repost header component displayed above a reposted event card
class _RepostHeader extends StatelessWidget {
  final UserProfile user;
  final DateTime time;
  final RepostContentType repostType;
  
  const _RepostHeader({
    Key? key,
    required this.user,
    required this.time,
    this.repostType = RepostContentType.standard,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User avatar and name row
          Row(
            children: [
              // User avatar
              if (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    user.profileImageUrl!,
                    width: 24,
                    height: 24,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.grey700,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              const SizedBox(width: 8),
              
              // User name and repost time
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: user.displayName,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      TextSpan(
                        text: ' ${repostType == RepostContentType.quote ? 'quoted' : 'reposted'} · ${_formatTimeAgo(time)}',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Format time as relative time (e.g. "2h ago")
  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'just now';
    }
  }
}

/// Specialized header component for quoted reposts, following X/Twitter style
class _QuoteRepostHeader extends StatelessWidget {
  final UserProfile user;
  final DateTime time;
  final String quoteText;
  final Event event;
  final VoidCallback? onEventTap;
  
  const _QuoteRepostHeader({
    Key? key,
    required this.user,
    required this.time,
    required this.quoteText,
    required this.event,
    this.onEventTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info row
          Row(
            children: [
              // User avatar
              if (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    user.profileImageUrl!,
                    width: 28,
                    height: 28,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.grey700,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              const SizedBox(width: 10),
              
              // User name and time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _formatTimeAgo(time),
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Quote icon
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.format_quote,
                  size: 16,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
          
          // Quote text
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 16),
            child: Text(
              quoteText,
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ),
          
          // Quoted event preview
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.grey800,
                width: 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onEventTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (event.imageUrl.isNotEmpty)
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        event.imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${event.formattedTimeRange} • ${event.organizerName}',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Format time as relative time (e.g. "2h ago")
  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }
}

/// Main event card body component 
class _EventCardBody extends StatelessWidget {
  final Event event;
  final bool isRsvped;
  final bool isRepostScaling;
  final VoidCallback onRsvp;
  final Function(bool) onRepostScale;
  final VoidCallback onRepost;
  final bool followsClub;
  final List<DateTime> todayBoosts;
  final EdgeInsets margin;
  final double borderRadius;

  const _EventCardBody({
    required this.event,
    required this.isRsvped,
    required this.isRepostScaling,
    required this.onRsvp,
    required this.onRepostScale,
    required this.onRepost,
    this.followsClub = false,
    this.todayBoosts = const [],
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.borderRadius = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: double.infinity,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event image if available
          if (event.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(borderRadius),
                topRight: Radius.circular(borderRadius),
              ),
              child: OptimizedImage(
                imageUrl: event.imageUrl,
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover,
              ),
            ),
          
          // Date and boost row
          _DateAndBoostRow(event: event),
          const SizedBox(height: 12),
          
          // Content section with padding
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event title
                _EventTitle(title: event.title),
                const SizedBox(height: 12),
                
                // Time and location
                _TimeAndLocationRow(
                  time: event.formattedTimeRange,
                  location: event.location,
                ),
                const SizedBox(height: 16),
                
                // CTA button row
                _CTAButtonsRow(
                  isRsvped: isRsvped,
                  isRepostScaling: isRepostScaling,
                  onRsvp: onRsvp,
                  onRepostScale: onRepostScale,
                  onRepost: onRepost,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Date and boost row component
class _DateAndBoostRow extends StatelessWidget {
  final Event event;

  const _DateAndBoostRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('E, MMM d • h:mm a').format(event.startDate);
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Date
          Expanded(
            child: Row(
              children: [
                const Icon(
                  HugeIcons.calendar,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  formattedDate,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          // Report button
          ReportButton(
            contentId: event.id,
            contentType: ReportedContentType.event,
            contentPreview: event.title,
            ownerId: event.createdBy,
            size: 16,
            color: Colors.white54,
          ),
        ],
      ),
    );
  }
}

/// Event title component
class _EventTitle extends StatelessWidget {
  final String title;

  const _EventTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
        letterSpacing: -0.5,
        height: 1.2,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Time and location row component
class _TimeAndLocationRow extends StatelessWidget {
  final String time;
  final String location;

  const _TimeAndLocationRow({
    required this.time,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time row
        Row(
          children: [
            const Icon(
              HugeIcons.calendar,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                time,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        
        // Location row
        Row(
          children: [
            const Icon(
              HugeIcons.strokeRoundedHouse03,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                location,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// CTA buttons row component
class _CTAButtonsRow extends StatelessWidget {
  final bool isRsvped;
  final bool isRepostScaling;
  final VoidCallback onRsvp;
  final Function(bool) onRepostScale;
  final VoidCallback onRepost;

  const _CTAButtonsRow({
    required this.isRsvped,
    required this.isRepostScaling,
    required this.onRsvp,
    required this.onRepostScale,
    required this.onRepost,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // RSVP button with animation
        _AnimatedRsvpButton(
          isRsvped: isRsvped,
          onRsvp: onRsvp,
        ),

        // Repost with scale interaction
        GestureDetector(
          onTapDown: (_) => onRepostScale(true),
          onTapUp: (_) => onRepost(),
          onTapCancel: () => onRepostScale(false),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 120),
            scale: isRepostScaling ? 0.95 : 1.0,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                HugeIcons.strokeRoundedHexagon01,
                color: AppColors.yellow.withOpacity(0.8),
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Animated RSVP button with tap animation and gold color when active
class _AnimatedRsvpButton extends StatefulWidget {
  final bool isRsvped;
  final VoidCallback onRsvp;

  const _AnimatedRsvpButton({
    required this.isRsvped,
    required this.onRsvp,
  });

  @override
  State<_AnimatedRsvpButton> createState() => _AnimatedRsvpButtonState();
}

class _AnimatedRsvpButtonState extends State<_AnimatedRsvpButton> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
    widget.onRsvp();
    HapticFeedback.mediumImpact();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final bool isRsvped = widget.isRsvped;
    
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 120,
              height: 42,
              decoration: BoxDecoration(
                color: isRsvped ? AppColors.gold.withOpacity(0.2) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isRsvped ? AppColors.gold : Colors.transparent,
                  width: 1,
                ),
                boxShadow: isRsvped ? [
                  BoxShadow(
                    color: AppColors.gold.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 0,
                  )
                ] : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isRsvped ? HugeIcons.strokeRoundedTick01 : HugeIcons.calendar,
                    size: 18,
                    color: isRsvped ? AppColors.gold : Colors.black,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isRsvped ? "GOING" : "RSVP",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isRsvped ? AppColors.gold : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
