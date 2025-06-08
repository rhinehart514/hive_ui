import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// Analytics service for tracking authentication and onboarding events
class AuthAnalyticsService {
  final FirebaseAnalytics _analytics;

  /// Creates an AuthAnalyticsService instance
  AuthAnalyticsService(this._analytics);

  /// Tracks a login event
  Future<void> trackLogin({
    required String method,
    Map<String, dynamic>? additionalParams,
  }) async {
    try {
      await _analytics.logLogin(loginMethod: method);

      // Log additional custom parameters if provided
      if (additionalParams != null && additionalParams.isNotEmpty) {
        // Ensure correct type for parameters
        final Map<String, Object> typedParams = Map<String, Object>.fromEntries(
          additionalParams.entries
            .where((entry) => entry.value != null) // Filter out null values
            .map((entry) => MapEntry(entry.key, entry.value as Object)),
        );
        await _analytics.logEvent(
          name: 'login_extended',
          parameters: typedParams.isNotEmpty ? typedParams : null,
        );
      }

      debugPrint(
          'Analytics: Login event tracked successfully (method: $method)');
    } catch (e) {
      debugPrint('Analytics: Failed to track login event: $e');
    }
  }

  /// Tracks a sign up event
  Future<void> trackSignUp({
    required String method,
    Map<String, dynamic>? additionalParams,
  }) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);

      // Log additional custom parameters if provided
      if (additionalParams != null && additionalParams.isNotEmpty) {
        // Ensure correct type for parameters
        final Map<String, Object> typedParams = Map<String, Object>.fromEntries(
          additionalParams.entries
            .where((entry) => entry.value != null)
            .map((entry) => MapEntry(entry.key, entry.value as Object)),
        );
        await _analytics.logEvent(
          name: 'sign_up_extended',
          parameters: typedParams.isNotEmpty ? typedParams : null,
        );
      }

      debugPrint(
          'Analytics: Sign up event tracked successfully (method: $method)');
    } catch (e) {
      debugPrint('Analytics: Failed to track sign up event: $e');
    }
  }

  /// Tracks a password reset request
  Future<void> trackPasswordReset({String? email}) async {
    try {
      final Map<String, dynamic> params = {};
      if (email != null) {
        params['email_domain'] = email.split('@').last;
      }

      // Ensure correct type for parameters
      final Map<String, Object> typedParams = Map<String, Object>.fromEntries(
        params.entries
          .where((entry) => entry.value != null)
          .map((entry) => MapEntry(entry.key, entry.value as Object)),
      );
      await _analytics.logEvent(
        name: 'password_reset_requested',
        parameters: typedParams.isNotEmpty ? typedParams : null,
      );

      debugPrint('Analytics: Password reset event tracked successfully');
    } catch (e) {
      debugPrint('Analytics: Failed to track password reset event: $e');
    }
  }

  /// Tracks an auth error
  Future<void> trackAuthError({
    required String method,
    required String errorCode,
    String? errorMessage,
    Map<String, dynamic>? additionalParams,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'method': method,
        'error_code': errorCode,
        'error_message': errorMessage ?? 'Unknown error',
      };

      if (additionalParams != null) {
        params.addAll(additionalParams);
      }

      // Ensure correct type for parameters
      final Map<String, Object> typedParams = Map<String, Object>.fromEntries(
        params.entries
          .where((entry) => entry.value != null)
          .map((entry) => MapEntry(entry.key, entry.value as Object)),
      );
      await _analytics.logEvent(
        name: 'auth_error',
        parameters: typedParams.isNotEmpty ? typedParams : null,
      );

      debugPrint(
          'Analytics: Auth error event tracked successfully (method: $method, code: $errorCode)');
    } catch (e) {
      debugPrint('Analytics: Failed to track auth error event: $e');
    }
  }

  /// Tracks an onboarding step completion
  Future<void> trackOnboardingStep({
    required String stepName,
    required int stepNumber,
    required int totalSteps,
    int? timeSpentSeconds,
  }) async {
    try {
      // Ensure correct type for parameters, handling potential null for timeSpentSeconds
      final Map<String, Object> typedParams = {
          'step_name': stepName,
          'step_number': stepNumber,
          'total_steps': totalSteps,
          if (timeSpentSeconds != null) 'time_spent_seconds': timeSpentSeconds,
          'completion_percentage': (stepNumber / totalSteps * 100).round(),
      };
      await _analytics.logEvent(
        name: 'onboarding_step_completed',
        parameters: typedParams,
      );

      debugPrint(
          'Analytics: Onboarding step event tracked successfully (step: $stepName)');
    } catch (e) {
      debugPrint('Analytics: Failed to track onboarding step event: $e');
    }
  }

  /// Tracks onboarding completion
  Future<void> trackOnboardingCompleted({
    required int totalTimeSeconds,
    Map<String, dynamic>? profileData,
  }) async {
    try {
      // Create parameters map
      final Map<String, dynamic> params = {
        'total_time_seconds': totalTimeSeconds,
      };

      // Add sanitized profile data (removing any PII)
      if (profileData != null) {
        if (profileData.containsKey('interests')) {
          params['has_interests'] = true;
          params['interest_count'] =
              (profileData['interests'] as List?)?.length ?? 0;
        }

        if (profileData.containsKey('profile_photo')) {
          params['has_profile_photo'] = true;
        }
      }

      // Ensure correct type for parameters
      final Map<String, Object> typedParams = Map<String, Object>.fromEntries(
        params.entries
          .where((entry) => entry.value != null)
          .map((entry) => MapEntry(entry.key, entry.value as Object)),
      );
      await _analytics.logEvent(
        name: 'onboarding_completed',
        parameters: typedParams.isNotEmpty ? typedParams : null,
      );

      debugPrint('Analytics: Onboarding completion event tracked successfully');
    } catch (e) {
      debugPrint('Analytics: Failed to track onboarding completion event: $e');
    }
  }

  /// Tracks onboarding abandonment
  Future<void> trackOnboardingAbandoned({
    required String lastStep,
    required int lastStepNumber,
    required int totalSteps,
    int? timeSpentSeconds,
  }) async {
    try {
      // Ensure correct type for parameters, handling potential null for timeSpentSeconds
      final Map<String, Object> typedParams = {
          'last_step': lastStep,
          'last_step_number': lastStepNumber,
          'total_steps': totalSteps,
          if (timeSpentSeconds != null) 'time_spent_seconds': timeSpentSeconds,
          'completion_percentage': (lastStepNumber / totalSteps * 100).round(),
      };
      await _analytics.logEvent(
        name: 'onboarding_abandoned',
        parameters: typedParams,
      );

      debugPrint(
          'Analytics: Onboarding abandonment event tracked successfully (last step: $lastStep)');
    } catch (e) {
      debugPrint('Analytics: Failed to track onboarding abandonment event: $e');
    }
  }

  /// Tracks email verification sent
  Future<void> trackEmailVerificationSent() async {
    try {
      await _analytics.logEvent(name: 'email_verification_sent');
      debugPrint(
          'Analytics: Email verification sent event tracked successfully');
    } catch (e) {
      debugPrint(
          'Analytics: Failed to track email verification sent event: $e');
    }
  }

  /// Tracks email verification completed
  Future<void> trackEmailVerificationCompleted() async {
    try {
      await _analytics.logEvent(name: 'email_verification_completed');
      debugPrint(
          'Analytics: Email verification completed event tracked successfully');
    } catch (e) {
      debugPrint(
          'Analytics: Failed to track email verification completed event: $e');
    }
  }

  /// Tracks a generic event
  Future<void> trackEvent(
    String eventName, {
    Map<String, dynamic>? parameters,
  }) async {
    try {
      // Ensure correct type for parameters
      Map<String, Object>? typedParams;
      if (parameters != null && parameters.isNotEmpty) {
         typedParams = Map<String, Object>.fromEntries(
          parameters.entries
            .where((entry) => entry.value != null) // Filter out null values
            .map((entry) => MapEntry(entry.key, entry.value as Object)),
        );
      }

      await _analytics.logEvent(
        name: eventName,
        parameters: (typedParams?.isNotEmpty ?? false) ? typedParams : null,
      );

      debugPrint(
          'Analytics: Event tracked successfully (name: $eventName)');
    } catch (e) {
      debugPrint('Analytics: Failed to track event: $e');
    }
  }
}
