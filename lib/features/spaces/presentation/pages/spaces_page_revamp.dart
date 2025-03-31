import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:auto_route/auto_route.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/features/spaces/presentation/providers/space_providers.dart';
import 'package:hive_ui/features/spaces/presentation/providers/spaces_controller.dart';
import 'package:hive_ui/models/space.dart';
import 'package:hive_ui/models/space_type.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';

@RoutePage()
class SpacesPageRevamp extends ConsumerStatefulWidget {
  const SpacesPageRevamp({super.key});

  @override
  ConsumerState<SpacesPageRevamp> createState() => _SpacesPageRevampState();
}

class _SpacesPageRevampState extends ConsumerState<SpacesPageRevamp>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchExpanded = false;

  // Scroll controllers
  final ScrollController _mainScrollController = ScrollController();
  final ScrollController _categoriesScrollController = ScrollController();
  final ScrollController _mySpacesScrollController = ScrollController();
  final ScrollController _featuredSpacesScrollController = ScrollController();
  final ScrollController _popularSpacesScrollController = ScrollController();

  // Tab controller for explore/my spaces
  late TabController _tabController;

  String _activeCategory = 'All';
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  final int _spacesPerPage = 20;

  // Define space categories
  final List<String> _categories = [
    'All',
    'Student Orgs',
    'Greek Life',
    'Campus Living',
    'University',
  ];

  @override
  void initState() {
    super.initState();

    // Initialize tab controller
    _tabController = TabController(length: 2, vsync: this);

    // Setup scroll controller for pagination
    _mainScrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (!_isLoadingMore &&
        _mainScrollController.position.pixels >=
            _mainScrollController.position.maxScrollExtent * 0.8) {
      _loadMoreSpaces();
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
    _featuredSpacesScrollController.dispose();
    _popularSpacesScrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // Refresh all spaces data
  Future<void> _refreshSpaces() async {
    setState(() {
      _isRefreshing = true;
      _currentPage = 1;
    });

    try {
      ref.refresh(hierarchicalSpacesProvider);
      ref.refresh(userSpacesProvider);
      ref.refresh(trendingSpacesProvider);
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  // Handle space joining
  void _handleJoinSpace(Space space) {
    HapticFeedback.mediumImpact();
    _joinSpaceDirectly(space);
  }

  // Join space directly
  Future<void> _joinSpaceDirectly(Space space) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Text('Adding to My Spaces...', style: GoogleFonts.inter()),
          ],
        ),
        backgroundColor: Colors.black87,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      await ref.read(spacesControllerProvider.notifier).joinSpace(space);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added to My Spaces', style: GoogleFonts.inter()),
            backgroundColor: Colors.green[700],
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join space: ${e.toString()}',
                style: GoogleFonts.inter()),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Navigate to space details
  void _navigateToSpaceDetails(Space space) {
    HapticFeedback.selectionClick();
    final clubId = Uri.encodeComponent(space.id);
    final spaceType = space.spaceType.toString().split('.').last;
    GoRouter.of(context).push('/spaces/club?id=$clubId&type=$spaceType');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: RefreshIndicator(
        backgroundColor: AppColors.cardBackground,
        color: AppColors.yellow,
        onRefresh: _refreshSpaces,
        child: CustomScrollView(
          controller: _mainScrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // App Bar
            SliverAppBar(
              backgroundColor: AppColors.black,
              floating: true,
              pinned: false,
              snap: false,
              title: Text(
                'Spaces',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              actions: [
                // Search button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _isSearchExpanded
                      ? MediaQuery.of(context).size.width - 80
                      : 40,
                  height: 40,
                  child: _isSearchExpanded
                      ? _buildSearchField()
                      : IconButton(
                          icon:
                              const Icon(Icons.search, color: AppColors.white),
                          onPressed: () {
                            setState(() {
                              _isSearchExpanded = true;
                              FocusScope.of(context)
                                  .requestFocus(_searchFocusNode);
                            });
                          },
                        ),
                ),
                const SizedBox(width: 8),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: _buildTabBar(),
              ),
            ),

            // Tab content
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Discover tab
                  _buildDiscoverContent(),

                  // My Spaces tab
                  _buildMySpacesContent(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.black,
        onPressed: () {
          // Provide haptic feedback
          HapticFeedback.mediumImpact();
          
          // Add a small delay to avoid mouse tracking issues during navigation
          Future.microtask(() {
            try {
              // Use context.push instead of GoRouter.of for more reliable navigation
              if (mounted && context.mounted) {
                context.push('/spaces/create');
              }
            } catch (e) {
              debugPrint('Error navigating to create space: $e');
              // Fallback navigation if the above fails
              GoRouter.of(context).push('/spaces/create');
            }
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // Build search field
  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      decoration: InputDecoration(
        hintText: 'Search spaces...',
        hintStyle: GoogleFonts.inter(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.inputBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          icon: const Icon(Icons.close, color: AppColors.white),
          onPressed: () {
            setState(() {
              _isSearchExpanded = false;
              _searchController.clear();
            });
          },
        ),
      ),
      style: GoogleFonts.inter(color: AppColors.white),
    );
  }

  // Build tab bar
  Widget _buildTabBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.yellow,
        labelColor: AppColors.yellow,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Discover'),
          Tab(text: 'My Spaces'),
        ],
      ),
    );
  }

  // Build discover content
  Widget _buildDiscoverContent() {
    return Column(
      children: [
        // Categories
        _buildCategoriesSection(),

        // Main content
        Expanded(
          child: Consumer(
            builder: (context, ref, child) {
              final spacesAsyncValue = ref.watch(hierarchicalSpacesProvider);

              return spacesAsyncValue.when(
                data: (spaces) {
                  if (spaces.isEmpty) {
                    return _buildEmptyState();
                  }

                  return _buildSpaceSections(spaces);
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.yellow),
                ),
                error: (error, stackTrace) => _buildErrorState(error),
              );
            },
          ),
        ),
      ],
    );
  }

  // Build categories section
  Widget _buildCategoriesSection() {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        controller: _categoriesScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isActive = _activeCategory == category;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _activeCategory = category;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.cardHighlight
                    : AppColors.cardBackground,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isActive ? AppColors.yellow : AppColors.cardBorder,
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                category,
                style: GoogleFonts.inter(
                  color: isActive ? AppColors.yellow : AppColors.textSecondary,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Build space sections
  Widget _buildSpaceSections(Map<String, List<Space>> spaces) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        // Featured Spaces
        _buildFeaturedSpacesSection(spaces['featured'] ?? []),

        // Popular Spaces
        _buildPopularSpacesSection(spaces['popular'] ?? []),

        // All Spaces by Category
        ...spaces.entries
            .where((entry) => !['featured', 'popular'].contains(entry.key))
            .map((entry) => _buildSpaceSection(entry.key, entry.value)),
      ],
    );
  }

  // Build featured spaces section
  Widget _buildFeaturedSpacesSection(List<Space> spaces) {
    if (spaces.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            'Featured Spaces',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
        ),
        SizedBox(
          height: 160,
          child: ListView.builder(
            controller: _featuredSpacesScrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: spaces.length,
            itemBuilder: (context, index) {
              final space = spaces[index];

              return _buildHorizontalSpaceCard(
                space,
                width: MediaQuery.of(context).size.width * 0.75,
                height: 160,
                isFeatured: true,
              );
            },
          ),
        ),
      ],
    );
  }

  // Build popular spaces section
  Widget _buildPopularSpacesSection(List<Space> spaces) {
    if (spaces.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            'Popular Spaces',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            controller: _popularSpacesScrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: spaces.length,
            itemBuilder: (context, index) {
              final space = spaces[index];

              return _buildHorizontalSpaceCard(
                space,
                width: MediaQuery.of(context).size.width * 0.6,
                height: 140,
              );
            },
          ),
        ),
      ],
    );
  }

  // Build space section by category
  Widget _buildSpaceSection(String category, List<Space> spaces) {
    if (spaces.isEmpty) return const SizedBox.shrink();

    // Skip if category filtering is active and this isn't the right category
    if (_activeCategory != 'All' &&
        !_categoryMatches(category, _activeCategory)) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            _formatCategoryName(category),
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: spaces.length,
            itemBuilder: (context, index) {
              final space = spaces[index];

              return _buildHorizontalSpaceCard(
                space,
                width: MediaQuery.of(context).size.width * 0.6,
                height: 120,
              );
            },
          ),
        ),
      ],
    );
  }

  // Build horizontal space card
  Widget _buildHorizontalSpaceCard(
    Space space, {
    required double width,
    required double height,
    bool isFeatured = false,
  }) {
    final hasImage = space.imageUrl != null && space.imageUrl!.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      width: width,
      height: height,
      child: GestureDetector(
        onTap: () => _navigateToSpaceDetails(space),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background image
                hasImage
                    ? CachedNetworkImage(
                        imageUrl: space.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppColors.cardBackground,
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.cardBackground,
                          child:
                              const Icon(Icons.error, color: AppColors.error),
                        ),
                      )
                    : Container(color: AppColors.cardBackground),

                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.6),
                        Colors.black.withOpacity(0.9),
                      ],
                      stops: const [0.2, 0.6, 1.0],
                    ),
                  ),
                ),

                // Glass effect
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Space name
                      Text(
                        space.name,
                        style: GoogleFonts.outfit(
                          fontSize: isFeatured ? 18 : 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Space description or metadata
                      const SizedBox(height: 4),
                      Text(
                        space.description,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Join button
                      if (isFeatured && !space.isJoined) ...[
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => _handleJoinSpace(space),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.yellow,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'Join',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Featured badge
                if (isFeatured)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.yellow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Featured',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
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

  // Build my spaces content
  Widget _buildMySpacesContent() {
    return Consumer(
      builder: (context, ref, child) {
        final userSpacesAsync = ref.watch(userSpacesProvider);

        return userSpacesAsync.when(
          data: (userSpaces) {
            if (userSpaces.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.group_outlined,
                        color: AppColors.textSecondary,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Spaces Yet',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Join some spaces to see them here',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          _tabController.animateTo(0); // Switch to discover tab
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.white,
                          foregroundColor: AppColors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Discover Spaces',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              controller: _mySpacesScrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: userSpaces.length,
              itemBuilder: (context, index) {
                final space = userSpaces[index];

                return _buildMySpaceCard(space);
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.yellow),
          ),
          error: (error, stackTrace) => _buildErrorState(error),
        );
      },
    );
  }

  // Build my space card
  Widget _buildMySpaceCard(Space space) {
    final hasImage = space.imageUrl != null && space.imageUrl!.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _navigateToSpaceDetails(space),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.cardBorder,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Space image
              if (hasImage)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: CachedNetworkImage(
                      imageUrl: space.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.cardHighlight,
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.cardHighlight,
                        child: const Icon(Icons.error, color: AppColors.error),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: AppColors.cardHighlight,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: Icon(
                    space.icon,
                    color: AppColors.white,
                    size: 32,
                  ),
                ),

              // Space content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Space name
                      Text(
                        space.name,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      // Space type
                      Text(
                        _getSpaceTypeString(space.spaceType),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Navigate arrow
              const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.yellow,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Empty state
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off_outlined,
              color: AppColors.textSecondary,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'No Spaces Found',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t find any spaces matching your criteria',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                _refreshSpaces();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Refresh',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Error state
  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Something Went Wrong',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'An error occurred while loading spaces',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.error,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                _refreshSpaces();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Try Again',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper functions
  String _formatCategoryName(String category) {
    // Convert from database format to display format
    // e.g. "student_organizations" -> "Student Organizations"
    final words = category.split('_');
    return words
        .map((word) =>
            word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  bool _categoryMatches(String dbCategory, String displayCategory) {
    // Match database category with display category
    final formattedDbCategory = _formatCategoryName(dbCategory).toLowerCase();
    return formattedDbCategory.contains(displayCategory.toLowerCase());
  }

  String _getSpaceTypeString(SpaceType spaceType) {
    switch (spaceType) {
      case SpaceType.studentOrg:
        return 'Student Organization';
      case SpaceType.universityOrg:
        return 'University Organization';
      case SpaceType.campusLiving:
        return 'Campus Living';
      case SpaceType.fraternityAndSorority:
        return 'Greek Life';
      case SpaceType.other:
      default:
        return 'Space';
    }
  }
}
