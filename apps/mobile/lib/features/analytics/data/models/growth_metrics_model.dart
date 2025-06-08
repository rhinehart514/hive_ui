import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ui/features/analytics/domain/entities/growth_metrics_entity.dart';

/// Data model for tracking growth metrics of the platform
class GrowthMetricsModel {
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

  const GrowthMetricsModel({
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

  /// Convert to domain entity
  GrowthMetricsEntity toEntity() {
    return GrowthMetricsEntity(
      id: id,
      date: date,
      dailyActiveUsers: dailyActiveUsers,
      weeklyActiveUsers: weeklyActiveUsers,
      monthlyActiveUsers: monthlyActiveUsers,
      totalUsers: totalUsers,
      newUsers: newUsers,
      returningUsers: returningUsers,
      retentionRate: retentionRate,
      acquisitionChannels: acquisitionChannels,
      userSegments: userSegments,
      engagementMetrics: engagementMetrics,
      additionalMetrics: additionalMetrics,
    );
  }

  /// Create from Firestore document
  factory GrowthMetricsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse date
    DateTime date = DateTime.now();
    if (data['date'] != null) {
      if (data['date'] is Timestamp) {
        date = (data['date'] as Timestamp).toDate();
      } else if (data['date'] is int) {
        date = DateTime.fromMillisecondsSinceEpoch(data['date']);
      } else if (data['date'] is String) {
        date = DateTime.parse(data['date']);
      }
    }

    // Parse acquisition channels
    Map<String, int> parseAcquisitionChannels() {
      if (data['acquisitionChannels'] == null) return {};
      if (data['acquisitionChannels'] is Map) {
        try {
          final map = data['acquisitionChannels'] as Map;
          return map.map((key, value) => 
            MapEntry(key.toString(), value is int ? value : 0));
        } catch (e) {
          return {};
        }
      }
      return {};
    }

    // Parse user segments
    Map<String, int> parseUserSegments() {
      if (data['userSegments'] == null) return {};
      if (data['userSegments'] is Map) {
        try {
          final map = data['userSegments'] as Map;
          return map.map((key, value) => 
            MapEntry(key.toString(), value is int ? value : 0));
        } catch (e) {
          return {};
        }
      }
      return {};
    }

    // Parse engagement metrics
    Map<String, double> parseEngagementMetrics() {
      if (data['engagementMetrics'] == null) return {};
      if (data['engagementMetrics'] is Map) {
        try {
          final map = data['engagementMetrics'] as Map;
          return map.map((key, value) => 
            MapEntry(key.toString(), 
              value is double ? value : (value is int ? value.toDouble() : 0.0)));
        } catch (e) {
          return {};
        }
      }
      return {};
    }

    // Parse additional metrics
    Map<String, dynamic> parseAdditionalMetrics() {
      if (data['additionalMetrics'] == null) return {};
      if (data['additionalMetrics'] is Map) {
        try {
          return Map<String, dynamic>.from(data['additionalMetrics'] as Map);
        } catch (e) {
          return {};
        }
      }
      return {};
    }

    return GrowthMetricsModel(
      id: doc.id,
      date: date,
      dailyActiveUsers: data['dailyActiveUsers'] is int ? data['dailyActiveUsers'] : 0,
      weeklyActiveUsers: data['weeklyActiveUsers'] is int ? data['weeklyActiveUsers'] : 0,
      monthlyActiveUsers: data['monthlyActiveUsers'] is int ? data['monthlyActiveUsers'] : 0,
      totalUsers: data['totalUsers'] is int ? data['totalUsers'] : 0,
      newUsers: data['newUsers'] is int ? data['newUsers'] : 0,
      returningUsers: data['returningUsers'] is int ? data['returningUsers'] : 0,
      retentionRate: data['retentionRate'] is double ? data['retentionRate'] : 
                    (data['retentionRate'] is int ? data['retentionRate'].toDouble() : 0.0),
      acquisitionChannels: parseAcquisitionChannels(),
      userSegments: parseUserSegments(),
      engagementMetrics: parseEngagementMetrics(),
      additionalMetrics: parseAdditionalMetrics(),
    );
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'dailyActiveUsers': dailyActiveUsers,
      'weeklyActiveUsers': weeklyActiveUsers,
      'monthlyActiveUsers': monthlyActiveUsers,
      'totalUsers': totalUsers,
      'newUsers': newUsers,
      'returningUsers': returningUsers,
      'retentionRate': retentionRate,
      'acquisitionChannels': acquisitionChannels,
      'userSegments': userSegments,
      'engagementMetrics': engagementMetrics,
      'additionalMetrics': additionalMetrics,
    };
  }

  /// Create a copy of this GrowthMetricsModel with given fields replaced
  GrowthMetricsModel copyWith({
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
    return GrowthMetricsModel(
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

  /// Create an empty metrics model for a specific date
  factory GrowthMetricsModel.empty(DateTime date) {
    final dateString = date.toIso8601String().split('T')[0];
    return GrowthMetricsModel(
      id: dateString,
      date: date,
      dailyActiveUsers: 0,
      weeklyActiveUsers: 0,
      monthlyActiveUsers: 0,
      totalUsers: 0,
      newUsers: 0,
      returningUsers: 0,
      retentionRate: 0.0,
      acquisitionChannels: {},
      userSegments: {},
      engagementMetrics: {},
      additionalMetrics: {},
    );
  }
} 