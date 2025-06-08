import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/widgets/profile/follow_button.dart';
import 'package:hive_ui/features/profile/domain/entities/recommended_user.dart';
import 'package:hive_ui/features/profile/presentation/providers/recommended_users_provider.dart';

/// A widget that displays recommended connections for the user
class ConnectionRecommendations extends ConsumerStatefulWidget {
  /// The current user's profile
  final UserProfile userProfile;

  /// Maximum number of recommendations to show
  final int limit;

  /// Constructor
  const ConnectionRecommendations({
    super.key,
    required this.userProfile,
    this.limit = 5,
  });

  @override
  ConsumerState<ConnectionRecommendations> createState() => _ConnectionRecommendationsState();
}

class _ConnectionRecommendationsState extends ConsumerState<ConnectionRecommendations> {
  @override
  Widget build(BuildContext context) {
    final recommendationsAsync = ref.watch(recommendedUsersProvider(widget.limit));

    return recommendationsAsync.when(
      data: (recommendations) {
        if (recommendations.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Recommended Connections',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recommendations.length,
              itemBuilder: (context, index) {
                final user = recommendations[index];
                return _buildRecommendationCard(user);
              },
            ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
        ),
      ),
      error: (error, stack) => Center(
        child: Text(
          'Error loading recommendations',
          style: GoogleFonts.inter(
            color: Colors.red[300],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'No Recommendations Yet',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll suggest connections as you use the app more',
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

  Widget _buildRecommendationCard(RecommendedUser user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.gold.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Profile Image
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.gold.withOpacity(0.1),
            backgroundImage: user.profileImage != null
                ? NetworkImage(user.profileImage!)
                : null,
            child: user.profileImage == null
                ? Text(
                    user.name[0].toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _buildRecommendationReason(user),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Follow Button
          SizedBox(
            width: 100,
            child: FollowButton(
              userId: user.id,
              onFollowStateChanged: (isFollowing) {
                // Optionally refresh recommendations when following status changes
                if (isFollowing) {
                  ref.refresh(recommendedUsersProvider(widget.limit));
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  String _buildRecommendationReason(RecommendedUser user) {
    final reasons = user.reasons;
    if (reasons.isEmpty) return '';

    // Show the first reason with highest score
    return reasons.first;
  }
} 