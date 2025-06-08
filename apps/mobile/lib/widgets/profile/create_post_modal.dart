import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/extensions/glassmorphism_extension.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A modal bottom sheet for creating a new post
class CreatePostModal extends StatefulWidget {
  /// Constructor
  const CreatePostModal({super.key});

  /// Helper method to show the modal
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) => const CreatePostModal(),
    );
  }

  @override
  State<CreatePostModal> createState() => _CreatePostModalState();
}

class _CreatePostModalState extends State<CreatePostModal> {
  /// Text controller for the post content
  final TextEditingController _textController = TextEditingController();

  /// Whether the post button is enabled
  bool _isPostEnabled = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_updatePostButtonState);
  }

  @override
  void dispose() {
    _textController.removeListener(_updatePostButtonState);
    _textController.dispose();
    super.dispose();
  }

  /// Update the post button state based on text input
  void _updatePostButtonState() {
    final String text = _textController.text.trim();
    final bool shouldBeEnabled = text.isNotEmpty;

    if (shouldBeEnabled != _isPostEnabled) {
      setState(() {
        _isPostEnabled = shouldBeEnabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16.0,
        16.0,
        16.0,
        MediaQuery.of(context).viewInsets.bottom + 16.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle for better UX
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Create Post',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[900],
              // Add subtle neumorphic effect to text field
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  spreadRadius: 0,
                  offset: const Offset(2, 2),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.03),
                  blurRadius: 4,
                  spreadRadius: 0,
                  offset: const Offset(-1, -1),
                ),
              ],
            ),
            child: TextField(
              controller: _textController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "What's on your mind?",
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[800]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[800]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.gold),
                ),
                filled: true,
                fillColor: Colors.grey[900],
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  icon: const Icon(Icons.photo),
                  label: const Text('Add Photo'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    // Logic to add photo would go here
                  },
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  icon: const Icon(Icons.tag),
                  label: const Text('Tag People'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    // Logic to tag people would go here
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isPostEnabled ? AppColors.gold : Colors.grey[800],
                foregroundColor:
                    _isPostEnabled ? Colors.black : Colors.grey[400],
                disabledBackgroundColor: Colors.grey[800],
                disabledForegroundColor: Colors.grey[400],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isPostEnabled ? _handlePost : null,
              child: const Text(
                'Post',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ).addModalGlassmorphism(),
    );
  }

  /// Handle the post button press
  void _handlePost() {
    HapticFeedback.mediumImpact();

    // In a real app, this would submit the post to a server
    Navigator.pop(context);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Post created successfully!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
