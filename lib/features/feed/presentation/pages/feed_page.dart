import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/core/refresh/global_refresh_controller.dart';

import '../../../../models/event.dart';
import '../../../../models/repost_content_type.dart';
import '../../../../providers/reposted_events_provider.dart';
import '../../../../providers/profile_provider.dart';
import '../../../../utils/auth_utils.dart';
import '../../domain/providers/feed_domain_providers.dart';

import '../widgets/stream_feed_list.dart';
import '../widgets/shimmer_event_card.dart';
import '../components/feed_strip.dart';
import '../../../../models/reposted_event.dart';
import '../controllers/feed_tab_controller.dart';

/// A optimized feed page that follows clean architecture principles
/// Handles efficient Firebase communication and state management via Streams
class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({Key? key}) : super(key: key);

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late GlobalKey<RefreshIndicatorState> _refreshIndicatorKey;
  bool _mounted = true; // Track mounted state
  
  // Add _hasUnreadNotifications variable with default value
  final bool _hasUnreadNotifications = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
    
    // Show refresh indicator automatically on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshIndicatorKey.currentState?.show();
      }
    });
  }

  @override
  void dispose() {
    _mounted = false; // Set mounted flag to false
    _tabController.dispose();
    super.dispose();
  }

  // Updated refresh function to use the new StreamProvider
  Future<void> _refreshFeed() async {
    if (!_mounted) return;
    debugPrint('🔄 FEED PAGE: Refreshing feed via controller...');
    try {
      // Use the controller to refresh
      await ref.read(feedTabControllerProvider).refreshFeed();
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feed refreshed'),
            duration: Duration(seconds: 1),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ FEED PAGE: Refresh error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing feed: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }
  
  // Handle RSVP for events - Updated to use repository
  Future<void> _handleRsvpClick(Event event) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You need to be logged in to RSVP to events'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      // Use the feed tab controller instead of directly calling the repository
      final controller = ref.read(feedTabControllerProvider);
      final success = await controller.handleRsvp(event);
      
      if (success) {
        // Show confirmation
        if (mounted) {
          final isRsvped = controller.isRsvpedToEvent(event.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isRsvped
                    ? 'You\'re going to ${event.title}!'
                    : 'You\'ve canceled your RSVP for ${event.title}'
              ),
              backgroundColor: isRsvped ? Colors.green : Colors.orange,
            ),
          );
        }
      } else {
        // Handle operation failure
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update RSVP for ${event.title}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error handling RSVP: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating RSVP: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Handle navigation to event details
  void _navigateToEventDetails(Event event) {
    context.push('/event/${event.id}', extra: {'heroTag': 'event_${event.id}'});
  }
  
  // Handle repost of events - Updated to use repository
  void _handleRepost(Event event, String? comment, RepostContentType type) {
    if (!AuthUtils.requireProfile(context, ref)) {
      return; // Exit if profile check fails
    }
    
    // Use the feed tab controller
    final controller = ref.read(feedTabControllerProvider);
    
    controller.handleRepost(event, comment, type).then((success) {
      if (success) {
        // Success: Show confirmation
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Reposted \'${event.title}\''),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      } else {
        // Failure: Show error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to repost \'${event.title}\''),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }).catchError((error) {
      debugPrint('Error handling repost: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reposting: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }
  
  // Show filter bottom sheet - Needs refactoring or removal
  void _showFilterBottomSheet(BuildContext context) {
    // TODO: Refactor filter logic or remove this feature for now
    // This method currently relies on the deleted feedContentProvider
    // and its associated state/filters (UserFilters).
    // Option 1: Re-implement filtering based on the new stream approach.
    // Option 2: Temporarily remove the filter button and this method.
    debugPrint('TODO: Refactor or remove _showFilterBottomSheet');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Filter functionality needs update.'),
        backgroundColor: Colors.orange,
      ),
    );
    /* Original code using feedContentProvider:
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Get current filter state
            final feedContent = ref.watch(feedContentProvider);
            final filters = feedContent.filters;
            
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 16,
                left: 16,
                right: 16,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  
                  // Title
                  Text(
                    'Filter Feed',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Content type filters
                  Text(
                    'CONTENT TYPE',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.6),
                      letterSpacing: 0.5,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Events filter
                  _buildFilterSwitch(
                    title: 'Events',
                    value: filters.showEvents,
                    icon: Icons.event,
                    onChanged: (value) {
                      setState(() {
                        ref.read(feedContentProvider.notifier).updateFilters(
                          filters.copyWith(showEvents: value),
                        );
                      });
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Reposts filter
                  _buildFilterSwitch(
                    title: 'Reposts',
                    value: filters.showReposts,
                    icon: Icons.repeat,
                    onChanged: (value) {
                      setState(() {
                        ref.read(feedContentProvider.notifier).updateFilters(
                          filters.copyWith(showReposts: value),
                        );
                      });
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Spaces filter
                  _buildFilterSwitch(
                    title: 'Space Recommendations',
                    value: filters.showSpaceRecommendations,
                    icon: Icons.groups,
                    onChanged: (value) {
                      setState(() {
                        ref.read(feedContentProvider.notifier).updateFilters(
                          filters.copyWith(showSpaceRecommendations: value),
                        );
                      });
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Event status filters
                  Text(
                    'EVENT STATUS',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.6),
                      letterSpacing: 0.5,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Today's events filter
                  _buildFilterSwitch(
                    title: 'Today\'s Events',
                    value: filters.showTodayEvents,
                    icon: Icons.today,
                    onChanged: (value) {
                      setState(() {
                        ref.read(feedContentProvider.notifier).updateFilters(
                          filters.copyWith(showTodayEvents: value),
                        );
                      });
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Upcoming events filter
                  _buildFilterSwitch(
                    title: 'Upcoming Events',
                    value: filters.showUpcomingEvents,
                    icon: Icons.event_available,
                    onChanged: (value) {
                      setState(() {
                        ref.read(feedContentProvider.notifier).updateFilters(
                          filters.copyWith(showUpcomingEvents: value),
                        );
                      });
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Past events filter
                  _buildFilterSwitch(
                    title: 'Past Events',
                    value: filters.showPastEvents,
                    icon: Icons.history,
                    onChanged: (value) {
                      setState(() {
                        ref.read(feedContentProvider.notifier).updateFilters(
                          filters.copyWith(showPastEvents: value),
                        );
                      });
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Reset button
                  Center(
                    child: TextButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        setState(() {
                          ref.read(feedContentProvider.notifier).updateFilters(
                            const UserFilters(), // Reset to defaults
                          );
                        });
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFFFD700),
                      ),
                      child: Text(
                        'Reset Filters',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
    */
  }
  
  // Build filter switch (Keep for potential future use, but check dependencies)
  Widget _buildFilterSwitch({
    required String title,
    required bool value,
    required IconData icon,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.white.withOpacity(0.7),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
        const Spacer(),
        Switch(
          value: value,
          onChanged: (newValue) {
            HapticFeedback.lightImpact();
            onChanged(newValue);
          },
          activeColor: const Color(0xFFFFD700),
          activeTrackColor: const Color(0xFFFFD700).withOpacity(0.3),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch the feed stream provider
    final feedStreamAsyncValue = ref.watch(feedStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.dark, // Primary surface color #121212 per brand aesthetic
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Add the FeedStrip at the top
          const Padding(
            padding: EdgeInsets.only(top: 12, bottom: 16), // Updated spacing
            child: FeedStrip(
              height: 125.0,
              maxCards: 5,
              showHeader: true,
              useGlassEffect: true,
            ),
          ),
          // Wrap the main content in an Expanded widget so it fills the remaining space
          Expanded(
            child: RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: _refreshFeed,
              backgroundColor: AppColors.surface,
              color: AppColors.primary,
              child: feedStreamAsyncValue.when(
                data: (feedItems) {
                  // Data is loaded, display the StreamFeedList
                  if (feedItems.isEmpty) {
                    // Handle empty feed state
                    return const Center(
                      child: Text(
                        'No events or reposts found.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  }
                  return StreamFeedList(
                    feedItems: feedItems,
                    onNavigateToEventDetails: _navigateToEventDetails,
                    onRsvpToEvent: _handleRsvpClick,
                    onRepost: _handleRepost,
                  );
                },
                loading: () {
                  // Show shimmer loading indicators while data is loading
                  return ListView.builder(
                    itemCount: 5, // Show a few shimmer cards
                    itemBuilder: (context, index) => const ShimmerEventCard(),
                  );
                },
                error: (error, stack) {
                  // Handle error state
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Error loading feed',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _refreshFeed(),
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // AppBar remains mostly the same, just removed TabBar for now
  AppBar _buildAppBar() {
    return AppBar(
      // Using the AppBarTheme from ThemeData instead of manually setting
      // backgroundColor: AppColors.dark, -- Now provided by theme
      // elevation: 0, -- Now provided by theme
      centerTitle: true,
      title: Text(
        'HIVE', // Or use an Image/SvgPicture for the logo
        style: GoogleFonts.orbitron(
          fontWeight: FontWeight.bold,
          fontSize: 24,
          color: AppColors.gold, // Use consistent gold accent
          letterSpacing: 1.5,
        ),
      ),
      actions: [
        // Add Filter button back if needed, but point to the updated/removed method
              IconButton(
          icon: const Icon(Icons.tune_rounded, color: AppColors.white),
                onPressed: () {
                  HapticFeedback.selectionClick();
            _showFilterBottomSheet(context); // This will now show the TODO message
                },
              ),
        // Example action: Notifications icon
              IconButton(
          icon: Icon(
            _hasUnreadNotifications ? Icons.notifications_active : Icons.notifications_none,
            color: AppColors.white, // White for standard icons
          ),
          onPressed: () {
            // TODO: Navigate to notifications screen
            debugPrint('Notifications icon pressed');
          },
        ),
        // Example action: Search icon
        IconButton(
          icon: const Icon(Icons.search, color: AppColors.white), // White for standard icons
          onPressed: () {
            // TODO: Navigate to search screen or show search bar
            debugPrint('Search icon pressed');
          },
        ),
      ],
      // Removed bottom TabBar for simplification in this step
    );
  }
} 