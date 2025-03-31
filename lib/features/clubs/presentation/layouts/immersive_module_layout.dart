import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Models
import 'package:hive_ui/models/club.dart';
import 'package:hive_ui/models/space.dart';
import 'package:hive_ui/models/event.dart';

// Theme and Styling
import 'package:hive_ui/theme/app_colors.dart';

// Components
import 'package:hive_ui/features/clubs/presentation/components/immersive_club_header.dart';
import 'package:hive_ui/features/clubs/presentation/components/club_info_strip.dart';
import 'package:hive_ui/features/clubs/presentation/components/club_live_strip.dart';

/// A club space layout with an immersive header and module-based content structure.
/// This layout provides a modern and engaging experience for club spaces.
class ImmersiveModuleLayout extends ConsumerStatefulWidget {
  final Club club;
  final Space? space;
  final bool isManager;
  final List<Event>? events;
  final List<Widget> contentModules;
  final Widget? floatingActionButton;
  final Widget? bottomBar;

  const ImmersiveModuleLayout({
    Key? key,
    required this.club,
    this.space,
    this.isManager = false,
    this.events,
    required this.contentModules,
    this.floatingActionButton,
    this.bottomBar,
  }) : super(key: key);

  @override
  ConsumerState<ImmersiveModuleLayout> createState() =>
      _ImmersiveModuleLayoutState();
}

class _ImmersiveModuleLayoutState extends ConsumerState<ImmersiveModuleLayout> {
  final ScrollController _scrollController = ScrollController();
  double _parallaxOffset = 0.0;
  bool _showCompactHeader = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;

    setState(() {
      _parallaxOffset = _scrollController.offset * 0.5;
      _showCompactHeader = _scrollController.offset > 80;
    });

    // Add subtle haptic feedback at certain scroll thresholds
    if (_scrollController.hasClients &&
        _scrollController.position.pixels > 0 &&
        _scrollController.position.pixels % 500 < 20) {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions and status bar height
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final screenSize = MediaQuery.of(context).size;

    // Calculate header height (dynamic based on screen size)
    final maxHeaderHeight = screenSize.height * 0.45; // 45% of screen height
    final minHeaderHeight = statusBarHeight + 60; // Status bar + mini header

    // Calculate current header height based on scroll position
    final scrollOffset =
        _scrollController.hasClients ? _scrollController.offset : 0.0;
    final headerHeight = (maxHeaderHeight - scrollOffset).clamp(
      minHeaderHeight,
      maxHeaderHeight,
    );

    // Calculate opacity for the collapsed header
    final collapsedHeaderOpacity = (1 -
            (headerHeight - minHeaderHeight) /
                (maxHeaderHeight - minHeaderHeight) *
                2)
        .clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Main scrollable content
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Expandable app bar with club header
              SliverToBoxAdapter(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: headerHeight,
                  child: ImmersiveClubHeader(
                    club: widget.club,
                    space: widget.space,
                    height: headerHeight,
                    parallaxOffset: _parallaxOffset,
                  ),
                ),
              ),

              // Club info strip (categories, location, website)
              SliverToBoxAdapter(
                child: ClubInfoStrip(club: widget.club),
              ),

              // Live strip with upcoming events, social proof, highlights
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  child: ClubLiveStrip(
                    club: widget.club,
                    events: widget.events,
                  ),
                ),
              ),

              // Content modules
              SliverList.builder(
                itemCount: widget.contentModules.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: widget.contentModules[index],
                  );
                },
              ),

              // Bottom padding to accommodate the bottom bar
              if (widget.bottomBar != null)
                SliverToBoxAdapter(
                  child: SizedBox(
                      height: 80 + MediaQuery.of(context).padding.bottom),
                ),
            ],
          ),

          // Collapsed header that appears when scrolling
          AnimatedOpacity(
            opacity: collapsedHeaderOpacity,
            duration: const Duration(milliseconds: 200),
            child: _buildCompactHeader(context),
          ),

          // Back button
          Positioned(
            top: statusBarHeight + 8,
            left: 16,
            child: _buildBackButton(context),
          ),

          // Follow button
          Positioned(
            top: statusBarHeight + 8,
            right: 16,
            child: _buildFollowButton(),
          ),

          // Bottom bar (if provided)
          if (widget.bottomBar != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: widget.bottomBar!,
            ),
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
    );
  }

  // Build the compact header that appears when scrolling
  Widget _buildCompactHeader(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).padding.top + 60,
      decoration: BoxDecoration(
        color: AppColors.black.withOpacity(0.8),
        boxShadow: _showCompactHeader
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: Row(
        children: [
          const SizedBox(width: 60), // Space for back button

          // Club logo or initial
          _buildClubLogo(),

          // Club name
          Expanded(
            child: Text(
              widget.club.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Follow button (compact version)
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.gold),
              color: Colors.transparent,
            ),
            child: const Center(
              child: Text(
                'Follow',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build club logo/avatar for compact header
  Widget _buildClubLogo() {
    if (widget.club.logoUrl != null) {
      return Container(
        width: 30,
        height: 30,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: NetworkImage(widget.club.logoUrl!),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      return Container(
        width: 30,
        height: 30,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _getColorFromClubName(widget.club.name),
        ),
        child: Center(
          child: Text(
            _getInitials(widget.club.name),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    }
  }

  // Build back button
  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        context.pop();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: const Icon(
          Icons.arrow_back,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  // Build follow button
  Widget _buildFollowButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        // Follow action logic would go here
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.gold,
            width: 1,
          ),
        ),
        child: const Icon(
          Icons.add,
          color: AppColors.gold,
          size: 20,
        ),
      ),
    );
  }

  // Helper function to get color from club name
  Color _getColorFromClubName(String name) {
    if (name.isEmpty) return Colors.blueGrey;

    final colorValue =
        name.codeUnits.fold<int>(0, (int result, int unit) => result + unit);

    final colors = [
      Colors.blue.shade800,
      Colors.purple.shade800,
      Colors.red.shade800,
      Colors.green.shade800,
      Colors.orange.shade800,
      Colors.teal.shade800,
      Colors.indigo.shade800,
      Colors.pink.shade800,
    ];

    return colors[colorValue % colors.length];
  }

  // Helper function to get initials from club name
  String _getInitials(String name) {
    final words = name.split(' ');
    if (words.length > 1) {
      return words.take(2).map((word) => word.isNotEmpty ? word[0] : '').join();
    } else if (name.isNotEmpty) {
      return name.substring(0, 1);
    } else {
      return 'C';
    }
  }
}
