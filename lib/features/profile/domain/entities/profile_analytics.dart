import 'package:flutter/foundation.dart';

/// Represents analytics and insights for a user profile
@immutable
class ProfileAnalytics {
  /// Overall engagement score (0-100)
  final int engagementScore;

  /// Number of profile views in the last 30 days
  final int recentProfileViews;

  /// Number of search appearances in the last 30 days
  final int recentSearchAppearances;

  /// Average weekly event attendance rate
  final double eventAttendanceRate;

  /// Average weekly space participation rate
  final double spaceParticipationRate;

  /// Connection growth rate (% increase in last 30 days)
  final double connectionGrowthRate;

  /// Content engagement rate (likes, comments per post)
  final double contentEngagementRate;

  /// Top 3 most active spaces
  final List<String> topActiveSpaces;

  /// Top 3 most attended event types
  final List<String> topEventTypes;

  /// Top 5 most engaged with users
  final List<String> topConnections;

  /// Peak activity hours (0-23, sorted by frequency)
  final List<int> peakActivityHours;

  /// Monthly activity breakdown
  final Map<String, int> monthlyActivity;

  /// Constructor
  const ProfileAnalytics({
    required this.engagementScore,
    required this.recentProfileViews,
    required this.recentSearchAppearances,
    required this.eventAttendanceRate,
    required this.spaceParticipationRate,
    required this.connectionGrowthRate,
    required this.contentEngagementRate,
    required this.topActiveSpaces,
    required this.topEventTypes,
    required this.topConnections,
    required this.peakActivityHours,
    required this.monthlyActivity,
  });

  /// Create a copy with some fields replaced
  ProfileAnalytics copyWith({
    int? engagementScore,
    int? recentProfileViews,
    int? recentSearchAppearances,
    double? eventAttendanceRate,
    double? spaceParticipationRate,
    double? connectionGrowthRate,
    double? contentEngagementRate,
    List<String>? topActiveSpaces,
    List<String>? topEventTypes,
    List<String>? topConnections,
    List<int>? peakActivityHours,
    Map<String, int>? monthlyActivity,
  }) {
    return ProfileAnalytics(
      engagementScore: engagementScore ?? this.engagementScore,
      recentProfileViews: recentProfileViews ?? this.recentProfileViews,
      recentSearchAppearances: recentSearchAppearances ?? this.recentSearchAppearances,
      eventAttendanceRate: eventAttendanceRate ?? this.eventAttendanceRate,
      spaceParticipationRate: spaceParticipationRate ?? this.spaceParticipationRate,
      connectionGrowthRate: connectionGrowthRate ?? this.connectionGrowthRate,
      contentEngagementRate: contentEngagementRate ?? this.contentEngagementRate,
      topActiveSpaces: topActiveSpaces ?? this.topActiveSpaces,
      topEventTypes: topEventTypes ?? this.topEventTypes,
      topConnections: topConnections ?? this.topConnections,
      peakActivityHours: peakActivityHours ?? this.peakActivityHours,
      monthlyActivity: monthlyActivity ?? this.monthlyActivity,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'engagementScore': engagementScore,
      'recentProfileViews': recentProfileViews,
      'recentSearchAppearances': recentSearchAppearances,
      'eventAttendanceRate': eventAttendanceRate,
      'spaceParticipationRate': spaceParticipationRate,
      'connectionGrowthRate': connectionGrowthRate,
      'contentEngagementRate': contentEngagementRate,
      'topActiveSpaces': topActiveSpaces,
      'topEventTypes': topEventTypes,
      'topConnections': topConnections,
      'peakActivityHours': peakActivityHours,
      'monthlyActivity': monthlyActivity,
    };
  }

  /// Create from JSON
  factory ProfileAnalytics.fromJson(Map<String, dynamic> json) {
    return ProfileAnalytics(
      engagementScore: json['engagementScore'] as int? ?? 0,
      recentProfileViews: json['recentProfileViews'] as int? ?? 0,
      recentSearchAppearances: json['recentSearchAppearances'] as int? ?? 0,
      eventAttendanceRate: (json['eventAttendanceRate'] as num?)?.toDouble() ?? 0.0,
      spaceParticipationRate: (json['spaceParticipationRate'] as num?)?.toDouble() ?? 0.0,
      connectionGrowthRate: (json['connectionGrowthRate'] as num?)?.toDouble() ?? 0.0,
      contentEngagementRate: (json['contentEngagementRate'] as num?)?.toDouble() ?? 0.0,
      topActiveSpaces: (json['topActiveSpaces'] as List<dynamic>?)?.cast<String>() ?? [],
      topEventTypes: (json['topEventTypes'] as List<dynamic>?)?.cast<String>() ?? [],
      topConnections: (json['topConnections'] as List<dynamic>?)?.cast<String>() ?? [],
      peakActivityHours: (json['peakActivityHours'] as List<dynamic>?)?.cast<int>() ?? [],
      monthlyActivity: (json['monthlyActivity'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as int),
          ) ??
          {},
    );
  }

  /// Create empty analytics
  factory ProfileAnalytics.empty() => const ProfileAnalytics(
        engagementScore: 0,
        recentProfileViews: 0,
        recentSearchAppearances: 0,
        eventAttendanceRate: 0.0,
        spaceParticipationRate: 0.0,
        connectionGrowthRate: 0.0,
        contentEngagementRate: 0.0,
        topActiveSpaces: [],
        topEventTypes: [],
        topConnections: [],
        peakActivityHours: [],
        monthlyActivity: {},
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProfileAnalytics &&
        other.engagementScore == engagementScore &&
        other.recentProfileViews == recentProfileViews &&
        other.recentSearchAppearances == recentSearchAppearances &&
        other.eventAttendanceRate == eventAttendanceRate &&
        other.spaceParticipationRate == spaceParticipationRate &&
        other.connectionGrowthRate == connectionGrowthRate &&
        other.contentEngagementRate == contentEngagementRate &&
        listEquals(other.topActiveSpaces, topActiveSpaces) &&
        listEquals(other.topEventTypes, topEventTypes) &&
        listEquals(other.topConnections, topConnections) &&
        listEquals(other.peakActivityHours, peakActivityHours) &&
        mapEquals(other.monthlyActivity, monthlyActivity);
  }

  @override
  int get hashCode {
    return Object.hash(
      engagementScore,
      recentProfileViews,
      recentSearchAppearances,
      eventAttendanceRate,
      spaceParticipationRate,
      connectionGrowthRate,
      contentEngagementRate,
      Object.hashAll(topActiveSpaces),
      Object.hashAll(topEventTypes),
      Object.hashAll(topConnections),
      Object.hashAll(peakActivityHours),
      Object.hashAll(monthlyActivity.entries),
    );
  }
} 