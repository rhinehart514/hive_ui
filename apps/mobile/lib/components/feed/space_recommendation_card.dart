import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../models/space_recommendation.dart';
import '../../features/clubs/presentation/widgets/space_detail/space_detail_screen.dart';

/// A card that displays a space recommendation in the feed
class SpaceRecommendationCard extends StatelessWidget {
  /// The space recommendation to display
  final SpaceRecommendation space;

  /// Optional callback when the card is tapped
  final VoidCallback? onTap;

  /// Constructor
  const SpaceRecommendationCard({
    Key? key,
    required this.space,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        // Navigate to space detail screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SpaceDetailScreen(
              spaceId: space.id,
              spaceType: space.category,
            ),
          ),
        );
        // Call optional callback
        onTap?.call();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              space.name,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              space.category,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              space.description,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 