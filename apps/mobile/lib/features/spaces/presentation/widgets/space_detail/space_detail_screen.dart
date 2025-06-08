import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/models/club.dart';
import 'package:hive_ui/models/space.dart';
import 'package:hive_ui/models/space_metrics.dart';
import 'package:hive_ui/features/events/domain/entities/event.dart' as entity;
import 'package:hive_ui/features/events/data/mappers/event_mapper.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_metrics_entity.dart';
import 'package:hive_ui/features/spaces/presentation/providers/spaces_repository_provider.dart';
import 'package:hive_ui/features/spaces/presentation/providers/space_providers.dart' as space_providers;
import 'package:hive_ui/core/services/firebase/firebase_services.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/space_detail/space_header.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/space_detail/space_about_tab.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/space_detail/space_events_tab.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/space_members_tab.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/space_message_board.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/space_content_modules.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/space_builder_tools.dart';
import 'package:hive_ui/shared/widgets/error_view.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart';
import 'package:hive_ui/features/profile/presentation/screens/profile_page.dart';
import 'package:hive_ui/features/spaces/domain/mappers/space_entity_mapper.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/features/moderation/domain/entities/content_report_entity.dart';
import 'package:hive_ui/components/moderation/report_dialog.dart';
import 'package:hive_ui/models/event.dart' as model_event;
import 'package:hive_ui/features/spaces/presentation/widgets/space_join_visualization.dart';

/// A screen to display details of a space or club
class SpaceDetailScreen extends ConsumerStatefulWidget {
  final String? spaceId;
  final Club? club;
  final Space? space;
  final String? spaceType;
  
  const SpaceDetailScreen({
    Key? key,
    this.spaceId,
    this.club,
    this.space,
    this.spaceType,
  }) : assert(spaceId != null || club != null || space != null,
            'Must provide at least one of spaceId, club, or space'),
      super(key: key);
  
  @override
  ConsumerState<SpaceDetailScreen> createState() => _SpaceDetailScreenState();
}

