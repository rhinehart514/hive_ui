import 'package:flutter/foundation.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/services/analytics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service for tracking and analyzing feed interactions for personalization
class FeedAnalytics {
  // Storage keys
  static const String _viewedEventsKey = 'viewed_events';
  static const String _interactionStatsKey = 'feed_interaction_stats';
  static const String _categoryPreferencesKey = 'category_preferences';
  static const String _organizerPreferencesKey = 'organizer_preferences';

  /// Track an event view
  static Future<void> trackEventView(Event event) async {
    try {
      // Log to analytics service
      AnalyticsService.logEvent('event_view', parameters: {
        'event_id': event.id,
        'event_title': event.title,
        'organizer': event.organizerName,
        'category': event.category,
      });

      // Store in local preferences
      await _addToViewHistory(event);

      // Update category and organizer preferences
      await _incrementCategoryPreference(event.category);
      await _incrementOrganizerPreference(event.organizerName);
    } catch (e) {
      debugPrint('Error tracking event view: $e');
    }
  }

  /// Track an event interaction (RSVP, share, etc)
  static Future<void> trackEventInteraction(
      Event event, String interactionType) async {
    try {
      // Log to analytics service
      AnalyticsService.logEvent('event_interaction', parameters: {
        'event_id': event.id,
        'event_title': event.title,
        'interaction_type': interactionType,
        'organizer': event.organizerName,
        'category': event.category,
      });

      // Store interaction stats
      await _updateInteractionStats(interactionType);

      // Update preferences with stronger weight for interactions
      await _incrementCategoryPreference(event.category, weight: 3);
      await _incrementOrganizerPreference(event.organizerName, weight: 2);

      // Add tags from the event to preferences
      for (final tag in event.tags) {
        if (tag.isNotEmpty) {
          await _incrementTagPreference(tag);
        }
      }
    } catch (e) {
      debugPrint('Error tracking event interaction: $e');
    }
  }

  /// Track feed refresh
  static Future<void> trackFeedRefresh({
    required bool userInitiated,
    required int itemCount,
  }) async {
    try {
      AnalyticsService.logEvent('feed_refresh', parameters: {
        'user_initiated': userInitiated,
        'item_count': itemCount,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Update interaction stats
      await _updateInteractionStats('feed_refresh');
    } catch (e) {
      debugPrint('Error tracking feed refresh: $e');
    }
  }

  /// Track time spent viewing the feed
  static Future<void> trackFeedViewTime(int seconds) async {
    try {
      // Only track if significant time spent (>5 seconds)
      if (seconds < 5) return;

      AnalyticsService.logEvent('feed_view_time', parameters: {
        'seconds': seconds,
        'timestamp': DateTime.now().toIso8601String(),
      });

      final prefs = await SharedPreferences.getInstance();
      const key = 'feed_view_time_stats';
      final stats = prefs.getString(key);

      final viewTimeStats = stats != null
          ? json.decode(stats) as Map<String, dynamic>
          : <String, dynamic>{
              'total_seconds': 0,
              'session_count': 0,
              'last_session': null,
            };

      // Update stats
      viewTimeStats['total_seconds'] =
          (viewTimeStats['total_seconds'] as int) + seconds;
      viewTimeStats['session_count'] =
          (viewTimeStats['session_count'] as int) + 1;
      viewTimeStats['last_session'] = DateTime.now().toIso8601String();

      // Calculate average
      final avgSessionTime = (viewTimeStats['total_seconds'] as int) /
          (viewTimeStats['session_count'] as int);
      viewTimeStats['avg_session_time'] = avgSessionTime;

      // Save updated stats
      await prefs.setString(key, json.encode(viewTimeStats));
    } catch (e) {
      debugPrint('Error tracking feed view time: $e');
    }
  }

  /// Track feed session time
  static Future<void> trackFeedSessionTime(int seconds) async {
    try {
      // Log to analytics service
      AnalyticsService.logEvent('feed_session', parameters: {
        'duration_seconds': seconds,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Also update local storage for tracking session patterns
      final prefs = await SharedPreferences.getInstance();
      final sessions = prefs.getStringList('feed_sessions') ?? [];

      // Keep the last 20 sessions
      if (sessions.length >= 20) {
        sessions.removeAt(0);
      }

      sessions.add(json.encode({
        'duration': seconds,
        'timestamp': DateTime.now().toIso8601String(),
      }));

      await prefs.setStringList('feed_sessions', sessions);
    } catch (e) {
      debugPrint('Error tracking feed session time: $e');
    }
  }

  /// Get user's category preferences
  static Future<Map<String, int>> getCategoryPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsString = prefs.getString(_categoryPreferencesKey);

      if (prefsString != null) {
        final Map<String, dynamic> data = json.decode(prefsString);
        return data.map((key, value) => MapEntry(key, value as int));
      }
    } catch (e) {
      debugPrint('Error getting category preferences: $e');
    }

    return {};
  }

  /// Get user's organizer preferences
  static Future<Map<String, int>> getOrganizerPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsString = prefs.getString(_organizerPreferencesKey);

      if (prefsString != null) {
        final Map<String, dynamic> data = json.decode(prefsString);
        return data.map((key, value) => MapEntry(key, value as int));
      }
    } catch (e) {
      debugPrint('Error getting organizer preferences: $e');
    }

    return {};
  }

