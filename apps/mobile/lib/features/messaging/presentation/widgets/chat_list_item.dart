import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';
import 'package:hive_ui/features/messaging/domain/entities/chat.dart';
import 'package:hive_ui/features/messaging/domain/entities/message.dart';
import 'package:hive_ui/features/messaging/application/providers/messaging_providers.dart';
import 'package:hive_ui/features/messaging/presentation/widgets/user_avatar.dart';
import 'package:hive_ui/features/messaging/presentation/widgets/unread_count_badge.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// Widget for displaying a chat item in a chat list with unread indicators
class ChatListItem extends ConsumerWidget {
  final Chat chat;
  final Message? lastMessage;
  final VoidCallback onTap;
  
  const ChatListItem({
    Key? key,
    required this.chat,
    this.lastMessage,
    required this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(currentUserIdProvider);
    
    // Get unread count
    final unreadCountAsync = ref.watch(unreadMessageCountProvider(chat.id));
    
    // Get other participant info
    final otherParticipants = chat.participantIds
        .where((id) => id != currentUserId)
        .toList();
    
    // For direct chats, get the other user's profile
    Widget avatar;
    if (chat.type == ChatType.direct && otherParticipants.isNotEmpty) {
      avatar = UserAvatar(
        userId: otherParticipants.first,
        imageUrl: chat.imageUrl,
        size: 56,
        showOnlineStatus: true,
      );
    } else {
      // Group chat or space chat avatar
      avatar = Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          shape: BoxShape.circle,
          image: chat.imageUrl != null
              ? DecorationImage(
                  image: NetworkImage(chat.imageUrl!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: chat.imageUrl == null
            ? Icon(
                chat.type == ChatType.group
                    ? Icons.group
                    : Icons.forum,
                color: Colors.white70,
                size: 28,
              )
            : null,
      );
    }
    
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade900,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Chat avatar
            avatar,
            const SizedBox(width: 12),
            
            // Chat details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Chat name and time
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (lastMessage != null)
                        Text(
                          timeago.format(lastMessage!.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Last message preview and unread count
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _getMessagePreview(lastMessage),
                          style: TextStyle(
                            fontSize: 14,
                            color: unreadCountAsync.maybeWhen(
                              data: (count) => count > 0 
                                  ? Colors.white 
                                  : Colors.grey.shade500,
                              orElse: () => Colors.grey.shade500,
                            ),
                            fontWeight: unreadCountAsync.maybeWhen(
                              data: (count) => count > 0 
                                  ? FontWeight.w500 
                                  : FontWeight.normal,
                              orElse: () => FontWeight.normal,
                            ),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      // Unread message badge
                      unreadCountAsync.when(
                        data: (count) => AnimatedUnreadCountBadge(
                          count: count,
                          backgroundColor: AppColors.gold,
                          textColor: Colors.black,
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _getMessagePreview(Message? message) {
    if (message == null) {
      return 'No messages yet';
    }
    
    switch (message.type) {
      case MessageType.text:
        return message.content;
      case MessageType.image:
        return message.content.isNotEmpty 
            ? 'Photo: ${message.content}' 
            : 'Photo';
      case MessageType.video:
        return 'Video';
      case MessageType.audio:
        return 'Audio message';
      case MessageType.file:
        return 'File: ${message.content}';
      case MessageType.event:
        return 'Event: ${message.content}';
      case MessageType.system:
        return message.content;
    }
  }

  /// Formats timestamp for display in the UI
  String _formatTime(DateTime? time) {
    if (time == null) {
      return '';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return DateFormat('h:mm a').format(time);
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(time).inDays < 7) {
      return DateFormat('EEE').format(time); // Day of week
    } else {
      return DateFormat('MM/dd').format(time);
    }
  }
} 