import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart' as auth;
import 'package:hive_ui/features/profile/presentation/providers/profile_providers.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/presentation/providers/space_search_provider.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/discover_spaces_content.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/my_spaces_content.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/requests_content.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/spaces_error_state.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/spaces_loading_state.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/spaces_search_bar.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/features/profile/domain/entities/user_profile.dart';

/// A screen that displays spaces according to different filters and sections
class SpacesListScreen extends ConsumerStatefulWidget {
  /// Constructor
  const SpacesListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SpacesListScreen> createState() => _SpacesListScreenState();
}

class _SpacesListScreenState extends ConsumerState<SpacesListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      // This ensures state is rebuilt when tab changes
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
    });
  }

  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _navigateToCreateSpace() {
    HapticFeedback.mediumImpact();
    context.push('/spaces/create');
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(auth.currentUserProvider);
    final userProfileAsyncValue = ref.watch(userProfileProvider(currentUser.id));

    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: _buildAppBar(),
      floatingActionButton: _buildCreateSpaceButton(userProfileAsyncValue),
      body: Column(
        children: [
          if (_isSearching)
            SpacesSearchBar(
              onClear: _stopSearch,
              onSearch: _updateSearchQuery,
            ),
          _buildTabBar(),
          Expanded(
            child: _isSearching
                ? _buildSearchResults()
                : TabBarView(
                    controller: _tabController,
                    children: const [
                      // Replace with actual implementations once we create these widgets
                      MySpacesContent(),
                      DiscoverSpacesContent(),
                      RequestsContent(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        'Spaces',
        style: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        if (!_isSearching)
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _startSearch,
          ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.gold,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.black,
        unselectedLabelColor: Colors.white,
        labelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'My Spaces'),
          Tab(text: 'Discover'),
          Tab(text: 'Requests'),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return ref.watch(searchSpacesProvider(_searchQuery)).when(
          loading: () => const SpacesLoadingState(),
          error: (err, stack) => SpacesErrorState(error: err.toString()),
          data: (spaces) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: spaces.length,
              itemBuilder: (context, index) {
                final space = spaces[index];
                return _buildSpaceCard(space);
              },
            );
          },
        );
  }

  Widget _buildSpaceCard(SpaceEntity space) {
    // This will be replaced with a proper SpaceCard widget later
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.black.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: ListTile(
        title: Text(
          space.name,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          space.description,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white.withOpacity(0.7),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        leading: CircleAvatar(
          backgroundColor: AppColors.gold.withOpacity(0.2),
          child: Icon(
            space.icon,
            color: AppColors.gold,
            size: 20,
          ),
        ),
        trailing: _buildSpaceActionButton(space),
        onTap: () => context.push('/spaces/${space.id}'),
      ),
    );
  }

  Widget _buildSpaceActionButton(SpaceEntity space) {
    return space.isJoined
        ? OutlinedButton(
            onPressed: () {
              // Handle leave space functionality
              HapticFeedback.mediumImpact();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Joined'),
          )
        : ElevatedButton(
            onPressed: () {
              // Handle join space functionality
              HapticFeedback.mediumImpact();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Join'),
          );
  }

  Widget? _buildCreateSpaceButton(AsyncValue<UserProfile?> userProfileAsyncValue) {
    return userProfileAsyncValue.when(
      loading: () => null,
      error: (_, __) => null,
      data: (userProfile) {
        if (userProfile == null) return null;

        // Only show create button to verified+ users
        if (!userProfile.isVerifiedPlus) return null;

        return FloatingActionButton(
          onPressed: _navigateToCreateSpace,
          backgroundColor: AppColors.gold,
          child: const Icon(
            Icons.add,
            color: Colors.black,
          ),
        );
      },
    );
  }
} 