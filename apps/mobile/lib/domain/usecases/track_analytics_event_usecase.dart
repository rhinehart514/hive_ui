import 'package:hive_ui/core/result/result.dart';
import 'package:hive_ui/domain/analytics/analytics_event.dart';
import 'package:hive_ui/domain/failures/auth_failure.dart';
import 'package:hive_ui/domain/repositories/analytics_repository.dart';

/// Use case for tracking analytics events
class TrackAnalyticsEventUseCase {
  final AnalyticsRepository _analyticsRepository;
  
  /// Creates a new instance with the given repository
  TrackAnalyticsEventUseCase(this._analyticsRepository);
  
  /// Executes the use case to track an analytics event
  Future<Result<void, Failure>> execute(AnalyticsEvent event) async {
    try {
      return await _analyticsRepository.trackEvent(event);
    } catch (e) {
      return Result.left(ServerFailure('Failed to track analytics event: ${e.toString()}'));
    }
  }
  
  /// Tracks an onboarding started event
  Future<Result<void, Failure>> trackOnboardingStarted({String? userId}) async {
    final event = AnalyticsEvent.onboardingStarted(userId: userId);
    return execute(event);
  }
  
  /// Tracks an onboarding step completed event
  Future<Result<void, Failure>> trackOnboardingStepCompleted({
    required String stepName,
    required int stepNumber,
    required int totalSteps,
    required Duration timeSpent,
    String? userId,
  }) async {
    final event = AnalyticsEvent.onboardingStepCompleted(
      stepName: stepName,
      stepNumber: stepNumber,
      totalSteps: totalSteps,
      timeSpent: timeSpent,
      userId: userId,
    );
    return execute(event);
  }
  
  /// Tracks an onboarding completed event
  Future<Result<void, Failure>> trackOnboardingCompleted({
    required Duration totalTime,
    required bool requestedVerification,
    required String? userId,
    int interestsCount = 0,
  }) async {
    final event = AnalyticsEvent.onboardingCompleted(
      totalTime: totalTime,
      requestedVerification: requestedVerification,
      userId: userId,
      interestsCount: interestsCount,
    );
    return execute(event);
  }
  
  /// Tracks an onboarding abandoned event
  Future<Result<void, Failure>> trackOnboardingAbandoned({
    required String lastCompletedStep,
    required int lastStepNumber,
    required Duration timeSpent,
    String? userId,
    String? abandonReason,
  }) async {
    final event = AnalyticsEvent.onboardingAbandoned(
      lastCompletedStep: lastCompletedStep,
      lastStepNumber: lastStepNumber,
      timeSpent: timeSpent,
      userId: userId,
      abandonReason: abandonReason,
    );
    return execute(event);
  }
} 