  /// Get engagement statistics
  static Future<Map<String, dynamic>> getEngagementStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsString = prefs.getString(_interactionStatsKey);

      if (statsString != null) {
        return json.decode(statsString) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error getting engagement stats: $e');
    }

    return {};
  }

  /// Clear all analytics data (for privacy or testing)
  static Future<void> clearAnalyticsData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_viewedEventsKey);
      await prefs.remove(_interactionStatsKey);
      await prefs.remove(_categoryPreferencesKey);
      await prefs.remove(_organizerPreferencesKey);
      debugPrint('Cleared all feed analytics data');
    } catch (e) {
      debugPrint('Error clearing analytics data: $e');
    }
  }

  /// Log feed initialization
  static Future<void> logFeedInitialization() async {
    try {
      AnalyticsService.logEvent('feed_initialization', parameters: {
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error logging feed initialization: $e');
    }
  }

  /// Log feed error
  static Future<void> logFeedError(String errorType, String errorMessage) async {
    try {
      AnalyticsService.logEvent('feed_error', parameters: {
        'error_type': errorType,
        'error_message': errorMessage,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error logging feed error: $e');
    }
  }

  /// Log feed view time with user context
  static Future<void> logFeedViewTime({
    required String userId,
    required Duration duration,
  }) async {
    try {
      AnalyticsService.logEvent('feed_view_time', parameters: {
        'user_id': userId,
        'duration_seconds': duration.inSeconds,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Also update local storage for tracking session patterns
      final prefs = await SharedPreferences.getInstance();
      final sessions = prefs.getStringList('feed_sessions') ?? [];

      // Keep the last 20 sessions
      if (sessions.length >= 20) {
        sessions.removeAt(0);
      }

      sessions.add(json.encode({
        'user_id': userId,
        'duration': duration.inSeconds,
        'timestamp': DateTime.now().toIso8601String(),
      }));

      await prefs.setStringList('feed_sessions', sessions);
    } catch (e) {
      debugPrint('Error logging feed view time: $e');
    }
  }

  /// Log an error event with metadata
  static Future<void> logError(String errorType, Map<String, dynamic> metadata) async {
    try {
      // Log to analytics service
      AnalyticsService.logEvent('feed_error', parameters: {
        'error_type': errorType,
        ...metadata,
      });

      // Store error in local storage for debugging
      final prefs = await SharedPreferences.getInstance();
      final errors = prefs.getStringList('feed_errors') ?? [];

      // Keep the last 50 errors
      if (errors.length >= 50) {
        errors.removeAt(0);
      }

      errors.add(json.encode({
        'error_type': errorType,
        'metadata': metadata,
        'timestamp': DateTime.now().toIso8601String(),
      }));

      await prefs.setStringList('feed_errors', errors);
    } catch (e) {
      debugPrint('Error logging feed error: $e');
    }
  }

  // Private helper methods

  /// Add event to view history
  static Future<void> _addToViewHistory(Event event) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyString = prefs.getString(_viewedEventsKey);

      final List<Map<String, dynamic>> viewedEvents = historyString != null
          ? (json.decode(historyString) as List).cast<Map<String, dynamic>>()
          : [];

      // Check if event already viewed
      final existingIndex =
          viewedEvents.indexWhere((e) => e['event_id'] == event.id);

      if (existingIndex >= 0) {
        // Update existing entry
        viewedEvents[existingIndex] = {
          'event_id': event.id,
          'timestamp': DateTime.now().toIso8601String(),
          'category': event.category,
          'organizer': event.organizerName,
          'view_count': (viewedEvents[existingIndex]['view_count'] as int) + 1,
        };
      } else {
        // Add new entry
        viewedEvents.add({
          'event_id': event.id,
          'timestamp': DateTime.now().toIso8601String(),
          'category': event.category,
          'organizer': event.organizerName,
          'view_count': 1,
        });
      }

      // Limit history size
      if (viewedEvents.length > 100) {
        viewedEvents.removeRange(0, viewedEvents.length - 100);
      }

      // Save updated history
      await prefs.setString(_viewedEventsKey, json.encode(viewedEvents));
    } catch (e) {
      debugPrint('Error adding to view history: $e');
    }
  }

  /// Update interaction statistics
  static Future<void> _updateInteractionStats(String interactionType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsString = prefs.getString(_interactionStatsKey);

      final Map<String, dynamic> stats = statsString != null
          ? json.decode(statsString) as Map<String, dynamic>
          : {
              'interactions': <String, int>{},
              'last_interaction': null,
              'total_interactions': 0,
            };

      // Get interactions map
      final interactions = stats['interactions'] as Map<String, dynamic>? ?? {};

      // Update counter for this interaction type
      interactions[interactionType] =
          (interactions[interactionType] as int? ?? 0) + 1;

      // Update stats
      stats['interactions'] = interactions;
      stats['last_interaction'] = DateTime.now().toIso8601String();
      stats['total_interactions'] =
          (stats['total_interactions'] as int? ?? 0) + 1;

      // Save updated stats
      await prefs.setString(_interactionStatsKey, json.encode(stats));
    } catch (e) {
      debugPrint('Error updating interaction stats: $e');
    }
  }

  /// Increment category preference
  static Future<void> _incrementCategoryPreference(String category,
      {int weight = 1}) async {
    try {
      if (category.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final prefsString = prefs.getString(_categoryPreferencesKey);

      final Map<String, dynamic> preferences = prefsString != null
          ? json.decode(prefsString) as Map<String, dynamic>
          : {};

      // Update preference count
      preferences[category] = (preferences[category] as int? ?? 0) + weight;

      // Save updated preferences
      await prefs.setString(_categoryPreferencesKey, json.encode(preferences));
    } catch (e) {
      debugPrint('Error incrementing category preference: $e');
    }
  }

  /// Increment organizer preference
  static Future<void> _incrementOrganizerPreference(String organizer,
      {int weight = 1}) async {
    try {
      if (organizer.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final prefsString = prefs.getString(_organizerPreferencesKey);

      final Map<String, dynamic> preferences = prefsString != null
          ? json.decode(prefsString) as Map<String, dynamic>
          : {};

      // Update preference count
      preferences[organizer] = (preferences[organizer] as int? ?? 0) + weight;

      // Save updated preferences
      await prefs.setString(_organizerPreferencesKey, json.encode(preferences));
    } catch (e) {
      debugPrint('Error incrementing organizer preference: $e');
    }
  }

  /// Increment tag preference
  static Future<void> _incrementTagPreference(String tag) async {
    try {
      if (tag.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      const key = 'tag_preferences';
      final prefsString = prefs.getString(key);

      final Map<String, dynamic> preferences = prefsString != null
          ? json.decode(prefsString) as Map<String, dynamic>
          : {};

      // Update preference count
      preferences[tag] = (preferences[tag] as int? ?? 0) + 1;

      // Save updated preferences
      await prefs.setString(key, json.encode(preferences));
    } catch (e) {
      debugPrint('Error incrementing tag preference: $e');
    }
  }
}
