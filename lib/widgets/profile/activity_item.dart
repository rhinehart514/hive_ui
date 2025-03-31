import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/models/activity.dart';
import 'package:hive_ui/widgets/profile/profile_card.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// Widget that displays a single activity item in the profile page
class ActivityItem extends StatelessWidget {
  /// The activity data to display
  final Activity activity;

  /// Constructor
  const ActivityItem({
    super.key,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'activity-${activity.id}',
      child: Material(
        color: Colors.transparent,
        child: ProfileCard(
          type: ProfileCardType.activity,
          padding: EdgeInsets.zero,
          addGoldAccent: _shouldAddGoldAccent(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Activity icon with refined styling
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getIconColor(),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _getIconColor().withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: Icon(
                    activity.iconData,
                    color: _getIconColor(),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),

                // Activity details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activity.subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.7),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                // Timestamp with more refined styling
                Text(
                  activity.timeAgo,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Check if we should add a gold accent to this activity
  bool _shouldAddGoldAccent() {
    return activity.type == ActivityType.achievement;
  }

  /// Get the appropriate icon color based on activity type
  /// Uses gold for important activities, white for others
  Color _getIconColor() {
    // If the activity is a join, friendship, or achievement, use gold
    if (activity.type == ActivityType.joinedClub ||
        activity.type == ActivityType.newFriend ||
        activity.type == ActivityType.achievement) {
      return AppColors.gold;
    }

    // Otherwise use white with opacity
    return Colors.white.withOpacity(0.8);
  }
}
