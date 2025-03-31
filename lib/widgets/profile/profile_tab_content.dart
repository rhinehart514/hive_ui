import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/models/space.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/providers/space_providers.dart';
import 'package:hive_ui/widgets/profile/profile_tab_bar.dart'
    show UserProfileStats;
import 'package:go_router/go_router.dart';
import 'package:hive_ui/services/analytics_service.dart';
import 'package:hive_ui/features/profile/presentation/widgets/profile_spaces_list.dart';
import 'package:hive_ui/extensions/neumorphic_extension.dart';

/// Enum for the different tab types in the profile page
enum ProfileTabType {
  /// Events tab
  events,

  /// Friends tab
  friends,

  /// Spaces tab
  spaces,
}

/// A widget to handle the tab content in the profile page
class ProfileTabContent extends ConsumerWidget {
  /// The type of tab to display
  final ProfileTabType tabType;

  /// The user profile being viewed
  final UserProfile profile;

  /// Whether this is the current user's profile
  final bool isCurrentUser;

  /// Callback when an action button is pressed (e.g., "Find Friends")
  final VoidCallback? onActionPressed;

  // Cache for expensive date calculations
  static final Map<String, String> _dateFormatCache = {};

  const ProfileTabContent({
    super.key,
    required this.tabType,
    required this.profile,
    this.isCurrentUser = false,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ensure renders completely by reducing render pressure
    return RepaintBoundary(
      child: SafeArea(
        bottom: false, // Allow content to extend to bottom nav
        child: Material(
          color: Colors.transparent, // Add Material widget for proper hit testing
          child: CustomScrollView(
            // Use physics optimized for mobile scrolling
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              // Add padding at top if needed
              _buildContent(context, ref),
              // Add bottom padding for SafeArea and to avoid FAB
              SliverToBoxAdapter(
                child: SizedBox(
                    height: MediaQuery.of(context).padding.bottom + 80),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    switch (tabType) {
      case ProfileTabType.events:
        return _buildEventsTab(context);
      case ProfileTabType.friends:
        return _buildFriendsTab(context);
      case ProfileTabType.spaces:
        return _buildSpacesTab(context, ref);
    }
  }

  Widget _buildEventsTab(BuildContext context) {
    // Check if the user has saved events
    if (profile.savedEvents.isEmpty) {
      return SliverList(
        delegate: SliverChildListDelegate([
          TabCountBadge(count: profile.eventCount, label: 'Events'),
          const SizedBox(height: 12), // Consistent spacing
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.grey[850]!.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.event,
                      color: Colors.white.withOpacity(0.7),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Events Yet',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      isCurrentUser
                          ? 'Save events to see them here'
                          : '${profile.username} hasn\'t saved any events yet',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                  if (isCurrentUser && onActionPressed != null) ...[
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: onActionPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        // Increase size for mobile touch targets
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Semantics(
                        button: true,
                        label: 'Explore Events button',
                        child: Text(
                          'Explore Events',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ]),
      );
    }

    // For devices with events, add proper semantics
    return SliverList(
      delegate: SliverChildListDelegate([
        TabCountBadge(count: profile.eventCount, label: 'Events'),
        const SizedBox(height: 12), // Consistent spacing
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Semantics(
            explicitChildNodes: true,
            container: true,
            label: 'Events list',
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              // Mobile optimizations
              cacheExtent: 500,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              itemCount: profile.savedEvents.length,
              itemBuilder: (context, index) {
                final event = profile.savedEvents[index];
                final isPastEvent = event.startDate.isBefore(DateTime.now());

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _EventCard(
                    event: event, 
                    isPastEvent: isPastEvent,
                    dateFormatter: _formatEventDate,
                  ),
                );
              },
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildFriendsTab(BuildContext context) {
    // Implement friends tab content here with proper accessibility
    return SliverToBoxAdapter(
      child: Semantics(
        label: 'Friends tab content coming soon',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              "Friends tab content coming soon", 
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpacesTab(BuildContext context, WidgetRef ref) {
    return SliverList(
      delegate: SliverChildListDelegate([
        TabCountBadge(count: profile.calculatedClubCount, label: 'Spaces'),
        const SizedBox(height: 12), // Consistent spacing
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Semantics(
            label: 'Spaces list',
            explicitChildNodes: true,
            child: ProfileSpacesList(
              profile: profile,
              isCurrentUser: isCurrentUser,
              onActionPressed: onActionPressed,
            ),
          ),
        ),
      ]),
    );
  }

  // Helper methods for formatting

  /// Format event date for display
  String _formatEventDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(date.year, date.month, date.day);

    // Check cache for formatted date
    final cacheKey = date.toIso8601String();
    if (_dateFormatCache.containsKey(cacheKey)) {
      return _dateFormatCache[cacheKey]!;
    }

    String formattedDate;
    final difference = eventDate.difference(today).inDays;

    if (difference == 0) {
      // Today
      final hour = date.hour > 12 ? date.hour - 12 : date.hour;
      final period = date.hour >= 12 ? 'PM' : 'AM';
      formattedDate = 'Today, ${hour == 0 ? 12 : hour}:${date.minute.toString().padLeft(2, '0')} $period';
    } else if (difference == 1) {
      // Tomorrow
      formattedDate = 'Tomorrow';
    } else if (difference > 1 && difference < 7) {
      // This week
      final weekday = _getWeekday(date.weekday);
      formattedDate = weekday;
    } else {
      // Further in the future
      final month = _getMonth(date.month);
      formattedDate = '$month ${date.day}';
    }

    // Cache for future use
    _dateFormatCache[cacheKey] = formattedDate;
    return formattedDate;
  }

  /// Get month name
  String _getMonth(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  /// Get weekday name
  String _getWeekday(int weekday) {
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    return weekdays[weekday - 1];
  }
  
  /// Build event image
  Widget _buildEventImage(Event event) {
    return Container(
      width: 90,
      height: 90,
      color: Colors.grey[850],
      child: event.imageUrl != null && event.imageUrl!.isNotEmpty
          ? Image.network(
              event.imageUrl!,
              fit: BoxFit.cover,
              height: 90,
              width: 90,
              cacheHeight: 180, // 2x for HiDPI screens
              cacheWidth: 180, // 2x for HiDPI screens
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded || frame != null) {
                  return child;
                }
                return Container(
                  color: Colors.grey[900],
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.gold.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Icon(
                    Icons.event,
                    color: Colors.white.withOpacity(0.5),
                    size: 32,
                  ),
                );
              },
            )
          : Center(
              child: Icon(
                Icons.event,
                color: Colors.white.withOpacity(0.5),
                size: 28,
              ),
            ),
    );
  }
}

/// A separated event card widget to improve maintainability
class _EventCard extends StatefulWidget {
  final Event event;
  final bool isPastEvent;
  final Function(DateTime) dateFormatter;

  const _EventCard({
    required this.event,
    required this.isPastEvent,
    required this.dateFormatter,
  });

  @override
  State<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<_EventCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown() {
    setState(() => _isPressed = true);
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    
    // Navigate to event details
    context.push('/event/${widget.event.id}');
    
    // Track for analytics
    AnalyticsService.logEvent(
      'profile_event_tapped',
      parameters: {'event_id': widget.event.id},
    );
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) => _onTapDown(),
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[900],
                border: Border.all(
                  color: widget.isPastEvent
                      ? Colors.grey.withOpacity(0.3)
                      : AppColors.gold.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: _isPressed ? [] : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              height: 90,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Event Image
                  SizedBox(
                    width: 90,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                      child: _buildEventImage(widget.event),
                    ),
                  ),
                  // Event Info
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.event.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              color: widget.isPastEvent
                                  ? Colors.white.withOpacity(0.7)
                                  : Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.dateFormatter(widget.event.startDate),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: widget.isPastEvent
                                  ? Colors.white.withOpacity(0.5)
                                  : Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.event.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventImage(Event event) {
    return Container(
      width: 90,
      height: 90,
      color: Colors.grey[850],
      child: event.imageUrl != null && event.imageUrl!.isNotEmpty
          ? Image.network(
              event.imageUrl!,
              fit: BoxFit.cover,
              height: 90,
              width: 90,
              cacheHeight: 180, // 2x for HiDPI screens
              cacheWidth: 180, // 2x for HiDPI screens
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded || frame != null) {
                  return child;
                }
                return Container(
                  color: Colors.grey[900],
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.gold.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Icon(
                    Icons.event,
                    color: Colors.white.withOpacity(0.5),
                    size: 32,
                  ),
                );
              },
            )
          : Center(
              child: Icon(
                Icons.event,
                color: Colors.white.withOpacity(0.5),
                size: 28,
              ),
            ),
    );
  }
}

/// A widget to display the count badge at the top of a tab
class TabCountBadge extends StatelessWidget {
  final int count;
  final String label;

  const TabCountBadge({
    super.key,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: GoogleFonts.inter(
                color: AppColors.gold,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
