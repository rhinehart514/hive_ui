import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import for HapticFeedback
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:auto_route/auto_route.dart';
import 'package:hive_ui/features/spaces/presentation/providers/space_providers.dart' as space_providers;
import 'package:hive_ui/features/spaces/presentation/providers/spaces_controller.dart';
import 'package:hive_ui/features/spaces/presentation/providers/user_spaces_providers.dart' as user_providers;
import 'package:hive_ui/features/spaces/presentation/providers/spaces_async_providers.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart' as entities;
import 'package:hive_ui/models/space.dart';
import 'package:hive_ui/models/space_type.dart' as model_space_type;
import 'package:hive_ui/models/space_metrics.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/huge_icons.dart';
import 'package:hive_ui/services/analytics_service.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/providers/user_providers.dart';
import 'dart:math';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hive_ui/core/navigation/routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/spaces_search_bar.dart';
import 'package:hive_ui/features/spaces/presentation/providers/space_search_provider.dart';
import 'package:hive_ui/extensions/glassmorphism_extension.dart';
import 'package:hive_ui/theme/glassmorphism_guide.dart';
import 'package:hive_ui/features/events/presentation/pages/create_event_page.dart';
// Import for profileProvider
import 'package:hive_ui/features/spaces/presentation/providers/space_navigation_provider.dart';
import 'package:hive_ui/core/navigation/navigation_service.dart';
import 'package:hive_ui/features/profile/presentation/providers/profile_providers.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/discover_spaces_content.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/my_spaces_content.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/requests_content.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';

// Extension to convert SpaceEntity to Space
extension SpaceEntityExt on entities.SpaceEntity {
  Space toSpace() {
    // Convert domain SpaceType to model SpaceType
    model_space_type.SpaceType convertSpaceType() {
      switch (spaceType) {
        case entities.SpaceType.studentOrg:
          return model_space_type.SpaceType.studentOrg;
        case entities.SpaceType.universityOrg:
          return model_space_type.SpaceType.universityOrg;
        case entities.SpaceType.campusLiving:
          return model_space_type.SpaceType.campusLiving;
        case entities.SpaceType.fraternityAndSorority:
          return model_space_type.SpaceType.fraternityAndSorority;
        case entities.SpaceType.hiveExclusive:
          return model_space_type.SpaceType.hiveExclusive;
        case entities.SpaceType.other:
        default:
          return model_space_type.SpaceType.other;
      }
    }

    return Space(
      id: id,
      name: name,
      description: description,
      icon: IconData(iconCodePoint, fontFamily: 'MaterialIcons'),
      imageUrl: imageUrl,
      bannerUrl: bannerUrl,
      metrics: SpaceMetrics.fromJson({
        'memberCount': metrics.memberCount,
        'engagementScore': metrics.engagementScore,
        'isTrending': metrics.isTrending,
        'spaceId': id,
      }),
      tags: tags,
      isJoined: isJoined,
      isPrivate: isPrivate,
      moderators: moderators,
      admins: admins,
      quickActions: quickActions,
      relatedSpaceIds: relatedSpaceIds,
      createdAt: createdAt,
      updatedAt: updatedAt,
      spaceType: convertSpaceType(),
      eventIds: eventIds,
      hiveExclusive: hiveExclusive,
      customData: customData,
    );
  }
}

// Custom FloatingActionButtonLocation that positions the FAB higher than the standard location
class _CustomFloatingActionButtonLocation extends FloatingActionButtonLocation {
  // Create a singleton instance
  static final _CustomFloatingActionButtonLocation endFloat = _CustomFloatingActionButtonLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // Get the standard end float position
    final standardOffset = FloatingActionButtonLocation.endFloat.getOffset(scaffoldGeometry);
    
    // Return a new offset with the same horizontal position but higher by 80dp to avoid navigation bar
    // This provides better positioning that doesn't interfere with the bottom navigation bar
    return Offset(standardOffset.dx, standardOffset.dy - 80);
  }
}

@RoutePage()
class SpacesPage extends ConsumerStatefulWidget {
  const SpacesPage({super.key});

  @override
  ConsumerState<SpacesPage> createState() => _SpacesPageState();
}

