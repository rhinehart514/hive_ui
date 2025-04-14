import 'package:hive_ui/features/analytics/domain/entities/growth_metrics_entity.dart';
import 'package:hive_ui/features/analytics/domain/failures/analytics_failures.dart';
import 'package:hive_ui/features/shared/domain/failures/failure.dart';

/// Repository interface for managing growth metrics
abstract class GrowthMetricsRepository {
  /// Get metrics for a specific date
  /// 
  /// Returns a Right with metrics on success or a Left with AnalyticsFailure on error
  Future<Either<AnalyticsFailure, GrowthMetricsEntity>> getMetricsForDate(DateTime date);

  /// Get metrics for a date range
  /// 
  /// Returns a Right with list of metrics on success or a Left with AnalyticsFailure on error
  Future<Either<AnalyticsFailure, List<GrowthMetricsEntity>>> getMetricsForDateRange(
      DateTime startDate, DateTime endDate);

  /// Get the latest metrics
  /// 
  /// Returns a Right with metrics on success or a Left with AnalyticsFailure on error
  Future<Either<AnalyticsFailure, GrowthMetricsEntity>> getLatestMetrics();

  /// Save metrics
  /// 
  /// Returns a Right with success status on success or a Left with AnalyticsFailure on error
  Future<Either<AnalyticsFailure, bool>> saveMetrics(GrowthMetricsEntity metrics);

  /// Watch the latest metrics (stream)
  Stream<Either<AnalyticsFailure, GrowthMetricsEntity>> watchLatestMetrics();

  /// Get growth trends for the specified number of days
  /// 
  /// Returns a Right with trends data on success or a Left with AnalyticsFailure on error
  Future<Either<AnalyticsFailure, Map<String, dynamic>>> getGrowthTrends(int days);

  /// Update acquisition channel count for a specific date
  /// 
  /// Returns a Right with success status on success or a Left with AnalyticsFailure on error
  Future<Either<AnalyticsFailure, bool>> updateAcquisitionChannel(DateTime date, String channel, int count);

  /// Increment acquisition channel count for a specific date
  /// 
  /// Returns a Right with success status on success or a Left with AnalyticsFailure on error
  Future<Either<AnalyticsFailure, bool>> incrementAcquisitionChannel(DateTime date, String channel);

  /// Update user segment count for a specific date
  /// 
  /// Returns a Right with success status on success or a Left with AnalyticsFailure on error
  Future<Either<AnalyticsFailure, bool>> updateUserSegment(DateTime date, String segment, int count);

  /// Increment user segment count for a specific date
  /// 
  /// Returns a Right with success status on success or a Left with AnalyticsFailure on error
  Future<Either<AnalyticsFailure, bool>> incrementUserSegment(DateTime date, String segment);

  /// Update engagement metric value for a specific date
  /// 
  /// Returns a Right with success status on success or a Left with AnalyticsFailure on error
  Future<Either<AnalyticsFailure, bool>> updateEngagementMetric(DateTime date, String metric, double value);

  /// Increment daily active users count for a specific date
  /// 
  /// Returns a Right with success status on success or a Left with AnalyticsFailure on error
  Future<Either<AnalyticsFailure, bool>> incrementDailyActiveUsers(DateTime date);

  /// Increment new users count for a specific date
  /// 
  /// Returns a Right with success status on success or a Left with AnalyticsFailure on error
  Future<Either<AnalyticsFailure, bool>> incrementNewUsers(DateTime date);

  /// Increment returning users count for a specific date
  /// 
  /// Returns a Right with success status on success or a Left with AnalyticsFailure on error
  Future<Either<AnalyticsFailure, bool>> incrementReturningUsers(DateTime date);
} 