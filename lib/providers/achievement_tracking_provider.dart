import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/models/user_achievement.dart';
import 'package:hive_ui/providers/achievement_provider.dart';
import 'package:hive_ui/widgets/achievements/achievement_notification.dart';

/// A provider to handle achievement tracking and progress
class AchievementTrackingNotifier extends StateNotifier<void> {
  /// Reference to other providers
  final Ref _ref;

  /// The controller for showing achievement notifications
  final AchievementNotificationController _notificationController;

  /// The context where notifications should be shown
  BuildContext? _context;

  AchievementTrackingNotifier(this._ref, this._notificationController)
      : super(null) {
    // Listen for changes in the achievements to show notifications
    _ref.listen<List<UserAchievement>>(
        userAchievementsProvider, _handleAchievementChanges);
  }

  /// Set the context where notifications should be shown
  void setContext(BuildContext context) {
    _context = context;
  }

  /// Check and update the current achievement progress
  void checkAndUpdateAchievement(AchievementType type, {int progress = 1}) {
    _ref
        .read(userAchievementsProvider.notifier)
        .completeAchievement(type, progress: progress);
  }

  /// Track an achievement with a specific progress value
  void trackAchievement(AchievementType type, {int progress = 1}) {
    // Find the specific achievement
    final achievements = _ref.read(userAchievementsProvider);
    final achievement = achievements.firstWhere(
      (a) => a.type == type,
      orElse: () => throw Exception('Achievement not found: $type'),
    );

    // Only track progress if the achievement is not already completed
    if (!achievement.isCompleted) {
      // Update the achievement progress
      checkAndUpdateAchievement(type, progress: progress);
    }
  }

  /// Reset tracking
  void resetTracking() {
    _context = null;
  }

  /// Handle changes in achievements to show notifications
  void _handleAchievementChanges(
      List<UserAchievement>? previous, List<UserAchievement> current) {
    // We need a context to show notifications
    if (_context == null) return;

    // If previous state is null, we can't compare changes
    if (previous == null) return;

    for (int i = 0; i < current.length; i++) {
      // Find matching achievement in previous state
      final prevAchievement = previous.firstWhere(
        (a) => a.type == current[i].type,
        orElse: () => current[i],
      );

      // Check if progress has increased but not yet completed
      if (current[i].progressCurrent > prevAchievement.progressCurrent &&
          !current[i].isCompleted) {
        _showProgressUpdate(current[i]);
      }

      // Check if achievement was just completed
      if (!prevAchievement.isCompleted && current[i].isCompleted) {
        _showAchievementCompleted(current[i]);
      }
    }
  }

  /// Show progress update notification
  void _showProgressUpdate(UserAchievement achievement) {
    if (_context != null) {
      _notificationController.showProgressUpdate(_context!, achievement);
    }
  }

  /// Show achievement completion notification
  void _showAchievementCompleted(UserAchievement achievement) {
    if (_context != null) {
      _notificationController.showCompletionNotification(
          _context!, achievement);
    }
  }
}

/// Provider for achievement tracking
final achievementTrackingProvider = Provider.family<AchievementTrackingNotifier,
    AchievementNotificationController>((ref, controller) {
  return AchievementTrackingNotifier(ref, controller);
});