class _SpacesPageState extends ConsumerState<SpacesPage> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final Set<String> _activeFilters = <String>{};
  bool _isSearchExpanded = false;
  bool _isSearching = false;
  bool _isJoiningSpace = false;
  int? _lastMySpacesRefreshTime;
  String _activeCategory = 'All';
  final bool _isRefreshing = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  final int _spacesPerPage = 20;
  
  // Define space categories - condensed to most important for students
  final List<String> _categories = [
    'All',
    'Student Orgs',
    'Greek Life',
    'Campus Living',
    'University',
    'Hive Exclusive',
    'Academics',  // New locked category
    'Circles',    // New locked category
  ];
  
  // Scroll controllers
  final ScrollController _mainScrollController = ScrollController();
  final ScrollController _categoriesScrollController = ScrollController();
  final ScrollController _mySpacesScrollController = ScrollController();

  // Tab controller for explore/my spaces
  TabController? _tabController;

  // New method to build the custom spaces app bar
  PreferredSizeWidget _buildSpacesAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: Size.fromHeight(_isSearchExpanded ? 180 : 140), // Adjust height based on search state
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
                          'Spaces',
                          style: GoogleFonts.outfit(
                            color: AppColors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const Spacer(),
                        // Search icon
                        _isSearchExpanded
                            ? const SizedBox.shrink() // Don't show search button when expanded
                            : IconButton(
                                icon: const Icon(Icons.search, color: AppColors.white),
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _toggleSearchExpanded(true);
                                  });
                                  Future.delayed(const Duration(milliseconds: 100), () {
                                    _searchFocusNode.requestFocus();
                              });
                            },
                          ),
                        if (!_isSearchExpanded) ...[
                          // Messaging button with custom icon
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              // Use NavigationService for consistent navigation
                              NavigationService.goToMessaging(context);
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              margin: const EdgeInsets.only(right: 16),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: const Icon(
                                HugeIcons.message,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Search bar when expanded
                  SpacesSearchBar(
                    onSearch: (query) {
                      setState(() {
                        _toggleSearchExpanded(true);
                        _searchController.text = query;
                      });
                      // Trigger search
                      ref.read(spaceSearchProvider.notifier).search(query);
                    },
                    onClear: () {
                      setState(() {
                        _toggleSearchExpanded(false);
                        _searchController.clear();
                      });
                      // Clear search results
                      ref.read(spaceSearchProvider.notifier).clear();
                    },
                  ),

                  // Tab bar
                  Container(
                    height: 48,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white10,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppColors.gold,
                      unselectedLabelColor: AppColors.textTertiary,
                      indicatorColor: AppColors.gold,
                      indicatorWeight: 3,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelStyle: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      tabs: const [
                        Tab(text: 'Explore'),
                        Tab(text: 'My Spaces'),
                        Tab(text: 'Requests'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    
    // Initialize search state in provider
    Future.microtask(() {
      ref.read(spaceSearchActiveProvider.notifier).state = _isSearchExpanded;
    });
    
    // Refresh user data to ensure spaces are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userProvider.notifier).refreshUserData();
      
      // Force refresh of user spaces data
      ref.invalidate(user_providers.userSpacesProvider);
      
      // Debug spaces loading
      final userData = ref.read(userProvider);
      if (userData != null) {
        debugPrint('SpacesPage: User has ${userData.joinedClubs.length} joined spaces: ${userData.joinedClubs}');
      } else {
        debugPrint('SpacesPage: No user data available');
      }
    });
    
    // Set up tab controller
    _tabController = TabController(
      length: 3,
      vsync: this,
    );
    
    // Add listener to handle tab changes
    _tabController!.addListener(_handleTabChange);

    // Setup scroll controllers for pagination
    _mainScrollController.addListener(_scrollListener);
    _mySpacesScrollController.addListener(_mySpacesScrollListener);

    // Load user data directly from Firebase
    _loadUserDataFromFirebase();

    // Log screen view
    AnalyticsService.logScreenView('spaces_page');
  }
  
  // Handle tab changes - close search if expanded
  void _handleTabChange() {
    if (_tabController?.indexIsChanging ?? false) {
      // Close search when switching tabs
      if (_isSearchExpanded) {
        _toggleSearchExpanded(false);
        _searchController.clear();
        
        // Move provider state update to microtask
        Future.microtask(() {
          ref.read(spaceSearchQueryProvider.notifier).state = '';
        });
      }
    }
  }

  // New method to load user data directly from Firebase
  Future<void> _loadUserDataFromFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('⚠️ Cannot load user data: No authenticated user');
      return;
    }

    try {
      debugPrint('🔄 Loading user data directly from Firebase for user ${user.uid}');
      
      // Get the user document from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (!userDoc.exists) {
        debugPrint('⚠️ User document does not exist in Firestore');
        return;
      }
      
      final data = userDoc.data();
      if (data == null) {
        debugPrint('⚠️ User document exists but has no data');
        return;
      }
      
      // Extract joined clubs and followed spaces
      List<String> joinedClubs = [];
      List<String> followedSpaces = [];
      
      if (data['joinedClubs'] is List) {
        joinedClubs = List<String>.from(data['joinedClubs']);
        debugPrint('📊 Found ${joinedClubs.length} joinedClubs in user document: $joinedClubs');
      }
      
      if (data['followedSpaces'] is List) {
        followedSpaces = List<String>.from(data['followedSpaces']);
        debugPrint('📊 Found ${followedSpaces.length} followedSpaces in user document: $followedSpaces');
      }
      
      // Combine both lists for maximum compatibility
      final allSpaceIds = {...joinedClubs, ...followedSpaces}.toList();
      
      if (allSpaceIds.isEmpty) {
        debugPrint('⚠️ User has no joined spaces in either joinedClubs or followedSpaces');
        return;
      }
      
      // Update the userProvider
      final currentUserData = ref.read(userProvider);
      if (currentUserData != null) {
        // Create updated user data with the joined clubs
        UserData updatedUserData = UserData(
          id: user.uid,
          name: user.displayName,
          email: user.email,
          joinedClubs: allSpaceIds,
          attendedEvents: currentUserData.attendedEvents,
          interests: currentUserData.interests,
        );
        
        // Update the provider - Use updateUserData instead of refreshUserData
        ref.read(userProvider.notifier).updateUserData(updatedUserData);
        debugPrint('✅ Updated userProvider with ${updatedUserData.joinedClubs.length} joined clubs');
        
        // Refresh spaces providers
        ref.invalidate(user_providers.userSpacesProvider);
        
        // Also sync from Firebase to local
        final syncUserSpaces = ref.read(user_providers.syncUserSpacesProvider);
        syncUserSpaces();
      }
    } catch (e) {
      debugPrint('❌ Error loading user data from Firebase: $e');
    }
  }

  void _scrollListener() {
    if (!_isLoadingMore &&
        _mainScrollController.position.pixels >=
            _mainScrollController.position.maxScrollExtent * 0.8) {
      _loadMoreSpaces();
    }
  }

  // Scroll listener for My Spaces tab
  void _mySpacesScrollListener() {
    if (!_isLoadingMore &&
        _mySpacesScrollController.position.pixels >=
            _mySpacesScrollController.position.maxScrollExtent * 0.8) {
      // If needed, implement pagination for mySpaces tab
      // For now, we'll just log that scrolling is working
      debugPrint('Scrolled to bottom of My Spaces tab');
    }
  }

  Future<void> _loadMoreSpaces() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      // Load next page of spaces
      _currentPage++;
      await ref
          .read(spacesControllerProvider.notifier)
          .loadMoreSpaces(_currentPage, _spacesPerPage);

      // Small delay to prevent rapid multiple loads if the user is scrolling fast
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      debugPrint('Error loading more spaces: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _mainScrollController.dispose();
    _categoriesScrollController.dispose();
    _mySpacesScrollController.dispose();
    // Safely dispose tab controller
    if (_tabController != null) {
      _tabController!.dispose();
    }
    super.dispose();
  }

  // Handle pull-to-refresh gesture
  Future<void> _refreshSpaces() async {
    try {
      debugPrint('Refreshing spaces data');
      
      // First call our new sync provider to ensure consistency between Firebase and local data
      final syncUserSpaces = ref.read(user_providers.syncUserSpacesProvider);
      await syncUserSpaces();
      debugPrint('User spaces data synchronized');
      
      // Refresh user data through the StateNotifier method
      await ref.read(userProvider.notifier).refreshUserData();
      debugPrint('User data refreshed');
      
      // Then refresh the spaces providers
      await ref.refresh(user_providers.userSpacesProvider.future);
      await ref.refresh(space_providers.hierarchicalSpacesProvider.future);
      await ref.refresh(trendingSpacesProvider.future);
      
      // For debugging: check what spaces we have after refresh
      final userData = ref.read(userProvider);
      debugPrint('After refresh: User has ${userData?.joinedClubs.length ?? 0} joined clubs: ${userData?.joinedClubs}');
      
      // Try to wait for the user spaces to be loaded and print what we got
      Future.delayed(const Duration(seconds: 1), () {
        final spacesAsync = ref.read(user_providers.userSpacesProvider);
        if (spacesAsync is AsyncData<List<entities.SpaceEntity>>) {
          final spaces = spacesAsync.value;
          debugPrint('UserSpacesProvider loaded ${spaces.length} spaces after refresh: ${spaces.map((s) => s.id).toList()}');
        }
      });
      
      setState(() {
        // Reset tab controller to ensure proper refresh
        if (_tabController != null && _tabController!.index == 1) {
          // When on My Spaces tab, store the current timestamp
          _lastMySpacesRefreshTime = DateTime.now().millisecondsSinceEpoch;
        }
      });
    } catch (e) {
      debugPrint('Error refreshing spaces: $e');
    }
  }

  // Handle space joining - REFACORTED to use Controller
  Future<void> _handleJoinSpace(Space space) async {
    if (_isJoiningSpace) return; // Prevent multiple simultaneous joins

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You need to sign in to join spaces'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    setState(() {
      _isJoiningSpace = true;
    });

    try {
      // Delegate joining logic to the controller
      await ref.read(spacesControllerProvider.notifier).joinSpace(space);

      // OPTIONAL: Optimistic UI update (already happens in previous code, keep it)
      final userData = ref.read(userProvider);
      if (userData != null) {
          ref.read(userProvider.notifier).state = userData.joinClub(space.id);
          debugPrint('UI: Updated local user provider state for join');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You\'ve joined ${space.name}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
       // Let the controller handle provider invalidation/refresh if possible.
       // If not, uncomment the line below:
       // ref.invalidate(userSpacesProvider); 

    } catch (e) {
      debugPrint('Error joining space via controller: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join ${space.name}: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isJoiningSpace = false;
        });
      }
    }
  }

  // Show dialog to join or create a space
  void _showJoinSpaceDialog(BuildContext context) {
    HapticFeedback.mediumImpact();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Join or Create a Space',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Would you like to join an existing space or create a new one?',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // Navigate to join space view
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.gold,
                        side: const BorderSide(color: AppColors.gold),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Join',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // Navigate to create space page
                        GoRouter.of(context).push(AppRoutes.getCreateSpacePath());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Create',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Note: The old space creation dialog has been completely replaced with a dedicated page
  // approach that provides a better user experience with more validation and features.

  // Helper to build dropdown items with icons for space types
  DropdownMenuItem<model_space_type.SpaceType> _buildSpaceTypeDropdownItem(
      model_space_type.SpaceType type, String text, IconData icon) {
    return DropdownMenuItem<model_space_type.SpaceType>(
      value: type,
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.gold.withOpacity(0.7),
            size: 18,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.inter(color: Colors.white),
          ),
        ],
      ),
    );
  }

  // Create a new space - removed in favor of the dedicated create space page

  // Handle space tapping
  void _handleTapSpace(Space space) {
    final navigator = ref.read(spaceNavigationProvider);
    navigator.navigateToSpace(
      context,
      spaceId: space.id,
      spaceType: _getSpaceTypeString(space.spaceType),
      space: space,
    );
  }

  String _getSpaceTypeString(model_space_type.SpaceType type) {
    switch (type) {
      case model_space_type.SpaceType.studentOrg:
        return 'student_organizations';
      case model_space_type.SpaceType.universityOrg:
        return 'university_organizations';
      case model_space_type.SpaceType.campusLiving:
        return 'campus_living';
      case model_space_type.SpaceType.fraternityAndSorority:
        return 'fraternity_and_sorority';
      case model_space_type.SpaceType.hiveExclusive:
        return 'hive_exclusive';
      case model_space_type.SpaceType.other:
      default:
        return 'other';
    }
  }

  // Add a wrapper to fix the async data issue in the tab controller
  void _performTabNavigation(int tab) {
    if (_tabController != null) {
      // Check that _tabController is initialized
      _tabController!.animateTo(tab);
    }
  }

  Widget _buildContent() {
    if (_isSearching && _searchController.text.trim().isNotEmpty) {
      return _buildSearchResults();
    }
    
    if (_tabController?.index == 0) {
      return const MySpacesContent();
    } else if (_tabController?.index == 1) {
      return const DiscoverSpacesContent();
    } else {
      return const RequestsContent();
    }
  }
  
  // Simple search results builder
  Widget _buildSearchResults() {
    return Center(
      child: Text(
        'Search results for: ${_searchController.text}',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(profileSyncProvider);
    
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: Column(
        children: [
          _buildAppBar(),
          _buildTabBar(),
          SpacesSearchBar(
            onSearch: (query) {
              setState(() {
                _searchController.text = query;
                _isSearching = query.trim().isNotEmpty;
              });
            },
            onClear: () {
              setState(() {
                _searchController.clear();
                _isSearching = false;
              });
            },
          ),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
      floatingActionButton: _buildCreateSpaceButton(userProfileAsync),
    );
  }

  void _refreshData() {
    // Refresh all the providers we're using
    ref.refresh(space_providers.spacesProvider);
    ref.refresh(space_providers.hierarchicalSpacesProvider);
    ref.refresh(searchedSpacesProvider);
  }

  // Update state provider synchronization for search status
  void _updateSearchStateProvider() {
    final currentState = ref.read(spaceSearchActiveProvider);
    if (currentState != _isSearchExpanded) {
      // Use Future.microtask to update the provider state outside build cycle
      Future.microtask(() {
        ref.read(spaceSearchActiveProvider.notifier).state = _isSearchExpanded;
      });
    }
  }
  
  // Override didUpdateWidget to update provider when local state changes
  @override
  void didUpdateWidget(SpacesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update search state provider directly
    Future.microtask(() {
      if (mounted) {
        ref.read(spaceSearchActiveProvider.notifier).state = _isSearchExpanded;
      }
    });
  }
  
  // Also update in setState where _isSearchExpanded is modified
  void _toggleSearchExpanded(bool expanded) {
    if (_isSearchExpanded != expanded) {
                                      setState(() {
        _isSearchExpanded = expanded;
      });
      
      // Use Future.microtask to update provider outside build cycle
      Future.microtask(() {
        ref.read(spaceSearchActiveProvider.notifier).state = expanded;
        if (!expanded) {
          ref.read(spaceSearchQueryProvider.notifier).state = '';
                                            }
                                          });
                                        }
  }

  // Explore tab view
  Widget _buildExploreTab(AsyncValue<Map<String, List<Space>>> allSpaces) {
    return CustomScrollView(
      controller: _mainScrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Remove category selector from here as it will be moved to the All Spaces header

        // Trending spaces section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: _buildTrendingSpaces(ref.watch(trendingSpacesProvider)),
          ),
        ),

        // Recommended spaces section
        SliverToBoxAdapter(
          child: _buildRecommendedSpaces(allSpaces),
        ),

        // Main spaces grid
        _buildSpacesGrid(allSpaces),
      ],
    );
  }

  // My Spaces tab view
  Widget _buildMySpacesTab(AsyncValue<List<Space>> userSpaces) {
    // Store a reference to the WidgetRef instead of capturing it in the closure
    final weakRef = ref;
    
    // Force a refresh of the userSpacesProvider when this tab is visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only refresh if it's been more than 5 minutes since the last refresh
      final now = DateTime.now().millisecondsSinceEpoch;
      if (_lastMySpacesRefreshTime == null ||
          now - _lastMySpacesRefreshTime! > 5 * 60 * 1000) {
        // We're in the context of a widget that may be unmounted, so use a WeakReference
        final weakRef = ref;
        Future.microtask(() {
          if (mounted) {
            weakRef.invalidate(user_providers.userSpacesProvider);
            _lastMySpacesRefreshTime = now;
          }
        });
      }
    });
    
    // Get current user data to check for spaces
    final userData = ref.watch(userProvider);
    final joinedSpaceIds = userData?.joinedClubs ?? [];
    
    // If user has no spaces in userData but userSpaces is loading, show loading
    if (joinedSpaceIds.isEmpty && userSpaces is AsyncLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }
    
    // If user has spaces in userData but userSpaces provider failed, show direct from userData
    if (joinedSpaceIds.isNotEmpty && userSpaces is AsyncError) {
      debugPrint('UserSpacesProvider error, falling back to direct space lookup for ${joinedSpaceIds.length} spaces');
      // We'll try to load spaces directly from spacesProvider
      final allSpacesAsync = ref.watch(spacesAsyncProvider);
      
      return allSpacesAsync.when(
        data: (allSpaces) {
          // Filter to only show user's joined spaces
          final mySpaces = allSpaces.values
              .where((space) => joinedSpaceIds.contains(space.id))
              .map((entity) => entity.toSpace())
              .toList();
          debugPrint('Fallback method found ${mySpaces.length} spaces from user joinedClubs');
          
          if (mySpaces.isEmpty) {
            return _buildEmptyMySpaces();
          }
          
          // Use SingleChildScrollView with AlwaysScrollableScrollPhysics as a wrapper
          return _buildMySpacesContent(mySpaces);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
        error: (error, stack) => Center(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red[300],
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Unable to load your spaces',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pull down to try again',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: _refreshSpaces,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.gold,
                      side: const BorderSide(color: AppColors.gold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(
                      'Retry',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    
    // Normal flow - use userSpaces provider
    return userSpaces.when(
      data: (spaces) {
        debugPrint('My Spaces tab displaying ${spaces.length} spaces: ${spaces.map((s) => s.id).toList()}');
        if (spaces.isEmpty) {
          return _buildEmptyMySpaces();
        }

        return _buildMySpacesContent(spaces);
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      ),
      error: (error, stackTrace) {
        debugPrint('Error displaying spaces: $error\n$stackTrace');
        return Center(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red[300],
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Unable to load your spaces',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pull down to try again',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: _refreshSpaces,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.gold,
                      side: const BorderSide(color: AppColors.gold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(
                      'Retry',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  // Common builder for My Spaces content
  Widget _buildMySpacesContent(List<Space> spaces) {
    // Get current user ID
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    
    // Fetch all spaces to find those where user is an admin but hasn't joined
    if (currentUserId != null) {
      // Using a direct reference to read all spaces instead of Consumer
      final allSpacesAsync = ref.watch(spacesAsyncProvider);
      
      return allSpacesAsync.when(
        data: (allSpaces) {
          // Find spaces where the user is an admin (leader)
          final adminSpaces = allSpaces.values
              .where((space) => space.admins.contains(currentUserId) && !spaces.any((s) => s.id == space.id))
              .map((entity) => entity.toSpace())
              .toList();
          
          // Combine user's joined spaces with spaces they lead
          final combinedSpaces = [...spaces, ...adminSpaces];
          debugPrint('Showing ${spaces.length} joined spaces and ${adminSpaces.length} admin spaces');
          
          return CustomScrollView(
            controller: _mySpacesScrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index < combinedSpaces.length) {
                        final space = combinedSpaces[index];
                        final isAdminOnly = !spaces.any((s) => s.id == space.id);
                        final isAdmin = isAdminOnly || space.admins.contains(currentUserId);
                        
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 50,
                            child: FadeInAnimation(
                              child: _buildSpaceListItem(
                                space, 
                                index,
                                inMySpaces: true,
                                isAdmin: isAdmin
                              ),
                            ),
                          ),
                        );
                      }
                      return null;
                    },
                    childCount: combinedSpaces.length,
                  ),
                ),
              ),
              // Adding bottom padding to ensure FAB doesn't overlap with the last item
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
        error: (error, stack) => Center(
          child: Text('Error loading spaces: $error'),
        ),
      );
    } else {
      // Fallback for when user isn't authenticated
      return CustomScrollView(
        controller: _mySpacesScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index < spaces.length) {
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        verticalOffset: 50,
                        child: FadeInAnimation(
                          child: _buildSpaceListItem(
                              spaces[index], index,
                              inMySpaces: true),
                        ),
                      ),
                    );
                  }
                  return null;
                },
                childCount: spaces.length,
              ),
            ),
          ),
          // Adding bottom padding to ensure FAB doesn't overlap with the last item
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      );
    }
  }

  // Empty state for My Spaces tab with enhanced design
  Widget _buildEmptyMySpaces() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 180, // Subtract app bar height
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // Add this to prevent overflow
              children: [
                // Styled container with animation
                TweenAnimationBuilder<double>(
                  duration: const Duration(seconds: 2),
                  tween: Tween<double>(begin: 0.5, end: 1.0),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black,
                        border: Border.all(
                          color: AppColors.gold.withOpacity(0.3 + (0.3 * value)),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withOpacity(0.1 + (0.2 * value)),
                            blurRadius: 15 * value,
                            spreadRadius: 2 * value,
                          ),
                        ],
                      ),
                      child: Center(
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedUserGroup03,
                          size: 40,
                          color: AppColors.gold.withOpacity(0.7 + (0.3 * value)),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),
                Text(
                  'No Spaces Yet',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Create your own space to connect with other students or join existing ones to discover events and communities.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                ),
                // "Create a Space" button removed since we now have the FAB
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build category selector with improved design
  Widget _buildCategorySelector() {
    return ListView.builder(
        controller: _categoriesScrollController,
        scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 16, right: 16),
      physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isActive = _activeCategory == category;

        // Assign appropriate HugeIcon based on category
        IconData categoryIcon;
          switch (category) {
            case 'All':
            categoryIcon = HugeIcons.home;
              break;
            case 'Student Orgs':
            categoryIcon = HugeIcons.strokeRoundedUserGroup03;
              break;
            case 'Greek Life':
            categoryIcon = HugeIcons.strokeRoundedAlphabetGreek;
              break;
            case 'Campus Living':
            categoryIcon = HugeIcons.strokeRoundedHouse03;
              break;
            case 'University':
            categoryIcon = HugeIcons.strokeRoundedMortarboard02;
            break;
            case 'Hive Exclusive':
              categoryIcon = Icons.workspace_premium;
              break;
          default:
            categoryIcon = HugeIcons.tag;
              break;
          }

        return GestureDetector(
                  onTap: () {
            HapticFeedback.selectionClick();
                    setState(() {
                      _activeCategory = category;
                    });
            
            // Optional: scroll to make selected category visible in center
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_categoriesScrollController.hasClients) {
                // Calculate the item's approximate position
                final screenWidth = MediaQuery.of(context).size.width;
                const itemWidth = 100; // Approximate average width 
                final offset = index * itemWidth - (screenWidth / 2) + (itemWidth / 2);
                
                // Ensure the offset is within bounds
                final maxScrollExtent = _categoriesScrollController.position.maxScrollExtent;
                final scrollOffset = offset.clamp(0.0, maxScrollExtent);
                
                _categoriesScrollController.animateTo(
                  scrollOffset,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            });

                    // Animate scroll to top when changing categories
                    if (_mainScrollController.hasClients) {
                      _mainScrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                color: isActive
                    ? AppColors.gold
                    : Colors.white.withOpacity(0.15),
                width: isActive ? 1.5 : 1,
              ),
              gradient: isActive
                  ? LinearGradient(
                      colors: [
                        Colors.black,
                        AppColors.gold.withOpacity(0.15),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isActive ? null : Colors.black.withOpacity(0.3),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                        color: AppColors.gold.withOpacity(0.15),
                        blurRadius: 8,
                                spreadRadius: 0,
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
              mainAxisSize: MainAxisSize.min,
                      children: [
                HugeIcon(
                  icon: categoryIcon,
                  size: 14,
                          color: isActive ? AppColors.gold : Colors.white70,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          category,
                          style: GoogleFonts.outfit(
                            color: isActive ? AppColors.gold : Colors.white,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 13,
                          ),
                        ),
                      ],
              ),
            ),
          );
        },
    );
  }

  // Build trending spaces section with new adapter to handle SpaceEntity
  Widget _buildTrendingSpaces(AsyncValue<List<SpaceEntity>> trendingSpacesAsync) {
    return trendingSpacesAsync.when(
      data: (trendingEntities) {
        // Convert SpaceEntity to Space objects
        final List<Space> trendingSpaces = trendingEntities
            .map((entity) => entity.toSpace())
            .toList();
            
        if (trendingSpaces.isEmpty) {
          return const SizedBox.shrink();
        }

        // Filter to only include certain types
        final filteredSpaces = trendingSpaces.where((space) {
          // Only allow StudentOrg and Fraternity/Sorority space types to appear in trending
          return space.spaceType == model_space_type.SpaceType.studentOrg ||
              space.spaceType == model_space_type.SpaceType.fraternityAndSorority;
        }).toList();

        if (filteredSpaces.isEmpty) {
          return const SizedBox.shrink();
        }

        // Sort by engagement score (higher scores first)
        filteredSpaces.sort((a, b) {
          // Use the dedicated engagementScore field
          final aEngagement = a.metrics.engagementScore;
          final bEngagement = b.metrics.engagementScore;
          return bEngagement.compareTo(aEngagement);
        });

        return Container(
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black,
                Colors.grey[900]!.withOpacity(0.3),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.trending_up,
                        size: 16,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Trending Spaces',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        // View all trending spaces
                        HapticFeedback.selectionClick();
                        // Navigate to full trending view or use filter
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.gold,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'See All',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 10,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 20, right: 8),
                  itemCount: filteredSpaces.length,
                  itemBuilder: (context, index) {
                    final space = filteredSpaces[index];
                    // Pass the trending rank (1-based) to show "#X trending"
                    final trendingRank = index < 10 ? index + 1 : null;

                    // Assign different labels based on position and randomness
                    String? specialLabel;
                    Color? labelColor;
                    if (trendingRank == 1) {
                      specialLabel = "#1 Trending";
                      labelColor = AppColors.gold;
                    } else if (trendingRank != null && trendingRank < 4) {
                      specialLabel = "Rising Fast";
                      labelColor = Colors.orange[300];
                    } else if (trendingRank != null &&
                        Random().nextInt(5) == 0) {
                      specialLabel = "Popular";
                      labelColor = Colors.blue[300];
                    }

                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: SizedBox(
                        width: 180,
                        child: AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            horizontalOffset: 50,
                            child: FadeInAnimation(
                              child: _buildMySpaceCard(
                                space,
                                trendingRank: trendingRank,
                                specialLabel: specialLabel,
                                labelColor: labelColor,
                                hasGlowEffect:
                                    index < 3, // Add glow effect to top 3
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
      loading: () => const SizedBox(
        height: 0,
      ),
      error: (_, __) => const SizedBox(
        height: 0,
      ),
    );
  }

  // Build recommended spaces section
  Widget _buildRecommendedSpaces(
      AsyncValue<Map<String, List<Space>>> allSpaces) {
    return allSpaces.when(
      data: (spacesData) {
        // Combine all spaces from different categories
        List<Space> allSpacesList = [];
        spacesData.forEach((key, value) {
          allSpacesList.addAll(value);
        });

        if (allSpacesList.isEmpty) {
          return const SizedBox.shrink();
        }

        // Sort by engagement score (higher scores first)
        allSpacesList.sort((a, b) {
          final aEngagement = a.metrics.engagementScore;
          final bEngagement = b.metrics.engagementScore;
          return bEngagement.compareTo(aEngagement);
        });

        // Get top 10 spaces by engagement score
        final recommendedSpaces =
            allSpacesList.take(min(10, allSpacesList.length)).toList();

        if (recommendedSpaces.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.recommend,
                    size: 18,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Recommended for You',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 16, right: 8),
                itemCount: recommendedSpaces.length,
                itemBuilder: (context, index) {
                  final space = recommendedSpaces[index];

                  // Determine special label for this space
                  String? specialLabel;
                  Color? labelColor;

                  if (index == 0) {
                    specialLabel = "Best Match";
                    labelColor = Colors.purple[300];
                  } else if (index < 3 && Random().nextBool()) {
                    specialLabel = "High Match";
                    labelColor = Colors.blue[400];
                  } else if (Random().nextInt(3) == 0) {
                    specialLabel = "Major Match";
                    labelColor = Colors.blue[300];
                  } else {
                    specialLabel = "#${index + 1} Recommended";
                    labelColor = Colors.purple[300];
                  }

                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: SizedBox(
                      width: 160,
                      child: AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          horizontalOffset: 50,
                          child: FadeInAnimation(
                            child: _buildRecommendedSpaceCard(
                              space,
                              specialLabel: specialLabel,
                              labelColor: labelColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 0,
      ),
      error: (_, __) => const SizedBox(
        height: 0,
      ),
    );
  }

  // Build recommended space card with subtle difference from trending card
  Widget _buildRecommendedSpaceCard(
    Space space, {
    String? specialLabel,
    Color? labelColor,
  }) {
    final hasImage = space.imageUrl != null && space.imageUrl!.isNotEmpty;
    final isGreekLife =
        space.spaceType.toString().toLowerCase().contains('greek');

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            Colors.grey[900]!.withOpacity(0.8),
            Colors.black.withOpacity(0.7),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        border: Border.all(
          color: AppColors.gold.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleTapSpace(space),
          splashColor: AppColors.gold.withOpacity(0.1),
          highlightColor: AppColors.gold.withOpacity(0.05),
          child: Stack(
            children: [
              // Background image with overlay
              if (hasImage)
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.3,
                    child: CachedNetworkImage(
                      imageUrl: space.imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Center(
                        child: isGreekLife
                            ? const Icon(
                                Icons.groups,
                                color: Colors.white30,
                                size: 36,
                              )
                            : const Icon(
                                Icons.person,
                                color: Colors.white30,
                                size: 36,
                              ),
                      ),
                    ),
                  ),
                )
              // If no image, show icon as background
              else
                Positioned.fill(
                  child: Center(
                    child: isGreekLife
                        ? const Icon(
                            Icons.groups,
                            color: Colors.white24,
                            size: 36,
                          )
                        : const Icon(
                            Icons.person,
                            color: Colors.white24,
                            size: 36,
                          ),
                  ),
                ),

              // Content - space name only (no label)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Center(
                  child: Text(
                    space.name,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Redesigned space card with visual enhancements for trending spaces
  Widget _buildMySpaceCard(
    Space space, {
    int? trendingRank,
    String? specialLabel,
    Color? labelColor,
    bool hasGlowEffect = false,
  }) {
    final hasImage = space.imageUrl != null && space.imageUrl!.isNotEmpty;
    final isGreekLife =
        space.spaceType.toString().toLowerCase().contains('greek');

    // Create the label text
    String? labelText;
    if (specialLabel != null) {
      labelText = specialLabel;
    } else if (trendingRank != null) {
      labelText = "#$trendingRank Trending";
    }

    // Create a key unique to this space for the animation controller
    final key = ValueKey('trending_${space.id}');

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.grey[900]!.withOpacity(0.5),
            Colors.black,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: hasGlowEffect
              ? AppColors.gold.withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: hasGlowEffect
            ? [
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleTapSpace(space),
          splashColor: AppColors.gold.withOpacity(0.1),
          highlightColor: AppColors.gold.withOpacity(0.05),
          child: Stack(
            children: [
              // Background image with overlay
              if (hasImage)
                Positioned.fill(
                  child: CachedNetworkImage(
                    imageUrl: space.imageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Center(
                      child: isGreekLife
                          ? const Icon(
                              Icons.diversity_3,
                              color: Colors.white30,
                              size: 36,
                            )
                          : const Icon(
                              Icons.groups,
                              color: Colors.white30,
                              size: 36,
                            ),
                    ),
                  ),
                ),

              // Gradient overlay for better text readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.4),
                        Colors.black.withOpacity(0.8),
                      ],
                      stops: const [0.0, 0.8],
                    ),
                  ),
                ),
              ),

              // Content with improved layout
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Add top badge if trending
                    if (trendingRank != null && trendingRank <= 3)
                      Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: trendingRank == 1
                                ? AppColors.gold.withOpacity(0.8)
                                : Colors.orange.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.trending_up,
                                color: Colors.black,
                                size: 10,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                trendingRank == 1 ? "HOT" : "#$trendingRank",
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const Spacer(),

                    // Space name with improved styling
                    Text(
                      space.name,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.2,
                        shadows: [
                          Shadow(
                            blurRadius: 3,
                            color: Colors.black.withOpacity(0.5),
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6),

                    // Member count
                    Row(
                      children: [
                        const Icon(
                          Icons.people_outlined,
                          size: 12,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${space.metrics.memberCount} members",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),

                    // Label with animation
                    if (labelText != null &&
                        labelText.toLowerCase() != "popular")
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              (labelColor ?? AppColors.gold).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color:
                                (labelColor ?? AppColors.gold).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: TweenAnimationBuilder<double>(
                          key: key,
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 500),
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    labelText!.contains("Rising")
                                        ? Icons.rocket_launch
                                        : Icons.local_fire_department,
                                    size: 10,
                                    color: labelColor ?? AppColors.gold,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    labelText,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: labelColor ?? AppColors.gold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // New list-style space item, optimized for mobile viewing
  Widget _buildSpaceListItem(Space space, int index,
      {bool inMySpaces = false, bool isAdmin = false}) {
    final hasImage = space.imageUrl != null && space.imageUrl!.isNotEmpty;
    final isGreekLife =
        space.spaceType.toString().toLowerCase().contains('greek');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[900]!.withOpacity(0.3),
          border: isAdmin ? Border.all(
            color: AppColors.gold.withOpacity(0.5),
            width: 1.5,
          ) : Border.all(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _handleTapSpace(space),
            splashColor: AppColors.gold.withOpacity(0.1),
            highlightColor: AppColors.gold.withOpacity(0.05),
            child: Stack(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Space image or placeholder
                      Hero(
                        tag: 'space_image_${space.id}',
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.black,
                            border: Border.all(
                              color: AppColors.gold.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: hasImage
                              ? Image.network(
                                  space.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: isGreekLife
                                        ? const Icon(
                                            Icons.groups,
                                            color: Colors.white54,
                                            size: 24,
                                          )
                                        : const Icon(
                                            Icons.person,
                                            color: Colors.white54,
                                            size: 24,
                                          ),
                                  ),
                                )
                              : Center(
                                  child: isGreekLife
                                      ? const Icon(
                                          Icons.groups,
                                          color: Colors.white54,
                                          size: 24,
                                        )
                                      : const Icon(
                                          Icons.person,
                                          color: Colors.white54,
                                          size: 24,
                                        ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Space name only - with padding to avoid plus button overlap
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: !inMySpaces ? 32 : 0, top: 2),
                          child: Text(
                            space.name,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              height: 1.3,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),

                      // Arrow button for My Spaces
                      if (inMySpaces)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                            ),
                            onPressed: () => _handleTapSpace(space),
                            color: AppColors.gold,
                            splashRadius: 20,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Quick-add button as a plus icon (only show in explore, not in My Spaces)
                if (!inMySpaces)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _handleJoinSpace(space),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          topRight: Radius.circular(12),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: const Tooltip(
                            message: "Add to My Spaces",
                            child: Icon(
                              HugeIcons.strokeRoundedPlusSignCircle,
                              color: AppColors.gold,
                              size: 16,
                            ),
                          ),
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

  // Main spaces grid with filtered content - redesigned for better mobile experience
  Widget _buildSpacesGrid(AsyncValue<Map<String, List<Space>>> spacesMap) {
    return spacesMap.when(
      data: (spacesData) {
        // Get the recommended spaces IDs to filter them out from the main grid
        final recommendedSpaceIds = _getRecommendedSpaceIds(spacesData);

        // Filter spaces based on selected category
        List<Space> spaces = [];

        if (_activeCategory == 'All') {
          // Combine all spaces from different categories
          spacesData.forEach((key, value) {
            spaces.addAll(value);
          });
        } else {
          // Map the UI category to the data category
          String dataCategory;
          switch (_activeCategory) {
            case 'Student Orgs':
              dataCategory = 'Student Organizations';
              break;
            case 'University':
              dataCategory = 'University Groups';
              break;
            case 'Campus Living':
              dataCategory = 'Campus Living';
              break;
            case 'Greek Life':
              dataCategory = 'Greek Life';
              break;
            case 'Hive Exclusive':
              // For Hive Exclusive, gather all spaces
              List<Space> hiveExclusiveSpaces = [];
              // Log all spaces to see what we're working with
              spacesData.forEach((key, value) {
                debugPrint('📂 Collection: $key, Spaces count: ${value.length}');
                
                // Check each space's hiveExclusive property
                for (var space in value) {
                  debugPrint('🔍 Space: ${space.name}, hiveExclusive: ${space.hiveExclusive}');
                }
                
                // Only add spaces that have the hiveExclusive flag set to true
                final filteredSpaces = value.where((space) => space.hiveExclusive == true).toList();
                debugPrint('✅ Found ${filteredSpaces.length} hiveExclusive spaces in $key');
                hiveExclusiveSpaces.addAll(filteredSpaces);
              });
              
              // Log the final count of Hive Exclusive spaces
              debugPrint('🏆 Total Hive Exclusive spaces found: ${hiveExclusiveSpaces.length}');
              
              // If there are no Hive Exclusive spaces, show a more helpful message
              if (hiveExclusiveSpaces.isEmpty) {
                // Keep spaces empty to show our custom message
                spaces = [];
              } else {
                // We have Hive Exclusive spaces, so use them
                spaces = hiveExclusiveSpaces;
              }
              dataCategory = ''; // Empty since we've already added the spaces
              break;
            default:
              dataCategory = 'Other Spaces';
          }

          // Get spaces from the selected category if not already filtered
          if (_activeCategory != 'Hive Exclusive') {
            spaces = spacesData[dataCategory] ?? [];
          }
        }

        // Apply search filter if needed
        final searchQuery = _searchController.text.toLowerCase();
        if (searchQuery.isNotEmpty) {
          spaces = spaces
              .where((space) =>
                  space.name.toLowerCase().contains(searchQuery) ||
                  space.description.toLowerCase().contains(searchQuery) ||
                  (space.tags
                      .any((tag) => tag.toLowerCase().contains(searchQuery))) ||
                  (space.spaceType
                      .toString()
                      .toLowerCase()
                      .contains(searchQuery)))
              .toList();
        }

        // Apply tag filters if any are active
        if (_activeFilters.isNotEmpty) {
          spaces = spaces
              .where((space) => (space.tags.any((tag) => _activeFilters.any(
                      (filter) =>
                          tag.toLowerCase().contains(filter.toLowerCase()))) ||
                  _activeFilters.any((filter) => space.spaceType
                      .toString()
                      .toLowerCase()
                      .contains(filter.toLowerCase()))))
              .toList();
        }

        // Filter out spaces that are in the recommended list
        spaces = spaces
            .where((space) => !recommendedSpaceIds.contains(space.id))
            .toList();

        // Sort spaces by engagement score
        spaces.sort((a, b) {
          // First prioritize spaces with higher engagement
          final aEngagement = a.metrics.engagementScore;
          final bEngagement = b.metrics.engagementScore;

          if (bEngagement != aEngagement) {
            return bEngagement.compareTo(aEngagement);
          }

          // Then alphabetically
          return a.name.compareTo(b.name);
        });

        if (spaces.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _activeCategory == 'Hive Exclusive' ? Icons.workspace_premium : Icons.search,
                      size: 48,
                      color: _activeCategory == 'Hive Exclusive' ? AppColors.gold.withOpacity(0.3) : Colors.white24,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _activeCategory == 'Hive Exclusive' 
                        ? 'No Hive Exclusive Spaces' 
                        : 'No spaces found',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                    if (_activeCategory == 'Hive Exclusive')
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Exclusive spaces will be added soon. Check back later!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white38,
                          ),
                        ),
                      )
                    else if (searchQuery.isNotEmpty || _activeFilters.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Try adjusting your filters',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white38,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }

        // Build grid of spaces
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(
              0, 8, 0, 120), // Add bottom padding for FAB
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                // Determine if we should add a section header
                if (index == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: Row(
                          children: [
                            Text(
                              'All Spaces',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            // Filter icon to replace horizontal category selector
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[850]?.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _activeCategory != 'All' 
                                    ? AppColors.gold.withOpacity(0.5) 
                                    : Colors.transparent,
                                  width: 1,
                                ),
                              ),
                              child: InkWell(
                                onTap: () => _showCategoryFilterDialog(context),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        HugeIcons.tag,
                                        size: 16,
                                        color: _activeCategory != 'All' 
                                          ? AppColors.gold 
                                          : Colors.white70,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _activeCategory != 'All' ? _activeCategory : 'Filter',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: _activeCategory != 'All' 
                                            ? FontWeight.w600 
                                            : FontWeight.w400,
                                          color: _activeCategory != 'All' 
                                            ? AppColors.gold 
                                            : Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Add tag filter button - always visible
                            if (_activeCategory == 'Hive Exclusive')
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[850]?.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _activeFilters.isNotEmpty
                                        ? AppColors.gold.withOpacity(0.5)
                                        : Colors.transparent,
                                      width: 1,
                                    ),
                                  ),
                                  child: InkWell(
                                    onTap: () => _showTagsFilterBottomSheet(context),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.local_offer,
                                            size: 16,
                                            color: _activeFilters.isNotEmpty
                                              ? AppColors.gold
                                              : Colors.white70,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _activeFilters.isNotEmpty ? 'Tags (${_activeFilters.length})' : 'Tags',
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: _activeFilters.isNotEmpty
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                              color: _activeFilters.isNotEmpty
                                                ? AppColors.gold
                                                : Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Add a subtle divider
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Divider(
                          color: Colors.white.withOpacity(0.1),
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                }

                final spaceIndex = index - 1;
                if (spaceIndex < spaces.length) {
                  return AnimationConfiguration.staggeredList(
                    position: spaceIndex,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50,
                      child: FadeInAnimation(
                        child:
                            _buildSpaceListItem(spaces[spaceIndex], spaceIndex),
                      ),
                    ),
                  );
                }

                // Show loading indicator at the end if loading more
                if (spaceIndex == spaces.length && _isLoadingMore) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                  );
                }

                return null;
              },
              // +1 for the header, +1 for possible loading indicator
              childCount: spaces.length + 1 + (_isLoadingMore ? 1 : 0),
            ),
          ),
        );
      },
      loading: () => const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      ),
      error: (_, __) => SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading spaces',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please try again later',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: _refreshSpaces,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gold,
                    side: const BorderSide(color: AppColors.gold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(
                    'Retry',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Add a method to show the category filter dialog
  void _showCategoryFilterDialog(BuildContext context) {
    // Use a full-screen dialog approach that completely covers the navigation bar
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
        decoration: BoxDecoration(
          // Only round the top corners
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          // Add a solid color at the bottom to ensure nav bar is fully covered
          color: AppColors.black.withOpacity(0.95),
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                    'Filter Spaces',
                    style: GoogleFonts.outfit(
                    fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
              ),
            ),
            const Divider(color: Colors.white12),
            Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListView.builder(
                shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isActive = _activeCategory == category;
                  
                  // Assign appropriate icon based on category
                  IconData categoryIcon = Icons.category;
                  switch (category) {
                    case 'All':
                      categoryIcon = HugeIcons.home;
                      break;
                    case 'Student Orgs':
                      categoryIcon = HugeIcons.strokeRoundedUserGroup03;
                      break;
                    case 'Greek Life':
                      categoryIcon = HugeIcons.strokeRoundedAlphabetGreek;
                      break;
                    case 'Campus Living':
                      categoryIcon = HugeIcons.strokeRoundedHouse03;
                      break;
                    case 'University':
                      categoryIcon = HugeIcons.strokeRoundedMortarboard02;
                      break;
                    case 'Hive Exclusive':
                      categoryIcon = Icons.workspace_premium;
                      break;
                  }
                  
                  return InkWell(
                    onTap: () {
                      // Disable tap for locked categories
                      if (category == 'Academics' || category == 'Circles') {
                        HapticFeedback.heavyImpact();
                        return;
                      }
                      
                      HapticFeedback.selectionClick();
                      setState(() {
                        _activeCategory = category;
                      });
                      Navigator.pop(context);
                      
                      // Animate scroll to top when changing categories
                      if (_mainScrollController.hasClients) {
                        _mainScrollController.animateTo(
                          0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
                      child: Row(
                        children: [
                          // Show different icons based on category
                          if (category == 'Hive Exclusive')
                            Image.asset(
                              'assets/images/hivelogo.png',
                              width: 20,
                              height: 20,
                              color: isActive ? AppColors.gold : Colors.white70,
                            )
                          else if (category == 'Academics')
                            const Icon(
                              HugeIcons.strokeRoundedBook02,
                              color: Colors.white30,
                              size: 20,
                            )
                          else if (category == 'Circles')
                            const Icon(
                              HugeIcons.strokeRoundedUserGroup03,
                              color: Colors.white30,
                              size: 20,
                            )
                          else
                            Icon(
                              categoryIcon,
                              color: isActive ? AppColors.gold : Colors.white70,
                              size: 20,
                            ),
                          const SizedBox(width: 16),
                          Text(
                            category,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              color: (category == 'Academics' || category == 'Circles')
                                  ? Colors.white38
                                  : (isActive ? AppColors.gold : Colors.white),
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                          const Spacer(),
                          if (isActive)
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.gold,
                              size: 20,
                            )
                          else if (category == 'Academics' || category == 'Circles')
                            const Icon(
                              Icons.lock,
                              color: Colors.white30,
                              size: 16,
                            ),
                        ],
                      ),
                    ),
                  );
                },
                      ),
                    ],
                  ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  // This is the single correct implementation of the tags filter
  void _showTagsFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.black.withOpacity(0.95),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Filter Spaces',
                  style: GoogleFonts.outfit(
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                // Add filter options here
                Text(
                  'Coming soon: Filter by tags',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  // Show dialog to create a new space
  void _showCreateSpaceDialog(BuildContext context) {
    HapticFeedback.mediumImpact();
    
    // Navigate to the CreateSpaceSplashPage instead of showing a dialog
    GoRouter.of(context).push('/spaces/create');
  }

  // Show dialog with options to create space or event
  void _showCreateOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.transparent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Tappable area to dismiss dialog
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),
                
                // Main content container
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                  margin: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom
                  ),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 0.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        color: AppColors.black.withOpacity(0.2),
                        child: Stack(
                          children: [
                            // Close button at top right
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.black.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.close, color: AppColors.white, size: 20),
                                  padding: const EdgeInsets.all(8),
                                  constraints: const BoxConstraints(),
                                  splashRadius: 24,
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                            ),
                            
                            // Content
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Add padding at the top to accommodate close button
                                const SizedBox(height: 8),
                                
                                // Adjust the title to avoid overlapping with close button
                                Padding(
                                  padding: const EdgeInsets.only(right: 48.0), // Add right padding to avoid X button
                                  child: Text(
                                    'Take Back Your School',
                                    style: GoogleFonts.outfit(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                
                                // Create Space button
                                InkWell(
                                  onTap: () {
                                    HapticFeedback.mediumImpact();
                                    Navigator.pop(context);
                                    // Navigate to the CreateSpaceSplashPage 
                                    GoRouter.of(context).push('/spaces/create');
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: AppColors.cardBackground,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.1),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          HugeIcons.strokeRoundedUserGroup03, 
                                          color: AppColors.gold,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Create Space',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.white,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Create a new community for your school',
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.arrow_forward_ios,
                                          color: AppColors.textSecondary,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ).addGlassmorphism(
                                    borderRadius: 16,
                                    blur: 15.0,
                                    opacity: 0.1,
                                    addGoldAccent: true,
                                  ),
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Create Event button
                                InkWell(
                                  onTap: () {
                                    HapticFeedback.mediumImpact();
                                    Navigator.pop(context);
                                    _showCreateEventDialog(context);
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: AppColors.cardBackground,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.1),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          HugeIcons.calendar, 
                                          color: AppColors.gold,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Create Event',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.white,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Schedule an event in spaces you admin',
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.arrow_forward_ios,
                                          color: AppColors.textSecondary,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ).addGlassmorphism(
                                    borderRadius: 16,
                                    blur: 15.0,
                                    opacity: 0.1,
                                    addGoldAccent: true,
                                  ),
                                ),
                                
                                // Add extra bottom space to ensure it's above the nav bar
                                const SizedBox(height: 8),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // Method to show event creation dialog
  void _showCreateEventDialog(BuildContext context) {
    // Check if the user has any spaces to create events in
    final userSpacesAsync = ref.read(user_providers.userSpacesProvider);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('You must be signed in to create an event'),
          backgroundColor: Colors.black.withOpacity(0.8),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    
    userSpacesAsync.when(
      data: (userSpaces) {
        // Filter spaces where the user is an admin
        final adminSpaces = userSpaces.where((space) => 
          space.admins.contains(currentUserId)).toList();
        
        if (adminSpaces.isEmpty) {
          // Show a message that user needs to be an admin of a space
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('You must be an admin of a space to create events'),
              backgroundColor: Colors.black.withOpacity(0.8),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              action: SnackBarAction(
                label: 'Create Space',
                textColor: AppColors.gold,
                onPressed: () => _showCreateSpaceDialog(context),
              ),
            ),
          );
          return;
        }

        // If there are spaces where user is admin, show the space selection dialog
        showDialog(
          context: context,
          barrierDismissible: true,
          barrierColor: Colors.black.withOpacity(0.75),
          builder: (context) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.zero,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.transparent,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Tappable area to dismiss dialog
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                    
                    // Main content container
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                      margin: EdgeInsets.only(
                        bottom: MediaQuery.of(context).padding.bottom
                      ),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 0.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            color: AppColors.black.withOpacity(0.2),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Select a Space',
                                      style: GoogleFonts.outfit(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.white,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, color: AppColors.white),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Choose a space you admin to create your event in:',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                // List of spaces where user is admin
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                                  ),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: adminSpaces.length,
                                    itemBuilder: (context, index) {
                                      final space = adminSpaces[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: InkWell(
                                          onTap: () {
                                            HapticFeedback.mediumImpact();
                                            Navigator.pop(context);
                                            
                                            // Navigate to create event page
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) => CreateEventPage(
                                                  selectedSpace: space.toSpace(),
                                                ),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: AppColors.cardBackground,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(0.1),
                                                width: 0.5,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: space.imageUrl?.isNotEmpty == true
                                                    ? Image.network(
                                                        space.imageUrl!,
                                                        width: 48,
                                                        height: 48,
                                                        fit: BoxFit.cover,
                                                      )
                                                    : Container(
                                                        width: 48,
                                                        height: 48,
                                                        color: AppColors.gold.withOpacity(0.2),
                                                        child: const Icon(
                                                          Icons.groups,
                                                          color: AppColors.gold,
                                                        ),
                                                      ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        space.name,
                                                        style: GoogleFonts.outfit(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w600,
                                                          color: AppColors.white,
                                                        ),
                                                      ),
                                                      if (space.description.isNotEmpty) ...[
                                                        const SizedBox(height: 4),
                                                        Text(
                                                          space.description,
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: GoogleFonts.inter(
                                                            fontSize: 14,
                                                            color: AppColors.textSecondary,
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                                const Icon(
                                                  Icons.arrow_forward_ios,
                                                  color: AppColors.textSecondary,
                                                  size: 16,
                                                ),
                                              ],
                                            ),
                                          ).addGlassmorphism(
                                            borderRadius: 12,
                                            blur: GlassmorphismGuide.kCardBlur,
                                            opacity: GlassmorphismGuide.kCardGlassOpacity,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Loading your spaces...'),
            backgroundColor: Colors.black.withOpacity(0.8),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      error: (error, stackTrace) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading spaces: ${error.toString()}'),
            backgroundColor: Colors.red.withOpacity(0.8),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  Widget _buildMySpacesGrid(List<Space> spaces) {
    // Implementation replaced
    if (spaces.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'You haven\'t joined any spaces yet!\nExplore and find your communities.',
            style: GoogleFonts.outfit(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return AnimationLimiter(
      child: GridView.builder(
        controller: _mySpacesScrollController,
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12.0,
          mainAxisSpacing: 12.0,
          childAspectRatio: 0.85, // Might need adjustment after removing separate text row
        ),
        itemCount: spaces.length,
        itemBuilder: (context, index) {
          final space = spaces[index];
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 375),
            columnCount: 3,
            child: ScaleAnimation(
              child: FadeInAnimation(
                child: SpaceGridItem(
                  space: space,
                  onTap: () => _handleTapSpace(space),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Builds the app bar for the spaces page
  Widget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        'Spaces',
        style: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () {
            // Navigate to notifications
            HapticFeedback.mediumImpact();
          },
        ),
      ],
    );
  }

  // Builds the tab bar for the spaces page
  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      indicatorColor: AppColors.gold,
      labelColor: AppColors.gold,
      unselectedLabelColor: Colors.white,
      tabs: const [
        Tab(text: 'My Spaces'),
        Tab(text: 'Discover'),
        Tab(text: 'Requests'),
      ],
    );
  }

  // Builds the floating action button for creating spaces
  Widget _buildCreateSpaceButton(ProfileSyncState profileAsync) {
    return FloatingActionButton(
      backgroundColor: AppColors.gold,
      foregroundColor: Colors.black,
      onPressed: () {
        // Show create space dialog or navigate to create space page
        HapticFeedback.mediumImpact();
        _showCreateSpaceDialog(context);
      },
      child: const Icon(Icons.add),
    );
  }

  void _performSearch(String query) {
    setState(() {
      _isSearching = true;
    });
    // Use the provider directly
    ref.read(spaceSearchProvider.notifier).search(query);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _isSearchExpanded = false;
    });
    // Use the provider directly
    ref.read(spaceSearchProvider.notifier).clear();
  }
}

// Keeping _SliverCategorySelectorDelegate for category selector
class _SliverCategorySelectorDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final bool visible;

  _SliverCategorySelectorDelegate({
    required this.child,
    required this.visible,
  });

  @override
  double get minExtent =>
      visible ? 56 : 0; // Updated height for better touch targets

  @override
  double get maxExtent => visible ? 56 : 0; // Updated height for consistency

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return visible ? child : const SizedBox.shrink();
  }

  @override
  bool shouldRebuild(_SliverCategorySelectorDelegate oldDelegate) {
    return child != oldDelegate.child || visible != oldDelegate.visible;
  }
}

// Helper method to get the IDs of all recommended spaces
Set<String> _getRecommendedSpaceIds(Map<String, List<Space>> spacesData) {
  // Combine all spaces from different categories
  List<Space> allSpacesList = [];
  spacesData.forEach((key, value) {
    allSpacesList.addAll(value);
  });

  if (allSpacesList.isEmpty) {
    return {};
  }

  // Sort by engagement score
  allSpacesList.sort((a, b) {
    final aEngagement = a.metrics.engagementScore;
    final bEngagement = b.metrics.engagementScore;
    return bEngagement.compareTo(aEngagement);
  });

  // Get top 10 spaces (or fewer if list is smaller)
  final recommendedSpaces =
      allSpacesList.take(min(10, allSpacesList.length)).toList();

  // Return the set of IDs
  return recommendedSpaces.map((space) => space.id).toSet();
}

// Widget that shows text temporarily and then hides it
class TemporaryText extends StatefulWidget {
  final String text;
  final TextStyle textStyle;
  final Duration displayDuration;
  final Duration hideDuration;

  const TemporaryText({
    super.key,
    required this.text,
    required this.textStyle,
    required this.displayDuration,
    required this.hideDuration,
  });

  @override
  State<TemporaryText> createState() => _TemporaryTextState();
}

class _TemporaryTextState extends State<TemporaryText> {
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _startCycle();
  }

  void _startCycle() async {
    await Future.delayed(widget.displayDuration);
    if (!mounted) return;

    setState(() {
      _visible = false;
    });

    await Future.delayed(widget.hideDuration);
    if (!mounted) return;

    setState(() {
      _visible = true;
    });

    _startCycle();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 800),
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          widget.text,
          style: widget.textStyle,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Optimized Grid Item for displaying spaces in My Spaces tab
class SpaceGridItem extends StatelessWidget {
  final Space space;
  final VoidCallback onTap;

  const SpaceGridItem({
    super.key,
    required this.space,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start, // Align content top
        children: [
          Expanded( // Use Expanded to fill the grid cell vertically
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.0),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: space.imageUrl ?? space.bannerUrl ?? '',
                    fit: BoxFit.cover,
                    memCacheHeight: 200,
                    memCacheWidth: 200,
                    maxWidthDiskCache: 200,
                    maxHeightDiskCache: 200,
                    placeholder: (context, url) => Container(
                      color: Colors.grey.shade800.withOpacity(0.5),
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey.shade800.withOpacity(0.5),
                      child: const Icon(
                        Icons.error_outline,
                        color: AppColors.textSecondary,
                        size: 30,
                      ),
                    ),
                  ),
                  // Gradient Overlay for text readability instead of glassmorphism
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.1),
                          Colors.black.withOpacity(0.6),
                        ],
                        stops: const [0.5, 0.7, 1.0], // Adjust stops for gradient
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Text(
                      space.name,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(
                            blurRadius: 2.0,
                            color: Colors.black.withOpacity(0.8),
                            offset: const Offset(1.0, 1.0),
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
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
}

// ... rest of spaces_page.dart ...

