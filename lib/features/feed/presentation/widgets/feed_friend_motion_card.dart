import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/features/feed/domain/entities/signal_content.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/huge_icons.dart';

/// A card that shows friend activity in the Feed Strip
class FeedFriendMotionCard extends ConsumerStatefulWidget {
  /// The signal content containing friend motion data
  final SignalContent signalContent;
  
  /// Callback when the card is tapped
  final VoidCallback? onTap;
  
  /// Constructor
  const FeedFriendMotionCard({
    Key? key,
    required this.signalContent,
    this.onTap,
  }) : super(key: key);
  
  /// Creates a compact version of the card for use in the signal strip
  /// This is a factory method that simplifies creation with specific parameters
  static Widget compact({
    String? avatarUrl,
    String? username,
    String? action,
    VoidCallback? onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              shape: BoxShape.circle,
              image: avatarUrl != null
                  ? DecorationImage(
                      image: NetworkImage(avatarUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: avatarUrl == null
                ? Icon(
                    Icons.person,
                    color: Colors.grey.shade400,
                    size: 24,
                  )
                : null,
          ),
          
          const SizedBox(height: 8),
          
          // Name
          Text(
            username ?? 'User',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 2),
          
          // Action text
          Text(
            action ?? 'did something',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  ConsumerState<FeedFriendMotionCard> createState() => _FeedFriendMotionCardState();
}

class _FeedFriendMotionCardState extends ConsumerState<FeedFriendMotionCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Set up animation controller for tap feedback
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
    
    _scaleAnimation = _animationController.drive(CurveTween(curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _animationController.reverse();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    _animationController.forward();
  }

  void _handleTapCancel() {
    _animationController.forward();
  }

  void _handleButtonTap() {
    // Provide haptic feedback
    HapticFeedback.mediumImpact();
    
    final data = widget.signalContent.data ?? {};
    final eventId = data['eventId'] as String?;
    final spaceId = data['spaceId'] as String?;
    
    if (spaceId != null) {
      // Navigate to space detail
      context.pushNamed(
        'space_detail',
        pathParameters: {'id': spaceId},
      );
    } else if (eventId != null) {
      // Navigate to event detail
      context.pushNamed(
        'event_detail',
        pathParameters: {'id': eventId},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.signalContent.data ?? {};
    final friendCount = data['friendCount'] as int? ?? 0;
    final eventId = data['eventId'] as String?;
    final spaceId = data['spaceId'] as String?;
    final isSpaceRelated = spaceId != null;
    final friendIds = data['friendIds'] as List<dynamic>? ?? [];
    
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 280,
              decoration: BoxDecoration(
                // Glass effect following HIVE stylistic system
                color: const Color(0xFF1E1E1E), // Secondary surface color from style guide
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Colors.cyan.withOpacity(0.3),
                  width: 1.0,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with accent color based on content type
                  Container(
                    color: Colors.cyan.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.cyan.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            HugeIcons.strokeRoundedUserGroup03,
                            color: Colors.cyan,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.signalContent.title,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Main content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Description text
                        Text(
                          widget.signalContent.description,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: AppColors.white,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Friend avatars (if we have friend IDs)
                        if (friendIds.isNotEmpty) ...[
                          _buildFriendAvatars(friendIds, friendCount),
                          const SizedBox(height: 16),
                        ],
                        // Action button
                        GestureDetector(
                          onTap: _handleButtonTap,
                          child: Container(
                            width: double.infinity,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Center(
                              child: Text(
                                isSpaceRelated ? 'Check Out Space' : 'View Event',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
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
          );
        },
      ),
    );
  }
  
  /// Build a row of friend avatars with overflow indicator
  Widget _buildFriendAvatars(List<dynamic> friendIds, int totalCount) {
    // Only show up to 3 avatars
    final displayCount = friendIds.length > 3 ? 3 : friendIds.length;
    
    return Row(
      children: [
        // Stack avatars with slight overlap
        SizedBox(
          height: 36,
          width: displayCount * 28.0, // Overlapping width
          child: Stack(
            children: List.generate(
              displayCount,
              (index) => Positioned(
                left: index * 24.0, // Overlap by 8px
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.cardBackground,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      // Just use a placeholder for the demo
                      String.fromCharCode(65 + index),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Show remaining count if applicable
        if (totalCount > displayCount) ...[
          const SizedBox(width: 8),
          Text(
            '+${totalCount - displayCount} more',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ],
    );
  }
} 