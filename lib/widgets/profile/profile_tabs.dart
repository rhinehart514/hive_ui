import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/huge_icons.dart';
import 'package:hive_ui/widgets/profile/empty_state.dart';
import 'package:hive_ui/features/friends/presentation/widgets/suggested_friends_list.dart';
import 'package:go_router/go_router.dart';

/// The spaces tab content for the profile page
class SpacesTab extends StatelessWidget {
  /// The user profile to display spaces for
  final UserProfile profile;

  /// Constructor
  const SpacesTab({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileEmptyState(
      icon: HugeIcons.party,
      title: 'No Spaces Yet',
      message: 'Spaces you create or join will appear here',
      actionLabel: 'Explore Spaces',
      onActionPressed: () {
        // Navigate to spaces page
        HapticFeedback.mediumImpact();
      },
    );
  }
}

/// The events tab content for the profile page
class EventsTab extends StatelessWidget {
  /// The user profile to display events for
  final UserProfile profile;

  /// Constructor
  const EventsTab({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileEmptyState(
      icon: HugeIcons.calendar,
      title: 'No Events Yet',
      message: 'Events you create or join will appear here',
      actionLabel: 'Find Events',
      onActionPressed: () {
        // Navigate to events page
        HapticFeedback.mediumImpact();
      },
    );
  }
}

/// The friends tab content for the profile page
class FriendsTab extends ConsumerWidget {
  /// The user profile to display friends for
  final UserProfile profile;

  /// Constructor
  const FriendsTab({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (profile.friendCount <= 0) {
      return Column(
        children: [
          ProfileEmptyState(
            icon: HugeIcons.user,
            title: 'No Friends Yet',
            message: 'Connect with friends to see them here',
            actionLabel: 'Find Friends',
            onActionPressed: () {
              // Navigate to suggested friends page
              HapticFeedback.mediumImpact();
              context.push('/profile/suggested-friends');
            },
          ),
          
          // Show suggested friends even when user has no friends
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(
                    'Suggested Friends',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                
                const Expanded(
                  child: SuggestedFriendsList(
                    limit: 5,
                    horizontal: false,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Friend count header
          Row(
            children: [
              Icon(
                HugeIcons.user,
                color: AppColors.gold,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                '${profile.friendCount} ${profile.friendCount == 1 ? 'Friend' : 'Friends'}',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Friends list would go here
          // This is a placeholder to be implemented with actual friends
          Expanded(
            flex: 2,
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                // Placeholder for actual friends list
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.grey[850]!.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const HugeIcon(
                          icon: HugeIcons.user,
                          color: AppColors.gold,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Friend list coming soon',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You have ${profile.friendCount} ${profile.friendCount == 1 ? 'friend' : 'friends'} on HIVE',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Suggested friends section
          const SizedBox(height: 24),
          Text(
            'Suggested Friends',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          
          // Show suggested friends
          const Expanded(
            flex: 3,
            child: SuggestedFriendsList(
              limit: 5,
              horizontal: false,
            ),
          ),
          
          // View all button
          Center(
            child: TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                context.push('/profile/suggested-friends');
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.gold,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16, 
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'View All Suggestions',
                style: GoogleFonts.inter(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// A custom sliver delegate for the tab bar
class SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  /// The tab bar to display
  final TabBar tabBar;

  /// Constructor
  SliverTabBarDelegate(this.tabBar);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.black.withOpacity(0.8),
      child: tabBar,
    );
  }

  @override
  double get maxExtent => 48;

  @override
  double get minExtent => 48;

  @override
  bool shouldRebuild(covariant SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}

/// A tab switching component for the profile page
class ProfileTabs extends StatelessWidget {
  /// The index of the currently selected tab
  final int selectedIndex;
  
  /// Callback function when a tab is tapped
  final void Function(int) onTabChanged;

  /// Constructor
  const ProfileTabs({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.black,
        border: Border(
          bottom: BorderSide(
            color: AppColors.gold.withOpacity(0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTabItem("Spaces", 0, selectedIndex == 0, onTabChanged),
          _buildTabItem("Events", 1, selectedIndex == 1, onTabChanged),
          _buildTabItem("Friends", 2, selectedIndex == 2, onTabChanged),
        ],
      ),
    );
  }

  /// Builds a single tab item 
  Widget _buildTabItem(String label, int index, bool isActive, void Function(int) onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap(index);
      },
      child: Semantics(
        button: true,
        selected: isActive,
        label: '$label tab',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label, 
                style: GoogleFonts.inter(
                  color: isActive ? AppColors.gold : Colors.white.withOpacity(0.7),
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              if (isActive)
                Container(
                  height: 2, 
                  width: 24, 
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(1),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}

/// A widget that displays a tab count badge
class TabCountBadge extends StatelessWidget {
  /// The count to display
  final int count;
  
  /// The label to display next to the count
  final String label;

  /// Constructor
  const TabCountBadge({
    super.key, 
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              count.toString(),
              style: GoogleFonts.inter(
                color: AppColors.gold,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
