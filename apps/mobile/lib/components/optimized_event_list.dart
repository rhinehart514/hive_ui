import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter/services.dart';
import 'event_card/event_card.dart';
import '../models/event.dart';
import '../models/feed_state.dart';
import '../providers/feed_provider.dart';
import '../providers/profile_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../pages/event_details_page.dart';
import '../models/user_profile.dart';
import '../models/repost_content_type.dart';

/// A high-performance event list component that efficiently renders events
/// using virtualization and implements infinite scrolling
class OptimizedEventList extends ConsumerStatefulWidget {
  /// Events to display
  final List<Event> events;

  /// Optional title for the section
  final String? sectionTitle;

  /// Whether to show section dividers between events
  final bool showDividers;

  /// Padding around the list
  final EdgeInsets padding;

  /// Whether this list should handle pagination/infinite scrolling
  final bool enablePagination;

  /// Empty state message when there are no events
  final String emptyStateMessage;

  /// Empty state icon when there are no events
  final IconData emptyStateIcon;

  /// Optional callback for when an event is tapped
  final Function(Event)? onEventTap;

  /// Optional callback for when an event is RSVP'd to
  final Function(Event, bool)? onEventRSVP;

  /// Optional key for identifying this list
  final Key? scrollKey;

  /// Constructor
  const OptimizedEventList({
    Key? key,
    required this.events,
    this.sectionTitle,
    this.showDividers = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.enablePagination = false,
    this.emptyStateMessage = 'No events to display',
    this.emptyStateIcon = Icons.event_busy,
    this.onEventTap,
    this.onEventRSVP,
    this.scrollKey,
  }) : super(key: key);

  @override
  ConsumerState<OptimizedEventList> createState() => _OptimizedEventListState();
}

class _OptimizedEventListState extends ConsumerState<OptimizedEventList> {
  // Scroll controller for pagination
  final ScrollController _scrollController = ScrollController();

  // Track if we're showing the scroll-to-top button
  bool _showScrollToTop = false;

  // Track visible event indices for analytics

  @override
  void initState() {
    super.initState();

    // Setup scroll listener for pagination and scroll-to-top button
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Handle scroll events for pagination and visibility tracking
  void _handleScroll() {
    // Show/hide scroll-to-top button based on scroll position
    final showButton = _scrollController.offset > 300;
    if (showButton != _showScrollToTop) {
      setState(() {
        _showScrollToTop = showButton;
      });
    }

    // Handle pagination (infinite scrolling) when near the bottom
    if (widget.enablePagination &&
        _scrollController.position.pixels >
            _scrollController.position.maxScrollExtent - 500) {
      ref.read(feedStateProvider.notifier).loadMoreEvents();
    }
  }

  /// Scroll to the top of the list with animation
  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedStateProvider);
    final isLoading = feedState.status == LoadingStatus.loading ||
        feedState.status == LoadingStatus.refreshing;
    final isPaginating = widget.enablePagination &&
        feedState.pagination.currentPage > 1 &&
        feedState.status == LoadingStatus.refreshing;

    // If no events and not in a loading state, show empty state
    if (widget.events.isEmpty && !isLoading) {
      return _buildEmptyState();
    }

    return Stack(
      children: [
        // Main event list
        AnimationLimiter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Optional section title
              if (widget.sectionTitle != null) ...[
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    widget.padding.left,
                    0,
                    widget.padding.right,
                    12,
                  ),
                  child: Row(
                    children: [
                      Text(
                        widget.sectionTitle!,
                        style: AppTheme.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${widget.events.length})',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppColors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Main list of events
              Expanded(
                child: ListView.builder(
                  key: widget.scrollKey,
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: widget.padding,
                  itemCount: widget.events.length + (isPaginating ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Show loading indicator at the end during pagination
                    if (isPaginating && index == widget.events.length) {
                      return _buildPaginationLoader();
                    }

                    // Get event for this index
                    final event = widget.events[index];

                    // Wrap in visibility detector for analytics
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: _buildEventCard(event),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Scroll-to-top button
        if (_showScrollToTop)
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              heroTag: 'event_list_scroll_top_fab',
              mini: true,
              backgroundColor: AppColors.gold.withOpacity(0.8),
              onPressed: () {
                HapticFeedback.lightImpact();
                _scrollToTop();
              },
              child: const Icon(
                Icons.keyboard_arrow_up,
                color: AppColors.black,
              ),
            ),
          ),
      ],
    );
  }

  /// Build a loading indicator for pagination
  Widget _buildPaginationLoader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
        strokeWidth: 2,
      ),
    );
  }

  /// Build an optimized event card
  Widget _buildEventCard(Event event) {
    // Check if user follows the club (you'd normally get this from a provider)
    final userProfile = ref.watch(profileProvider).profile;
    final bool followsClub = _userFollowsClub(userProfile, event);
    
    // Check if user has already boosted this event today
    final todayBoosts = _getTodayBoosts(event.id);
    
    return HiveEventCard(
      event: event,
      onTap: (event) => _navigateToEventDetail(event),
      onRsvp: (event) {
        HapticFeedback.mediumImpact();
        ref.read(profileProvider.notifier).saveEvent(event);
      },
      onRepost: (event, comment, type) {
        // Handle repost action
        _handleRepost(event, comment, type);
      },
      followsClub: followsClub,
      todayBoosts: todayBoosts,
    );
  }
  
  // Helper to check if user follows a club
  bool _userFollowsClub(UserProfile? profile, Event event) {
    if (profile == null) return false;
    if (event.source != EventSource.club) return false;
    if (event.createdBy == null) return false;
    
    // In a real implementation, this would check from the profile's followed clubs list
    // For now, we'll return a default value
    return false;
  }

  // Helper to get today's boosts for an event
  List<DateTime> _getTodayBoosts(String eventId) {
    // This would normally come from a provider or service
    // For now, we'll return an empty list 
    return [];
  }
  
  // Handle repost action
  void _handleRepost(Event event, String? comment, RepostContentType type) {
    // In a real implementation, this would actually repost the event
    // For now, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${event.title} reposted'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _navigateToEventDetail(Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailsPage(
          eventId: event.id,
          event: event,
        ),
      ),
    );
  }

  /// Build an empty state when there are no events
  Widget _buildEmptyState() {
    return Padding(
      padding: widget.padding,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.emptyStateIcon,
              color: AppColors.white.withOpacity(0.5),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              widget.emptyStateMessage,
              style: AppTheme.bodyLarge.copyWith(
                color: AppColors.white.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
