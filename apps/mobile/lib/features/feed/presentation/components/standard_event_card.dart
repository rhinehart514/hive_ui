import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/models/repost_content_type.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:hive_ui/features/moderation/domain/entities/content_report_entity.dart';
import 'package:hive_ui/components/moderation/report_button.dart';
import 'package:hive_ui/features/feed/presentation/widgets/rsvp_button.dart';
import 'package:hive_ui/features/feed/presentation/widgets/repost_dialog.dart';
import 'package:hive_ui/features/feed/presentation/controllers/feed_tab_controller.dart';
import 'package:hive_ui/features/feed/presentation/providers/rsvp_provider.dart';

/// A standard event card component
/// This is the base template for displaying events in the feed
class StandardEventCard extends ConsumerWidget {
  /// The event to display
  final Event event;
  
  /// Called when the card is tapped
  final Function(Event) onTap;
  
  /// Called when the user RSVPs to this event
  final Function(Event)? onRsvp;
  
  /// Called when the user reposts this event
  final Function(Event, String?, RepostContentType)? onRepost;
  
  /// Called when the event is reported
  final Function(Event)? onReport;
  
  /// Whether the RSVP action is in progress
  final bool isRsvpLoading;
  
  /// Constructor
  const StandardEventCard({
    super.key,
    required this.event,
    required this.onTap,
    this.onRsvp,
    this.onRepost,
    this.onReport,
    this.isRsvpLoading = false,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formattedDate = DateFormat('E, MMM d • h:mm a').format(event.startDate);
    
    // Get the RSVP status and loading state from the new providers
    final isRsvped = ref.watch(rsvpStateProvider)[event.id] ?? false;
    final loadingStatus = ref.watch(rsvpLoadingProvider)[event.id] ?? RsvpLoadingStatus.idle;
    final isLoading = loadingStatus != RsvpLoadingStatus.idle;
    
    // Load RSVP status if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(feedTabControllerProvider).loadRsvpStatus(event.id);
    });
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.dark2, // #1E1E1E - Secondary Surface per brand guidelines
        borderRadius: BorderRadius.circular(8), // 8px corner radius per guidelines
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), // Minimal, diffused drop shadows
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap(event);
          },
          splashColor: Colors.white.withOpacity(0.04), // Subtle splash
          highlightColor: Colors.white.withOpacity(0.02), // Subtle highlight
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Image - Edge-to-edge media content per guidelines
              if (event.imageUrl.isNotEmpty)
                SizedBox(
                  height: 160, // Slightly larger for better visibility
                  width: double.infinity,
                  child: Image.network(
                    event.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.dark3,
                        child: const Icon(
                          Icons.image_not_supported,
                          color: AppColors.textDarkSecondary,
                        ),
                      );
                    },
                  ),
                ),
              
              // Event Details
              Padding(
                padding: const EdgeInsets.all(16), // 16px padding (spacing-md)
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date and time with report button
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: AppColors.textDarkSecondary,
                        ),
                        const SizedBox(width: 8), // 8px spacing (spacing-xs)
                        Text(
                          formattedDate,
                          style: GoogleFonts.inter(
                            fontSize: 12, // Small/Labels font size
                            fontWeight: FontWeight.w500, // Small/Labels weight
                            color: AppColors.textDarkSecondary,
                            height: 1.5, // Line height for Small/Labels
                          ),
                        ),
                        const Spacer(),
                        ReportButton(
                          contentId: event.id,
                          contentType: ReportedContentType.event,
                          contentPreview: event.title,
                          ownerId: event.createdBy,
                          size: 16,
                          color: AppColors.textDarkSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12), // 12px spacing (spacing-sm)
                    
                    // Event title
                    Text(
                      event.title,
                      style: GoogleFonts.inter(
                        fontSize: 20, // H3 size
                        fontWeight: FontWeight.w600, // H3 weight
                        color: AppColors.textDark,
                        height: 1.5, // Line height for H3
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8), // 8px spacing (spacing-xs)
                    
                    // Location
                    if (event.location.isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppColors.textDarkSecondary,
                          ),
                          const SizedBox(width: 8), // 8px spacing (spacing-xs)
                          Expanded(
                            child: Text(
                              event.location,
                              style: GoogleFonts.inter(
                                fontSize: 14, // Body font size
                                fontWeight: FontWeight.w400, // Body weight
                                color: AppColors.textDarkSecondary,
                                height: 1.6, // Line height for Body
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16), // 16px spacing (spacing-md)
                    
                    // Action buttons
                    _buildActionButtons(context, ref, isRsvped),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Build the action buttons row
  Widget _buildActionButtons(BuildContext context, WidgetRef ref, bool isRsvped) {
    // Get loading state from provider
    final loadingStatus = ref.watch(rsvpLoadingProvider)[event.id] ?? RsvpLoadingStatus.idle;
    final isLoading = loadingStatus != RsvpLoadingStatus.idle;
    
    return Row(
      children: [
        // Organizer text
        Expanded(
          child: Text(
            event.organizerName,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        
        // Repost button
        if (onRepost != null)
          IconButton(
            onPressed: () => _showRepostDialog(context),
            icon: const Icon(
              Icons.repeat_rounded,
              color: Colors.white,
              size: 20,
            ),
            visualDensity: VisualDensity.compact,
            splashRadius: 20,
          ),
        
        const SizedBox(width: 8),
        
        // RSVP button
        if (onRsvp != null)
          RsvpButton(
            isRsvped: isRsvped,
            isLoading: isLoading,
            onRsvpChanged: (isRsvping) {
              onRsvp!(event);
            },
          ),
      ],
    );
  }
  
  /// Show the repost dialog
  void _showRepostDialog(BuildContext context) {
    if (onRepost == null) return;
    
    // Show the repost dialog
    RepostDialog.show(
      context: context,
      event: event,
      onRepost: (event, comment, type) {
        onRepost!(event, comment, type);
      },
    );
  }
} 