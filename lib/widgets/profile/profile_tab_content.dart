import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/models/friend.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/features/profile/presentation/providers/profile_providers.dart' as profile_providers;
import 'package:hive_ui/features/profile/presentation/widgets/profile_spaces_list.dart';
import 'package:hive_ui/providers/friend_providers.dart' as friend_providers;
import 'package:intl/intl.dart';
import 'package:hive_ui/features/profile/presentation/widgets/trail_visualization.dart';

/// Type of tab in the profile page
enum ProfileTabType {
  /// Spaces tab
  spaces,
  /// Events tab
  events,
  /// Friends tab
  friends,
}

/// A streamlined profile tab content widget that displays content based on tab type
class ProfileTabContent extends ConsumerStatefulWidget {
  /// The type of tab to display
  final ProfileTabType tabType;
  
  /// The user profile to display
  final UserProfile profile;
  
  /// Whether this is the current user's profile
  final bool isCurrentUser;
  
  /// Callback when an action button is pressed
  final VoidCallback? onActionPressed;
  
  /// Constructor
  const ProfileTabContent({
    super.key,
    required this.tabType,
    required this.profile,
    this.isCurrentUser = false,
    this.onActionPressed,
  });
  
  @override
  ConsumerState<ProfileTabContent> createState() => _ProfileTabContentState();
}

class _ProfileTabContentState extends ConsumerState<ProfileTabContent> {
  // Track last refresh time to prevent too frequent refreshes
  DateTime? _lastRefreshTime;
  
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.gold,
      backgroundColor: Colors.black,
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        
        // Prevent refreshing too often
        final now = DateTime.now();
        if (_lastRefreshTime != null && 
            now.difference(_lastRefreshTime!).inSeconds < 5) {
          return;
        }
        
        _lastRefreshTime = now;
        debugPrint('ProfileTabContent: Manual refresh triggered');
        
        // Always use the profile refresh method
        await ref.read(profile_providers.profileSyncProvider.notifier).syncProfile();
      },
      child: _buildTabContent(),
    );
  }
  
  Widget _buildTabContent() {
    // Create tab with key to ensure proper lifecycle
    switch (widget.tabType) {
      case ProfileTabType.events:
        return EventsTab(
          key: const ValueKey('events_tab'),
          profile: widget.profile,
          isCurrentUser: widget.isCurrentUser,
          onActionPressed: widget.onActionPressed,
        );
      case ProfileTabType.friends:
        return FriendsTab(
          key: const ValueKey('friends_tab'),
          profile: widget.profile,
          isCurrentUser: widget.isCurrentUser,
          onActionPressed: widget.onActionPressed,
        );
      case ProfileTabType.spaces:
        return SpacesTab(
          key: const ValueKey('spaces_tab'),
          profile: widget.profile,
          isCurrentUser: widget.isCurrentUser,
          onActionPressed: widget.onActionPressed,
        );
    }
  }
}

/// Tab for displaying events
class EventsTab extends ConsumerStatefulWidget {
  /// The user profile
  final UserProfile profile;
  
  /// Whether this is the current user's profile
  final bool isCurrentUser;
  
  /// Callback when an action button is pressed
  final VoidCallback? onActionPressed;
  
  /// Constructor
  const EventsTab({
    super.key,
    required this.profile,
    required this.isCurrentUser,
    this.onActionPressed,
  });
  
