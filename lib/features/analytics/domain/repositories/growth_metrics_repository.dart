import 'package:hive_ui/features/analytics/domain/entities/growth_metrics_entity.dart';

/// Repository interface for managing growth metrics
abstract class GrowthMetricsRepository {
  /// Get metrics for a specific date
  Future<GrowthMetricsEntity> getMetricsForDate(DateTime date);

  /// Get metrics for a date range
  Future<List<GrowthMetricsEntity>> getMetricsForDateRange(
      DateTime startDate, DateTime endDate);

  /// Get the latest metrics
  Future<GrowthMetricsEntity> getLatestMetrics();

  /// Save metrics
  Future<void> saveMetrics(GrowthMetricsEntity metrics);

  /// Watch the latest metrics (stream)
  Stream<GrowthMetricsEntity> watchLatestMetrics();

  /// Get growth trends for the specified number of days
  Future<Map<String, dynamic>> getGrowthTrends(int days);

  /// Update acquisition channel count for a specific date
  Future<void> updateAcquisitionChannel(DateTime date, String channel, int count);

  /// Increment acquisition channel count for a specific date
  Future<void> incrementAcquisitionChannel(DateTime date, String channel);

  /// Update user segment count for a specific date
  Future<void> updateUserSegment(DateTime date, String segment, int count);

  /// Increment user segment count for a specific date
  Future<void> incrementUserSegment(DateTime date, String segment);

  /// Update engagement metric value for a specific date
  Future<void> updateEngagementMetric(DateTime date, String metric, double value);

  /// Increment daily active users count for a specific date
  Future<void> incrementDailyActiveUsers(DateTime date);

  /// Increment new users count for a specific date
  Future<void> incrementNewUsers(DateTime date);

  /// Increment returning users count for a specific date
  Future<void> incrementReturningUsers(DateTime date);
} 