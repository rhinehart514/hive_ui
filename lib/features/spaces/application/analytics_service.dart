import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';

/// Service for tracking analytics events related to spaces
class SpacesAnalyticsService {
  final FirebaseAnalytics _analytics;

  /// Constructor
  SpacesAnalyticsService({FirebaseAnalytics? analytics})
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  /// Track when a user views the spaces screen
  Future<void> trackSpacesScreenView() async {
    try {
      await _analytics.logScreenView(
        screenName: 'spaces_screen',
        screenClass: 'SpacesScreen',
      );
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  /// Track when a user views a specific space
  Future<void> trackSpaceView(SpaceEntity space) async {
    try {
      await _analytics.logEvent(
        name: 'space_view',
        parameters: {
          'space_id': space.id,
          'space_name': space.name,
          'space_type': space.spaceType.toString(),
          'is_joined': space.isJoined,
        },
      );
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  /// Track when a user joins a space
  Future<void> trackSpaceJoin(SpaceEntity space) async {
    try {
      await _analytics.logEvent(
        name: 'space_join',
        parameters: {
          'space_id': space.id,
          'space_name': space.name,
          'space_type': space.spaceType.toString(),
          'member_count': space.metrics.memberCount,
        },
      );
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  /// Track when a user leaves a space
  Future<void> trackSpaceLeave(SpaceEntity space) async {
    try {
      await _analytics.logEvent(
        name: 'space_leave',
        parameters: {
          'space_id': space.id,
          'space_name': space.name,
          'space_type': space.spaceType.toString(),
          'duration_days': _getDaysAsMember(space),
        },
      );
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  /// Track when a user searches for spaces
  Future<void> trackSpaceSearch(String query, int resultCount) async {
    try {
      await _analytics.logSearch(
        searchTerm: query,
        numberOfNights: resultCount, // Repurposing this field for result count
      );

      // Additionally log a custom event with more details
      await _analytics.logEvent(
        name: 'space_search',
        parameters: {
          'query': query,
          'result_count': resultCount,
          'query_length': query.length,
        },
      );
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  /// Track when a user filters spaces by category
  Future<void> trackSpaceFilter(String category, int resultCount) async {
    try {
      await _analytics.logEvent(
        name: 'space_filter',
        parameters: {
          'category': category,
          'result_count': resultCount,
        },
      );
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  /// Track when a user switches tabs in the spaces screen
  Future<void> trackTabChange(String tabName) async {
    try {
      await _analytics.logEvent(
        name: 'spaces_tab_change',
        parameters: {
          'tab_name': tabName,
        },
      );
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  /// Track when a space is updated
  void trackSpaceUpdate(String spaceId) {
    // Implement analytics tracking for space updates
    debugPrint('🔄 Space updated: $spaceId');
  }

  /// Helper method to estimate days as a member
  int _getDaysAsMember(SpaceEntity space) {
    // This is a placeholder - in a real app, you would store the join date
    // and calculate the actual duration
    return 30; // Default to 30 days
  }
}
