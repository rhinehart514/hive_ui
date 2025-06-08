import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/messaging/controllers/messaging_controller.dart';
import 'package:hive_ui/theme/app_colors.dart';

class MessageInput extends ConsumerStatefulWidget {
  final String? chatId;
  final String? replyToMessageId;
  final Function()? onReplyCanceled;
  final Function(String text)? onSendMessage;
  final Function(File file)? onAttachmentSelected;
  final Function(bool isTyping)? onTypingStateChanged;

  const MessageInput({
    Key? key,
    this.chatId,
    this.replyToMessageId,
    this.onReplyCanceled,
    this.onSendMessage,
    this.onAttachmentSelected,
    this.onTypingStateChanged,
  }) : super(key: key);

  @override
  ConsumerState<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends ConsumerState<MessageInput> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isTyping = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();

    // Listen for text changes to trigger typing indicator
    _textController.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_handleTextChanged);
    _textController.dispose();
    _focusNode.dispose();
    _typingTimer?.cancel();
    // Ensure typing indicator is turned off when widget is disposed
    if (_isTyping) {
      widget.onTypingStateChanged?.call(false);
    }
    super.dispose();
  }

  void _handleTextChanged() {
    // Only trigger typing events if text changes and controller exists
    if (widget.onTypingStateChanged != null) {
      final isCurrentlyTyping = _textController.text.isNotEmpty;

      // Only notify if typing state changed
      if (isCurrentlyTyping != _isTyping) {
        _isTyping = isCurrentlyTyping;
        widget.onTypingStateChanged!(_isTyping);

        // Cancel existing timer if any
        _typingTimer?.cancel();

        // If typing, set a timer to reset typing status after inactivity
        if (_isTyping) {
          _typingTimer = Timer(const Duration(seconds: 5), () {
            if (mounted && _isTyping) {
              _isTyping = false;
              widget.onTypingStateChanged!(_isTyping);
            }
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.replyToMessageId != null) _buildReplyPreview(),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12.0,
            vertical: 8.0,
          ),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(
              color: AppColors.cardBorder,
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              // Attachment button
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _showAttachmentOptions();
                },
                icon: const Icon(
                  Icons.attachment,
                  color: AppColors.gold,
                ),
                iconSize: 22,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                splashRadius: 22,
              ),

              const SizedBox(width: 8.0),

              // Text input
              Expanded(
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16.0,
                  ),
                  cursorColor: AppColors.gold,
                  maxLines: 5,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                  ),
                ),
              ),

              const SizedBox(width: 8.0),

              // Send button
              IconButton(
                onPressed:
                    _textController.text.trim().isEmpty ? null : _sendMessage,
                icon: const Icon(Icons.send),
                color: AppColors.gold,
                iconSize: 24,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                splashRadius: 22,
                disabledColor: AppColors.textDisabled,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.symmetric(
        horizontal: 12.0,
        vertical: 8.0,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: AppColors.cardBorder,
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.reply,
            color: AppColors.textSecondary,
            size: 16,
          ),
          const SizedBox(width: 8.0),
          const Expanded(
            child: Text(
              'Replying to message',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14.0,
              ),
            ),
          ),
          IconButton(
            onPressed: widget.onReplyCanceled,
            icon: const Icon(Icons.close),
            color: AppColors.textSecondary,
            iconSize: 16,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 16,
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    HapticFeedback.mediumImpact();

    try {
      // If direct callback is provided, use it
      if (widget.onSendMessage != null) {
        widget.onSendMessage!(text);
      }
      // Otherwise, use controller if chatId is provided
      else if (widget.chatId != null) {
        await ref.read(messagingControllerProvider).sendTextMessage(
              widget.chatId!,
              text,
            );
      }

      if (widget.replyToMessageId != null && widget.onReplyCanceled != null) {
        widget.onReplyCanceled!();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Attach',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption(
                    icon: Icons.photo,
                    label: 'Gallery',
                    color: Colors.purple,
                    onTap: () => _handleAttachment('gallery'),
                  ),
                  _buildAttachmentOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    color: Colors.red,
                    onTap: () => _handleAttachment('camera'),
                  ),
                  _buildAttachmentOption(
                    icon: Icons.insert_drive_file,
                    label: 'Document',
                    color: Colors.blue,
                    onTap: () => _handleAttachment('document'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAttachment(String type) {
    // This would be implemented with actual file picking functionality
    // For now, just show a placeholder message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$type attachment coming soon!'),
        backgroundColor: AppColors.cardBackground,
      ),
    );

    // In a real implementation, you would:
    // 1. Launch file picker or camera
    // 2. Get the file
    // 3. Call widget.onAttachmentSelected(file)
  }
}
