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
import '../../providers/reposted_events_provider.dart';
import '../../providers/profile_provider.dart';
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
  
  /// Called when the user RSVPs to the event
  final Function(Event)? onRsvp;
  
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
    this.onRsvp,
    this.onRepost,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isQuoteRepost = isRepost && 
                          repostType == RepostContentType.quote && 
                          quoteText != null && 
                          quoteText!.isNotEmpty;
    
    // IMPORTANT: Watch the reposted events to ensure UI updates when repost status changes
    final repostedEvents = ref.watch(repostedEventsProvider);
    final currentUser = ref.watch(profileProvider).profile;
    
    final hasReposted = currentUser != null && 
      repostedEvents.any((repost) => 
        repost.event.id == event.id && 
        repost.repostedBy.id == currentUser.id
      );
    
    if (isQuoteRepost) {
      return _buildQuoteRepost(context, ref);
    } else if (isRepost) {
      return _buildStandardRepost(context, ref);
    } else {
      // Return the HiveEventCard directly for regular events
      return HiveEventCard(
        event: event,
        onTap: onTap,
        onRsvp: onRsvp,
        onRepost: onRepost,
        isRepost: hasReposted,
      );
    }
  }
  
  // Build a standard repost card
  Widget _buildStandardRepost(BuildContext context, WidgetRef ref) {
    // IMPORTANT: Use watch instead of read to ensure UI updates when repost status changes
    final repostedEvents = ref.watch(repostedEventsProvider);
    final currentUserId = _getCurrentUserId(ref);
    
    // Check if the current user has also reposted this event (different from shown repost)
    final hasUserAlsoReposted = repostedBy != null && 
                              currentUserId != null && 
                              repostedEvents.any((repost) => 
                                repost.event.id == event.id && 
                                repost.repostedBy.id == currentUserId && 
                                currentUserId != repostedBy!.id
                              );
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withOpacity(0.2), width: 1),
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
          // Show "You also reposted" if the current user reposted this event
          if (hasUserAlsoReposted)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Icon(
                    Icons.repeat_rounded,
                    size: 14,
                    color: AppColors.gold.withOpacity(0.8),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'You also reposted',
                    style: GoogleFonts.inter(
                      color: AppColors.white.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
          // Repost header
          if (repostedBy != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Reposter avatar
                  if (repostedBy!.profileImageUrl != null && 
                      repostedBy!.profileImageUrl!.isNotEmpty)
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.gold.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: OptimizedImage(
                          imageUrl: repostedBy!.profileImageUrl!,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.cardBackground,
                        border: Border.all(
                          color: AppColors.gold.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 18,
                        color: AppColors.gold,
                      ),
                    ),
                  const SizedBox(width: 10),
                  
                  // Reposter info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                repostedBy!.displayName,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.repeat_rounded,
                              size: 14,
                              color: AppColors.gold.withOpacity(0.8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'reposted',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                        if (repostTime != null)
                          Text(
                            _formatRepostTime(repostTime!),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.white.withOpacity(0.5),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          // Event card  
          Padding(
            padding: EdgeInsets.only(
              left: 8,
              right: 8,
              top: 8,
              bottom: isRepost ? 16 : 8,
            ),
            child: HiveEventCard(
              event: event,
              onTap: onTap,
              onRsvp: onRsvp,
              onRepost: onRepost,
            ),
          ),
        ],
      ),
    );
  }
  
  // Build a quote repost card with X/Twitter style
  Widget _buildQuoteRepost(BuildContext context, WidgetRef ref) {
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
  
  // Format timestamp as relative time
  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mo';
    } else {
      return '${(difference.inDays / 365).floor()}y';
    }
  }
  
  // Helper method to get current user ID
  String? _getCurrentUserId(WidgetRef ref) {
    try {
      final currentUser = ref.watch(profileProvider).profile;
      return currentUser?.id;
    } catch (e) {
      debugPrint('Error getting current user ID: $e');
      return null;
    }
  }

  // Helper method to format repost time
  String _formatRepostTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
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
      return 'Just now';
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
      builder: (context) => Consumer(
        builder: (context, ref, child) => Material(
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
                      
                      try {
                        // Navigate to quote page
                        context.pushNamed(
                          'quote_repost',
                          extra: event,
                        ).then((result) {
                          // The parent component will handle the success message
                          // No need to show a duplicate message here
                        });
                      } catch (e) {
                        debugPrint('Error navigating to quote_repost: $e');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Could not open quote page'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
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