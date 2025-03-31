import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:hive_ui/models/user_achievement.dart';
import 'package:hive_ui/widgets/profile/profile_card.dart';

/// Widget that displays achievement badges for the user's profile
class AchievementBadges extends StatelessWidget {
  /// The list of achievements to display
  final List<UserAchievement> achievements;

  /// Callback when an achievement is tapped
  final Function(UserAchievement)? onAchievementTap;

  /// Whether the HIVE Lab is unlocked
  final bool isHiveLabUnlocked;

  /// Optional padding for the widget
  final EdgeInsetsGeometry padding;

  /// Optional margin for the card
  final EdgeInsetsGeometry margin;

  /// Optional highlighted achievement
  final UserAchievement? highlightedAchievement;

  /// Constructor
  const AchievementBadges({
    super.key,
    required this.achievements,
    this.onAchievementTap,
    this.isHiveLabUnlocked = false,
    this.padding = const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
    this.margin = const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    this.highlightedAchievement,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileCard(
      type: ProfileCardType.achievement,
      padding: padding,
      margin: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          _buildProgressBar(),
          const SizedBox(height: 20),
          _buildAchievementGrid(context),
          if (isHiveLabUnlocked) ...[
            const SizedBox(height: 16),
            _buildHiveLabUnlockedBanner(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final completedCount = achievements.where((a) => a.isCompleted).length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Profile Progression',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        Text(
          '$completedCount/${achievements.length} Complete',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    final progressPercentage = achievements.isEmpty
        ? 0.0
        : achievements.fold<int>(0, (sum, a) => sum + a.progressCurrent) /
            achievements.fold<int>(0, (sum, a) => sum + a.progressTotal);

    return Container(
      height: 8,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progressPercentage.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.7)
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementGrid(BuildContext context) {
    return AnimationLimiter(
      child: Wrap(
        spacing: 16,
        runSpacing: 20,
        alignment: WrapAlignment.spaceEvenly,
        children: List.generate(
          achievements.length,
          (index) => AnimationConfiguration.staggeredGrid(
            position: index,
            columnCount: 3,
            duration: const Duration(milliseconds: 500),
            child: ScaleAnimation(
              child: FadeInAnimation(
                child: _buildAchievementBadge(achievements[index], context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementBadge(
      UserAchievement achievement, BuildContext context) {
    final isHighlighted = highlightedAchievement?.type == achievement.type;

    return GestureDetector(
      onTap: () {
        if (onAchievementTap != null) {
          onAchievementTap!(achievement);
        }
      },
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 1.0, end: isHighlighted ? 1.2 : 1.0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: achievement.isCompleted
                      ? achievement.typeColor
                          .withOpacity(isHighlighted ? 0.3 : 0.2)
                      : Colors.white10,
                  border: Border.all(
                    color: achievement.isCompleted
                        ? achievement.typeColor
                        : Colors.white24,
                    width: isHighlighted ? 2.5 : 1.5,
                  ),
                  boxShadow: isHighlighted
                      ? [
                          BoxShadow(
                            color: achievement.typeColor.withOpacity(0.4),
                            blurRadius: 12,
                            spreadRadius: 2,
                          )
                        ]
                      : null,
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        achievement.emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                    if (achievement.progressTotal > 1 &&
                        !achievement.isCompleted)
                      CircularProgressIndicator(
                        value: achievement.progressPercentage,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          achievement.typeColor.withOpacity(0.5),
                        ),
                        strokeWidth: 2,
                      ),
                    if (achievement.isCompleted)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.black,
                              width: 1.5,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.check,
                              size: 12,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Badge title text
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: GoogleFonts.outfit(
                fontWeight: achievement.isCompleted || isHighlighted
                    ? FontWeight.w600
                    : FontWeight.w500,
                fontSize: isHighlighted ? 13 : 12,
                color: isHighlighted
                    ? achievement.typeColor
                    : (achievement.isCompleted ? Colors.white : Colors.white70),
              ),
              child: Text(
                achievement.title
                    .split(' ')[0], // Just show first word to keep it short
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHiveLabUnlockedBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Text(
            '🧪',
            style: TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'HIVE Lab Unlocked!',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 4),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              minimumSize: const Size(60, 28),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Enter',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
