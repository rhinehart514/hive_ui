import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import for HapticFeedback
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:auto_route/auto_route.dart';
import 'package:hive_ui/features/spaces/presentation/providers/space_providers.dart' as presentation_space_providers;
import 'package:hive_ui/features/spaces/presentation/providers/spaces_controller.dart';
import 'package:hive_ui/features/spaces/presentation/providers/user_spaces_providers.dart' as user_providers;
import 'package:hive_ui/features/spaces/application/providers.dart' as application_providers;
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
import 'dart:async'; // Add this import for TimeoutException
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
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
// Import Phosphor Icons
import 'package:phosphor_flutter/phosphor_flutter.dart';
// Import intl for date formatting if needed for "Just Created" logic refinement
import 'package:intl/intl.dart';

// --- NEW: Custom Scroll Behavior for Desktop Dragging ---
class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        // Add other device kinds as needed
      };
}
// --- END NEW ---

// Define constants for MySpaceCircleItem sizing outside the state class
const double _mySpaceCircleRadius = 36.0;
const double _mySpaceHorizontalPadding = 8.0;

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

@RoutePage()
class SpacesPage extends ConsumerStatefulWidget {
  const SpacesPage({super.key});

  // --- NEW: Create a static key for My Spaces that can be accessed from anywhere ---
  static final GlobalKey mySpacesListKey = GlobalKey();
  // --- END NEW ---

  @override
  ConsumerState<SpacesPage> createState() => _SpacesPageState();
}

class _SpacesPageState extends ConsumerState<SpacesPage> with TickerProviderStateMixin {
  // Animation Controller for pulsing the create button
  late AnimationController _pulseController;
  // Make the animation nullable to avoid LateInitializationError
  Animation<double>? _pulseAnimation;

  // --- Controller and Key for My Spaces List ---
  final ScrollController _mySpacesScrollController = ScrollController();
  // Use the static key from SpacesPage
  GlobalKey get _mySpacesListKey => SpacesPage.mySpacesListKey;
  // --- END ---

  // --- NEW: Track joined spaces for auto-scroll ---
  List<String> _previousSpaceIds = [];
  // --- END NEW ---

  @override
  void initState() {
    super.initState();
    
    // Initialize pulse animation controller
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Initialize the animation
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Initialize previous space IDs list
    _previousSpaceIds = [];
  }
  
