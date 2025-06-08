import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/providers/activity_provider.dart';
import 'package:hive_ui/widgets/profile/activity_item.dart';
import 'package:hive_ui/widgets/profile/activity_stats_card.dart';

/// Widget that displays the activity feed tab on the profile page
class ActivityFeedTab extends ConsumerWidget {
  /// The user profile whose activity is being displayed
  final UserProfile profile;

  /// Optional user ID - if null, shows the current user's activity
  final String? userId;

  /// Constructor
  const ActivityFeedTab({
    super.key,
    required this.profile,
    this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String userIdToUse = userId ?? profile.id;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Consumer(
        builder: (context, ref, child) {
          final activityAsync = ref.watch(userActivityProvider(userIdToUse));

          return activityAsync.when(
            data: (activities) {
              if (activities.isEmpty) {
                return _buildEmptyState(context);
              }

              return ListView(
                padding: const EdgeInsets.only(top: 16),
                physics: const BouncingScrollPhysics(),
                children: [
                  // Activity stats card at the top
                  ActivityStatsCard(profile: profile),
                  const SizedBox(height: 24),
                  
                  // Activity feed items
                  ...activities.map((activity) => ActivityItem(
                    key: ValueKey('activity-${activity.id}'),
                    activity: activity,
                  )).toList(),
                ],
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
            error: (error, stackTrace) => Center(
              child: Text(
                'Failed to load activity feed',
                style: GoogleFonts.outfit(
                  color: Colors.red[300],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build the empty state when there's no activity
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Show stats card even when there's no activity
          ActivityStatsCard(profile: profile),
          const SizedBox(height: 48),
          
          Icon(
            Icons.hourglass_empty,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'No Activity Yet',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Activities will appear here when ${userId == null ? 'you' : profile.username} joins clubs, attends events, or connects with friends.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}
