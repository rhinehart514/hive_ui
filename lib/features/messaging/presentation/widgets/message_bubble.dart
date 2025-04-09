import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/messaging/domain/entities/message.dart';
import 'package:hive_ui/features/messaging/presentation/widgets/message_delivery_indicator.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// Displays a message bubble in the chat
class MessageBubble extends ConsumerStatefulWidget {
  final Message message;
  final bool isCurrentUser;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onReplyTap;
  final VoidCallback? onThreadTap;
  final Function(String)? onAddReaction;
  final VoidCallback? onShowReadReceipts;
  final bool hasThread;
  final int threadRepliesCount;
  final bool isGroupChat;
  final bool showSenderInfo;
  final String? senderName;
  final Message? replyMessage;
  final bool showSender;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isCurrentUser,
    this.onTap,
    this.onLongPress,
    this.onReplyTap,
    this.onThreadTap,
    this.onAddReaction,
    this.onShowReadReceipts,
    this.hasThread = false,
    this.threadRepliesCount = 0,
    this.isGroupChat = false,
    this.showSenderInfo = false,
    this.senderName,
    this.replyMessage,
    this.showSender = false,
  }) : super(key: key);

  @override
  ConsumerState<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends ConsumerState<MessageBubble> {
  double _swipeOffset = 0;
  bool _showQuickReactions = false;
  bool _showActions = false;

  BorderRadius _getBubbleBorderRadius() {
    const double radius = 20.0;
    const double smallRadius = 5.0;

    return widget.isCurrentUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(radius),
            topRight: Radius.circular(smallRadius),
            bottomLeft: Radius.circular(radius),
            bottomRight: Radius.circular(radius),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(smallRadius),
            topRight: Radius.circular(radius),
            bottomLeft: Radius.circular(radius),
            bottomRight: Radius.circular(radius),
          );
  }

  void _handleSwipeComplete(DragEndDetails details) {
    if (_swipeOffset.abs() > 50) {
      // If swiped far enough, trigger reply
      HapticFeedback.mediumImpact();
      widget.onReplyTap?.call();
    }
    setState(() {
      _swipeOffset = 0;
      _showQuickReactions = false;
    });
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      // Only allow swiping in one direction based on message alignment
      if (widget.isCurrentUser && details.delta.dx < 0) {
        _swipeOffset += details.delta.dx;
      } else if (!widget.isCurrentUser && details.delta.dx > 0) {
        _swipeOffset += details.delta.dx;
      }

      // Show quick reactions when swiped enough
      _showQuickReactions = _swipeOffset.abs() > 20;
    });
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final isCurrentUser = widget.isCurrentUser;
    final hasAttachment = message.attachmentUrl != null;
    final isVoiceMessage = message.attachmentType == 'audio';
    final hasReactions = message.reactions != null && message.reactions!.isNotEmpty;

    // Determine bubble alignment and colors
    final alignment = isCurrentUser 
      ? CrossAxisAlignment.end 
      : CrossAxisAlignment.start;
    
    final bubbleColor = isCurrentUser 
      ? AppColors.gold.withOpacity(0.2) 
      : Colors.grey.shade800;
    
    final textColor = isCurrentUser 
      ? Colors.white 
      : Colors.white;
      
    final borderColor = isCurrentUser 
      ? AppColors.gold 
      : Colors.grey.shade700;
    
    return Padding(
      padding: EdgeInsets.only(
        left: isCurrentUser ? 60.0 : 12.0,
        right: isCurrentUser ? 12.0 : 60.0,
        bottom: 8.0,
      ),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          if (!isCurrentUser &&
              widget.isGroupChat &&
              widget.showSenderInfo)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: Text(
                widget.senderName!,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Stack(
            children: [
              // Quick reactions overlay
              if (_showQuickReactions)
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: isCurrentUser ? null : 0,
                  right: isCurrentUser ? 0 : null,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[900]!.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.grey[800]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildQuickReactionButton('❤️'),
                          _buildQuickReactionButton('👍'),
                          _buildQuickReactionButton('😂'),
                          _buildQuickReactionButton('😮'),
                        ],
                      ),
                    ),
                  ),
                ),

              // Message content with swipe gesture
              GestureDetector(
                onHorizontalDragUpdate: _handleHorizontalDragUpdate,
                onHorizontalDragEnd: _handleSwipeComplete,
                onTap: widget.onTap,
                onLongPress: () {
                  HapticFeedback.mediumImpact();
                  if (widget.onLongPress != null) {
                    widget.onLongPress!();
                  }
                  setState(() {
                    _showActions = !_showActions;
                  });
                },
                child: Transform.translate(
                  offset: Offset(_swipeOffset, 0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  message.type == MessageType.text
                                      ? 16.0
                                      : 12.0,
                              vertical: message.type == MessageType.text
                                  ? 12.0
                                  : 8.0,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: _getBubbleBorderRadius(),
                              color: bubbleColor,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              border: Border.all(
                                color: borderColor,
                                width: 1,
                              ),
                            ),
                            child: _buildMessageContent(),
                          ),
                          if (hasReactions)
                            Positioned(
                              bottom: -10,
                              right: isCurrentUser ? null : -10,
                              left: isCurrentUser ? -10 : null,
                              child: _buildReactions(),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: isCurrentUser 
                ? MainAxisAlignment.end 
                : MainAxisAlignment.start,
            children: [
              if (widget.hasThread)
                GestureDetector(
                  onTap: widget.onThreadTap,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4, left: 12),
                    child: Text(
                      '${widget.threadRepliesCount} ${widget.threadRepliesCount == 1 ? 'reply' : 'replies'}',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              if (isCurrentUser && message.id.isNotEmpty) 
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 8),
                  child: MessageDeliveryIndicator(
                    messageId: message.id,
                    recipientId: message.chatId,
                    size: 12,
                    showLabel: false,
                  ),
                ),
            ],
          ),
          if (_showActions)
            _buildMessageActions(),
        ],
      ),
    );
  }

  Widget _buildQuickReactionButton(String emoji) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onAddReaction?.call(emoji);
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageContent() {
    switch (widget.message.type) {
      case MessageType.text:
        return Text(
          widget.message.content,
          style: TextStyle(
            color: widget.isCurrentUser ? AppColors.gold : Colors.white,
            fontSize: 16,
          ),
        );

      case MessageType.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            widget.message.attachmentUrl!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 200,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: double.infinity,
                height: 200,
                color: Colors.grey[900],
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: double.infinity,
                height: 150,
                color: AppColors.cardBackground,
                child: const Center(
                  child: Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 32,
                  ),
                ),
              );
            },
          ),
        );

      case MessageType.audio:
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.play_arrow,
                color: widget.isCurrentUser ? AppColors.gold : Colors.white,
              ),
              const SizedBox(width: 8),
              Container(
                width: 150,
                height: 2,
                decoration: BoxDecoration(
                  color: widget.isCurrentUser
                      ? AppColors.gold.withOpacity(0.3)
                      : Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '0:15',
                style: TextStyle(
                  color: widget.isCurrentUser ? AppColors.gold : Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildReactions() {
    // Group reactions by emoji
    final reactionCounts = <String, int>{};
    for (final reaction in widget.message.reactions ?? []) {
      reactionCounts[reaction.emoji] =
          (reactionCounts[reaction.emoji] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[900]!.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[800]!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: reactionCounts.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              '${entry.key}${entry.value}',
              style: const TextStyle(fontSize: 12),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMessageActions() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade800,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActionButton(
            icon: Icons.emoji_emotions_outlined,
            label: 'React',
            onTap: _showReactionsBottomSheet,
          ),
          _buildActionButton(
            icon: Icons.reply,
            label: 'Reply',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reply feature coming soon'),
                ),
              );
            },
          ),
          if (widget.isCurrentUser)
            _buildActionButton(
              icon: Icons.delete_outline,
              label: 'Delete',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Delete feature coming soon'),
                  ),
                );
                setState(() {
                  _showActions = false;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: Colors.white70,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReactionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      builder: (context) {
        return Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Reaction',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildQuickReaction('👍'),
                  _buildQuickReaction('❤️'),
                  _buildQuickReaction('😂'),
                  _buildQuickReaction('😮'),
                  _buildQuickReaction('😢'),
                  _buildQuickReaction('🙏'),
                  _buildQuickReaction('🔥'),
                  _buildQuickReaction('👏'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickReaction(String emoji) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reaction system coming soon'),
          ),
        );
      },
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}
