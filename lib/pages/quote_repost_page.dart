import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../models/event.dart';
import '../models/repost_content_type.dart';
import '../theme/app_colors.dart';
import '../models/user_profile.dart';
import '../providers/profile_provider.dart';
import '../providers/reposted_events_provider.dart';
import '../services/interactions/interaction_service.dart';
import '../models/interactions/interaction.dart';
import '../components/optimized_image.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart';

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
      // Check auth state first
      final authState = ref.read(authStateProvider);
      final isAuthenticated = authState.maybeWhen(
        data: (user) => user.isNotEmpty,
        orElse: () => false,
      );
      
      // Get current user profile first since it's already available in the UI
      final userProfile = ref.read(profileProvider).profile;
      
      // If we already have a user profile, consider the user authenticated
      if (userProfile != null) {
        // Use the existing profile directly
        _handleSubmitWithProfile(userProfile, quoteText);
        return;
      }
      
      // Otherwise fall back to regular auth check
      if (!isAuthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in to repost events')),
        );
        setState(() {
          _isSubmitting = false;
        });
        return;
      }
      
      // Try to load/refresh the profile
      try {
        await ref.read(profileProvider.notifier).loadProfile();
        
        // Check again after reload
        final refreshedProfile = ref.read(profileProvider).profile;
        if (refreshedProfile == null) {
          // Still null after refresh attempt
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to load your profile. Please try again.')),
          );
          setState(() {
            _isSubmitting = false;
          });
          return;
        }
        
        // Use the refreshed profile
        _handleSubmitWithProfile(refreshedProfile, quoteText);
      } catch (e) {
        print('Error refreshing profile: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to load your profile. Please try again.')),
        );
        setState(() {
          _isSubmitting = false;
        });
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

  /// Helper to complete submission with an existing profile
  void _handleSubmitWithProfile(UserProfile profile, String quoteText) {
    try {
      // Log the interaction
      _logRepostInteraction(widget.event, profile.id);
      
      // Add the event to reposted events
      final repostedEvents = ref.read(repostedEventsProvider.notifier);
      
      repostedEvents.addRepost(
        event: widget.event,
        repostedBy: profile,
        comment: quoteText,
        type: RepostContentType.quote,
      );
      
      // Provide haptic feedback for confirmation
      HapticFeedback.mediumImpact();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quote shared')),
      );
      
      // Navigate back with success using GoRouter
      if (mounted && context.mounted) {
        if (widget.onComplete != null) {
          widget.onComplete!(true);
        }
        context.pop();
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
          onPressed: () => context.pop(),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User avatar and info
                      if (currentUser != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0, bottom: 16.0),
                          child: Row(
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
                        ),
                      
                      // Quote input field
                      TextField(
                        controller: _quoteController,
                        focusNode: _focusNode,
                        maxLength: 280,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: "What's your take on this event?",
                          hintStyle: GoogleFonts.inter(
                            color: AppColors.textSecondary.withOpacity(0.5),
                            fontSize: 18,
                            height: 1.4,
                          ),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                          fillColor: Colors.transparent,
                          filled: true,
                        ),
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          height: 1.4,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Quoted event card
                      _QuotedEventPreview(event: widget.event),
                    ],
                  ),
                ),
              ),
            ),
            
            // Bottom bar with character count
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: const BoxDecoration(
                color: Colors.black,
                border: Border(
                  top: BorderSide(color: AppColors.grey800, width: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Character count
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _quoteController,
                    builder: (context, value, child) {
                      final int charCount = value.text.length;
                      final int remaining = 280 - charCount;
                      final Color counterColor = remaining < 20 
                          ? (remaining < 10 ? Colors.red : AppColors.gold)
                          : AppColors.textSecondary;
                      
                      return Text(
                        '$remaining',
                        style: GoogleFonts.inter(
                          color: counterColor,
                          fontSize: 14,
                          fontWeight: remaining < 50 ? FontWeight.bold : FontWeight.normal,
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
        color: const Color(0xFF0A0A0A),
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
            AspectRatio(
              aspectRatio: 16 / 9,
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
                  event.formattedTimeRange,
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