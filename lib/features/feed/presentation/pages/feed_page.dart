import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ui/widgets/hive_app_bar.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/rendering.dart';

import '../../../../models/event.dart';
import '../../../../models/reposted_event.dart';
import '../../../../models/feed_state.dart';
import '../../../../models/repost_content_type.dart';
import '../../../../models/user_profile.dart';
import '../../../../theme/app_colors.dart';
import '../../../../widgets/hive_app_bar.dart';
import '../../../../services/event_service.dart';
import '../../../../controllers/feed_controller.dart';
import '../../../../providers/feed_provider.dart';
import '../../../../providers/reposted_events_provider.dart';
import '../../../../providers/profile_provider.dart';
import '../../../../utils/auth_utils.dart';
import '../../domain/providers/feed_events_provider.dart';
import '../../domain/providers/feed_optimization_provider.dart';
import '../../domain/providers/space_recommendations_provider.dart';
import '../../../../models/space_recommendation.dart';

import '../widgets/feed_list.dart';
import '../widgets/shimmer_event_card.dart';

/// A optimized feed page that follows clean architecture principles
/// Handles efficient Firebase communication and state management
class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({Key? key}) : super(key: key);

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late GlobalKey<RefreshIndicatorState> _refreshIndicatorKey;
  late ScrollController _scrollController;
  Timer? _scrollDebounceTimer;
  bool _isScrollHandlerPaused = false;
  bool _mounted = true; // Track mounted state

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
    _scrollController = ScrollController();
    _scrollController.addListener(_debouncedScrollHandler);
    
    // Use post-frame callback to ensure widget is fully built before initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initialize();
        
        // Show refresh indicator automatically on first load
        _refreshIndicatorKey.currentState?.show();
      }
    });
  }

  @override
  void dispose() {
    _mounted = false; // Set mounted flag to false
    _tabController.dispose();
    _scrollDebounceTimer?.cancel();
    _scrollController.removeListener(_debouncedScrollHandler);
    _scrollController.dispose();
    super.dispose();
  }

  // Debounced scroll handler to prevent multiple calls during rapid scrolling
  void _debouncedScrollHandler() {
    if (_isScrollHandlerPaused || !_mounted) return;
    
    // Cancel existing timer if it's running
    _scrollDebounceTimer?.cancel();
    
    // Set a new timer for 150ms
    _scrollDebounceTimer = Timer(const Duration(milliseconds: 150), () {
      if (!_mounted) return;
      
      // Only trigger load more when user has scrolled to 80% of the list
      if (_scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent * 0.8) {
        _loadMoreData();
      }
    });
  }

  // Initialize main data with performance optimization
  Future<void> _initialize() async {
    if (!_mounted) return;
    
    debugPrint('🚀 Initializing FeedPage...');
    
    // Set loading state immediately to show user feedback
    if (!_mounted) return;
    ref.read(feedOptimizationProvider.notifier).setInitialLoading(true);
    
    try {
      // Initialize feed events provider
      await ref.read(feedEventsProvider.notifier).initializeFeed();
      
      // Early return if widget is no longer mounted
      if (!_mounted) return;
    } catch (e) {
      debugPrint('❌ Error initializing feed: $e');
      // Handle error state
      if (_mounted) {
        ref.read(feedOptimizationProvider.notifier).setError(e.toString());
      }
    } finally {
      if (_mounted) {
        ref.read(feedOptimizationProvider.notifier).setInitialLoading(false);
      }
    }
  }

  // Load more data when scrolling to bottom - optimized to avoid duplicate loads
  Future<void> _loadMoreData() async {
    if (!_mounted) return;
    
    final optimizationNotifier = ref.read(feedOptimizationProvider.notifier);
    
    // Check if we're already loading more data (with debounce)
    if (optimizationNotifier.canLoadMore()) {
      try {
        // Pause scroll handler to prevent multiple loads
        _isScrollHandlerPaused = true;
        
        // Set loading state locally first before making network request
        optimizationNotifier.setLoadingMore(true);
        
        // Load more events through the feed events provider
        await ref.read(feedEventsProvider.notifier).loadMoreEvents();
      } catch (e) {
        debugPrint('Error loading more data: $e');
      } finally {
        if (_mounted) {
          // Reset loading state and enable scroll handler
          optimizationNotifier.setLoadingMore(false);
          _isScrollHandlerPaused = false;
        }
      }
    }
  }

  // Optimized refresh function
  Future<void> _refreshFeed() async {
    if (!_mounted) return;
    
    debugPrint('🔄 FEED PAGE: Refreshing feed...');
    
    try {
      // Explicitly force refresh to add test events if needed
      await ref.read(feedEventsProvider.notifier).refreshFeed();
      
      // Early return if widget is unmounted during async operation
      if (!_mounted) return;
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feed refreshed'),
          duration: Duration(seconds: 1),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      debugPrint('❌ FEED PAGE: Refresh error: $e');
      
      // Show error message
      if (_mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing feed: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }
  
  // Handle RSVP for events
  Future<void> _handleRsvpClick(Event event) async {
    // Check if user is logged in
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You need to be logged in to RSVP to events'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    try {
      // Determine current RSVP status
      final isCurrentlyRsvpd = event.attendees.contains(currentUser.uid);
      
      // Update RSVP status - this will handle the state update
      await ref.read(feedEventsProvider.notifier).updateRsvpStatus(
        event.id, 
        !isCurrentlyRsvpd,
      );
      
      // Show confirmation to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCurrentlyRsvpd 
                ? 'You\'ve canceled your RSVP for ${event.title}'
                : 'You\'re going to ${event.title}!'
            ),
            backgroundColor: isCurrentlyRsvpd ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error handling RSVP: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating RSVP: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Handle navigation to event details
  void _navigateToEventDetails(Event event) {
    context.push('/event/${event.id}', extra: {'heroTag': 'event_${event.id}'});
  }
  
  // Handle repost of events
  void _handleRepost(Event event, String? comment, RepostContentType type) {
    try {
      // Use AuthUtils to check only for profile
      if (!AuthUtils.requireProfile(context, ref)) {
        return;
      }
      
      final userProfile = ref.read(profileProvider).profile!; // Safe to use ! since we checked profile
      
      // Check if this event is already reposted by the user
      final repostedEvents = ref.read(repostedEventsProvider);
      final hasReposted = repostedEvents.any((repost) => 
        repost.event.id == event.id && 
        repost.repostedBy.id == userProfile.id
      );
      
      if (hasReposted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("You've already reposted this event"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      // Add the repost through the provider
      ref.read(repostedEventsProvider.notifier).addRepost(
        event: event,
        repostedBy: userProfile,
        comment: comment,
        type: type,
      );
      
      // Force a rebuild of the feed to show the updated repost status
      _refreshFeed();
      
      // Invalidate the feed events provider to ensure fresh data
      ref.invalidate(feedEventsProvider);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            type == RepostContentType.quote
                ? 'Event quoted with your comment'
                : 'Event reposted successfully'
          ),
          backgroundColor: AppColors.gold.withOpacity(0.8),
        ),
      );
    } catch (e) {
      debugPrint('Error reposting event: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to repost: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    ref.listen(repostedEventsProvider, (previous, next) {
      if (previous != next && mounted) {
        setState(() {});
      }
    });

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(140),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.black.withOpacity(0.7),
                border: const Border(
                  bottom: BorderSide(
                    color: Colors.white10,
                    width: 0.5,
                  ),
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // Top section with title and actions
                    SizedBox(
                      height: 60,
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          Text(
                            'HIVE',
                            style: GoogleFonts.outfit(
                              color: AppColors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const Spacer(),
                          // Notifications button
                          Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 40),
                              icon: const Icon(
                                Icons.notifications_outlined,
                                color: AppColors.white,
                                size: 24,
                              ),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                // Handle notifications
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Tab bar
                    TabBar(
                      controller: _tabController,
                      indicatorColor: AppColors.yellow,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelColor: AppColors.yellow,
                      unselectedLabelColor: AppColors.white,
                      labelStyle: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                      unselectedLabelStyle: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                      tabs: const [
                        Tab(text: 'DISCOVER'),
                        Tab(text: 'WHAT\'S COMING'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 64.0),
        child: FloatingActionButton(
          heroTag: 'feed_page_fab',
          onPressed: () {
            HapticFeedback.mediumImpact();
            context.push('/post/create');
          },
          backgroundColor: AppColors.gold,
          child: const Icon(
            Icons.add,
            color: AppColors.black,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: TabBarView(
        controller: _tabController,
        children: [
          // DISCOVER Tab
          RefreshIndicator(
            key: _refreshIndicatorKey,
            onRefresh: _refreshFeed,
            backgroundColor: AppColors.cardBackground,
            color: AppColors.gold,
            child: _buildFeedContent(),
          ),
          // WHAT'S COMING Tab
          RefreshIndicator(
            onRefresh: _refreshFeed,
            backgroundColor: AppColors.cardBackground,
            color: AppColors.gold,
            child: _buildUpcomingContent(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildUpcomingContent() {
    // Use select instead of watch to minimize rebuilds
    final feedState = ref.watch(feedEventsProvider);
    final isLoadingMore = ref.watch(feedOptimizationProvider.select((state) => state.isLoadingMore));
    
    // Handle loading state with shimmer effect
    if (feedState.status == LoadingStatus.initial || feedState.status == LoadingStatus.loading) {
      return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        itemCount: 5, // Show 5 shimmer items
        itemBuilder: (context, index) => const ShimmerEventCard(),
      );
    }
    
    // Filter for upcoming events only
    final upcomingEvents = feedState.feedItems.where((item) {
      if (item['type'] == 'event') {
        final event = item['data'] as Event;
        return event.startDate.isAfter(DateTime.now());
      }
      return false;
    }).toList();
    
    // Handle empty state
    if (upcomingEvents.isEmpty) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.event_available_rounded,
                    color: AppColors.gold,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No upcoming events',
                    style: GoogleFonts.inter(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check back soon for new events',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _refreshFeed();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.yellow,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.yellow),
                      ),
                    ),
                    child: const Text('Refresh', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    
    // Use the FeedList component for upcoming events
    return FeedList(
      feedItems: upcomingEvents,
      isLoadingMore: isLoadingMore,
      hasMoreEvents: feedState.hasMoreEvents,
      scrollController: _scrollController,
      onLoadMore: _loadMoreData,
      onNavigateToEventDetails: _navigateToEventDetails,
      onRsvpToEvent: _handleRsvpClick,
      onRepost: _handleRepost,
    );
  }

  // Build the main feed content with memory optimization
  Widget _buildFeedContent() {
    // Use select instead of watch to minimize rebuilds
    final feedState = ref.watch(feedEventsProvider);
    final isLoadingMore = ref.watch(feedOptimizationProvider.select((state) => state.isLoadingMore));
    
    // Handle loading state
    if (feedState.status == LoadingStatus.initial || feedState.status == LoadingStatus.loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }
    
    // Handle error state
    if (feedState.status == LoadingStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Error loading feed',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _refreshFeed,
              child: const Text('Retry', style: TextStyle(color: AppColors.gold)),
            ),
          ],
        ),
      );
    }
    
    // Handle empty state
    if (feedState.feedItems.isEmpty) {
      return const Center(
        child: Text(
          'No items in your feed',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    }
    
    // Use the comprehensive FeedList component with all feed items
    return FeedList(
      feedItems: feedState.feedItems,
      isLoadingMore: isLoadingMore,
      hasMoreEvents: feedState.hasMoreEvents,
      scrollController: _scrollController,
      onLoadMore: _loadMoreData,
      onNavigateToEventDetails: _navigateToEventDetails,
      onRsvpToEvent: _handleRsvpClick,
      onRepost: _handleRepost,
    );
  }
} 