import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/presentation/controllers/spaces_controller.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A reusable card to display a space
class SpaceCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(spacesControllerProvider.notifier);
    final theme = Theme.of(context);
    
    // Check if this space was created by the current user
    final bool isCreatedByUser = space.customData['isCreatedByUser'] == true;

    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          HapticFeedback.lightImpact();
          onTap!();
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
                              : space.primaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(
                            space.icon,
                            color: isCreatedByUser ? AppColors.gold : space.primaryColor,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          space.name,
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
                    space.description,
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
                        '${space.metrics.memberCount}',
                        'Members',
                      ),
                      const SizedBox(width: 16),
                      _buildMetricItem(
                        Icons.calendar_today_outlined,
                        '${space.metrics.weeklyEvents}',
                        'Weekly Events',
                      ),
                    ],
                  ),

                  // Join button
                  if (showJoinButton && !space.isJoined)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: TextButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          controller.joinSpace(space.id);
                        },
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
                        child: Text(
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
