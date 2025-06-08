import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/presentation/providers/space_providers.dart';
import 'package:hive_ui/features/spaces/presentation/providers/spaces_repository_provider.dart';
import 'package:hive_ui/features/spaces/presentation/providers/space_events_model_provider.dart';
import 'package:hive_ui/features/spaces/presentation/providers/space_join_provider.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/leadership_claim_dialog.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/space_detail/space_events_tab.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/space_members_tab.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/space_message_board.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/spaces_loading_state.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/spaces_error_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'package:hive_ui/theme/glassmorphism_guide.dart';

/// A screen that displays detailed information about a space using the enhanced UX concept.
class SpaceDetailScreen extends ConsumerStatefulWidget {
  /// The ID of the space to display
  final String spaceId;

  /// Constructor
  const SpaceDetailScreen({
    Key? key,
    required this.spaceId,
  }) : super(key: key);

  @override
  ConsumerState<SpaceDetailScreen> createState() => _SpaceDetailScreenState();
}

// Added AutomaticKeepAliveClientMixin for preserving tab state
class _SpaceDetailScreenState extends ConsumerState<SpaceDetailScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _isHeaderCollapsed = false;
  bool _showWelcomeCard = false; // Default to false until checked
  bool _isManager = false; // Keep manager status

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _setupScrollListener();
    // Refresh space data and check space/manager status on initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshSpaceData();
        _checkSpaceStatus();
        _checkFirstTimeVisit(); // Check for welcome card
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener); // Remove listener
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // Keep state alive when switching tabs/pages
  @override
  bool get wantKeepAlive => true;

  void _scrollListener() {
    // Check if header should be considered collapsed (adjust offset as needed)
    final isCollapsed = _scrollController.hasClients &&
                          _scrollController.offset > (200 - kToolbarHeight); // Example threshold
    if (isCollapsed != _isHeaderCollapsed) {
      setState(() {
        _isHeaderCollapsed = isCollapsed;
      });
    }
  }

  void _setupScrollListener() {
    _scrollController.addListener(_scrollListener);
  }

  void _refreshSpaceData() {
    final spaceNotifier = ref.read(spacesProvider.notifier);
    
    // Refresh the space data
    spaceNotifier.refreshSpace(widget.spaceId);
    
    // Refresh space metrics
    ref.read(spaceMetricsProvider.notifier).refreshMetrics(widget.spaceId);
  }

  Future<void> _checkSpaceStatus() async {
    try {
      final repository = ref.read(spaceRepositoryProvider);
      final currentUser = ref.read(currentUserProvider);
      
      if (currentUser.id.isEmpty) {
        setState(() {
          _isManager = false;
        });
        return;
      }
      
      // Check if user is a manager of the space
      final userId = currentUser.id;
      final space = await repository.getSpaceById(widget.spaceId);
      final isManager = space?.admins.contains(userId) ?? false;
      
      if (mounted) {
        setState(() {
          _isManager = isManager;
        });
      }
    } catch (e) {
      debugPrint('Error checking space status: $e');
    }
  }

  /// Checks SharedPreferences to see if this is the user's first visit.
  Future<void> _checkFirstTimeVisit() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Check if the key for this space visit exists
      final hasVisited = prefs.containsKey('visited_space_${widget.spaceId}');
      if (mounted) {
        setState(() {
          _showWelcomeCard = !hasVisited;
        });
      }
    } catch (e) {
      debugPrint("Error checking SharedPreferences for first visit: $e");
      // Default to not showing the card if there's an error
      if (mounted) {
        setState(() {
          _showWelcomeCard = false;
        });
      }
    }
  }

  /// Hides the welcome card and saves the visit status in SharedPreferences.
  Future<void> _dismissWelcomeCard() async {
    HapticFeedback.selectionClick();
    if (mounted) {
      setState(() {
        _showWelcomeCard = false;
      });
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      // Set the flag indicating the user has visited this space
      await prefs.setBool('visited_space_${widget.spaceId}', true);
    } catch (e) {
      debugPrint("Error saving visit status to SharedPreferences: $e");
    }
  }

  Future<void> _handleJoinToggle() async {
    HapticFeedback.mediumImpact();
    
    final currentUser = ref.read(currentUserProvider);
    
    if (currentUser.id.isEmpty) {
      // Show dialog to sign in
      _showSignInDialog();
      return;
    }
    
    // Use the SpaceJoinProvider to handle join/unjoin
    final joinNotifier = ref.read(spaceJoinProvider(widget.spaceId).notifier);
    final success = await joinNotifier.toggleJoin();
    
    if (success && mounted) {
      // Refresh space data
      _refreshSpaceData();
    } else {
      // Error is already handled in the provider with state updates
      final errorMessage = ref.read(spaceJoinProvider(widget.spaceId)).errorMessage;
      if (errorMessage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSignInDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign In Required', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        content: Text(
          'You need to sign in to join spaces',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/auth/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.black,
            ),
            child: Text('Sign In', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _handleClaimLeadership() {
    HapticFeedback.mediumImpact();
    
    showDialog(
      context: context,
      builder: (context) => LeadershipClaimDialog(
        spaceId: widget.spaceId,
        onClaim: () {
          // This will trigger a refresh of the space data after a claim
          _refreshSpaceData();
        },
      ),
    );
  }

  void _handleShareSpace(SpaceEntity space) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bottomSheetBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(GlassmorphismGuide.kModalRadius)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Share Space',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Invite others to join ${space.name}',
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildShareOption(Icons.link, 'Copy Link', () {
                      Clipboard.setData(const ClipboardData(text: 'TODO: Add space link'));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Link copied to clipboard'),
                          backgroundColor: AppColors.dark2,
                        ),
                      );
                    }),
                    _buildShareOption(Icons.message, 'Message', () {
                      Navigator.pop(context);
                    }),
                    _buildShareOption(Icons.people, 'Invite', () {
                      Navigator.pop(context);
                      _showInviteMembersDialog(space);
                    }),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShareOption(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.dark2,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _showInviteMembersDialog(SpaceEntity space) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite Members (Not Implemented)'),
        content: const Text('This feature needs to be built.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Important for AutomaticKeepAliveClientMixin

    final spaceAsync = ref.watch(spaceProvider(widget.spaceId));

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Space Details',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_isManager)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                // Navigate to edit space page
                HapticFeedback.mediumImpact();
                context.push('/spaces/${widget.spaceId}/edit');
              },
            ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              HapticFeedback.mediumImpact();
              spaceAsync.maybeWhen(
                data: (space) {
                  if (space != null) {
                    _showSpaceMenu(context, space);
                  }
                },
                orElse: () {},
              );
            },
          ),
        ],
      ),
      body: spaceAsync.when(
        data: (space) {
          if (space == null) {
            return const Center(
              child: Text(
                'Space not found',
                style: TextStyle(color: Colors.white),
              ),
            );
          }
          
          return _buildSpaceContent(space);
        },
        loading: () => const SpacesLoadingState(),
        error: (error, stackTrace) {
          debugPrint('Error loading space ${widget.spaceId}: $error\n$stackTrace');
          // Use custom error view
          // TODO: Pass a real retry callback to SpaceErrorState
          return const SpacesErrorState(error: 'Could not load space details.');
        },
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget? _buildFloatingActionButton() {
    final joinState = ref.watch(spaceJoinProvider(widget.spaceId));
    final isJoined = joinState.isJoined;
    
    if (isJoined && !_isManager) {
      return FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          // Navigate to create event or post in this space
          _showContentCreationMenu();
        },
        backgroundColor: AppColors.gold,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: Text(
          'Create',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      );
    }
    
    return null;
  }

  Widget _buildSpaceContent(SpaceEntity space) {
    // Fetch events data for the events tab
    final eventsModelAsync = ref.watch(spaceEventsModelProvider(widget.spaceId));

    // Main layout using NestedScrollView
    return NestedScrollView(
      controller: _scrollController,
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        // Return list of slivers placed in the header
        return <Widget>[
          _buildSliverAppBar(space),
          _buildSliverTabBar(),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          _buildBoardTab(space),
          // Provide required parameters to SpaceEventsTab
          eventsModelAsync.when(
             // Use the list directly, assuming provider returns List<Event>
             data: (eventList) => SpaceEventsTab(
                events: eventList, // Pass the fetched event list
                onEventTap: (event) {
                  // Navigate to event detail screen
                  context.push('/events/${event.id}');
                },
                isManager: _isManager, // Pass manager status
                onCreateEvent: _isManager
                    ? () {
                        // Navigate to create event screen
                        context.push('/spaces/${widget.spaceId}/create-event');
                      }
                    : null, // Only allow creation if manager
                 // TODO: Pass RSVP statuses if available from a provider
                 // rsvpStatuses: ref.watch(rsvpStatusesProvider(widget.spaceId)),
             ),
             loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
             error: (error, _) => const Center(child: Text('Error loading events', style: TextStyle(color: AppColors.textDarkSecondary))),
          ),
          SpaceMembersTab(spaceId: widget.spaceId),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(SpaceEntity space) {
    // TODO: Implement SliverAppBar based on Concept 1 or 2
    // Needs banner, avatar, name, type, member count, join/share buttons
    // Should react to _isHeaderCollapsed state
    return SliverAppBar(
      expandedHeight: 200.0, // Adjust as needed
      floating: false,
      pinned: true,
      snap: false,
      backgroundColor: _isHeaderCollapsed ? AppColors.black : Colors.transparent,
      elevation: _isHeaderCollapsed ? 4.0 : 0.0,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false, // Align title to start when collapsed
        titlePadding: const EdgeInsetsDirectional.only(start: 16.0, bottom: 16.0),
        title: _isHeaderCollapsed
            ? Text(
                space.name,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null, // Title only shown when collapsed
        background: Stack(
          fit: StackFit.expand,
          children: [
            // TODO: Add Banner Image if available (space.bannerUrl)
            Container(color: AppColors.dark2), // Placeholder background
            // TODO: Add Gradient Overlay
            // TODO: Add Header Content (Avatar, Name, etc.) visible when expanded
          ],
        ),
      ),
      // TODO: Add actions (Share, More/Admin)
      actions: [
        IconButton(
          icon: const Icon(Icons.share_outlined, color: Colors.white),
          tooltip: 'Share Space',
          onPressed: () => _handleShareSpace(space),
        ),
        // TODO: Add Admin Menu Button if _isManager is true
        if (_isManager)
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            tooltip: 'Space Settings',
            onPressed: () { /* TODO: Navigate to settings */ },
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSliverTabBar() {
    // Use SliverPersistentHeader for the sticky tab bar
    return SliverPersistentHeader(
      delegate: _SliverTabBarDelegate(
        TabBar(
          controller: _tabController,
          indicatorColor: AppColors.gold,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.textDarkSecondary,
          indicatorWeight: 2.0,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
          unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
          tabs: const [
            Tab(text: 'Board'),
            Tab(text: 'Events'),
            Tab(text: 'Members'),
          ],
        ),
      ),
      pinned: true, // Make it stick
    );
  }

  Widget _buildBoardTab(SpaceEntity space) {
    // Use ListView or Column for scrollable content
    return ListView(
      padding: const EdgeInsets.all(16.0), // Add padding around tab content
      children: [
        // Conditionally display the welcome card
        if (_showWelcomeCard) _buildWelcomeCard(space),
        // Add existing SpaceMessageBoard or other content here
        SpaceMessageBoard(spaceId: widget.spaceId),
        // Add more widgets as needed for the board...
      ],
    );
  }

  Widget _buildWelcomeCard(SpaceEntity space) {
    return AnimatedOpacity(
      opacity: _showWelcomeCard ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16.0),
        color: Colors.transparent, // Make card transparent for backdrop filter
        elevation: 0, // Use decoration for border/background
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GlassmorphismGuide.kRadiusMd),
        ),
        clipBehavior: Clip.antiAlias, // Important for BackdropFilter
        child: BackdropFilter(
          filter: ImageFilter.blur(
              sigmaX: GlassmorphismGuide.kCardBlur,
              sigmaY: GlassmorphismGuide.kCardBlur),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: AppColors.cardBackground.withOpacity(0.6), // Use HIVE card color
              borderRadius: BorderRadius.circular(GlassmorphismGuide.kRadiusMd),
              border: Border.all(
                color: AppColors.cardBorder, // Use HIVE border color
                width: GlassmorphismGuide.kBorderThin,
              ),
              gradient: LinearGradient( // Subtle gradient consistent with glass style
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.05),
                  Colors.white.withOpacity(0.02),
                ],
                stops: const [0.1, 1.0],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.gold, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Welcome to ${space.name}',
                        style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: AppColors.textDarkSecondary),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Dismiss',
                      onPressed: _dismissWelcomeCard,
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  space.description.isNotEmpty
                      ? space.description
                      : 'Explore what this space has to offer.', // Fallback description
                  style: GoogleFonts.inter(
                      color: AppColors.textDarkSecondary, fontSize: 14, height: 1.5),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                // TODO: Add suggested action buttons (Join, Explore Events etc.)?
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showContentCreationMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Content',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.event, color: AppColors.gold),
                  ),
                  title: Text(
                    'Create Event',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Schedule an event for this space',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/spaces/${widget.spaceId}/create-event');
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.post_add, color: AppColors.gold),
                  ),
                  title: Text(
                    'Create Post',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Share a post with this space',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/spaces/${widget.spaceId}/create-post');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSpaceMenu(BuildContext context, SpaceEntity space) {
    // Get join state
    final joinState = ref.read(spaceJoinProvider(widget.spaceId));
    final isJoined = joinState.isJoined;
    
    HapticFeedback.mediumImpact();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Space Menu',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.white),
                  title: Text(
                    'Edit Space',
                    style: GoogleFonts.inter(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/spaces/${space.id}/edit');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.flag, color: Colors.white),
                  title: Text(
                    'Report Space',
                    style: GoogleFonts.inter(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    // Implement report functionality
                  },
                ),
                if (isJoined && !_isManager)
                  ListTile(
                    leading: const Icon(Icons.exit_to_app, color: Colors.red),
                    title: Text(
                      'Leave Space',
                      style: GoogleFonts.inter(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _handleJoinToggle();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Helper delegate class for the sticky TabBar using SliverPersistentHeader
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Use a background color that matches the HIVE aesthetic for the sticky bar
    return Container(
      color: AppColors.black, // Pure black for the tab bar container
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
} 