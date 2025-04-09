import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/presentation/providers/space_providers.dart';
import 'package:hive_ui/features/spaces/presentation/providers/spaces_repository_provider.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/leadership_claim_dialog.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/lifecycle_state_indicator.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/space_members_tab.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/space_message_board.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/space_type_indicator.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/leadership_claim_status_widget.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/space_join_request.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/space_visibility_control.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/space_archive_control.dart';

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
  bool _isJoined = false;
  bool _isManager = false;
  bool _isLoading = true;

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
    setState(() {
      _isLoading = true;
    });

    try {
      final repository = ref.read(spaceRepositoryProvider);
      final currentUser = ref.read(currentUserProvider);
      
      if (currentUser.isEmpty) {
        setState(() {
          _isJoined = false;
          _isManager = false;
          _isLoading = false;
        });
        return;
      }
      
      // Check if user has joined the space
      final hasJoined = await repository.hasJoinedSpace(widget.spaceId, userId: currentUser.id);
      
      // Check if user is a manager of the space
      // This would typically check if the user has admin role in the space
      final userId = currentUser.id;
      final space = await repository.getSpaceById(widget.spaceId);
      final isManager = space?.admins.contains(userId) ?? false;
      
      if (mounted) {
        setState(() {
          _isJoined = hasJoined;
          _isManager = isManager;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking space status: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleJoinToggle() async {
    HapticFeedback.mediumImpact();
    
    final repository = ref.read(spaceRepositoryProvider);
    final currentUser = ref.read(currentUserProvider);
    
    if (currentUser.isEmpty) {
      // Show dialog to sign in
      _showSignInDialog();
      return;
    }
    
    // Optimistic update
    setState(() {
      _isJoined = !_isJoined;
    });
    
    try {
      if (_isJoined) {
        await repository.joinSpace(widget.spaceId, userId: currentUser.id);
      } else {
        await repository.leaveSpace(widget.spaceId, userId: currentUser.id);
      }
      
      // Refresh space data
      _refreshSpaceData();
    } catch (e) {
      // Revert optimistic update on error
      if (mounted) {
        setState(() {
          _isJoined = !_isJoined;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
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

  @override
  Widget build(BuildContext context) {
    final spaceAsync = ref.watch(spaceProvider(widget.spaceId));
    
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: spaceAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Error loading space: $err',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        data: (space) {
          if (space == null) {
            return const Center(
              child: Text(
                'Space not found',
                style: TextStyle(color: Colors.white),
              ),
            );
          }
          
          return CustomScrollView(
            slivers: [
              _buildAppBar(space),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSpaceHeader(space),
                    _buildTabBar(),
                  ],
                ),
              ),
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAboutTab(space),
                    _buildEventsTab(space),
                    SpaceMembersTab(spaceId: widget.spaceId),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(SpaceEntity space) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Colors.black.withOpacity(0.7),
      flexibleSpace: FlexibleSpaceBar(
        background: space.bannerUrl != null
            ? Image.network(
                space.bannerUrl!,
                fit: BoxFit.cover,
              )
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: space.gradientColors,
                  ),
                ),
              ),
        title: Text(
          space.name,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
      ),
      actions: [
        if (_isManager)
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to edit space screen
              context.push('/spaces/${space.id}/edit');
            },
          ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            // Show space options menu
            _showSpaceOptionsMenu(space);
          },
        ),
      ],
    );
  }

  Widget _buildSpaceHeader(SpaceEntity space) {
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: _isJoined
              ? OutlinedButton(
                  onPressed: _handleJoinToggle,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Leave Space',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : ElevatedButton(
                  onPressed: _handleJoinToggle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
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

  Widget _buildAboutTab(SpaceEntity space) {
    // Get the current user
    final currentUser = ref.watch(currentUserProvider);
    
    // Check if the user is an admin or creator of this space
    final isAdmin = space.admins.contains(currentUser.id);
    final isModerator = space.moderators.contains(currentUser.id);
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
            showClaimButton: !_isLoading && !_isManager,
            onClaimPressed: _handleClaimLeadership,
          ),
        const SizedBox(height: 16),
        
        // Join Request for private spaces the user hasn't joined
        if (space.isPrivate && !_isJoined)
          SpaceJoinRequest(
            space: space,
            onJoinStatusChanged: _checkSpaceStatus,
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
          const SizedBox(height: 16),
        ],
        
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

  Widget _buildEventsTab(SpaceEntity space) {
    // Implementation for events tab
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (space.eventIds.isEmpty)
          Card(
            color: Colors.black.withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 48,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No upcoming events',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This space doesn\'t have any scheduled events at the moment.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isManager || space.isJoined)
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to create event page
                        context.push('/spaces/${space.id}/create-event');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Create Event',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showSpaceOptionsMenu(SpaceEntity space) {
    HapticFeedback.mediumImpact();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.share, color: Colors.white),
                  title: Text(
                    'Share Space',
                    style: GoogleFonts.inter(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    // Implement share functionality
                  },
                ),
                if (_isManager) ...[
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
                ],
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
                if (_isJoined && !_isManager)
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