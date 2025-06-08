import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/models/space.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/presentation/providers/spaces_repository_provider.dart';
import 'package:hive_ui/features/spaces/presentation/providers/space_providers.dart' as space_providers;
import 'package:hive_ui/shared/widgets/error_view.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/features/moderation/domain/entities/content_report_entity.dart';
import 'package:hive_ui/components/moderation/report_dialog.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart'; // For icons
import 'package:hive_ui/core/navigation/routes.dart'; // Import AppRoutes

// Placeholder Widgets (Define basic structure)
class HeroLayer extends StatelessWidget {
  final SpaceEntity space;
  const HeroLayer({Key? key, required this.space}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Implement conditional logic for Ritual, Pin, Event, Welcome
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      color: AppColors.dark2, // Example temporary background
      child: Center(
          child: Text('Dynamic Hero Layer for ${space.name}',
              style: GoogleFonts.inter(color: AppColors.textSecondary))),
    );
  }
}

class DropFeed extends StatelessWidget {
  final String spaceId;
  const DropFeed({Key? key, required this.spaceId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Implement Drop fetching and ListView/SliverList of DropCards
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => DropCardPlaceholder(index: index),
        childCount: 15, // Example count
      ),
    );
  }
}

class DropCardPlaceholder extends StatelessWidget {
  final int index;
  const DropCardPlaceholder({Key? key, required this.index}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dark2, // Card color
        borderRadius: BorderRadius.circular(16), // HIVE Card Radius
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 16, backgroundColor: AppColors.dark3),
              const SizedBox(width: 8),
              Text('User ${index + 1}', style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
              const Spacer(),
              Text('${index+1}h ago', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'This is a placeholder for Drop content #${index + 1}. It might contain text, images, or event links.',
            style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(PhosphorIcons.fire(), size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text('${index * 3}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(width: 16),
              Icon(PhosphorIcons.chatCircle(), size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text('$index', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
            ],
          )
        ],
      ),
    );
  }
}

class ComposerBar extends StatelessWidget {
  const ComposerBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Implement collapsed/expanded state, text field, icons, etc.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.dark2, // Secondary surface or slightly darker
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5)),
      ),
      child: Row(
        children: [
          const CircleAvatar(radius: 16, backgroundColor: AppColors.dark3),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Drop something...',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          Icon(PhosphorIcons.plusCircle(), size: 24, color: AppColors.gold),
        ],
      ),
    );
  }
}

/// A screen to display details of a space or club - REBUILT STRUCTURE
class SpaceDetailScreen extends ConsumerStatefulWidget {
  final String? spaceId;
  final Space? space; // Keep direct space object if passed
  final String? spaceType; // Keep for potential use, but structure changed
  
  const SpaceDetailScreen({
    Key? key,
    this.spaceId,
    this.space, // Allow passing space directly
    this.spaceType, // May not be needed for routing anymore
  }) : assert(spaceId != null || space != null, 'Must provide at least spaceId or space object'),
      super(key: key);
  
  @override
  ConsumerState<SpaceDetailScreen> createState() => _SpaceDetailScreenState();
}

class _SpaceDetailScreenState extends ConsumerState<SpaceDetailScreen> {
  // Removed TabController, keep ScrollController for CustomScrollView
  late ScrollController _scrollController;
  
  // Keep relevant UI state
  bool _isFollowing = false;
  bool _isSpaceManager = false;
  bool _isLoading = true;
  
