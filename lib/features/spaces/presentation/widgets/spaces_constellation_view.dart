import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/models/space.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/extensions/glassmorphism_extension.dart';
import 'dart:math' as math;
import 'dart:ui';

/// A provider to track which spaces have been expanded/highlighted in the constellation
final constellationHighlightProvider = StateProvider<String?>((ref) => null);

/// Constellation view that displays spaces in a flowing, dynamic layout
class SpacesConstellationView extends ConsumerStatefulWidget {
  final List<Space> spaces;
  final Function(Space space) onSpaceTap;
  final ScrollController? scrollController;

  const SpacesConstellationView({
    Key? key,
    required this.spaces,
    required this.onSpaceTap,
    this.scrollController,
  }) : super(key: key);

  @override
  ConsumerState<SpacesConstellationView> createState() => _SpacesConstellationViewState();
}

class _SpacesConstellationViewState extends ConsumerState<SpacesConstellationView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Offset> _offsets = [];
  final math.Random _random = math.Random();
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    )..repeat(reverse: true);
    
    // Create random offsets for a slightly dynamic layout
    _generateOffsets();
  }
  
  @override
  void didUpdateWidget(SpacesConstellationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.spaces.length != oldWidget.spaces.length) {
      _generateOffsets();
    }
  }
  
  void _generateOffsets() {
    _offsets.clear();
    for (int i = 0; i < widget.spaces.length; i++) {
      _offsets.add(Offset(
        _random.nextDouble() * 0.2 - 0.1, // X offset between -0.1 and 0.1
        _random.nextDouble() * 0.2 - 0.1, // Y offset between -0.1 and 0.1
      ));
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final highlightedSpaceId = ref.watch(constellationHighlightProvider);
    
    if (widget.spaces.isEmpty) {
      return const Center(
        child: Text(
          'No spaces found',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    
    return Stack(
      children: [
        // Background connection lines
        CustomPaint(
          size: Size.infinite,
          painter: _ConstellationLinePainter(
            spaces: widget.spaces,
            highlightedId: highlightedSpaceId,
            animation: _controller,
          ),
        ),
        
        // Spaces grid with flow layout
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double totalWidth = constraints.maxWidth;
              const int columnsSmall = 2;
              const int columnsLarge = 3;
              final int columns = totalWidth > 400 ? columnsLarge : columnsSmall;
              final double spaceWidth = (totalWidth - (16.0 * columns)) / columns;
              
              return SingleChildScrollView(
                controller: widget.scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 100), // Extra padding for bottom nav bar
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: List.generate(widget.spaces.length, (index) {
                    final space = widget.spaces[index];
                    // Calculate position based on index and offset
                    final int row = index ~/ columns;
                    final int col = index % columns;
                    final double xPos = (col * (spaceWidth + 16)) + (_offsets[index].dx * spaceWidth);
                    final double yPos = (row * (spaceWidth + 16)) + (_offsets[index].dy * spaceWidth);
                    final bool isHighlighted = space.id == highlightedSpaceId;
                    
                    return AnimatedPositioned(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      left: xPos,
                      top: yPos,
                      width: spaceWidth,
                      height: spaceWidth * 1.2,
                      child: _ConstellationSpaceCard(
                        space: space,
                        isHighlighted: isHighlighted,
                        onTap: () => widget.onSpaceTap(space),
                        onHover: (hovering) {
                          if (hovering) {
                            ref.read(constellationHighlightProvider.notifier).state = space.id;
                          } else if (ref.read(constellationHighlightProvider) == space.id) {
                            ref.read(constellationHighlightProvider.notifier).state = null;
                          }
                        },
                      ),
                    );
                  }),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Custom painter to draw constellation connection lines
class _ConstellationLinePainter extends CustomPainter {
  final List<Space> spaces;
  final String? highlightedId;
  final Animation<double> animation;
  final ConnectionType connectionType;
  
  _ConstellationLinePainter({
    required this.spaces,
    this.highlightedId,
    required this.animation,
    this.connectionType = ConnectionType.clustered,
  }) : super(repaint: animation);
  
  @override
  void paint(Canvas canvas, Size size) {
    if (spaces.length < 2) return;
    
    // Draw connections based on type
    switch (connectionType) {
      case ConnectionType.clustered:
        _drawClusteredConnections(canvas, size);
        break;
      case ConnectionType.all:
        _drawAllConnections(canvas, size);
        break;
      case ConnectionType.nearest:
        _drawNearestConnections(canvas, size);
        break;
    }
  }
  
  void _drawClusteredConnections(Canvas canvas, Size size) {
    // Group spaces by category/type
    final Map<String, List<int>> clusters = {};
    
    for (int i = 0; i < spaces.length; i++) {
      final space = spaces[i];
      final key = space.spaceType.toString();
      if (!clusters.containsKey(key)) {
        clusters[key] = [];
      }
      clusters[key]!.add(i);
    }
    
    // Draw connections within each cluster
    clusters.forEach((_, indices) {
      for (int i = 0; i < indices.length; i++) {
        for (int j = i + 1; j < indices.length; j++) {
          _drawConnection(canvas, size, indices[i], indices[j]);
        }
      }
    });
  }
  
  void _drawAllConnections(Canvas canvas, Size size) {
    for (int i = 0; i < spaces.length; i++) {
      for (int j = i + 1; j < spaces.length; j++) {
        _drawConnection(canvas, size, i, j);
      }
    }
  }
  
  void _drawNearestConnections(Canvas canvas, Size size) {
    for (int i = 0; i < spaces.length; i++) {
      int nearest = -1;
      double minDist = double.infinity;
      
      for (int j = 0; j < spaces.length; j++) {
        if (i == j) continue;
        
        final dist = _calculateDistance(i, j, size);
        if (dist < minDist) {
          minDist = dist;
          nearest = j;
        }
      }
      
      if (nearest >= 0) {
        _drawConnection(canvas, size, i, nearest);
      }
    }
  }
  
  double _calculateDistance(int i, int j, Size size) {
    final p1 = _getPositionForIndex(i, size);
    final p2 = _getPositionForIndex(j, size);
    return (p1 - p2).distance;
  }
  
  void _drawConnection(Canvas canvas, Size size, int i, int j) {
    final p1 = _getPositionForIndex(i, size);
    final p2 = _getPositionForIndex(j, size);
    
    bool isHighlighted = false;
    if (highlightedId != null) {
      isHighlighted = spaces[i].id == highlightedId || spaces[j].id == highlightedId;
    }
    
    final paint = Paint()
      ..color = isHighlighted 
          ? AppColors.gold.withOpacity(0.3 * animation.value)
          : Colors.white.withOpacity(0.1 * animation.value)
      ..strokeWidth = isHighlighted ? 2.0 : 1.0
      ..style = PaintingStyle.stroke;
    
    canvas.drawLine(p1, p2, paint);
    
    // Draw animated dot traveling along the line
    if (isHighlighted) {
      final progress = (animation.value - 0.5).abs() * 2; // 0-1 range
      final Offset lerpPosition = Offset.lerp(p1, p2, progress) ?? p1;
      
      final dotPaint = Paint()
        ..color = AppColors.gold
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(lerpPosition, 3, dotPaint);
    }
  }
  
  Offset _getPositionForIndex(int index, Size size) {
    // This is a simple placement algorithm - in real implementation, 
    // we would need the actual card positions from the parent widget
    final int cols = size.width > 400 ? 3 : 2;
    final double itemWidth = size.width / cols;
    final double itemHeight = itemWidth * 1.2;
    
    final int row = index ~/ cols;
    final int col = index % cols;
    
    return Offset(
      (col + 0.5) * itemWidth, 
      (row + 0.5) * itemHeight
    );
  }
  
  @override
  bool shouldRepaint(_ConstellationLinePainter oldDelegate) {
    return oldDelegate.highlightedId != highlightedId ||
           oldDelegate.spaces != spaces;
  }
}

/// Space card for the constellation view
class _ConstellationSpaceCard extends StatefulWidget {
  final Space space;
  final bool isHighlighted;
  final VoidCallback onTap;
  final Function(bool) onHover;

  const _ConstellationSpaceCard({
    Key? key,
    required this.space,
    required this.isHighlighted,
    required this.onTap,
    required this.onHover,
  }) : super(key: key);

  @override
  State<_ConstellationSpaceCard> createState() => _ConstellationSpaceCardState();
}

class _ConstellationSpaceCardState extends State<_ConstellationSpaceCard> with SingleTickerProviderStateMixin {
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
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
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
    final isMember = widget.space.isJoined;
    
    // Define colors based on state
    final Color glowColor = widget.isHighlighted
        ? AppColors.gold
        : isMember
            ? AppColors.gold.withOpacity(0.3)
            : Colors.white.withOpacity(0.1);
    
    return MouseRegion(
      onEnter: (_) => widget.onHover(true),
      onExit: (_) => widget.onHover(false),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return AnimatedScale(
              scale: widget.isHighlighted 
                  ? 1.07 * _scaleAnimation.value
                  : 1.0 * _scaleAnimation.value,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: glowColor.withOpacity(0.2 * _glowAnimation.value),
                      blurRadius: widget.isHighlighted ? 15 : 8,
                      spreadRadius: widget.isHighlighted ? 3 : 1,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      // Background image or gradient
                      hasImage
                          ? Image.network(
                              widget.space.imageUrl!,
                              width: double.infinity,
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
                      
                      // Glassmorphism overlay
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
                                  color: widget.isHighlighted
                                      ? AppColors.gold.withOpacity(0.3)
                                      : Colors.white.withOpacity(0.1),
                                  width: widget.isHighlighted ? 1.5 : 1.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Space icon or first letter
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[800]!.withOpacity(0.5),
                                border: Border.all(
                                  color: widget.isHighlighted
                                      ? AppColors.gold.withOpacity(0.4)
                                      : Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: widget.space.icon != null
                                  ? Icon(
                                      widget.space.icon,
                                      color: widget.isHighlighted
                                          ? AppColors.gold
                                          : Colors.white,
                                      size: 20,
                                    )
                                  : Center(
                                      child: Text(
                                        widget.space.name.isNotEmpty
                                            ? widget.space.name[0].toUpperCase()
                                            : '?',
                                        style: GoogleFonts.inter(
                                          color: widget.isHighlighted
                                              ? AppColors.gold
                                              : Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Space name
                            Text(
                              widget.space.name,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            
                            // Space membership indicator
                            if (isMember)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.gold.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'Member',
                                  style: GoogleFonts.inter(
                                    color: AppColors.gold,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
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
            );
          },
        ),
      ),
    );
  }
}

/// Type of connections to draw between spaces
enum ConnectionType {
  clustered, // Connect spaces of same type/category
  all,       // Connect all spaces
  nearest    // Connect each space to its nearest neighbor
} 