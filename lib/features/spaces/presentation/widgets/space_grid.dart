import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart'
    as entity;
import 'package:hive_ui/features/spaces/domain/entities/space_metrics_entity.dart'
    as entity;
import 'package:hive_ui/features/spaces/presentation/widgets/space_card.dart';
import 'package:hive_ui/models/space.dart';
import 'package:hive_ui/models/space_metrics.dart';
import 'package:hive_ui/models/space_type.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:flutter/services.dart';

/// Extension to convert model SpaceType to entity SpaceType
extension SpaceTypeConversion on SpaceType {
  entity.SpaceType toEntitySpaceType() {
    switch (this) {
      case SpaceType.studentOrg:
        return entity.SpaceType.studentOrg;
      case SpaceType.universityOrg:
        return entity.SpaceType.universityOrg;
      case SpaceType.campusLiving:
        return entity.SpaceType.campusLiving;
      case SpaceType.fraternityAndSorority:
        return entity.SpaceType.fraternityAndSorority;
      default:
        return entity.SpaceType.other;
    }
  }
}

/// Extension to convert model SpaceCategory to entity SpaceCategory
extension SpaceCategoryConversion on SpaceCategory {
  entity.SpaceCategory toEntitySpaceCategory() {
    switch (this) {
      case SpaceCategory.active:
        return entity.SpaceCategory.active;
      case SpaceCategory.expanding:
        return entity.SpaceCategory.expanding;
      case SpaceCategory.emerging:
        return entity.SpaceCategory.emerging;
      default:
        return entity.SpaceCategory.suggested;
    }
  }
}

/// Extension to convert model SpaceSize to entity SpaceSize
extension SpaceSizeConversion on SpaceSize {
  entity.SpaceSize toEntitySpaceSize() {
    switch (this) {
      case SpaceSize.large:
        return entity.SpaceSize.large;
      case SpaceSize.medium:
        return entity.SpaceSize.medium;
      default:
        return entity.SpaceSize.small;
    }
  }
}

class SpaceGrid extends StatelessWidget {
  final List<Space> spaces;
  final Function(Space) onTapSpace;
  final Function(Space) onJoinSpace;
  final bool isUserSpaces;
  final bool isLoading;
  final String emptyStateMessage;
  final bool showJoinButton;
  final String searchQuery;

