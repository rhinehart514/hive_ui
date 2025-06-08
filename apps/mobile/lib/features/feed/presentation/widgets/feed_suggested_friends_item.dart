import 'package:flutter/material.dart';
// For kDebugMode
import 'package:hive_ui/features/feed/presentation/widgets/feed_suggested_friend_card.dart';
import 'package:hive_ui/features/friends/domain/entities/suggested_friend.dart';
import 'feed_section_header.dart';

/// A widget that displays a horizontal list of suggested friends in the feed
class FeedSuggestedFriendsItem extends StatelessWidget {
  /// The list of suggested friends to display
  final List<SuggestedFriend> suggestedFriends;

  /// Constructor
  const FeedSuggestedFriendsItem({
    Key? key,
    required this.suggestedFriends,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (suggestedFriends.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 8),
          child: FeedSectionHeader(
            title: 'PEOPLE YOU MAY KNOW',
            icon: Icons.people_alt_outlined,
          ),
        ),
        SizedBox(
          height: 280, // Fixed height for the container
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: suggestedFriends.length,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemBuilder: (context, index) {
              final suggestion = suggestedFriends[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SizedBox(
                  width: 260, // Fixed width for each card
                  child: FeedSuggestedFriendCard(
                    suggestedFriend: suggestion,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
} 