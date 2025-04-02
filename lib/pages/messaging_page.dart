import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/features/messaging/domain/entities/chat.dart';
import 'package:hive_ui/features/messaging/injection.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/app_icons.dart';
import 'package:hive_ui/components/buttons.dart';
import 'package:hive_ui/core/navigation/routes.dart';
import 'package:hive_ui/features/messaging/presentation/providers/mock_messages_provider.dart' as mock;

/// Main messaging page that displays a user's chats and allows navigation to chat screens
class MessagingPage extends ConsumerWidget {
  final bool useMockData;
  
  const MessagingPage({
    Key? key,
    this.useMockData = true, // Default to mock data
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chats = useMockData 
      ? ref.watch(mock.mockConversationsProvider)
      : ref.watch(userChatsStreamProvider).value ?? [];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
        ],
      ),
      body: chats.isEmpty
          ? _buildEmptyState(context)
          : _buildChatList(context, chats),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.gold,
        onPressed: () => _navigateToCreateChat(context),
        heroTag: 'chat_list_fab',
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            AppIcons.message,
            size: 80,
            color: Colors.white24,
          ),
          const SizedBox(height: 16),
          const Text(
            'No conversations yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start chatting with friends, clubs, and events',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          HiveButton(
            text: 'Start a conversation',
            onPressed: () => _navigateToCreateChat(context),
            variant: HiveButtonVariant.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildChatList(BuildContext context, List<dynamic> chats) {
    // Sort chats by last message time
    final sortedChats = [...chats];
    sortedChats.sort((a, b) {
      final aTime = a is Chat ? a.lastMessageAt : a.lastMessageTime;
      final bTime = b is Chat ? b.lastMessageAt : b.lastMessageTime;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });

    return ListView.builder(
      itemCount: sortedChats.length,
      padding: const EdgeInsets.only(bottom: 80),
      itemBuilder: (context, index) {
        final chat = sortedChats[index];
        return _buildChatTile(context, chat);
      },
    );
  }

  Widget _buildChatTile(BuildContext context, dynamic chat) {
    final bool isMockChat = chat is mock.Conversation;
    final String title = isMockChat ? chat.name : chat.title;
    final String? imageUrl = isMockChat ? chat.avatarUrl : chat.imageUrl;
    final String id = chat.id;
    final bool isOnline = isMockChat ? chat.isOnline : false;
    final String previewText = isMockChat 
        ? chat.messages.isNotEmpty ? chat.messages.last.content : ''
        : chat.lastMessageText ?? '';
    final DateTime? timestamp = isMockChat 
        ? chat.lastMessageTime 
        : chat.lastMessageAt;

    return InkWell(
      onTap: () => _navigateToChat(context, id, title, imageUrl, isMockChat),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withOpacity(0.1),
              width: 0.5,
            ),
          ),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: _buildChatAvatar(imageUrl, isOnline),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            previewText,
            style: const TextStyle(
              color: Colors.white54,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: timestamp != null
              ? Text(
                  _formatChatTime(timestamp),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildChatAvatar(String? imageUrl, bool isOnline) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.gold.withOpacity(0.2),
          backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
          child: imageUrl == null ? const Icon(Icons.person) : null,
        ),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.black,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _formatChatTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    if (messageDate == today) {
      // Format as time for today
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(timestamp).inDays < 7) {
      // Format as day of week for this week
      final dayOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return dayOfWeek[timestamp.weekday - 1];
    } else {
      // Format as date for older messages
      return '${timestamp.month}/${timestamp.day}';
    }
  }

  void _navigateToChat(BuildContext context, String id, String title, String? imageUrl, bool useMockData) {
    context.push('/messaging/chat/$id', extra: {
      'chatName': title,
      'chatAvatar': imageUrl,
      'isGroupChat': false,
      'useMockData': useMockData,
    });
  }

  void _navigateToCreateChat(BuildContext context) {
    context.push(AppRoutes.createChat);
  }
}
