import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/providers/profile_provider.dart';
import 'dart:ui';

/// A dialog for creating a quote post with commentary
class QuotePostDialog extends ConsumerStatefulWidget {
  /// The event being quoted
  final Event event;
  
  /// Optional initial comment text
  final String? initialComment;
  
  /// Callback when quote is submitted successfully
  final Function(Event, String, UserProfile) onQuoteSubmit;
  
  /// Constructor
  const QuotePostDialog({
    Key? key,
    required this.event,
    this.initialComment,
    required this.onQuoteSubmit,
  }) : super(key: key);
  
  /// Static helper method to show the dialog
  static Future<void> show({
    required BuildContext context,
    required Event event,
    String? initialComment,
    required Function(Event, String, UserProfile) onQuoteSubmit,
  }) async {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuotePostDialog(
        event: event,
        initialComment: initialComment,
        onQuoteSubmit: onQuoteSubmit,
      ),
    );
  }

  @override
  ConsumerState<QuotePostDialog> createState() => _QuotePostDialogState();
}

class _QuotePostDialogState extends ConsumerState<QuotePostDialog> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocus = FocusNode();
  bool _isSubmitting = false;
  
  @override
  void initState() {
    super.initState();
    
    // Set initial text if provided
    if (widget.initialComment != null) {
      _commentController.text = widget.initialComment!;
    }
    
    // Focus the comment field after the dialog is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _commentFocus.requestFocus();
    });
  }
  
  @override
  void dispose() {
    _commentController.dispose();
    _commentFocus.dispose();
    super.dispose();
  }
  
  /// Handle the quote submission
  void _handleSubmit() {
    final comment = _commentController.text.trim();
    
    // Validate input
    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a comment to your quote'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    // Get the current user profile
    final userProfile = ref.read(profileProvider).profile;
    
    if (userProfile == null) {
      // Handle the case where the user isn't logged in or has no profile
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need to complete your profile first'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _isSubmitting = false;
      });
      return;
    }
    
    // Call the submission callback
    widget.onQuoteSubmit(widget.event, comment, userProfile);
    
    // Provide haptic feedback
    HapticFeedback.mediumImpact();
    
    // Close the dialog
    Navigator.of(context).pop();
  }
  
  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: AppColors.cardBackground.withOpacity(0.98),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 0.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              // Dialog title
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add Your Commentary',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    // Action buttons
                    Row(
                      children: [
                        // Cancel button
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).pop();
                          },
                          child: const Icon(
                            Icons.close,
                            color: Colors.white70,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Event preview
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.event.imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[800],
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.white70,
                              size: 24,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Event details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.event.title,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.event.description,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.event.location,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.5),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Comment input
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: TextField(
                  controller: _commentController,
                  focusNode: _commentFocus,
                  maxLines: 5,
                  minLines: 3,
                  maxLength: 280, // Twitter-like limit
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    hintText: 'What would you like to say about this event?',
                    hintStyle: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 16,
                    ),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                    counterStyle: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              
              // Submit button
              Padding(
                padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + bottomSafeArea),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.format_quote,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Post Quote',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 