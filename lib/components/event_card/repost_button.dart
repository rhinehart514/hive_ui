import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../theme/huge_icons.dart';
import '../../models/event.dart';
import '../../models/repost_content_type.dart';

/// A compact repost button that expands on tap to show repost options
class RepostButton extends StatefulWidget {
  /// The event being reposted
  final Event event;
  
  /// Callback when a repost is submitted
  final Function(Event, String?, RepostContentType) onRepost;
  
  /// Size of the button
  final double size;
  
  /// Constructor
  const RepostButton({
    super.key,
    required this.event,
    required this.onRepost,
    this.size = 48.0,
  });

  @override
  State<RepostButton> createState() => _RepostButtonState();
}

class _RepostButtonState extends State<RepostButton> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  bool _isExpanded = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
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
        
    widget.onRepost(widget.event, comment, RepostContentType.standard);
    
    // Close the expanded view
    setState(() {
      _isExpanded = false;
    });
    _animationController.reverse();
    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenSize = MediaQuery.of(context).size;
    
    // Calculate maximum height to avoid overflow
    final maxExpandedHeight = screenSize.height * 0.3; // Max 30% of screen height
    const expandedHeight = 130.0;
    final actualHeight = _isExpanded ? 
        (expandedHeight > maxExpandedHeight ? maxExpandedHeight : expandedHeight) 
        : widget.size;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(_isExpanded ? 16 : widget.size / 2),
            splashColor: AppColors.gold.withOpacity(0.1),
            highlightColor: AppColors.gold.withOpacity(0.2),
            onTap: _handleTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _isExpanded 
                  ? screenWidth > 600 ? 400 : screenWidth * 0.75
                  : widget.size,
              height: actualHeight,
              decoration: BoxDecoration(
                color: _isExpanded 
                    ? AppColors.cardBackground 
                    : AppColors.gold.withOpacity(0.2),
                borderRadius: BorderRadius.circular(_isExpanded ? 16 : widget.size / 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: AppColors.gold.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: _isExpanded
                  ? _buildExpandedContent()
                  : _buildCompactButton(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactButton() {
    return Center(
      child: HugeIcon(
        icon: HugeIcons.repost,
        size: widget.size * 0.5,
        color: AppColors.gold,
      ),
    );
  }

  Widget _buildExpandedContent() {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(
                  child: Text(
                    'Repost Event',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: _handleTap,
                  icon: const Icon(Icons.close, color: Colors.white, size: 18),
                  constraints: const BoxConstraints(maxHeight: 30, maxWidth: 30),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Comment field - Fixed height to prevent overflow
            SizedBox(
              height: 60,
              child: TextField(
                controller: _commentController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Add your thoughts...',
                  hintStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(8),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: ElevatedButton(
                onPressed: _handleRepost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Repost',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 