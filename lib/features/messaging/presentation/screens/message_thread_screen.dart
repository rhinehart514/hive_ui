import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/messaging/application/providers/messaging_providers.dart';
import 'package:hive_ui/features/messaging/domain/entities/message.dart';
import 'package:hive_ui/features/messaging/presentation/widgets/message_bubble.dart';
import 'package:hive_ui/features/messaging/presentation/widgets/chat_input.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// Screen for viewing and interacting with message threads
class MessageThreadScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String threadParentId;
  
  const MessageThreadScreen({
    Key? key,
    required this.chatId,
    required this.threadParentId,
  }) : super(key: key);
  
  @override
  ConsumerState<MessageThreadScreen> createState() => _MessageThreadScreenState();
}

class _MessageThreadScreenState extends ConsumerState<MessageThreadScreen> {
  final ScrollController _scrollController = ScrollController();
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Get the parent message
    final parentMessageAsync = ref.watch(
      messageFutureProvider((chatId: widget.chatId, messageId: widget.threadParentId))
    );
    
    // Get thread replies
    final threadsAsync = ref.watch(
      threadMessagesStreamProvider((chatId: widget.chatId, threadParentId: widget.threadParentId))
    );
    
    // Get current user ID
    final currentUserId = ref.watch(currentUserIdProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thread'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Parent message
          parentMessageAsync.when(
            data: (message) {
              if (message == null) {
                return _buildMessageNotFound();
              }
              
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thread label
                    Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 4),
                      child: Text(
                        'Thread',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    
                    // Original message
                    MessageBubble(
                      message: message,
                      isCurrentUser: message.senderId == currentUserId,
                      showSender: true,
                      isGroupChat: true,
                    ),
                    
                    const Divider(color: Colors.grey),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _buildMessageNotFound(),
          ),
          
          // Replies list
          Expanded(
            child: threadsAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No replies yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: messages.length,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isCurrentUser = message.senderId == currentUserId;
                    
                    return MessageBubble(
                      message: message,
                      isCurrentUser: isCurrentUser,
                      showSender: !isCurrentUser,
                      isGroupChat: true,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(
                child: Text('Failed to load replies'),
              ),
            ),
          ),
          
          // Input for replying to thread
          ChatInput(
            chatId: widget.chatId,
            threadParentId: widget.threadParentId,
            onMessageSent: _scrollToBottom,
          ),
        ],
      ),
    );
  }
  
  Widget _buildMessageNotFound() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'Thread not found',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
} 
 
 