import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/messaging/controllers/messaging_controller.dart';
import 'package:hive_ui/features/messaging/presentation/widgets/message_bubble.dart';
import '../providers/mock_messages_provider.dart' as mock;
import 'package:hive_ui/features/messaging/application/providers/messaging_providers.dart' as providers;

/// Screen that displays messages in a specific chat
class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String chatName;
  final String? chatAvatar;
  final bool isGroupChat;
  final bool useMockData;

  const ChatScreen({
    Key? key,
    required this.chatId,
    required this.chatName,
    this.chatAvatar,
    this.isGroupChat = false,
    this.useMockData = true, // Default to mock data
  }) : super(key: key);

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();

    if (!widget.useMockData) {
      // Set current chat in controller for live data
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(messagingControllerProvider).setCurrentChat(widget.chatId);
        ref.read(messagingControllerProvider).markChatAsRead(widget.chatId);
        _focusNode.addListener(_handleFocusChange);
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();

    if (!widget.useMockData && _isTyping) {
      ref.read(messagingControllerProvider).updateTypingStatus(widget.chatId, false);
    }

    super.dispose();
  }

  void _handleFocusChange() {
    if (widget.useMockData) return;

    final bool hasFocus = _focusNode.hasFocus;
    if (hasFocus != _isTyping) {
      setState(() {
        _isTyping = hasFocus;
      });
      ref.read(messagingControllerProvider).updateTypingStatus(widget.chatId, hasFocus);
    }
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    if (widget.useMockData) {
      _sendMockMessage(content);
    } else {
      _sendLiveMessage(content);
    }

    _messageController.clear();
    _scrollToBottom();
  }

  void _sendMockMessage(String content) {
    final conversations = ref.read(mock.mockConversationsProvider.notifier);
    final updatedConversations = ref.read(mock.mockConversationsProvider).map((conv) {
      if (conv.id == widget.chatId) {
        final newMessage = mock.Message(
          content: content,
          senderId: "1", // Current user ID
          isMe: true,
        );
        return mock.Conversation(
          id: conv.id,
          name: conv.name,
          avatarUrl: conv.avatarUrl,
          isOnline: conv.isOnline,
          messages: [...conv.messages, newMessage],
        );
      }
      return conv;
    }).toList();

    conversations.state = updatedConversations;
  }

  void _sendLiveMessage(String content) {
    ref.read(messagingControllerProvider).sendTextMessage(
      widget.chatId,
      content,
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          Expanded(
            child: widget.useMockData
                ? _buildMockMessageList()
                : _buildLiveMessageList(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    if (widget.useMockData) {
      final conversation = ref.watch(mock.mockConversationsProvider)
          .firstWhere((conv) => conv.id == widget.chatId);

      return AppBar(
        title: Column(
          children: [
            Text(
              widget.chatName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            if (conversation.isOnline)
              const Text(
                'Online',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.video_call),
            onPressed: () {
              // Video call functionality will be implemented later
            },
          ),
        ],
      );
    }

    return AppBar(
      title: Text(widget.chatName),
      actions: [
        if (widget.isGroupChat)
          IconButton(
            icon: const Icon(Icons.group),
            onPressed: () {
              // Group info functionality will be implemented later
            },
          ),
      ],
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildMockMessageList() {
    final conversation = ref.watch(mock.mockConversationsProvider)
        .firstWhere((conv) => conv.id == widget.chatId);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: conversation.messages.length,
      itemBuilder: (context, index) {
        final message = conversation.messages[index];
        final showAvatar = index == 0 ||
            conversation.messages[index - 1].senderId != message.senderId;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment:
                message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!message.isMe && showAvatar) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(conversation.avatarUrl),
                ),
                const SizedBox(width: 8),
              ],
              if (!message.isMe && !showAvatar)
                const SizedBox(width: 40),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: message.isMe
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: message.isMe ? Colors.white : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLiveMessageList() {
    final messagesStream = ref.watch(providers.chatMessagesStreamProvider(widget.chatId));

    return messagesStream.when(
      data: (messages) {
        if (messages.isEmpty) {
          return const Center(
            child: Text('No messages yet'),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            return MessageBubble(
              message: message,
              isCurrentUser: message.senderId == ref.read(providers.currentUserIdProvider),
              showSenderInfo: widget.isGroupChat,
              isGroupChat: widget.isGroupChat,
              senderName: message.senderName,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading messages: $error'),
      ),
    );
  }
}

