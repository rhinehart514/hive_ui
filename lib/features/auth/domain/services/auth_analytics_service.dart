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
        await _analytics.logEvent(
          name: 'login_extended',
          parameters: additionalParams,
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
        await _analytics.logEvent(
          name: 'sign_up_extended',
          parameters: additionalParams,
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

      await _analytics.logEvent(
        name: 'password_reset_requested',
        parameters: params,
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
  }) async {
    try {
      await _analytics.logEvent(
        name: 'auth_error',
        parameters: {
          'method': method,
          'error_code': errorCode,
          'error_message': errorMessage ?? 'Unknown error',
        },
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
      await _analytics.logEvent(
        name: 'onboarding_step_completed',
        parameters: {
          'step_name': stepName,
          'step_number': stepNumber,
          'total_steps': totalSteps,
          'time_spent_seconds': timeSpentSeconds,
          'completion_percentage': (stepNumber / totalSteps * 100).round(),
        },
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

      await _analytics.logEvent(
        name: 'onboarding_completed',
        parameters: params,
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
      await _analytics.logEvent(
        name: 'onboarding_abandoned',
        parameters: {
          'last_step': lastStep,
          'last_step_number': lastStepNumber,
          'total_steps': totalSteps,
          'time_spent_seconds': timeSpentSeconds,
          'completion_percentage': (lastStepNumber / totalSteps * 100).round(),
        },
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
}
