import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// Widget to display the type of space (pre-seeded vs. user-created)
class SpaceTypeIndicator extends StatelessWidget {
  /// The space entity to display type for
  final SpaceEntity space;
  
  /// Whether to show full details
  final bool showDetails;
  
  /// Constructor
  const SpaceTypeIndicator({
    Key? key,
    required this.space,
    this.showDetails = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final bool isPreSeeded = space.isPreSeeded;
    final bool isHiveExclusive = space.hiveExclusive;
    
    // Determine badge color and text
    Color badgeColor;
    String badgeText;
    IconData badgeIcon;
    
    if (isHiveExclusive) {
      badgeColor = AppColors.gold;
      badgeText = 'HIVE Exclusive';
      badgeIcon = Icons.verified;
    } else if (isPreSeeded) {
      switch (space.spaceType) {
        case SpaceType.studentOrg:
          badgeColor = Colors.purple;
          badgeText = 'Student Org';
          badgeIcon = Icons.school;
          break;
        case SpaceType.universityOrg:
          badgeColor = Colors.blue;
          badgeText = 'University Org';
          badgeIcon = Icons.account_balance;
          break;
        case SpaceType.campusLiving:
          badgeColor = Colors.green;
          badgeText = 'Campus Living';
          badgeIcon = Icons.home;
          break;
        case SpaceType.fraternityAndSorority:
          badgeColor = Colors.pink;
          badgeText = 'Greek Life';
          badgeIcon = Icons.group;
          break;
        default:
          badgeColor = Colors.orange;
          badgeText = 'Pre-seeded';
          badgeIcon = Icons.star;
      }
    } else {
      badgeColor = Colors.teal;
      badgeText = 'Community Created';
      badgeIcon = Icons.people;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: badgeColor.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeIcon,
            size: 14,
            color: badgeColor,
          ),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: badgeColor,
            ),
          ),
          if (showDetails && isPreSeeded) ...[
            const SizedBox(width: 4),
            Tooltip(
              message: 'This is an official space from your institution',
              child: Icon(
                Icons.info_outline,
                size: 12,
                color: badgeColor.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
} 