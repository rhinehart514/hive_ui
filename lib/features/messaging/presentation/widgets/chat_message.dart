import 'package:flutter/material.dart';
import 'package:hive_ui/features/messaging/domain/entities/message.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:intl/intl.dart';

/// A widget that displays a message in a chat bubble
class ChatMessage extends StatelessWidget {
  final Message message;
  final String currentUserId;
  final bool showSenderInfo;
  final bool isLastInGroup;

  const ChatMessage({
    Key? key,
    required this.message,
    required this.currentUserId,
    this.showSenderInfo = false,
    this.isLastInGroup = false,
  }) : super(key: key);

  bool get _isCurrentUser => message.senderId == currentUserId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 2,
        bottom: isLastInGroup ? 12 : 2,
        left: 16,
        right: 16,
      ),
      child: Column(
        crossAxisAlignment:
            _isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Sender name
          if (showSenderInfo && !_isCurrentUser)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: Text(
                message.senderName,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          // Message bubble
          Row(
            mainAxisAlignment: _isCurrentUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Avatar for other users
              if (!_isCurrentUser && showSenderInfo) _buildAvatar(),

              // Bubble
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  decoration: BoxDecoration(
                    color: _getBubbleColor(),
                    borderRadius: _getBubbleBorderRadius(),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: _buildMessageContent(context),
                ),
              ),
            ],
          ),

          // Timestamp
          if (isLastInGroup)
            Padding(
              padding: EdgeInsets.only(
                top: 4,
                left: _isCurrentUser ? 0 : 12,
                right: _isCurrentUser ? 12 : 0,
              ),
              child: Text(
                _formatTimestamp(message.timestamp),
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white38,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (message.senderAvatar != null && message.senderAvatar!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: CircleAvatar(
          radius: 16,
          backgroundImage: NetworkImage(message.senderAvatar!),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: Colors.grey.withOpacity(0.2),
        child: Text(
          message.senderName.isNotEmpty
              ? message.senderName[0].toUpperCase()
              : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content,
          style: TextStyle(
            color: _isCurrentUser ? Colors.black : Colors.white,
            fontSize: 15,
          ),
        );
      case MessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                message.attachmentUrl ?? '',
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return SizedBox(
                    height: 150,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                (loadingProgress.expectedTotalBytes ?? 1)
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
            if (message.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  message.content,
                  style: TextStyle(
                    color: _isCurrentUser ? Colors.black : Colors.white,
                    fontSize: 15,
                  ),
                ),
              ),
          ],
        );
      default:
        return Text(
          message.content,
          style: TextStyle(
            color: _isCurrentUser ? Colors.black : Colors.white,
            fontSize: 15,
          ),
        );
    }
  }

  Color _getBubbleColor() {
    if (_isCurrentUser) {
      return AppColors.gold;
    } else {
      return Colors.grey.shade800;
    }
  }

  BorderRadius _getBubbleBorderRadius() {
    const double radius = 18;

    if (_isCurrentUser) {
      return const BorderRadius.only(
        topLeft: Radius.circular(radius),
        topRight: Radius.circular(radius),
        bottomLeft: Radius.circular(radius),
        bottomRight: Radius.circular(radius / 3),
      );
    } else {
      return const BorderRadius.only(
        topLeft: Radius.circular(radius),
        topRight: Radius.circular(radius),
        bottomRight: Radius.circular(radius),
        bottomLeft: Radius.circular(radius / 3),
      );
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    final timeFormatter = DateFormat('h:mm a');
    final timeString = timeFormatter.format(timestamp);

    if (messageDate == today) {
      return timeString;
    } else if (messageDate == yesterday) {
      return 'Yesterday, $timeString';
    } else if (now.difference(timestamp).inDays < 7) {
      final dayFormatter = DateFormat('EEEE');
      return '${dayFormatter.format(timestamp)}, $timeString';
    } else {
      final dateFormatter = DateFormat('MMM d');
      return '${dateFormatter.format(timestamp)}, $timeString';
    }
  }
}
