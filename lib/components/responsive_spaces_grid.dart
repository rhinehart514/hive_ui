import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/models/space.dart';
import 'package:hive_ui/providers/space_providers.dart';
import 'package:hive_ui/features/spaces/presentation/providers/space_providers.dart';

class ResponsiveSpacesGrid extends ConsumerStatefulWidget {
  final Function(dynamic) onSpaceTapped;
  final VoidCallback onSpaceAdded;
  final String? searchQuery;
  final bool showSortControls;
  final Function?
      noSpacesCallback; // Callback to show custom empty state with debugging

  const ResponsiveSpacesGrid({
    super.key,
    required this.onSpaceTapped,
    required this.onSpaceAdded,
    this.searchQuery,
    this.showSortControls = false,
    this.noSpacesCallback,
  });

  @override
  ConsumerState<ResponsiveSpacesGrid> createState() =>
      _ResponsiveSpacesGridState();
}

class _ResponsiveSpacesGridState extends ConsumerState<ResponsiveSpacesGrid> {
  late ScrollController _scrollController;
  bool _isLoadingMore = false;
  int _lastCrossAxisCount = 4; // Default
  bool _hasCalledEmptyCallback = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  // Scroll listener for infinite scrolling
  void _scrollListener() {
    // Check if we're near the bottom of the scroll view
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      _loadMoreItems();
    }
  }

  // Load more items
  Future<void> _loadMoreItems() async {
    final state = ref.read(paginatedSpacesProvider);

    // Don't load more if already loading, no more items, or no search
    if (_isLoadingMore || !state.hasMore || state.isLoading) {
      return;
    }

    // Set loading flag and load more
    setState(() => _isLoadingMore = true);
    await ref.read(paginatedSpacesProvider.notifier).loadMore();
    setState(() => _isLoadingMore = false);
  }

  // Calculate the cross-axis count based on screen width
  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < 480) return 1; // Small mobile - single column
    if (width < 600) return 2; // Mobile
    if (width < 900) return 3; // Tablet
    if (width < 1200) return 4; // Small desktop
    return 6; // Large desktop - reduced from 8 for better UI density
  }

  // Refresh the grid
  Future<void> _refresh() async {
    await ref.read(paginatedSpacesProvider.notifier).refresh();
  }

  // Change the sort method
  void _changeSortMethod(String sortBy, bool descending) {
    ref
        .read(paginatedSpacesProvider.notifier)
        .setSortOptions(sortBy, descending);
  }

  @override
  Widget build(BuildContext context) {
    // Get the spaces from the provider
    final spacesState = ref.watch(paginatedSpacesProvider);

    // Calculate responsive grid parameters
    final crossAxisCount = _getCrossAxisCount(context);
    // If cross axis count changed, we need to recalculate layout
    if (crossAxisCount != _lastCrossAxisCount) {
      _lastCrossAxisCount = crossAxisCount;
      // Add a microtask to rebuild after layout
      Future.microtask(() => setState(() {}));
    }

    // Filter spaces if search query is provided
    List<Space> filteredSpaces = spacesState.spaces;
    if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
      filteredSpaces = filteredSpaces
          .where((space) => space.name
              .toLowerCase()
              .contains(widget.searchQuery!.toLowerCase()))
          .toList();
    }

    // Handle empty spaces list
    if (filteredSpaces.isEmpty && !spacesState.isLoading) {
      if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No spaces found matching "${widget.searchQuery}"',
                style: TextStyle(color: Colors.grey[300]),
              ),
            ],
          ),
        );
      } else {
        if (!_hasCalledEmptyCallback && widget.noSpacesCallback != null) {
          // Call empty callback once
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.noSpacesCallback!();
            setState(() {
              _hasCalledEmptyCallback = true;
            });
          });
        }
        return const Center(
          child: Text(
            'No spaces available',
            style: TextStyle(color: Colors.white),
          ),
        );
      }
    }

    // Reset flag if we have spaces again
    if (filteredSpaces.isNotEmpty) {
      _hasCalledEmptyCallback = false;
    }

    // Build the grid with refresh indicator for pull-to-refresh
    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.gold,
      backgroundColor: Colors.grey[900],
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Optional sort controls
          if (widget.showSortControls)
            _buildSortControls(spacesState.sortBy, spacesState.sortDescending),

          // Main grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: _buildSpacesGrid(filteredSpaces, crossAxisCount),
          ),

          // Loading indicator at bottom
          if (spacesState.isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                  ),
                ),
              ),
            ),

          // Error message if any
          if (spacesState.error != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  spacesState.error!,
                  style: GoogleFonts.inter(
                    color: Colors.red[300],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // End of list message
          if (!spacesState.hasMore &&
              !spacesState.isLoading &&
              filteredSpaces.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'No more spaces to display',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // Empty list message for search results
          if (filteredSpaces.isEmpty &&
              widget.searchQuery != null &&
              widget.searchQuery!.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildEmptyState(context),
            ),

          // Bottom padding for FAB
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  // Build sorting controls
  Widget _buildSortControls(String currentSortBy, bool currentSortDescending) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Text(
              'Sort by:',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 12),
            _buildSortButton(
              'Most Members',
              currentSortBy == 'memberCount' && currentSortDescending,
              () => _changeSortMethod('memberCount', true),
            ),
            const SizedBox(width: 8),
            _buildSortButton(
              'Alphabetical',
              currentSortBy == 'name' && !currentSortDescending,
              () => _changeSortMethod('name', false),
            ),
          ],
        ),
      ),
    );
  }

  // Build sort option button
  Widget _buildSortButton(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.gold : Colors.grey[800],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isActive ? Colors.black : Colors.white70,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // Build the staggered grid of spaces
  Widget _buildSpacesGrid(List<Space> spaces, int crossAxisCount) {
    if (spaces.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text(
              'No spaces available',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    }

    // Distribute sizes based on popularity/engagement with improved spacing
    return SliverMasonryGrid.count(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childCount: spaces.length,
      itemBuilder: (context, index) {
        final space = spaces[index];

        // Optimize card size distribution for better visual flow
        // Limit the number of special-sized cards based on cross axis count
        final isFeatured =
            space.metrics.memberCount > 100 || space.metrics.isTrending;
        final isLarge =
            index == 0 && isFeatured; // Only the first featured space is large
        final isMedium = crossAxisCount >
                1 && // Only use medium cards in multi-column layouts
            ((index % 7 == 0 && index > 0) || (isFeatured && index % 5 == 0)) &&
            !isLarge;

        if (isLarge && crossAxisCount > 1) {
          // Large cards only in multi-column layouts
          return _buildLargeSpaceCard(space);
        } else if (isMedium) {
          return _buildMediumSpaceCard(space);
        } else {
          return _buildSmallSpaceCard(space);
        }
      },
    );
  }

  // Large space card (2x2) - optimized padding and spacing
  Widget _buildLargeSpaceCard(Space space) {
    return Container(
      key: Key('space-large-${space.id}'),
      margin: const EdgeInsets.all(4.0), // Reduced margin
      child: GestureDetector(
        onTap: () => widget.onSpaceTapped(space),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.black,
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            image: (space.imageUrl != null && space.imageUrl!.isNotEmpty)
                ? DecorationImage(
                    image: NetworkImage(space.imageUrl!),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.6),
                      BlendMode.darken,
                    ),
                  )
                : null,
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0), // Reduced padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and metrics
                    Text(
                      space.name,
                      style: GoogleFonts.outfit(
                        fontSize: 20, // Reduced font size
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8), // Reduced spacing

                    // Description
                    if (space.description.isNotEmpty)
                      Text(
                        space.description,
                        style: GoogleFonts.inter(
                          fontSize: 13, // Reduced font size
                          color: Colors.white70,
                        ),
                        maxLines: 2, // Reduced max lines
                        overflow: TextOverflow.ellipsis,
                      ),

                    const Spacer(),

                    // Member count
                    Row(
                      children: [
                        const Icon(
                          Icons.people,
                          color: Colors.white70,
                          size: 14, // Reduced icon size
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${space.metrics.memberCount} members',
                          style: GoogleFonts.inter(
                            fontSize: 12, // Reduced font size
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Join/leave button
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    _handleJoinToggle(space);
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: space.isJoined
                          ? Colors.white.withOpacity(0.2)
                          : AppColors.gold,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      space.isJoined ? 'Joined' : 'Join',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: space.isJoined ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
              ),

              // New badge if created recently
              if (_isNewSpace(space))
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              // Trending badge if highly active
              if (_isTrendingSpace(space))
                Positioned(
                  top: _isNewSpace(space) ? 48 : 16,
                  left: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.trending_up,
                          size: 10,
                          color: Colors.white,
                        ),
                        SizedBox(width: 2),
                        Text(
                          'TRENDING',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
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

  // Medium space card (2x1 or 1x2) - optimized
  Widget _buildMediumSpaceCard(Space space) {
    return Container(
      key: Key('space-medium-${space.id}'),
      margin: const EdgeInsets.all(4.0), // Reduced margin
      child: GestureDetector(
        onTap: () => widget.onSpaceTapped(space),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[900],
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header image with optimized aspect ratio
              if (space.imageUrl != null && space.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      space.imageUrl!,
                      fit: BoxFit.cover,
                      cacheWidth: 300, // Add width for caching optimization
                    ),
                  ),
                ),

              // Content with optimized padding
              Padding(
                padding: const EdgeInsets.all(12.0), // Reduced padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      space.name,
                      style: GoogleFonts.outfit(
                        fontSize: 16, // Reduced font size
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4), // Consistent spacing
                    Text(
                      '${space.metrics.memberCount} members',
                      style: GoogleFonts.inter(
                        fontSize: 12, // Reduced font size
                        color: Colors.white70,
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

  // Small space card (1x1) - optimized
  Widget _buildSmallSpaceCard(Space space) {
    return Container(
      key: Key('space-small-${space.id}'),
      margin: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onSpaceTapped(space);
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF1C1C1E),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 0.5,
                  ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
              ),
          child: Padding(
            padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Space icon and name
                Row(
                  children: [
                    Container(
                      height: 32,
                      width: 32,
                      decoration: BoxDecoration(
                        color: space.primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Icon(
                          space.icon,
                          color: space.primaryColor,
                          size: 16,
                        ),
                      ),
                            ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        space.name,
                              style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                          letterSpacing: -0.25,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                const SizedBox(height: 8),
                
                // Member count
                Row(
                  children: [
                    const Icon(
                      Icons.people_outline,
                      size: 14,
                      color: AppColors.textTertiary,
                            ),
                    const SizedBox(width: 4),
                    Text(
                      '${space.metrics.memberCount}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Members',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                        letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
          ),
        ),
      ),
    );
  }

  // Unified join toggle handler with animation
  void _handleJoinToggle(Space space) {
    HapticFeedback.selectionClick();

    if (space.isJoined) {
      // Leave space
      ref.read(toggleSpaceMembershipProvider(space.id));
    } else {
      // Join space with optimistic UI update
      ref.read(toggleSpaceMembershipProvider(space.id));
      widget.onSpaceAdded();
    }
  }

  // Helper method to check if space is new (created in the last 7 days)
  bool _isNewSpace(Space space) {
    final now = DateTime.now();
    final createdAt = space.createdAt;
    final difference = now.difference(createdAt);

    return difference.inDays < 7;
  }

  // Helper method to check if space is trending
  bool _isTrendingSpace(Space space) {
    // Simple example logic - in a real app, you might have more complex metrics
    return space.metrics.memberCount > 100;
  }

  // Empty search state - optimized
  Widget _buildEmptyState(BuildContext context) {
    // Check if this is a debug build
    const bool isDebugMode = true;

    // Handle empty state with debug option when in debug mode
    if (isDebugMode && widget.noSpacesCallback != null) {
      return widget.noSpacesCallback!();
    }

    // Adjust sizing based on screen size
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = screenWidth < 360 ? 48.0 : 64.0;
    final titleSize = screenWidth < 360 ? 18.0 : 20.0;
    final messageSize = screenWidth < 360 ? 14.0 : 16.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: iconSize,
              color: Colors.white.withOpacity(0.5),
            ),
            SizedBox(height: screenWidth < 360 ? 12 : 16),
            Text(
              'No results found',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: titleSize,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            SizedBox(height: screenWidth < 360 ? 6 : 8),
            Text(
              'Try using different keywords or check your filters',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: messageSize,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
