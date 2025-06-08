import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/models/space.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/space_join_button.dart';

/// A widget that visualizes the space join process with animations
class SpaceJoinVisualization extends ConsumerStatefulWidget {
  /// The space to visualize joining
  final Space space;
  
  /// Whether to show in expanded mode
  final bool isExpanded;
  
  /// Callback when close button is pressed
  final VoidCallback? onClose;
  
  /// Custom content to show below the visualization
  final Widget? additionalContent;

  const SpaceJoinVisualization({
    super.key,
    required this.space,
    this.isExpanded = false,
    this.onClose,
    this.additionalContent,
  });

  @override
  ConsumerState<SpaceJoinVisualization> createState() => _SpaceJoinVisualizationState();
}

class _SpaceJoinVisualizationState extends ConsumerState<SpaceJoinVisualization> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;
  
  bool _hasJoined = false;

  @override
  void initState() {
    super.initState();
    _hasJoined = widget.space.isJoined;
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );
    
    // Start the animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground.withOpacity(0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _hasJoined 
                    ? AppColors.gold.withOpacity(0.5) 
                    : Colors.white.withOpacity(0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with space name and close button
                  Row(
                    children: [
                      if (widget.space.imageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            widget.space.imageUrl!,
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 32,
                              height: 32,
                              color: Colors.grey[800],
                              child: const Icon(Icons.image_not_supported, size: 16, color: Colors.white70),
                            ),
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.space.name,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.onClose != null)
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: widget.onClose,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Main content - different based on joined status
                  _hasJoined
                    ? _buildJoinedState()
                    : _buildPreJoinState(),
                  
                  if (widget.additionalContent != null) ...[
                    const SizedBox(height: 16),
                    widget.additionalContent!,
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds the UI shown when the user has already joined the space
  Widget _buildJoinedState() {
    return Column(
      children: [
        // Success animation
        SizedBox(
          height: 100,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Animated circles
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.gold.withOpacity(0.5),
                        AppColors.gold.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
                
                // Check icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gold.withOpacity(0.2),
                    border: Border.all(color: AppColors.gold, width: 2),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: AppColors.gold,
                    size: 36,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Success text
        Text(
          'You\'re In!',
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'You\'ve joined ${widget.space.name}',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 16),
        
        // Leave button option
        SpaceJoinButton(
          space: widget.space,
          size: SpaceJoinButtonSize.medium,
          onLeft: () {
            setState(() {
              _hasJoined = false;
            });
          },
        ),
      ],
    );
  }

  /// Builds the UI shown before the user joins the space
  Widget _buildPreJoinState() {
    return Column(
      children: [
        // Space image or placeholder
        if (widget.space.bannerUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              widget.space.bannerUrl!,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 120,
                width: double.infinity,
                color: Colors.grey[850],
                child: const Icon(Icons.image, size: 48, color: Colors.white30),
              ),
            ),
          )
        else
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                widget.space.icon ?? Icons.group,
                size: 48,
                color: Colors.white30,
              ),
            ),
          ),
        
        const SizedBox(height: 16),
        
        // Space description
        if (widget.space.description.isNotEmpty)
          Text(
            widget.space.description,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
            maxLines: widget.isExpanded ? 5 : 2,
            overflow: TextOverflow.ellipsis,
          ),
        
        const SizedBox(height: 24),
        
        // Join button
        SpaceJoinButton(
          space: widget.space,
          size: SpaceJoinButtonSize.large,
          onJoined: () {
            setState(() {
              _hasJoined = true;
            });
          },
        ),
      ],
    );
  }
} 