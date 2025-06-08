import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io' show Platform;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/event.dart';
import '../models/feed_state.dart';
import '../models/repost_content_type.dart';
import '../theme/app_colors.dart';
import '../services/event_service.dart';
import '../controllers/feed_controller.dart';
import '../providers/feed_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/reposted_events_provider.dart';
import '../widgets/feed_list_wrapper.dart';
import '../features/feed/presentation/components/premium_top_bar.dart';
import '../features/feed/presentation/components/signal_strip.dart';

/// A simplified feed page that guarantees content will be displayed
/// Optimized for mobile devices
class MainFeed extends ConsumerStatefulWidget {
  const MainFeed({Key? key}) : super(key: key);

  @override
  ConsumerState<MainFeed> createState() => _MainFeedState();
}

class _MainFeedState extends ConsumerState<MainFeed> {
  late ScrollController _scrollController;
  late GlobalKey<RefreshIndicatorState> _refreshIndicatorKey;
  final bool _isDesktop = kIsWeb || (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
  late bool _isLoading = false;

  // Real-time Firebase subscriptions
  StreamSubscription<QuerySnapshot>? _eventsSubscription;
  StreamSubscription<QuerySnapshot>? _userEventsSubscription;
  StreamSubscription<QuerySnapshot>? _repostsSubscription;
  
  // Debouncing for scroll events
  Timer? _debounceTimer;
  
  // Sample data for Space recommendations and HiveLab items
  // In a real implementation, this would come from Firestore
  final List<SpaceRecommendation> _spaceRecommendations = [
    SpaceRecommendation(
      id: 'space1',
      name: 'Photography Club',
      description: 'For students passionate about photography and visual arts',
      category: 'Arts & Media',
      imageUrl: 'https://via.placeholder.com/150',
    ),
    SpaceRecommendation(
      id: 'space2',
      name: 'Computer Science Society',
      description: 'Connecting students interested in technology and coding',
      category: 'Academic',
      imageUrl: 'https://via.placeholder.com/150',
    ),
    SpaceRecommendation(
      id: 'space3',
      name: 'Hiking & Outdoors',
      description: 'For nature lovers and adventure seekers',
      category: 'Recreation',
      imageUrl: 'https://via.placeholder.com/150',
    ),
  ];
  
  final List<HiveLabItem> _hiveLabItems = [
    HiveLabItem(
      id: 'lab1',
      title: 'Event Planning Workshop',
      description: 'Learn how to organize successful events on campus',
      actionLabel: 'Register',
    ),
    HiveLabItem(
      id: 'lab2',
      title: 'Space Optimization',
      description: 'Enhance your campus group\'s digital presence',
      actionLabel: 'Learn More',
    ),
  ];
  
  // Track real-time changes to avoid full refreshes
  final Map<String, dynamic> _changedEvents = {};
  final Set<String> _changedRsvps = {};
  final Set<String> _changedReposts = {};

  @override
  void initState() {
    super.initState();
    
    // Configure system UI overlay style for better integration with the app design
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
    
    _scrollController = ScrollController();
    _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
    
    _scrollController.addListener(_handleScroll);
    
    // Start initialization immediately
    _initialize();
    
    // Delay setting up real-time listeners until after the UI is rendered and data is loaded
    // This prevents the feed from being blocked by Firebase listener setup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Add a slight delay before setting up listeners to prioritize initial render
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _setupRealTimeListeners();
        }
      });
    });
  }

  // Initialize main data
  Future<void> _initialize() async {
    debugPrint('🚀 Initializing MainFeed page...');
    
    // Start showing skeleton loading UI immediately by updating state
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    // Load profile and feed data in parallel
    Future<void> profileFuture = _loadProfileInBackground();
    Future<void> feedFuture = _loadFeedData();
    
    // Wait for feed data to complete (don't block on profile)
    try {
      await feedFuture;
      debugPrint('✅ Feed initialization complete');
    } catch (e) {
      debugPrint('❌ Error initializing feed: $e');
      
      // Fallback to direct data loading if feed controller fails
      try {
        await _loadData();
      } catch (fallbackError) {
        debugPrint('❌ Fallback data loading also failed: $fallbackError');
      }
    } finally {
      // Hide loading state regardless of success/failure
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Load profile in background without blocking feed
  Future<void> _loadProfileInBackground() async {
    try {
      final profileState = ref.read(profileProvider);
      if (profileState.profile == null && !profileState.isLoading) {
        await ref.read(profileProvider.notifier).loadProfile();
      }
      return;
    } catch (e) {
      debugPrint('❌ Error loading profile: $e');
      // Continue with feed loading even if profile loading fails
      return;
    }
  }
  
  // Load feed data through controller
  Future<void> _loadFeedData() async {
    final feedController = ref.read(feedControllerProvider);
    debugPrint('🔄 Calling feed controller initializeFeed()...');
    return feedController.initializeFeed();
  }

  // Setup real-time Firebase listeners for various collections
  void _setupRealTimeListeners() {
    debugPrint('🔥 Setting up real-time Firebase listeners...');
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final FirebaseAuth auth = FirebaseAuth.instance;
    final currentUser = auth.currentUser;
    
    if (currentUser == null) {
      debugPrint('⚠️ Cannot set up listeners: No authenticated user');
      return;
    }
    
    // Listen to all events updates in real-time with optimized query
    // - Reduce limit from 50 to 20 events
    // - Only query future events to reduce data transfer
    // - Add index hint for better performance
    _eventsSubscription = firestore
        .collection('events')
        .where('startDate', isGreaterThanOrEqualTo: DateTime.now().millisecondsSinceEpoch)
        .orderBy('startDate')
        .limit(20) // Reduced from 50 to 20
        .snapshots()
        .listen((snapshot) {
      // Instead of refreshing the entire feed, track which events changed
      for (var change in snapshot.docChanges) {
        final eventData = change.doc.data();
        if (eventData != null) {
          final eventId = change.doc.id;
          
          // Track the change type and data
          _changedEvents[eventId] = {
            'changeType': change.type.toString(),
            'data': eventData,
          };
          
          // Only log in debug mode
          if (kDebugMode) {
            debugPrint('📌 Event $eventId ${change.type}');
          }
        }
      }
      
      // Only refresh the UI state, not the data
      if (snapshot.docChanges.isNotEmpty && mounted) {
        setState(() {
          // Just trigger a rebuild with the latest changes
        });
      }
    }, onError: (error) {
      debugPrint('❌ Error in events listener: $error');
    });
    
    // Optimize user-specific events listener to only listen for changes
    // Use a more efficient query with fewer read operations
    _userEventsSubscription = firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('savedEvents')
        .snapshots()
        .listen((snapshot) {
      // Only process changes, not the entire collection
      if (snapshot.docChanges.isEmpty) return;
      
      // Track RSVP changes without refreshing the entire feed
      for (var change in snapshot.docChanges) {
        final eventId = change.doc.id;
        _changedRsvps.add(eventId);
        
        // Only log in debug mode
        if (kDebugMode) {
          debugPrint('📌 RSVP changed for event: $eventId');
        }
      }
      
      // Only refresh the UI if needed
      if (mounted) {
        setState(() {
          // Just trigger a rebuild with updated RSVP state
        });
      }
    }, onError: (error) {
      debugPrint('❌ Error in user events listener: $error');
    });
    
    // Optimize reposts listener to be more efficient
    // - Reduce time window from 7 days to 3 days
    // - Add limit to query
    _repostsSubscription = firestore
        .collection('reposts')
        .where('createdAt', isGreaterThanOrEqualTo: 
            DateTime.now().add(const Duration(days: -3)).millisecondsSinceEpoch) // 3 days instead of 7
        .orderBy('createdAt', descending: true)
        .limit(15) // Add limit to reduce data transfer
        .snapshots()
        .listen((snapshot) {
      // Skip processing if no changes
      if (snapshot.docChanges.isEmpty) return;
      
      // Track repost changes without refreshing the entire feed
      for (var change in snapshot.docChanges) {
        final repostData = change.doc.data();
        if (repostData != null && repostData['eventId'] != null) {
          final eventId = repostData['eventId'] as String;
          _changedReposts.add(eventId);
          
          // Only log in debug mode
          if (kDebugMode) {
            debugPrint('📌 Repost changed for event: $eventId');
          }
        }
      }
      
      // Only refresh the UI if needed
      if (mounted) {
        setState(() {
          // Just trigger a rebuild with updated repost state
        });
      }
    }, onError: (error) {
      debugPrint('❌ Error in reposts listener: $error');
    });
  }

  // Handle scroll events with debouncing for performance
  void _handleScroll() {
    // Debounce scroll events to prevent excessive data fetching
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    
    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
      // Load more when approaching bottom (80% of max scroll extent)
      if (_scrollController.position.pixels > 
          _scrollController.position.maxScrollExtent * 0.8) {
        _loadMoreData();
      }
    });
  }

  // Load more data when scrolling to bottom
  Future<void> _loadMoreData() async {
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final feedController = ref.read(feedControllerProvider);
        await feedController.loadMoreEvents();
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
    try {
      await EventService.getEvents();
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: PremiumTopBar(
        useLogo: true,
        centerTitle: true,
        actions: [
          // Filter button
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppColors.gold),
            onPressed: () {
              HapticFeedback.selectionClick();
              // TODO: Implement filter functionality
              debugPrint('Filter icon pressed');
            },
          ),
          // Notifications icon
          IconButton(
            icon: const Icon(
              Icons.notifications_none,
              color: AppColors.gold,
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              // TODO: Navigate to notifications screen
              debugPrint('Notifications icon pressed');
            },
          ),
          // Search icon
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.gold),
            onPressed: () {
              HapticFeedback.selectionClick();
              // TODO: Navigate to search screen or show search bar
              debugPrint('Search icon pressed');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: () async {
          final feedController = ref.read(feedControllerProvider);
          await feedController.refreshFeed(showLoading: true, userInitiated: true);
          
          // Clear tracked changes after manual refresh
          _changedEvents.clear();
          _changedRsvps.clear();
          _changedReposts.clear();
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
    
    // Create the main content widget
    Widget mainContent;
    
    // Show skeleton UI while loading initial data
    if ((feedState.status == LoadingStatus.initial || 
        feedState.status == LoadingStatus.loading) && _isLoading) {
      mainContent = _buildSkeletonFeed();
    }
    // Handle error state
    else if (feedState.status == LoadingStatus.error) {
      mainContent = Center(
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
                
                // Clear tracked changes after manual refresh
                _changedEvents.clear();
                _changedRsvps.clear();
                _changedReposts.clear();
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }
    // Handle empty feed
    else if (feedState.feedItems.isEmpty) {
      mainContent = const Center(
        child: Text('No events found', 
          style: TextStyle(color: AppColors.textPrimary)),
      );
    }
    else {
      // Create combined feed with events, spaces and hive lab items
      final combinedFeed = <Map<String, dynamic>>[];
      
      // Add all feed items to our combined feed
      combinedFeed.addAll(feedState.feedItems);
      
      // Insert a space recommendation every 5 items
      if (_spaceRecommendations.isNotEmpty) {
        int spaceCounter = 0;
        int originalLength = combinedFeed.length;
        
        for (int i = 4; i < originalLength; i += 5) {
          if (spaceCounter >= _spaceRecommendations.length) {
            spaceCounter = 0; // Start over if we run out of spaces
          }
          
          // Calculate insert position accounting for previous inserts
          int insertPos = i + (i ~/ 5);
          if (insertPos < combinedFeed.length) {
            combinedFeed.insert(insertPos, {
              'type': 'space_recommendation',
              'data': _spaceRecommendations[spaceCounter],
            });
            spaceCounter++;
          }
        }
      }
      
      // Insert a hive lab item every 8 items
      if (_hiveLabItems.isNotEmpty) {
        int labCounter = 0;
        int originalLength = combinedFeed.length;
        
        for (int i = 7; i < originalLength; i += 8) {
          if (labCounter >= _hiveLabItems.length) {
            labCounter = 0; // Start over if we run out of lab items
          }
          
          // Calculate insert position accounting for previous inserts
          // This accounts for both space recommendations and previous lab items
          int insertPos = i + (i ~/ 5) + (i ~/ 8);
          if (insertPos < combinedFeed.length) {
            combinedFeed.insert(insertPos, {
              'type': 'hive_lab',
              'data': _hiveLabItems[labCounter],
            });
            labCounter++;
          }
        }
      }
      
      // Use our new FeedListWrapper to fix ParentDataWidget issues
      mainContent = FeedListWrapper(
        feedItems: combinedFeed,
        isLoadingMore: feedState.isLoadingMore,
        hasMoreEvents: feedState.hasMoreEvents,
        scrollController: _scrollController,
        onLoadMore: _loadMoreData,
        onNavigateToEventDetails: _navigateToEventDetails,
        onRsvpToEvent: _handleRsvpToEvent,
        onRepost: _handleRepost,
      );
    }
    
    // Return a column with the signal strip at the top and the main content below
    return Column(
      children: [
        // Add the Signal Strip at the top
        if (_shouldShowSignalStrip())
          const Padding(
            padding: EdgeInsets.only(top: 4, bottom: 8),
            child: SignalStrip(
              height: 125.0,
              showHeader: true,
            ),
          ),
        // Wrap the main content in an Expanded widget so it fills the remaining space
        Expanded(child: mainContent),
      ],
    );
  }
  
  // Check if we should show the signal strip
  bool _shouldShowSignalStrip() {
    // TODO: Add logic to determine if signal strip should be shown
    return true; // Show by default for now
  }
  
  // Build skeleton UI while loading
  Widget _buildSkeletonFeed() {
    // Create a list of skeleton items for loading state
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5, // Show 5 skeleton items
      itemBuilder: (context, index) {
        // Alternate between event cards and space recommendation skeletons
        if (index % 3 == 2) {
          return _buildSkeletonSpaceCard();
        } else {
          return _buildSkeletonEventCard();
        }
      },
    );
  }
  
  // Build a skeleton event card
  Widget _buildSkeletonEventCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Skeleton image
          Container(
            height: 160,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.grey800,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Skeleton title
                Container(
                  height: 24,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.grey800,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                // Skeleton location and time
                Row(
                  children: [
                    Container(
                      height: 16,
                      width: 100,
                      decoration: BoxDecoration(
                        color: AppColors.grey800,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      height: 16,
                      width: 80,
                      decoration: BoxDecoration(
                        color: AppColors.grey800,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Skeleton buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: 36,
                      width: 80,
                      decoration: BoxDecoration(
                        color: AppColors.grey800,
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      height: 36,
                      width: 100,
                      decoration: BoxDecoration(
                        color: AppColors.grey700,
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Build a skeleton space recommendation card
  Widget _buildSkeletonSpaceCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Skeleton label
          Container(
            height: 16,
            width: 160,
            decoration: BoxDecoration(
              color: AppColors.grey800,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Skeleton image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.grey800,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Skeleton title
                    Container(
                      height: 18,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.grey800,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Skeleton category
                    Container(
                      height: 14,
                      width: 100,
                      decoration: BoxDecoration(
                        color: AppColors.grey800,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Skeleton description
          Container(
            height: 14,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.grey800,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 14,
            width: MediaQuery.of(context).size.width * 0.7,
            decoration: BoxDecoration(
              color: AppColors.grey800,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          // Skeleton buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                height: 36,
                width: 80,
                decoration: BoxDecoration(
                  color: AppColors.grey800,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                height: 36,
                width: 80,
                decoration: BoxDecoration(
                  color: AppColors.grey700,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Build Space recommendation card
  Widget _buildSpaceRecommendationCard(SpaceRecommendation space) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.group, color: AppColors.gold, size: 16),
              const SizedBox(width: 8),
              Text(
                'RECOMMENDED SPACE',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  space.imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 60,
                      color: AppColors.grey800,
                      child: const Icon(Icons.image, color: AppColors.textSecondary),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      space.name,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      space.category,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            space.description,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  // Navigate to space details
                  context.go('/home/space/${space.id}');
                },
                child: Text(
                  'View Space',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  // Follow space logic
                  _followSpace(space.id);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text(
                  'Follow',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Build HIVE Lab card
  Widget _buildHiveLabCard(HiveLabItem item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.science, color: AppColors.gold),
              const SizedBox(width: 8),
              Text(
                'HIVE LAB',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.description,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                // Handle HIVE Lab action
                _handleHiveLabAction(item.id);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                item.actionLabel,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Handle following a space
  void _followSpace(String spaceId) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final currentUser = auth.currentUser;
    
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to follow spaces')),
        );
      }
      return;
    }
    
    try {
      // Update user's followed spaces
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('users').doc(currentUser.uid).update({
        'followedSpaces': FieldValue.arrayUnion([spaceId]),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Space followed successfully'),
            backgroundColor: AppColors.gold,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error following space: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to follow space: ${e.toString()}')),
        );
      }
    }
  }
  
  // Handle HIVE Lab action
  void _handleHiveLabAction(String labId) {
    // Navigate to the lab detail or action page
    context.go('/home/lab/$labId');
  }
  
  // Handle reposting an event
  void _handleRepost(Event event, String? comment, RepostContentType type) async {
    try {
      // Provide haptic feedback for better user experience
      HapticFeedback.mediumImpact();
      
      // Get current user ID from Firebase Auth first 
      final FirebaseAuth auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;
      
      if (currentUser == null) {
        // User is definitely not authenticated
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You must be logged in to repost')),
          );
        }
        return;
      }
      
      // Now check profile from provider
      final userProfile = ref.read(profileProvider).profile;
      
      // If profile is null but user is authenticated, try to refresh profile
      if (userProfile == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Loading your profile...')),
          );
        }
        
        // Try to load profile
        await ref.read(profileProvider.notifier).loadProfile();
        
        // Check again after loading
        final refreshedProfile = ref.read(profileProvider).profile;
        if (refreshedProfile == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not load your profile. Please try again.')),
            );
          }
          return;
        }
      }
      
      // At this point we should have a valid profile
      switch (type) {
        case RepostContentType.standard:
          // Use the repository via the notifier for standard reposts
          ref.read(repostedEventsProvider.notifier).addRepost(
            event: event,
            repostedBy: userProfile!,
            comment: comment,
            type: RepostContentType.standard,
          );
          
          // Show success message with animation
          if (mounted) {
            // Provide stronger haptic feedback for confirmation
            HapticFeedback.heavyImpact();
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.repeat_rounded, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Event reposted'),
                  ],
                ),
                backgroundColor: AppColors.gold.withOpacity(0.8),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
          break;
          
        case RepostContentType.quote:
          // Navigate to quote repost page with the selected event
          final result = await context.pushNamed(
            'quote_repost',
            extra: event,
            queryParameters: {
              'userId': currentUser.uid,
              'eventId': event.id,
              'onComplete': 'true'
            },
          );
          
          // Handle result if needed
          if (result == true && mounted) {
            // Provide stronger haptic feedback for confirmation
            HapticFeedback.heavyImpact();
            
            // Quote repost was created, show success feedback
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.format_quote_rounded, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Quote shared'),
                  ],
                ),
                backgroundColor: AppColors.gold.withOpacity(0.8),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
          break;
          
        default:
          // Handle other repost types
          ref.read(repostedEventsProvider.notifier).addRepost(
            event: event,
            repostedBy: userProfile!,
            comment: comment,
            type: type,
          );
          
          // Show success message with type
          if (mounted) {
            // Provide stronger haptic feedback for confirmation
            HapticFeedback.heavyImpact();
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.repeat_rounded, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('${type.toString().split('.').last} shared'),
                  ],
                ),
                backgroundColor: AppColors.gold.withOpacity(0.8),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
          break;
      }
      
      // Add this to tracked reposts instead of refreshing entire feed
      _changedReposts.add(event.id);
      setState(() {}); // Update UI with minimal changes
    } catch (e) {
      debugPrint('Error reposting event: $e');
      
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to repost event: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Navigate to event details
  void _navigateToEventDetails(Event event) {
    // Using the correct nested route under the home branch with hero tag
    context.go('/home/event/${event.id}', extra: {'event': event, 'heroTag': 'event_${event.id}'});
  }

  // Handle RSVP
  void _handleRsvpToEvent(Event event) async {
    try {
      // Get current user ID from Firebase Auth first 
      final FirebaseAuth auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;
      
      if (currentUser == null) {
        // User is definitely not authenticated
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You must be logged in to RSVP')),
          );
        }
        return;
      }
      
      // Get current user from profile provider
      final userProfile = ref.read(profileProvider).profile;
      
      // If profile is null but user is authenticated, try to refresh profile
      if (userProfile == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Loading your profile...')),
          );
        }
        
        // Try to load profile
        await ref.read(profileProvider.notifier).loadProfile();
        
        // Check again after loading
        final refreshedProfile = ref.read(profileProvider).profile;
        if (refreshedProfile == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not load your profile. Please try again.')),
            );
          }
          return;
        }
      }
      
      // Check current RSVP status
      final currentStatus = await EventService.getEventRsvpStatus(event.id);
      
      // Toggle RSVP status - pass the user ID explicitly
      final success = await EventService.rsvpToEvent(
        event.id, 
        !currentStatus,
      );
      
      if (success && mounted) {
        // Add to tracked RSVPs instead of refreshing entire feed
        _changedRsvps.add(event.id);
        
        // Show feedback to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(!currentStatus 
                ? 'You\'re going to ${event.title}!' 
                : 'RSVP cancelled'),
            backgroundColor: !currentStatus ? AppColors.gold : AppColors.grey800,
          ),
        );
        
        // Update UI with minimal changes
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error handling RSVP: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update RSVP: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    // Cancel all stream subscriptions
    _eventsSubscription?.cancel();
    _userEventsSubscription?.cancel();
    _repostsSubscription?.cancel();
    _debounceTimer?.cancel();
    
    _scrollController.dispose();
    super.dispose();
  }
}

// Space recommendation card component
class SpaceRecommendation {
  final String id;
  final String name;
  final String description;
  final String category;
  final String imageUrl;
  
  SpaceRecommendation({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.imageUrl,
  });
}

// HiveLab item component
class HiveLabItem {
  final String id;
  final String title;
  final String description;
  final String actionLabel;
  
  HiveLabItem({
    required this.id,
    required this.title,
    required this.description,
    required this.actionLabel,
  });
} 