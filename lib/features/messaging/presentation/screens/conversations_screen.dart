import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../providers/mock_messages_provider.dart' as mock;
import 'package:hive_ui/features/messaging/injection.dart' as injection;
import 'package:hive_ui/features/messaging/domain/entities/chat.dart';
import 'package:hive_ui/features/messaging/domain/entities/message.dart';
import 'chat_screen.dart';

class ConversationsScreen extends ConsumerWidget {
  final bool useMockData;

  const ConversationsScreen({
    super.key,
    this.useMockData = true, // Default to mock data for now
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_square),
            onPressed: () {
              // New message functionality will be implemented later
            },
          ),
        ],
      ),
      body: useMockData ? _buildMockConversationsList(context, ref) : _buildLiveConversationsList(context, ref),
    );
  }

  Widget _buildMockConversationsList(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(mock.mockConversationsProvider);

    return ListView.separated(
      itemCount: conversations.length,
      separatorBuilder: (context, index) => const Divider(
        height: 1,
        indent: 80,
      ),
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        final lastMessage = conversation.messages.last;
        
        return ListTile(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  chatId: conversation.id,
                  chatName: conversation.name,
                  useMockData: true,
                ),
              ),
            );
          },
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: NetworkImage(conversation.avatarUrl),
              ),
              if (conversation.isOnline)
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
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            conversation.name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            lastMessage.content,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontSize: 14,
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeago.format(lastMessage.timestamp, allowFromNow: true),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 4),
              if (!lastMessage.isMe && lastMessage.status != mock.MessageStatus.read)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLiveConversationsList(BuildContext context, WidgetRef ref) {
    final chatsStream = ref.watch(injection.userChatsStreamProvider);

    return chatsStream.when(
      data: (chats) {
        if (chats.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.message_outlined,
                  size: 64,
                  color: Theme.of(context).disabledColor,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No conversations yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    // New message functionality will be implemented later
                  },
                  child: const Text('Start a conversation'),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: chats.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final Chat chat = chats[index];
            final bool isGroup = chat.type == ChatType.group;
            final String? lastMessageText = chat.lastMessageText;
            final int unreadCount = chat.getUnreadCountForUser(
              ref.read(injection.currentUserIdProvider) ?? '',
            );

            return ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      chatId: chat.id,
                      chatName: chat.title,
                      chatAvatar: chat.imageUrl,
                      isGroupChat: isGroup,
                      useMockData: false,
                    ),
                  ),
                );
              },
              leading: CircleAvatar(
                radius: 28,
                backgroundImage: chat.imageUrl != null ? NetworkImage(chat.imageUrl!) : null,
                child: chat.imageUrl == null
                    ? Icon(isGroup ? Icons.group : Icons.person)
                    : null,
              ),
              title: Text(
                chat.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: lastMessageText != null
                  ? Text(
                      lastMessageText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (chat.lastMessageAt != null)
                    Text(
                      timeago.format(chat.lastMessageAt!),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  if (unreadCount > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text('Error loading conversations: $error'),
      ),
    );
  }
} 