  @override
  ConsumerState<EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends ConsumerState<EventsTab> {
  bool _hasTriggeredRefresh = false;
  
  @override
  void initState() {
    super.initState();
    _triggerInitialRefresh();
  }
  
  void _triggerInitialRefresh() {
    if (widget.isCurrentUser && !_hasTriggeredRefresh) {
      _hasTriggeredRefresh = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          debugPrint('EventsTab: Triggering events refresh (once)');
          ref.read(profile_providers.profileProvider.notifier).refreshProfile();
        }
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    debugPrint('EventsTab: Building with ${widget.profile.savedEvents.length} saved events');
    
    if (ref.watch(profile_providers.profileProvider).isLoading) {
      return _buildLoadingState();
    }
    
    if (widget.profile.savedEvents.isEmpty) {
      return _buildEmptyState(context);
    }
    
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      children: [
        for (final event in widget.profile.savedEvents)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ProfileEventCard(event: event),
          ),
      ],
    );
  }
  
  Widget _buildLoadingState() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      children: [
        const SizedBox(height: 40),
        const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Loading events...',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      children: [
        const SizedBox(height: 40),
        Icon(
          Icons.event_note_outlined,
          size: 64,
          color: Colors.white.withOpacity(0.3),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'No Events Yet',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              widget.isCurrentUser 
                ? 'Events you save will appear here'
                : '${widget.profile.username} hasn\'t saved any events yet',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.6),
                fontSize: 15,
              ),
            ),
          ),
        ),
        if (widget.isCurrentUser && widget.onActionPressed != null) ...[
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton(
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
                'Browse Events',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Simplified event card for profile view
class ProfileEventCard extends StatelessWidget {
  /// The event to display
  final Event event;
  
  /// Constructor
  const ProfileEventCard({
    super.key,
    required this.event,
  });
  
  @override
  Widget build(BuildContext context) {
    final isPastEvent = event.startDate.isBefore(DateTime.now());
    
    return Card(
      elevation: 3,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      color: const Color(0xFF1E1E1E),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Navigate to event details
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date column
                  _buildDateSection(event.startDate),
                  const SizedBox(width: 12),
                  // Main content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isPastEvent ? Colors.white.withOpacity(0.6) : Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.location,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 14,
                              color: AppColors.gold.withOpacity(0.8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              event.attendees.isNotEmpty 
                                ? '${event.attendees.length} attending'
                                : 'No attendees yet',
                              style: GoogleFonts.inter(
                                fontSize: 13,
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
            ],
          ),
        ),
      ),
    );
  }
  
  /// Build the date section of the card
  Widget _buildDateSection(DateTime date) {
    final day = DateFormat('dd').format(date);
    final month = DateFormat('MMM').format(date);
    final isPast = date.isBefore(DateTime.now());
    
    return Container(
      width: 50,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isPast ? Colors.grey.withOpacity(0.2) : AppColors.gold.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPast ? Colors.grey.withOpacity(0.3) : AppColors.gold.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            month.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isPast ? Colors.white.withOpacity(0.5) : AppColors.gold,
            ),
          ),
          Text(
            day,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isPast ? Colors.white.withOpacity(0.5) : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tab for displaying friends
class FriendsTab extends ConsumerStatefulWidget {
  /// The user profile
  final UserProfile profile;
  
  /// Whether this is the current user's profile
  final bool isCurrentUser;
  
  /// Callback when an action button is pressed
  final VoidCallback? onActionPressed;
  
  /// Constructor
  const FriendsTab({
    super.key,
    required this.profile,
    required this.isCurrentUser,
    this.onActionPressed,
  });
  
  @override
  ConsumerState<FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends ConsumerState<FriendsTab> {
  bool _hasTriggeredRefresh = false;
  
  @override
  void initState() {
    super.initState();
    _triggerInitialRefresh();
  }
  
  void _triggerInitialRefresh() {
    if (widget.isCurrentUser && !_hasTriggeredRefresh) {
      _hasTriggeredRefresh = true;
      // Friends data comes from a different provider, so we'll just
      // refresh the profile to make sure friend count is accurate
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Use the refresh result or explicitly ignore it
          final _ = ref.refresh(friend_providers.userFriendsProvider);
        }
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final friendsAsync = ref.watch(friend_providers.userFriendsProvider);
        
        return friendsAsync.when(
          data: (friends) {
            if (friends.isEmpty) {
              return _buildEmptyState(context);
            }
            
            return _buildFriendsList(context, friends);
          },
          loading: () => _buildLoadingState(),
          error: (error, stack) => _buildErrorState(context, error),
        );
      },
    );
  }
  
  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      children: [
        const SizedBox(height: 40),
        Icon(
          Icons.people,
          size: 64,
          color: Colors.white.withOpacity(0.3),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'No Friends Yet',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              widget.isCurrentUser 
                ? 'Connect with friends to see them here'
                : '${widget.profile.username} hasn\'t connected with anyone yet',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.6),
                fontSize: 15,
              ),
            ),
          ),
        ),
        if (widget.isCurrentUser && widget.onActionPressed != null) ...[
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton(
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
                'Find Friends',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildErrorState(BuildContext context, Object error) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      children: [
        const SizedBox(height: 40),
        Icon(
          Icons.error_outline,
          size: 64,
          color: Colors.red.withOpacity(0.7),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Error Loading Friends',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ),
        ),
        if (widget.onActionPressed != null) ...[
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton(
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
                'Try Again',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildFriendsList(BuildContext context, List<Friend> friends) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      itemCount: friends.length,
      itemBuilder: (context, index) {
        final friend = friends[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FriendCard(friend: friend),
        );
      },
    );
  }
}

/// Tab for displaying spaces
class SpacesTab extends ConsumerStatefulWidget {
  /// The user profile
  final UserProfile profile;
  
  /// Whether this is the current user's profile
  final bool isCurrentUser;
  
  /// Callback when an action button is pressed
  final VoidCallback? onActionPressed;
  
  /// Constructor
  const SpacesTab({
    super.key,
    required this.profile,
    required this.isCurrentUser,
    this.onActionPressed,
  });
  
  @override
  ConsumerState<SpacesTab> createState() => _SpacesTabState();
}

class _SpacesTabState extends ConsumerState<SpacesTab> {
  bool _hasTriggeredRefresh = false;
  
  @override
  void initState() {
    super.initState();
    _triggerInitialRefresh();
  }
  
  void _triggerInitialRefresh() {
    if (widget.isCurrentUser && !_hasTriggeredRefresh) {
      _hasTriggeredRefresh = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          debugPrint('SpacesTab: Triggering spaces refresh (once)');
          ref.read(profile_providers.profileProvider.notifier).refreshProfile();
        }
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    debugPrint('SpacesTab: Building with ${widget.profile.followedSpaces.length} followed spaces');
    
    // If we're loading spaces, show loading state
    if (ref.watch(profile_providers.profileProvider).isLoading) {
      return _buildLoadingState();
    }
    
    if (widget.profile.followedSpaces.isEmpty) {
      return _buildEmptyState(context);
    }
    
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      children: [
        ProfileSpacesList(
          profile: widget.profile,
          isCurrentUser: widget.isCurrentUser,
          onActionPressed: widget.onActionPressed,
        ),
      ],
    );
  }
  
  Widget _buildLoadingState() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      children: [
        const SizedBox(height: 40),
        const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Loading spaces...',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      children: [
        const SizedBox(height: 40),
        Icon(
          Icons.people_outline,
          size: 64,
          color: Colors.white.withOpacity(0.3),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'No Spaces Yet',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              widget.isCurrentUser 
                ? 'Join spaces to see them here'
                : '${widget.profile.username} hasn\'t joined any spaces yet',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.6),
                fontSize: 15,
              ),
            ),
          ),
        ),
        if (widget.isCurrentUser && widget.onActionPressed != null) ...[
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton(
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
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// A card for displaying a friend in the profile
class FriendCard extends StatelessWidget {
  /// The friend to display
  final Friend friend;
  
  /// Constructor
  const FriendCard({
    super.key,
    required this.friend,
  });
  
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          if (friend.id.isNotEmpty) {
            context.push('../${friend.id}');
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.gold.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Friend avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[850],
                    image: friend.imageUrl != null && friend.imageUrl!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(friend.imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: friend.imageUrl == null || friend.imageUrl!.isEmpty
                      ? Center(
                          child: Text(
                            friend.name.isNotEmpty
                                ? friend.name[0].toUpperCase()
                                : '?',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // Friend info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend.name,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${friend.major}${friend.year.isNotEmpty ? ' • ${friend.year}' : ''}',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Online indicator
                if (friend.isOnline)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Add a Trail/Activity tab to the tab content
class ProfileTrailTab extends StatelessWidget {
  final String? userId;
  
  const ProfileTrailTab({
    Key? key,
    this.userId,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return TrailVisualization(
      userId: userId,
      showHeader: false,
    );
  }
}
