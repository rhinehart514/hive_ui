import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/messaging/domain/entities/message.dart';
import 'package:hive_ui/features/messaging/application/providers/messaging_providers.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// Widget to display a preview of message threads with reply count
class MessageThreadPreview extends ConsumerWidget {
  final String chatId;
  final String threadParentId;
  final int replyCount;
  final VoidCallback onTap;
  
  const MessageThreadPreview({
    Key? key,
    required this.chatId,
    required this.threadParentId,
    required this.replyCount,
    required this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the parent message if available
    final threadParentAsync = ref.watch(
      messageFutureProvider((chatId: chatId, messageId: threadParentId))
    );
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 6, bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade900.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.gold.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 14,
              color: AppColors.gold.withOpacity(0.7),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: threadParentAsync.when(
                data: (message) => Text(
                  '${replyCount} ${replyCount == 1 ? 'reply' : 'replies'} to "${_truncateMessage(message?.content ?? 'message')}"',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                loading: () => Text(
                  '${replyCount} ${replyCount == 1 ? 'reply' : 'replies'} to thread',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                error: (_, __) => Text(
                  '${replyCount} ${replyCount == 1 ? 'reply' : 'replies'} to thread',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: Colors.white.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }
  
  String _truncateMessage(String message) {
    if (message.length <= 20) return message;
    return '${message.substring(0, 20)}...';
  }
} 
 
 