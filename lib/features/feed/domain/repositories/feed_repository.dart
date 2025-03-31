import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/models/feed_state.dart';
import 'package:hive_ui/models/recommended_space.dart';

/// Repository interface for feed data operations
abstract class FeedRepository {
  /// Fetch events for the feed with optional filtering and pagination
  Future<Map<String, dynamic>> fetchFeedEvents({
    bool forceRefresh = false,
    int page = 1,
    int pageSize = 20,
    EventFilters? filters,
    bool userInitiated = false,
  });

  /// Fetch events directly from spaces
  Future<List<Event>> fetchEventsFromSpaces({int limit = 20});

  /// Fetch space recommendations for the feed
  Future<List<RecommendedSpace>> fetchSpaceRecommendations({int limit = 5});

  /// Prioritize events based on user preferences
  Future<List<Event>> prioritizeEvents({
    required List<Event> events,
    Map<String, int>? categoryScores,
    Map<String, int>? organizerScores,
    List<String>? userInterests,
    String? userMajor,
    int? userYear,
    String? userResidence,
    List<String>? joinedSpaceIds,
    List<String>? rsvpedEventIds,
    List<String>? friendIds,
    List<String>? boostedEventIds,
  });
}
