import 'package:hive_ui/core/result/result.dart';
import 'package:hive_ui/domain/analytics/analytics_event.dart';
import 'package:hive_ui/domain/failures/auth_failure.dart';

/// Repository interface for analytics operations
abstract class AnalyticsRepository {
  /// Tracks an analytics event
  Future<Result<void, Failure>> trackEvent(AnalyticsEvent event);
  
  /// Sets the user ID for analytics tracking
  Future<Result<void, Failure>> setUserId(String? userId);
  
  /// Sets a user property for analytics segmentation
  Future<Result<void, Failure>> setUserProperty(String property, String? value);
  
  /// Begins tracking a timed operation
  Future<Result<String, Failure>> startTrace(String traceName);
  
  /// Ends tracking a timed operation
  Future<Result<void, Failure>> stopTrace(String traceId);
  
  /// Get the onboarding completion rate
  Future<Result<double, Failure>> getOnboardingCompletionRate({
    DateTime? startDate,
    DateTime? endDate,
  });
  
  /// Get the average time spent in onboarding
  Future<Result<Duration, Failure>> getAverageOnboardingTime();
  
  /// Get the drop-off rate at each onboarding step
  Future<Result<Map<String, double>, Failure>> getOnboardingStepDropoffRates();
} 