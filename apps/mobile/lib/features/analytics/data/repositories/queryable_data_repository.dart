import 'package:hive_ui/features/analytics/data/models/analytics_event_model.dart';
import 'package:hive_ui/features/analytics/data/models/growth_metrics_model.dart';

/// Definition of time periods for data queries
enum TimePeriod {
  /// Last 24 hours
  day,
  
  /// Last 7 days
  week,
  
  /// Last 30 days
  month,
  
  /// Last 90 days
  quarter,
  
  /// Last 365 days
  year,
  
  /// Custom date range
  custom
}

/// Definition of data aggregation level
enum AggregationLevel {
  /// Individual data points
  raw,
  
  /// Hourly aggregation
  hourly,
  
  /// Daily aggregation
  daily,
  
  /// Weekly aggregation
  weekly,
  
  /// Monthly aggregation
  monthly
}

/// Definition of privacy level for data access
enum PrivacyLevel {
  /// Completely anonymized data
  anonymized,
  
  /// Pseudonymized data (consistent identifiers but not real IDs)
  pseudonymized,
  
  /// Identifiable data (requires highest permissions)
  identifiable
}

/// Interface for querying analytics data
abstract class QueryableDataRepository {
  /// Retrieves analytics events matching the specified criteria
  /// 
  /// [eventTypes] - List of event types to include
  /// [startDate] - Beginning of date range
  /// [endDate] - End of date range
  /// [userIds] - Optional list of user IDs to filter by
  /// [properties] - Optional properties to filter by
  /// [limit] - Maximum number of events to return
  /// [privacyLevel] - Level of privacy anonymization to apply
  Future<List<AnalyticsEventModel>> queryEvents({
    required List<String> eventTypes,
    required DateTime startDate,
    required DateTime endDate,
    List<String>? userIds,
    Map<String, dynamic>? properties,
    int limit = 100,
    PrivacyLevel privacyLevel = PrivacyLevel.anonymized,
  });
  
  /// Retrieves aggregated metrics over time
  /// 
  /// [metricType] - Type of metric to aggregate (e.g., 'events', 'users', 'sessions')
  /// [period] - Time period to analyze
  /// [startDate] - Beginning of date range (required if period is TimePeriod.custom)
  /// [endDate] - End of date range (required if period is TimePeriod.custom)
  /// [aggregation] - Level of time aggregation
  /// [filters] - Additional filters to apply to the data
  Future<Map<DateTime, double>> getTimeSeriesMetric({
    required String metricType,
    required TimePeriod period,
    DateTime? startDate,
    DateTime? endDate,
    AggregationLevel aggregation = AggregationLevel.daily,
    Map<String, dynamic>? filters,
  });
  
  /// Retrieves user cohort metrics
  /// 
  /// [cohortDefinition] - Query definition for the cohort
  /// [metrics] - List of metrics to calculate for the cohort
  /// [period] - Time period to analyze
  /// [startDate] - Beginning of date range (required if period is TimePeriod.custom)
  /// [endDate] - End of date range (required if period is TimePeriod.custom)
  Future<Map<String, dynamic>> getUserCohortMetrics({
    required Map<String, dynamic> cohortDefinition,
    required List<String> metrics,
    required TimePeriod period,
    DateTime? startDate,
    DateTime? endDate,
  });
  
  /// Retrieves growth metrics for the platform or a specific entity
  /// 
  /// [entityType] - Type of entity (e.g., 'platform', 'space', 'event')
  /// [entityId] - ID of the entity (null for platform-wide metrics)
  /// [period] - Time period to analyze
  /// [startDate] - Beginning of date range (required if period is TimePeriod.custom)
  /// [endDate] - End of date range (required if period is TimePeriod.custom)
  Future<GrowthMetricsModel> getGrowthMetrics({
    required String entityType,
    String? entityId,
    required TimePeriod period,
    DateTime? startDate,
    DateTime? endDate,
  });
  
  /// Generates a behavioral model for prediction
  /// 
  /// [userId] - ID of the user to model
  /// [behaviors] - List of behaviors to include in the model
  /// [timePeriod] - Historical time period to base model on
  Future<Map<String, dynamic>> generateBehavioralModel({
    required String userId,
    required List<String> behaviors,
    required TimePeriod timePeriod,
  });
  
  /// Saves a user consent preference for data collection and usage
  /// 
  /// [userId] - ID of the user
  /// [dataTypes] - Map of data types and user consent (true/false)
  Future<void> saveUserConsentPreferences({
    required String userId,
    required Map<String, bool> dataTypes,
  });
  
  /// Gets a user's current consent preferences
  /// 
  /// [userId] - ID of the user
  Future<Map<String, bool>> getUserConsentPreferences({
    required String userId,
  });
  
  /// Anonymizes user data based on retention policy or user request
  /// 
  /// [userId] - ID of the user to anonymize
  /// [reason] - Reason for anonymization (e.g., 'retention_policy', 'user_request')
  Future<void> anonymizeUserData({
    required String userId,
    required String reason,
  });
} 