import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:hive_ui/core/result/result.dart';
import 'package:hive_ui/domain/analytics/analytics_event.dart';
import 'package:hive_ui/domain/failures/auth_failure.dart';
import 'package:hive_ui/domain/repositories/analytics_repository.dart';

/// Implementation of AnalyticsRepository using Firebase Analytics
class FirebaseAnalyticsRepository implements AnalyticsRepository {
  final FirebaseAnalytics _analytics;
  final FirebaseCrashlytics _crashlytics;
  
  // Store active traces by ID for performance monitoring
  final Map<String, String> _activeTraces = {};
  
  /// Creates a new instance with the given Firebase services
  FirebaseAnalyticsRepository(this._analytics, this._crashlytics);
  
  @override
  Future<Result<void, Failure>> trackEvent(AnalyticsEvent event) async {
    try {
      // Convert parameters to Map<String, Object>
      final Map<String, Object> parameters = {}; 
      event.parameters.forEach((key, value) {
        if (value != null) {
          parameters[key] = value;
        }
      });
      
      await _analytics.logEvent(
        name: event.eventName,
        parameters: parameters,
      );
      return const Result.right(null);
    } catch (e) {
      _crashlytics.recordError(e, StackTrace.current, reason: 'Analytics event tracking failed');
      return Result.left(ServerFailure('Failed to track analytics event: ${e.toString()}'));
    }
  }
  
  @override
  Future<Result<void, Failure>> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
      return const Result.right(null);
    } catch (e) {
      _crashlytics.recordError(e, StackTrace.current, reason: 'Setting analytics user ID failed');
      return Result.left(ServerFailure('Failed to set user ID: ${e.toString()}'));
    }
  }
  
  @override
  Future<Result<void, Failure>> setUserProperty(String property, String? value) async {
    try {
      await _analytics.setUserProperty(name: property, value: value);
      return const Result.right(null);
    } catch (e) {
      _crashlytics.recordError(e, StackTrace.current, reason: 'Setting user property failed');
      return Result.left(ServerFailure('Failed to set user property: ${e.toString()}'));
    }
  }
  
  @override
  Future<Result<String, Failure>> startTrace(String traceName) async {
    try {
      // Generate a unique ID for this trace instance
      final traceId = '${traceName}_${DateTime.now().millisecondsSinceEpoch}';
      
      // Store the trace name
      _activeTraces[traceId] = traceName;
      
      // Start a custom trace for performance monitoring
      await _analytics.logEvent(
        name: 'trace_start',
        parameters: <String, Object>{
          'trace_name': traceName,
          'trace_id': traceId,
          'start_time': DateTime.now().millisecondsSinceEpoch,
        },
      );
      
      return Result.right(traceId);
    } catch (e) {
      _crashlytics.recordError(e, StackTrace.current, reason: 'Starting performance trace failed');
      return Result.left(ServerFailure('Failed to start trace: ${e.toString()}'));
    }
  }
  
  @override
  Future<Result<void, Failure>> stopTrace(String traceId) async {
    try {
      // Retrieve the trace name
      final traceName = _activeTraces[traceId];
      
      if (traceName == null) {
        return const Result.left(AuthFailure('Trace ID not found'));
      }
      
      // Log the trace completion
      await _analytics.logEvent(
        name: 'trace_stop',
        parameters: <String, Object>{
          'trace_name': traceName,
          'trace_id': traceId,
          'stop_time': DateTime.now().millisecondsSinceEpoch,
          'duration_ms': DateTime.now().millisecondsSinceEpoch - 
              int.parse(traceId.split('_').last),
        },
      );
      
      // Remove from active traces
      _activeTraces.remove(traceId);
      
      return const Result.right(null);
    } catch (e) {
      _crashlytics.recordError(e, StackTrace.current, reason: 'Stopping performance trace failed');
      return Result.left(ServerFailure('Failed to stop trace: ${e.toString()}'));
    }
  }
  
  @override
  Future<Result<double, Failure>> getOnboardingCompletionRate({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // In a real implementation, this would query Firebase Analytics or BigQuery
      // For now, we return a placeholder value
      
      // Mock implementation - would be replaced with actual Firebase Analytics data
      // This would typically involve querying BigQuery with the Firebase Analytics data
      // or using Firebase Analytics dashboard APIs
      
      // Placeholder calculation - 85% completion rate
      return const Result.right(0.85);
    } catch (e) {
      _crashlytics.recordError(e, StackTrace.current, reason: 'Getting onboarding completion rate failed');
      return Result.left(ServerFailure('Failed to get onboarding completion rate: ${e.toString()}'));
    }
  }
  
  @override
  Future<Result<Duration, Failure>> getAverageOnboardingTime() async {
    try {
      // Mock implementation - would be replaced with actual Firebase Analytics data
      // This would typically involve querying BigQuery with the Firebase Analytics data
      // or using Analytics dashboard APIs
      
      // Placeholder value - average onboarding time of 2 minutes
      return const Result.right(Duration(minutes: 2));
    } catch (e) {
      _crashlytics.recordError(e, StackTrace.current, reason: 'Getting average onboarding time failed');
      return Result.left(ServerFailure('Failed to get average onboarding time: ${e.toString()}'));
    }
  }
  
  @override
  Future<Result<Map<String, double>, Failure>> getOnboardingStepDropoffRates() async {
    try {
      // Mock implementation - would be replaced with actual Firebase Analytics data
      // This would typically involve querying BigQuery with the Firebase Analytics data
      // or using Analytics dashboard APIs
      
      // Placeholder values - step drop-off rates
      return const Result.right({
        'name_step': 0.05,     // 5% drop-off at name step
        'residence_step': 0.07, // 7% drop-off at residence step
        'major_step': 0.08,    // 8% drop-off at major step
        'interests_step': 0.10, // 10% drop-off at interests step
        'role_step': 0.05,     // 5% drop-off at role step
      });
    } catch (e) {
      _crashlytics.recordError(e, StackTrace.current, reason: 'Getting onboarding step drop-off rates failed');
      return Result.left(ServerFailure('Failed to get step drop-off rates: ${e.toString()}'));
    }
  }
} 