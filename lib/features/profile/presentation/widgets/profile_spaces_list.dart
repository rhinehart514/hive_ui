import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart' hide SpaceType;
import 'package:hive_ui/features/spaces/presentation/providers/space_providers.dart' as space_providers;
import 'package:hive_ui/features/spaces/presentation/providers/spaces_async_providers.dart';
import 'package:hive_ui/features/profile/presentation/providers/profile_providers.dart';
import 'package:hive_ui/models/space.dart';
import 'package:hive_ui/models/space_metrics.dart';
import 'package:hive_ui/models/space_type.dart';
import 'package:hive_ui/theme/huge_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// A streamlined widget that displays a user's spaces in the profile tab
class ProfileSpacesList extends ConsumerStatefulWidget {
  /// The user profile to display spaces for
  final UserProfile profile;
  
  /// Whether this is the current user's profile
  final bool isCurrentUser;
  
  /// Callback when the action button is pressed
  final VoidCallback? onActionPressed;

  const ProfileSpacesList({
    super.key,
    required this.profile,
    required this.isCurrentUser,
    this.onActionPressed,
  });

  @override
  ConsumerState<ProfileSpacesList> createState() => _ProfileSpacesListState();
}

class _ProfileSpacesListState extends ConsumerState<ProfileSpacesList> {
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    // Remove direct provider access in initState
    // Instead, schedule it for after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshData();
      }
    });
  }
  
  /// Refresh the spaces data
  Future<void> _refreshData() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Refresh space data
      ref.invalidate(space_providers.spacesProvider);
      
      if (widget.isCurrentUser) {
        ref.invalidate(userSpacesAsyncProvider);
        
        // Get current profile state
        final profileState = ref.read(profileProvider);
        final followedSpaces = profileState.profile?.followedSpaces;
        
        // Only refresh if we have no profile or no followedSpaces array at all
        // This prevents refreshing when we just have an empty array
        if (profileState.profile == null || followedSpaces == null) {
          await ref.read(profileProvider.notifier).refreshProfile();
          debugPrint('Refreshed profile provider - profile was null or missing followedSpaces field');
        } else {
          debugPrint('Skipped profile refresh - profile exists with followedSpaces field (${followedSpaces.length} spaces)');
        }
      }
    } catch (e) {
      debugPrint('Error refreshing space data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  /// Convert SpaceEntity to Space for use in UI
  Space _convertToSpace(dynamic space) {
    if (space is Space) {
      return space;
    } else if (space is SpaceEntity) {
      return Space(
        id: space.id,
        name: space.name,
        description: space.description,
        icon: IconData(space.iconCodePoint, fontFamily: 'MaterialIcons'),
        imageUrl: space.imageUrl,
        bannerUrl: space.bannerUrl,
        metrics: SpaceMetrics(
          spaceId: space.id,
          memberCount: space.metrics.memberCount, 
          activeMembers: space.metrics.activeMembers,
          weeklyEvents: space.metrics.weeklyEvents,
          monthlyEngagements: space.metrics.monthlyEngagements,
          lastActivity: space.metrics.lastActivity,
          hasNewContent: space.metrics.hasNewContent,
          isTrending: space.metrics.isTrending,
          activeMembers24h: space.metrics.activeMembers24h,
          activityScores: space.metrics.activityScores,
          category: SpaceCategory.suggested,
          size: SpaceSize.medium,
          engagementScore: 0.0,
          connectedFriends: space.metrics.connectedFriends,
          firstActionPrompt: space.metrics.firstActionPrompt,
          needsIntroduction: space.metrics.needsIntroduction,
        ),
        tags: space.tags,
        isJoined: space.isJoined,
        isPrivate: space.isPrivate,
        moderators: space.moderators,
        admins: space.admins,
        quickActions: space.quickActions,
        relatedSpaceIds: space.relatedSpaceIds,
        createdAt: space.createdAt,
        updatedAt: space.updatedAt,
        spaceType: _convertSpaceType(space.spaceType),
        eventIds: space.eventIds,
        hiveExclusive: space.hiveExclusive,
        customData: space.customData,
      );
    }
    
    // Default empty space as fallback
    return Space(
      id: 'unknown',
      name: 'Unknown Space',
      description: 'No description available',
      icon: Icons.group,
      metrics: SpaceMetrics.empty(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  /// Convert SpaceEntity.SpaceType to Space.SpaceType
  SpaceType _convertSpaceType(dynamic spaceType) {
    if (spaceType is SpaceType) {
      return spaceType;
    }
    
    // Convert from SpaceEntity.SpaceType
    switch (spaceType.toString().split('.').last) {
      case 'studentOrg':
        return SpaceType.studentOrg;
      case 'universityOrg':
        return SpaceType.universityOrg;
      case 'campusLiving':
        return SpaceType.campusLiving;
      case 'fraternityAndSorority':
        return SpaceType.fraternityAndSorority;
      case 'hiveExclusive':
        return SpaceType.hiveExclusive;
      default:
        return SpaceType.other;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppColors.gold,
      child: widget.isCurrentUser
          ? _buildCurrentUserSpaces()
          : _buildOtherUserSpaces(),
    );
  }
  
  // Current user's spaces tab
  Widget _buildCurrentUserSpaces() {
    // Use the async provider with proper when() support
    final userSpacesAsync = ref.watch(userSpacesAsyncProvider);
    
    return userSpacesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      ),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red[300],
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load your spaces',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pull down to try again',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
      data: (spaces) {
        if (spaces.isEmpty) {
          return _buildEmptySpaces();
        }
        
        // Wrap ListView in a SizedBox with defined height
        return SizedBox(
          height: MediaQuery.of(context).size.height - 200, // Adjust height as needed
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: spaces.length,
            itemBuilder: (context, index) {
              final space = _convertToSpace(spaces[index]);
              return _buildSpaceItem(space, index, true);
            },
          ),
        );
      },
    );
  }
  
  // Other user's spaces tab
  Widget _buildOtherUserSpaces() {
    final List<String> followedSpaces = widget.profile.followedSpaces;
    
    // Handle null or empty followedSpaces gracefully
    if (followedSpaces.isEmpty) {
      return _buildEmptyState(
        '${widget.profile.username} hasn\'t joined any spaces yet',
        'Check back later'
      );
    }
    
    // For non-current user, we need to fetch their spaces from the spacesAsyncProvider
    final allSpacesAsync = ref.watch(spacesAsyncProvider);
    
    return allSpacesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      ),
      error: (err, stack) => Center(
        child: Text(
          'Failed to load spaces',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
      ),
      data: (allSpaces) {
        // Filter to show only spaces the user follows
        final userSpaces = allSpaces.values.where((space) => 
          followedSpaces.contains(space.id)).toList();
        
        if (userSpaces.isEmpty) {
          return _buildEmptyState(
            '${widget.profile.username} hasn\'t joined any spaces yet',
            'Check back later'
          );
        }
        
        // Wrap ListView in a SizedBox with defined height
        return SizedBox(
          height: MediaQuery.of(context).size.height - 200, // Adjust height as needed
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: userSpaces.length,
            itemBuilder: (context, index) {
              final space = _convertToSpace(userSpaces[index]);
              return _buildSpaceItem(space, index, false);
            },
          ),
        );
      },
    );
  }
  
  // Empty spaces state with Hive UI design
  Widget _buildEmptySpaces() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 180,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Styled container with animation
                TweenAnimationBuilder<double>(
                  duration: const Duration(seconds: 2),
                  tween: Tween<double>(begin: 0.5, end: 1.0),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black,
                        border: Border.all(
                          color: AppColors.gold.withOpacity(0.3 + (0.3 * value)),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withOpacity(0.1 + (0.2 * value)),
                            blurRadius: 15 * value,
                            spreadRadius: 2 * value,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          HugeIcons.strokeRoundedUserGroup03,
                          size: 40,
                          color: AppColors.gold.withOpacity(0.7 + (0.3 * value)),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),
                Text(
                  'No Spaces Yet',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Join spaces to connect with other students and discover events and communities.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (widget.onActionPressed != null)
                  ElevatedButton(
                    onPressed: widget.onActionPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'Explore Spaces',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
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
  
  // Space item card reused from spaces page
  Widget _buildSpaceItem(Space space, int index, bool isCurrentUser) {
    final hasImage = space.imageUrl != null && space.imageUrl!.isNotEmpty;
    final isGreekLife = space.spaceType.toString().toLowerCase().contains('greek');

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 6),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[900]!.withOpacity(0.3),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _navigateToSpace(space.id),
            splashColor: AppColors.gold.withOpacity(0.1),
            highlightColor: AppColors.gold.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Space image with production-ready caching
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.black,
                      border: Border.all(
                        color: AppColors.gold.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: hasImage
                        ? CachedNetworkImage(
                            imageUrl: space.imageUrl!,
                            fit: BoxFit.cover,
                            memCacheWidth: 96, // 2x for high-res displays
                            memCacheHeight: 96,
                            maxWidthDiskCache: 96,
                            maxHeightDiskCache: 96,
                            fadeInDuration: const Duration(milliseconds: 200),
                            fadeOutDuration: const Duration(milliseconds: 200),
                            placeholderFadeInDuration: const Duration(milliseconds: 200),
                            errorWidget: (context, url, error) {
                              // Log error for debugging in production
                              debugPrint('Error loading space image: $error');
                              return _buildSpaceIcon(isGreekLife);
                            },
                            placeholder: (context, url) => Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: AppColors.gold.withOpacity(0.5),
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          )
                        : _buildSpaceIcon(isGreekLife),
                  ),
                  const SizedBox(width: 12),

                  // Space info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          space.name,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (space.description.isNotEmpty)
                          Text(
                            space.description,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),

                  // Arrow button
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                    ),
                    onPressed: () => _navigateToSpace(space.id),
                    color: AppColors.gold,
                    splashRadius: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  /// Helper method to build the appropriate space icon
  Widget _buildSpaceIcon(bool isGreekLife) {
    return Center(
      child: isGreekLife
          ? const Icon(
              Icons.groups,
              color: Colors.white54,
              size: 24,
            )
          : const Icon(
              Icons.person,
              color: Colors.white54,
              size: 24,
            ),
    );
  }
  
  // Navigate to the space details page
  void _navigateToSpace(String spaceId) {
    // Add error handling around navigation for production
    try {
      HapticFeedback.selectionClick();
      GoRouter.of(context).push('/spaces/$spaceId');
    } catch (e) {
      debugPrint('Navigation error: $e');
      // Show a subtle error toast if navigation fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to open this space',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: Colors.red[900]!.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
  
  // Simple empty state for non-current user
  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_outlined,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 