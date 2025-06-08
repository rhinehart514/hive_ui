import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/messaging/injection.dart' as injection;
import 'package:hive_ui/theme/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:hive_ui/features/messaging/utils/typing_indicator_manager.dart';

/// A chat input widget with support for text messages and media attachments
class ChatInput extends ConsumerStatefulWidget {
  final String chatId;
  final Function()? onMessageSent;
  final FocusNode? focusNode;
  final String? threadParentId;

  const ChatInput({
    Key? key,
    required this.chatId,
    this.onMessageSent,
    this.focusNode,
    this.threadParentId,
  }) : super(key: key);

  @override
  ConsumerState<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends ConsumerState<ChatInput> {
  final TextEditingController _textController = TextEditingController();
  bool _isComposing = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_handleTextChange);
  }

  @override
  void dispose() {
    _textController.removeListener(_handleTextChange);
    _textController.dispose();
    super.dispose();
  }

  void _handleTextChange() {
    final isComposing = _textController.text.isNotEmpty;
    if (isComposing != _isComposing) {
      setState(() {
        _isComposing = isComposing;
      });
    }
    
    // If text is being entered, notify the typing indicator manager
    if (_textController.text.isNotEmpty) {
      ref.read(typingIndicatorManagerProvider(widget.chatId)).userIsTyping();
    } else {
      // If text is cleared, notify that user stopped typing
      ref.read(typingIndicatorManagerProvider(widget.chatId)).userStoppedTyping();
    }
  }

  void _handleSubmitted() {
    final message = _textController.text.trim();
    if (message.isEmpty) return;

    // Set sending state to true
    ref.read(injection.isSendingMessageProvider(widget.chatId).notifier).state = true;

    // Notify that user is no longer typing
    ref.read(typingIndicatorManagerProvider(widget.chatId)).userStoppedTyping();

    // Send the message, optionally as a thread reply
    if (widget.threadParentId != null) {
      // Send as thread reply
      ref.read(injection.messagingControllerProvider).sendTextMessageReply(
        widget.chatId,
        message,
        widget.threadParentId!,
      ).then((_) {
        // Set sending state to false when complete
        ref.read(injection.isSendingMessageProvider(widget.chatId).notifier).state = false;
      }).catchError((error) {
        // Set sending state to false on error
        ref.read(injection.isSendingMessageProvider(widget.chatId).notifier).state = false;
        // Could show an error snackbar here
      });
    } else {
      // Send as regular message
    ref.read(injection.messagingControllerProvider).sendTextMessage(
      widget.chatId,
      message,
    ).then((_) {
      // Set sending state to false when complete
      ref.read(injection.isSendingMessageProvider(widget.chatId).notifier).state = false;
    }).catchError((error) {
      // Set sending state to false on error
      ref.read(injection.isSendingMessageProvider(widget.chatId).notifier).state = false;
      // Could show an error snackbar here
    });
    }

    // Clear the input
    _textController.clear();

    // Notify parent about sent message
    widget.onMessageSent?.call();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final permissionStatus = source == ImageSource.camera 
          ? await Permission.camera.request() 
          : await Permission.photos.request();
      
      if (permissionStatus.isGranted) {
        final pickedFile = await _picker.pickImage(
          source: source,
          imageQuality: 70, // Compress image for faster upload
        );
        
        if (pickedFile != null) {
          setState(() {
            _imageFile = File(pickedFile.path);
            _isUploading = true;
          });
          
          await _sendImageMessage();
        }
      } else {
        // Show permission denied message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission denied. Please enable in settings.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } on PlatformException catch (e) {
      print('Failed to pick image: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        // Get file size
        final fileSize = await file.length();
        // Maximum file size: 20MB
        if (fileSize > 20 * 1024 * 1024) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File size exceeds 20MB limit.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        
        // Send the file
        setState(() {
          _isUploading = true;
        });
        
        await _sendFileMessage(file);
      }
    } on PlatformException catch (e) {
      print('Failed to pick file: $e');
    }
  }

  Future<void> _sendImageMessage() async {
    if (_imageFile == null) return;
    
    try {
      // Set uploading state
      ref.read(injection.isSendingMessageProvider(widget.chatId).notifier).state = true;
      
      // Send the image message
      await ref.read(injection.messagingControllerProvider).sendImageMessage(
        widget.chatId,
        _imageFile!,
        caption: _textController.text.trim(),
      );
      
      // Clear the input and image
      _textController.clear();
      setState(() {
        _imageFile = null;
        _isUploading = false;
      });
      
      // Set uploading state to false when complete
      ref.read(injection.isSendingMessageProvider(widget.chatId).notifier).state = false;
      
      // Notify parent about sent message
      widget.onMessageSent?.call();
    } catch (e) {
      // Set uploading state to false on error
      ref.read(injection.isSendingMessageProvider(widget.chatId).notifier).state = false;
      setState(() {
        _isUploading = false;
      });
      
      // Show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendFileMessage(File file) async {
    try {
      // Set uploading state
      ref.read(injection.isSendingMessageProvider(widget.chatId).notifier).state = true;
      
      // Send the file message
      await ref.read(injection.messagingControllerProvider).sendFileMessage(
        widget.chatId,
        file,
        path.basename(file.path),
      );
      
      // Set uploading state to false when complete
      ref.read(injection.isSendingMessageProvider(widget.chatId).notifier).state = false;
      setState(() {
        _isUploading = false;
      });
      
      // Notify parent about sent message
      widget.onMessageSent?.call();
    } catch (e) {
      // Set uploading state to false on error
      ref.read(injection.isSendingMessageProvider(widget.chatId).notifier).state = false;
      setState(() {
        _isUploading = false;
      });
      
      // Show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Share Media',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.insert_drive_file,
                  label: 'File',
                  onTap: () {
                    Navigator.pop(context);
                    _pickFile();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.gold,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch the sending state
    final isSending = ref.watch(injection.isSendingMessageProvider(widget.chatId));

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image preview if there's an image selected
            if (_imageFile != null)
              Stack(
                children: [
                  Container(
                    height: 150,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _imageFile!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _imageFile = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  if (_isUploading)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.5),
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            
            Row(
          children: [
            // Attachment button
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white70),
                  onPressed: _isUploading ? null : _showAttachmentOptions,
            ),

            // Text input
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _textController,
                  focusNode: widget.focusNode,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 5,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Message',
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onSubmitted: (_) => _handleSubmitted(),
                ),
              ),
            ),

            // Send button
            AnimatedOpacity(
                  opacity: _isComposing || _imageFile != null ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IconButton(
                    icon: isSending || _isUploading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.gold),
                        ),
                      )
                    : const Icon(Icons.send, color: AppColors.gold),
                    onPressed: (isSending || _isUploading || (!_isComposing && _imageFile == null))
                        ? null
                        : _imageFile != null
                            ? _sendImageMessage
                            : _handleSubmitted,
              ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
