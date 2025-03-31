import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service for tracking analytics in the app
class AnalyticsService {
  static const String _analyticsStorageKey = 'analytics_data';
  static const String _sessionStorageKey = 'current_session';
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

      // Log locally for debugging
      debugPrint('📊 Analytics - Error tracked: $safeErrorMsg');

      // Send to analytics using existing _trackEvent method
      await _trackEvent('error', {
        'error_type': method ?? 'unknown',
        'error_message': safeErrorMsg,
        'stack_trace': stackPreview,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Don't cause cascading errors by failing in the error tracker
      debugPrint('Error in analytics error tracking: $e');
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

      // In debug mode, log events to console
      if (kDebugMode) {
        print('Analytics event: $eventName - ${json.encode(parameters)}');
      }
    } catch (e, stackTrace) {
      // Don't use trackError here to avoid infinite recursion
      if (kDebugMode) {
        print('Error tracking analytics event: $e');
        print(stackTrace);
      }
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
      if (kDebugMode) {
        print('Error starting analytics session: $e');
      }
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
      if (kDebugMode) {
        print('Error ending analytics session: $e');
      }
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
      if (kDebugMode) {
        print('Error getting analytics data: $e');
      }
    }

    return {'events': <Map<String, dynamic>>[]};
  }

  /// Log an analytics event
  static void logEvent(String eventName, {Map<String, dynamic>? parameters}) {
    // In a real implementation, this would send events to Firebase Analytics or similar
    debugPrint(
        'ANALYTICS EVENT: $eventName ${parameters != null ? '- $parameters' : ''}');
  }

  /// Log a screen view
  static void logScreenView(String screenName, {String? screenClass}) {
    debugPrint(
        'ANALYTICS SCREEN: $screenName ${screenClass != null ? '[$screenClass]' : ''}');
  }

  /// Log a user property
  static void setUserProperty(String name, String value) {
    debugPrint('ANALYTICS USER PROPERTY: $name = $value');
  }
}
