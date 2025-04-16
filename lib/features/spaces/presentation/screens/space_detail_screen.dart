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
import 'package:hive_ui/features/spaces/presentation/widgets/lifecycle_state_indicator.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/space_detail/space_events_tab.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/space_members_tab.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/space_message_board.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/space_type_indicator.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/leadership_claim_status_widget.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/space_visibility_control.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/space_archive_control.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/space_content_modules.dart';

/// A screen that displays detailed information about a space
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

class _SpaceDetailScreenState extends ConsumerState<SpaceDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isManager = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Refresh space data and check space status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshSpaceData();
        _checkSpaceStatus();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      
      if (currentUser == null || currentUser.id.isEmpty) {
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

  Future<void> _handleJoinToggle() async {
    HapticFeedback.mediumImpact();
    
    final currentUser = ref.read(currentUserProvider);
    
    if (currentUser == null || currentUser.id.isEmpty) {
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
                      // Copy space link
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Link copied to clipboard'),
                        ),
                      );
                    }),
                    _buildShareOption(Icons.message, 'Message', () {
                      // Share via message
                      Navigator.pop(context);
                    }),
                    _buildShareOption(Icons.people, 'Invite', () {
                      // Open invite dialog
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
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppColors.gold,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12,
              ),
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
        backgroundColor: Colors.grey[900],
        title: Text(
          'Invite to ${space.name}',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Coming soon: You\'ll be able to invite friends and contacts to join this space.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.inter(color: AppColors.gold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spaceAsync = ref.watch(spaceProvider(widget.spaceId));
    final eventsModel = ref.watch(spaceEventsModelProvider(widget.spaceId));
    
    // Get join state for the build method
    final joinState = ref.watch(spaceJoinProvider(widget.spaceId));
    final isJoined = joinState.isJoined;
    
    return Scaffold(
      backgroundColor: Colors.black,
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
          
          return Column(
            children: [
              _buildSpaceHeader(space),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAboutTab(space),
                    SpaceEventsTab(
                      onEventTap: (event) {
                        context.push('/events/${event.id}');
                      },
                      onCreateEvent: _isManager ? () {
                        context.push('/spaces/${widget.spaceId}/create-event');
                      } : null,
                      isManager: _isManager,
                      events: const [],
                    ),
                    SpaceMembersTab(
                      spaceId: widget.spaceId,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading space',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(spaceProvider(widget.spaceId));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black,
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
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

  Widget _buildSpaceHeader(SpaceEntity space) {
    if (space == null) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.gold.withOpacity(0.2),
                radius: 24,
                backgroundImage: space.imageUrl != null ? NetworkImage(space.imageUrl!) : null,
                child: space.imageUrl == null
                    ? Icon(
                        space.icon,
                        color: AppColors.gold,
                        size: 24,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      space.name,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      children: [
                        LifecycleStateIndicator(space: space),
                        if (space.claimStatus == SpaceClaimStatus.unclaimed)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: GestureDetector(
                              onTap: _handleClaimLeadership,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.add_moderator,
                                    size: 14,
                                    color: AppColors.gold,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Claim Leadership',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.gold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            space.description,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          _buildActionButtons(space),
        ],
      ),
    );
  }

  Widget _buildActionButtons(SpaceEntity space) {
    // Use the SpaceJoinProvider to get the current join state
    final joinState = ref.watch(spaceJoinProvider(widget.spaceId));
    final isJoined = joinState.isJoined;
    final isLoading = joinState.isLoading;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: isLoading 
              ? ElevatedButton(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.withOpacity(0.3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isJoined ? Colors.white : AppColors.gold,
                      ),
                    ),
                  ),
                )
              : isJoined
                  ? OutlinedButton.icon(
                      onPressed: _handleJoinToggle,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: Text(
                        'Joined',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: _handleJoinToggle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(
                        'Join Space',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: () {
            // Share space functionality
            HapticFeedback.mediumImpact();
            _handleShareSpace(space);
          },
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(
            Icons.share,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.gold,
        labelColor: AppColors.gold,
        unselectedLabelColor: Colors.white.withOpacity(0.7),
        labelStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'About'),
          Tab(text: 'Events'),
          Tab(text: 'Members'),
        ],
      ),
    );
  }

  Widget _buildAboutTab(SpaceEntity? space) {
    if (space == null) return const SizedBox.shrink();
    
    // Get the current user
    final currentUser = ref.watch(currentUserProvider);
    
    // Get join state from provider
    final joinState = ref.watch(spaceJoinProvider(widget.spaceId));
    final isJoined = joinState.isJoined;
    final isLoading = joinState.isLoading;
    
    // Check if the user is an admin or creator of this space
    final isAdmin = space.admins.contains(currentUser?.id);
    final isModerator = space.moderators.contains(currentUser?.id);
    final canModify = isAdmin || isModerator;
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Description section
        Text(
          'About',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          space.description,
          style: GoogleFonts.inter(
            fontSize: 16,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        
        // Space Type and Status Section
        Row(
          children: [
            // Space Type Indicator
            SpaceTypeIndicator(
              space: space,
              showDetails: true,
            ),
            const SizedBox(width: 8),
            // Lifecycle State Indicator
            LifecycleStateIndicator(
              space: space,
              showDetails: true,
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Leadership Claim Status if applicable
        if (space.requiresLeadershipClaim)
          LeadershipClaimStatusWidget(
            space: space,
            showClaimButton: !isLoading && !_isManager,
            onClaimPressed: _handleClaimLeadership,
          ),
        const SizedBox(height: 16),
        
        // Space Visibility Controls (only for admins/moderators)
        if (canModify)
          SpaceVisibilityControl(
            space: space,
            canModify: canModify,
            onVisibilityChanged: (isPrivate) {
              // Refresh space data after visibility change
              _refreshSpaceData();
            },
          ),
        if (canModify)
          const SizedBox(height: 16),
        
        // Archive Controls
        SpaceArchiveControl(
          space: space,
          canArchive: canModify,
          onLifecycleChanged: (newState) {
            // Refresh space data after lifecycle state change
            _refreshSpaceData();
          },
        ),
        const SizedBox(height: 24),
        
        // Tags section
        if (space.tags.isNotEmpty) ...[
          Text(
            'Tags',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: space.tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  '#$tag',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
        
        // Space Content Modules
        SpaceContentModules(
          space: space,
          isManager: _isManager,
          isJoined: isJoined,
        ),
        
        const SizedBox(height: 24),
        
        // Space metadata
        Text(
          'Details',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _buildMetadataItem(
          Icons.people, 
          '${space.metrics.memberCount} members',
        ),
        _buildMetadataItem(
          Icons.event, 
          '${space.eventIds.length} events',
        ),
        _buildMetadataItem(
          Icons.calendar_today, 
          'Created ${_formatDate(space.createdAt)}',
        ),
        if (space.lastActivityAt != null)
          _buildMetadataItem(
            Icons.access_time, 
            'Last activity ${_formatDate(space.lastActivityAt!)}',
          ),
      ],
    );
  }

  Widget _buildMetadataItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.white.withOpacity(0.7),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} ${(difference.inDays / 365).floor() == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} ${(difference.inDays / 30).floor() == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
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