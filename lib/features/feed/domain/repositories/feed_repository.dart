import '../../../../models/event.dart';
import '../../../../models/reposted_event.dart';
import 'package:hive_ui/models/feed_state.dart';
import 'package:hive_ui/models/recommended_space.dart';

/// Repository interface for feed-related operations
abstract class FeedRepository {
  /// Get events for the feed
  Future<List<Event>> getEvents({
    bool forceRefresh = false,
    int limit = 20,
    Event? lastEvent,
  });
  
  /// Get recommended events for the feed
  Future<List<Event>> getRecommendedEvents({
    int limit = 10,
  });
  
  /// Get RSVP status for an event
  Future<bool> getEventRsvpStatus(String eventId);
  
  /// RSVP to an event
  Future<bool> rsvpToEvent(String eventId, bool attending);
  
  /// Repost an event
  Future<RepostedEvent?> repostEvent({
    required String eventId,
    String? comment,
    String? userId,
  });
  
  /// Clear the repository cache
  Future<void> clearCache();

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

  /// Get a stream of combined feed items (events, reposts, recommendations, etc.)
  Stream<List<Map<String, dynamic>>> getFeedStream();
}
