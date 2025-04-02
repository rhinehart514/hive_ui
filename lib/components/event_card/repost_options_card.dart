import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../models/event.dart';
import '../../models/repost_content_type.dart';
import '../../theme/app_colors.dart';
import '../../theme/huge_icons.dart';
import '../../extensions/glassmorphism_extension.dart';
import '../../core/navigation/routes.dart';
import 'package:flutter/foundation.dart';
import '../../providers/reposted_events_provider.dart';
import '../../utils/auth_utils.dart';
import '../../providers/feed_provider.dart';
import '../../providers/profile_provider.dart';

/// A peaking card that displays repost options for an event
class RepostOptionsCard extends ConsumerStatefulWidget {
  /// The event to repost
  final Event event;

  /// Callback when a repost option is selected
  final Function(Event, String?, RepostContentType) onRepostSelected;

  /// Whether the user follows the club associated with this event
  final bool followsClub;

  /// List of boost timestamps for today (to check if already boosted)
  final List<DateTime> todayBoosts;

  /// Constructor
  const RepostOptionsCard({
    Key? key,
    required this.event,
    required this.onRepostSelected,
    this.followsClub = false,
    this.todayBoosts = const [],
  }) : super(key: key);

  @override
  ConsumerState<RepostOptionsCard> createState() => _RepostOptionsCardState();
}

class _RepostOptionsCardState extends ConsumerState<RepostOptionsCard> {
  // Track loading states
  bool _isReposting = false;
  bool _isBoosting = false;
  
  bool get _canBoost {
    return widget.followsClub && widget.todayBoosts.isEmpty;
  }
  
  // Handle repost with optimistic update
  Future<void> _handleRepost() async {
    if (_isReposting || _isBoosting) return;
    
    HapticFeedback.mediumImpact();
    
    // Check profile first
    if (!AuthUtils.requireProfile(context, ref)) {
      return;
    }
    
    setState(() {
      _isReposting = true;
    });
    
    try {
      // Get the current user profile
      final profileState = ref.read(profileProvider);
      final profile = profileState.profile;
      
      // Profile should be available since we checked with requireProfile
      if (profile == null) {
        throw Exception('Unable to access your profile. Please try again.');
      }
      
      // Optimistically update the UI
      ref.read(repostedEventsProvider.notifier).addRepost(
        event: widget.event,
        repostedBy: profile,
        type: RepostContentType.standard,
      );
      
      // Perform the actual repost
      await widget.onRepostSelected(widget.event, null, RepostContentType.standard);
      
      // Close the bottom sheet on success
      if (mounted) {
        Navigator.of(context).pop();
        
        // Show confirmation toast
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Event reposted!',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: AppColors.gold.withOpacity(0.8),
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Refresh feeds to show updated content
        ref.invalidate(repostedEventsProvider);
        ref.invalidate(feedStateProvider);
      }
    } catch (e) {
      if (mounted) {
        // Revert optimistic update if it was added
        try {
          ref.read(repostedEventsProvider.notifier).removeRepost(widget.event.id);
        } catch (_) {
          // Ignore error if repost wasn't added yet
        }
        
        // Show error with more descriptive message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to repost: ${e.toString().replaceAll('Exception: ', '')}',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
        debugPrint('Error reposting event: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isReposting = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share this event',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 20),
            
            // Repost option
            _buildOptionButton(
              icon: Icons.repeat_rounded,
              label: _isReposting ? 'Reposting...' : 'Repost',
              description: 'Share this event with your followers',
              isDisabled: _isReposting || _isBoosting,
              showProgress: _isReposting,
              onTap: (_isReposting || _isBoosting) ? null : _handleRepost,
            ),
            
            const SizedBox(height: 12),
            
            // Quote option
            _buildOptionButton(
              icon: Icons.format_quote_rounded,
              label: 'Quote',
              description: 'Add your thoughts when sharing',
              onTap: () {
                HapticFeedback.mediumImpact();
                
                // Check profile before proceeding
                if (AuthUtils.requireProfile(context, ref)) {
                  // Close the bottom sheet first
                  Navigator.of(context).pop();
                  
                  // Navigate to the quote repost page
                  context.pushNamed(
                    'quote_repost',
                    extra: widget.event,
                    queryParameters: {
                      'onComplete': 'true'
                    },
                  ).then((_) {
                    // Refresh feeds when returning
                    ref.invalidate(repostedEventsProvider);
                  });
                }
              },
            ),
            
            const SizedBox(height: 12),
            
            // Boost option
            _buildOptionButton(
              icon: HugeIcons.strokeRoundedHexagon01,
              label: _isBoosting ? 'Boosting...' : 'Boost',
              description: widget.followsClub 
                ? (widget.todayBoosts.isEmpty 
                    ? 'Prioritize this event in your followers\' feeds' 
                    : 'You can only boost an event once a day')
                : 'Follow this club to unlock boosting',
              isDisabled: !_canBoost || _isReposting || _isBoosting,
              showProgress: _isBoosting,
              onTap: (!_canBoost || _isReposting || _isBoosting) ? null : () async {
                HapticFeedback.mediumImpact();
                
                setState(() {
                  _isBoosting = true;
                });
                
                try {
                  // Perform boost operation
                  await widget.onRepostSelected(widget.event, null, RepostContentType.highlight);
                  
                  if (mounted) {
                    Navigator.of(context).pop();
                    
                    // Show confirmation
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Event boosted!',
                          style: GoogleFonts.inter(color: Colors.white),
                        ),
                        backgroundColor: AppColors.gold.withOpacity(0.8),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    
                    // Refresh feeds
                    ref.invalidate(repostedEventsProvider);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to boost: ${e.toString()}'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    debugPrint('Error boosting event: $e');
                  }
                } finally {
                  if (mounted) {
                    setState(() {
                      _isBoosting = false;
                    });
                  }
                }
              },
            ),
          ],
        ),
      ),
    ).addModalGlassmorphism(
      borderRadius: 20,
      blur: 20,
      opacity: 0.2,
      addGoldAccent: true,
    );
  }

  Widget _buildOptionButton({
    required IconData icon, 
    required String label, 
    required String description,
    required VoidCallback? onTap,
    bool isDisabled = false,
    bool showProgress = false,
  }) {
    final Color textColor = isDisabled ? AppColors.textDisabled : AppColors.white;
    final Color iconColor = isDisabled ? AppColors.textDisabled : AppColors.yellow;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDisabled 
                ? Colors.white.withOpacity(0.1) 
                : AppColors.yellow.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            if (showProgress)
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                ),
              )
            else
              Icon(icon, size: 24, color: iconColor),
              
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: textColor.withOpacity(0.7),
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

/// Extension method to show the repost options bottom sheet
extension RepostOptionsExtension on BuildContext {
  /// Shows the repost options bottom sheet
  Future<void> showRepostOptions({
    required Event event,
    required Function(Event, String?, RepostContentType) onRepostSelected,
    bool followsClub = false,
    List<DateTime> todayBoosts = const [],
  }) async {
    await showModalBottomSheet(
      context: this,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(this).size.height * 0.85,
      ),
      builder: (context) => RepostOptionsCard(
        event: event,
        onRepostSelected: onRepostSelected,
        followsClub: followsClub,
        todayBoosts: todayBoosts,
      ),
    );
  }
} 