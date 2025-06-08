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
import 'package:hive_ui/models/friend.dart';
import 'package:hive_ui/providers/friend_providers.dart';

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
              const Icon(
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
                // Replace placeholder with actual friends list
                ref.watch(userFriendsProvider).when(
                  data: (friends) {
                    if (friends.isEmpty) {
                      return Center(
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
                              'No friends yet',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: friends.length,
                      itemBuilder: (context, index) {
                        final friend = friends[index];
                        return _FriendListItem(friend: friend);
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.gold,
                    ),
                  ),
                  error: (error, stackTrace) => Center(
                    child: Text(
                      'Error loading friends',
                      style: GoogleFonts.inter(
                        color: Colors.red,
                        fontSize: 16,
                      ),
                    ),
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

/// A custom tab bar for the profile page
class ProfileTabs extends StatelessWidget {
  /// The currently selected tab index
  final int selectedIndex;
  
  /// Callback when a tab is selected
  final Function(int) onTabChanged;
  
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
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white10,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTab(context, 'Spaces', 0),
          _buildTab(context, 'Events', 1),
          _buildTab(context, 'Friends', 2),
        ],
      ),
    );
  }
  
  /// Build an individual tab
  Widget _buildTab(BuildContext context, String title, int index) {
    final bool isSelected = selectedIndex == index;
    
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTabChanged(index);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  color: isSelected ? AppColors.gold : AppColors.textTertiary,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            // Indicator line
            Container(
              height: 3,
              width: 40,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.gold : Colors.transparent,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(3),
                ),
              ),
            ),
          ],
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

/// A widget that displays a single friend in the friends list
class _FriendListItem extends StatelessWidget {
  final Friend friend;

  const _FriendListItem({required this.friend});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          // Profile image
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[800],
            ),
            child: friend.imageUrl != null && friend.imageUrl!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      friend.imageUrl!,
                      fit: BoxFit.cover,
                      width: 48,
                      height: 48,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildInitialsAvatar();
                      },
                    ),
                  )
                : _buildInitialsAvatar(),
          ),
          
          const SizedBox(width: 16),
          
          // Friend information
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.name,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${friend.major} • ${friend.year}',
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // Online indicator
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: friend.isOnline ? AppColors.gold : Colors.grey,
              border: Border.all(
                color: Colors.black, 
                width: 1,
              ),
            ),
          ),
          
          // Message icon button
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              // Navigate to chat with this friend
              context.push('/messages/chat/${friend.id}');
            },
            icon: const HugeIcon(
              icon: HugeIcons.message,
              color: AppColors.gold,
              size: 24,
            ),
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build initials avatar when image is not available
  Widget _buildInitialsAvatar() {
    final initials = friend.name.isNotEmpty
        ? friend.name.characters.first.toUpperCase()
        : '?';
        
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
