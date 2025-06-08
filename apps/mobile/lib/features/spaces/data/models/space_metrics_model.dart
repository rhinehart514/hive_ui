import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_metrics_entity.dart';

/// Data model for space metrics
class SpaceMetricsModel {
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

  SpaceMetricsModel({
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

  /// Creates a copy of this SpaceMetricsModel with the given fields replaced with new values
  SpaceMetricsModel copyWith({
    String? spaceId,
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
    return SpaceMetricsModel(
      spaceId: spaceId ?? this.spaceId,
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

  /// Convert to domain entity
  SpaceMetricsEntity toEntity() {
    return SpaceMetricsEntity(
      spaceId: spaceId,
      memberCount: memberCount,
      activeMembers: activeMembers,
      weeklyEvents: weeklyEvents,
      monthlyEngagements: monthlyEngagements,
      lastActivity: lastActivity,
      hasNewContent: hasNewContent,
      isTrending: isTrending,
      activeMembers24h: activeMembers24h,
      activityScores: activityScores,
      category: category,
      size: size,
      engagementScore: engagementScore,
      isTimeSensitive: isTimeSensitive,
      expiryDate: expiryDate,
      connectedFriends: connectedFriends,
      firstActionPrompt: firstActionPrompt,
      needsIntroduction: needsIntroduction,
    );
  }

  /// Create an empty SpaceMetricsModel object
  factory SpaceMetricsModel.empty() {
    return SpaceMetricsModel(
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

  /// Create an initialized SpaceMetricsModel with default values
  factory SpaceMetricsModel.initial(String spaceId) {
    return SpaceMetricsModel(
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

  /// Create a SpaceMetricsModel from JSON
  factory SpaceMetricsModel.fromJson(Map<String, dynamic> json, String spaceId) {
    return SpaceMetricsModel(
      spaceId: spaceId,
      memberCount: json['memberCount'] as int? ?? 0,
      activeMembers: json['activeMembers'] as int? ?? 0,
      weeklyEvents: json['weeklyEvents'] as int? ?? 0,
      monthlyEngagements: json['monthlyEngagements'] as int? ?? 0,
      lastActivity: json['lastActivity'] != null
          ? DateTime.parse(json['lastActivity'] as String)
          : DateTime.now(),
      hasNewContent: json['hasNewContent'] as bool? ?? false,
      isTrending: json['isTrending'] as bool? ?? false,
      activeMembers24h: json['activeMembers24h'] != null
          ? List<String>.from(json['activeMembers24h'] as List)
          : const [],
      activityScores: json['activityScores'] != null
          ? Map<String, int>.from(json['activityScores'] as Map)
          : const {},
      category: _parseCategoryFromString(json['category']),
      size: _parseSizeFromString(json['size']),
      engagementScore: (json['engagementScore'] as num?)?.toDouble() ?? 0.0,
      isTimeSensitive: json['isTimeSensitive'] as bool? ?? false,
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'] as String)
          : null,
      connectedFriends: json['connectedFriends'] != null
          ? List<String>.from(json['connectedFriends'] as List)
          : const [],
      firstActionPrompt: json['firstActionPrompt'] as String?,
      needsIntroduction: json['needsIntroduction'] as bool? ?? false,
    );
  }
  
  /// Create a SpaceMetricsModel from Firestore map
  factory SpaceMetricsModel.fromMap(String spaceId, Map<String, dynamic> map) {
    return SpaceMetricsModel(
      spaceId: spaceId,
      memberCount: map['memberCount'] as int? ?? 0,
      activeMembers: map['activeMembers'] as int? ?? 0,
      weeklyEvents: map['weeklyEvents'] as int? ?? 0,
      monthlyEngagements: map['monthlyEngagements'] as int? ?? 0,
      lastActivity: map['lastActivity'] is Timestamp 
          ? (map['lastActivity'] as Timestamp).toDate()
          : DateTime.now(),
      hasNewContent: map['hasNewContent'] as bool? ?? false,
      isTrending: map['isTrending'] as bool? ?? false,
      activeMembers24h: map['activeMembers24h'] != null
          ? List<String>.from(map['activeMembers24h'] as List)
          : const [],
      activityScores: map['activityScores'] != null
          ? Map<String, int>.from(map['activityScores'] as Map)
          : const {},
      category: _parseCategoryFromString(map['category']),
      size: _parseSizeFromString(map['size']),
      engagementScore: (map['engagementScore'] as num?)?.toDouble() ?? 0.0,
      isTimeSensitive: map['isTimeSensitive'] as bool? ?? false,
      expiryDate: map['expiryDate'] is Timestamp
          ? (map['expiryDate'] as Timestamp).toDate()
          : null,
      connectedFriends: map['connectedFriends'] != null
          ? List<String>.from(map['connectedFriends'] as List)
          : const [],
      firstActionPrompt: map['firstActionPrompt'] as String?,
      needsIntroduction: map['needsIntroduction'] as bool? ?? false,
    );
  }
  
  /// Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'spaceId': spaceId,
      'memberCount': memberCount,
      'activeMembers': activeMembers,
      'weeklyEvents': weeklyEvents,
      'monthlyEngagements': monthlyEngagements,
      'lastActivity': Timestamp.fromDate(lastActivity),
      'hasNewContent': hasNewContent,
      'isTrending': isTrending,
      'activeMembers24h': activeMembers24h,
      'activityScores': activityScores,
      'category': _categoryToString(category),
      'size': _sizeToString(size),
      'engagementScore': engagementScore,
      'isTimeSensitive': isTimeSensitive,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'connectedFriends': connectedFriends,
      'firstActionPrompt': firstActionPrompt,
      'needsIntroduction': needsIntroduction,
    };
  }
  
  /// Convert to JSON for serialization
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
      'category': _categoryToString(category),
      'size': _sizeToString(size),
      'engagementScore': engagementScore,
      'isTimeSensitive': isTimeSensitive,
      'expiryDate': expiryDate?.toIso8601String(),
      'connectedFriends': connectedFriends,
      'firstActionPrompt': firstActionPrompt,
      'needsIntroduction': needsIntroduction,
    };
  }

  /// Parse SpaceCategory from string
  static SpaceCategory _parseCategoryFromString(dynamic value) {
    if (value == null) return SpaceCategory.suggested;

    final String categoryStr = value.toString().toLowerCase();

    if (categoryStr.contains('active')) {
      return SpaceCategory.active;
    } else if (categoryStr.contains('expand')) {
      return SpaceCategory.expanding;
    } else if (categoryStr.contains('emerg')) {
      return SpaceCategory.emerging;
    } else {
      return SpaceCategory.suggested;
    }
  }

  /// Parse SpaceSize from string
  static SpaceSize _parseSizeFromString(dynamic value) {
    if (value == null) return SpaceSize.small;

    final String sizeStr = value.toString().toLowerCase();

    if (sizeStr.contains('large')) {
      return SpaceSize.large;
    } else if (sizeStr.contains('medium')) {
      return SpaceSize.medium;
    } else {
      return SpaceSize.small;
    }
  }
  
  /// Convert SpaceCategory to string
  static String _categoryToString(SpaceCategory category) {
    switch (category) {
      case SpaceCategory.active:
        return 'active';
      case SpaceCategory.expanding:
        return 'expanding';
      case SpaceCategory.emerging:
        return 'emerging';
      case SpaceCategory.suggested:
        return 'suggested';
    }
  }
  
  /// Convert SpaceSize to string
  static String _sizeToString(SpaceSize size) {
    switch (size) {
      case SpaceSize.large:
        return 'large';
      case SpaceSize.medium:
        return 'medium';
      case SpaceSize.small:
        return 'small';
    }
  }
}
