import 'package:flutter/material.dart';

/// Represents a category for spaces
enum SpaceCategory {
  active, // Spaces you frequently engage with
  expanding, // Spaces you're part of but less active
  emerging, // New or trending spaces
  suggested // Personalized recommendations
}

/// Represents the size classification of a space
enum SpaceSize {
  large, // Most engaged spaces
  medium, // Moderately engaged spaces
  small // New or less engaged spaces
}

/// Domain entity for space metrics
@immutable
class SpaceMetricsEntity {
  final String spaceId;
  final int memberCount;
  final int activeMembers;
  final int weeklyEvents;
  final int monthlyEngagements;
  final DateTime lastActivity;
  final bool hasNewContent;
  final bool isTrending;
  final List<String> activeMembers24h;
  final Map<String, int> activityScores;
  final SpaceCategory category;
  final SpaceSize size;
  final double engagementScore;
  final bool isTimeSensitive;
  final DateTime? expiryDate;
  final List<String> connectedFriends;
  final String? firstActionPrompt;
  final bool needsIntroduction;

  const SpaceMetricsEntity({
    required this.spaceId,
    required this.memberCount,
    required this.activeMembers,
    required this.weeklyEvents,
    required this.monthlyEngagements,
    required this.lastActivity,
    required this.hasNewContent,
    required this.isTrending,
    required this.activeMembers24h,
    required this.activityScores,
    required this.category,
    required this.size,
    required this.engagementScore,
    this.isTimeSensitive = false,
    this.expiryDate,
    this.connectedFriends = const [],
    this.firstActionPrompt,
    this.needsIntroduction = false,
  });

  /// Create an empty SpaceMetricsEntity object
  factory SpaceMetricsEntity.empty() {
    return SpaceMetricsEntity(
      spaceId: '',
      memberCount: 0,
      activeMembers: 0,
      weeklyEvents: 0,
      monthlyEngagements: 0,
      lastActivity: DateTime.now(),
      hasNewContent: false,
      isTrending: false,
      activeMembers24h: const [],
      activityScores: const {},
      category: SpaceCategory.suggested,
      size: SpaceSize.small,
      engagementScore: 0.0,
    );
  }

  /// Create an initialized SpaceMetricsEntity with default values
  factory SpaceMetricsEntity.initial(String spaceId) {
    return SpaceMetricsEntity(
      spaceId: spaceId,
      memberCount: 0,
      activeMembers: 0,
      weeklyEvents: 0,
      monthlyEngagements: 0,
      lastActivity: DateTime.now(),
      hasNewContent: false,
      isTrending: false,
      activeMembers24h: const [],
      activityScores: const {},
      category: SpaceCategory.suggested,
      size: SpaceSize.small,
      engagementScore: 0.0,
    );
  }

  /// Create a copy of this entity with specified values changed
  SpaceMetricsEntity copyWith({
    int? memberCount,
    int? activeMembers,
    int? weeklyEvents,
    int? monthlyEngagements,
    DateTime? lastActivity,
    bool? hasNewContent,
    bool? isTrending,
    List<String>? activeMembers24h,
    Map<String, int>? activityScores,
    SpaceCategory? category,
    SpaceSize? size,
    double? engagementScore,
    bool? isTimeSensitive,
    DateTime? expiryDate,
    List<String>? connectedFriends,
    String? firstActionPrompt,
    bool? needsIntroduction,
  }) {
    return SpaceMetricsEntity(
      spaceId: spaceId,
      memberCount: memberCount ?? this.memberCount,
      activeMembers: activeMembers ?? this.activeMembers,
      weeklyEvents: weeklyEvents ?? this.weeklyEvents,
      monthlyEngagements: monthlyEngagements ?? this.monthlyEngagements,
      lastActivity: lastActivity ?? this.lastActivity,
      hasNewContent: hasNewContent ?? this.hasNewContent,
      isTrending: isTrending ?? this.isTrending,
      activeMembers24h: activeMembers24h ?? this.activeMembers24h,
      activityScores: activityScores ?? this.activityScores,
      category: category ?? this.category,
      size: size ?? this.size,
      engagementScore: engagementScore ?? this.engagementScore,
      isTimeSensitive: isTimeSensitive ?? this.isTimeSensitive,
      expiryDate: expiryDate ?? this.expiryDate,
      connectedFriends: connectedFriends ?? this.connectedFriends,
      firstActionPrompt: firstActionPrompt ?? this.firstActionPrompt,
      needsIntroduction: needsIntroduction ?? this.needsIntroduction,
    );
  }
}