class _SpaceDetailScreenState extends ConsumerState<SpaceDetailScreen> 
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  
  // UI state
  bool _isFollowing = false;
  bool _isSpaceManager = false;
  bool _chatUnlocked = false;
  bool _isLoading = true;
  
  // Keep tab state alive
  @override
  bool get wantKeepAlive => true;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with 4 tabs instead of 3
    _tabController = TabController(length: 4, vsync: this);
    _scrollController = ScrollController();
    
    // Add scroll listener for performance optimization
    _scrollController.addListener(_handleScroll);
    
    // Refresh space data if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshSpaceIfNeeded();
      _checkSpaceStatus();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }
  
  // Optimize scroll performance
  void _handleScroll() {
    if (!mounted) return;
    
    // Only rebuild if we've scrolled enough to make a visual difference
    if (_scrollController.position.pixels % 5 == 0) {
      setState(() {});
    }
  }
  
  // Refresh space data if it's stale or not in cache
  void _refreshSpaceIfNeeded() {
    if (widget.spaceId != null) {
      final spacesNotifier = ref.read(space_providers.spacesProvider.notifier);
      final spaces = ref.read(space_providers.spacesProvider);
      
      // If space is not in cache or is expired, refresh it
      if (!spaces.containsKey(widget.spaceId) || spacesNotifier.isExpired(widget.spaceId!)) {
        spacesNotifier.refreshSpace(widget.spaceId!);
        ref.read(space_providers.spaceMetricsProvider.notifier).refreshMetrics(widget.spaceId!);
      }
    }
  }
  
  // Check if user is following space and if user is a space manager
  Future<void> _checkSpaceStatus() async {
    // Ensure widget is still mounted before proceeding
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final repository = ref.read(spaceRepositoryProvider);
      final currentUser = ref.read(currentUserProvider);
      
      // Default values
      bool hasJoined = false;
      bool isManager = false;
      
      if (currentUser.isNotEmpty && widget.spaceId != null) {
        final spaceId = widget.spaceId!;
        final userId = currentUser.id;

        // Perform checks concurrently for efficiency
        final results = await Future.wait([
          repository.hasJoinedSpace(spaceId, userId: userId),
          // TODO: Replace this with a dedicated repository method if possible
          // Check if the user has the 'admin' role in the members subcollection
          repository.getSpaceMember(spaceId, userId).then((member) => member?.role == 'admin')
        ]);

        hasJoined = results[0];
        isManager = results[1];
      } 
      
      // Update state only if mounted
      if (mounted) {
        setState(() {
          _isFollowing = hasJoined;
          _isSpaceManager = isManager; // Use the role check result
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking space status: $e');
      // Update state only if mounted
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Reset potentially incorrect optimistic states on error
          _isFollowing = false; 
          _isSpaceManager = false;
        });
      }
    } 
  }
  
  // Handle join/leave space with optimistic updates
  Future<void> _handleJoinToggle() async {
    HapticFeedback.mediumImpact();
    
    // Optimistic update
    setState(() {
      _isFollowing = !_isFollowing;
    });
    
    try {
      final repository = ref.read(spaceRepositoryProvider);
      final currentUser = ref.read(currentUserProvider);
      
      if (currentUser.isEmpty) {
        // User is not authenticated, show login prompt
        _showLoginPrompt();
        // Revert optimistic update
        setState(() {
          _isFollowing = !_isFollowing;
        });
        return;
      }
      
      if (_isFollowing) {
        await repository.joinSpace(widget.spaceId!, userId: currentUser.id);
      } else {
        await repository.leaveSpace(widget.spaceId!, userId: currentUser.id);
      }
      
      // Refresh space data in background
      ref.read(space_providers.spacesProvider.notifier).refreshSpace(widget.spaceId!);
      ref.read(space_providers.spaceMetricsProvider.notifier).refreshMetrics(widget.spaceId!);
      
    } catch (e) {
      // Revert optimistic update on error
      setState(() {
        _isFollowing = !_isFollowing;
      });
      
      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
  
  // Show login prompt if user is not authenticated
  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign In Required', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text(
          'You need to sign in to join spaces.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to login page
              context.go('/auth/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.black,
            ),
            child: Text('Sign In', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    // Check if Firebase is initialized
    final firebaseInitialized = ref.watch(firebaseCoreServiceProvider).isInitialized;
    
    // Show loading indicator when checking space status
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.black,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
          ),
        ),
      );
    }
    
    if (!firebaseInitialized) {
      return const Scaffold(
        backgroundColor: AppColors.black,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
          ),
        ),
      );
    }
    
    // If we have a spaceId, use the providers to fetch data
    if (widget.spaceId != null) {
      final spaceAsync = ref.watch(space_providers.spaceByIdProvider(widget.spaceId!));
      
      return spaceAsync.when(
        data: (space) {
          if (space == null) {
            return const ErrorView(
              message: 'Space not found',
              icon: Icons.error_outline,
            );
          }
          
          final metricsAsync = ref.watch(space_providers.spaceMetricsByIdProvider(widget.spaceId!));
          
          return metricsAsync.when(
            data: (metrics) => _buildContent(space, metrics),
            loading: () => _buildContent(space, null),
            error: (error, stack) => _buildContent(space, null),
          );
        },
        loading: () => const Scaffold(
          backgroundColor: AppColors.black,
          body: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
            ),
          ),
        ),
        error: (error, stack) => ErrorView(
          message: error.toString(),
          icon: Icons.error_outline,
          onRetry: () => _refreshSpaceIfNeeded(),
        ),
      );
    }
    
    // If we have a club or space directly, build the UI with that
    if (widget.club != null || widget.space != null) {
      // Use our mapper to convert Club or Space to SpaceEntity
      SpaceEntity spaceEntity;
      if (widget.club != null) {
        spaceEntity = SpaceEntityMapper.fromClub(widget.club!);
      } else if (widget.space != null) {
        spaceEntity = SpaceEntityMapper.fromSpace(widget.space!);
      } else {
        return const ErrorView(
          message: 'Invalid space configuration',
          icon: Icons.error_outline,
        );
      }
      
      return _buildContent(spaceEntity, spaceEntity.metrics);
    }
    
    return const ErrorView(
      message: 'Invalid space configuration',
      icon: Icons.error_outline,
    );
  }
  
  Widget _buildContent(SpaceEntity space, SpaceMetricsEntity? metrics) {
    final memberCount = metrics?.memberCount ?? space.metrics.memberCount;
    final eventCount = metrics?.weeklyEvents ?? space.metrics.weeklyEvents;
    _chatUnlocked = memberCount >= 10;
    
    // Get screen size for adaptive layout
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isSmallScreen = screenWidth < 360;
    
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'report') {
                _showReportDialog(space);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'report',
                child: ListTile(
                  leading: Icon(Icons.report_outlined, color: Colors.red),
                  title: Text('Report Space'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          // Only rebuild on scroll end for better performance
          if (notification is ScrollEndNotification) {
            setState(() {});
          }
          return false;
        },
        child: NestedScrollView(
          controller: _scrollController,
          // Use BouncingScrollPhysics for iOS-style physics on all platforms
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // Space header
              SliverToBoxAdapter(
                child: SpaceHeader(
                  space: space,
                  scrollOffset: _scrollController.hasClients ? _scrollController.offset : 0,
                  isFollowing: _isFollowing,
                  memberCount: memberCount,
                  eventCount: eventCount,
                  chatUnlocked: _chatUnlocked,
                  onJoinPressed: _handleJoinToggle,
                ),
              ),
              
              // Display join visualization card if not joined
              if (!_isFollowing)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: SpaceJoinVisualization(
                      space: Space(
                        id: space.id,
                        name: space.name,
                        description: space.description,
                        imageUrl: space.imageUrl,
                        bannerUrl: space.bannerUrl,
                        isJoined: _isFollowing,
                        isPrivate: space.isPrivate,
                        icon: Icons.group, // Default icon
                        metrics: SpaceMetrics.empty(),
                        createdAt: space.createdAt,
                        updatedAt: space.updatedAt,
                      ),
                      isExpanded: true,
                      onClose: () {}, // No close action needed in this context
                    ),
                  ),
                ),
              
              // Tab bar with optimized sizing for mobile
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    controller: _tabController,
                    tabs: [
                      Tab(
                        text: 'About',
                        // Adjust height for better touch targets on mobile
                        height: isSmallScreen ? 40 : 46,
                      ),
                      Tab(
                        text: 'Events',
                        height: isSmallScreen ? 40 : 46,
                      ),
                      Tab(
                        text: 'Members',
                        height: isSmallScreen ? 40 : 46,
                      ),
                      Tab(
                        text: 'Discussions',
                        height: isSmallScreen ? 40 : 46,
                      ),
                    ],
                    indicatorColor: AppColors.gold,
                    indicatorWeight: 2,
                    // Add padding for small screens
                    labelPadding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 8 : 16,
                    ),
                    // Optimize label styles for better readability
                    labelStyle: GoogleFonts.inter(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: GoogleFonts.inter(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                pinned: true,
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            // Use ClampingScrollPhysics for better performance on TabBarView
            physics: const ClampingScrollPhysics(),
            children: [
              // About tab - Enhanced with Space Content Modules
              SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description section
                    SpaceAboutTab(
                      description: space.description,
                      aboutItems: const [], // Empty list for now
                      onEditDescription: _isSpaceManager ? () {
                        // Show edit description dialog
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Edit Description'),
                            content: const Text('Edit description functionality'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      } : null,
                    ),
                    
                    // Builder tools for space managers
                    if (_isSpaceManager)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                        child: SpaceBuilderTools(space: space),
                      ),
                    
                    // Content modules
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: SpaceContentModules(
                        space: space,
                        isManager: _isSpaceManager,
                        isJoined: _isFollowing,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Events tab
              FutureBuilder<List<entity.Event>>(
                future: ref.read(spaceRepositoryProvider).getSpaceEvents(space.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading events'));
                  }
                  
                  final domainEvents = snapshot.data ?? [];
                  // Convert domain events to model events
                  final modelEvents = domainEvents.map(EventMapper.toModel).toList();
                  
                  return SpaceEventsTab(
                    events: modelEvents,
                    onEventTap: (event) {
                      _navigateToEventDetails(event);
                    },
                    isManager: _isSpaceManager,
                    onCreateEvent: _isSpaceManager ? () {
                      _navigateToCreateEvent();
                    } : null,
                  );
                },
              ),
              
              // Members tab
              SpaceMembersTab(
                spaceId: space.id,
              ),
              
              // Discussions tab (message board)
              space.hasMessageBoard
                ? SpaceMessageBoard(spaceId: space.id)
                : Center(
                    child: Text(
                      'Discussions are not enabled for this space',
                      style: GoogleFonts.inter(color: Colors.grey),
                    ),
                  ),
            ],
          ),
        ),
      ),
      // Add floating action button for message board
      floatingActionButton: _buildFloatingActionButton(space),
      // Position the FAB in the bottom right, but slightly raised to avoid nav bar
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
  
  // Extract FAB logic to a separate method for better readability
  Widget? _buildFloatingActionButton(SpaceEntity space) {
    // Show different FABs based on the active tab
    switch (_tabController.index) {
      case 0: // About tab - no FAB
        return null;
      case 1: // Events tab - Create Event FAB for managers
        return _isSpaceManager ? FloatingActionButton(
          onPressed: () {
            _navigateToCreateEvent();
            HapticFeedback.mediumImpact();
          },
          backgroundColor: AppColors.gold,
          tooltip: 'Create Event',
          child: const Icon(
            Icons.add,
            color: Colors.black,
          ),
        ) : null;
      case 3: // Discussions tab - Message FAB
        return space.hasMessageBoard ? FloatingActionButton(
          onPressed: () {
            // Add/focus on message input field
            // This logic depends on the implementation of SpaceMessageBoard
            HapticFeedback.mediumImpact();
          },
          backgroundColor: AppColors.gold,
          tooltip: 'New Message',
          child: const Icon(
            Icons.chat_bubble_outline,
            color: Colors.black,
          ),
        ) : null;
      default:
        return null;
    }
  }
  
  // Show edit description dialog
  void _showEditDescriptionDialog() {
    final TextEditingController controller = TextEditingController(text: '');
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Edit Description', style: GoogleFonts.inter()),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Enter space description',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final repository = ref.read(spaceRepositoryProvider);
                final space = await repository.getSpaceById(widget.spaceId!);
                
                if (!mounted) return;
                
                if (space != null) {
                  await repository.updateSpace(
                    space.copyWith(description: controller.text),
                  );
                  
                  if (!mounted) return;
                  Navigator.of(dialogContext).pop();
                  // Refresh space details
                  ref.invalidate(space_providers.spaceByIdProvider(widget.spaceId!));
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  // Navigate to event details safely
  void _navigateToEventDetails(model_event.Event event) {
    HapticFeedback.mediumImpact();
    if (mounted) {
      // Navigate using the model event id
      context.pushNamed(
        'event-details',
        pathParameters: {'eventId': event.id},
      );
    }
  }
  
  // Navigate to member profile safely with proper context usage
  void _navigateToMemberProfile(String userId, String displayName) {
    HapticFeedback.mediumImpact();
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ProfilePage(userId: userId),
        ),
      );
    }
  }
  
  // Show invite member dialog
  void _showInviteMembersDialog() {
    HapticFeedback.mediumImpact();
    
    final TextEditingController emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Invite Member', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter email address of the person you want to invite.',
              style: GoogleFonts.inter(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Email address',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () {
              try {
                final email = emailController.text.trim();
                if (email.isEmpty || !email.contains('@')) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid email address'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                
                // Close the dialog
                Navigator.of(dialogContext).pop();
                
                // No need to keep repository as unused variable
                // Just show a snackbar for now
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Invitation sent to $email'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.black,
            ),
            child: Text('Send Invite', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
  
  // Navigate to create event page safely
  void _navigateToCreateEvent() {
    HapticFeedback.mediumImpact();
    if (mounted) {
      context.pushNamed(
        'create-event',
        queryParameters: {'spaceId': widget.spaceId},
      );
    }
  }
  
  // Show report dialog
  void _showReportDialog(SpaceEntity space) {
    HapticFeedback.mediumImpact();
    
    // Use the first admin as the owner ID, if available
    final String? ownerId = space.admins.isNotEmpty ? space.admins.first : null;
    
    showReportDialog(
      context, 
      contentId: space.id,
      contentType: ReportedContentType.space,
      contentPreview: space.name,
      ownerId: ownerId,
    ).then((reported) {
      if (reported == true) {
        // Success message already shown by the dialog
      }
    });
  }
}

// Helper widget to keep tab state alive
class KeepAlive extends StatefulWidget {
  final Widget child;

  const KeepAlive({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<KeepAlive> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

// Class to keep the tab bar pinned with optimized rebuild
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final double _height;

  _SliverAppBarDelegate(this.tabBar) : _height = tabBar.preferredSize.height;

  @override
  double get minExtent => _height;
  
  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.black,
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false; // Optimize rebuilds since tab bar rarely changes
  }
} 