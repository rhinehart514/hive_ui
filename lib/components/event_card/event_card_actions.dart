import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/event.dart';
import '../../theme/app_colors.dart';
import '../../models/repost_content_type.dart';
import '../../theme/huge_icons.dart';
import '../../providers/profile_provider.dart';
import 'repost_options_card.dart';
import '../../utils/auth_utils.dart';

/// A modular widget for event card action buttons that can be used
/// independently or within the EventCard component.
class EventCardActions extends ConsumerWidget {
  /// The event to associate with the actions
  final Event event;
  
  /// Called when the user RSVPs to the event
  final Function(Event)? onRsvp;
  
  /// Called when the user reposts the event
  final Function(Event, String?, RepostContentType)? onRepost;
  
  /// Whether the user has already RSVP'd to this event
  final bool isRsvped;
  
  /// Whether to show the RSVP button
  final bool showRsvpButton;
  
  /// Whether to show the Repost button
  final bool showRepostButton;
  
  /// Optional custom color for the RSVP button
  final Color? rsvpButtonColor;
  
  /// Custom text for the RSVP button
  final String? rsvpButtonText;
  
  /// Whether the buttons should use a compact layout
  final bool isCompact;
  
  /// Optional layout orientation (horizontal or vertical)
  final Axis orientation;

  /// Whether the user follows the club associated with this event
  final bool followsClub;
  
  /// List of boost timestamps for today (to check if already boosted)
  final List<DateTime> todayBoosts;
  
  /// Constructor
  const EventCardActions({
    Key? key,
    required this.event,
    required this.isRsvped,
    this.onRsvp,
    this.onRepost,
    this.showRsvpButton = true,
    this.showRepostButton = true,
    this.rsvpButtonColor,
    this.rsvpButtonText,
    this.isCompact = false,
    this.orientation = Axis.horizontal,
    this.followsClub = false,
    this.todayBoosts = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Button text size based on screen size and compact mode
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 360;
    final double buttonTextSize = isSmallScreen || isCompact ? 14 : 16;
    
    // If both buttons are hidden, return an empty container
    if (!showRsvpButton && !(showRepostButton && onRepost != null)) {
      return const SizedBox.shrink();
    }

    final rsvpButton = showRsvpButton ? Expanded(
      child: TextButton(
        onPressed: () {
          if (onRsvp != null) {
            HapticFeedback.mediumImpact(); // Clear feedback for important action
            onRsvp!(event);
          }
        },
        style: TextButton.styleFrom(
          foregroundColor: isRsvped ? AppColors.black : (rsvpButtonColor ?? AppColors.yellow),
          backgroundColor: isRsvped 
            ? (rsvpButtonColor ?? AppColors.yellow)
            : Colors.transparent,
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 16, 
            vertical: isCompact ? 8 : 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isRsvped
              ? BorderSide.none
              : BorderSide(
                  color: (rsvpButtonColor ?? AppColors.yellow).withOpacity(0.3),
                  width: 1,
                ),
          ),
          minimumSize: Size(0, isCompact ? 36 : 48), // Touch target size based on compact mode
        ),
        child: Text(
          isRsvped ? rsvpButtonText ?? "RSVP'd" : rsvpButtonText ?? "RSVP",
          style: GoogleFonts.inter(
            fontSize: buttonTextSize,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
    ) : const SizedBox.shrink();

    final repostButton = (showRepostButton && onRepost != null) ? Expanded(
      child: OutlinedButton.icon(
        onPressed: () {
          HapticFeedback.lightImpact();
          
          if (onRepost != null) {
            // Watch profile state instead of just reading it once
            final profileState = ref.watch(profileProvider);
            debugPrint('Profile check - State: isLoading=${profileState.isLoading}, hasError=${profileState.hasError}, profile=${profileState.profile != null}');
            
            // Check only for profile existence before showing repost options
            if (AuthUtils.requireProfile(context, ref)) {
              // Show repost options card directly
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                builder: (context) => RepostOptionsCard(
                  event: event,
                  onRepostSelected: onRepost!,
                  followsClub: followsClub,
                  todayBoosts: todayBoosts,
                ),
              );
            }
          }
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.white, // Updated to white per guidelines for secondary actions
          side: BorderSide(
            color: Colors.white.withOpacity(0.3), // Updated border color
            width: 1,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 16, 
            vertical: isCompact ? 8 : 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: Size(0, isCompact ? 36 : 48), // Touch target size based on compact mode
        ).copyWith(
          overlayColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.pressed)) {
                return Colors.white.withOpacity(0.1); // Subtle press state
              }
              return null;
            },
          ),
        ),
        icon: Icon(HugeIcons.strokeRoundedHexagon01, size: isCompact ? 16 : 18),
        label: Text(
          "Repost",
          style: GoogleFonts.inter(
            fontSize: buttonTextSize,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ) : const SizedBox.shrink();

    // Space between buttons
    final spacer = orientation == Axis.horizontal 
      ? const SizedBox(width: 8) 
      : const SizedBox(height: 8);

    // Choose layout based on orientation
    if (orientation == Axis.horizontal) {
      return Row(
        children: [
          if (showRsvpButton) rsvpButton,
          if (showRsvpButton && showRepostButton && onRepost != null) spacer,
          if (showRepostButton && onRepost != null) repostButton,
        ],
      );
    } else {
      return Column(
        children: [
          if (showRsvpButton) rsvpButton,
          if (showRsvpButton && showRepostButton && onRepost != null) spacer,
          if (showRepostButton && onRepost != null) repostButton,
        ],
      );
    }
  }
}
