import 'package:flutter/material.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// Represents different types of user achievements
enum AchievementType {
  profileBuilder,
  clubExplorer,
  eventScout,
  firstConnection,
  socialSignal,
  firstInteraction,
}

/// Model class for user achievements
class UserAchievement {
  final AchievementType type;
  final String title;
  final String description;
  final String emoji;
  final bool isCompleted;
  final DateTime? completedAt;
  final int progressCurrent;
  final int progressTotal;

  UserAchievement({
    required this.type,
    required this.title,
    required this.description,
    required this.emoji,
    required this.isCompleted,
    this.completedAt,
    this.progressCurrent = 0,
    this.progressTotal = 1,
  });

  /// Get progress percentage
  double get progressPercentage => progressTotal > 0
      ? (progressCurrent / progressTotal).clamp(0.0, 1.0)
      : 0.0;

  /// Get appropriate color for the achievement type
  Color get typeColor {
    switch (type) {
      case AchievementType.profileBuilder:
        return const Color(0xFF9C27B0);
      case AchievementType.clubExplorer:
        return const Color(0xFF2196F3);
      case AchievementType.eventScout:
        return const Color(0xFFFF9800);
      case AchievementType.firstConnection:
        return const Color(0xFF4CAF50);
      case AchievementType.socialSignal:
        return const Color(0xFFE91E63);
      case AchievementType.firstInteraction:
        return AppColors.gold;
    }
  }

  /// Create a copy of the achievement with updated properties
  UserAchievement copyWith({
    AchievementType? type,
    String? title,
    String? description,
    String? emoji,
    bool? isCompleted,
    DateTime? completedAt,
    int? progressCurrent,
    int? progressTotal,
  }) {
    return UserAchievement(
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      progressCurrent: progressCurrent ?? this.progressCurrent,
      progressTotal: progressTotal ?? this.progressTotal,
    );
  }
}
