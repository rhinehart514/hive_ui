import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/features/friends/domain/entities/suggested_friend.dart';
import 'package:hive_ui/features/friends/presentation/widgets/suggested_friends_list.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A screen that displays suggested friends with filtering options
class SuggestedFriendsScreen extends ConsumerStatefulWidget {
  const SuggestedFriendsScreen({super.key});

  @override
  ConsumerState<SuggestedFriendsScreen> createState() => _SuggestedFriendsScreenState();
}

class _SuggestedFriendsScreenState extends ConsumerState<SuggestedFriendsScreen> {
  MatchCriteria? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Suggested Friends',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.black,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter chips
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', null),
                    const SizedBox(width: 8),
                    _buildFilterChip('Major', MatchCriteria.major),
                    const SizedBox(width: 8),
                    _buildFilterChip('Residence', MatchCriteria.residence),
                    const SizedBox(width: 8),
                    _buildFilterChip('Interests', MatchCriteria.interest),
                  ],
                ),
              ),
            ),
            
            // Horizontal suggestions carousel
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4, left: 16),
              child: Text(
                'People you might know',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            
            SuggestedFriendsList(
              filterCriteria: _selectedFilter,
              limit: 10,
              horizontal: true,
            ),
            
            const SizedBox(height: 24),
            
            // Additional suggestions grouped by match type
            if (_selectedFilter == null) ...[
              // If no filter is selected, show all types
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SuggestedFriendsList(
                        filterCriteria: MatchCriteria.major,
                        title: 'Students in your major',
                        limit: 3,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      SuggestedFriendsList(
                        filterCriteria: MatchCriteria.residence,
                        title: 'People who live nearby',
                        limit: 3,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      SuggestedFriendsList(
                        filterCriteria: MatchCriteria.interest,
                        title: 'People with similar interests',
                        limit: 3,
                      ),
                      
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // If a filter is selected, show more suggestions with that filter
              Expanded(
                child: SuggestedFriendsList(
                  filterCriteria: _selectedFilter,
                  limit: 20,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// Build a filter chip for the criteria
  Widget _buildFilterChip(String label, MatchCriteria? criteria) {
    final isSelected = _selectedFilter == criteria;
    
    return FilterChip(
      label: Text(
        label,
        style: GoogleFonts.inter(
          color: isSelected ? Colors.black : Colors.white,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          fontSize: 14,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedFilter = selected ? criteria : null;
        });
      },
      backgroundColor: Colors.grey[850],
      selectedColor: AppColors.gold,
      checkmarkColor: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.gold : Colors.transparent,
          width: 1,
        ),
      ),
    );
  }
} 