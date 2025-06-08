import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/models/user_achievement.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';

/// Provider for user achievements
final userAchievementsProvider =
    StateNotifierProvider<AchievementsNotifier, List<UserAchievement>>((ref) {
  return AchievementsNotifier();
});

/// Notifier for managing user achievements
class AchievementsNotifier extends StateNotifier<List<UserAchievement>> {
  AchievementsNotifier() : super(_initialAchievements);

  /// Complete an achievement
  void completeAchievement(AchievementType type, {int progress = 1}) {
    state = state.map((achievement) {
      if (achievement.type == type) {
        final newProgress = achievement.progressCurrent + progress;
        final isNowCompleted = newProgress >= achievement.progressTotal;

        return achievement.copyWith(
          progressCurrent: newProgress,
          isCompleted: isNowCompleted,
          completedAt: isNowCompleted ? DateTime.now() : null,
        );
      }
      return achievement;
    }).toList();
  }

  /// Check if all achievements are completed (for HIVE Lab unlock)
  bool get areAllAchievementsCompleted {
    return state.every((achievement) => achievement.isCompleted);
  }

  /// Get the progress percentage (0.0 to 1.0)
  double get progressPercentage {
    final totalSteps = state.fold<int>(0, (sum, a) => sum + a.progressTotal);
    final completedSteps =
        state.fold<int>(0, (sum, a) => sum + a.progressCurrent);
    return totalSteps > 0 ? (completedSteps / totalSteps).clamp(0.0, 1.0) : 0.0;
  }
}

/// Initial set of achievements
final List<UserAchievement> _initialAchievements = [
  UserAchievement(
    type: AchievementType.profileBuilder,
    title: "You're Official!",
    description: "Upload a profile picture & fill in your basic info",
    emoji: "👤",
    isCompleted: false,
    progressTotal: 2, // Profile pic + basic info
  ),
  UserAchievement(
    type: AchievementType.clubExplorer,
    title: "Campus Explorer",
    description: "Visit 3+ club spaces",
    emoji: "👥",
    isCompleted: false,
    progressTotal: 3, // Need to visit 3 clubs
  ),
  UserAchievement(
    type: AchievementType.eventScout,
    title: "Event Scout",
    description: "RSVP to your first event",
    emoji: "🎉",
    isCompleted: false,
  ),
  UserAchievement(
    type: AchievementType.firstConnection,
    title: "Networker",
    description: "Follow or add 3 friends",
    emoji: "🤝",
    isCompleted: false,
    progressTotal: 3, // Need 3 friends
  ),
  UserAchievement(
    type: AchievementType.socialSignal,
    title: "Social Butterfly",
    description: "Share your first event",
    emoji: "📣",
    isCompleted: false,
  ),
  UserAchievement(
    type: AchievementType.firstInteraction,
    title: "Engaged!",
    description: "Comment on a post",
    emoji: "⚡️",
    isCompleted: false,
  ),
];

class AnimatedAchievementBadge extends StatelessWidget {
  final UserAchievement achievement;
  final VoidCallback? onTap;
  final int index;

  const AnimatedAchievementBadge({
    super.key,
    required this.achievement,
    required this.index,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimationConfiguration.staggeredGrid(
      position: index,
      duration: const Duration(milliseconds: 500),
      columnCount: 3,
      child: ScaleAnimation(
        child: FadeInAnimation(
          child: GestureDetector(
            onTap: onTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: achievement.isCompleted
                            ? achievement.typeColor.withOpacity(0.2)
                            : Colors.white10,
                        border: Border.all(
                          color: achievement.isCompleted
                              ? achievement.typeColor
                              : Colors.white24,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          achievement.emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                    if (achievement.progressTotal > 1)
                      Positioned.fill(
                        child: CircularProgressIndicator(
                          value: achievement.progressPercentage,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            achievement.typeColor.withOpacity(0.5),
                          ),
                          strokeWidth: 2,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  achievement.title.split(' ')[0],
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: achievement.isCompleted
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color:
                        achievement.isCompleted ? Colors.white : Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
