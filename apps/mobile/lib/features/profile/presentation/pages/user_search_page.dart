import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/features/profile/domain/entities/user_search_filters.dart';
import 'package:hive_ui/features/profile/presentation/providers/user_search_providers.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/widgets/profile/follow_button.dart';

class UserSearchPage extends ConsumerStatefulWidget {
  const UserSearchPage({super.key});

  @override
  ConsumerState<UserSearchPage> createState() => _UserSearchPageState();
}

class _UserSearchPageState extends ConsumerState<UserSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateSearchQuery(String query) {
    ref.read(userSearchFiltersProvider.notifier).state = 
        ref.read(userSearchFiltersProvider).copyWith(query: query);
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(userSearchResultsProvider);
    final filters = ref.watch(userSearchFiltersProvider);

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: Text(
          'Find People',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
              color: AppColors.gold,
            ),
            onPressed: _toggleFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _updateSearchQuery,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by name, major, or interests...',
                hintStyle: GoogleFonts.inter(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: AppColors.gold),
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.gold.withOpacity(0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.gold),
                ),
              ),
            ),
          ),

          // Filters
          if (_showFilters) _buildFilters(filters),

          // Results
          Expanded(
            child: searchResults.when(
              data: (users) => _buildSearchResults(users),
              loading: () => const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                ),
              ),
              error: (error, stack) => Center(
                child: Text(
                  'Error loading results',
                  style: GoogleFonts.inter(color: Colors.red[300]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(UserSearchFilters filters) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.cardBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filters',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip(
                'Verified Only',
                filters.onlyVerified,
                (value) => ref.read(userSearchFiltersProvider.notifier).state =
                    filters.copyWith(onlyVerified: value),
              ),
              _buildFilterChip(
                'Exclude Followed',
                filters.excludeFollowed,
                (value) => ref.read(userSearchFiltersProvider.notifier).state =
                    filters.copyWith(excludeFollowed: value),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Year Filter
          DropdownButtonFormField<String>(
            value: filters.year,
            decoration: const InputDecoration(
              labelText: 'Year',
              labelStyle: TextStyle(color: Colors.white70),
            ),
            dropdownColor: AppColors.cardBackground,
            style: GoogleFonts.inter(color: Colors.white),
            items: ['Freshman', 'Sophomore', 'Junior', 'Senior', 'Graduate']
                .map((year) => DropdownMenuItem(
                      value: year,
                      child: Text(year),
                    ))
                .toList(),
            onChanged: (value) => ref.read(userSearchFiltersProvider.notifier).state =
                filters.copyWith(year: value),
          ),
          const SizedBox(height: 8),
          // Major Filter
          DropdownButtonFormField<String>(
            value: filters.major,
            decoration: const InputDecoration(
              labelText: 'Major',
              labelStyle: TextStyle(color: Colors.white70),
            ),
            dropdownColor: AppColors.cardBackground,
            style: GoogleFonts.inter(color: Colors.white),
            items: ['Computer Science', 'Psychology', 'Engineering', 'Business']
                .map((major) => DropdownMenuItem(
                      value: major,
                      child: Text(major),
                    ))
                .toList(),
            onChanged: (value) => ref.read(userSearchFiltersProvider.notifier).state =
                filters.copyWith(major: value),
          ),
          const SizedBox(height: 16),
          // Activity Level Slider
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Minimum Activity Level',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: (filters.minActivityLevel ?? 0).toDouble(),
                      min: 0,
                      max: 100,
                      divisions: 10,
                      activeColor: AppColors.gold,
                      inactiveColor: AppColors.gold.withOpacity(0.2),
                      label: '${filters.minActivityLevel ?? 0}%',
                      onChanged: (value) {
                        ref.read(userSearchFiltersProvider.notifier).state =
                            filters.copyWith(minActivityLevel: value.round());
                      },
                    ),
                  ),
                  SizedBox(
                    width: 50,
                    child: Text(
                      '${filters.minActivityLevel ?? 0}%',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Shared Spaces & Events
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: filters.minSharedSpaces?.toString() ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Min Shared Spaces',
                    labelStyle: TextStyle(color: Colors.white70),
                    suffixIcon: Icon(Icons.space_dashboard, color: AppColors.gold),
                  ),
                  style: GoogleFonts.inter(color: Colors.white),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final intValue = int.tryParse(value);
                    ref.read(userSearchFiltersProvider.notifier).state =
                        filters.copyWith(minSharedSpaces: intValue);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  initialValue: filters.minSharedEvents?.toString() ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Min Shared Events',
                    labelStyle: TextStyle(color: Colors.white70),
                    suffixIcon: Icon(Icons.event, color: AppColors.gold),
                  ),
                  style: GoogleFonts.inter(color: Colors.white),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final intValue = int.tryParse(value);
                    ref.read(userSearchFiltersProvider.notifier).state =
                        filters.copyWith(minSharedEvents: intValue);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected, Function(bool) onSelected) {
    return FilterChip(
      label: Text(
        label,
        style: GoogleFonts.inter(
          color: selected ? Colors.black : Colors.white,
        ),
      ),
      selected: selected,
      onSelected: onSelected,
      selectedColor: AppColors.gold,
      backgroundColor: AppColors.cardBackground,
      checkmarkColor: Colors.black,
    );
  }

  Widget _buildSearchResults(List<UserProfile> users) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(UserProfile user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.gold.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Profile Image
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.gold.withOpacity(0.1),
            backgroundImage: user.profileImageUrl != null
                ? NetworkImage(user.profileImageUrl!)
                : null,
            child: user.profileImageUrl == null
                ? Text(
                    user.displayName[0].toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user.displayName,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    if (user.isVerified)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.verified,
                          size: 16,
                          color: AppColors.gold,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${user.major} • ${user.year}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                ),
                if (user.bio != null && user.bio!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    user.bio!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[300],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: user.interests.take(3).map((interest) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        interest,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.gold,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Follow Button
          SizedBox(
            width: 100,
            child: FollowButton(
              userId: user.id,
              onFollowStateChanged: (isFollowing) {
                // Optionally refresh search results when follow state changes
                ref.refresh(userSearchResultsProvider);
              },
            ),
          ),
        ],
      ),
    );
  }
} 