import 'package:dartz/dartz.dart' as dartz;
import 'package:hive_ui/features/analytics/domain/entities/analytics_event_entity.dart';
import 'package:hive_ui/features/analytics/domain/entities/user_metrics_entity.dart';
import 'package:hive_ui/features/analytics/domain/failures/analytics_failures.dart';
import 'package:hive_ui/features/analytics/domain/entities/user_insights.dart';
import 'package:hive_ui/features/shared/domain/failures/failure.dart';

/// Repository interface for analytics operations at domain layer
abstract class AnalyticsRepositoryInterface {
  /// Track an analytics event
  /// 
  /// Returns a Right with success status on success or a Left with AnalyticsFailure on error
  Future<dartz.Either<AnalyticsFailure, bool>> trackEvent({
    required AnalyticsEventType eventType,
    required Map<String, dynamic> properties,
    String? userId,
  });
  
  /// Get user metrics data
  /// 
  /// Returns a Right with UserMetricsEntity on success or a Left with AnalyticsFailure on error
  Future<dartz.Either<AnalyticsFailure, UserMetricsEntity?>> getUserMetrics(String userId);
  
  /// Get recent events for a user
  /// 
  /// Returns a Right with list of events on success or a Left with AnalyticsFailure on error
  Future<dartz.Either<AnalyticsFailure, List<AnalyticsEventEntity>>> getUserEvents(
    String userId, {
    int limit = 50,
    AnalyticsEventType? eventType,
  });
  
  /// Export user analytics data
  /// 
  /// Returns a Right with export data on success or a Left with AnalyticsFailure on error
  Future<dartz.Either<AnalyticsFailure, Map<String, dynamic>>> exportUserAnalytics(String userId);

  /// Get insights for a user
  /// 
  /// Returns a Right with user insights on success or a Left with AnalyticsFailure on error
  Future<dartz.Either<AnalyticsFailure, UserInsights>> getUserInsights(String userId);
} 