import 'package:equatable/equatable.dart';

/// Enum representing different types of analytics events for the app.
enum AnalyticsEventType {
  /// Event when onboarding process starts
  onboardingStarted,
  
  /// Event when a step in the onboarding process is completed
  onboardingStepCompleted,
  
  /// Event when the entire onboarding process is completed
  onboardingCompleted,
  
  /// Event when onboarding is abandoned before completion
  onboardingAbandoned,
  
  /// Event when user signs in
  signIn,
  
  /// Event when user signs out
  signOut,
  
  /// Event when a screen is viewed
  screenView,
  
  /// Event when an error occurs
  error,
}

/// Entity representing an analytics event to be tracked.
class AnalyticsEvent extends Equatable {
  /// The type of event
  final AnalyticsEventType type;
  
  /// The timestamp when the event occurred
  final DateTime timestamp;
  
  /// Additional parameters for the event
  final Map<String, dynamic> parameters;

  /// Creates a new analytics event.
  AnalyticsEvent({
    required this.type,
    required this.parameters,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Creates an onboarding started event.
  factory AnalyticsEvent.onboardingStarted({String? userId}) {
    return AnalyticsEvent(
      type: AnalyticsEventType.onboardingStarted,
      parameters: {
        'user_id': userId,
      },
    );
  }

  /// Creates an onboarding step completed event.
  factory AnalyticsEvent.onboardingStepCompleted({
    required String stepName,
    required int stepNumber,
    required int totalSteps,
    required Duration timeSpent,
    String? userId,
  }) {
    return AnalyticsEvent(
      type: AnalyticsEventType.onboardingStepCompleted,
      parameters: {
        'step_name': stepName,
        'step_number': stepNumber,
        'total_steps': totalSteps,
        'time_spent_ms': timeSpent.inMilliseconds,
        'user_id': userId,
      },
    );
  }

  /// Creates an onboarding completed event.
  factory AnalyticsEvent.onboardingCompleted({
    required Duration totalTime,
    required bool requestedVerification,
    required String? userId,
    int interestsCount = 0,
  }) {
    return AnalyticsEvent(
      type: AnalyticsEventType.onboardingCompleted,
      parameters: {
        'total_time_ms': totalTime.inMilliseconds,
        'requested_verification': requestedVerification,
        'interests_count': interestsCount,
        'user_id': userId,
      },
    );
  }

  /// Creates an onboarding abandoned event.
  factory AnalyticsEvent.onboardingAbandoned({
    required String lastCompletedStep,
    required int lastStepNumber,
    required Duration timeSpent,
    String? userId,
    String? abandonReason,
  }) {
    return AnalyticsEvent(
      type: AnalyticsEventType.onboardingAbandoned,
      parameters: {
        'last_completed_step': lastCompletedStep,
        'last_step_number': lastStepNumber,
        'time_spent_ms': timeSpent.inMilliseconds,
        'abandon_reason': abandonReason,
        'user_id': userId,
      },
    );
  }

  /// Creates an error event.
  factory AnalyticsEvent.error({
    required String errorType,
    required String errorMessage,
    String? userId,
    String? screenName,
  }) {
    return AnalyticsEvent(
      type: AnalyticsEventType.error,
      parameters: {
        'error_type': errorType,
        'error_message': errorMessage,
        'user_id': userId,
        'screen_name': screenName,
      },
    );
  }

  /// Returns the event name as a string for tracking purposes.
  String get eventName {
    switch (type) {
      case AnalyticsEventType.onboardingStarted:
        return 'onboarding_started';
      case AnalyticsEventType.onboardingStepCompleted:
        return 'onboarding_step_completed';
      case AnalyticsEventType.onboardingCompleted:
        return 'onboarding_completed';
      case AnalyticsEventType.onboardingAbandoned:
        return 'onboarding_abandoned';
      case AnalyticsEventType.signIn:
        return 'sign_in';
      case AnalyticsEventType.signOut:
        return 'sign_out';
      case AnalyticsEventType.screenView:
        return 'screen_view';
      case AnalyticsEventType.error:
        return 'error';
    }
  }

  @override
  List<Object?> get props => [type, timestamp, parameters];
} 