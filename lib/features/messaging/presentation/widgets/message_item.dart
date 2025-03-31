import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/messaging/domain/entities/message.dart';
import 'package:hive_ui/features/messaging/presentation/widgets/event_message_content.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:add_2_calendar/add_2_calendar.dart';

class MessageItem extends ConsumerWidget {
  final Message message;
  final bool isCurrentUser;
  final Message? parentMessage;
  final Function(Message)? onReplyTap;
  final Function(Message)? onThreadTap;

  const MessageItem({
    Key? key,
    required this.message,
    required this.isCurrentUser,
    this.parentMessage,
    this.onReplyTap,
    this.onThreadTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final containerColor = isCurrentUser
        ? AppColors.cardBackground.withOpacity(0.7)
        : AppColors.cardBackground.withOpacity(0.4);

    final alignment =
        isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12.0,
        vertical: 4.0,
      ),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          // Sender name (only for non-current user messages)
          if (!isCurrentUser)
            Padding(
              padding: const EdgeInsets.only(left: 12.0, bottom: 4.0),
              child: Text(
                message.senderName,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          // Parent message for replies
          if (parentMessage != null)
            GestureDetector(
              onTap: () {
                if (onThreadTap != null) {
                  onThreadTap!(parentMessage!);
                }
              },
              child: Container(
                margin: EdgeInsets.only(
                  bottom: 4.0,
                  left: isCurrentUser ? 40.0 : 0.0,
                  right: isCurrentUser ? 0.0 : 40.0,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: AppColors.cardBorder.withOpacity(0.5),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parentMessage!.senderName,
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 12.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      parentMessage!.content,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

          // Main message container
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: AppColors.cardBorder,
                width: 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Message content based on type
                _buildMessageContent(context),

                // Timestamp
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTimestamp(message.timestamp),
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 10.0,
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 4.0),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          color: message.isRead
                              ? AppColors.gold.withOpacity(0.7)
                              : AppColors.textTertiary,
                          size: 12.0,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    // For text messages
    if (message.type == MessageType.text) {
      return Text(
        message.content,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16.0,
        ),
      );
    }

    // For image messages
    else if (message.type == MessageType.image &&
        message.attachmentUrl != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
              message.attachmentUrl!,
              height: 200.0,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return SizedBox(
                  height: 200.0,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(AppColors.gold),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200.0,
                  color: AppColors.cardBackground.withOpacity(0.5),
                  child: const Center(
                    child: Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                    ),
                  ),
                );
              },
            ),
          ),
          if (message.content.isNotEmpty && message.content != '📷 Image')
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                message.content,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14.0,
                ),
              ),
            ),
        ],
      );
    }

    // For video messages
    else if (message.type == MessageType.video &&
        message.attachmentUrl != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 180.0,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Center(
                  child: Icon(
                    Icons.play_circle_fill,
                    color: AppColors.gold,
                    size: 48.0,
                  ),
                ),
              ),
              Positioned(
                bottom: 8.0,
                right: 8.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.videocam,
                        color: AppColors.gold.withOpacity(0.8),
                        size: 12.0,
                      ),
                      const SizedBox(width: 4.0),
                      const Text(
                        'Video',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (message.content.isNotEmpty && message.content != '🎥 Video')
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                message.content,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14.0,
                ),
              ),
            ),
        ],
      );
    }

    // For voice messages
    else if (message.type == MessageType.audio &&
        message.attachmentUrl != null) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12.0,
          vertical: 8.0,
        ),
        decoration: BoxDecoration(
          color: AppColors.cardBackground.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.play_arrow,
              color: AppColors.gold,
              size: 24.0,
            ),
            const SizedBox(width: 8.0),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Voice Message',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Container(
                    height: 20.0,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: LinearProgressIndicator(
                        value: 0.0,
                        backgroundColor: AppColors.surface.withOpacity(0.5),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(AppColors.gold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // For file messages
    else if (message.type == MessageType.file &&
        message.attachmentUrl != null) {
      String fileName = message.content.startsWith('📎 ')
          ? message.content.substring(2)
          : 'File';

      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12.0,
          vertical: 8.0,
        ),
        decoration: BoxDecoration(
          color: AppColors.cardBackground.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.insert_drive_file,
              color: AppColors.gold,
              size: 32.0,
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14.0,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    'Tap to download',
                    style: TextStyle(
                      color: AppColors.gold.withOpacity(0.8),
                      fontSize: 12.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // For event messages
    else if (message.type == MessageType.event && message.eventData != null) {
      return EventMessageContent(
        eventData: message.eventData!,
        isCurrentUser: isCurrentUser,
        onTap: () {
          if (message.eventData != null) {
            _addEventToCalendar(message.eventData!);
          }
        },
      );
    }

    // Default to text display
    return Text(
      message.content,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16.0,
      ),
    );
  }

  void _addEventToCalendar(MessageEventData eventData) {
    final Event event = Event(
      title: eventData.eventTitle,
      description: 'Event shared in chat',
      location: eventData.eventLocation,
      startDate: eventData.eventDateTime,
      endDate: eventData.eventDateTime.add(const Duration(hours: 2)),
    );

    Add2Calendar.addEvent2Cal(event);
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate =
        DateTime(timestamp.year, timestamp.month, timestamp.day);

    final timeFormatter = DateFormat('h:mm a');
    final dateFormatter = DateFormat('MMM d');

    if (messageDate == today) {
      return timeFormatter.format(timestamp);
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return dateFormatter.format(timestamp);
    }
  }
}
