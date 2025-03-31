import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/huge_icons.dart';
import '../../../../models/event.dart';
import '../../../../models/repost_content_type.dart';

/// A compact repost button that expands on tap to show repost options for the feed card.
/// This component follows HIVE's premium aesthetic with subtle animations.
class FeedRepostButton extends StatefulWidget {
  /// The event being reposted
  final Event event;
  
  /// Callback when a repost is submitted
  final Function(Event, String?, RepostContentType) onRepost;
  
  /// Size of the compact button
  final double size;
  
  /// Constructor
  const FeedRepostButton({
    super.key,
    required this.event,
    required this.onRepost,
    this.size = 48.0,
  });

  @override
  State<FeedRepostButton> createState() => _FeedRepostButtonState();
}

class _FeedRepostButtonState extends State<FeedRepostButton> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  
  bool _isExpanded = false;
  bool _isPressed = false;
  final TextEditingController _commentController = TextEditingController();
  RepostContentType _selectedContentType = RepostContentType.standard;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _expandAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    
    setState(() {
      _isExpanded = !_isExpanded;
    });
    
    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
      // Reset controller when closing
      _commentController.clear();
    }
  }

  void _handleRepost() {
    final comment = _commentController.text.isNotEmpty 
        ? _commentController.text 
        : null;
        
    widget.onRepost(widget.event, comment, _selectedContentType);
    
    // Close the expanded view
    setState(() {
      _isExpanded = false;
    });
    _animationController.reverse();
    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    // Debug output to verify this component is being instantiated
    debugPrint('FeedRepostButton build method called for event: ${widget.event.id}');
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return GestureDetector(
          onTap: _handleTap,
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isExpanded 
                ? MediaQuery.of(context).size.width * 0.9 
                : widget.size,
            height: _isExpanded 
                ? 180 
                : widget.size,
            decoration: BoxDecoration(
              color: _isExpanded 
                  ? AppColors.cardBackground 
                  : AppColors.gold.withOpacity(0.4), // Increased opacity for better visibility
              borderRadius: BorderRadius.circular(_isExpanded ? 16 : widget.size / 2),
              boxShadow: _isPressed ? [] : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: AppColors.gold,
                width: 2.0, // Increased border width
              ),
            ),
            child: _isExpanded
                ? _buildExpandedContent()
                : _buildCompactButton(),
          ),
        );
      },
    );
  }

  Widget _buildCompactButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.gold.withOpacity(0.6),
          width: 1.5,
        ),
      ),
      child: Center(
        child: HugeIcon(
          icon: HugeIcons.repost,
          size: widget.size * 0.5,
          color: AppColors.gold,
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Add a comment to your repost',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              IconButton(
                onPressed: _handleTap,
                icon: Icon(Icons.close, color: Colors.white, size: 20),
                constraints: BoxConstraints(maxHeight: 32, maxWidth: 32),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TextField(
              controller: _commentController,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Add your thoughts...',
                hintStyle: TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.black.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleRepost,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Repost',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 