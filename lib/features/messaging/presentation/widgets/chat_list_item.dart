import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_ui/features/messaging/domain/entities/chat.dart';
import 'package:hive_ui/theme/app_colors.dart';

class ChatListItem extends StatelessWidget {
  final Chat chat;
  final String currentUserId;
  final VoidCallback onTap;

  const ChatListItem({
    Key? key,
    required this.chat,
    required this.currentUserId,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final unreadCount = chat.getUnreadCountForUser(currentUserId);
    final timeString = _formatTime(chat.lastMessageAt);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withOpacity(0.2),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            _buildChatAvatar(),
            const SizedBox(width: 12),
            
            // Chat info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          chat.title,
                          style: TextStyle(
                            fontWeight: unreadCount > 0 
                                ? FontWeight.bold 
                                : FontWeight.normal,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (timeString.isNotEmpty)
                        Text(
                          timeString,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Preview and unread count
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.getPreviewText(),
                          style: TextStyle(
                            color: unreadCount > 0 
                                ? Colors.black87 
                                : Colors.grey[600],
                            fontWeight: unreadCount > 0 
                                ? FontWeight.w500 
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber[700],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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

  Widget _buildChatAvatar() {
    // If chat has an image, use it
    if (chat.imageUrl != null && chat.imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundImage: NetworkImage(chat.imageUrl!),
      );
    }

    // Otherwise use an icon based on chat type
    IconData iconData;
    Color backgroundColor;

    switch (chat.type) {
      case ChatType.direct:
        iconData = Icons.person;
        backgroundColor = Colors.blue;
        break;
      case ChatType.group:
        iconData = Icons.group;
        backgroundColor = Colors.purple;
        break;
      case ChatType.club:
        iconData = Icons.groups;
        backgroundColor = Colors.green;
        break;
      case ChatType.event:
        iconData = Icons.event;
        backgroundColor = Colors.orange;
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