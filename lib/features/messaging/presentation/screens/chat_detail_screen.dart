import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/messaging/application/providers/messaging_providers.dart';
import 'package:hive_ui/features/messaging/domain/entities/chat_user.dart';
import 'package:hive_ui/features/messaging/domain/entities/message.dart';
import 'package:hive_ui/features/messaging/presentation/widgets/message_bubble.dart';
import 'package:hive_ui/features/messaging/presentation/widgets/typing_indicator.dart';
import 'package:hive_ui/features/messaging/presentation/widgets/chat_input.dart';
import 'package:hive_ui/features/messaging/presentation/widgets/system_message.dart';
import 'package:hive_ui/features/messaging/presentation/widgets/message_search_bar.dart';
import 'package:hive_ui/theme/app_colors.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String chatId;

  const ChatDetailScreen({
    Key? key,
    required this.chatId,
  }) : super(key: key);

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _typingTimer;
  bool _isTyping = false;
  bool _isSearching = false;
  String _searchQuery = '';
  String? _jumpToMessageId;

  @override
  void initState() {
    super.initState();
    
    // Set current chat ID in provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentChatIdProvider.notifier).state = widget.chatId;
      
      // Mark chat as read
      final userId = ref.read(currentUserIdProvider);
      if (userId != null) {
        ref.read(markChatAsReadProvider(widget.chatId));
      }
    });
    
    // Set up listener for typing indicator
    _messageController.addListener(_onTypingChanged);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _onTypingChanged() {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    
    final isCurrentlyTyping = _messageController.text.isNotEmpty;
    
    // Only update if state changed
    if (isCurrentlyTyping != _isTyping) {
      _isTyping = isCurrentlyTyping;
      
      // Update typing status in database
      final useCase = ref.read(messageUseCaseProvider);
      useCase.updateTypingStatus(widget.chatId, userId, _isTyping);
      
      // Reset timer
      _typingTimer?.cancel();
      
      // If no longer typing, immediately clear
      if (!_isTyping) return;
      
      // Set timer to clear typing indicator after 5 seconds of inactivity
      _typingTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          useCase.updateTypingStatus(widget.chatId, userId, false);
          _isTyping = false;
        }
      });
    }
  }

  void _sendMessage() async {
    final content = _messageController.text.trim();
    final userId = ref.read(currentUserIdProvider);
    
    if (content.isEmpty || userId == null) return;
    
    // Clear the input field
    _messageController.clear();
    
    try {
      // Send the message
      await ref.read(
        sendTextMessageProvider(
          (chatId: widget.chatId, content: content),
        ).future,
      );
      
      // Scroll to bottom
      _scrollToBottom();
    } catch (e) {
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
    final userId = ref.watch(currentUserIdProvider);
    
    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view messages')),
      );
    }
    
    return Scaffold(
      appBar: _isSearching 
          ? PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: MessageSearchBar(
                chatId: widget.chatId,
                onClose: () {
                  setState(() {
                    _isSearching = false;
                    _searchQuery = '';
                  });
                },
                onSearch: (query) {
                  setState(() {
                    _searchQuery = query;
                  });
                  // Save the search query to the provider
                  ref.read(chatSearchQueryProvider.notifier).state = query;
                },
              ),
            )
          : _buildAppBar(),
      body: _isSearching && _searchQuery.isNotEmpty
          ? MessageSearchResults(
              chatId: widget.chatId,
              query: _searchQuery,
              onClose: () {
                setState(() {
                  _isSearching = false;
                  _searchQuery = '';
                });
              },
              onMessageSelected: (messageId) {
                // Set the message ID to jump to
                setState(() {
                  _jumpToMessageId = messageId;
                  _isSearching = false;
                  _searchQuery = '';
                });
                
                // TODO: Implement scrolling to specific message
              },
            )
          : _buildChatBody(context),
    );
  }

  Widget _buildChatBody(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    
    if (userId == null) {
      return const Center(child: Text('Please log in to view messages'));
    }
    
    return Column(
      children: [
        // Messages list
        Expanded(
          child: _buildMessagesList(userId),
        ),
        
        // Typing indicator
        TypingIndicator(chatId: widget.chatId),
        
        // Chat input
        ChatInput(
          chatId: widget.chatId,
          onMessageSent: _scrollToBottom,
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final chatAsync = ref.watch(chatParticipantsProvider(widget.chatId));
    
    return AppBar(
      title: chatAsync.when(
        data: (participants) {
          final otherParticipants = participants
              .where((user) => user.id != ref.watch(currentUserIdProvider))
              .toList();
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getChatTitle(otherParticipants),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (otherParticipants.length == 1 && otherParticipants.first.isOnline)
                const Text(
                  'Online',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
            ],
          );
        },
        loading: () => const Text('Loading...'),
        error: (error, stackTrace) => const Text('Chat'),
      ),
      actions: [
        // Search button
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            setState(() {
              _isSearching = true;
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            // Show chat options menu
            // TODO: Implement chat options menu
          },
        ),
      ],
    );
  }

  Widget _buildMessagesList(String userId) {
    return Consumer(
      builder: (context, ref, child) {
        final messagesAsync = ref.watch(chatMessagesStreamProvider(widget.chatId));
        
        return messagesAsync.when(
          data: (messages) {
            if (messages.isEmpty) {
              return const Center(
                child: Text(
                  'No messages yet. Say hello!',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }
            
            // Group messages by date
            final groupedMessages = _groupMessagesByDate(messages);
            
            return RefreshIndicator(
              color: AppColors.gold,
              backgroundColor: Colors.grey.shade900,
              onRefresh: () async {
                // Load older messages
                await ref.read(loadMoreMessagesProvider(widget.chatId).future);
              },
              child: ListView.builder(
                controller: _scrollController,
                reverse: true,
                itemCount: groupedMessages.length,
                padding: const EdgeInsets.only(bottom: 8, top: 8),
                physics: const AlwaysScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final entry = groupedMessages[index];
                  
                  if (entry.isDateHeader) {
                    return _buildDateHeader(entry.date!);
                  } else {
                    // Check if it's a system message
                    final message = entry.message!;
                    if (message.type == MessageType.system) {
                      return SystemMessage(message: message);
                    } else {
                      // Regular message
                      return MessageBubble(
                        message: message,
                        isCurrentUser: message.senderId == userId,
                        showSender: message.senderId != userId,
                      );
                    }
                  }
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text('Error loading messages: $error'),
          ),
        );
      },
    );
  }

  Widget _buildDateHeader(DateTime date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _formatDateHeader(date),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Consumer(
      builder: (context, ref, child) {
        final typingAsync = ref.watch(typingIndicatorsProvider(widget.chatId));
        final participantsAsync = ref.watch(chatParticipantsProvider(widget.chatId));
        
        final currentUserId = ref.watch(currentUserIdProvider);
        if (currentUserId == null) return const SizedBox.shrink();
        
        return typingAsync.when(
          data: (typingUsers) {
            // Filter out current user
            final typing = Map<String, DateTime>.from(typingUsers)
              ..remove(currentUserId);
            
            if (typing.isEmpty) return const SizedBox.shrink();
            
            return participantsAsync.when(
              data: (participants) {
                final typingNames = typing.keys
                    .map((userId) => participants
                        .firstWhere(
                          (p) => p.id == userId,
                          orElse: () => ChatUser(
                            id: userId,
                            name: 'User',
                            isOnline: false,
                            lastActive: DateTime.now(),
                          ),
                        )
                        .name)
                    .join(', ');
                
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$typingNames ${typing.length == 1 ? 'is' : 'are'} typing...',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Attachment button
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: () {
              // TODO: Implement attachment picker
            },
          ),
          
          // Text input
          Expanded(
            child: TextField(
              controller: _messageController,
              maxLines: 5,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Color(0xFFF2F2F2),
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Send button
          CircleAvatar(
            backgroundColor: Colors.amber[700],
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  String _getChatTitle(List<ChatUser> otherParticipants) {
    if (otherParticipants.isEmpty) return 'Chat';
    
    if (otherParticipants.length == 1) {
      return otherParticipants.first.name;
    }
    
    return '${otherParticipants.first.name} and ${otherParticipants.length - 1} others';
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return 'Yesterday';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  List<_MessageOrDateEntry> _groupMessagesByDate(List<Message> messages) {
    final result = <_MessageOrDateEntry>[];
    DateTime? lastDate;
    
    for (var message in messages) {
      final messageDate = DateTime(
        message.timestamp.year,
        message.timestamp.month,
        message.timestamp.day,
      );
      
      if (lastDate == null || messageDate != lastDate) {
        result.add(_MessageOrDateEntry.date(messageDate));
        lastDate = messageDate;
      }
      
      result.add(_MessageOrDateEntry.message(message));
    }
    
    return result;
  }
}

/// Helper class to represent either a message or a date header in the list
class _MessageOrDateEntry {
  final Message? message;
  final DateTime? date;
  
  _MessageOrDateEntry.message(this.message) : date = null;
  _MessageOrDateEntry.date(this.date) : message = null;
  
  bool get isDateHeader => date != null;
}