  // Removed AutomaticKeepAliveClientMixin
  
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    
    // Fetch initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fetchInitialData();
    });
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  // Fetch initial space data and user status
  Future<void> _fetchInitialData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });

    final spaceId = widget.spaceId ?? widget.space?.id;
    if (spaceId == null) {
      setState(() { _isLoading = false; });
      // Show an error view if spaceId is truly null
      // This state should ideally not be reachable due to constructor assert
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Space ID is missing.')));
      return;
    }

    try {
      // Ensure space data is loaded (if only ID was passed)
      if (widget.space == null) {
        await ref.read(space_providers.spacesProvider.notifier).refreshSpace(spaceId);
  }
  
      // Check following/manager status
      final repository = ref.read(spaceRepositoryProvider);
      final currentUser = ref.read(currentUserProvider);
      
      bool hasJoined = false;
      bool isManager = false;
      
      if (currentUser.isNotEmpty) {
        final userId = currentUser.id;
        final results = await Future.wait([
          repository.hasJoinedSpace(spaceId, userId: userId),
          repository.getSpaceMember(spaceId, userId).then((member) => member?.role == 'admin'),
        ]);
        hasJoined = results[0];
        isManager = results[1];
      } 
      
      if (mounted) {
        setState(() {
          _isFollowing = hasJoined;
          _isSpaceManager = isManager;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching initial space data: $e');
      if (mounted) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading space details: ${e.toString()}')));
      }
    } 
  }
  
  // Handle join/leave space with optimistic updates
  Future<void> _handleJoinToggle() async {
    // Keep existing logic for now, may need adjustments later
    HapticFeedback.mediumImpact();
    setState(() { _isFollowing = !_isFollowing; });
    try {
      final repository = ref.read(spaceRepositoryProvider);
      final currentUser = ref.read(currentUserProvider);
      final spaceId = widget.spaceId ?? widget.space?.id;
      if (currentUser.isEmpty || spaceId == null) {
        _showLoginPrompt();
        setState(() { _isFollowing = !_isFollowing; });
        return;
      }
      if (_isFollowing) {
        await repository.joinSpace(spaceId, userId: currentUser.id);
      } else {
        await repository.leaveSpace(spaceId, userId: currentUser.id);
      }
      ref.read(space_providers.spacesProvider.notifier).refreshSpace(spaceId);
      ref.read(space_providers.spaceMetricsProvider.notifier).refreshMetrics(spaceId);
    } catch (e) {
      setState(() { _isFollowing = !_isFollowing; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), behavior: SnackBarBehavior.floating));
      }
    }
  }
  
  // Show login prompt if user is not authenticated
  void _showLoginPrompt() {
    // Keep existing logic
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign In Required', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text('You need to sign in to join spaces.', style: GoogleFonts.inter()),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cancel', style: GoogleFonts.inter())),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go(AppRoutes.signIn); // Use GoRouter
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: Colors.black),
            child: Text('Sign In', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Show report dialog
  void _showReportDialog(SpaceEntity space) {
    HapticFeedback.mediumImpact();
    final String? ownerId = space.admins.isNotEmpty ? space.admins.first : null;
    showReportDialog(context, contentId: space.id, contentType: ReportedContentType.space, contentPreview: space.name, ownerId: ownerId);
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, child) {
      final spaceId = widget.spaceId ?? widget.space?.id;
      if (spaceId == null) {
        // Add required icon parameter
        return const ErrorView(message: 'Missing Space Identifier', icon: Icons.error_outline);
    }
    
      // Watch the provider for the space entity
      final spaceAsync = ref.watch(space_providers.spaceByIdProvider(spaceId));
      
      return spaceAsync.when(
        data: (spaceEntity) {
          if (spaceEntity == null) {
            // Add required icon parameter
            return const ErrorView(message: 'Space not found', icon: Icons.error_outline);
          }
          return _buildScaffold(spaceEntity);
        },
        loading: () => const Scaffold(
          backgroundColor: Color(0xFF0D0D0D), // Use correct background
          body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
        ),
        error: (error, stack) => ErrorView(
          message: error.toString(),
          // Add required icon parameter
          icon: Icons.refresh, // Use refresh icon for retry action
          onRetry: () => ref.invalidate(space_providers.spaceByIdProvider(spaceId)),
        ),
        );
    });
    }
    
  // Main build method for the screen layout
  Widget _buildScaffold(SpaceEntity space) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D), // HIVE Background #0D0D0D
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D), // Match background
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIcons.arrowLeft(), color: AppColors.textPrimary), // Use Phosphor icon
          onPressed: () => context.pop(),
          tooltip: 'Back',
          splashRadius: 24,
        ),
        title: Text(
          space.name,
          style: GoogleFonts.inter( // Use SF Pro Text ideally, fallback to Inter
            fontSize: 20, 
            fontWeight: FontWeight.bold, 
            color: AppColors.textPrimary
          ),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true, // Center title for aesthetic
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.dotsThreeOutlineVertical(), color: AppColors.textPrimary), // Use Phosphor icon
            onPressed: () {
              // TODO: Implement Overflow Menu (Builder, Invite, Report)
              _showOverflowMenu(space);
            },
            tooltip: 'Space Settings',
            splashRadius: 24,
          ),
        ],
      ),
      // Use Stack for sticky composer
      body: Stack(
        children: [
          // Scrollable content (Hero + Feed)
          CustomScrollView(
          controller: _scrollController,
            slivers: [
              // 2. Dynamic Hero Layer (as a Sliver)
              SliverToBoxAdapter(
                child: HeroLayer(space: space), // Placeholder
              ),
              
              // Spacer between Hero and Feed (optional)
              const SliverToBoxAdapter(child: SizedBox(height: 12)), // Use HIVE spacing
              
              // 3. Feed Layer (Drop Stream)
              DropFeed(spaceId: space.id), // Placeholder
              
              // Padding at the bottom to avoid composer overlap
              const SliverToBoxAdapter(child: SizedBox(height: 80)), // Adjust height based on composer
            ],
          ),
          
          // 4. Composer Bar (Sticky Footer)
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ComposerBar(), // Placeholder
          ),
        ],
      ),
    );
  }
  
  // Placeholder for overflow menu
  void _showOverflowMenu(SpaceEntity space) {
    HapticFeedback.mediumImpact();
     // TODO: Implement using showModalBottomSheet or similar
     showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.dark2.withOpacity(0.95), // Use secondary surface, slightly transparent
        barrierColor: Colors.black.withOpacity(0.6),
        shape: const RoundedRectangleBorder(
           borderRadius: BorderRadius.only(topLeft: Radius.circular(16.0), topRight: Radius.circular(16.0)),
        ),
        builder: (context) {
           return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
              child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
                    // Handle
                    Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: AppColors.grey700, borderRadius: BorderRadius.circular(2))),
                    // Builder actions (conditional)
                    if (_isSpaceManager)
                       ListTile(
                          leading: Icon(PhosphorIcons.wrench(), color: AppColors.textSecondary),
                          title: Text('Builder Tools', style: GoogleFonts.inter(color: AppColors.textPrimary)),
                          onTap: () { Navigator.pop(context); /* TODO: Navigate to Builder Screen */ },
                    ),
                    // Invite
                    ListTile(
                       leading: Icon(PhosphorIcons.userPlus(), color: AppColors.textSecondary),
                       title: Text('Invite Members', style: GoogleFonts.inter(color: AppColors.textPrimary)),
                       onTap: () { Navigator.pop(context); /* TODO: Implement Invite Flow */ },
                  ),
                    // Report
                    ListTile(
                       leading: Icon(PhosphorIcons.flag(), color: Colors.red.shade400),
                       title: Text('Report Space', style: GoogleFonts.inter(color: Colors.red.shade400)),
                       onTap: () {
                          Navigator.pop(context);
                          _showReportDialog(space);
                       },
                    ),
                    SizedBox(height: MediaQuery.of(context).padding.bottom + 8), // Safe area
        ],
      ),
    );
        },
      );
  }
} 