import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/models/repost_content_type.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/huge_icons.dart';
import 'dart:ui';

/// A bottom sheet dialog that allows users to repost content
class RepostDialog extends StatefulWidget {
  /// The event being reposted
  final Event event;
  
  /// Optional comment to pre-fill
  final String? initialComment;
  
  /// Callback when user confirms repost
  final Function(Event event, String? comment, RepostContentType type) onRepost;
  
  /// Constructor
  const RepostDialog({
    Key? key,
    required this.event,
    this.initialComment,
    required this.onRepost,
  }) : super(key: key);
  
  /// Helper to show the dialog as a modal bottom sheet
  static Future<void> show({
    required BuildContext context,
    required Event event,
    String? initialComment,
    required Function(Event event, String? comment, RepostContentType type) onRepost,
  }) async {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RepostDialog(
        event: event,
        initialComment: initialComment,
        onRepost: onRepost,
      ),
    );
  }

  @override
  State<RepostDialog> createState() => _RepostDialogState();
}

class _RepostDialogState extends State<RepostDialog> {
  late TextEditingController _commentController;
  bool _isLoading = false;
  RepostContentType _selectedType = RepostContentType.standard;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController(text: widget.initialComment ?? '');
    
    // If initial comment is provided, set to quote type
    if (widget.initialComment != null && widget.initialComment!.isNotEmpty) {
      _selectedType = RepostContentType.quote;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _handleRepost() {
    // Don't allow empty comment for quote type
    if (_selectedType == RepostContentType.quote && _commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a comment for quote repost'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    // Call the repost callback with the current state
    widget.onRepost(
      widget.event,
      _commentController.text.isEmpty ? null : _commentController.text,
      _selectedType,
    );
    
    // Provide haptic feedback for confirmation
    HapticFeedback.mediumImpact();
    
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQueryData = MediaQuery.of(context);
    final viewPadding = mediaQueryData.viewPadding;
    final bottomPadding = viewPadding.bottom;
    final keyboardHeight = mediaQueryData.viewInsets.bottom;
    
    // Determine if the selected type is quote
    final isQuoteType = _selectedType == RepostContentType.quote;
    
    return Padding(
      padding: EdgeInsets.only(
        bottom: bottomPadding + keyboardHeight,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E).withOpacity(0.9),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              
              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
                child: Text(
                  'Share Event',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              
              // Event card preview
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event image
                      if (widget.event.imageUrl != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            widget.event.imageUrl!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[900],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      
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
                              widget.event.location,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.7),
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
              ),
              
              // Repost type selector
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
                child: Row(
                  children: [
                    _buildTypeOption(
                      label: 'Standard',
                      type: RepostContentType.standard,
                      icon: Icons.repeat_rounded,
                    ),
                    const SizedBox(width: 16),
                    _buildTypeOption(
                      label: 'Quote',
                      type: RepostContentType.quote,
                      icon: Icons.format_quote_rounded,
                    ),
                  ],
                ),
              ),
              
              // Comment field (only shown for quote repost)
              if (isQuoteType) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFEEB700),
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    maxLines: 4,
                    minLines: 3,
                  ),
                ),
              ],
              
              // Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                child: Row(
                  children: [
                    // Cancel button
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Center(
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Repost button
                    Expanded(
                      child: GestureDetector(
                        onTap: _isLoading ? null : _handleRepost,
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.black,
                                      ),
                                    ),
                                  )
                                : Text(
                                    'Repost',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTypeOption({
    required String label,
    required RepostContentType type,
    required IconData icon,
  }) {
    final isSelected = _selectedType == type;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = type;
          });
          HapticFeedback.selectionClick();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            border: Border.all(
              color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.black : Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.black : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 