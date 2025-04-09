import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/providers/activity_provider.dart';
import 'package:hive_ui/models/activity.dart';
import 'package:hive_ui/widgets/profile/profile_tab_bar.dart';

/// A card widget that displays user activity statistics
class ActivityStatsCard extends ConsumerWidget {
  /// The user profile to display stats for
  final UserProfile profile;

  const ActivityStatsCard({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(userActivityProvider(profile.id));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.gold.withOpacity(0.3),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: activityAsync.when(
        data: (activities) => _buildStatsContent(context, activities),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildErrorState(),
      ),
    );
  }

  Widget _buildStatsContent(BuildContext context, List<Activity> activities) {
    // Calculate activity metrics
    final totalActivities = activities.length;
    final recentActivities = activities.where(
      (a) => a.timestamp.isAfter(DateTime.now().subtract(const Duration(days: 30)))
    ).length;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Activity Overview',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Stats grid
          Row(
            children: [
              _buildStatItem(
                'Total Activities',
                totalActivities.toString(),
                Icons.timeline,
              ),
              _buildStatItem(
                'Recent (30d)',
                recentActivities.toString(),
                Icons.trending_up,
              ),
              _buildStatItem(
                'Engagement Score',
                UserProfileStats(profile).activityCount.toString(),
                Icons.star,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Activity breakdown
          _buildActivityBreakdown(activities),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.gold,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityBreakdown(List<Activity> activities) {
    // Count activities by type
    final typeCount = <ActivityType, int>{};
    for (final activity in activities) {
      typeCount[activity.type] = (typeCount[activity.type] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity Breakdown',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ...ActivityType.values.map((type) {
          final count = typeCount[type] ?? 0;
          return _buildActivityTypeRow(type, count, activities.length);
        }),
      ],
    );
  }

  Widget _buildActivityTypeRow(ActivityType type, int count, int total) {
    final percentage = total > 0 ? (count / total * 100).round() : 0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _getActivityTypeLabel(type),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                '$count ($percentage%)',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: count / (total > 0 ? total : 1),
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              _getActivityTypeColor(type),
            ),
          ),
        ],
      ),
    );
  }

  String _getActivityTypeLabel(ActivityType type) {
    switch (type) {
      case ActivityType.joinedClub:
        return 'Joined Spaces';
      case ActivityType.attendedEvent:
        return 'Events Attended';
      case ActivityType.achievement:
        return 'Achievements';
      case ActivityType.newFriend:
        return 'New Connections';
      case ActivityType.postCreated:
        return 'Posts Created';
    }
  }

  Color _getActivityTypeColor(ActivityType type) {
    switch (type) {
      case ActivityType.joinedClub:
        return AppColors.gold;
      case ActivityType.attendedEvent:
        return Colors.purple;
      case ActivityType.achievement:
        return Colors.amber;
      case ActivityType.newFriend:
        return Colors.blue;
      case ActivityType.postCreated:
        return Colors.green;
    }
  }

  Widget _buildErrorState() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: Text(
          'Unable to load activity statistics',
          style: TextStyle(color: Colors.white60),
        ),
      ),
    );
  }
} 