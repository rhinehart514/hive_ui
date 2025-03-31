import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/features/messaging/domain/entities/chat.dart';
import 'package:hive_ui/features/messaging/injection.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/app_icons.dart';
import 'package:hive_ui/components/buttons.dart';

/// Main messaging page that displays a user's chats and allows navigation to chat screens
class MessagingPage extends ConsumerWidget {
  const MessagingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsStream = ref.watch(userChatsStreamProvider);

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
      body: chatsStream.when(
        data: (chats) {
          if (chats.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildChatList(context, chats);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Error loading chats: $error',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
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

  Widget _buildChatList(BuildContext context, List<Chat> chats) {
    // Sort chats by last message time
    final sortedChats = [...chats];
    sortedChats.sort((a, b) {
      if (a.lastMessageAt == null && b.lastMessageAt == null) return 0;
      if (a.lastMessageAt == null) return 1;
      if (b.lastMessageAt == null) return -1;
      return b.lastMessageAt!.compareTo(a.lastMessageAt!);
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

  Widget _buildChatTile(BuildContext context, Chat chat) {
    return InkWell(
      onTap: () => _navigateToChat(context, chat),
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
          leading: _buildChatAvatar(chat),
          title: Text(
            chat.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            chat.getPreviewText(),
            style: const TextStyle(
              color: Colors.white54,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: chat.lastMessageAt != null
              ? Text(
                  _formatChatTime(chat.lastMessageAt!),
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

  Widget _buildChatAvatar(Chat chat) {
    if (chat.imageUrl != null && chat.imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundColor: AppColors.gold.withOpacity(0.2),
        backgroundImage: NetworkImage(chat.imageUrl!),
      );
    }

    IconData iconData;
    Color backgroundColor;

    switch (chat.type) {
      case ChatType.direct:
        iconData = Icons.person;
        backgroundColor = AppColors.gold.withOpacity(0.2);
        break;
      case ChatType.group:
        iconData = Icons.group;
        backgroundColor = Colors.purpleAccent.withOpacity(0.2);
        break;
      case ChatType.club:
        iconData = Icons.school;
        backgroundColor = Colors.blueAccent.withOpacity(0.2);
        break;
      case ChatType.event:
        iconData = Icons.event;
        backgroundColor = Colors.greenAccent.withOpacity(0.2);
        break;
    }

    return CircleAvatar(
      radius: 28,
      backgroundColor: backgroundColor,
      child: Icon(
        iconData,
        color: Colors.white,
        size: 24,
      ),
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

  void _navigateToChat(BuildContext context, Chat chat) {
    context.push('/messaging/chat/${chat.id}', extra: {
      'chatName': chat.title,
      'chatAvatar': chat.imageUrl,
      'isGroupChat': chat.type != ChatType.direct,
    });
  }

  void _navigateToCreateChat(BuildContext context) {
    context.push('/messaging/create');
  }
}