  // Helper method to scroll to a specific space in the list
  void _scrollToNewSpace(String spaceId, List<entities.SpaceEntity> spaces) {
    // Find the index of the new space in the list
    // +1 because first item is "Create Space"
    final int indexOfSpace = spaces.indexWhere((space) => space.id == spaceId);
    if (indexOfSpace == -1) return; // Space not found
    
    final int targetIndex = indexOfSpace + 1; // +1 for "Create Space" at index 0
    
    // Calculate approximate position (each item is roughly 2*_mySpaceCircleRadius + padding)
    final double itemWidth = (_mySpaceCircleRadius * 2) + (_mySpaceHorizontalPadding * 2);
    final double targetPosition = targetIndex * itemWidth;
    
    // Animate to position
    if (_mySpacesScrollController.hasClients) {
      print('Scrolling My Spaces list to show newly joined space at index $targetIndex');
      _mySpacesScrollController.animateTo(
        targetPosition, 
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose(); // Dispose pulse controller
    _mySpacesScrollController.dispose(); // Dispose scroll controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Track space changes when build runs
    final userSpacesAsync = ref.watch(user_providers.userSpacesProvider);
    
    // Handle space changes and scrolling within build method
    userSpacesAsync.whenData((userSpacesEntities) {
      // Extract current space IDs
      final currentSpaceIds = userSpacesEntities.map((entity) => entity.id).toList();
      
      // Compare with previous IDs to find new ones
      if (_previousSpaceIds.isNotEmpty) {
        final newSpaceIds = currentSpaceIds.where((id) => !_previousSpaceIds.contains(id)).toList();
        
        // If we have new spaces, scroll to them
        if (newSpaceIds.isNotEmpty) {
          // Use post frame callback to ensure the UI is built before scrolling
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToNewSpace(newSpaceIds.first, userSpacesEntities);
          });
        }
      }
      
      // Update previous IDs for next comparison
      _previousSpaceIds = currentSpaceIds;
    });
    
    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        backgroundColor: AppColors.dark,
        elevation: 0,
          title: Text(
          'SPACES',
          style: GoogleFonts.inter(
            fontSize: 28, // H2 Style
              fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
      ),
      // --- WRAP with ScrollConfiguration ---
      body: ScrollConfiguration(
        behavior: MyCustomScrollBehavior(),
        child: CustomScrollView( // Use CustomScrollView for mixed content
      slivers: [
          // Sliver for the "My Spaces" horizontal list
        SliverToBoxAdapter(
            child: _buildMySpacesSection(),
          ),
          // Sliver for the "Discover" header
        SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 24.0, bottom: 12.0, right: 16.0), // spacing-lg top, spacing-sm bottom
                    child: Text(
                'Discover',
                    style: GoogleFonts.inter(
                  fontSize: 20, // H3 Style
                    fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
          // Sliver for the "Discover" vertical list
          _buildDiscoverSliverList(), // Use a separate method to build the sliver list
        ],
      ),
      ),
      // --- END WRAP ---
    );
  }

  // Updated My Spaces Section with Data Integration & BouncingScrollPhysics
  Widget _buildMySpacesSection() {
    final userSpacesAsync = ref.watch(user_providers.userSpacesProvider);

    return userSpacesAsync.when(
      data: (userSpacesEntities) {
        final bool isEmptyState = userSpacesEntities.isEmpty;

        // --- NEW: Determine if any spaces are newly joined ---
        final currentSpaceIds = userSpacesEntities.map((entity) => entity.id).toList();
        final Set<String> newlyJoinedSpaceIds = {};
        
        if (_previousSpaceIds.isNotEmpty) {
          // Find spaces that are in the current list but weren't in the previous list
          for (final id in currentSpaceIds) {
            if (!_previousSpaceIds.contains(id)) {
              newlyJoinedSpaceIds.add(id);
            }
          }
        }
        // --- END NEW ---

        final List<Map<String, dynamic>> mySpacesData = [
          {'type': 'create', 'label': 'Create Space', 'entity': null},
          ...userSpacesEntities.map((entity) => {
             'type': 'space',
             'label': entity.name,
             'details': null,
             'imageUrl': entity.imageUrl,
             'selected': false,
             'entity': entity,
             'isNewlyJoined': newlyJoinedSpaceIds.contains(entity.id), // NEW: Pass the newly joined flag
          }),
        ];

        // --- Refined Height Calculation --- 
        // Height needed for one horizontal list item (Circle + Spacing + Label)
        final double circleDiameter = _mySpaceCircleRadius * 2; // 72.0
        final double spacingBelowCircle = 6.0;
        final double labelHeightEstimate = 30.0; // Approx height for max 2 lines of text
        final double itemVerticalPadding = 8.0; // Extra buffer within the list item height
        final double listHeight = circleDiameter + spacingBelowCircle + labelHeightEstimate + itemVerticalPadding; // Height for the SizedBox containing the ListView

        // Height needed for the separate "You're not in any Spaces..." text widget
        final double emptyStateTextTopPadding = 12.0;
        final double emptyStateTextHeightEstimate = 20.0; 
        final double emptyStateWidgetHeight = isEmptyState ? (emptyStateTextTopPadding + emptyStateTextHeightEstimate) : 0.0;

        // Total container height
        final double containerVerticalPadding = 16.0; // Top/Bottom padding for the outer Container
        final double containerHeight = listHeight + emptyStateWidgetHeight + (containerVerticalPadding * 2);
        // --- End Refined Height Calculation ---

        return Container(
          height: containerHeight, // Use new calculated height
          padding: EdgeInsets.symmetric(vertical: containerVerticalPadding), // Use correct padding var
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                key: _mySpacesListKey, // --- NEW: Assign key to the container ---
                height: listHeight, // Use height calculated specifically for the list view
                child: ListView.builder(
                  controller: _mySpacesScrollController, // --- NEW: Assign controller ---
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(), // Changed from ClampingScrollPhysics
                  padding: const EdgeInsets.symmetric(horizontal: _mySpaceHorizontalPadding),
                  itemCount: mySpacesData.length,
                  itemBuilder: (context, index) {
                    final itemData = mySpacesData[index];
                    final bool isCreateItem = itemData['type'] == 'create';
                    return MySpaceCircleItem(
                      key: ValueKey(itemData['entity']?.id ?? itemData['label']),
                      type: itemData['type'],
                      label: itemData['label'],
                      details: itemData['details'],
                      imageUrl: itemData['imageUrl'],
                      selected: itemData['selected'] ?? false,
                      showCreateHighlight: isCreateItem && isEmptyState,
                      spaceEntity: itemData['entity'],
                      isNewlyJoined: itemData['isNewlyJoined'] ?? false, // NEW: Pass the newly joined flag
                    );
                  },
                ),
              ),
              if (isEmptyState)
                Padding(
                  // Use the calculated top padding
                  padding: EdgeInsets.only(top: emptyStateTextTopPadding),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: 1.0,
                    child: Text(
                      'You\'re not in any Spaces yet',
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () {
        // Calculate loading height based on non-empty state height for consistency
        final double loadingListHeight = (_mySpaceCircleRadius * 2) + 6.0 + 30.0 + 8.0;
        final double loadingContainerHeight = loadingListHeight + (16.0 * 2);
        return Container(
          height: loadingContainerHeight,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(color: AppColors.gold),
        );
      },
      error: (error, stackTrace) {
        print("Error loading user spaces: $error\n$stackTrace");
        // Calculate error height based on non-empty state height for consistency
        final double errorListHeight = (_mySpaceCircleRadius * 2) + 6.0 + 30.0 + 8.0;
        final double errorContainerHeight = errorListHeight + (16.0 * 2);
        return Container(
           height: errorContainerHeight,
           alignment: Alignment.center,
           padding: const EdgeInsets.symmetric(horizontal: 16.0),
           child: Text(
            'Error loading your spaces.',
            style: GoogleFonts.inter(color: AppColors.error),
            textAlign: TextAlign.center,
           ),
        );
      },
    );
  }

  // Updated Discover Sliver List with Data Integration using allSpacesProvider
  Widget _buildDiscoverSliverList() {
    // Watch the application-level allSpacesProvider
    final discoverSpacesAsync = ref.watch(application_providers.allSpacesProvider);

    return discoverSpacesAsync.when(
      data: (discoverSpacesEntities) { // Directly receive the list
        // --- DEBUG LOG ---
        debugPrint('Discover Spaces Provider Data: Received ${discoverSpacesEntities.length} space entities directly.');

        if (discoverSpacesEntities.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false, // Prevent unnecessary scrolling
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(16.0), // Add padding
                child: Text(
                  'No spaces to discover right now.\\nTry creating one!', // Updated empty state text
                  style: TextStyle(color: AppColors.textSecondary, height: 1.5), // Added line height
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0), // Add bottom padding
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) { // Pass index here
                final entity = discoverSpacesEntities[index];
                // Use the DiscoverSpaceCard StatefulWidget, passing the index
                return DiscoverSpaceCard(
                  key: ValueKey(entity.id), // Use entity ID for key
                  index: index, // Pass index for alternating background
                  spaceEntity: entity,
                );
              },
              childCount: discoverSpacesEntities.length,
            ),
          ),
        );
      },
      loading: () {
        // Return a sliver loading state (e.g., shimmer list)
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          sliver: SliverList(
             delegate: SliverChildBuilderDelegate(
               // Pass index to shimmer card if needed for alternating shimmer styles
               (context, index) => ShimmerDiscoverCard(index: index),
               childCount: 5, // Show a few shimmers
            ),
          ),
        );
      },
      error: (error, stackTrace) {
         print("Error loading discover spaces: $error\\n$stackTrace");
         return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error loading spaces to discover.\\nPlease try again later.', // Updated error message
                  style: GoogleFonts.inter(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        },
    );
  }

  // ... Keep any other relevant methods (e.g., for data fetching/handling if they can be adapted)
  // ... Remove methods specific to the old UI (like _buildSpaceCard, _buildLoadingIndicator, etc. if they are replaced)
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

// NEW: Convert to ConsumerStatefulWidget for provider access
class DiscoverSpaceCard extends ConsumerStatefulWidget {
  final int index; // Index for alternating background
  final entities.SpaceEntity spaceEntity;

  const DiscoverSpaceCard({
    super.key,
    required this.index,
    required this.spaceEntity,
  });

  @override
  ConsumerState<DiscoverSpaceCard> createState() => _DiscoverSpaceCardState(); // Update state type
}

// Update state class to extend ConsumerState
class _DiscoverSpaceCardState extends ConsumerState<DiscoverSpaceCard> with TickerProviderStateMixin { // Use TickerProviderStateMixin for multiple controllers
  // --- NEW: Key for this Card ---
  final GlobalKey _cardKey = GlobalKey();
  // --- END NEW ---

  // --- Nullable Animation Controllers & Animations ---
  AnimationController? _animationController;
  Animation<double>? _scaleAnimation;
  AnimationController? _glowController;
  Animation<double>? _glowAnimation;
  // --- End Nullable ---

  // Flag to prevent multiple highlights of the My Spaces section
  bool _isFlashingMySpaces = false;

  // Define "Just Created" threshold (e.g., 48 hours)
  final Duration justCreatedThreshold = const Duration(hours: 48);

  // --- NEW: State for handling join button ---
  bool _isJoining = false;
  // Track successful join locally for checkmark display after loading
  bool _justJoined = false; 
  // --- END NEW ---

  @override
  void initState() {
    super.initState();
    
    // --- Initialize Tap Animation ---
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _animationController!, // Safe to use ! here as it's initialized right above
        curve: Curves.easeOut,
        reverseCurve: Curves.elasticOut,
      ),
    );
    // --- End Initialize Tap Animation ---

    // --- Initialize Glow Animation ---
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // Glow duration
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController!, curve: Curves.easeOut), // Safe to use ! here
    );
    // --- END Initialize Glow Animation ---
  }

  @override
  void dispose() {
    _animationController?.dispose(); // Use null-aware dispose
    _glowController?.dispose(); // Use null-aware dispose
    super.dispose();
  }

  // --- Tap Handlers (keep existing logic, add null checks) ---
  void _handleTapDown(TapDownDetails details) { _animationController?.forward(); }
  void _handleTapUp(TapUpDetails details) {
    Future.delayed(const Duration(milliseconds: 50), () {
       if (mounted) { _animationController?.reverse(); }
    });
    HapticFeedback.lightImpact();
    print('Tapped on discover space: ${widget.spaceEntity.name} (ID: ${widget.spaceEntity.id})');
    // --- NAVIGATION UPDATED --- 
    // Use pushNamed with path parameters for both type and id
    final spaceTypeString = _spaceTypeToString(widget.spaceEntity.spaceType);
    context.pushNamed(
      'space_detail', 
      pathParameters: {
        'type': spaceTypeString, 
        'id': widget.spaceEntity.id
      },
      extra: widget.spaceEntity.toSpace() // Pass the Space object if needed by detail screen
    );
    // --- END NAVIGATION --- 
  }
  void _handleTapCancel() { if (mounted) { _animationController?.reverse(); } }
  void _handleLongPress() {
    HapticFeedback.mediumImpact();
    print('Long pressed on discover: ${widget.spaceEntity.name}');
    _showMiniMenu(context, widget.spaceEntity);
  }
  void _showMiniMenu(BuildContext context, entities.SpaceEntity spaceEntity) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.dark2.withOpacity(0.9), // Use secondary surface, slightly transparent
      barrierColor: Colors.black.withOpacity(0.6), // Dim background
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.0), // radius-lg
          topRight: Radius.circular(16.0),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Optional: Handle bar indicator
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.grey700,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.group_add_outlined, color: AppColors.textSecondary),
                title: Text('Join Space', style: GoogleFonts.inter(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  print('Join Space action for ${spaceEntity.name}');
                  // TODO: Implement join action using spaceEntity.id
                },
              ),
              ListTile(
                leading: const Icon(Icons.visibility_outlined, color: AppColors.textSecondary),
                title: Text('View Drops', style: GoogleFonts.inter(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  print('View Drops action for ${spaceEntity.name}');
                  // TODO: Implement view drops action using spaceEntity.id
                },
              ),
              ListTile(
                leading: const Icon(Icons.bookmark_border, color: AppColors.textSecondary),
                title: Text('Save for Later', style: GoogleFonts.inter(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  print('Save for Later action for ${spaceEntity.name}');
                  // TODO: Implement save action using spaceEntity.id
                },
              ),
               // Add padding for safe area / navigation bar
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        );
      },
    );
  }
  // --- End Tap Handlers ---

  // --- Helper to determine the icon ---
  IconData _getSpaceIcon(entities.SpaceEntity entity) {
    // 1. Try using the iconCodePoint from the entity if valid
    if (entity.iconCodePoint > 0) {
      // Ensure the font family matches where the codepoint is defined
      // Assuming MaterialIcons for now, adjust if different
      return IconData(entity.iconCodePoint, fontFamily: 'MaterialIcons');
    }

    // 2. Fallback based on SpaceType
    switch (entity.spaceType) {
      case entities.SpaceType.studentOrg:
        return PhosphorIcons.users(); // Example icon
      case entities.SpaceType.universityOrg:
        return PhosphorIcons.buildings(); // Example icon
      case entities.SpaceType.campusLiving:
        return PhosphorIcons.house(); // Example icon
      case entities.SpaceType.fraternityAndSorority:
        return PhosphorIcons.usersThree(); // Example icon
      case entities.SpaceType.hiveExclusive:
        return PhosphorIcons.crownSimple(); // Example icon for exclusive
      case entities.SpaceType.other:
      default:
        return PhosphorIcons.circlesFour(); // Default fallback
    }
    // TODO: Consider using tags for more specific icons if type is 'other'
  }

  // --- Helper to build subtitle ---
  Widget _buildSubtitle(entities.SpaceEntity entity) {
    final now = DateTime.now();
    final timeSinceCreation = now.difference(entity.createdAt ?? now);
    final bool isJustCreated = timeSinceCreation < justCreatedThreshold;
    final bool isTrending = entity.metrics.isTrending ?? false;
    final int memberCount = entity.metrics.memberCount;

    String text;
    Color color = AppColors.textSecondary;
    FontWeight weight = FontWeight.w500;
    String prefix = '';

    if (isJustCreated) {
      text = 'Just Created';
      color = AppColors.gold; // Highlight new spaces
      prefix = '✨ ';
    } else if (isTrending) {
      text = 'Trending';
       color = AppColors.gold; // Highlight trending spaces
       prefix = '🔥 ';
       if (memberCount > 0) {
         text += ' • $memberCount members'; // Add member count if trending and > 0
       }
    } else if (memberCount > 0) {
      text = '$memberCount member${memberCount == 1 ? "" : "s"}';
    } else {
      // Case: Not just created, not trending, 0 members
      text = 'New Space'; // Use "New Space" instead of "0 members"
      color = AppColors.textSecondary;
       prefix = '✨ '; // Use sparkle for new spaces too
    }

    return Text(
      prefix + text,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: weight,
        color: color,
        letterSpacing: 0.1,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  // Simple animation for successful space join
  void _performSuccessAnimation(BuildContext context, IconData iconData) {
    // 1. Show success snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(iconData, color: AppColors.dark, size: 18),
            const SizedBox(width: 8),
            Text('Space added to your collection!', 
              style: GoogleFonts.inter(
                color: AppColors.dark,
                fontWeight: FontWeight.w600
              )
            ),
          ],
        ),
        backgroundColor: AppColors.gold,
        duration: const Duration(milliseconds: 1800),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: SnackBarAction(
          label: 'VIEW',
          textColor: AppColors.dark,
          onPressed: () {
            // 2. Scroll to My Spaces section and highlight the new space
            _scrollToMySpacesSection(context);
          },
        ),
      ),
    );
  }
  
  // Scroll to the My Spaces section after joining
  void _scrollToMySpacesSection(BuildContext context) {
    try {
      // Find the nearest scrollable ancestor
      final scrollController = PrimaryScrollController.of(context);
      if (scrollController != null && scrollController.hasClients) {
        // Scroll to the top where My Spaces are located
        scrollController.animateTo(
          0, // Scroll to top
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutQuad,
        );
        
        // Wait a short time to ensure the scroll has happened
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) {
            // Flash the My Spaces section to highlight it
            _flashMySpacesSection();
          }
        });
      }
    } catch (e) {
      debugPrint('Error scrolling to My Spaces: $e');
      // Don't show error to user - non-critical UI enhancement
    }
  }
  
  // Make the My Spaces section flash briefly to draw attention
  void _flashMySpacesSection() {
    if (_isFlashingMySpaces) return;
    _isFlashingMySpaces = true;
    
    try {
      // My Spaces list is already available through the static key
      final mySpacesList = SpacesPage.mySpacesListKey.currentContext?.findRenderObject();
      if (mySpacesList == null) {
        _isFlashingMySpaces = false;
        return;
      }
      
      // Find nearest ancestor that can showOverlay
      final BuildContext? overlayContext = _cardKey.currentContext;
      if (overlayContext == null) {
        _isFlashingMySpaces = false;
        return;
      }
      
      final overlay = Overlay.of(overlayContext);
      late OverlayEntry overlayEntry;
      
            overlayEntry = OverlayEntry(
        builder: (context) {
          try {
            // Convert render object position to global position
            final RenderBox box = mySpacesList as RenderBox;
            final position = box.localToGlobal(Offset.zero);
            
            return Positioned(
              left: position.dx,
              top: position.dy,
              width: box.size.width,
              height: box.size.height,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  // Create a fading gold highlight effect
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: AppColors.gold.withOpacity(0.7 * (1.0 - value)),
                        width: 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withOpacity(0.4 * (1.0 - value)),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  );
                },
                onEnd: () {
                  // Remove the overlay when animation completes
                  overlayEntry.remove();
                  _isFlashingMySpaces = false;
                },
              ),
            );
          } catch (e) {
            // Return an empty widget if there's an error
            debugPrint('Error in flash overlay builder: $e');
            Future.microtask(() {
              overlayEntry.remove();
              _isFlashingMySpaces = false;
            });
            return const SizedBox.shrink();
          }
        },
      );
      
      // Add the highlight overlay
      overlay.insert(overlayEntry);
    } catch (e) {
      debugPrint('Error flashing My Spaces section: $e');
      _isFlashingMySpaces = false;
    }
  }

  // REVISED: Direct Firestore update approach to avoid Firestore settings issues
  Future<void> _handleJoinSpace() async {
    // Skip if already joining, already joined, or just joined
    if (_isJoining || widget.spaceEntity.isJoined || _justJoined) return;

    try {
      // 1. Start visual feedback
      HapticFeedback.lightImpact();
      setState(() {
        _isJoining = true;
      });
      
      if (_glowController != null) {
        _glowController!.forward();
      }

      // 2. Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User must be logged in to join a space');
      }

      final spaceId = widget.spaceEntity.id;
      final userId = user.uid;
      
      // Track start time for optimistic UI updates
      final startTime = DateTime.now();

      // 3. Join the space directly with Firebase - avoid provider which causes settings issues
      try {
        // First, update user's followedSpaces (this is the key operation)
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'followedSpaces': FieldValue.arrayUnion([spaceId]),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Success guaranteed at this point - update UI optimistically while background operations complete
        if (mounted) {
        setState(() {
            _isJoining = false;
            _justJoined = true;
          });
          
          // Show success animation immediately
          _performSuccessAnimation(context, _getSpaceIcon(widget.spaceEntity));
          
          // Fade out glow effect
          if (_glowController != null) {
            _glowController!.reverse();
          }
          
          // Invalidate user spaces provider to refresh the data
          ref.invalidate(user_providers.userSpacesProvider);
        }

        // Continue with background operations (not blocking the UI)
        try {
          // Update the space's member count
          final spaceQuery = await FirebaseFirestore.instance
              .collectionGroup('spaces')
              .where('id', isEqualTo: spaceId)
              .limit(1)
              .get();

          if (spaceQuery.docs.isNotEmpty) {
            final spaceRef = spaceQuery.docs.first.reference;
            await spaceRef.update({
              'metrics.memberCount': FieldValue.increment(1),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        } catch (backgroundError) {
          // Log background errors but don't affect the user experience
          debugPrint('Background operation error (non-critical): $backgroundError');
        }
      } catch (e) {
        // Only show error UI if we're still mounted
      if (mounted) {
        setState(() {
          _isJoining = false;
          _justJoined = false;
        });
          
          if (_glowController != null) {
            _glowController!.reverse();
          }
          
          // Show error message with retry option
          ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
                  Expanded(
                    child: Text('Could not join ${widget.spaceEntity.name}'),
            ),
          ],
        ),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'RETRY',
                textColor: Colors.white,
                onPressed: () {
                  // Retry joining
                  if (mounted) {
                    _handleJoinSpace();
                  }
                },
              ),
            )
          );
        }
        
        // Re-throw to be caught by the outer try-catch
        rethrow;
      }
    } catch (e) {
      debugPrint('Error in join space flow: $e');
      
      // Recovery - make sure UI is in the correct state
      if (mounted) {
        setState(() {
          _isJoining = false;
          _justJoined = false;
        });
        
        if (_glowController != null) {
          _glowController!.reverse();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the specific space's joined status from the provider if possible.
    // For now, rely on initial widget state and local _justJoined flag.
    // A more robust solution involves watching a provider for the specific space ID.
    final bool isJoined = widget.spaceEntity.isJoined || _justJoined;

    // --- Determine Background Color ---
    final Color cardColor = widget.index % 2 == 0
        ? AppColors.dark2 // #1E1E1E
        : AppColors.dark3; // Use the new darker color #252525 (ensure defined in AppColors)

    // --- Get Icon ---
    final IconData iconData = _getSpaceIcon(widget.spaceEntity);

    // --- Build Subtitle ---
    final Widget subtitleWidget = _buildSubtitle(widget.spaceEntity);

    return GestureDetector(
      key: _cardKey, // --- Assign key to the GestureDetector ---
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onLongPress: _handleLongPress,
      child: ScaleTransition(
        // Use null-aware access with default value
        scale: _scaleAnimation ?? kAlwaysCompleteAnimation,
        // --- Add AnimatedBuilder for Glow ---
        child: AnimatedBuilder(
          // Use null-aware access with default value (a stopped animation)
          animation: _glowAnimation ?? kAlwaysDismissedAnimation,
          builder: (context, child) {
            // Get value safely, defaulting to 0.0 if animation is null
            final glowValue = _glowAnimation?.value ?? 0.0;
            final glowColor = AppColors.gold.withOpacity(0.4 * glowValue); // Gold glow as requested
            final glowRadius = 8.0 * glowValue;

            return Container(
              margin: const EdgeInsets.only(bottom: 12.0), // spacing-sm
              decoration: BoxDecoration(
                 borderRadius: BorderRadius.circular(8.0), // Match card radius
                 boxShadow: glowValue > 0.01 ? // Avoid rendering tiny shadows
                 [
                   BoxShadow(
                     color: glowColor,
                     blurRadius: glowRadius,
                     spreadRadius: 1.0 * glowValue,
                   ),
                 ] : null,
              ),
              child: child, // The Card goes here
            );
          },
          // --- END NEW ---
          child: Card(
            color: cardColor, // Use alternating color
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)), // radius-md
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            elevation: 0, // Rely on color difference, not elevation
            child: Padding(
              padding: const EdgeInsets.all(16.0), // spacing-md
              child: Row(
                children: [
                  // --- Icon Avatar ---
                  CircleAvatar(
                    radius: 24, // Standard size
                    backgroundColor: cardColor == AppColors.dark2 ? AppColors.dark3 : AppColors.dark2, // Contrast background slightly
                    child: Icon(iconData, color: AppColors.white, size: 22),
                  ),
                  const SizedBox(width: 16.0), // spacing-md
                  // --- Text Content ---
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          widget.spaceEntity.name,
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.white, letterSpacing: 0.2),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4.0), // spacing-xxs
                        // Subtitle (using helper)
                        subtitleWidget,
                      ],
                    ),
                  ),
                  // --- NEW: Join Button / Indicator ---
                  const SizedBox(width: 12.0), // spacing-sm between text and button
                  _buildJoinButton(isJoined), // Pass calculated joined status
                  // --- END NEW ---
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- NEW: Helper to build the join button/indicator ---
  Widget _buildJoinButton(bool isJoined) {
    const double buttonSize = 36.0; // Consistent size for the button area
    final Color buttonBackgroundColor = AppColors.dark3; // Or determine based on card bg

    // --- NEW: Use AnimatedSwitcher ---
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200), // Fade duration for '+' -> loading / check
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: _buildButtonContent(isJoined, buttonSize, buttonBackgroundColor), // Use helper for content
    );
    // --- END NEW ---
  }

  // --- NEW: Helper for AnimatedSwitcher content ---
  Widget _buildButtonContent(bool isJoined, double buttonSize, Color buttonBackgroundColor) {
     // Use ValueKey for proper AnimatedSwitcher transitions
     if (_isJoining) {
      return SizedBox(
        key: const ValueKey('loading'), // Key for loading state
        width: buttonSize,
        height: buttonSize,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
            ),
          ),
        ),
      );
    } else if (isJoined) {
      return SizedBox(
        key: const ValueKey('check'), // Key for check state
        width: buttonSize,
        height: buttonSize,
        child: Center(
          child: Icon(
            PhosphorIcons.check(),
            color: AppColors.success, 
            size: 20,
          ),
        ),
      );
    } else {
      return Material(
         key: const ValueKey('plus'), // Key for plus state
         color: Colors.transparent, // Make background transparent, rely on InkWell splash
         borderRadius: BorderRadius.circular(buttonSize / 2), 
         child: InkWell(
           onTap: _handleJoinSpace, 
           borderRadius: BorderRadius.circular(buttonSize / 2),
           splashColor: AppColors.gold.withOpacity(0.3),
           highlightColor: AppColors.gold.withOpacity(0.1),
           child: SizedBox(
             width: buttonSize,
             height: buttonSize,
             child: Center(
               child: Icon(
                 PhosphorIcons.plus(),
                 color: AppColors.white,
                 size: 20,
               ),
             ),
           ),
         ),
       );
    }
  }
  // --- END NEW ---
}

