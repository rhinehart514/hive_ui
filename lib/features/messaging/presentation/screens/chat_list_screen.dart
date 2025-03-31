import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/components/buttons.dart';
import 'package:hive_ui/features/messaging/domain/entities/chat.dart';
import 'package:hive_ui/features/messaging/injection.dart' as injection;
import 'package:intl/intl.dart';
import 'package:hive_ui/theme/app_icons.dart';
import 'package:hive_ui/features/messaging/application/providers/messaging_providers.dart';
import 'package:hive_ui/features/messaging/presentation/widgets/chat_list_item.dart';
import 'package:hive_ui/features/messaging/presentation/widgets/friend_suggestions_list.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// Screen that displays all of a user's chats
class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    
    if (userId == null) {
      return const Center(child: Text('Please log in to view messages'));
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Show search dialog/screen
              // TODO: Implement search functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              // Navigate to find friends screen
              // TODO: Implement navigation to friend finder
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Friend suggestions
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: FriendSuggestionsList(userId: userId),
          ),
          
          // Divider
          const Divider(height: 2, thickness: 1),
          
          // Chats list
          Expanded(
            child: _buildChatsList(userId),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to new message screen
          // TODO: Implement navigation to new message screen
        },
        child: const Icon(Icons.chat),
        backgroundColor: Colors.amber[700],
      ),
    );
  }
  
  Widget _buildChatsList(String userId) {
    return Consumer(
      builder: (context, ref, child) {
        final chatsAsyncValue = ref.watch(userChatsStreamProvider.call(userId));
        
        return chatsAsyncValue.when(
          data: (chats) {
            if (chats.isEmpty) {
              return const Center(
                child: Text(
                  'No messages yet. Start a conversation!',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }
            
            // Sort chats by most recent message
            final sortedChats = _sortChatsByRecency(chats);
            
            return ListView.builder(
              itemCount: sortedChats.length,
              itemBuilder: (context, index) {
                final chat = sortedChats[index];
                return ChatListItem(
                  chat: chat,
                  currentUserId: userId,
                  onTap: () {
                    // Set current chat ID and navigate to chat detail
                    ref.read(currentChatIdProvider.notifier).state = chat.id;
                    
                    Navigator.pushNamed(
                      context,
                      '/chat_detail',
                      arguments: {'chatId': chat.id},
                    );
                  },
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text('Error loading chats: $error'),
          ),
        );
      },
    );
  }
  
  List<Chat> _sortChatsByRecency(List<Chat> chats) {
    return [...chats]..sort((a, b) {
      if (a.lastMessageAt == null) return 1;
      if (b.lastMessageAt == null) return -1;
      return b.lastMessageAt!.compareTo(a.lastMessageAt!);
    });
  }
}
