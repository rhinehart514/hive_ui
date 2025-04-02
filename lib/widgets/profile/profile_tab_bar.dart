import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/models/user_profile.dart';

/// Type of profile tab
enum ProfileTabType {
  spaces,
  events,
  friends,
}

/// Extension on UserProfile to provide additional computed properties
extension UserProfileStats on UserProfile {
  /// Estimated activity count based on other metrics
  int get activityCount => (eventCount + clubCount) ~/ 2 + 5;

  // Ensure clubCount reflects the number of followed spaces and handles nulls safely
  int get calculatedClubCount {
    try {
      final spaces = followedSpaces;
      return spaces.isNotEmpty ? spaces.length : 0;
    } catch (e) {
      debugPrint('Error calculating club count: $e');
      return 0; // Safe fallback
    }
  }
}

/// A persistent tab bar for the profile page
class ProfileTabBar extends StatelessWidget {
  /// Tab controller
  final TabController tabController;

  /// Whether the screen is small
  final bool isSmallScreen;

  /// User profile to display stats
  final UserProfile? profile;

  const ProfileTabBar({
    super.key,
    required this.tabController,
    this.isSmallScreen = false,
    this.profile,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate accurate counts from profile
    final spacesCount = profile?.calculatedClubCount ?? 0;
    final eventsCount = profile?.eventCount ?? 0;
    final friendsCount = profile?.friendCount ?? 0;

    return Material(
      color: AppColors.cardBackground,
      elevation: 4.0,
      child: Container(
        // Increase height for better touch targets on mobile
        height: isSmallScreen ? 60.0 : 56.0,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          border: Border(
            bottom: BorderSide(
              color: AppColors.gold.withOpacity(0.3),
              width: 0.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TabBar(
          controller: tabController,
          indicatorColor: AppColors.gold,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          isScrollable: false,
          // Increase font size slightly for better readability on mobile
          labelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: isSmallScreen ? 13 : 14,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: isSmallScreen ? 13 : 14,
          ),
          tabs: [
            _buildTabWithCount('Spaces', spacesCount, ProfileTabType.spaces),
            _buildTabWithCount('Events', eventsCount, ProfileTabType.events),
            _buildTabWithCount('Friends', friendsCount, ProfileTabType.friends),
          ],
          overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
            if (states.contains(MaterialState.pressed)) {
              return AppColors.gold.withOpacity(0.2);
            }
            if (states.contains(MaterialState.focused) || 
                states.contains(MaterialState.hovered)) {
              return AppColors.gold.withOpacity(0.1);
            }
            return null;
          }),
          // Increase padding for better touch targets
          labelPadding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 20 : 16),
          splashFactory: InkRipple.splashFactory,
          enableFeedback: true,
          onTap: (_) => HapticFeedback.selectionClick(),
          dividerColor: Colors.transparent,
        ),
      ),
    );
  }

  /// Build a tab with a count badge
  Widget _buildTabWithCount(String label, int count, ProfileTabType type) {
    // Create semantic label for accessibility
    final String semanticLabel;
    switch (type) {
      case ProfileTabType.spaces:
        semanticLabel = 'Spaces tab, $count spaces';
        break;
      case ProfileTabType.events:
        semanticLabel = 'Events tab, $count events';
        break;
      case ProfileTabType.friends:
        semanticLabel = 'Friends tab, $count friends';
        break;
    }

    return Semantics(
      label: semanticLabel,
      selected: tabController.index == type.index,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: tabController.index == type.index ? 1.0 : 0.8,
        child: Tab(
          height: isSmallScreen ? 60.0 : 56.0, // Match container height
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: tabController.index == type.index 
                    ? AppColors.gold.withOpacity(0.2) 
                    : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: tabController.index == type.index 
                      ? AppColors.gold 
                      : Colors.white.withOpacity(0.7),
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

/// Delegate for SliverPersistentHeader to use the ProfileTabBar
class ProfileTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final bool isSmallScreen;
  final UserProfile? profile;

  // Store a constant height to ensure consistency between extent values
  final double _tabHeight;

  ProfileTabBarDelegate({
    required this.tabController,
    this.isSmallScreen = false,
    this.profile,
  }) : _tabHeight = isSmallScreen ? 60.0 : 56.0; // Use consistent height value based on screen size

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ProfileTabBar(
      tabController: tabController,
      isSmallScreen: isSmallScreen,
      profile: profile,
    );
  }

  @override
  double get minExtent => _tabHeight;

  @override
  double get maxExtent => _tabHeight;

  @override
  bool shouldRebuild(covariant ProfileTabBarDelegate oldDelegate) {
    // Include profile information in shouldRebuild check to update when counts change
    return tabController != oldDelegate.tabController ||
        isSmallScreen != oldDelegate.isSmallScreen ||
        profile?.id != oldDelegate.profile?.id ||
        profile?.calculatedClubCount != oldDelegate.profile?.calculatedClubCount ||
        profile?.eventCount != oldDelegate.profile?.eventCount ||
        profile?.friendCount != oldDelegate.profile?.friendCount;
  }
}
