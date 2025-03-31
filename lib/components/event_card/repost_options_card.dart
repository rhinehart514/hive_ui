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

/// A peaking card that displays repost options for an event
class RepostOptionsCard extends ConsumerWidget {
  /// The event to be reposted
  final Event event;
  
  /// Callback when user selects repost option
  final Function(Event, String?, RepostContentType) onRepostSelected;
  
  /// Whether the user follows the event's club
  final bool followsClub;
  
  /// List of boost timestamps for today (to check if already boosted)
  final List<DateTime> todayBoosts;

  const RepostOptionsCard({
    Key? key,
    required this.event,
    required this.onRepostSelected,
    this.followsClub = false,
    this.todayBoosts = const [],
  }) : super(key: key);

  bool get _canBoost {
    return followsClub && todayBoosts.isEmpty;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              label: 'Repost',
              description: 'Share this event with your followers',
              onTap: () {
                HapticFeedback.mediumImpact();
                onRepostSelected(event, null, RepostContentType.standard);
                Navigator.of(context).pop();
              },
            ),
            
            const SizedBox(height: 12),
            
            // Quote option
            _buildOptionButton(
              icon: Icons.format_quote_rounded,
              label: 'Quote',
              description: 'Add your thoughts when sharing',
              onTap: () {
                HapticFeedback.mediumImpact();
                
                // Close the bottom sheet first
                Navigator.of(context).pop();
                
                // Navigate to the quote repost page with the path directly
                context.push(AppRoutes.quoteRepost, extra: event);
              },
            ),
            
            const SizedBox(height: 12),
            
            // Boost option
            _buildOptionButton(
              icon: HugeIcons.strokeRoundedHexagon01,
              label: 'Boost',
              description: followsClub 
                ? (todayBoosts.isEmpty 
                    ? 'Prioritize this event in your followers\' feeds' 
                    : 'You can only boost an event once a day')
                : 'Follow this club to unlock boosting',
              isDisabled: !_canBoost,
              onTap: _canBoost ? () {
                HapticFeedback.mediumImpact();
                onRepostSelected(event, null, RepostContentType.highlight);
                Navigator.of(context).pop();
              } : null,
            ),
            
            const SizedBox(height: 20),
            
            // Cancel button
            Center(
              child: TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
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