import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:hive_ui/utils/realtime_db_windows_fix.dart';

/// Service for tracking analytics in the app
class AnalyticsService {
  static const String _analyticsStorageKey = 'analytics_data';
  static const String _sessionStorageKey = 'current_session';
  static const String _onboardingEventsKey = 'onboarding_events';
  static final AnalyticsService _instance = AnalyticsService._internal();

  /// Singleton instance of the analytics service
  factory AnalyticsService() => _instance;

  AnalyticsService._internal();

  /// Initialize analytics service
  Future<void> initialize() async {
    await _startSession();
  }

  /// Track a screen view
  Future<void> trackScreenView(String screenName) async {
    await _trackEvent('screen_view', {
      'screen_name': screenName,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track an event
  Future<void> trackEvent(
      String eventName, Map<String, dynamic> parameters) async {
    await _trackEvent(eventName, {
      ...parameters,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track user engagement
  Future<void> trackEngagement(
      String contentType, String contentId, String action) async {
    await _trackEvent('engagement', {
      'content_type': contentType,
      'content_id': contentId,
      'action': action,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track app performance
  Future<void> trackPerformance(String operation, int durationMs) async {
    await _trackEvent('performance', {
      'operation': operation,
      'duration_ms': durationMs,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track an error that occurred in the app
  Future<void> trackError(dynamic error, StackTrace? stackTrace,
      {String? method}) async {
    try {
      // Sanitize and truncate the error message to prevent analytics rejection
      final errorString = error.toString();
      final safeErrorMsg = errorString.length > 500
          ? errorString.substring(0, 500)
          : errorString;

      // Get the first few lines of the stack trace for better error identification
      final stackString = stackTrace?.toString() ?? 'No stack trace';
      final stackPreview = stackString.length > 500
          ? stackString.substring(0, 500)
          : stackString;

      // Send to analytics using existing _trackEvent method
      await _trackEvent('error', {
        'error_type': method ?? 'unknown',
        'error_message': safeErrorMsg,
        'stack_trace': stackPreview,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Don't cause cascading errors by failing in the error tracker
    }
  }

  /// Implementation of event tracking
  Future<void> _trackEvent(
      String eventName, Map<String, dynamic> parameters) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? analyticsJson = prefs.getString(_analyticsStorageKey);

      final Map<String, dynamic> analytics = analyticsJson != null
          ? json.decode(analyticsJson) as Map<String, dynamic>
          : {'events': <Map<String, dynamic>>[]};

      final List<dynamic> events = analytics['events'] as List<dynamic>;

      events.add({
        'event_name': eventName,
        'parameters': parameters,
      });

      // Limit stored events to prevent excessive storage use
      if (events.length > 1000) {
        events.removeRange(0, events.length - 1000);
      }

      analytics['events'] = events;

      await prefs.setString(_analyticsStorageKey, json.encode(analytics));
      
      // Track onboarding events specifically for completion rate monitoring
      if (eventName.startsWith('onboarding_')) {
        await _trackOnboardingEvent(eventName, parameters);
      }
    } catch (e) {
      // Don't use trackError here to avoid infinite recursion
    }
  }
  
  /// Track onboarding-specific events for completion rate monitoring
  Future<void> _trackOnboardingEvent(
      String eventName, Map<String, dynamic> parameters) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? onboardingJson = prefs.getString(_onboardingEventsKey);

      final Map<String, dynamic> onboardingData = onboardingJson != null
          ? json.decode(onboardingJson) as Map<String, dynamic>
          : {
              'starts': 0,
              'completions': 0,
              'abandonments': 0,
              'steps': <String, int>{},
              'user_ids': <String>[],
              'last_updated': DateTime.now().toIso8601String(),
            };

      final String userId = parameters['user_id'] as String? ?? 'unknown_user';
      if (!onboardingData['user_ids'].contains(userId)) {
        onboardingData['user_ids'].add(userId);
      }

      switch (eventName) {
        case 'onboarding_started':
          onboardingData['starts'] = (onboardingData['starts'] as int) + 1;
          break;
        case 'onboarding_complete':
          onboardingData['completions'] = (onboardingData['completions'] as int) + 1;
          break;
        case 'onboarding_abandoned':
          onboardingData['abandonments'] = (onboardingData['abandonments'] as int) + 1;
          break;
        case 'onboarding_step_completed':
          final String step = parameters['step'] as String? ?? 'unknown_step';
          Map<String, int> steps = Map<String, int>.from(onboardingData['steps'] as Map);
          steps[step] = (steps[step] ?? 0) + 1;
          onboardingData['steps'] = steps;
          break;
      }

      onboardingData['last_updated'] = DateTime.now().toIso8601String();
      await prefs.setString(_onboardingEventsKey, json.encode(onboardingData));
    } catch (e) {
      // Silently fail for analytics to avoid app disruption
    }
  }

  /// Start a new session
  Future<void> _startSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionData = {
        'start_time': DateTime.now().toIso8601String(),
        'platform': defaultTargetPlatform.toString(),
      };

      await prefs.setString(_sessionStorageKey, json.encode(sessionData));

      await _trackEvent('session_start', sessionData);
    } catch (e) {
      // Silent fail for analytics
    }
  }

  /// End the current session
  Future<void> endSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? sessionJson = prefs.getString(_sessionStorageKey);

      if (sessionJson != null) {
        final sessionData = json.decode(sessionJson) as Map<String, dynamic>;
        final startTime = DateTime.parse(sessionData['start_time'] as String);
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime).inSeconds;

        await _trackEvent('session_end', {
          'start_time': sessionData['start_time'],
          'end_time': endTime.toIso8601String(),
          'duration_seconds': duration,
          'platform': sessionData['platform'],
        });
      }
    } catch (e) {
      // Silent fail for analytics
    }
  }

  /// Get analytics data for debug purposes
  Future<Map<String, dynamic>> getAnalyticsData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? analyticsJson = prefs.getString(_analyticsStorageKey);

      if (analyticsJson != null) {
        return json.decode(analyticsJson) as Map<String, dynamic>;
      }
    } catch (e) {
      // Silent fail for analytics
    }

    return {'events': <Map<String, dynamic>>[]};
  }
  
  /// Get onboarding analytics data
  Future<Map<String, dynamic>> getOnboardingAnalytics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? onboardingJson = prefs.getString(_onboardingEventsKey);

      if (onboardingJson != null) {
        return json.decode(onboardingJson) as Map<String, dynamic>;
      }
    } catch (e) {
      // Silent fail for analytics
    }

    return {
      'starts': 0,
      'completions': 0,
      'abandonments': 0,
      'steps': <String, int>{},
      'user_ids': <String>[],
      'last_updated': DateTime.now().toIso8601String(),
    };
  }
  
  /// Calculate onboarding completion rate
  Future<double> getOnboardingCompletionRate() async {
    final analytics = await getOnboardingAnalytics();
    final int starts = analytics['starts'] as int;
    final int completions = analytics['completions'] as int;
    
    if (starts == 0) return 0.0;
    return completions / starts;
  }

  /// Log an analytics event
  static void logEvent(String eventName, {Map<String, dynamic>? parameters}) {
    // For production, this would connect to Firebase Analytics or similar
    if (RealtimeDbWindowsFix.needsSpecialHandling && !RealtimeDbWindowsFix.isSupported) {
      // Still log the event even on Windows, it just won't be sent to Firebase
      debugPrint('📊 Analytics event (Windows local): $eventName - ${parameters ?? {}}');
      
      // Track the event locally
      AnalyticsService()
          .trackEvent(eventName, parameters ?? <String, dynamic>{});
      return;
    }
    
    // Track onboarding specific events
    if (eventName.startsWith('onboarding_')) {
      AnalyticsService()
          .trackEvent(eventName, parameters ?? <String, dynamic>{});
    }
  }

  /// Log onboarding started
  static void logOnboardingStarted(String userId) {
    logEvent('onboarding_started', parameters: {
      'user_id': userId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// Log onboarding step completed
  static void logOnboardingStepCompleted(String userId, String step, int stepNumber, int totalSteps) {
    logEvent('onboarding_step_completed', parameters: {
      'user_id': userId,
      'step': step,
      'step_number': stepNumber,
      'total_steps': totalSteps,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// Log onboarding completed
  static void logOnboardingCompleted(String userId, int timeSeconds) {
    logEvent('onboarding_complete', parameters: {
      'user_id': userId,
      'completion_time_seconds': timeSeconds,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// Log onboarding abandoned
  static void logOnboardingAbandoned(String userId, String lastStep) {
    logEvent('onboarding_abandoned', parameters: {
      'user_id': userId,
      'last_step': lastStep,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Log a screen view
  static void logScreenView(String screenName, {String? screenClass}) {
    if (RealtimeDbWindowsFix.needsSpecialHandling && !RealtimeDbWindowsFix.isSupported) {
      return;
    }
    
    AnalyticsService().trackScreenView(screenName);
  }

  /// Log a user property
  static void setUserProperty(String name, String value) {
    if (RealtimeDbWindowsFix.needsSpecialHandling && !RealtimeDbWindowsFix.isSupported) {
      return;
    }
    
    // In production, this would be implemented with Firebase Analytics
  }
}
