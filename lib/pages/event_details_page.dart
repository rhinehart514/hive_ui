import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/glassmorphism_guide.dart';
import 'package:hive_ui/theme/huge_icons.dart';
import 'package:hive_ui/providers/profile_provider.dart';
import '../services/event_service.dart';
import '../services/calendar_integration_service.dart';
import '../components/event_details/event_action_bar.dart';
import 'package:go_router/go_router.dart';
import '../models/repost_content_type.dart';
import '../components/shared/event_header.dart';
import '../components/shared/event_content.dart';
import '../services/interactions/interaction_service.dart';
import '../models/interactions/interaction.dart';
import '../features/auth/providers/auth_providers.dart';
import '../providers/reposted_events_provider.dart';

class EventDetailsPage extends ConsumerStatefulWidget {
  final Event event;
  final String? heroTag;

  const EventDetailsPage({
    Key? key,
    required this.event,
    this.heroTag,
  }) : super(key: key);

  @override
  ConsumerState<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends ConsumerState<EventDetailsPage>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;
  double _scrollOffset = 0.0;

  // Add state variable for the space
  Space? _relatedSpace;
  bool _isLoadingSpace = false;

  bool _hasLoggedView = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Start the entrance animation
    _animationController.forward();

    // Load related space if event is club-created
    if (widget.event.isClubCreated) {
      _loadRelatedSpace();
    }
  }

  Future<void> _loadRelatedSpace() async {
    if (!mounted) return;

    setState(() {
      _isLoadingSpace = true;
    });

    try {
      // Try to find the space by organizer name
      // Since findSpaceByName doesn't exist, we'll create a stub implementation
      // that would typically handle this functionality
      final spaceName = widget.event.organizerName;
      // Simulate space lookup - in a real implementation, this would query Firestore
      await Future.delayed(const Duration(milliseconds: 500));
      // Create a mock space as a fallback
      final space = Space(
        id: 'space_${DateTime.now().millisecondsSinceEpoch}',
        name: spaceName,
        description: 'Official space for $spaceName',
        imageUrl: null, // Always set to null for safety on Windows
        spaceType: 'Student Organization',
        tags: [widget.event.category],
        memberCount: widget.event.attendees.length + 10, // Mock member count
        eventCount: 3,
      );

      if (mounted) {
        setState(() {
          _relatedSpace = space;
          _isLoadingSpace = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading space: $e');
      if (mounted) {
        setState(() {
          _isLoadingSpace = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset.clamp(0, 150);
    });
  }

  void _handleOrganizerTap() {
    // Extract the club ID from the event's organizer
    final organizerName = widget.event.organizerName;
    if (organizerName.isEmpty) return;

    HapticFeedback.mediumImpact();

    if (_relatedSpace != null) {
      // Navigate to the space detail page
      context.push('/spaces/${_relatedSpace!.id}');
    } else {
      // Navigate to spaces list with search query
      context.push('/spaces?search=$organizerName');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Log view interaction when the page is visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasLoggedView) {
        _logViewInteraction();
        _hasLoggedView = true;
      }
    });

    try {
      final size = MediaQuery.of(context).size;
      final event = widget.event;
      final isRsvpd =
          ref.watch(profileProvider.notifier).isEventSaved(event.id);
      
      // Get user profile for repost functionality
      final userProfile = ref.watch(profileProvider).profile;
      
      // Check if user follows the club
      final bool followsClub = userProfile != null && event.createdBy != null 
          ? false  // We'll implement proper club following later
          : false;
      
      // Check if user has already boosted the event today
      final todayBoosts = _getTodayBoosts(event.id);

      // Calculate dynamic header height based on scroll position
      final headerHeight = size.height * 0.40 - (_scrollOffset * 0.8);

      // Calculate blur sigma based on scroll
      final blurSigma = (_scrollOffset / 30).clamp(0.0, 5.0);

      return PopScope(
        canPop: true,
        onPopInvoked: (bool didPop) async {
          if (didPop) {
            // Run exit animation
            await _animationController.reverse();
          }
        },
        child: GestureDetector(
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity! > 0) {
              // Swipe right - go back
              Navigator.of(context).pop();
            }
          },
          child: Scaffold(
            backgroundColor: AppColors.black,
            body: Stack(
              children: [
                // Content
                CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // App Bar with header
                    SliverAppBar(
                      expandedHeight: headerHeight,
                      floating: false,
                      pinned: true,
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      leading: _buildBackButton(),
                      flexibleSpace: FlexibleSpaceBar(
                        background: EventHeader(
                          event: event,
                          heroTag: widget.heroTag,
                          imageHeight: 300,
                          showFullDate: true,
                          showOrganizer: true,
                        ),
                      ),
                    ),

                    // Content
                    SliverToBoxAdapter(
                      child: EventContent(
                        event: event,
                        showFullDescription: true,
                        onRsvp: _handleRsvp,
                        onRepost: _handleRepost,
                      ),
                    ),
                  ],
                ),

                // Dynamic app bar glass effect
                AnimatedOpacity(
                  opacity: (_scrollOffset / 100).clamp(0.0, 1.0),
                  duration: const Duration(milliseconds: 150),
                  child: SizedBox(
                    height: MediaQuery.of(context).padding.top + 56,
                    width: double.infinity,
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                            sigmaX: blurSigma, sigmaY: blurSigma),
                        child: Container(
                          color: AppColors.cardBackground.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                ),

                // Title that appears when scrolling
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 56,
                  right: 16,
                  child: AnimatedOpacity(
                    opacity: (_scrollOffset / 50).clamp(0.0, 1.0),
                    duration: const Duration(milliseconds: 150),
                    child: Text(
                      event.title,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: EventActionBar(
              event: event,
              isRsvpd: isRsvpd,
              onRsvpTap: _handleRsvpToggle,
              onAddToCalendarTap: _addToCalendar,
              onRepost: _handleRepost,
              followsClub: followsClub,
              todayBoosts: todayBoosts,
            ),
          ),
        ),
      );
    } catch (e) {
      // Error state
      return Scaffold(
        body: Center(
          child: Text(
            'Error loading event: $e',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  Widget _buildRelatedSpaceSection() {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
        )),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Space divider
              Container(
                height: 1,
                width: double.infinity,
                color: AppColors.white.withOpacity(0.1),
              ),
              const SizedBox(height: 16),

              // Section title
              Row(
                children: [
                  const HugeIcon(
                    icon: HugeIcons.spaces,
                    color: AppColors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Space',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  // See all spaces
                  InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.push('/spaces');
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Text(
                        'See all spaces',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Space card
              if (_isLoadingSpace)
                // Loading state
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.gold),
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                )
              else if (_relatedSpace != null)
                // Space found
                InkWell(
                  onTap: _handleOrganizerTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.white.withOpacity(0.15),
                        width: 0.5,
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Fix the image loading error by proper null checking
                        if (_relatedSpace!.imageUrl != null &&
                            _relatedSpace!.imageUrl!.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _buildSpacePlaceholder(),
                          )
                        else
                          _buildSpacePlaceholder(),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _relatedSpace!.name,
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_relatedSpace!.description != null &&
                                  _relatedSpace!.description!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _relatedSpace!.description!,
                                  style: TextStyle(
                                    color: AppColors.white.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 14,
                                    color: AppColors.white.withOpacity(0.7),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_relatedSpace!.memberCount} members',
                                    style: TextStyle(
                                      color: AppColors.white.withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: AppColors.gold,
                        ),
                      ],
                    ),
                  ),
                )
              else
                // No space found
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.white.withOpacity(0.15),
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hosted by ${widget.event.organizerName}',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _handleOrganizerTap,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.gold,
                          side: const BorderSide(color: AppColors.gold),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                        child: const Text('Find related spaces'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendeesSection() {
    if (widget.event.attendees.isEmpty) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
        )),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const HugeIcon(
                    icon: HugeIcons.user,
                    color: AppColors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Who\'s Going (${widget.event.attendees.length})',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Attendee list - simplified version showing just the count
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.white.withOpacity(0.15),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    // User icons in a stack
                    SizedBox(
                      width: 80,
                      height: 32,
                      child: Stack(
                        children: List.generate(
                          widget.event.attendees.length > 3
                              ? 3
                              : widget.event.attendees.length,
                          (index) => Positioned(
                            left: index * 20.0,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.gold.withOpacity(0.2),
                                border: Border.all(
                                  color: AppColors.gold,
                                  width: 1,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.person,
                                  size: 16,
                                  color: AppColors.gold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Count and join message
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.event.attendees.length > 1
                                ? '${widget.event.attendees.length} people are going'
                                : '1 person is going',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'RSVP to join them!',
                            style: TextStyle(
                              color: AppColors.white.withOpacity(0.7),
                              fontSize: 12,
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
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
          borderRadius: BorderRadius.circular(GlassmorphismGuide.kRadiusFull),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.black.withOpacity(0.3),
              borderRadius:
                  BorderRadius.circular(GlassmorphismGuide.kRadiusFull),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  /// Add event to calendar
  Future<void> _addToCalendar() async {
    HapticFeedback.mediumImpact();

    try {
      final success =
          await CalendarIntegrationService.addEventToCalendar(widget.event);

      if (mounted) {
        if (success) {
          _showSnackBar('Event added to calendar', isSuccess: true);
        } else {
          _showSnackBar('Failed to add event to calendar', isSuccess: false);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error adding to calendar: $e', isSuccess: false);
      }
    }
  }

  /// Handle RSVP toggle with calendar integration option
  Future<void> _handleRsvpToggle(bool currentRsvpStatus) async {
    final profileNotifier = ref.read(profileProvider.notifier);

    try {
      if (currentRsvpStatus) {
        // Remove RSVP
        profileNotifier.removeEvent(widget.event.id);
        await EventService.rsvpToEvent(widget.event.id, false);
        if (mounted) {
          _showSnackBar('RSVP removed', isSuccess: true);
        }
      } else {
        // Add RSVP
        profileNotifier.saveEvent(widget.event);
        await EventService.rsvpToEvent(widget.event.id, true);

        if (mounted) {
          _showSnackBar("You're going!", isSuccess: true);

          // Ask if user wants to add to calendar
          final addToCalendar = await showDialog<bool>(
            context: context,
            builder: (context) => _buildAddToCalendarDialog(),
          );

          if (addToCalendar == true) {
            _addToCalendar();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to update RSVP status', isSuccess: false);
      }
    }
  }

  /// Build dialog to ask user if they want to add event to calendar
  Widget _buildAddToCalendarDialog() {
    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      title: const Text(
        'Add to Calendar?',
        style: TextStyle(
          color: AppColors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: const Text(
        'Would you like to add this event to your calendar?',
        style: TextStyle(
          color: AppColors.white,
          fontSize: 16,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Skip',
            style: TextStyle(
              color: AppColors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(
            'Add',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  /// Show a snackbar message
  void _showSnackBar(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.85,
          left: 16,
          right: 16,
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildSpacePlaceholder() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.groups, color: AppColors.gold),
    );
  }

  void _handleRsvp(Event event) async {
    HapticFeedback.mediumImpact();

    final isRsvped = ref.read(profileProvider.notifier).isEventSaved(event.id);

    // Update backend
    await EventService.rsvpToEvent(event.id, !isRsvped);

    // Update local state
    if (!isRsvped) {
      ref.read(profileProvider.notifier).saveEvent(event);
    } else {
      ref.read(profileProvider.notifier).removeEvent(event.id);
    }

    // Log interaction
    _logRsvpInteraction();
  }

  void _handleRepost(Event event, String? quoteText, RepostContentType repostType) async {
    // Add haptic feedback
    HapticFeedback.mediumImpact();

    try {
      // Get current user profile
      final userProfile = ref.read(profileProvider).profile;
      
      if (userProfile == null) {
        // Not logged in - show auth dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in to repost events')),
        );
        return;
      }
      
      // Log the interaction
      _logRepostInteraction(event, userProfile.id, repostType);
      
      // Get a reference to the reposted events provider
      final repostedEvents = ref.read(repostedEventsProvider.notifier);
      
      // Add the event to reposted events
      repostedEvents.addRepost(
        event: event,
        repostedBy: userProfile,
        comment: quoteText,
        type: repostType,
      );
      
      // Show success message specific to repost type
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            repostType == RepostContentType.quote 
                ? 'Event quoted with your comment' 
                : repostType == RepostContentType.highlight 
                    ? 'Event boosted to your followers' 
                    : 'Event reposted to your profile'
          ),
        ),
      );
    } catch (e) {
      print('Error reposting event: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to repost event')),
      );
    }
  }

  void _logViewInteraction() {
    try {
      final user = ref.read(currentUserProvider);
      if (user.isNotEmpty == false) return;

      InteractionService.logInteraction(
        userId: user.id,
        entityId: widget.event.id,
        entityType: EntityType.event,
        action: InteractionAction.view,
        metadata: {
          'title': widget.event.title,
          'organizer': widget.event.organizerName,
          'category': widget.event.category,
          'tags': widget.event.tags,
          'view_type': 'details',
        },
      );
    } catch (e) {
      debugPrint('Error logging view interaction: $e');
    }
  }

  void _logRsvpInteraction() {
    try {
      final user = ref.read(currentUserProvider);
      if (user.isNotEmpty == false) return;

      InteractionService.logInteraction(
        userId: user.id,
        entityId: widget.event.id,
        entityType: EntityType.event,
        action: InteractionAction.rsvp,
        metadata: {
          'title': widget.event.title,
          'organizer': widget.event.organizerName,
          'category': widget.event.category,
          'tags': widget.event.tags,
        },
      );
    } catch (e) {
      debugPrint('Error logging RSVP interaction: $e');
    }
  }

  void _logRepostInteraction(Event event, String userId, RepostContentType repostType) {
    try {
      final interactionAction = repostType == RepostContentType.highlight 
          ? InteractionAction.share  // Use 'share' for boost as it's similar
          : repostType == RepostContentType.quote
              ? InteractionAction.comment  // Use 'comment' for quote
              : InteractionAction.share;   // Standard repost is 'share'
      
      InteractionService.logInteraction(
        entityId: event.id,
        entityType: EntityType.event,
        action: interactionAction,
        userId: userId,
        metadata: {
          'repostType': repostType.name,
          'title': event.title,
          'organizer': event.organizerName,
        },
      );
    } catch (e) {
      print('Failed to log repost interaction: $e');
    }
  }

  // Helper to get today's boosts for an event
  List<DateTime> _getTodayBoosts(String eventId) {
    // This would normally come from a provider or service
    // For now, we'll return an empty list 
    return [];
  }
}

// Move from separate import to local definition for simplicity
// Remove the import of '../models/space.dart' above and define a minimal version here
class Space {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String spaceType;
  final List<String> tags;
  final int memberCount;
  final int eventCount;

  Space({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.spaceType,
    required this.tags,
    this.memberCount = 0,
    this.eventCount = 0,
  });
}
