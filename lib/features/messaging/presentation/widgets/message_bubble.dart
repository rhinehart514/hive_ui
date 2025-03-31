import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ui/features/messaging/domain/entities/message.dart';
import 'package:hive_ui/features/messaging/presentation/widgets/message_delivery_indicator.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatefulWidget {
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
    super.key,
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
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  double _swipeOffset = 0;
  bool _showQuickReactions = false;

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
    final hasAttachment = widget.message.attachmentUrl != null;
    final isVoiceMessage = widget.message.attachmentType == 'audio';
    final hasReactions = widget.message.reactions != null &&
        widget.message.reactions!.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(
        left: widget.isCurrentUser ? 60.0 : 12.0,
        right: widget.isCurrentUser ? 12.0 : 60.0,
        bottom: 8.0,
      ),
      child: Column(
        crossAxisAlignment: widget.isCurrentUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (!widget.isCurrentUser &&
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
                  left: widget.isCurrentUser ? null : 0,
                  right: widget.isCurrentUser ? 0 : null,
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
                  widget.onLongPress?.call();
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
                                  widget.message.type == MessageType.text
                                      ? 16.0
                                      : 12.0,
                              vertical: widget.message.type == MessageType.text
                                  ? 12.0
                                  : 8.0,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: _getBubbleBorderRadius(),
                              color: widget.isCurrentUser
                                  ? AppColors.gold.withOpacity(0.15)
                                  : Colors.grey[800]!.withOpacity(0.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: _buildMessageContent(),
                          ),
                          if (hasReactions)
                            Positioned(
                              bottom: -10,
                              right: widget.isCurrentUser ? null : -10,
                              left: widget.isCurrentUser ? -10 : null,
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
            mainAxisAlignment: widget.isCurrentUser 
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
              if (widget.isCurrentUser && widget.message.id.isNotEmpty) 
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 8),
                  child: MessageDeliveryIndicator(
                    messageId: widget.message.id,
                    recipientId: widget.message.chatId,
                    size: 12,
                    showLabel: false,
                  ),
                ),
            ],
          ),
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
}
