import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';

// Theme and Styling
import 'package:hive_ui/theme/app_colors.dart';

// Models and Entities
import 'package:hive_ui/models/club.dart';
import 'package:hive_ui/models/space.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_metrics_entity.dart';

// Providers
import 'package:hive_ui/features/spaces/presentation/providers/spaces_repository_provider.dart';
import 'package:hive_ui/features/spaces/presentation/providers/space_providers.dart' as space_providers;
import 'package:hive_ui/features/spaces/presentation/providers/spaces_async_providers.dart';
import 'package:hive_ui/core/services/firebase/firebase_services.dart';

// Components
import 'package:hive_ui/features/clubs/presentation/widgets/space_detail/space_header.dart';
import 'package:hive_ui/features/clubs/presentation/widgets/space_detail/space_about_tab.dart';
import 'package:hive_ui/features/clubs/presentation/widgets/space_detail/space_events_tab.dart';
import 'package:hive_ui/features/clubs/presentation/widgets/space_detail/space_members_tab.dart';
import 'package:hive_ui/shared/widgets/error_view.dart';

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
  
  // Keep tab state alive
  @override
  bool get wantKeepAlive => true;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize controllers
    _tabController = TabController(length: 3, vsync: this);
    _scrollController = ScrollController();
    
    // Add scroll listener for performance optimization
    _scrollController.addListener(_handleScroll);
    
    // Refresh space data if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshSpaceIfNeeded();
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
  
  // Handle join/leave space with optimistic updates
  Future<void> _handleJoinToggle() async {
    HapticFeedback.mediumImpact();
    
    // Optimistic update
    setState(() {
      _isFollowing = !_isFollowing;
    });
    
    try {
      final repository = ref.read(spaceRepositoryProvider);
      final userId = 'current_user_id'; // TODO: Get from auth provider
      
      if (_isFollowing) {
        await repository.leaveSpace(widget.spaceId!, userId);
      } else {
        await repository.joinSpace(widget.spaceId!, userId);
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
  
  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    // Check if Firebase is initialized
    final firebaseInitialized = ref.watch(firebaseCoreServiceProvider).isInitialized;
    
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
      final spaceId = widget.club?.id ?? widget.space?.id ?? '';
      final metrics = SpaceMetricsEntity(
        spaceId: spaceId,
        memberCount: widget.club?.memberCount ?? 0,
        activeMembers: 0,
        weeklyEvents: 0,
        monthlyEngagements: 0,
        lastActivity: DateTime.now(),
        hasNewContent: false,
        isTrending: false,
        activeMembers24h: const [],
        activityScores: const {},
        category: SpaceCategory.suggested,
        size: SpaceSize.small,
        engagementScore: 0.0,
      );
      
      return _buildContent(
        SpaceEntity(
          id: spaceId,
          name: widget.club?.name ?? widget.space?.name ?? '',
          description: widget.club?.description ?? widget.space?.description ?? '',
          iconCodePoint: Icons.groups.codePoint,
          metrics: metrics,
          createdAt: widget.club?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
          isPrivate: false, // TODO: Map from club/space privacy
          spaceType: SpaceType.other, // TODO: Map from club/space type
          imageUrl: '', // TODO: Map from club/space image
        ),
        metrics,
      );
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
    
    return Scaffold(
      backgroundColor: AppColors.black,
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
          physics: const AlwaysScrollableScrollPhysics(),
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // Space header
              SliverToBoxAdapter(
                child: SpaceHeader(
                  club: Club( // TODO: Create proper mapping
                    id: space.id,
                    name: space.name,
                    description: space.description,
                    category: space.spaceType.toString(),
                    memberCount: memberCount,
                    status: 'active',
                    icon: Icons.groups,
                    createdAt: space.createdAt,
                    updatedAt: DateTime.now(),
                    tags: [],
                    socialLinks: [],
                    website: '',
                    email: '',
                    meetingTimes: [],
                    resources: {},
                    requirements: [],
                    followersCount: memberCount,
                  ),
                  scrollOffset: _scrollController.hasClients ? _scrollController.offset : 0,
                  isFollowing: _isFollowing,
                  memberCount: memberCount,
                  eventCount: eventCount,
                  chatUnlocked: _chatUnlocked,
                  onJoinPressed: _handleJoinToggle,
                  extraInfo: _chatUnlocked 
                    ? "Chat unlocked" 
                    : "Need ${10 - memberCount > 0 ? 10 - memberCount : 0} more to unlock",
                ),
              ),
              
              // Tab bar
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'About'),
                      Tab(text: 'Events'),
                      Tab(text: 'Members'),
                    ],
                    indicatorColor: AppColors.gold,
                    indicatorWeight: 2,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    labelStyle: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                    dividerColor: Colors.transparent,
                  ),
                ),
                pinned: true,
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              // About tab - Lazy load with keep alive
              KeepAlive(
                child: SpaceAboutTab(
                  description: space.description,
                  aboutItems: [], // TODO: Get from space metadata
                  onEditDescription: _isSpaceManager ? _showEditDescriptionDialog : null,
                ),
              ),
              
              // Events tab - Lazy load with keep alive
              KeepAlive(
                child: FutureBuilder<List<Event>>(
                  future: (() {
                    debugPrint('🏛️ Loading events for space: ${space.id}');
                    debugPrint('Space type: ${space.spaceType}');
                    return ref.read(spaceRepositoryProvider).getSpaceEvents(space.id);
                  })(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      debugPrint('⌛ Loading events...');
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                        ),
                      );
                    }
                    
                    if (snapshot.hasError) {
                      debugPrint('❌ Error loading events: ${snapshot.error}');
                      debugPrint('Error stack trace: ${snapshot.stackTrace}');
                      
                      // Check if it's a date parsing error
                      final errorStr = snapshot.error.toString().toLowerCase();
                      final isDateError = errorStr.contains('timestamp') || 
                                       errorStr.contains('datetime') ||
                                       errorStr.contains('date');
                      
                      String errorMessage = 'Error loading events';
                      if (isDateError) {
                        errorMessage = 'Error loading events: Invalid date format in some events';
                        // Log for debugging
                        debugPrint('⚠️ Date parsing error detected. This might indicate inconsistent date formats in Firestore.');
                      }
                      
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.white, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              errorMessage,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => setState(() {}), // Refresh
                              child: const Text('Retry'),
                            )
                          ],
                        ),
                      );
                    }

                    final events = snapshot.data ?? [];
                    debugPrint('✨ Loaded ${events.length} events for space ${space.id}');
                    if (events.isEmpty) {
                      debugPrint('ℹ️ No events found for this space');
                    }
                    
                    return SpaceEventsTab(
                      events: events,
                      onEventTap: _navigateToEventDetails,
                      onCreateEvent: _isSpaceManager ? _navigateToCreateEvent : null,
                      isManager: _isSpaceManager,
                      rsvpStatuses: {},
                    );
                  },
                ),
              ),
              
              // Members tab - Lazy load with keep alive
              KeepAlive(
                child: SpaceMembersTab(
                  members: [], // TODO: Get from members provider
                  onMemberTap: _navigateToMemberProfile,
                  onInviteMember: _isSpaceManager ? _showInviteMemberDialog : null,
                  isManager: _isSpaceManager,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Show edit description dialog
  void _showEditDescriptionDialog() {
    final TextEditingController controller = TextEditingController(text: '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final repository = ref.read(spaceRepositoryProvider);
                final space = await repository.getSpaceById(widget.spaceId!);
                
                if (space != null) {
                  await repository.updateSpace(
                    space.copyWith(description: controller.text),
                  );
                  
                  if (mounted) {
                    Navigator.of(context).pop();
                    // Refresh space details
                    ref.invalidate(space_providers.spaceByIdProvider(widget.spaceId!));
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  // Navigate to event details
  void _navigateToEventDetails(Event event) {
    // TODO: Implement navigation to event details
    debugPrint('Navigate to event details: ${event.title}');
  }
  
  // Navigate to member profile
  void _navigateToMemberProfile(SpaceMember member) {
    // TODO: Implement navigation to member profile
    debugPrint('Navigate to member profile: ${member.name}');
  }
  
  // Show invite member dialog
  void _showInviteMemberDialog() {
    // TODO: Implement invite member dialog
    debugPrint('Show invite member dialog');
  }
  
  // Navigate to create event page
  void _navigateToCreateEvent() {
    // TODO: Implement navigation to create event page
    debugPrint('Navigate to create event');
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