import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/presentation/controllers/spaces_controller.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_ui/core/event_bus/app_event_bus.dart';

/// A reusable card to display a space
class SpaceCard extends ConsumerStatefulWidget {
  final SpaceEntity space;
  final VoidCallback? onTap;
  final bool showJoinButton;

  const SpaceCard({
    Key? key,
    required this.space,
    this.onTap,
    this.showJoinButton = true,
  }) : super(key: key);

  @override
  ConsumerState<SpaceCard> createState() => _SpaceCardState();
}

class _SpaceCardState extends ConsumerState<SpaceCard> {
  // Track local join state for optimistic updates
  late bool _isJoined;
  bool _isJoining = false;
  
  @override
  void initState() {
    super.initState();
    _isJoined = widget.space.isJoined;
  }
  
  @override
  void didUpdateWidget(SpaceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update local state if the space join status changes externally
    if (oldWidget.space.isJoined != widget.space.isJoined && !_isJoining) {
      _isJoined = widget.space.isJoined;
    }
  }
  
  // Handle joining a space with optimistic updates
  Future<void> _handleJoinSpace() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    
    // Apply haptic feedback
    HapticFeedback.mediumImpact();
    
    // Store previous state for rollback if needed
    final previousState = _isJoined;
    
    try {
      // Mark as joining to prevent state conflicts
      setState(() {
        _isJoining = true;
        _isJoined = true; // Optimistically update UI
      });
      
      // Emit event for other listeners
      AppEventBus().emit(
        SpaceMembershipChangedEvent(
          spaceId: widget.space.id,
          userId: userId,
          isJoining: true,
        ),
      );
      
      // Perform actual backend operation
      final controller = ref.read(spacesControllerProvider.notifier);
      final success = await controller.joinSpace(widget.space.id);
      
      if (!success) {
        // If the operation failed, revert the optimistic update
        if (mounted) {
          setState(() {
            _isJoined = previousState;
            _isJoining = false;
          });
          
          // Emit corrective event
          AppEventBus().emit(
            SpaceMembershipChangedEvent(
              spaceId: widget.space.id,
              userId: userId,
              isJoining: false,
            ),
          );
          
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to join space. Please try again.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // Operation succeeded
        if (mounted) {
          setState(() {
            _isJoining = false;
          });
        }
      }
    } catch (e) {
      // Handle errors and revert optimistic update
      if (mounted) {
        setState(() {
          _isJoined = previousState;
          _isJoining = false;
        });
        
        // Emit corrective event
        AppEventBus().emit(
          SpaceMembershipChangedEvent(
            spaceId: widget.space.id,
            userId: userId,
            isJoining: false,
          ),
        );
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error joining space: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Check if this space was created by the current user
    final bool isCreatedByUser = widget.space.customData['isCreatedByUser'] == true;

    return GestureDetector(
      onTap: () {
        if (widget.onTap != null) {
          HapticFeedback.lightImpact();
          widget.onTap!();
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            // Use gold border for spaces created by the user
            color: isCreatedByUser
                ? AppColors.gold
                : Colors.white.withOpacity(0.1),
            width: isCreatedByUser ? 1.0 : 0.5,
          ),
          boxShadow: [
            // Add special gold glow for spaces created by the user
            if (isCreatedByUser)
              BoxShadow(
                color: AppColors.gold.withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Space name and icon
                  Row(
                    children: [
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: isCreatedByUser
                              ? AppColors.gold.withOpacity(0.15)
                              : widget.space.primaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(
                            widget.space.icon,
                            color: isCreatedByUser ? AppColors.gold : widget.space.primaryColor,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.space.name,
                          style: GoogleFonts.inter(
                            color: AppColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.25,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Add new button to view improved space detail
                      IconButton(
                        icon: const Icon(
                          Icons.open_in_new,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          // Navigate to our improved space detail view
                          GoRouter.of(context).push(
                            '/spaces/detail?id=${Uri.encodeComponent(widget.space.id)}&type=space',
                          );
                        },
                        tooltip: 'View improved space detail',
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Space description
                  Text(
                    widget.space.description,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 16),

                  // Space metrics
                  Row(
                    children: [
                      _buildMetricItem(
                        Icons.people_outline,
                        '${widget.space.metrics.memberCount}',
                        'Members',
                      ),
                      const SizedBox(width: 16),
                      _buildMetricItem(
                        Icons.calendar_today_outlined,
                        '${widget.space.metrics.weeklyEvents}',
                        'Weekly Events',
                      ),
                    ],
                  ),

                  // Join button
                  if (widget.showJoinButton && !_isJoined)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: TextButton(
                        onPressed: _isJoining ? null : _handleJoinSpace,
                        style: TextButton.styleFrom(
                          foregroundColor: isCreatedByUser ? AppColors.gold : AppColors.yellow,
                          minimumSize: const Size(0, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ).copyWith(
                          overlayColor: MaterialStateProperty.resolveWith<Color?>(
                            (Set<MaterialState> states) {
                              if (states.contains(MaterialState.pressed)) {
                                return (isCreatedByUser ? AppColors.gold : AppColors.yellow).withOpacity(0.15);
                              }
                              return null;
                            },
                          ),
                        ),
                        child: _isJoining
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                                ),
                              )
                            : Text(
                                'Join Space',
                                style: GoogleFonts.inter(
                                  color: isCreatedByUser ? AppColors.gold : AppColors.yellow,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.1,
                                ),
                              ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Creator badge
            if (isCreatedByUser)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.9),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: Text(
                    'CREATOR',
                    style: GoogleFonts.outfit(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(IconData icon, String value, String label) {
    return Row(
        children: [
          Icon(
            icon,
          size: 16,
          color: AppColors.textTertiary,
          ),
          const SizedBox(width: 4),
          Text(
          value,
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppColors.textTertiary,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.2,
            ),
          ),
        ],
    );
  }
}
