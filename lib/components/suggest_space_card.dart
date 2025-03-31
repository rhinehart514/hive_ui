import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

/// A card component for suggesting spaces to users that is consistent with SpaceCard
class SuggestSpaceCard extends ConsumerStatefulWidget {
  /// The name of the space
  final String spaceName;

  /// The category of the space
  final String category;

  /// A brief description
  final String description;

  /// URL for the space's image/logo
  final String? imageUrl;

  /// The number of members in the space
  final int memberCount;

  /// Whether this is an official space
  final bool isOfficial;

  /// Called when the user taps the join button
  final VoidCallback? onJoin;

  /// Called when the card is tapped
  final VoidCallback? onTap;

  /// Constructor
  const SuggestSpaceCard({
    super.key,
    required this.spaceName,
    required this.category,
    required this.description,
    this.imageUrl,
    this.memberCount = 0,
    this.isOfficial = false,
    this.onJoin,
    this.onTap,
  });

  @override
  ConsumerState<SuggestSpaceCard> createState() => _SuggestSpaceCardState();
}

class _SuggestSpaceCardState extends ConsumerState<SuggestSpaceCard>
    with SingleTickerProviderStateMixin {
  // Animation controller for press animation
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Track whether the card is being pressed
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller with same parameters as SpaceCard
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Create scale animation with same values as SpaceCard
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.03,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutQuad,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.imageUrl != null && widget.imageUrl!.isNotEmpty;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    // Optimize padding based on screen dimensions (matching SpaceCard)
    final cardPadding = isSmallScreen ? 12.0 : 16.0;

    // Using a more consistent cardHeight with SpaceCard
    const cardHeight = 140.0;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              widget.onTap?.call();
            },
            onTapDown: (_) {
              _animationController.forward();
              setState(() {
                _isHovering = true;
              });
            },
            onTapUp: (_) {
              _animationController.reverse();
              setState(() {
                _isHovering = false;
              });
            },
            onTapCancel: () {
              _animationController.reverse();
              setState(() {
                _isHovering = false;
              });
            },
            child: child,
          ),
        );
      },
      child: Container(
        height: cardHeight,
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[900]?.withOpacity(0.3),
              image: hasImage
                  ? DecorationImage(
                      image: NetworkImage(widget.imageUrl!),
                      fit: BoxFit.cover,
                      opacity: 0.3,
                    )
                  : null,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isHovering
                    ? AppColors.gold.withOpacity(0.5)
                    : Colors.white.withOpacity(0.1),
                width: 1,
              ),
              // Add a subtle gradient as background
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.cardBackground.withOpacity(0.9),
                  AppColors.cardBackground,
                ],
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Gradient overlay for readability
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.9),
                          Colors.black.withOpacity(0.5),
                          Colors.black.withOpacity(0.2),
                        ],
                        stops: const [0.0, 0.6, 0.9],
                      ),
                    ),
                  ),
                ),

                // Content layout
                Padding(
                  padding: EdgeInsets.all(cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // "Suggested for you" tag at the top
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppColors.gold.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.recommend,
                              color: AppColors.gold,
                              size: 12,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Suggested',
                              style: TextStyle(
                                color: AppColors.gold,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Spacer
                      const Spacer(),

                      // Space name & verified badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.spaceName,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.isOfficial)
                            const Icon(
                              Icons.verified,
                              color: AppColors.gold,
                              size: 16,
                            ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Category & member count
                      Row(
                        children: [
                          Text(
                            widget.category,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.people,
                            size: 12,
                            color: Colors.white.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.memberCount}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Join button
                      ElevatedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          widget.onJoin?.call();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: Colors.black,
                          minimumSize: const Size.fromHeight(32),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Join Space',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
