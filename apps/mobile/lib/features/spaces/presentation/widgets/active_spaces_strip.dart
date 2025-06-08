import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/models/space.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'dart:ui'; // Add this import for ImageFilter

/// A horizontal strip displaying active spaces with animation effects
class ActiveSpacesStrip extends ConsumerStatefulWidget {
  final List<Space> spaces;
  final Function(Space space) onSpaceTap;

  const ActiveSpacesStrip({
    Key? key,
    required this.spaces,
    required this.onSpaceTap,
  }) : super(key: key);

  @override
  ConsumerState<ActiveSpacesStrip> createState() => _ActiveSpacesStripState();
}

class _ActiveSpacesStripState extends ConsumerState<ActiveSpacesStrip> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filter spaces to only show those with high activity/trending
    final activeSpaces = widget.spaces
        .where((space) => 
            space.metrics.isTrending || 
            (space.metrics.engagementScore > 50))
        .toList();

    // If no active spaces, return empty container with minimal height
    if (activeSpaces.isEmpty) {
      return const SizedBox(height: 8);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title with gold accent
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: Row(
            children: [
              Text(
                'Active Spaces',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: 8),
                height: 8,
                width: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withOpacity(0.4),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Horizontal scrolling container for active spaces
        SizedBox(
          height: 130,
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: activeSpaces.length,
            itemBuilder: (context, index) {
              final space = activeSpaces[index];
              return _ActiveSpaceCard(
                space: space,
                onTap: () => widget.onSpaceTap(space),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Individual card for an active space with glow effect
class _ActiveSpaceCard extends StatefulWidget {
  final Space space;
  final VoidCallback onTap;

  const _ActiveSpaceCard({
    Key? key,
    required this.space,
    required this.onTap,
  }) : super(key: key);

  @override
  State<_ActiveSpaceCard> createState() => _ActiveSpaceCardState();
}

class _ActiveSpaceCardState extends State<_ActiveSpaceCard> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _glowAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Setup animations
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeInOut,
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.space.imageUrl != null && widget.space.imageUrl!.isNotEmpty;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(right: 12, bottom: 8, top: 4),
              width: 140,
              child: Stack(
                children: [
                  // Main Card with Glassmorphism
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withOpacity(0.1 * _glowAnimation.value),
                          blurRadius: 10 * _glowAnimation.value,
                          spreadRadius: 1 * _glowAnimation.value,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          // Image or Gradient Background
                          hasImage
                              ? Image.network(
                                  widget.space.imageUrl!,
                                  width: 140,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[900],
                                      child: const Icon(Icons.broken_image, color: Colors.white54),
                                    );
                                  },
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.grey[800]!,
                                        Colors.grey[900]!,
                                      ],
                                    ),
                                  ),
                                ),
                          
                          // Overlay with glassmorphism effect
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.black.withOpacity(0.3),
                                        Colors.black.withOpacity(0.6),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                      width: 1.0,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          // Content (Icon, Name, Tag)
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Space icon or first letter
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey[800]!.withOpacity(0.5),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: widget.space.icon != null
                                      ? Icon(
                                          widget.space.icon,
                                          color: Colors.white,
                                          size: 20,
                                        )
                                      : Center(
                                          child: Text(
                                            widget.space.name.isNotEmpty
                                                ? widget.space.name[0].toUpperCase()
                                                : '?',
                                            style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                ),
                                
                                const Spacer(),
                                
                                // Space name
                                Text(
                                  widget.space.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                
                                // Space tag or type
                                if (widget.space.tags.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      widget.space.tags.first,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          
                          // Glow overlay
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.gold.withOpacity(0.1 * _glowAnimation.value),
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Status indicator (joined, builder, etc.)
                  if (widget.space.isJoined)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.gold,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gold.withOpacity(0.4),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
} 