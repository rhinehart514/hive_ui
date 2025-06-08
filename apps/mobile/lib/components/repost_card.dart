import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/app_theme.dart';
import 'package:hive_ui/components/optimized_image.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/theme/app_icons.dart';
import 'package:hive_ui/models/repost_content_type.dart';

/// A card component for showing reposted content in the feed
class RepostCard extends ConsumerStatefulWidget {
  /// The reposted event
  final Event event;

  /// Optional user comment for the repost
  final String? comment;

  /// The user who reposted the event
  final String reposterName;

  /// The repost time
  final DateTime repostTime;

  /// URL for the reposter's profile image
  final String? reposterImageUrl;

  /// The content type of the repost
  final RepostContentType contentType;

  /// Called when the card is tapped
  final VoidCallback? onTap;

  /// Called when the user taps to interact with the original event
  final Function(Event)? onEventTap;

  /// Hero tag for animations
  final String? heroTag;

  /// Constructor
  const RepostCard({
    super.key,
    required this.event,
    this.comment,
    required this.reposterName,
    required this.repostTime,
    this.reposterImageUrl,
    this.contentType = RepostContentType.standard,
    this.onTap,
    this.onEventTap,
    this.heroTag,
  });

  @override
  ConsumerState<RepostCard> createState() => _RepostCardState();
}

class _RepostCardState extends ConsumerState<RepostCard>
    with SingleTickerProviderStateMixin {
  // Animation controller for smooth animations
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Track if the card is being pressed
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    // Setup animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isPressed = true;
          _animationController.forward();
        });
      },
      onTapUp: (_) {
        setState(() {
          _isPressed = false;
          _animationController.reverse();
        });
      },
      onTapCancel: () {
        setState(() {
          _isPressed = false;
          _animationController.reverse();
        });
      },
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onTap?.call();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.cardBorder.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reposter info
              _buildReposterHeader(),

              // Repost comment
              if (widget.comment != null && widget.comment!.isNotEmpty)
                _buildComment(),

              // Original event card
              _buildOriginalEventCard(),

              // Action bar
              _buildActionBar(),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the reposter header section
  Widget _buildReposterHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Reposter avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.gold.withOpacity(0.5),
                width: 1.5,
              ),
              image: widget.reposterImageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(widget.reposterImageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: widget.reposterImageUrl == null
                ? const Icon(Icons.person, color: AppColors.gold, size: 20)
                : null,
          ),
          const SizedBox(width: 12),

          // Reposter info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.reposterName,
                        style: AppTheme.titleSmall.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Content type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: widget.contentType.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: widget.contentType.color.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.contentType.icon,
                            color: widget.contentType.color,
                            size: 12,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            widget.contentType.displayName,
                            style: AppTheme.labelSmall.copyWith(
                              color: widget.contentType.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Text(
                  _formatTimeAgo(widget.repostTime),
                  style: AppTheme.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // More options
          IconButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              // Show options menu
            },
            icon: Icon(
              Icons.more_horiz,
              color: AppColors.white.withOpacity(0.7),
              size: 18,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
          ),
        ],
      ),
    );
  }

  /// Build the comment section
  Widget _buildComment() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Text(
        widget.comment!,
        style: AppTheme.bodyMedium.copyWith(
          color: AppColors.white,
        ),
      ),
    );
  }

  /// Build original event card with reduced detail
  Widget _buildOriginalEventCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.cardBorder.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onEventTap?.call(widget.event);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event organizer
              Row(
                children: [
                  Text(
                    widget.event.organizerName,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.verified,
                    color: AppColors.gold.withOpacity(0.7),
                    size: 14,
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Event title
              Text(
                widget.event.title,
                style: AppTheme.titleMedium.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              // Event details
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: AppColors.textSecondary,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(widget.event.startDate),
                    style: AppTheme.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.location_on,
                    color: AppColors.textSecondary,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.event.location,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // Event image if available
              if (widget.event.imageUrl.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: OptimizedImage(
                      imageUrl: widget.event.imageUrl,
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build action bar with comment and share buttons
  Widget _buildActionBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          // Comment button
          _buildActionButton(
            icon: AppIcons.message,
            label: 'Comment',
            onTap: () {
              HapticFeedback.selectionClick();
              // Handle comment
            },
          ),

          // Share button
          _buildActionButton(
            icon: Icons.share_outlined,
            label: 'Share',
            onTap: () {
              HapticFeedback.selectionClick();
              // Handle share
            },
          ),

          const Spacer(),

          // Save/bookmark button
          IconButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              // Handle save
            },
            icon: const Icon(
              Icons.bookmark_border,
              color: AppColors.textSecondary,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
          ),
        ],
      ),
    );
  }

  /// Helper method to build action buttons with consistent styling
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.textSecondary,
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Format relative time ago
  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${(difference.inDays / 7).floor()}w';
    }
  }

  /// Format date for display
  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateToCheck = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (dateToCheck == today) {
      return 'Today, ${_formatTime(dateTime)}';
    } else if (dateToCheck == tomorrow) {
      return 'Tomorrow, ${_formatTime(dateTime)}';
    } else {
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${months[dateTime.month - 1]} ${dateTime.day}, ${_formatTime(dateTime)}';
    }
  }

  /// Format time for display
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12
        ? dateTime.hour - 12
        : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