// NEW StatefulWidget for My Spaces Circle Item
class MySpaceCircleItem extends ConsumerStatefulWidget {
  final String type;
  final String label;
  final String? details;
  final String? imageUrl;
  final bool selected;
  final bool showCreateHighlight;
  final entities.SpaceEntity? spaceEntity;
  // --- NEW: Flag for newly joined space ---
  final bool isNewlyJoined;

  const MySpaceCircleItem({
    super.key,
    required this.type,
    required this.label,
    this.details,
    this.imageUrl,
    required this.selected,
    required this.showCreateHighlight,
    this.spaceEntity,
    // --- NEW: Default to false ---
    this.isNewlyJoined = false,
  });

  @override
  ConsumerState<MySpaceCircleItem> createState() => _MySpaceCircleItemState();
}

// Changed to ConsumerState
class _MySpaceCircleItemState extends ConsumerState<MySpaceCircleItem> with TickerProviderStateMixin {
  late AnimationController _tapController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;

  // Controller and Animation for the highlight pulse - MAKE NULLABLE
  AnimationController? _highlightController;
  Animation<double>? _highlightOpacityAnimation;
  
  // --- NEW: Controller for newly joined effect ---
  AnimationController? _newlyJoinedController;
  Animation<double>? _newlyJoinedOpacityAnimation;
  Animation<double>? _newlyJoinedScaleAnimation;
  // --- END NEW ---

