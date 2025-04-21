import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:ui'; // Import for ImageFilter
// import 'package:vector_math/vector_math_64.dart' as vector; // Not used currently
// import 'dart:ui'; // Not used currently

import '../../models/event.dart';
import '../../models/user_profile.dart';
import '../../models/repost_content_type.dart';
import '../../theme/app_colors.dart';
// import '../../theme/app_theme.dart'; // Removed theme dependency
import '../../theme/huge_icons.dart'; // Keep for other icons if used elsewhere
import '../../services/event_service.dart';
import '../../providers/profile_provider.dart';
import '../../providers/reposted_events_provider.dart';
import '../../components/optimized_image.dart';
import '../../components/card_lifecycle.dart';
import '../../components/card_lifecycle_wrapper.dart';
import 'repost_options_card.dart';
import 'package:go_router/go_router.dart';
import '../../providers/feed_provider.dart';
import '../../services/feed/feed_analytics.dart';
import '../../components/moderation/report_button.dart';
import '../../features/moderation/domain/entities/content_report_entity.dart';
import '../../features/events/presentation/routing/event_routes.dart';
import '../../widgets/glassmorphism.dart'; // Corrected import path
// Removed: import '../../widgets/buttons/hive_pill_button.dart'; // Removed non-existent import

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
    // Ensure view is logged only once per card instance
    if (!_hasLoggedView) {
      _hasLoggedView = true;
      _logViewInteraction();
    }
    
    // Create the card with our improved layout
    Widget cardContent = _buildEnhancedCardContent(context);
    
    // Apply the lifecycle wrapper based on the event's creation date and state
    // Use lastModified as a proxy for creation date if available, otherwise fall back to startDate
    final DateTime creationTime = widget.event.lastModified ?? widget.event.startDate;
    final bool isActive = !widget.event.isCancelled && 
                         widget.event.currentState != EventLifecycleState.archived;
    
    // Use the appropriate lifecycle state based on the event's properties
    final CardLifecycleState lifecycleState = _determineCardLifecycleState();

    // Apply the lifecycle visualization directly with CardLifecycleWrapper
    return CardLifecycleWrapper(
      createdAt: creationTime,
      state: lifecycleState,
      autoAge: isActive,
      showIndicator: false, // Don't show the indicator (we have EventLifecycleBadge)
      child: cardContent,
    );
  }
  
  // Determine the appropriate card lifecycle state based on event properties
  CardLifecycleState _determineCardLifecycleState() {
    // If event is cancelled or archived, use archived state
    if (widget.event.isCancelled || widget.event.currentState == EventLifecycleState.archived) {
      return CardLifecycleState.archived;
    }
    
    // For completed events, use old state
    if (widget.event.currentState == EventLifecycleState.completed) {
      return CardLifecycleState.old;
    }
    
    // For draft events, use aging state (less visibility)
    if (widget.event.currentState == EventLifecycleState.draft) {
      return CardLifecycleState.aging;
    }
    
    // For live events, use fresh state (maximum visibility)
    if (widget.event.currentState == EventLifecycleState.live) {
      return CardLifecycleState.fresh;
    }
    
    // For published events, base it on lastModified/startDate
    final DateTime now = DateTime.now();
    final DateTime creationTime = widget.event.lastModified ?? widget.event.startDate;
    final Duration age = now.difference(creationTime);
    
    // Fresh if less than 24 hours old
    if (age <= const Duration(hours: 24)) {
      return CardLifecycleState.fresh;
    }
    
    // Aging if less than 3 days old
    if (age <= const Duration(days: 3)) {
      return CardLifecycleState.aging;
    }
    
    // Otherwise, old
    return CardLifecycleState.old;
  }

  // Our new integrated card design that works well for both web and mobile
  Widget _buildEnhancedCardContent(BuildContext context) {
    final now = DateTime.now();
    final bool isLive = widget.event.startDate.isBefore(now) && widget.event.endDate.isAfter(now);
    final bool isPast = widget.event.endDate.isBefore(now);
    final isReposted = widget.isRepost && widget.repostedBy != null;
    final isQuote = isReposted && widget.repostType == RepostContentType.quote && 
                    widget.quoteText != null && widget.quoteText!.isNotEmpty;
    
    // Apply different styling if this is a quoted card
    final margin = widget.isQuoted 
        ? const EdgeInsets.all(0)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    final borderRadius = widget.isQuoted ? 12.0 : 16.0;
    
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
              _buildModernCard(
                borderRadius: borderRadius,
                margin: margin,
                isLive: isLive,
              ),
          ],
        ),
      ),
    );
  }
  
  // Modern card design with text overlaid directly on image
  Widget _buildModernCard({
    required double borderRadius,
    required EdgeInsets margin,
    required bool isLive,
  }) {
    return AnimatedScale(
      scale: _isPressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTap: _handleTap,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: Container(
          margin: margin,
          decoration: BoxDecoration(
            color: AppColors.cardBackground, // Fallback color
            borderRadius: BorderRadius.circular(borderRadius),
            // Removed border for cleaner overlay look
            // border: Border.all(
            //   color: Colors.white.withOpacity(0.08),
            //   width: 0.5,
            // ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Stack(
              children: [
                // --- Background Image (Non-Positioned - Defines Stack Size) ---
                _buildOverlayImageBackground(), // AspectRatio defines the size

                // --- Gradient Overlay ---
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.85), // Stronger dark at bottom
                          Colors.black.withOpacity(0.0)    // Fades to transparent
                        ],
                        stops: const [0.0, 0.7], // Gradient covers lower 70%
                      ),
                    ),
                  ),
                ),

                // --- Content Overlay ---
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0), // Consistent padding
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top: Date/Time
                        _buildMetadataRow(
                          Icons.calendar_today_outlined,
                          _formatEventTime(),
                          color: Colors.white.withOpacity(0.9),
                        ),
                        const SizedBox(height: 12), // sm spacing

                        // Middle: Club Info & Title (pushes button down)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end, // Align to bottom before button
                            children: [
                              _buildMetadataRow(
                                Icons.sports_esports_outlined, // Placeholder pawn icon
                                widget.event.organizerName,
                                color: Colors.white.withOpacity(0.8),
                              ),
                              const SizedBox(height: 8), // xs spacing
                              Text(
                                widget.event.title,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 28, // H2 size
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary, // White
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Bottom: RSVP Button
                        const SizedBox(height: 16), // Add space above button
                        _buildOverlayRsvpButton(),
                      ],
                    ),
                  ),
                ),

                // "LIVE NOW" Pill (if applicable)
                if (isLive)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'LIVE NOW',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
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

  // Builds just the background image for the overlay style
  Widget _buildOverlayImageBackground() {
    // Use AspectRatio for consistent card images
    return AspectRatio(
      aspectRatio: 16 / 9, // Standard content ratio for web/mobile
      child: Container(
        color: AppColors.grey900, // Background if image fails
        child: OptimizedImage(
          imageUrl: widget.event.imageUrl,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  // Builds the dark RSVP button for the overlay style
  Widget _buildOverlayRsvpButton() {
    final bool isRsvped = _isRsvped; // Use local state

    // Style matches the image provided (Dark bg, White fg)
    final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.black.withOpacity(0.5), // Dark semi-transparent
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), // Pill shape
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // Slightly more padding
      minimumSize: const Size(0, 36), // HIVE standard height
      side: BorderSide(color: Colors.white.withOpacity(0.3), width: 1), // Subtle border
    );

    final Widget buttonChild = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isRsvped ? Icons.check_rounded : Icons.add_rounded,
          size: 16,
          color: Colors.white,
        ),
        const SizedBox(width: 6),
        Text(
          isRsvped ? 'GOING' : 'RSVP',
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ],
    );

    // Use simple ElevatedButton for this specific style
    return ElevatedButton(
      onPressed: _handleRsvp,
      style: buttonStyle,
      child: buttonChild,
    );
  }

  // Updated: _buildMetadataRow to accept color
  Widget _buildMetadataRow(IconData icon, String text, {Color? color}) {
    final textColor = color ?? AppColors.textSecondary;
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: textColor.withOpacity(0.8), // Slightly muted icon
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
            maxLines: 1, // Ensure single line for metadata
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Keep: _formatEventTime
  String _formatEventTime() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final eventDay = DateTime(widget.event.startDate.year, widget.event.startDate.month, widget.event.startDate.day);
    
    String dayString;
    if (eventDay == today) {
      dayString = 'Today';
    } else if (eventDay == tomorrow) {
      dayString = 'Tomorrow';
    } else {
      dayString = DateFormat('E, MMM d').format(widget.event.startDate);
    }
    
    final timeString = DateFormat('h:mm a').format(widget.event.startDate);
    return '$dayString at $timeString';
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
