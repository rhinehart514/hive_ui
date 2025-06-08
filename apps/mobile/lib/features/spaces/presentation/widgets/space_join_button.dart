import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/models/space.dart';
import 'package:hive_ui/features/spaces/presentation/providers/spaces_controller.dart';
import 'package:hive_ui/features/profile/data/repositories/trail_repository.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/core/events/app_event_bus.dart';

/// Enhanced join button for spaces with visual feedback
class SpaceJoinButton extends ConsumerStatefulWidget {
  /// The space to join/leave
  final Space space;
  
  /// Size of the button
  final SpaceJoinButtonSize size;
  
  /// Optional callback for after successful join
  final VoidCallback? onJoined;
  
  /// Optional callback for after successful leave
  final VoidCallback? onLeft;

  const SpaceJoinButton({
    super.key,
    required this.space,
    this.size = SpaceJoinButtonSize.medium,
    this.onJoined,
    this.onLeft,
  });

  @override
  ConsumerState<SpaceJoinButton> createState() => _SpaceJoinButtonState();
}

/// Size variants for the join button
enum SpaceJoinButtonSize {
  small,
  medium,
  large
}

class _SpaceJoinButtonState extends ConsumerState<SpaceJoinButton> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _showSuccessAnimation = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animation controller for join animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    // Scale animation for button press effect
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );
    
    // Pulse animation for success feedback
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.25), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 1.25, end: 1.0), weight: 1),
    ]).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
      ),
    );
    
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Reset animation state after completion
        setState(() {
          _showSuccessAnimation = false;
        });
        _animationController.reset();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isJoined = widget.space.isJoined;
    
    // Button dimensions based on size
    final double height = _getButtonHeight();
    final double fontSize = _getButtonFontSize();
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _showSuccessAnimation ? _pulseAnimation.value : _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) {
              if (!_isLoading) {
                _animationController.forward(from: 0.0);
              }
            },
            onTapCancel: () {
              if (!_isLoading && !_showSuccessAnimation) {
                _animationController.reverse();
              }
            },
            onTap: () => _handleJoinTap(isJoined),
            child: Container(
              height: height,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: isJoined
                  ? null
                  : LinearGradient(
                      colors: [
                        AppColors.gold.withOpacity(0.95),
                        AppColors.gold.withOpacity(0.85),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                color: isJoined ? Colors.transparent : null,
                borderRadius: BorderRadius.circular(height / 2),
                border: Border.all(
                  color: isJoined 
                    ? AppColors.gold.withOpacity(0.5) 
                    : AppColors.gold.withOpacity(0.8),
                  width: 1.5,
                ),
              ),
              child: _isLoading
                ? _buildLoadingIndicator(isJoined)
                : _showSuccessAnimation
                  ? _buildSuccessIndicator(isJoined)
                  : Center(
                      child: Text(
                        isJoined ? 'Joined' : 'Join',
                        style: GoogleFonts.outfit(
                          color: isJoined ? AppColors.gold : Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: fontSize,
                        ),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
  
  /// Handle join/leave button tap
  Future<void> _handleJoinTap(bool isJoined) async {
    if (_isLoading || _showSuccessAnimation) return;
    
    // Provide haptic feedback
    HapticFeedback.mediumImpact();
    
    setState(() {
      _isLoading = true;
    });

    try {
      final spacesController = ref.read(spacesControllerProvider.notifier);
      
      if (isJoined) {
        // Leave space
        await spacesController.leaveSpace(widget.space);
        
        // Notify other tabs via event bus
        appEventBus.fireSpaceLeft(
          widget.space.id,
          widget.space.name,
          source: 'space_join_button',
        );
        
        if (widget.onLeft != null) {
          widget.onLeft!();
        }
      } else {
        // Join space
        await spacesController.joinSpace(widget.space);
        
        // Record the join in the user's trail
        final trailRepository = ref.read(trailRepositoryProvider);
        await trailRepository.recordSpaceJoin(
          widget.space.id,
          widget.space.name,
          widget.space.imageUrl,
        );
        
        // Notify other tabs via event bus
        appEventBus.fireSpaceJoined(
          widget.space.id,
          widget.space.name,
          source: 'space_join_button',
        );
        
        // Fire trail updated event
        appEventBus.fireTrailUpdated(source: 'space_join_button');
        
        // Refresh feeds to show new content
        appEventBus.fireRefreshFeed(source: 'space_join_button');
        
        // Show success animation
        setState(() {
          _showSuccessAnimation = true;
        });
        
        if (widget.onJoined != null) {
          widget.onJoined!();
        }
      }
    } catch (e) {
      debugPrint('Error joining/leaving space: $e');
      // Show error toast or snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to ${isJoined ? 'leave' : 'join'} space: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  /// Build loading indicator
  Widget _buildLoadingIndicator(bool isJoined) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          isJoined ? AppColors.gold : Colors.black,
        ),
      ),
    );
  }
  
  /// Build success indicator
  Widget _buildSuccessIndicator(bool isJoined) {
    return Icon(
      Icons.check_circle,
      color: isJoined ? AppColors.gold : Colors.black,
      size: 20,
    );
  }
  
  /// Get button height based on size
  double _getButtonHeight() {
    switch (widget.size) {
      case SpaceJoinButtonSize.small:
        return 32;
      case SpaceJoinButtonSize.medium:
        return 40;
      case SpaceJoinButtonSize.large:
        return 48;
    }
  }
  
  /// Get font size based on button size
  double _getButtonFontSize() {
    switch (widget.size) {
      case SpaceJoinButtonSize.small:
        return 14;
      case SpaceJoinButtonSize.medium:
        return 16;
      case SpaceJoinButtonSize.large:
        return 18;
    }
  }
}

/// Provider for the spaces controller
final spacesControllerProvider = StateNotifierProvider<SpacesController, SpacesPageState>((ref) {
  return SpacesController(ref);
}); 