  bool get isCreateButton => widget.type == 'create';
  static const double circleRadius = 36.0;
  static const double horizontalPadding = 8.0;

  @override
  void initState() {
    super.initState();
    // Tap Animation Controller
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeOut, reverseCurve: Curves.elasticOut),
    );
    _shadowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeOut, reverseCurve: Curves.easeIn),
    );

    // --- Initialize Highlight Animation Controller ONLY if needed ---
    if (widget.showCreateHighlight) {
      _highlightController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
      );
      _highlightOpacityAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _highlightController!, curve: Curves.easeInOut),
      );
      _highlightController!.repeat(reverse: true);
    }
    
    // --- NEW: Initialize Newly Joined Animation ---
    if (widget.isNewlyJoined) {
      _newlyJoinedController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000), // Slightly shorter duration
      );
      
      // Enhanced Opacity (fade in faster, hold, fade out slower)
      _newlyJoinedOpacityAnimation = TweenSequence<double>([
        TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.9).chain(CurveTween(curve: Curves.easeOut)), weight: 15),
        TweenSequenceItem(tween: ConstantTween<double>(0.9), weight: 50), // Hold peak opacity
        TweenSequenceItem(tween: Tween<double>(begin: 0.9, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 35),
      ]).animate(_newlyJoinedController!);
      
      // Enhanced Scale (Subtle pulse out then settle)
      _newlyJoinedScaleAnimation = TweenSequence<double>([
        TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.2).chain(CurveTween(curve: Curves.easeOutBack)), weight: 25),
        TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 75),
      ]).animate(_newlyJoinedController!);
      
      // Start the animation
      _newlyJoinedController!.forward();
    }
    // --- END NEW ---
  }

  @override
  void dispose() {
    _tapController.dispose();
    // Check for null before disposing controllers
    _highlightController?.dispose();
    _newlyJoinedController?.dispose(); // Dispose new controller
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) { _tapController.forward(); }
  void _handleTapUp(TapUpDetails details) {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) { _tapController.reverse(); }
    });
    HapticFeedback.lightImpact();
    if (widget.spaceEntity != null) {
       print('Tapped on space: ${widget.spaceEntity!.name} (ID: ${widget.spaceEntity!.id})');
       // --- NAVIGATION UPDATED --- 
       // Use pushNamed with path parameters for both type and id
       final spaceTypeString = _spaceTypeToString(widget.spaceEntity!.spaceType);
       context.pushNamed(
         'space_detail', 
         pathParameters: {
           'type': spaceTypeString, 
           'id': widget.spaceEntity!.id
          },
         extra: widget.spaceEntity!.toSpace() // Pass the Space object if needed
       );
       // --- END NAVIGATION --- 
    } else if (widget.type == 'create') {
       print('Tapped on Create Space - Navigating');
       // Navigate to create space page (uses absolute path or named route)
       context.push(AppRoutes.createSpace); // Assuming this works or use context.pushNamed if needed
    }
  }
  void _handleTapCancel() {
    if (mounted) { _tapController.reverse(); }
  }

  @override
  Widget build(BuildContext context) {
    // --- UPDATED: Use the helper method to get the icon --- 
    IconData iconData = _getIcon();
    // --- END UPDATED ---

    double iconSize = isCreateButton ? 34 : 30;

    // --- Build Base Circle --- 
    Widget baseCircle = AnimatedBuilder(
       animation: _tapController,
       builder: (context, child) {
         // Calculate shadow opacity safely
         final double shadowAnimValue = _shadowAnimation.value;
         final shadowOpacity = 0.3 + (shadowAnimValue * 0.2);
         final shadowOffsetY = 3.0 + (shadowAnimValue * 1.0);

         return Container(
            width: circleRadius * 2,
            height: circleRadius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  isCreateButton ? AppColors.grey800 : AppColors.grey700.withOpacity(0.8),
                  isCreateButton ? AppColors.dark2 : AppColors.grey800,
                ],
                center: const Alignment(0.0, -0.2),
                radius: 0.9,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(shadowOpacity),
                  blurRadius: 10.0,
                  spreadRadius: 0.0,
                  offset: Offset(0, shadowOffsetY),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.08),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.6],
                    ),
                  ),
                ),
                Icon(
                  iconData,
                  color: isCreateButton ? AppColors.textSecondary : AppColors.white,
                  size: iconSize,
                ),
              ],
            ),
          );
       }
    );

    // Apply selection glow (if selected)
    if (widget.selected) {
      baseCircle = Container(
        width: circleRadius * 2, height: circleRadius * 2,
        decoration: BoxDecoration(
           shape: BoxShape.circle,
           gradient: RadialGradient(
             colors: [AppColors.gold.withOpacity(0.15), AppColors.gold.withOpacity(0.0)],
             stops: const [0.3, 1.0],
           ),
        ),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.gold, width: 2.0),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withOpacity(0.4),
                blurRadius: 10.0,
                spreadRadius: 1.0,
              ),
            ],
          ),
          child: baseCircle,
        ),
      );
    }

    // Apply tap scale animation to the base circle
    Widget finalCircleWidget = ScaleTransition(
      scale: _scaleAnimation,
      child: baseCircle, // Apply scale to the potentially selection-glowed circle
    );

    // --- Conditionally Apply Highlight Pulse Border --- 
    // Check if highlight should be shown AND if the controller/animation are initialized
    if (widget.showCreateHighlight && _highlightController != null && _highlightOpacityAnimation != null) {
      // If highlight is active, wrap the scaled circle with the AnimatedBuilder
      finalCircleWidget = AnimatedBuilder(
        animation: _highlightOpacityAnimation!, // Safe to use ! here due to the check above
        builder: (context, child) {
          // Use the animation value directly
          final highlightOpacity = _highlightOpacityAnimation!.value;
          return Container(
            padding: const EdgeInsets.all(2.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.gold.withOpacity(highlightOpacity),
                width: 2.0,
              ),
              boxShadow: [
                 BoxShadow(
                   color: AppColors.gold.withOpacity(highlightOpacity * 0.3),
                   blurRadius: 6.0,
                   spreadRadius: 1.0,
                 ),
              ]
            ),
            // The child is the result from the previous step (ScaleTransition)
            child: child, 
          );
        },
        // Pass the potentially scaled circle as the child to the builder
        child: finalCircleWidget, 
      );
    } 
    // If not highlighting, finalCircleWidget remains the ScaleTransition widget
    // --- END Conditional Highlight Pulse Border ---

    // --- NEW: Apply Newly Joined Effect ---
    if (widget.isNewlyJoined && _newlyJoinedController != null && _newlyJoinedOpacityAnimation != null) {
      finalCircleWidget = AnimatedBuilder(
        animation: _newlyJoinedController!,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(2.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.gold.withOpacity(_newlyJoinedOpacityAnimation!.value),
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withOpacity(_newlyJoinedOpacityAnimation!.value * 0.5),
                  blurRadius: 8.0,
                  spreadRadius: 2.0,
                ),
              ],
            ),
            child: Transform.scale(
              // Apply the scale animation
              scale: _newlyJoinedScaleAnimation?.value ?? 1.0,
              child: child,
            ),
          );
        },
        child: finalCircleWidget,
      );
    }
    // --- END NEW ---

    String? displayDetails = widget.details?.toLowerCase();
    // --- NEW: Add "Just joined" label for newly joined spaces ---
    if (widget.isNewlyJoined && displayDetails == null) {
      displayDetails = '● just joined';
    }
    // --- END NEW ---
    
    bool isBadge = false;
    if (displayDetails != null) {
        isBadge = displayDetails.contains('drop') ?? false;
        if (isBadge) {
          final match = RegExp(r'(\d+)').firstMatch(displayDetails);
          if (match != null) { displayDetails = '● ${match.group(1)} new'; }
          else { displayDetails = '● new'; }
        }
    }

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: SizedBox(
          width: (circleRadius * 2) + (horizontalPadding * 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              finalCircleWidget,
              const SizedBox(height: 6.0),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.selected ? AppColors.textPrimary : AppColors.textSecondary,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (displayDetails != null) ...[
                Text(
                  displayDetails,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gold,
                    letterSpacing: 0.1,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --- NEW: Helper to get the icon consistently ---
  IconData _getIcon() {
    // Special case for the "Create Space" button
    if (isCreateButton) {
      return PhosphorIcons.plus();
    }
    
    // 1. Prioritize iconCodePoint from the entity if available and valid
    if (widget.spaceEntity?.iconCodePoint != null && widget.spaceEntity!.iconCodePoint > 0) {
      // Ensure the font family matches where the codepoint is defined
      // Assuming MaterialIcons for now, adjust if different
      return IconData(widget.spaceEntity!.iconCodePoint, fontFamily: 'MaterialIcons');
    }
    
    // 2. Fallback based on SpaceType from the entity
    if (widget.spaceEntity?.spaceType != null) {
      switch (widget.spaceEntity!.spaceType) {
        case entities.SpaceType.studentOrg:
          return PhosphorIcons.users(); 
        case entities.SpaceType.universityOrg:
          return PhosphorIcons.buildings(); 
        case entities.SpaceType.campusLiving:
          return PhosphorIcons.house(); 
        case entities.SpaceType.fraternityAndSorority:
          return PhosphorIcons.usersThree(); 
        case entities.SpaceType.hiveExclusive:
          return PhosphorIcons.crownSimple(); 
        case entities.SpaceType.other:
        default:
          return PhosphorIcons.circlesFour(); 
      }
    }
    
    // 3. Final fallback if no entity or type is available
    return PhosphorIcons.circlesFour();
  }
  // --- END NEW ---
}

// Update ShimmerDiscoverCard to accept index for potential alternating shimmer
class ShimmerDiscoverCard extends StatelessWidget {
  final int index;
  const ShimmerDiscoverCard({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
     // Use index to potentially alternate shimmer base color slightly
     final Color baseColor = index % 2 == 0 ? AppColors.dark2 : AppColors.dark3;
     final Color highlightColor = index % 2 == 0 ? AppColors.grey800 : AppColors.grey700;

    // TODO: Wrap with actual Shimmer widget from shimmer package
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Card(
        color: baseColor, // Use alternating base color
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(radius: 24, backgroundColor: highlightColor), // Use highlight color
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 16, width: 150, color: highlightColor), // Use highlight color
                    const SizedBox(height: 8.0),
                    Container(height: 12, width: 100, color: highlightColor), // Use highlight color
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ############################################################################
// # Space Summoning Animation Widget
// ############################################################################

class SpaceSummonAnimation extends StatefulWidget {
  final Offset startPosition;
  final Offset endPosition;
  final IconData iconData;
  final VoidCallback onComplete;
  // Add the initial small size of the circle in the My Spaces list
  final double targetCircleRadius = _mySpaceCircleRadius; 

  const SpaceSummonAnimation({
    super.key,
    required this.startPosition,
    required this.endPosition,
    required this.iconData,
    required this.onComplete,
  });

  @override
  State<SpaceSummonAnimation> createState() => _SpaceSummonAnimationState();
}

class _SpaceSummonAnimationState extends State<SpaceSummonAnimation> with SingleTickerProviderStateMixin {
  // Make controller nullable
  AnimationController? _controller;
  Animation<Offset>? _positionAnimation;
  Animation<double>? _scaleAnimation;
  Animation<double>? _opacityAnimation; // For fade in/out

  // Define animation timings based on spec
  final Duration _travelDuration = const Duration(milliseconds: 400);
  final Duration _scaleBounceDuration = const Duration(milliseconds: 150);
  // Total duration needs to accommodate both phases
  Duration get _totalDuration => Duration(milliseconds: _travelDuration.inMilliseconds + _scaleBounceDuration.inMilliseconds);

  @override
  void initState() {
    super.initState();

    try {
      _controller = AnimationController(
        vsync: this,
        duration: _totalDuration,
      );

      // Calculate the actual target size based on the MySpaceCircleItem radius
      final double targetSize = widget.targetCircleRadius * 2;

      // --- Position Animation --- 
      // Simple linear movement for now
      _positionAnimation = Tween<Offset>(
        begin: widget.startPosition,
        end: widget.endPosition,
      ).animate(CurvedAnimation(
        parent: _controller!,
        // Animate position primarily during the travel phase
        curve: Interval(0.0, _travelDuration.inMilliseconds / _totalDuration.inMilliseconds, curve: Curves.easeInOut),
      ));

      // --- Scale Animation --- 
      // Spec: 0.3x -> 1.1x (relative to final size) -> 1.0x
      // We animate scale during the latter part of travel and the bounce phase
      _scaleAnimation = TweenSequence<double>([
         // Start small (0.3x of target size)
         TweenSequenceItem(tween: Tween<double>(begin: 0.3, end: 0.3), weight: 0.1), 
         // Scale up to 1.1x during travel
         TweenSequenceItem(
           tween: Tween<double>(begin: 0.3, end: 1.1),
           weight: (_travelDuration.inMilliseconds / _totalDuration.inMilliseconds * 0.9), // Most of travel duration
         ),
         // Bounce back to 1.0x during the final phase
         TweenSequenceItem(
           tween: Tween<double>(begin: 1.1, end: 1.0),
           weight: (_scaleBounceDuration.inMilliseconds / _totalDuration.inMilliseconds), // Bounce duration
         ),
      ]).animate(CurvedAnimation(
        parent: _controller!,
        curve: Curves.elasticOut, // Apply an elastic curve for the bounce feel overall
      ));

      // --- Opacity Animation --- 
      // Fade in quickly, stay visible, could fade out if needed
      _opacityAnimation = TweenSequence<double>([
        TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 0.1), // Fade in
        TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.0), weight: 0.9), // Stay visible
      ]).animate(_controller!);

      // Add listener to remove overlay when done
      _controller!.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete();
        }
      });

      // Start the animation
      _controller!.forward();
    } catch (e) {
      print('Error initializing SpaceSummonAnimation: $e');
      // Make sure we still call onComplete even if animation setup fails
      // This ensures the overlay gets removed
      Future.microtask(() => widget.onComplete());
    }
  }

  @override
  void dispose() {
    // Safely dispose
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If animation setup failed, show nothing but still allow onComplete to be called
    if (_controller == null || 
        _positionAnimation == null || 
        _scaleAnimation == null || 
        _opacityAnimation == null) {
      return const SizedBox.shrink();
    }
    
    return AnimatedBuilder(
      animation: _controller!,
      builder: (context, child) {
        try {
          // Calculate the current size based on scale animation
          final double currentSize = (widget.targetCircleRadius * 2) * (_scaleAnimation?.value ?? 0.3);
          // Adjust position based on current size to keep it centered
          final Offset currentPosition = (_positionAnimation?.value ?? widget.startPosition) - 
              Offset(currentSize / 2, currentSize / 2);
          
          return Positioned(
            left: currentPosition.dx,
            top: currentPosition.dy,
            child: Opacity(
              opacity: _opacityAnimation?.value ?? 0.0,
              child: Container(
                 width: currentSize,
                 height: currentSize,
                 decoration: BoxDecoration(
                   shape: BoxShape.circle,
                   color: AppColors.gold.withOpacity(0.8), // Gold glowing dot
                   boxShadow: [
                     BoxShadow(
                       color: AppColors.gold.withOpacity(0.5 * (_opacityAnimation?.value ?? 0.0)),
                       blurRadius: 8.0 * (_scaleAnimation?.value ?? 0.3),
                       spreadRadius: 2.0 * (_scaleAnimation?.value ?? 0.3),
                     ),
                   ],
                 ),
                 child: Center(
                   child: Icon(
                     widget.iconData,
                     // Scale icon slightly smaller than the container
                     size: currentSize * 0.5,
                     color: AppColors.dark.withOpacity(0.8), // Icon color on gold bg
                   ),
                 ),
              ),
            ),
          );
        } catch (e) {
          print('Error in SpaceSummonAnimation build: $e');
          // Return empty widget if there's an error during build
          return const SizedBox.shrink();
        }
      },
    );
  }
}

// Helper function to convert SpaceType enum to the string used in routes/paths
String _spaceTypeToString(entities.SpaceType type) {
  switch (type) {
    case entities.SpaceType.studentOrg:
      return 'student_organizations'; // Match Firestore path
    case entities.SpaceType.universityOrg:
      return 'university_organizations'; // Match Firestore path
    case entities.SpaceType.campusLiving:
      return 'campus_living';
    case entities.SpaceType.fraternityAndSorority:
      return 'fraternity_and_sorority';
    case entities.SpaceType.hiveExclusive:
      return 'hive_exclusive';
    case entities.SpaceType.other:
    default:
      return 'other';
  }
}

// ... rest of spaces_page.dart ...

