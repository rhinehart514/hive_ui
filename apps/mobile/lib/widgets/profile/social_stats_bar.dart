import 'package:flutter/material.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/widgets/profile/profile_card.dart';

/// A widget that displays social stats (spaces, events, friends) in a horizontal bar
class SocialStatsBar extends StatelessWidget {
  /// The user profile containing the stats to display
  final UserProfile profile;

  /// Optional padding for the bar
  final EdgeInsetsGeometry padding;

  /// Optional margin for the card
  final EdgeInsetsGeometry margin;

  /// Constructor
  const SocialStatsBar({
    super.key,
    required this.profile,
    this.padding = const EdgeInsets.symmetric(vertical: 12),
    this.margin = const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  });

  @override
  Widget build(BuildContext context) {
    return ProfileCard(
      type: ProfileCardType.social,
      padding: padding,
      margin: margin,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            label: 'Spaces',
            value: profile.spaceCount.toString(),
            icon: Icons.group,
          ),
          _buildVerticalDivider(),
          _buildStatItem(
            label: 'Events',
            value: profile.eventCount.toString(),
            icon: Icons.event,
          ),
          _buildVerticalDivider(),
          _buildStatItem(
            label: 'Friends',
            value: profile.friendCount.toString(),
            icon: Icons.person,
          ),
        ],
      ),
    );
  }

  /// Builds a single stat item with an icon, value, and label
  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.gold,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// Builds a vertical divider between stat items
  Widget _buildVerticalDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.grey.withOpacity(0.3),
    );
  }
}
