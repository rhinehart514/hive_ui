import 'package:hive_ui/features/analytics/domain/entities/analytics_event_entity.dart';
import 'package:hive_ui/features/analytics/domain/entities/user_metrics_entity.dart';

/// Repository interface for analytics operations at domain layer
abstract class AnalyticsRepositoryInterface {
  /// Track an analytics event
  Future<void> trackEvent({
    required AnalyticsEventType eventType,
    required Map<String, dynamic> properties,
    String? userId,
  });
  
  /// Get user metrics data
  Future<UserMetricsEntity?> getUserMetrics(String userId);
  
  /// Get recent events for a user
  Future<List<AnalyticsEventEntity>> getUserEvents(
    String userId, {
    int limit = 50,
    AnalyticsEventType? eventType,
  });
  
  /// Export user analytics data
  Future<Map<String, dynamic>> exportUserAnalytics(String userId);
} 