import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/presentation/controllers/spaces_controller.dart';
import 'package:hive_ui/models/space.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/services/analytics_service.dart';

/// A unified card to display spaces, compatible with both Space and SpaceEntity models
class UnifiedSpaceCard extends ConsumerWidget {
  /// The legacy Space model from older code
  final Space? legacySpace;
  
  /// The new SpaceEntity model from the refactored architecture
  final SpaceEntity? spaceEntity;
  
  /// Callback when the space card is tapped
  final VoidCallback? onTap;
  
  /// Whether to show the join button
  final bool showJoinButton;

  const UnifiedSpaceCard({
    Key? key,
    this.legacySpace,
    this.spaceEntity,
    this.onTap,
    this.showJoinButton = true,
  }) : assert(legacySpace != null || spaceEntity != null, 'Either legacySpace or spaceEntity must be provided'),
       super(key: key);
  
  /// Factory constructor to create from legacy Space model
  factory UnifiedSpaceCard.fromLegacySpace(
    Space space, {
    Key? key,
    VoidCallback? onTap,
    bool showJoinButton = true,
  }) {
    return UnifiedSpaceCard(
      key: key,
      legacySpace: space,
      onTap: onTap,
      showJoinButton: showJoinButton,
    );
  }
  
  /// Factory constructor to create from SpaceEntity
  factory UnifiedSpaceCard.fromSpaceEntity(
    SpaceEntity entity, {
    Key? key,
    VoidCallback? onTap,
    bool showJoinButton = true,
  }) {
    return UnifiedSpaceCard(
      key: key,
      spaceEntity: entity,
      onTap: onTap,
      showJoinButton: showJoinButton,
    );
  }
  
  /// Helper to get the space ID
  String get id => spaceEntity?.id ?? legacySpace!.id;
  
  /// Helper to get the space name
  String get name => spaceEntity?.name ?? legacySpace!.name;
  
  /// Helper to get the space description
  String get description => spaceEntity?.description ?? legacySpace!.description;
  
  /// Helper to get the space image URL
  String? get imageUrl => spaceEntity?.imageUrl ?? legacySpace!.imageUrl;
  
  /// Helper to get whether the space is joined
  bool get isJoined => spaceEntity?.isJoined ?? legacySpace!.isJoined;
  
  /// Helper to get the member count
  int get memberCount => spaceEntity?.metrics.memberCount ?? legacySpace!.metrics.memberCount;
  
  /// Helper to get the weekly events count
  int get weeklyEvents => spaceEntity?.metrics.weeklyEvents ?? legacySpace!.metrics.weeklyEvents;
  
  /// Helper to get the space type
  String get spaceType {
    if (spaceEntity != null) {
      return spaceEntity!.spaceType.toString().split('.').last;
    } else {
      return legacySpace!.spaceType.toString().split('.').last;
    }
  }
  
  /// Helper to get the space primary color
  Color get primaryColor {
    if (spaceEntity != null) {
      return spaceEntity!.primaryColor;
    } else {
      // Generate a color based on the name
      final hash = legacySpace!.name.hashCode.abs();
      final hue = (hash % 360).toDouble();
      return HSLColor.fromAHSL(1.0, hue, 0.6, 0.4).toColor();
    }
  }
  
  /// Helper to get the space icon
  IconData get icon {
    if (spaceEntity != null) {
      return spaceEntity!.icon;
    } else {
      // Default icon for legacy spaces
      return Icons.group;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          HapticFeedback.lightImpact();
          onTap!();
        } else {
          _handleDefaultTap(context);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
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
                      color: primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        color: primaryColor,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
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
                ],
              ),

              const SizedBox(height: 8),

              // Space description
              Text(
                description,
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.7),
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
                    '$memberCount',
                    'Members',
                  ),
                  const SizedBox(width: 16),
                  _buildMetricItem(
                    Icons.calendar_today_outlined,
                    '$weeklyEvents',
                    'Weekly Events',
                  ),
                ],
              ),

              // Join button
              if (showJoinButton && !isJoined)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: TextButton(
                    onPressed: () => _handleJoinSpace(context, ref),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.gold,
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ).copyWith(
                      overlayColor: MaterialStateProperty.resolveWith<Color?>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.pressed)) {
                            return AppColors.gold.withOpacity(0.15);
                          }
                          return null;
                        },
                      ),
                    ),
                    child: Text(
                      'Join Space',
                      style: GoogleFonts.inter(
                        color: AppColors.gold,
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
      ),
    );
  }

  Widget _buildMetricItem(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.white.withOpacity(0.4),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.4),
            fontSize: 12,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
  
  /// Handle the default tap action for spaces
  void _handleDefaultTap(BuildContext context) {
    HapticFeedback.selectionClick();
    
    try {
      // Navigate to space detail
      final clubId = Uri.encodeComponent(id);
      
      // Log analytics
      AnalyticsService.logEvent(
        'view_space',
        parameters: {
          'space_id': id,
          'space_name': name,
          'space_type': spaceType,
          'source': 'profile_spaces_list',
        },
      );
      
      // Use a safer navigation method
      try {
        // Try to navigate using standard Navigator first
        Navigator.of(context).pushNamed(
          '/spaces/club',
          arguments: {'id': clubId, 'type': spaceType},
        );
      } catch (navError) {
        debugPrint('Primary navigation failed, trying fallback: $navError');
        
        // Fallback to context router if available
        if (context.mounted) {
          context.go('/spaces/club/$clubId');
        }
      }
    } catch (e) {
      debugPrint('Error navigating to space: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error opening space'),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
  
  /// Handle joining a space
  void _handleJoinSpace(BuildContext context, WidgetRef ref) {
    HapticFeedback.mediumImpact();
    
    try {
      if (spaceEntity != null) {
        // Use the spaces controller for SpaceEntity
        final controller = ref.read(spacesControllerProvider.notifier);
        controller.joinSpace(id);
      } else if (legacySpace != null) {
        // Handle joining for legacy Space model via its providers or services
        // This will depend on your implementation of the legacy space joining functionality
        final spacesController = ref.read(spacesControllerProvider.notifier);
        spacesController.joinSpace(id);
      }
    } catch (e) {
      debugPrint('Error joining space: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error joining space: ${e.toString()}'),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
} 