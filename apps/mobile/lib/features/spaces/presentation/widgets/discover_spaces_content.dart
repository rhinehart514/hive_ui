import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/presentation/providers/spaces_providers.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/spaces_empty_state.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/spaces_error_state.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/spaces_loading_state.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/space_type_indicator.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/lifecycle_state_indicator.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:go_router/go_router.dart';

/// Widget to display discoverable spaces
class DiscoverSpacesContent extends ConsumerStatefulWidget {
  /// Constructor
  const DiscoverSpacesContent({Key? key}) : super(key: key);

  @override
  ConsumerState<DiscoverSpacesContent> createState() => _DiscoverSpacesContentState();
}

class _DiscoverSpacesContentState extends ConsumerState<DiscoverSpacesContent> {
  /// Current filter for space discovery
  String _currentFilter = 'All Spaces';
  
  /// List of available filters
  final List<String> _filters = [
    'All Spaces',
    'Trending',
    'Student Orgs',
    'University Orgs',
    'Greek Life',
    'Campus Living',
    'Newest',
  ];

  /// Navigate to space details page
  void _navigateToSpaceDetails(String spaceId) {
    HapticFeedback.lightImpact();
    context.push('/spaces/$spaceId');
  }

  /// Filter spaces based on current filter
  List<SpaceEntity> _filterSpaces(List<SpaceEntity> allSpaces) {
    // Base filter: exclude archived spaces and spaces the user has already joined
    final discoverableSpaces = allSpaces.where((space) => 
      space.lifecycleState != SpaceLifecycleState.archived && 
      !space.isJoined
    ).toList();

    switch (_currentFilter) {
      case 'Trending':
        return discoverableSpaces
          ..sort((a, b) => b.metrics.memberCount.compareTo(a.metrics.memberCount));
      case 'Student Orgs':
        return discoverableSpaces.where((space) => 
          space.spaceType == SpaceType.studentOrg).toList();
      case 'University Orgs':
        return discoverableSpaces.where((space) => 
          space.spaceType == SpaceType.universityOrg).toList();
      case 'Greek Life':
        return discoverableSpaces.where((space) => 
          space.spaceType == SpaceType.fraternityAndSorority).toList();
      case 'Campus Living':
        return discoverableSpaces.where((space) => 
          space.spaceType == SpaceType.campusLiving).toList();
      case 'Newest':
        return discoverableSpaces
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      default: // 'All Spaces'
        return discoverableSpaces;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Horizontal filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: _filters.map((filter) {
              final isSelected = _currentFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    filter,
                    style: GoogleFonts.inter(
                      color: isSelected ? Colors.black : Colors.white,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _currentFilter = filter;
                      });
                      HapticFeedback.selectionClick();
                    }
                  },
                  backgroundColor: Colors.black.withOpacity(0.3),
                  selectedColor: AppColors.gold,
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.2),
                      width: 0.5,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        
        // Spaces content
        Expanded(
          child: ref.watch(allSpacesProvider).when(
            loading: () => const SpacesLoadingState(),
            error: (err, stack) => SpacesErrorState(error: err.toString()),
            data: (spaces) {
              final filteredSpaces = _filterSpaces(spaces);
              
              if (filteredSpaces.isEmpty) {
                return SpacesEmptyState(
                  message: 'No ${_currentFilter == 'All Spaces' ? '' : _currentFilter} spaces found to discover'
                );
              }
              
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredSpaces.length,
                itemBuilder: (context, index) {
                  final space = filteredSpaces[index];
                  return _buildDiscoverableSpaceCard(space);
                },
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildDiscoverableSpaceCard(SpaceEntity space) {
    // Hide archived spaces from discovery
    if (space.lifecycleState == SpaceLifecycleState.archived) {
      return const SizedBox.shrink();
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.white.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: InkWell(
        onTap: () => _navigateToSpaceDetails(space.id),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and name
              Row(
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: space.primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      space.icon,
                      color: space.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          space.name,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.people,
                              size: 14,
                              color: Colors.white.withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${space.metrics.memberCount} members',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Space description
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  space.description,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // Tags row (horizontal scroll)
              if (space.tags.isNotEmpty)
                SizedBox(
                  height: 28,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: space.tags.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            '#${space.tags[index]}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
              const SizedBox(height: 16),
              
              // Status indicators row
              Row(
                children: [
                  // Space Type indicator
                  SpaceTypeIndicator(space: space),
                  const SizedBox(width: 8),
                  // Only show lifecycle state if not active
                  if (space.lifecycleState != SpaceLifecycleState.active)
                    LifecycleStateIndicator(space: space),
                  const Spacer(),
                  // Private indicator 
                  if (space.isPrivate)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.lock,
                            size: 12,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Private',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Join button
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => _navigateToSpaceDetails(space.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: Text(
                    space.isPrivate ? 'Request to Join' : 'Join Space',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
