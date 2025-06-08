import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/messaging/domain/entities/message.dart';
import 'package:hive_ui/features/messaging/presentation/widgets/message_bubble.dart';
import 'package:hive_ui/features/messaging/presentation/widgets/chat_input.dart';
import 'package:hive_ui/features/messaging/presentation/screens/message_thread_screen.dart';
import 'package:hive_ui/features/spaces/presentation/providers/space_chat_provider.dart' as space_chat;
import 'package:hive_ui/features/spaces/presentation/providers/space_providers.dart';
import 'package:hive_ui/features/messaging/application/providers/messaging_providers.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A widget that displays a space's message board with thread support
class SpaceMessageBoard extends ConsumerStatefulWidget {
  /// The ID of the space whose message board to display
  final String spaceId;
  
  /// Optional scroll controller for the message list
  final ScrollController? scrollController;
  
  /// Constructor
  const SpaceMessageBoard({
    Key? key,
    required this.spaceId,
    this.scrollController,
  }) : super(key: key);
  
  @override
  ConsumerState<SpaceMessageBoard> createState() => _SpaceMessageBoardState();
}

class _SpaceMessageBoardState extends ConsumerState<SpaceMessageBoard> {
  late ScrollController _scrollController;
  
  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
  }
  
  @override
  void dispose() {
    // Only dispose if we created the controller
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
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
    // Get the space entity from the provider
    final spaceAsync = ref.watch(spaceProvider(widget.spaceId));
    
    return spaceAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Failed to load space')),
      data: (space) {
        if (space == null) {
          return const Center(child: Text('Space not found'));
        }
        
        // Get space chat ID (or create if doesn't exist)
        final spaceChatAsync = ref.watch(space_chat.spaceChatProvider(widget.spaceId));
        
        return spaceChatAsync.when(
          data: (chatId) {
            if (chatId == null) {
              return const Center(child: Text('Unable to load message board'));
            }
            
            // Get screen width to determine if we're on a small device
            final screenWidth = MediaQuery.of(context).size.width;
            final isSmallScreen = screenWidth < 500; // Threshold for small screens
            
            // For small screens (mobile devices), show a floating action button instead of the full UI
            if (isSmallScreen) {
              return Stack(
                children: [
                  // Empty chat indicator
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 48,
                          color: Colors.grey.withOpacity(0.7),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Tap the button below to open\nthe space discussion',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Button to open the full message board on mobile
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: InkWell(
                      onTap: () => _openMobileMessageInput(chatId),
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outlined,
                          color: Colors.black,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            
            // On larger screens, show the full message board UI
            // Get chat messages
            final messagesAsync = ref.watch(chatMessagesStreamProvider(chatId));
            
            // Get pinned messages
            final pinnedMessagesAsync = ref.watch(space_chat.pinnedMessagesProvider(chatId));
            
            return Column(
              children: [
                // Pinned messages section
                pinnedMessagesAsync.when(
                  data: (pinnedMessages) {
                    if (pinnedMessages.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    
                    return _buildPinnedMessagesSection(pinnedMessages);
                  },
                  loading: () => const SizedBox(height: 4),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                
                // Messages list
                Expanded(
                  child: messagesAsync.when(
                    data: (messages) {
                      if (messages.isEmpty) {
                        return const Center(
                          child: Text(
                            'No messages yet. Start a conversation!',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }
                      
                      return _buildMessagesList(messages, chatId);
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const Center(
                      child: Text('Failed to load messages'),
                    ),
                  ),
                ),
                
                // Message input
                ChatInput(
                  chatId: chatId,
                  onMessageSent: () => _scrollToBottom(),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(
            child: Text('Failed to load message board'),
          ),
        );
      },
    );
  }
  
  Widget _buildPinnedMessagesSection(List<Message> pinnedMessages) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'PINNED MESSAGES',
              style: TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: pinnedMessages.length,
              itemBuilder: (context, index) {
                final message = pinnedMessages[index];
                return _buildPinnedMessageCard(message);
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPinnedMessageCard(Message message) {
    return GestureDetector(
      onTap: () => _showMessage(message),
      child: Container(
        width: 200,
        margin: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.gold.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                message.senderName,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  message.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMessagesList(List<Message> messages, String chatId) {
    final currentUserAsync = ref.watch(space_chat.currentUserProvider);
    
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      itemCount: messages.length,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemBuilder: (context, index) {
        final message = messages[index];
        final isCurrentUser = message.senderId == currentUserAsync?.uid;
        
        // Check if this is a thread parent
        final hasReplies = message.hasReplies;
        
        return Column(
          children: [
            MessageBubble(
              message: message,
              isCurrentUser: isCurrentUser,
              showSender: true,
              isGroupChat: true,
              onLongPress: () => _showMessageOptions(message, chatId),
            ),
            
            // Show thread indicators for messages with replies
            if (hasReplies)
              _buildThreadIndicator(message),
          ],
        );
      },
    );
  }
  
  Widget _buildThreadIndicator(Message message) {
    return GestureDetector(
      onTap: () => _navigateToThread(message),
      child: Container(
        margin: const EdgeInsets.only(left: 40, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gold.withOpacity(0.3)),
        ),
        child: Text(
          '${message.replyCount} ${message.replyCount == 1 ? 'reply' : 'replies'}',
          style: const TextStyle(
            color: AppColors.gold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
  
  void _navigateToThread(Message message) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MessageThreadScreen(
          chatId: message.chatId,
          threadParentId: message.id,
        ),
      ),
    );
  }
  
  void _showMessage(Message message) {
    // Navigate to the specific message or highlight it
    // If it has a thread, go to the thread
    if (message.hasReplies || message.threadParentId != null) {
      _navigateToThread(message.threadParentId != null 
          ? Message(
              id: message.threadParentId!,
              chatId: message.chatId,
              senderId: message.senderId,
              senderName: message.senderName,
              content: '',
              timestamp: message.timestamp,
              isRead: true,
              type: MessageType.text,
            )
          : message);
    }
  }
  
  void _showMessageOptions(Message message, String chatId) {
    HapticFeedback.mediumImpact();
    
    // Check if user can pin messages
    final canPin = ref.read(space_chat.canPinMessagesProvider(widget.spaceId));
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.9),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply, color: AppColors.gold),
              title: const Text('Reply in Thread'),
              onTap: () {
                Navigator.pop(context);
                _navigateToThread(message);
              },
            ),
            if (message.hasReplies)
              ListTile(
                leading: const Icon(Icons.forum_outlined, color: AppColors.gold),
                title: const Text('View Thread'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToThread(message);
                },
              ),
            // Add pin option for moderators/admins
            if (canPin)
              ListTile(
                leading: Icon(
                  message.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: AppColors.gold,
                ),
                title: Text(message.isPinned ? 'Unpin Message' : 'Pin Message'),
                onTap: () {
                  Navigator.pop(context);
                  _toggleMessagePin(message, chatId);
                },
              ),
          ],
        ),
      ),
    );
  }
  
  void _toggleMessagePin(Message message, String chatId) {
    final messageRepo = ref.read(messageRepositoryProvider);
    if (message.isPinned) {
      messageRepo.unpinMessage(chatId, message.id);
    } else {
      messageRepo.pinMessage(chatId, message.id);
    }
  }

  // Add a method to open the message input in a bottom sheet for mobile
  void _openMobileMessageInput(String chatId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Drag handle
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 4),
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                
                // Header
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'Space Discussion',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                
                // Message list
                Expanded(
                  child: _buildMessagesList(
                    ref.watch(chatMessagesStreamProvider(chatId)).value ?? [],
                    chatId
                  ),
                ),
                
                // Input
                ChatInput(
                  chatId: chatId,
                  onMessageSent: () {
                    // No need to scroll in the bottom sheet as new messages
                    // will appear above the input automatically
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 