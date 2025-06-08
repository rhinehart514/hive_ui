import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/presentation/providers/spaces_repository_provider.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// Widget to control and display space visibility status
class SpaceVisibilityControl extends ConsumerStatefulWidget {
  /// The space entity to control visibility for
  final SpaceEntity space;
  
  /// Whether the current user has permission to change visibility
  final bool canModify;
  
  /// Callback when visibility is changed
  final Function(bool isPrivate)? onVisibilityChanged;

  /// Constructor
  const SpaceVisibilityControl({
    Key? key,
    required this.space,
    this.canModify = false,
    this.onVisibilityChanged,
  }) : super(key: key);

  @override
  ConsumerState<SpaceVisibilityControl> createState() => _SpaceVisibilityControlState();
}

class _SpaceVisibilityControlState extends ConsumerState<SpaceVisibilityControl> {
  late bool _isPrivate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isPrivate = widget.space.isPrivate;
  }

  @override
  void didUpdateWidget(SpaceVisibilityControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update local state if the space visibility changes externally
    if (oldWidget.space.isPrivate != widget.space.isPrivate && !_isLoading) {
      _isPrivate = widget.space.isPrivate;
    }
  }

  Future<void> _toggleVisibility() async {
    if (!widget.canModify) return;

    // Apply haptic feedback
    HapticFeedback.mediumImpact();

    // Store previous state for rollback if needed
    final previousState = _isPrivate;
    
    try {
      // Mark as loading to prevent state conflicts
      setState(() {
        _isLoading = true;
        _isPrivate = !_isPrivate; // Optimistically update UI
      });
      
      // Perform actual backend operation
      final repository = ref.read(spaceRepositoryProvider);
      final updatedSpace = widget.space.copyWith(isPrivate: _isPrivate);
      await repository.updateSpace(updatedSpace);
      
      // Call the callback if provided
      if (widget.onVisibilityChanged != null) {
        widget.onVisibilityChanged!(_isPrivate);
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      // Handle errors and revert optimistic update
      if (mounted) {
        setState(() {
          _isPrivate = previousState;
          _isLoading = false;
        });
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating visibility: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibilityText = _isPrivate ? 'Private' : 'Public';
    final visibilityIcon = _isPrivate ? Icons.lock_outline : Icons.public;
    final visibilityColor = _isPrivate ? Colors.blue : Colors.green;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Space Visibility',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isPrivate
                ? 'Only members can see content and activities'
                : 'Anyone can see content and activities',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: visibilityColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(visibilityIcon, color: visibilityColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    visibilityText,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              if (widget.canModify)
                _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                        ),
                      )
                    : TextButton(
                        onPressed: _toggleVisibility,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.gold,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: Text(
                          'Change',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
            ],
          ),
        ],
      ),
    );
  }
} 