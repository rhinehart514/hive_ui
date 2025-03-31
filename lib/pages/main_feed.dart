import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event.dart';
import '../services/feed/feed_analytics.dart';
import '../services/space_event_manager.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/controllers/feed_controller.dart';
import 'package:hive_ui/features/feed/presentation/widgets/feed_suggested_friends_item.dart';
import 'package:hive_ui/features/feed/presentation/widgets/suggested_space_card.dart';
import 'package:hive_ui/models/feed_state.dart';
import 'package:hive_ui/models/recommended_space.dart';
import 'package:hive_ui/models/repost_content_type.dart';
import 'package:hive_ui/models/space.dart' as space_model;
import 'package:hive_ui/models/space_metrics.dart';
import 'package:hive_ui/providers/feed_provider.dart';
import 'package:hive_ui/providers/profile_provider.dart';
import 'package:hive_ui/providers/reposted_events_provider.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/huge_icons.dart';
import '../components/event_card/event_card.dart';
import '../pages/event_details_page.dart';
import '../core/navigation/app_bar_builder.dart';
import 'package:hive_ui/widgets/hive_app_bar.dart';
import 'package:hive_ui/core/navigation/routes.dart';
import 'package:hive_ui/services/event_service.dart';
import 'package:hive_ui/services/user_preferences_service.dart';
import '../components/event_card/hive_event_card.dart';
import '../components/feed/feed_event_card.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import '../../models/user_profile.dart';
import '../components/hive_lab_card.dart';
import '../models/reposted_event.dart';
import 'package:hive_ui/features/spaces/presentation/providers/user_spaces_providers.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_metrics_entity.dart';
import 'package:hive_ui/features/spaces/utils/model_converters.dart';
import 'package:hive_ui/features/friends/domain/providers/suggested_friends_provider.dart';
import 'package:hive_ui/features/spaces/domain/providers/suggested_spaces_provider.dart';
import 'quote_repost_page.dart';

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
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Color?> _textColorAnimation;
  late AnimationController _logoOpacityController;
  late Animation<double> _logoOpacityAnimation;
  late ScrollController _scrollController;
  late GlobalKey<RefreshIndicatorState> _refreshIndicatorKey;
  late List<Event> _allEvents = [];
  late List<RecommendedSpace> _recommendedSpaces = [];
  late bool _isDesktop = kIsWeb || (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
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
    
    _logoFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );
    
    _textColorAnimation = ColorTween(
      begin: Colors.white,
      end: AppColors.gold,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );
    
    // Initialize logo opacity animation controller
    _logoOpacityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _logoOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _logoOpacityController,
        curve: Curves.easeInOut,
      ),
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
        
        // Initialize feed-related providers for social features
        _initializeSocialFeatures();
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
        print('Error loading more data: $e');
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
      final events = await EventService.getEvents();
      if (mounted) {
        setState(() {
          _allEvents = events;
        });
      }
    } catch (e) {
      print('Error loading events: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load events: $e')),
        );
      }
    }
  }
  
  // Initialize social features for the feed
  void _initializeSocialFeatures() {
    final userProfile = ref.read(profileProvider).profile;
    if (userProfile != null) {
      // Get the list of users the current user follows
      final followedUserIds = userProfile.followedSpaces;
      
      // Initialize repost listener for feed
      // We'll adapt this since listenToFeedReposts isn't defined
      // Instead of adding a listener directly, we'll just refresh on changes
      ref.listen<List<RepostedEvent>>(repostedEventsProvider, (previous, next) {
        if (mounted) setState(() {});
      });
      
      // Pre-load suggested spaces and friends
      ref.read(suggestedSpacesProvider);
      ref.read(suggestedFriendsProvider);
    }
  }

  // Refresh feed data, including social content
  Future<void> _refreshFeed() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Refresh events
      await _loadData();
      
      // Refresh social features
      final userProfile = ref.read(profileProvider).profile;
      if (userProfile != null) {
        // Refresh suggested spaces
        await ref.refresh(suggestedSpacesProvider.future);
        
        // Refresh suggested friends
        await ref.refresh(suggestedFriendsProvider.future);
        
        // Update recommended spaces from provider
        final suggestedSpaces = ref.read(suggestedSpacesProvider).valueOrNull;
        if (suggestedSpaces != null && suggestedSpaces.isNotEmpty) {
          // Convert SpaceEntity to RecommendedSpace
          setState(() {
            _recommendedSpaces = suggestedSpaces.map((spaceEntity) {
              // Create a Space object first
              final space = space_model.Space(
                id: spaceEntity.id,
                name: spaceEntity.name,
                description: spaceEntity.description ?? '',
                icon: spaceEntity.icon,
                imageUrl: spaceEntity.imageUrl,
                metrics: SpaceMetrics.empty(), // Default metrics
                createdAt: spaceEntity.createdAt,
                updatedAt: spaceEntity.updatedAt,
              );
              
              // Then create RecommendedSpace with the Space object
              return RecommendedSpace(
                space: space,
              );
            }).toList();
          });
        }
      }
      
      // Log analytics event
      try {
        // Implement FeedAnalytics or use a different analytics approach
        print('Feed refreshed by user ${userProfile?.id ?? 'anonymous'}');
      } catch (e) {
        print('Failed to log feed refresh: $e');
      }
    } catch (e) {
      print('Error refreshing feed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to refresh feed')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the feed state from provider
    final feedState = ref.watch(feedStateProvider);
    final userProfile = ref.watch(profileProvider).profile;
    
    return Scaffold(
      appBar: HiveAppBar.fromBuilder(
        AppBarBuilder.feedAppBar(context, ref, onSearch: (query) {
          // Search functionality using the feed controller
          ref.read(feedControllerProvider).searchFeed(query);
        }),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: () async {
            // Refresh using feed controller
            await ref.read(feedControllerProvider).refreshFeed(
              showLoading: true,
              userInitiated: true,
            );
          },
          child: _buildFeedContent(feedState, userProfile),
        ),
      ),
    );
  }
  
  // Build the feed content based on feed state
  Widget _buildFeedContent(FeedState feedState, UserProfile? userProfile) {
    // Handle loading state
    if (feedState.status == LoadingStatus.initial ||
        feedState.status == LoadingStatus.loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    // Handle error state
    if (feedState.status == LoadingStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Could not load feed'),
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
    
    // Handle search results
    if (feedState.isSearchActive) {
      return _buildSearchResults(feedState.searchResults);
    }
    
    // Handle empty state
    if (feedState.feedItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No events found'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(feedControllerProvider).refreshFeed(
                  showLoading: true,
                  userInitiated: true,
                );
              },
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }
    
    // Build feed with interleaved content
    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: feedState.feedItems.length + 1, // +1 for loading indicator
      itemBuilder: (context, index) {
        // Show loading indicator at the end if loading more
        if (index == feedState.feedItems.length) {
          if (feedState.isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          } else if (feedState.hasMoreEvents) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: TextButton(
                  onPressed: () {
                    ref.read(feedControllerProvider).loadMoreEvents();
                  },
                  child: const Text('Load More'),
                ),
              ),
            );
          } else {
            return const SizedBox(height: 60); // Bottom padding
          }
        }
        
        // Display feed item based on type
        final feedItem = feedState.feedItems[index];
        final itemType = feedItem['type'];
        final itemData = feedItem['data'];
        
        // Log the type for debugging
        debugPrint('🔍 Rendering feed item type: $itemType');
        
        // Render different widgets based on item type
        switch (itemType) {
          case 'event':
            return FeedEventCard(
              event: itemData as Event,
              onTap: () => _navigateToEventDetails(itemData),
            );
            
          case 'repost':
            return _buildRepostCard(itemData as RepostItem);
            
          case 'space_recommendation':
            return SuggestedSpaceCard(
              space: itemData as RecommendedSpace,
              onJoin: () => _joinSpace(itemData),
            );
            
          case 'friend_suggestion':
            return FeedSuggestedFriendsItem(
              friend: itemData,
              onConnect: () => _connectWithFriend(itemData),
            );
            
          case 'hive_lab':
            return HiveLabCard(
              title: (itemData as HiveLabItem).title,
              description: itemData.description,
              actionLabel: itemData.actionLabel,
              onAction: () => _openHiveLab(itemData),
            );
            
          case 'inspirational_message':
            return _buildInspirationalMessage(itemData as InspirationalMessage);
            
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }
  
  // Build HiveLab feedback card
  Widget _buildHiveLabFeedbackCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Help improve HIVE',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'We value your feedback. Share your thoughts to help us make HIVE better.',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      // Mark as dismissed in state
                    });
                  },
                  child: const Text(
                    'Dismiss',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to feedback form
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                  ),
                  child: const Text('Give Feedback'),
                ),
              ],
            ),
          ],
        ),
      ),
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
          // Navigate to the quote repost page for quote reposts
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => QuoteRepostPage(event: event),
            ),
          );
          
          // Handle result if needed
          if (result == true) {
            // Quote repost was created, show success feedback
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Quote shared')),
            );
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
      print('Error reposting event: $e');
      
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to repost event')),
      );
    }
  }
  
  // Build a reposted event card
  Widget _buildRepostedEventCard(RepostedEvent repost) {
    // If it's a quote repost, use a different style
    if (repost.repostType == "quote") {
      return _buildQuoteRepostCard(repost);
    }
    
    // Standard repost
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Repost header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Icon(
                HugeIcons.repost,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Reposted by ${repost.repostedBy.displayName}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        
        // The actual event card
        FeedEventCard(
          event: repost.event,
          onTap: (_) => _navigateToEventDetails(repost.event),
          onRepost: (event, comment, type) => _handleRepost(event, comment, type),
        ),
        
        // If there's a comment, show it
        if (repost.comment != null && repost.comment!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              repost.comment!,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
            ),
          ),
      ],
    );
  }
  
  // Build a quote repost card
  Widget _buildQuoteRepostCard(RepostedEvent repost) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.gold.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quote author
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: repost.repostedBy.profileImageUrl != null
                      ? NetworkImage(repost.repostedBy.profileImageUrl!)
                      : null,
                  backgroundColor: AppColors.gold.withOpacity(0.2),
                  child: repost.repostedBy.profileImageUrl == null
                      ? const Icon(Icons.person, color: AppColors.gold)
                      : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      repost.repostedBy.displayName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Quoted this event',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Quote text
          if (repost.comment != null && repost.comment!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                repost.comment!,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          
          // Original event summary
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.gold.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  repost.event.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(repost.event.startDate),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _navigateToEventDetails(repost.event),
                  child: const Text(
                    'View event details',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Format date for display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    if (date.isAfter(today) && date.isBefore(tomorrow)) {
      return 'Today';
    } else if (date.isAfter(tomorrow) && date.isBefore(tomorrow.add(const Duration(days: 1)))) {
      return 'Tomorrow';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
  
  // Navigate to event details
  void _navigateToEventDetails(Event event) {
    context.go('/event-details/${event.id}');
  }
  
  // Determine whether to show HiveLab feedback card
  bool _shouldShowHiveLabCard() {
    // Check user preferences or state
    return true; // Simplified for now
  }
  
  // Handle joining a space
  void _joinSpace(RecommendedSpace space) {
    // Update spaces in database
    final userId = ref.read(profileProvider).profile?.id;
    if (userId == null) return;
    
    try {
      // Convert to SpaceEntity
      final spaceEntity = SpaceEntity(
        id: space.space.id,
        name: space.space.name,
        description: space.space.description,
        iconCodePoint: space.space.icon.codePoint,
        metrics: SpaceMetricsEntity.initial(space.space.id),
        imageUrl: space.space.imageUrl,
        createdAt: space.space.createdAt,
        updatedAt: DateTime.now(),
      );
      
      // Join the space
      ref.read(joinSpaceProvider(space.space.id))();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Joined ${space.space.name}')),
      );
      
      // Refresh suggested spaces
      setState(() {
        _recommendedSpaces.removeWhere((s) => s.space.id == space.space.id);
      });
    } catch (e) {
      print('Error joining space: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to join space')),
      );
    }
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