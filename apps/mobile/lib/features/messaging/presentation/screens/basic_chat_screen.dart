import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/features/messaging/domain/entities/message.dart';
import 'package:hive_ui/features/messaging/domain/entities/chat_user.dart';
import 'package:hive_ui/features/messaging/injection.dart' as injection;
import 'package:hive_ui/features/messaging/presentation/widgets/chat_message.dart';
import 'package:hive_ui/features/messaging/presentation/widgets/chat_input.dart';

/// A simplified chat screen that displays messages in a conversation
class BasicChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String chatName;
  final String? chatAvatar;
  final bool isGroupChat;

  const BasicChatScreen({
    Key? key,
    required this.chatId,
    required this.chatName,
    this.chatAvatar,
    this.isGroupChat = false,
  }) : super(key: key);

  @override
  ConsumerState<BasicChatScreen> createState() => _BasicChatScreenState();
}

class _BasicChatScreenState extends ConsumerState<BasicChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;

    // Mark chat as read
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(injection.messagingControllerProvider);
      // Mark chat as read
      controller.markChatAsRead(widget.chatId);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
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
    final messagesStream =
        ref.watch(injection.chatMessagesStreamProvider(widget.chatId));
    final participantsAsync =
        ref.watch(injection.chatParticipantsProvider(widget.chatId));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          children: [
            _buildChatAvatar(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chatName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  participantsAsync.when(
                    data: (participants) {
                      return _buildSubtitle(participants);
                    },
                    loading: () => const Text(
                      'Loading...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Show chat options menu
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: messagesStream.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return _buildEmptyChat();
                }
                return _buildMessageList(messages);
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, _) => Center(
                child: Text(
                  'Error loading messages: $error',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),

          // Message input
          ChatInput(
            chatId: widget.chatId,
            focusNode: _focusNode,
            onMessageSent: _scrollToBottom,
          ),
        ],
      ),
    );
  }

  Widget _buildChatAvatar() {
    if (widget.chatAvatar != null && widget.chatAvatar!.isNotEmpty) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: NetworkImage(widget.chatAvatar!),
      );
    }

    IconData iconData = widget.isGroupChat ? Icons.group : Icons.person;
    Color backgroundColor = widget.isGroupChat
        ? Colors.purpleAccent.withOpacity(0.2)
        : const Color(0xFFE2B253).withOpacity(0.2); // Gold color

    return CircleAvatar(
      radius: 16,
      backgroundColor: backgroundColor,
      child: Icon(
        iconData,
        color: Colors.white,
        size: 14,
      ),
    );
  }

  Widget _buildSubtitle(List<ChatUser> participants) {
    if (participants.isEmpty) {
      return const SizedBox.shrink();
    }

    if (widget.isGroupChat) {
      return Text(
        '${participants.length} participants',
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white54,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    } else {
      // For direct messages, show online status
      final otherUser = participants.firstWhere(
        (p) => p.id != _currentUserId,
        orElse: () => participants.first,
      );

      return Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: otherUser.isOnline ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            otherUser.isOnline ? 'Online' : 'Offline',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white54,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.isGroupChat ? Icons.group : Icons.chat_bubble_outline,
            size: 64,
            color: Colors.white24,
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet with ${widget.chatName}',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Start the conversation by sending a message below',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(List<Message> messages) {
    // Messages come in reverse chronological order (newest first)
    final sortedMessages = messages.toList();

    return ListView.builder(
      controller: _scrollController,
      reverse: true, // Start from the bottom
      padding: const EdgeInsets.only(top: 16, bottom: 16),
      itemCount: sortedMessages.length,
      itemBuilder: (context, index) {
        final message = sortedMessages[index];
        final previousSenderId = index < sortedMessages.length - 1
            ? sortedMessages[index + 1].senderId
            : null;
        final nextSenderId =
            index > 0 ? sortedMessages[index - 1].senderId : null;

        // Determine if this message should show sender info
        final showSenderInfo =
            previousSenderId != message.senderId && widget.isGroupChat;

        // Determine if this is the last message in a group
        final isLastInGroup = nextSenderId != message.senderId;

        return ChatMessage(
          message: message,
          currentUserId: _currentUserId ?? '',
          showSenderInfo: showSenderInfo,
          isLastInGroup: isLastInGroup,
        );
      },
    );
  }
}
