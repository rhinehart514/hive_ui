import 'package:flutter/material.dart';

enum SpaceCategory {
  active, // Spaces you frequently engage with
  expanding, // Spaces you're part of but less active
  emerging, // New or trending spaces
  suggested // Personalized recommendations
}

enum SpaceSize {
  large, // Most engaged spaces
  medium, // Moderately engaged spaces
  small // New or less engaged spaces
}

@immutable
class SpaceMetrics {
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

  const SpaceMetrics({
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

  factory SpaceMetrics.initial(String spaceId) {
    return SpaceMetrics(
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

  /// Create SpaceMetrics from Firestore JSON data
  factory SpaceMetrics.fromJson(Map<String, dynamic> json) {
    return SpaceMetrics(
      spaceId: json['spaceId'] ?? '',
      memberCount: json['memberCount'] ?? 0,
      activeMembers: json['activeMembers'] ?? 0,
      weeklyEvents: json['weeklyEvents'] ?? 0,
      monthlyEngagements: json['monthlyEngagements'] ?? 0,
      lastActivity: json['lastActivity'] != null
          ? (json['lastActivity'] is DateTime
              ? json['lastActivity']
              : DateTime.fromMillisecondsSinceEpoch(
                  (json['lastActivity']['seconds'] ?? 0) * 1000))
          : DateTime.now(),
      hasNewContent: json['hasNewContent'] ?? false,
      isTrending: json['isTrending'] ?? false,
      activeMembers24h: json['activeMembers24h'] != null
          ? List<String>.from(json['activeMembers24h'])
          : const [],
      activityScores: json['activityScores'] != null
          ? Map<String, int>.from(json['activityScores'])
          : const {},
      category: _stringToSpaceCategory(json['category'] ?? 'suggested'),
      size: _stringToSpaceSize(json['size'] ?? 'medium'),
      engagementScore: (json['engagementScore'] ?? 0).toDouble(),
      isTimeSensitive: json['isTimeSensitive'] ?? false,
      expiryDate: json['expiryDate'] != null
          ? (json['expiryDate'] is DateTime
              ? json['expiryDate']
              : DateTime.fromMillisecondsSinceEpoch(
                  (json['expiryDate']['seconds'] ?? 0) * 1000))
          : null,
      connectedFriends: json['connectedFriends'] != null
          ? List<String>.from(json['connectedFriends'])
          : const [],
      firstActionPrompt: json['firstActionPrompt'],
      needsIntroduction: json['needsIntroduction'] ?? false,
    );
  }

  /// Create an empty SpaceMetrics object
  factory SpaceMetrics.empty() {
    return SpaceMetrics(
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

  SpaceMetrics copyWith({
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
    return SpaceMetrics(
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

  /// Calculate the visual prominence factor (0.0 to 1.0)
  double get prominence {
    double score = engagementScore;

    // Boost score for trending spaces
    if (isTrending) score *= 1.2;

    // Boost for new content
    if (hasNewContent) score *= 1.1;

    // Boost for connected friends
    if (connectedFriends.isNotEmpty) {
      score *= (1 + (connectedFriends.length * 0.05));
    }

    // Decay based on inactivity
    final daysSinceActivity = DateTime.now().difference(lastActivity).inDays;
    if (daysSinceActivity > 0) {
      score *= (1 - (daysSinceActivity * 0.05));
    }

    return score.clamp(0.0, 1.0);
  }

  /// Check if the space should be deprioritized
  bool get shouldDeprioritize {
    final inactiveDays = DateTime.now().difference(lastActivity).inDays;
    return inactiveDays > 30 || monthlyEngagements < 5;
  }

  /// Get appropriate size based on metrics
  SpaceSize calculateSize() {
    if (prominence > 0.7) return SpaceSize.large;
    if (prominence > 0.4) return SpaceSize.medium;
    return SpaceSize.small;
  }

  /// Get category based on engagement patterns
  SpaceCategory calculateCategory() {
    if (monthlyEngagements > 20) return SpaceCategory.active;
    if (monthlyEngagements > 5) return SpaceCategory.expanding;
    if (isTrending || hasNewContent) return SpaceCategory.emerging;
    return SpaceCategory.suggested;
  }

  /// Helper method to convert string to SpaceCategory
  static SpaceCategory _stringToSpaceCategory(String value) {
    switch (value.toLowerCase()) {
      case 'active':
        return SpaceCategory.active;
      case 'expanding':
        return SpaceCategory.expanding;
      case 'emerging':
        return SpaceCategory.emerging;
      case 'suggested':
      default:
        return SpaceCategory.suggested;
    }
  }

  /// Helper method to convert string to SpaceSize
  static SpaceSize _stringToSpaceSize(String value) {
    switch (value.toLowerCase()) {
      case 'large':
        return SpaceSize.large;
      case 'medium':
        return SpaceSize.medium;
      case 'small':
      default:
        return SpaceSize.small;
    }
  }

  /// Convert SpaceMetrics to JSON
  Map<String, dynamic> toJson() {
    return {
      'spaceId': spaceId,
      'memberCount': memberCount,
      'activeMembers': activeMembers,
      'weeklyEvents': weeklyEvents,
      'monthlyEngagements': monthlyEngagements,
      'lastActivity': lastActivity.toIso8601String(),
      'hasNewContent': hasNewContent,
      'isTrending': isTrending,
      'activeMembers24h': activeMembers24h,
      'activityScores': activityScores,
      'category': category.toString().split('.').last,
      'size': size.toString().split('.').last,
      'engagementScore': engagementScore,
      'isTimeSensitive': isTimeSensitive,
      'expiryDate': expiryDate?.toIso8601String(),
      'connectedFriends': connectedFriends,
      'firstActionPrompt': firstActionPrompt,
      'needsIntroduction': needsIntroduction,
    };
  }
}
