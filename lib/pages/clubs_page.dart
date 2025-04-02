import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../models/club.dart';
import '../features/clubs/presentation/widgets/space_detail/space_detail_screen.dart';
import '../providers/club_providers.dart';
import '../providers/event_providers.dart';
import '../theme/app_colors.dart';
import '../theme/glassmorphism_guide.dart';

/// ClubsPage - Redesigned screen displaying all organizations
class ClubsPage extends ConsumerStatefulWidget {
  const ClubsPage({super.key});

  @override
  ConsumerState<ClubsPage> createState() => _ClubsPageState();
}

class _ClubsPageState extends ConsumerState<ClubsPage>
    with AutomaticKeepAliveClientMixin {
  // Sort options
  String _sortOption = 'Name';
  static const List<String> _sortOptions = [
    'Name',
    'Events',
    'Recently Active'
  ];

  // Scroll controller for animations
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _setupScrollListener();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Setup scroll listener for header animation
  void _setupScrollListener() {
    _scrollController.addListener(() {
      setState(() {
        _isScrolled = _scrollController.offset > 10;
      });
    });
  }

  // Initialize data without blocking UI
  void _initializeData() {
    Future.microtask(() {
      // Show indeterminate progress first
      ref.read(clubsProvider);
      // Check for refresh in the background if needed
      _checkForRefresh();
    });
  }

  // Check if we need to refresh data without blocking UI
  Future<void> _checkForRefresh() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        final currentClubs = await ref.read(clubsProvider.future);
        if (currentClubs.isEmpty && mounted) {
          ref.read(refreshClubsProvider);
        }
      }
    } catch (e) {
      debugPrint('Background refresh check error: $e');
    }
  }

  // Helper method to sort clubs based on selected option
  List<Club> _getSortedClubs(List<Club> clubs) {
    switch (_sortOption) {
      case 'Events':
        return List.from(clubs)
          ..sort((a, b) => b.eventCount.compareTo(a.eventCount));
      case 'Recently Active':
        return List.from(clubs)
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case 'Name':
      default:
        return List.from(clubs)..sort((a, b) => a.name.compareTo(b.name));
    }
  }

  /// Perform a thorough refresh of all events and clubs data
  Future<void> _performThoroughRefresh() async {
    HapticFeedback.mediumImpact();
    _showSnackBar('Refreshing all organizations data...');

    try {
      // First invalidate events provider to force a refresh of the source data
      ref.invalidate(refreshEventsProvider);

      // Wait a moment to allow events to refresh
      await Future.delayed(const Duration(milliseconds: 300));

      // Invalidate club providers
      ref.invalidate(clubsProvider);
      ref.invalidate(categoriesProvider);
      ref.invalidate(refreshClubsProvider);

      // Force a refresh of the clubs data
      await ref.read(refreshClubsProvider.future);

      if (mounted) {
        _showSnackBar('Organizations data refreshed successfully!');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error refreshing data: $e', isError: true);
      }
      debugPrint('Error during thorough refresh: $e');
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
          ),
        ),
        duration: Duration(seconds: isError ? 4 : 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isError ? Colors.red.shade900 : Colors.black.withOpacity(0.8),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GlassmorphismGuide.kRadiusMd),
        ),
      ),
    );
  }

  // Navigate to club space
  void _navigateToClubSpace(Club club) {
    debugPrint('Navigating to club space: ${club.name}');
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SpaceDetailScreen(club: club),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Watch the current selected category
    final selectedCategory = ref.watch(selectedCategoryProvider);

    // Watch the clubs data based on selected category
    final clubsAsync = ref.watch(selectedCategory == null
        ? clubsProvider
        : clubsByCategoryProvider(selectedCategory));

    // Watch the categories list
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          // Main scrollable content
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // App bar with animations
              SliverAppBar(
                pinned: true,
                floating: true,
                backgroundColor:
                    _isScrolled ? AppColors.black : Colors.transparent,
                elevation: _isScrolled ? 0 : 0,
                expandedHeight: 120,
                collapsedHeight: 60,
                flexibleSpace: FlexibleSpaceBar(
                  title: AnimatedOpacity(
                    opacity: _isScrolled ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      'Organizations',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.black,
                          AppColors.black.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  // Sort button
                  IconButton(
                    icon: const Icon(Icons.sort, color: Colors.white),
                    tooltip: 'Sort organizations',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      _showSortMenu(context);
                    },
                  ),
                  // Refresh button
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: _performThoroughRefresh,
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              // Header section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderText(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Category filters
              SliverToBoxAdapter(
                child: _buildCategoryFilters(categoriesAsync, selectedCategory),
              ),

              // Clubs list or states
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: clubsAsync.when(
                  data: (clubs) => clubs.isEmpty
                      ? SliverToBoxAdapter(
                          child: _buildEmptyState(selectedCategory != null))
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final club = _getSortedClubs(clubs)[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: ClubCard(
                                  club: club,
                                  onTap: () => _navigateToClubSpace(club),
                                ),
                              );
                            },
                            childCount: clubs.length,
                          ),
                        ),
                  loading: () =>
                      SliverToBoxAdapter(child: _buildLoadingState()),
                  error: (error, stackTrace) {
                    debugPrint('Error loading clubs: $error\n$stackTrace');
                    return SliverToBoxAdapter(child: _buildErrorState());
                  },
                ),
              ),

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 40),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Show sort options modal
  void _showSortMenu(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(GlassmorphismGuide.kModalRadius),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: GlassmorphismGuide.kModalBlur,
            sigmaY: GlassmorphismGuide.kModalBlur,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.black.withOpacity(0.8),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(GlassmorphismGuide.kModalRadius),
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),

                // Title
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Sort Organizations',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),

                // Divider
                Divider(color: Colors.white.withOpacity(0.1)),

                // Sort options
                ..._sortOptions.map((option) => ListTile(
                      title: Text(
                        option,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: _sortOption == option
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      leading: Icon(
                        _getIconForSortOption(option),
                        color: _sortOption == option
                            ? AppColors.gold
                            : Colors.white.withOpacity(0.7),
                      ),
                      trailing: _sortOption == option
                          ? const Icon(
                              Icons.check,
                              color: AppColors.gold,
                            )
                          : null,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _sortOption = option;
                        });
                        Navigator.pop(context);
                      },
                    )),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Get sort option icon
  IconData _getIconForSortOption(String option) {
    switch (option) {
      case 'Name':
        return Icons.sort_by_alpha;
      case 'Events':
        return Icons.event;
      case 'Recently Active':
        return Icons.update;
      default:
        return Icons.sort;
    }
  }

  Widget _buildHeaderText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Organizations',
          style: GoogleFonts.outfit(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Discover campus clubs, departments, and organizations',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              _getIconForSortOption(_sortOption),
              size: 14,
              color: AppColors.gold,
            ),
            const SizedBox(width: 4),
            Text(
              'Sorted by $_sortOption',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.gold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Build category filters
  Widget _buildCategoryFilters(
      AsyncValue<List<String>> categoriesAsync, String? selectedCategory) {
    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                'Filter by Category',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildCategoryChip('All', null, selectedCategory),
                  ...categories.map((category) =>
                      _buildCategoryChip(category, category, selectedCategory)),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(height: 48),
      error: (_, __) => const SizedBox(height: 48),
    );
  }

  // Build individual category chip
  Widget _buildCategoryChip(
      String label, String? value, String? selectedCategory) {
    final bool isSelected = (value == selectedCategory) ||
        (value == null && selectedCategory == null);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        showCheckmark: false,
        onSelected: (selected) {
          HapticFeedback.selectionClick();
          if (selected) {
            ref.read(selectedCategoryProvider.notifier).state = value;
          } else {
            // Only reset if clicking on an already selected filter
            if (isSelected) {
              ref.read(selectedCategoryProvider.notifier).state = null;
            }
          }
        },
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GlassmorphismGuide.kRadiusMd),
          side: BorderSide(
            color: isSelected
                ? AppColors.gold.withOpacity(0.7)
                : Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        selectedColor: AppColors.black,
        labelStyle: GoogleFonts.inter(
          color: isSelected ? AppColors.gold : Colors.white.withOpacity(0.7),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  // Build loading state
  Widget _buildLoadingState() {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),
            Text(
              'Loading organizations...',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build empty state
  Widget _buildEmptyState(bool isFiltered) {
    return Container(
      padding: const EdgeInsets.all(32),
      height: 380,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFiltered ? Icons.filter_alt_off : Icons.groups_outlined,
            size: 64,
            color: Colors.white.withOpacity(0.2),
          ),
          const SizedBox(height: 24),
          Text(
            isFiltered ? 'No Matching Organizations' : 'No Organizations Yet',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isFiltered
                ? 'Try selecting a different category'
                : 'Check back later or refresh to see organizations',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              if (isFiltered) {
                ref.read(selectedCategoryProvider.notifier).state = null;
              } else {
                _performThoroughRefresh();
              }
            },
            icon: Icon(isFiltered ? Icons.clear_all : Icons.refresh),
            label: Text(isFiltered ? 'Clear Filter' : 'Refresh'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.black,
              backgroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  // Build error state
  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(32),
      height: 380,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.withOpacity(0.7),
          ),
          const SizedBox(height: 24),
          Text(
            'Something Went Wrong',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'We couldn\'t load the organizations. Please try again.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              _performThoroughRefresh();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.black,
              backgroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

/// ClubCard - Redesigned card component for displaying club information
class ClubCard extends StatelessWidget {
  final Club club;
  final VoidCallback onTap;

  const ClubCard({
    super.key,
    required this.club,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(GlassmorphismGuide.kRadiusMd),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(GlassmorphismGuide.kRadiusMd),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: GlassmorphismGuide.kCardBlur,
              sigmaY: GlassmorphismGuide.kCardBlur,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground.withOpacity(0.5),
                borderRadius:
                    BorderRadius.circular(GlassmorphismGuide.kRadiusMd),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card header with club info
                  _buildCardHeader(),

                  // Club details
                  _buildCardBody(),

                  // Stats and indicators
                  _buildCardFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Build card header
  Widget _buildCardHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Club icon/logo
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _getIconColor().withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: _getIconColor().withOpacity(0.3),
                width: 1,
              ),
            ),
            child: club.logoUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.network(
                      club.logoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        _getIconData(),
                        color: _getIconColor(),
                        size: 28,
                      ),
                    ),
                  )
                : Icon(
                    _getIconData(),
                    color: _getIconColor(),
                    size: 28,
                  ),
          ),
          const SizedBox(width: 16),

          // Club name and details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        club.name,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (club.isVerifiedPlus || club.isOfficial) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.verified,
                        size: 16,
                        color:
                            club.isVerifiedPlus ? AppColors.gold : Colors.blue,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  club.category,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build card body
  Widget _buildCardBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Text(
        club.description,
        style: GoogleFonts.inter(
          fontSize: 14,
          height: 1.4,
          color: Colors.white.withOpacity(0.8),
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // Build card footer
  Widget _buildCardFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(GlassmorphismGuide.kRadiusMd),
        ),
      ),
      child: Row(
        children: [
          // Event count
          _buildStatChip(
            Icons.event_outlined,
            club.eventCount.toString(),
            'Events',
          ),
          const SizedBox(width: 16),

          // Member count
          _buildStatChip(
            Icons.people_outline,
            club.memberCount.toString(),
            'Members',
          ),

          const Spacer(),

          // View details indicator
          Text(
            'View',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.arrow_forward_ios,
            color: AppColors.gold,
            size: 12,
          ),
        ],
      ),
    );
  }

  // Build stat chip
  Widget _buildStatChip(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.white.withOpacity(0.6),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  // Get icon data based on club category
  IconData _getIconData() {
    switch (club.category.toLowerCase()) {
      case 'academic':
      case 'education':
      case 'research':
        return Icons.school;
      case 'sports':
      case 'athletics':
      case 'recreation':
        return Icons.sports;
      case 'arts':
      case 'culture':
      case 'music':
        return Icons.palette;
      case 'social':
      case 'community':
        return Icons.people;
      case 'greek life':
        return Icons.diversity_3;
      case 'professional':
      case 'career':
        return Icons.business;
      case 'technology':
      case 'engineering':
        return Icons.computer;
      case 'advocacy':
      case 'activism':
        return Icons.campaign;
      case 'religious':
      case 'spiritual':
        return Icons.church;
      default:
        return Icons.group;
    }
  }

  // Get icon color based on club category
  Color _getIconColor() {
    return AppColors.gold;
  }
}
