import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/features/friends/domain/entities/suggested_friend.dart';
import 'package:hive_ui/features/friends/presentation/providers/suggested_friends_provider.dart' as local_providers;
import 'package:hive_ui/features/friends/presentation/widgets/suggested_friend_card.dart';
import 'package:hive_ui/providers/friend_providers.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:go_router/go_router.dart';

/// A widget that displays a list of suggested friends
class SuggestedFriendsList extends ConsumerWidget {
  /// Optional filter for match criteria
  final MatchCriteria? filterCriteria;
  
  /// Optional title for the list
  final String? title;
  
  /// Maximum number of friends to display
  final int limit;
  
  /// Whether to use a horizontal scrolling list
  final bool horizontal;
  
  const SuggestedFriendsList({
    super.key,
    this.filterCriteria,
    this.title,
    this.limit = 5,
    this.horizontal = false,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestedFriends = ref.watch(
      filterCriteria != null
          ? local_providers.filteredSuggestedFriendsProvider(filterCriteria)
          : local_providers.suggestedFriendsProvider,
    );
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Optional title
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              title!,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
        // List content with state handling
        suggestedFriends.when(
          data: (friends) {
            if (friends.isEmpty) {
              return _buildEmptyState();
            }
            
            // Limit the number of friends to display
            final displayFriends = friends.take(limit).toList();
            
            return horizontal
                ? _buildHorizontalList(context, displayFriends, ref)
                : _buildVerticalList(context, displayFriends, ref);
          },
          loading: () => _buildLoadingState(),
          error: (error, stackTrace) => _buildErrorState(error),
        ),
      ],
    );
  }
  
  /// Build a vertical list of suggested friends
  Widget _buildVerticalList(
    BuildContext context, 
    List<SuggestedFriend> friends,
    WidgetRef ref,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: friends.length,
      itemBuilder: (context, index) {
        final friend = friends[index];
        return SuggestedFriendCard(
          suggestedFriend: friend,
          onCardTapped: () => _navigateToProfile(context, friend),
          onRequestPressed: () => _sendFriendRequest(context, friend, ref),
        );
      },
    );
  }
  
  /// Build a horizontal scrolling list of suggested friends
  Widget _buildHorizontalList(
    BuildContext context, 
    List<SuggestedFriend> friends,
    WidgetRef ref,
  ) {
    return SizedBox(
      height: 220, // Fixed height for horizontal cards
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: friends.length,
        itemBuilder: (context, index) {
          final friend = friends[index];
          // Wrap in a fixed width container for horizontal layout
          return SizedBox(
            width: 280,
            child: SuggestedFriendCard(
              suggestedFriend: friend,
              onCardTapped: () => _navigateToProfile(context, friend),
              onRequestPressed: () => _sendFriendRequest(context, friend, ref),
            ),
          );
        },
      ),
    );
  }
  
  /// Build an empty state when no suggestions are available
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              color: Colors.white.withOpacity(0.5),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'No suggestions available',
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build a loading state with shimmer effect
  Widget _buildLoadingState() {
    return horizontal
        ? _buildHorizontalLoadingState()
        : _buildVerticalLoadingState();
  }
  
  /// Build loading shimmer for vertical list
  Widget _buildVerticalLoadingState() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3, // Show 3 loading cards
      itemBuilder: (context, index) {
        return _buildLoadingCard();
      },
    );
  }
  
  /// Build loading shimmer for horizontal list
  Widget _buildHorizontalLoadingState() {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3, // Show 3 loading cards
        itemBuilder: (context, index) {
          return SizedBox(
            width: 280,
            child: _buildLoadingCard(),
          );
        },
      ),
    );
  }
  
  /// Build a single loading card with shimmer effect
  Widget _buildLoadingCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Shimmer avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Shimmer name
                    Container(
                      width: 120,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Shimmer status
                    Container(
                      width: 80,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Shimmer match
                    Container(
                      width: 100,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Shimmer button
          Container(
            width: double.infinity,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build an error state
  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red[400],
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading suggestions',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
  
  /// Navigate to user profile
  void _navigateToProfile(BuildContext context, SuggestedFriend friend) {
    context.push('/profile/${friend.id}');
  }
  
  /// Send a friend request
  void _sendFriendRequest(BuildContext context, SuggestedFriend friend, WidgetRef ref) {
    // Store context-related values before async operation
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // Use the provider from local_providers to avoid ambiguity
    ref.refresh(local_providers.sendFriendRequestProvider(friend.id));
    
    ref.read(local_providers.sendFriendRequestProvider(friend.id).future).then((success) {
      if (!scaffoldMessenger.mounted) return;
      
      if (success) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Friend request sent to ${friend.name}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green[700],
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to send friend request'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }
} 