  const SpaceGrid({
    Key? key,
    required this.spaces,
    required this.onTapSpace,
    required this.onJoinSpace,
    this.isUserSpaces = false,
    this.isLoading = false,
    this.emptyStateMessage = 'No spaces found',
    this.showJoinButton = true,
    this.searchQuery = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.gold,
        ),
      );
    }

    if (spaces.isEmpty) {
      return _buildEmptyState(context);
    }

    // Get screen width to determine grid layout
    final screenWidth = MediaQuery.of(context).size.width;

    // Optimized responsive layout with better spacing
    int crossAxisCount;
    double itemSpacing;
    double horizontalPadding;

    if (screenWidth > 1200) {
      crossAxisCount = 4;
      itemSpacing = 20;
      horizontalPadding = 20;
    } else if (screenWidth > 900) {
      crossAxisCount = 3;
      itemSpacing = 16;
      horizontalPadding = 16;
    } else if (screenWidth > 600) {
      crossAxisCount = 2;
      itemSpacing = 12;
      horizontalPadding = 16;
    } else if (screenWidth > 380) {
      crossAxisCount = 2;
      itemSpacing = 10;
      horizontalPadding = 12;
    } else {
      // Very small screens get single column
      crossAxisCount = 1;
      itemSpacing = 10;
      horizontalPadding = 12;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: MasonryGridView.count(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: itemSpacing,
        crossAxisSpacing: itemSpacing,
        itemCount: spaces.length,
        physics: const BouncingScrollPhysics(),
        // Remove padding to optimize layout
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          // Optimize card size distribution for better visual layout
          bool isCompact = false;

          if (crossAxisCount >= 2) {
            // More efficient pattern assignment
            if (crossAxisCount == 2) {
              isCompact = index % 3 != 0;
            } else if (crossAxisCount == 3) {
              isCompact = index % 4 != 0 && index % 4 != 2;
            } else {
              isCompact = index % 5 != 0 && index % 5 != 3;
            }
          }

          return _buildSpaceCard(spaces[index], isCompact);
        },
      ),
    );
  }

  Widget _buildSpaceCard(Space space, bool compact) {
    return SpaceCard(
      space: entity.SpaceEntity(
        id: space.id,
        name: space.name,
        description: space.description,
        iconCodePoint: space.icon.codePoint,
        metrics: entity.SpaceMetricsEntity(
          spaceId: space.metrics.spaceId,
          memberCount: space.metrics.memberCount,
          activeMembers: space.metrics.activeMembers,
          weeklyEvents: space.metrics.weeklyEvents,
          monthlyEngagements: space.metrics.monthlyEngagements,
          lastActivity: space.metrics.lastActivity,
          hasNewContent: space.metrics.hasNewContent,
          isTrending: space.metrics.isTrending,
          activeMembers24h: space.metrics.activeMembers24h,
          activityScores: space.metrics.activityScores,
          category: space.metrics.category.toEntitySpaceCategory(),
          size: space.metrics.size.toEntitySpaceSize(),
          engagementScore: space.metrics.engagementScore,
        ),
        imageUrl: space.imageUrl,
        bannerUrl: space.bannerUrl,
        tags: space.tags,
        isJoined: space.isJoined,
        isPrivate: space.isPrivate,
        createdAt: space.createdAt,
        updatedAt: space.updatedAt,
        spaceType: space.spaceType.toEntitySpaceType(),
      ),
      onTap: () => onTapSpace(space),
      showJoinButton: showJoinButton,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    // Determine if this is a search with no results
    final isSearch = searchQuery.isNotEmpty;
    final screenWidth = MediaQuery.of(context).size.width;

    // Create a message based on context
    final String title = isSearch
        ? 'No results found'
        : isUserSpaces
            ? 'No spaces joined yet'
            : 'No spaces available';

    final String message = isSearch
        ? 'Try a different search term or explore available spaces'
        : isUserSpaces
            ? 'Join a space to see it here'
            : emptyStateMessage;

    // Optimize empty state padding based on screen size
    final horizontalPadding = screenWidth < 360 ? 16.0 : 24.0;

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated empty state icon
              _PulsingEmptyStateIcon(
                isSearch: isSearch,
                isUserSpaces: isUserSpaces,
                screenWidth: screenWidth,
              ),
              SizedBox(height: screenWidth < 360 ? 16 : 24),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: screenWidth < 360 ? 20 : 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: screenWidth < 360 ? 14 : 16,
                  color: Colors.white.withOpacity(0.7),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenWidth < 360 ? 24 : 32),
              if (isUserSpaces && !isSearch)
                _buildActionButton(context, 'Explore Spaces', Icons.explore,
                    () {
                  HapticFeedback.mediumImpact();
                }),
              if (isSearch)
                _buildActionButton(context, 'Clear Search', Icons.clear, () {
                  HapticFeedback.lightImpact();
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon,
      VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: Colors.black,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// Stateful widget for the pulsing animation
class _PulsingEmptyStateIcon extends StatefulWidget {
  final bool isSearch;
  final bool isUserSpaces;
  final double screenWidth;

  const _PulsingEmptyStateIcon({
    Key? key,
    required this.isSearch,
    required this.isUserSpaces,
    required this.screenWidth,
  }) : super(key: key);

  @override
  State<_PulsingEmptyStateIcon> createState() => _PulsingEmptyStateIconState();
}

class _PulsingEmptyStateIconState extends State<_PulsingEmptyStateIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.5, end: 0.8).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final IconData iconData = widget.isSearch
        ? Icons.search_off
        : widget.isUserSpaces
            ? Icons.people_outline
            : Icons.category_outlined;

    // Optimized sizes for better scaling with screen size
    final double iconSize = widget.screenWidth < 360
        ? 50.0
        : widget.screenWidth < 600
            ? 60.0
            : 70.0;

    final double containerSize = widget.screenWidth < 360
        ? 120.0
        : widget.screenWidth < 600
            ? 140.0
            : 160.0;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: containerSize,
            height: containerSize,
            decoration: BoxDecoration(
              color: Colors.grey[900]?.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      AppColors.gold.withOpacity(0.1 * _scaleAnimation.value),
                  blurRadius: 15 * _scaleAnimation.value,
                  spreadRadius: 1 * _scaleAnimation.value,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                iconData,
                size: iconSize,
                color: AppColors.gold.withOpacity(_opacityAnimation.value),
              ),
            ),
          ),
        );
      },
    );
  }
}
