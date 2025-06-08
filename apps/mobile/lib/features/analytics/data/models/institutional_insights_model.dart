import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing institutional insights data for dashboards
class InstitutionalInsightsModel {
  /// Unique identifier for this insights collection
  final String id;
  
  /// Date this data represents
  final DateTime date;
  
  /// Timeframe of the data (e.g., day, week, month)
  final String timeframe;
  
  /// Total user count at the institution
  final int totalUserCount;
  
  /// Student engagement metrics
  final Map<String, double> studentEngagement;
  
  /// Organization/club engagement metrics
  final Map<String, double> organizationEngagement;
  
  /// Event metrics
  final Map<String, dynamic> eventMetrics;
  
  /// Space performance metrics
  final Map<String, dynamic> spacePerformance;
  
  /// Content distribution metrics
  final Map<String, int> contentDistribution;
  
  /// Demographic metrics (anonymized)
  final Map<String, Map<String, int>> demographics;
  
  /// Retention metrics
  final Map<String, double> retentionMetrics;
  
  /// Growth metrics over time
  final Map<String, List<double>> growthTrends;
  
  /// Additional custom metrics
  final Map<String, dynamic> customMetrics;
  
  /// Constructor
  const InstitutionalInsightsModel({
    required this.id,
    required this.date,
    required this.timeframe,
    required this.totalUserCount,
    required this.studentEngagement,
    required this.organizationEngagement,
    required this.eventMetrics,
    required this.spacePerformance,
    required this.contentDistribution,
    required this.demographics,
    required this.retentionMetrics,
    required this.growthTrends,
    this.customMetrics = const {},
  });
  
  /// Create from a Firestore document
  factory InstitutionalInsightsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Parse date
    DateTime date = DateTime.now();
    if (data['date'] != null) {
      if (data['date'] is Timestamp) {
        date = (data['date'] as Timestamp).toDate();
      } else if (data['date'] is String) {
        date = DateTime.parse(data['date'] as String);
      }
    }
    
    // Parse student engagement metrics
    Map<String, double> parseStudentEngagement() {
      final Map<String, double> result = {};
      
      if (data['studentEngagement'] is Map) {
        final map = data['studentEngagement'] as Map;
        map.forEach((key, value) {
          if (value is double) {
            result[key.toString()] = value;
          } else if (value is int) {
            result[key.toString()] = value.toDouble();
          }
        });
      }
      
      return result;
    }
    
    // Parse organization engagement metrics
    Map<String, double> parseOrganizationEngagement() {
      final Map<String, double> result = {};
      
      if (data['organizationEngagement'] is Map) {
        final map = data['organizationEngagement'] as Map;
        map.forEach((key, value) {
          if (value is double) {
            result[key.toString()] = value;
          } else if (value is int) {
            result[key.toString()] = value.toDouble();
          }
        });
      }
      
      return result;
    }
    
    // Parse content distribution
    Map<String, int> parseContentDistribution() {
      final Map<String, int> result = {};
      
      if (data['contentDistribution'] is Map) {
        final map = data['contentDistribution'] as Map;
        map.forEach((key, value) {
          if (value is int) {
            result[key.toString()] = value;
          }
        });
      }
      
      return result;
    }
    
    // Parse demographics
    Map<String, Map<String, int>> parseDemographics() {
      final Map<String, Map<String, int>> result = {};
      
      if (data['demographics'] is Map) {
        final map = data['demographics'] as Map;
        map.forEach((category, values) {
          if (values is Map) {
            final categoryMap = <String, int>{};
            (values).forEach((key, value) {
              if (value is int) {
                categoryMap[key.toString()] = value;
              }
            });
            result[category.toString()] = categoryMap;
          }
        });
      }
      
      return result;
    }
    
    // Parse retention metrics
    Map<String, double> parseRetentionMetrics() {
      final Map<String, double> result = {};
      
      if (data['retentionMetrics'] is Map) {
        final map = data['retentionMetrics'] as Map;
        map.forEach((key, value) {
          if (value is double) {
            result[key.toString()] = value;
          } else if (value is int) {
            result[key.toString()] = value.toDouble();
          }
        });
      }
      
      return result;
    }
    
