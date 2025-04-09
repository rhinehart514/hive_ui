/// Entity representing growth metrics in the domain layer
class GrowthMetricsEntity {
  final String id;
  final DateTime date;
  final int dailyActiveUsers;
  final int weeklyActiveUsers;
  final int monthlyActiveUsers;
  final int totalUsers;
  final int newUsers;
  final int returningUsers;
  final double retentionRate;
  final Map<String, int> acquisitionChannels;
  final Map<String, int> userSegments;
  final Map<String, double> engagementMetrics;
  final Map<String, dynamic> additionalMetrics;

  const GrowthMetricsEntity({
    required this.id,
    required this.date,
    required this.dailyActiveUsers,
    required this.weeklyActiveUsers,
    required this.monthlyActiveUsers,
    required this.totalUsers,
    required this.newUsers,
    required this.returningUsers,
    required this.retentionRate,
    required this.acquisitionChannels,
    required this.userSegments,
    required this.engagementMetrics,
    this.additionalMetrics = const {},
  });

  /// Creates a copy of this GrowthMetricsEntity with given fields replaced
  GrowthMetricsEntity copyWith({
    String? id,
    DateTime? date,
    int? dailyActiveUsers,
    int? weeklyActiveUsers,
    int? monthlyActiveUsers,
    int? totalUsers,
    int? newUsers,
    int? returningUsers,
    double? retentionRate,
    Map<String, int>? acquisitionChannels,
    Map<String, int>? userSegments,
    Map<String, double>? engagementMetrics,
    Map<String, dynamic>? additionalMetrics,
  }) {
    return GrowthMetricsEntity(
      id: id ?? this.id,
      date: date ?? this.date,
      dailyActiveUsers: dailyActiveUsers ?? this.dailyActiveUsers,
      weeklyActiveUsers: weeklyActiveUsers ?? this.weeklyActiveUsers,
      monthlyActiveUsers: monthlyActiveUsers ?? this.monthlyActiveUsers,
      totalUsers: totalUsers ?? this.totalUsers,
      newUsers: newUsers ?? this.newUsers,
      returningUsers: returningUsers ?? this.returningUsers,
      retentionRate: retentionRate ?? this.retentionRate,
      acquisitionChannels: acquisitionChannels ?? this.acquisitionChannels,
      userSegments: userSegments ?? this.userSegments,
      engagementMetrics: engagementMetrics ?? this.engagementMetrics,
      additionalMetrics: additionalMetrics ?? this.additionalMetrics,
    );
  }

  /// Calculate the churn rate (1 - retention rate)
  double get churnRate => 1.0 - retentionRate;

  /// Calculate the growth rate (new users / total users)
  double get growthRate => totalUsers > 0 ? newUsers / totalUsers : 0.0;

  /// Calculate the returning user ratio (returning users / total users)
  double get returningUserRatio => totalUsers > 0 ? returningUsers / totalUsers : 0.0;

  /// Get the top acquisition channel
  String? get topAcquisitionChannel {
    if (acquisitionChannels.isEmpty) return null;
    
    String topChannel = acquisitionChannels.keys.first;
    int maxCount = acquisitionChannels.values.first;
    
    for (final entry in acquisitionChannels.entries) {
      if (entry.value > maxCount) {
        topChannel = entry.key;
        maxCount = entry.value;
      }
    }
    
    return topChannel;
  }

  /// Get the top user segment
  String? get topUserSegment {
    if (userSegments.isEmpty) return null;
    
    String topSegment = userSegments.keys.first;
    int maxCount = userSegments.values.first;
    
    for (final entry in userSegments.entries) {
      if (entry.value > maxCount) {
        topSegment = entry.key;
        maxCount = entry.value;
      }
    }
    
    return topSegment;
  }

  /// Get the date string in YYYY-MM-DD format
  String get dateString => date.toIso8601String().split('T')[0];

  /// Check if this is a weekly report (date is the start of a week)
  bool get isWeeklyReport => date.weekday == DateTime.monday;

  /// Check if this is a monthly report (date is the start of a month)
  bool get isMonthlyReport => date.day == 1;
} 