import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/event.dart';
import '../models/repost_content_type.dart';
import '../theme/app_colors.dart';
import '../models/user_profile.dart';
import '../providers/profile_provider.dart';
import '../providers/reposted_events_provider.dart';
import '../services/interactions/interaction_service.dart';
import '../models/interactions/interaction.dart';
import '../components/optimized_image.dart';
import '../theme/huge_icons.dart';

/// Page for creating a quote repost
class QuoteRepostPage extends ConsumerStatefulWidget {
  /// The event to be quoted
  final Event event;
  
  /// Callback when repost is completed
  final Function(bool)? onComplete;

  const QuoteRepostPage({
    Key? key,
    required this.event,
    this.onComplete,
  }) : super(key: key);

  @override
  ConsumerState<QuoteRepostPage> createState() => _QuoteRepostPageState();
}

class _QuoteRepostPageState extends ConsumerState<QuoteRepostPage> {
  final TextEditingController _quoteController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSubmitting = false;
  
  @override
  void initState() {
    super.initState();
    // Focus the text field when the page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }
  
  @override
  void dispose() {
    _quoteController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
  
  // Handle repost submission
  Future<void> _handleSubmitQuoteRepost() async {
    if (_isSubmitting) return;
    
    setState(() {
      _isSubmitting = true;
    });
    
    final String quoteText = _quoteController.text.trim();
    if (quoteText.isEmpty) {
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a comment to your quote')),
      );
      return;
    }
    
    try {
      // Get current user profile
      final userProfile = ref.read(profileProvider).profile;
      
      if (userProfile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in to repost events')),
        );
        setState(() {
          _isSubmitting = false;
        });
        return;
      }
      
      // Log the interaction
      _logRepostInteraction(widget.event, userProfile.id);
      
      // Add the event to reposted events
      final repostedEvents = ref.read(repostedEventsProvider.notifier);
      
      // Debug print to confirm comment text
      print('Creating quote repost with text: $quoteText');
      
      repostedEvents.addRepost(
        event: widget.event,
        repostedBy: userProfile,
        comment: quoteText,
        type: RepostContentType.quote,
      );
      
      // Provide haptic feedback for confirmation
      HapticFeedback.mediumImpact();
      
      // Debug info about the repost we just created
      final allReposts = ref.read(repostedEventsProvider);
      final userReposts = allReposts.where((r) => r.repostedBy.id == userProfile.id).toList();
      print('User has ${userReposts.length} reposts. Latest comment: ${userReposts.isNotEmpty ? userReposts.last.comment : "none"}');
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quote shared')),
      );
      
      // Navigate back with success
      if (mounted) {
        Navigator.of(context).pop();
        if (widget.onComplete != null) {
          widget.onComplete!(true);
        }
      }
    } catch (e) {
      print('Error creating quote repost: $e');
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to share quote')),
        );
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
  
  // Log repost interaction
  void _logRepostInteraction(Event event, String userId) {
    try {
      InteractionService.logInteraction(
        entityId: event.id,
        entityType: EntityType.event,
        action: InteractionAction.comment,
        userId: userId,
        metadata: {
          'repostType': 'quote',
          'title': event.title,
          'organizer': event.organizerName,
        },
      );
    } catch (e) {
      print('Failed to log repost interaction: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final UserProfile? currentUser = ref.watch(profileProvider).profile;
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Quote Event',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton(
              onPressed: _isSubmitting ? null : _handleSubmitQuoteRepost,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black,
                disabledBackgroundColor: AppColors.gold.withOpacity(0.3),
                disabledForegroundColor: Colors.black54,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                'Share',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Divider below app bar
            const Divider(
              height: 1,
              thickness: 0.5,
              color: AppColors.grey800,
            ),
            
            // Quote compose area
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User avatar and info
                      if (currentUser != null)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // User avatar
                            if (currentUser.profileImageUrl != null && 
                                currentUser.profileImageUrl!.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: OptimizedImage(
                                  imageUrl: currentUser.profileImageUrl!,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.grey800,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              
                            const SizedBox(width: 12),
                            
                            // User display name
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentUser.displayName,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppColors.white,
                                    ),
                                  ),
                                  Text(
                                    '@${currentUser.username}',
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
                      
                      // Quote input field
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: TextField(
                          controller: _quoteController,
                          focusNode: _focusNode,
                          maxLength: 280,
                          maxLines: null,
                          decoration: InputDecoration(
                            hintText: "What's your take on this event?",
                            hintStyle: GoogleFonts.inter(
                              color: AppColors.textSecondary.withOpacity(0.7),
                              fontSize: 18,
                            ),
                            border: InputBorder.none,
                            counterText: '',
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: GoogleFonts.inter(
                            color: AppColors.white,
                            fontSize: 18,
                            height: 1.4,
                          ),
                        ),
                      ),
                      
                      // Quoted event card
                      Padding(
                        padding: const EdgeInsets.only(top: 24.0),
                        child: _QuotedEventPreview(event: widget.event),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Bottom bar with character count
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border(
                  top: BorderSide(color: AppColors.grey800, width: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icon with gold accent
                  const Icon(
                    Icons.format_quote_rounded,
                    color: AppColors.gold,
                  ),
                  
                  // Character count
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _quoteController,
                    builder: (context, value, child) {
                      final int charCount = value.text.length;
                      final int remaining = 280 - charCount;
                      final Color counterColor = remaining < 20 
                          ? (remaining < 10 ? Colors.red : AppColors.gold)
                          : AppColors.textSecondary;
                      
                      return Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: counterColor,
                            width: remaining < 50 ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$remaining',
                            style: GoogleFonts.inter(
                              color: counterColor,
                              fontWeight: remaining < 50 
                                  ? FontWeight.bold 
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    },
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

/// Preview of the quoted event
class _QuotedEventPreview extends StatelessWidget {
  final Event event;

  const _QuotedEventPreview({
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.grey800,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event image
          if (event.imageUrl.isNotEmpty)
            SizedBox(
              width: double.infinity,
              height: 120,
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
                  '${event.formattedTimeRange}',
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
                  child: Row(
                    children: [
                      // Organization icon
                      Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: AppColors.grey800,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.business,
                            size: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        event.organizerName,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 