    // Parse growth trends
    Map<String, List<double>> parseGrowthTrends() {
      final Map<String, List<double>> result = {};
      
      if (data['growthTrends'] is Map) {
        final map = data['growthTrends'] as Map;
        map.forEach((key, value) {
          if (value is List) {
            final trendValues = <double>[];
            for (final item in value) {
              if (item is double) {
                trendValues.add(item);
              } else if (item is int) {
                trendValues.add(item.toDouble());
              }
            }
            result[key.toString()] = trendValues;
          }
        });
      }
      
      return result;
    }
    
    return InstitutionalInsightsModel(
      id: doc.id,
      date: date,
      timeframe: data['timeframe'] as String? ?? 'day',
      totalUserCount: data['totalUserCount'] as int? ?? 0,
      studentEngagement: parseStudentEngagement(),
      organizationEngagement: parseOrganizationEngagement(),
      eventMetrics: data['eventMetrics'] as Map<String, dynamic>? ?? {},
      spacePerformance: data['spacePerformance'] as Map<String, dynamic>? ?? {},
      contentDistribution: parseContentDistribution(),
      demographics: parseDemographics(),
      retentionMetrics: parseRetentionMetrics(),
      growthTrends: parseGrowthTrends(),
      customMetrics: data['customMetrics'] as Map<String, dynamic>? ?? {},
    );
  }
  
  /// Convert to JSON format for Firestore
  Map<String, dynamic> toJson() {
    return {
      'date': Timestamp.fromDate(date),
      'timeframe': timeframe,
      'totalUserCount': totalUserCount,
      'studentEngagement': studentEngagement,
      'organizationEngagement': organizationEngagement,
      'eventMetrics': eventMetrics,
      'spacePerformance': spacePerformance,
      'contentDistribution': contentDistribution,
      'demographics': demographics,
      'retentionMetrics': retentionMetrics,
      'growthTrends': growthTrends,
      'customMetrics': customMetrics,
    };
  }
  
  /// Create a copy with updated fields
  InstitutionalInsightsModel copyWith({
    String? id,
    DateTime? date,
    String? timeframe,
    int? totalUserCount,
    Map<String, double>? studentEngagement,
    Map<String, double>? organizationEngagement,
    Map<String, dynamic>? eventMetrics,
    Map<String, dynamic>? spacePerformance,
    Map<String, int>? contentDistribution,
    Map<String, Map<String, int>>? demographics,
    Map<String, double>? retentionMetrics,
    Map<String, List<double>>? growthTrends,
    Map<String, dynamic>? customMetrics,
  }) {
    return InstitutionalInsightsModel(
      id: id ?? this.id,
      date: date ?? this.date,
      timeframe: timeframe ?? this.timeframe,
      totalUserCount: totalUserCount ?? this.totalUserCount,
      studentEngagement: studentEngagement ?? this.studentEngagement,
      organizationEngagement: organizationEngagement ?? this.organizationEngagement,
      eventMetrics: eventMetrics ?? this.eventMetrics,
      spacePerformance: spacePerformance ?? this.spacePerformance,
      contentDistribution: contentDistribution ?? this.contentDistribution,
      demographics: demographics ?? this.demographics,
      retentionMetrics: retentionMetrics ?? this.retentionMetrics,
      growthTrends: growthTrends ?? this.growthTrends,
      customMetrics: customMetrics ?? this.customMetrics,
    );
  }
  
  /// Create an empty model for a specific date and timeframe
  factory InstitutionalInsightsModel.empty(DateTime date, String timeframe) {
    return InstitutionalInsightsModel(
      id: '${timeframe}_${date.toIso8601String().split('T')[0]}',
      date: date,
      timeframe: timeframe,
      totalUserCount: 0,
      studentEngagement: {},
      organizationEngagement: {},
      eventMetrics: {},
      spacePerformance: {},
      contentDistribution: {},
      demographics: {},
      retentionMetrics: {},
      growthTrends: {},
      customMetrics: {},
    );
  }
} 