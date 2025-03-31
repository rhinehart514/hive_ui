import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/models/space.dart';
import 'package:hive_ui/theme/glassmorphism_guide.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'dart:ui';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/features/clubs/presentation/pages/club_space_page.dart';

/// A horizontally scrolling carousel of recommended spaces that appears
/// at the top of the Discover tab
class RecommendedSpacesCarousel extends ConsumerStatefulWidget {
  final List<Space> spaces;
  final Function(Space) onJoinSpace;
  final Function(Space) onTapSpace;

  const RecommendedSpacesCarousel({
    super.key,
    required this.spaces,
    required this.onJoinSpace,
    required this.onTapSpace,
  });

  @override
  ConsumerState<RecommendedSpacesCarousel> createState() =>
      _RecommendedSpacesCarouselState();
}

class _RecommendedSpacesCarouselState
    extends ConsumerState<RecommendedSpacesCarousel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Listen to scroll changes for animation effects
    _scrollController.addListener(() {
      setState(() {
        // Trigger rebuild on scroll
      });
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.spaces.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title in crisp white typography
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Text(
            'Recommended For You',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
        ),

        // Horizontal scrolling carousel with scroll indicator
        SizedBox(
          height: 120, // Fixed, smaller height for the simpler cards
          child: AnimationLimiter(
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(
                decelerationRate: ScrollDecelerationRate.fast,
              ),
              padding: const EdgeInsets.only(left: 16, right: 16),
              itemCount: widget.spaces.length,
              itemBuilder: (context, index) {
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 600),
                  delay: Duration(milliseconds: index * 50),
                  child: SlideAnimation(
                    horizontalOffset: 50.0,
                    curve: Curves.easeOutQuint,
                    child: FadeInAnimation(
                      curve: Curves.easeOut,
                      child: _buildSpaceCard(widget.spaces[index], index),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Bottom padding for separation from grid below
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSpaceCard(Space space, int index) {
    final bool isJoined = space.isJoined;

    return GestureDetector(
      onTap: () {
        // Apply haptic feedback for better tactile response
        HapticFeedback.mediumImpact();

        // Navigate to club space
        try {
          // Clean up and encode the space ID for URL safety
          final String encodedId = Uri.encodeComponent(space.id);
          debugPrint('Space card tapped: ${space.id}');
          debugPrint('Encoded ID for URL: $encodedId');

          GoRouter.of(context).push('/club-space?id=$encodedId');
          debugPrint('Navigated to club space via GoRouter');
        } catch (e) {
          debugPrint('Error using GoRouter: $e');

          // Fallback to MaterialPageRoute if GoRouter fails
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClubSpacePage(
                clubId: space.id, // Original ID for direct navigation
                space: space,
              ),
            ),
          );
          debugPrint('Navigated to club space via MaterialPageRoute');
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: SizedBox(
          width: 140, // Fixed width for consistent card size
          child: Stack(
            children: [
              // Card with glassmorphism effect
              Container(
                height: 110, // Reduced fixed height for simpler cards
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: -3,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: GlassmorphismGuide.kCardBlur,
                      sigmaY: GlassmorphismGuide.kCardBlur,
                    ),
                    child: Container(
                      padding:
                          const EdgeInsets.all(12), // Slightly reduced padding
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: Colors.white.withOpacity(0.1)),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.1),
                            Colors.grey[850]!.withOpacity(
                                GlassmorphismGuide.kCardGlassOpacity + 0.2),
                          ],
                          stops: const [0.1, 1.0],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Space name - focus on just this for simplicity
                          Text(
                            space.name,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Add button in top right
              if (!isJoined)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: AppColors.gold,
                    shape: const CircleBorder(),
                    elevation: 2,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        widget.onJoinSpace(space);
                      },
                      customBorder: const CircleBorder(),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        child: const Icon(
                          Icons.add,
                          color: Colors.black,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ),

              // Clickable overlay - covers whole card except the + button
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      widget.onTapSpace(space);
                    },
                    splashColor: Colors.white.withOpacity(0.1),
                    highlightColor: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
