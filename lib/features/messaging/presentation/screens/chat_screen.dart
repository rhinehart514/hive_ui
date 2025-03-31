import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/messaging/controllers/messaging_controller.dart';
import 'package:hive_ui/features/messaging/domain/entities/message.dart';
import 'package:hive_ui/features/messaging/domain/entities/chat_user.dart';
import 'package:hive_ui/features/messaging/injection.dart' as injection;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:hive_ui/theme/app_icons.dart';
import 'package:hive_ui/features/messaging/presentation/widgets/online_status_indicator.dart';
import 'package:hive_ui/features/messaging/presentation/widgets/typing_indicator.dart';
import 'package:hive_ui/features/messaging/presentation/widgets/message_bubble.dart';

/// Screen that displays messages in a specific chat
class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String chatName;
  final String? chatAvatar;
  final bool isGroupChat;

  const ChatScreen({
    Key? key,
    required this.chatId,
    required this.chatName,
    this.chatAvatar,
    this.isGroupChat = false,
  }) : super(key: key);

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isTyping = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;

    // Set current chat in controller
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(messagingControllerProvider)
          .setCurrentChat(widget.chatId);
      ref
          .read(messagingControllerProvider)
          .markChatAsRead(widget.chatId);

      // Listen for typing indicator changes
      _focusNode.addListener(_handleFocusChange);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();

    // Stop typing indication when leaving the chat
    if (_isTyping) {
      ref
          .read(messagingControllerProvider)
          .updateTypingStatus(widget.chatId, false);
    }

    super.dispose();
  }

  void _handleFocusChange() {
    final bool hasFocus = _focusNode.hasFocus;
    if (hasFocus != _isTyping) {
      setState(() {
        _isTyping = hasFocus;
      });
      ref
          .read(messagingControllerProvider)
          .updateTypingStatus(widget.chatId, hasFocus);
    }
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    ref.read(messagingControllerProvider).sendTextMessage(
          widget.chatId,
          message,
        );

    _messageController.clear();

    // Scroll to bottom after sending
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatStream =
        ref.watch(injection.chatMessagesStreamProvider(widget.chatId));
    final typingUsersStream =
        ref.watch(injection.typingUsersStreamProvider(widget.chatId));
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
                      return _buildSubtitle(participants, typingUsersStream);
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
            child: chatStream.when(
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
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildChatAvatar() {
    if (widget.chatAvatar != null && widget.chatAvatar!.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage(widget.chatAvatar!),
      );
    }

    IconData iconData = widget.isGroupChat ? Icons.group : AppIcons.message;
    Color backgroundColor = widget.isGroupChat
        ? Colors.purpleAccent.withOpacity(0.2)
        : const Color(0xFFE2B253).withOpacity(0.2); // Gold color

    return CircleAvatar(
      radius: 20,
      backgroundColor: backgroundColor,
      child: Icon(
        iconData,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  Widget _buildSubtitle(List<ChatUser> participants,
      AsyncValue<Map<String, DateTime>> typingUsersStream) {
    // For group chats, just return a typing indicator
    if (widget.isGroupChat) {
      return typingUsersStream.when(
        data: (typingUsers) {
          final typingUserIds = typingUsers.keys.toList();

          if (typingUserIds.isNotEmpty &&
              typingUserIds.any((id) => id != _currentUserId)) {
            return TypingIndicator(
              chatId: widget.chatId,
              participantIds: participants.map((p) => p.id).toList(),
              participantNames: Map.fromEntries(
                participants.map((p) => MapEntry(p.id, p.name))
              ),
              currentUserId: _currentUserId ?? '',
              textStyle: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontStyle: FontStyle.italic,
              ),
            );
          } else {
            return Text(
              '${participants.length} participants',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white54,
              ),
            );
          }
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      );
    } 
    
    // For direct chats, show online status or typing indicator
    final otherParticipant = participants.firstWhere(
      (p) => p.id != _currentUserId,
      orElse: () => participants.isNotEmpty ? participants.first : const ChatUser(
        id: '',
        name: 'Unknown User',
        isOnline: false,
      ),
    );
    
    return typingUsersStream.when(
      data: (typingUsers) {
        final typingUserIds = typingUsers.keys.toList();
        
        if (typingUserIds.isNotEmpty &&
            typingUserIds.any((id) => id == otherParticipant.id)) {
          return const Text(
            'typing...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white70,
              fontStyle: FontStyle.italic,
            ),
          );
        } else {
          return OnlineStatusIndicator(
            userId: otherParticipant.id,
            compactMode: true,
            showOfflineStatus: true,
            textStyle: const TextStyle(
              fontSize: 12,
              color: Colors.white54,
            ),
          );
        }
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.isGroupChat ? Icons.group : AppIcons.message,
            size: 64,
            color: Colors.white24,
          ),
          const SizedBox(height: 16),
          Text(
            widget.isGroupChat
                ? 'Start the conversation in ${widget.chatName}'
                : 'Start a conversation',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Your messages are encrypted and secure',
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
    // Group messages by date
    final groupedMessages = <String, List<Message>>{};
    for (final message in messages) {
      final dateString = _getMessageDateString(message.timestamp);
      if (!groupedMessages.containsKey(dateString)) {
        groupedMessages[dateString] = [];
      }
      groupedMessages[dateString]!.add(message);
    }

    final sortedDates = groupedMessages.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Recent dates first

    return ListView.builder(
      controller: _scrollController,
      reverse: true, // Recent messages at the bottom
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      itemCount: groupedMessages.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final messagesForDate = groupedMessages[date]!;

        return Column(
          children: [
            // Date divider
            _buildDateDivider(date),

            // Messages for this date
            ...messagesForDate.asMap().entries.map((entry) {
              final message = entry.value;
              final isCurrentUser = message.senderId == _currentUserId;
              final showAvatar = !isCurrentUser &&
                  (entry.key == 0 ||
                      messagesForDate[entry.key - 1].senderId !=
                          message.senderId);

              return _buildMessageBubble(message, isCurrentUser, showAvatar);
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildDateDivider(String date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(
            child: Divider(color: Colors.white24),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              date,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ),
          const Expanded(
            child: Divider(color: Colors.white24),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
      Message message, bool isCurrentUser, bool showAvatar) {
    final String? senderPhotoUrl = message.senderAvatar;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 16),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar for other users
          if (!isCurrentUser && showAvatar)
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.withOpacity(0.2),
              backgroundImage:
                  senderPhotoUrl != null ? NetworkImage(senderPhotoUrl) : null,
              child: senderPhotoUrl == null
                  ? const Icon(Icons.person, size: 16, color: Colors.white)
                  : null,
            )
          else if (!isCurrentUser && !showAvatar)
            const SizedBox(width: 32), // Space for avatar

          const SizedBox(width: 8),

          // Message bubble
          MessageBubble(
            message: message,
            isCurrentUser: isCurrentUser,
            showSenderInfo: showAvatar && widget.isGroupChat,
            isGroupChat: widget.isGroupChat,
            senderName: message.senderName,
            onTap: () {
              // Handle message tap
            },
            onLongPress: () {
              // Show message options (reply, delete, etc.)
            },
            onReplyTap: () {
              // Handle message reply
            },
            onThreadTap: message.hasReplies 
                ? () {
                    // Navigate to thread screen
                  } 
                : null,
            onShowReadReceipts: isCurrentUser 
                ? () {
                    // Show read receipts
                  } 
                : null,
            hasThread: message.hasReplies,
            threadRepliesCount: message.replyCount ?? 0,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Attachment button
            IconButton(
              icon: const Icon(Icons.attach_file),
              color: Colors.white70,
              onPressed: () {
                // TODO: Implement attachment menu
              },
            ),

            // Text input
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Message',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade800,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
                onChanged: (value) {
                  // If user was not typing before but is typing now
                  if (!_isTyping && value.isNotEmpty) {
                    setState(() {
                      _isTyping = true;
                    });
                    ref
                        .read(messagingControllerProvider)
                        .updateTypingStatus(widget.chatId, true);
                  }

                  // If user was typing before but is not typing now
                  if (_isTyping && value.isEmpty) {
                    setState(() {
                      _isTyping = false;
                    });
                    ref
                        .read(messagingControllerProvider)
                        .updateTypingStatus(widget.chatId, false);
                  }
                },
              ),
            ),

            // Send button
            IconButton(
              icon: const Icon(Icons.send),
              color: const Color(0xFFE2B253), // Gold color
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  String _getMessageDateString(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
    );

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(messageDate).inDays < 7) {
      return DateFormat('EEEE').format(dateTime); // Day of week
    } else {
      return DateFormat('MMM d, yyyy').format(dateTime);
    }
  }
}
