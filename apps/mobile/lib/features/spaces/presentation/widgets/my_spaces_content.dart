import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/features/spaces/presentation/providers/space_search_provider.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/spaces_empty_state.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/spaces_error_state.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/spaces_loading_state.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/features/spaces/presentation/providers/space_navigation_provider.dart';
import 'package:hive_ui/extensions/glassmorphism_extension.dart';

/// Widget that displays the spaces a user has joined
class MySpacesContent extends ConsumerWidget {
  /// Constructor
  const MySpacesContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final joinedSpacesAsync = ref.watch(joinedSpacesProvider);

    return joinedSpacesAsync.when(
      loading: () => const SpacesLoadingState(),
      error: (err, stack) => SpacesErrorState(error: err.toString()),
      data: (spaces) {
        if (spaces.isEmpty) {
          return const SpacesEmptyState(
            message: 'You haven\'t joined any spaces yet',
            subMessage: 'Discover spaces to join and connect with other members',
            icon: Icons.group_outlined,
          );
        }

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Your Spaces',
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.gold.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${spaces.length}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Spaces you have joined or created',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Grid of spaces
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final space = spaces[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildSpaceCard(context, space, ref),
                    );
                  },
                  childCount: spaces.length,
                ),
              ),
            ),
            
            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildSpaceCard(BuildContext context, dynamic space, WidgetRef ref) {
    final navigator = ref.read(spaceNavigationProvider);
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        // Use the proper navigation pattern with spaceType
        final spaceType = _getSpaceTypeString(space.spaceType);
        navigator.navigateToSpace(
          context, 
          spaceId: space.id, 
          spaceType: spaceType,
          space: space,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _buildGlassmorphicCard(space),
      ),
    );
  }
  
  Widget _buildGlassmorphicCard(dynamic space) {
    // Create a properly styled Container with glassmorphism effect
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: space.isBuilder
            ? AppColors.gold.withOpacity(0.3)
            : Colors.white.withOpacity(0.05),
          width: space.isBuilder ? 1.0 : 0.5,
        ),
      ),
      child: _buildCardContent(space),
    ).addGlassmorphism(
      borderRadius: 16,
      blur: 3,
      opacity: 0.3,
    );
  }
  
  Widget _buildCardContent(dynamic space) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Space icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: space.primaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              space.icon,
              color: space.isBuilder ? AppColors.gold : space.primaryColor,
              size: 24,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and type badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        space.name,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (space.isBuilder)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'BUILDER',
                          style: GoogleFonts.inter(
                            color: AppColors.gold,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                // Description
                Text(
                  space.description,
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 12),
                
                // Stats row
                Row(
                  children: [
                    _buildStatItem(Icons.people_outline, space.metrics.memberCount.toString(), 'Members'),
                    const SizedBox(width: 16),
                    _buildStatItem(Icons.calendar_today_outlined, space.metrics.weeklyEvents.toString(), 'Events'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(IconData icon, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.white.withOpacity(0.5),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  String _getSpaceTypeString(dynamic type) {
    // Convert the space type to a URL-friendly string
    final typeStr = type.toString().split('.').last;
    
    switch (typeStr) {
      case 'studentOrg':
        return 'student_organizations';
      case 'universityOrg':
        return 'university_organizations';
      case 'campusLiving':
        return 'campus_living';
      case 'fraternityAndSorority':
        return 'fraternity_and_sorority';
      case 'hiveExclusive':
        return 'hive_exclusive';
      default:
        return 'other';
    }
  }
}
