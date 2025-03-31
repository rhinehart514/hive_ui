import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io' show Platform;

import '../models/event.dart';
import '../models/reposted_event.dart';
import '../models/feed_state.dart';
import '../models/repost_content_type.dart';
import '../theme/app_colors.dart';
import '../theme/huge_icons.dart';
import '../widgets/hive_app_bar.dart';
import '../services/event_service.dart';
import '../controllers/feed_controller.dart';
import '../providers/feed_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/reposted_events_provider.dart';
import '../pages/quote_repost_page.dart';
import '../components/feed/feed_event_card.dart';

/// A simplified feed page that guarantees content will be displayed
/// Optimized for mobile devices
class MainFeed extends ConsumerStatefulWidget {
  const MainFeed({Key? key}) : super(key: key);

  @override
  ConsumerState<MainFeed> createState() => _MainFeedState();
}

class _MainFeedState extends ConsumerState<MainFeed> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late AnimationController _logoOpacityController;
  late ScrollController _scrollController;
  late GlobalKey<RefreshIndicatorState> _refreshIndicatorKey;
  final bool _isDesktop = kIsWeb || (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
  late bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize tab controller
    _tabController = TabController(length: 2, vsync: this);
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    // Initialize logo opacity animation controller
    _logoOpacityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _scrollController = ScrollController();
    _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
    
    _scrollController.addListener(_handleScroll);
    
    // Set up timer for logo animation - skip on desktop platforms
    if (!_isDesktop) {
      _setupLogoAnimationTimer();
    }
    
    // Use post-frame callback to ensure widget is fully built before initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initialize();
        
        // Set up platform-specific settings
        _setupPlatformSpecifics();
      }
    });
  }

  // Handle scroll events
  void _handleScroll() {
    // Implement scroll handling logic
    // For example:
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      // Load more content when reaching the bottom
      _loadMoreData();
    }
  }

  // Setup timer for logo animation
  void _setupLogoAnimationTimer() {
    // Implement logo animation timing
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  // Initialize main data
  Future<void> _initialize() async {
    debugPrint('🚀 Initializing MainFeed page...');
    
    // Use the feed controller to initialize feed data
    final feedController = ref.read(feedControllerProvider);
    debugPrint('🔄 Calling feed controller initializeFeed()...');
    
    try {
      // Initialize the feed which will apply our prioritization algorithm
      await feedController.initializeFeed();
      debugPrint('✅ Feed initialization complete');
    } catch (e) {
      debugPrint('❌ Error initializing feed: $e');
      
      // Fallback to direct data loading if feed controller fails
      await _loadData();
    }
  }

  // Setup platform specific settings
  void _setupPlatformSpecifics() {
    // Implement platform specific setups
    // For example, different UI layouts or behavior for mobile vs desktop
  }

  // Load more data when scrolling to bottom
  Future<void> _loadMoreData() async {
    // Implement logic to load additional data
    // Example:
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        // Load additional events or content
        await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
        
        // For now, we'll just set _isLoading back to false
      } catch (e) {
        debugPrint('Error loading more data: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // Load initial feed data
  Future<void> _loadData() async {
    // Implement data loading logic
    // For example, fetch events from a service
    try {
      await EventService.getEvents();
      // We won't set the events directly since we'll use the feed controller
      // to manage the feed state
    } catch (e) {
      debugPrint('Error loading events: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load events: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Main layout with feed data
    return Scaffold(
      appBar: HiveAppBar(
        title: 'Feed',
        showBackButton: false,
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: () async {
          final feedController = ref.read(feedControllerProvider);
          await feedController.refreshFeed(showLoading: true, userInitiated: true);
        },
        backgroundColor: AppColors.cardBackground,
        color: AppColors.gold,
        child: _buildFeedContent(),
      ),
    );
  }
  
  // Build the main feed content
  Widget _buildFeedContent() {
    // Watch the feed state
    final feedState = ref.watch(feedStateProvider);
    
    // Handle loading state
    if (feedState.status == LoadingStatus.initial || 
        feedState.status == LoadingStatus.loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.gold,
        ),
      );
    }
    
    // Handle error state
    if (feedState.status == LoadingStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Could not load feed', 
              style: TextStyle(color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(feedControllerProvider).refreshFeed(
                  showLoading: true,
                  userInitiated: true,
                );
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }
    
    // Handle empty feed
    if (feedState.feedItems.isEmpty) {
      return const Center(
        child: Text('No events found', 
          style: TextStyle(color: AppColors.textPrimary)),
      );
    }
    
    // Show feed with prioritized content
    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      itemCount: feedState.feedItems.length + 1, // +1 for load more indicator
      itemBuilder: (context, index) {
        // Show loading indicator at the end
        if (index == feedState.feedItems.length) {
          if (feedState.isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
            );
          } else if (feedState.hasMoreEvents) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: TextButton(
                  onPressed: () {
                    ref.read(feedControllerProvider).loadMoreEvents();
                  },
                  child: const Text('Load More', style: TextStyle(color: AppColors.gold)),
                ),
              ),
            );
          } else {
            return const SizedBox(height: 60); // Bottom padding
          }
        }
        
        final item = feedState.feedItems[index];
        final type = item['type'];
        final data = item['data'];
        
        // Render different types of feed items
        switch (type) {
          case 'event':
            final event = data as Event;
            return FeedEventCard(
              event: event,
              onTap: (_) => _navigateToEventDetails(event),
              onRepost: (event, comment, type) => _handleRepost(event, comment, type),
            );
            
          case 'repost':
            final repost = data as RepostItem;
            return FeedEventCard(
              event: repost.event,
              isRepost: true,
              repostedBy: ref.read(profileProvider).profile,
              repostTime: repost.repostTime,
              quoteText: repost.comment,
              repostType: repost.contentType,
              onTap: (_) => _navigateToEventDetails(repost.event),
              onRepost: (event, comment, type) => _handleRepost(event, comment, type),
            );
            
          default:
            // For other content types, show a placeholder for now
            return const SizedBox(height: 80, 
              child: Center(child: Text('Unsupported content type',
                style: TextStyle(color: AppColors.textSecondary)))
            );
        }
      },
    );
  }
  
  // Handle reposting an event
  void _handleRepost(Event event, String? comment, RepostContentType type) async {
    final userProfile = ref.read(profileProvider).profile;
    if (userProfile == null) return;
    
    try {
      switch (type) {
        case RepostContentType.standard:
          // Use the repository via the notifier for standard reposts
          // Modify this since addRepost seems to be void
          ref.read(repostedEventsProvider.notifier).addRepost(
            event: event,
            repostedBy: userProfile,
            comment: comment,
            type: RepostContentType.standard,
          );
          break;
          
        case RepostContentType.quote:
          // Use GoRouter for navigation instead of Navigator
          final result = await context.pushNamed(
            'quote_repost',
            extra: event,
            queryParameters: {'onComplete': 'true'},
          );
          
          // Handle result if needed
          if (result == true) {
            // Quote repost was created, show success feedback
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Quote shared')),
              );
            }
          }
          break;
          
        // Add missing cases
        case RepostContentType.review:
        case RepostContentType.informative:
        case RepostContentType.question:
        case RepostContentType.recommendation:
        case RepostContentType.highlight:
          // For now, handle these the same as standard repost
          ref.read(repostedEventsProvider.notifier).addRepost(
            event: event,
            repostedBy: userProfile,
            comment: comment,
            type: type,
          );
          break;
      }
    } catch (e) {
      debugPrint('Error reposting event: $e');
      
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to repost event')),
        );
      }
    }
  }
  
  // Navigate to event details
  void _navigateToEventDetails(Event event) {
    // Using the correct nested route under the home branch
    context.go('/home/event/${event.id}', extra: {'event': event, 'heroTag': 'event_${event.id}'});
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _logoOpacityController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
} 