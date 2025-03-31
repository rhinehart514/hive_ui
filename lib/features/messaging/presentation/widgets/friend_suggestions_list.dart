import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/messaging/application/providers/messaging_providers.dart';
import 'package:hive_ui/features/messaging/domain/entities/chat_user.dart';

class FriendSuggestionsList extends ConsumerWidget {
  final String userId;

  const FriendSuggestionsList({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionsAsync = ref.watch(friendChatSuggestionsProvider(userId));

    return suggestionsAsync.when(
      data: (suggestions) {
        if (suggestions.isEmpty) {
          return const SizedBox.shrink(); // Hide if no suggestions
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
              child: Text(
                'Suggested Friends',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: suggestions.length,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemBuilder: (context, index) {
                  final friend = suggestions[index];
                  return _FriendSuggestionItem(
                    friend: friend,
                    onTap: () => _startChat(context, ref, friend),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }

  void _startChat(BuildContext context, WidgetRef ref, ChatUser friend) async {
    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Starting conversation...'),
        duration: Duration(seconds: 1),
      ),
    );
    
    try {
      // Create or get existing chat
      final chatAsync = await ref.read(
        friendChatProvider(friend.id).future,
      );
      
      // Set current chat
      ref.read(currentChatIdProvider.notifier).state = chatAsync.id;
      
      // Navigate to chat
      if (context.mounted) {
        Navigator.pushNamed(
          context,
          '/chat_detail',
          arguments: {'chatId': chatAsync.id},
        );
      }
    } catch (e) {
      // Show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _FriendSuggestionItem extends StatelessWidget {
  final ChatUser friend;
  final VoidCallback onTap;

  const _FriendSuggestionItem({
    Key? key,
    required this.friend,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar
            CircleAvatar(
              radius: 30,
              backgroundImage: friend.avatarUrl != null
                  ? NetworkImage(friend.avatarUrl!)
                  : null,
              backgroundColor: Colors.blue.shade100,
              child: friend.avatarUrl == null
                  ? Text(
                      friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 8),
            // Name
            Text(
              friend.name,
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
} 