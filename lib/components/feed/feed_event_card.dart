import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/event.dart';
import '../../models/user_profile.dart';
import '../../models/repost_content_type.dart';
import '../../theme/app_colors.dart';
import '../../components/optimized_image.dart';
import '../../core/navigation/routes.dart';
import '../../providers/reposted_events_provider.dart';
import '../../components/event_card/event_card.dart';

/// An optimized version of the event card for the main feed
/// that properly handles standard and quote reposts
class FeedEventCard extends ConsumerWidget {
  /// The event to display
  final Event event;
  
  /// Whether this is a reposted event
  final bool isRepost;
  
  /// The user who reposted the event
  final UserProfile? repostedBy;
  
  /// The time when the event was reposted
  final DateTime? repostTime;
  
  /// Quote text for quote reposts
  final String? quoteText;
  
  /// Type of repost
  final RepostContentType repostType;
  
  /// Called when the user taps the card
  final Function(Event)? onTap;
  
  /// Called when the user reposts the event
  final Function(Event, String?, RepostContentType)? onRepost;

  const FeedEventCard({
    Key? key,
    required this.event,
    this.isRepost = false,
    this.repostedBy,
    this.repostTime,
    this.quoteText,
    this.repostType = RepostContentType.standard,
    this.onTap,
    this.onRepost,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isQuoteRepost = isRepost && 
                          repostType == RepostContentType.quote && 
                          quoteText != null && 
                          quoteText!.isNotEmpty;
    
    if (isQuoteRepost) {
      return _buildQuoteRepost(context);
    } else {
      // Use the standard HiveEventCard for regular events and standard reposts
      return HiveEventCard(
        event: event,
        isRepost: isRepost,
        repostedBy: repostedBy,
        repostTimestamp: repostTime,
        quoteText: quoteText,
        repostType: repostType,
        onTap: onTap,
        onRepost: onRepost,
      );
    }
  }
  
  // Build a quote repost card with X/Twitter style
  Widget _buildQuoteRepost(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User who reposted information
          if (repostedBy != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // User avatar
                  if (repostedBy!.profileImageUrl != null && 
                      repostedBy!.profileImageUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: OptimizedImage(
                        imageUrl: repostedBy!.profileImageUrl!,
                        width: 28,
                        height: 28,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.grey700,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  const SizedBox(width: 10),
                  
                  // Username and timestamp
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          repostedBy!.displayName,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _formatTimeAgo(repostTime ?? DateTime.now()),
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Quote icon
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.format_quote,
                      size: 16,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
            ),
          
          // Quote text with animation and expanded view
          if (quoteText != null && quoteText!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quoteText!,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: AppColors.textPrimary,
                            height: 1.4,
                            letterSpacing: 0.1,
                          ),
                          // Allow reasonable number of lines for typical phone sizes
                          maxLines: constraints.maxWidth > 400 ? 8 : 6,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        // Show read more button if needed
                        if (quoteText!.length > 180)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: GestureDetector(
                              onTap: () {
                                // Tap to expand quote
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => Container(
                                    constraints: BoxConstraints(
                                      maxHeight: MediaQuery.of(context).size.height * 0.7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(24),
                                      ),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.08),
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Flexible(
                                          child: SingleChildScrollView(
                                            child: Text(
                                              quoteText!,
                                              style: GoogleFonts.inter(
                                                fontSize: 18,
                                                color: AppColors.textPrimary,
                                                height: 1.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                'Read more',
                                style: GoogleFonts.inter(
                                  color: AppColors.gold,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  }
                ),
              ),
            ),
          
          // Quoted event card (embedded)
          GestureDetector(
            onTap: onTap != null ? () => onTap!(event) : null,
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event image
                  if (event.imageUrl.isNotEmpty)
                    AspectRatio(
                      aspectRatio: 16/9,
                      child: OptimizedImage(
                        imageUrl: event.imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  
                  // Event details
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Event title
                        Text(
                          event.title,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // Event time and location
                        Text(
                          '${event.formattedTimeRange} • ${event.location}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        // Organizer
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'By ${event.organizerName}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textSecondary,
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
          
          // Action buttons (RSVP, Repost)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    
                    if (onRepost != null) {
                      // Show repost options
                      context.showRepostOptions(
                        event: event,
                        onRepostSelected: onRepost!,
                      );
                    }
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.repeat_rounded,
                      color: AppColors.yellow.withOpacity(0.8),
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Format time as relative time (e.g. "2h ago")
  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }
}

/// Extension for showing repost options
extension RepostOptionsExtension on BuildContext {
  Future<void> showRepostOptions({
    required Event event,
    required Function(Event, String?, RepostContentType) onRepostSelected,
  }) async {
    await showModalBottomSheet(
      context: this,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(this).size.height * 0.85,
      ),
      builder: (context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            padding: const EdgeInsets.all(16),
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Repost option
                _buildRepostOption(
                  context: context,
                  icon: Icons.repeat_rounded,
                  label: 'Repost',
                  description: 'Share this event with your followers',
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.of(context).pop();
                    onRepostSelected(event, null, RepostContentType.standard);
                  },
                ),
                
                const SizedBox(height: 8),
                
                // Quote option
                _buildRepostOption(
                  context: context,
                  icon: Icons.format_quote_rounded,
                  label: 'Quote',
                  description: 'Add your thoughts when sharing',
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.of(context).pop();
                    
                    // Navigate to quote page
                    context.push(
                      AppRoutes.quoteRepost,
                      extra: event,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildRepostOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gold.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.gold),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 