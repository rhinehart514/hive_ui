import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// An overlay to display user information on top of the profile image
class ProfileInfoOverlay extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback? onVerifiedPlusTap;

  const ProfileInfoOverlay({
    super.key,
    required this.profile,
    this.onVerifiedPlusTap,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate available width to ensure name doesn't get truncated
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    // Dynamically adjust font size based on screen width and username length
    final usernameFontSize = _calculateUsernameFontSize(
        screenWidth: screenWidth, username: profile.username);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.5),
            Colors.black.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Name and verification badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  profile.username,
                  style: GoogleFonts.outfit(
                    fontSize: usernameFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (profile.accountTier != AccountTier.public)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _buildVerificationBadge(profile.accountTier),
                ),
            ],
          ),

          // Major and year on one line with smaller text
          const SizedBox(height: 4),
          Text(
            '${profile.major}, ${profile.year}',
            style: GoogleFonts.outfit(
              fontSize: isSmallScreen ? 12 : 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.85),
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationBadge(AccountTier tier) {
    final isVerifiedPlus = tier == AccountTier.verifiedPlus;

    // Colors updated: gold for verified+, blue for regular verified
    final Color badgeColor = isVerifiedPlus
        ? AppColors.gold
        : const Color(0xFF4C9FFF); // Blue for verified

    // Wrap in a GestureDetector to handle verification badge taps
    return GestureDetector(
      onTap: isVerifiedPlus ? onVerifiedPlusTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: badgeColor.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.verified,
              color: badgeColor,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              isVerifiedPlus ? 'Verified+' : 'Verified',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: badgeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dynamically calculate username font size based on screen width and name length
  double _calculateUsernameFontSize({
    required double screenWidth,
    required String username,
  }) {
    // Base font size
    double fontSize = 24;

    // Adjust for screen width
    if (screenWidth < 600) fontSize = 20;
    if (screenWidth < 400) fontSize = 18;

    // Further reduce for long usernames
    if (username.length > 15) fontSize -= 2;
    if (username.length > 20) fontSize -= 2;

    return fontSize;
  }
}
