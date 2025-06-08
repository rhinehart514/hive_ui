import '../../../../models/event.dart';
import '../../../../models/reposted_event.dart';
import 'package:hive_ui/models/feed_state.dart';
import 'package:hive_ui/models/recommended_space.dart';
import 'package:hive_ui/features/feed/domain/failures/feed_failures.dart';
import 'package:hive_ui/features/shared/domain/failures/failure.dart';

/// Repository interface for feed-related operations
abstract class FeedRepository {
  /// Get events for the feed
  /// 
  /// Returns a Right with events list on success or a Left with FeedFailure on error
  Future<Either<FeedFailure, List<Event>>> getEvents({
    bool forceRefresh = false,
    int limit = 20,
    Event? lastEvent,
  });
  
  /// Get recommended events for the feed
  /// 
  /// Returns a Right with recommended events list on success or a Left with FeedFailure on error
  Future<Either<FeedFailure, List<Event>>> getRecommendedEvents({
    int limit = 10,
  });
  
  /// Get RSVP status for an event
  /// 
  /// Returns a Right with RSVP status on success or a Left with FeedFailure on error
  Future<Either<FeedFailure, bool>> getEventRsvpStatus(String eventId);
  
  /// RSVP to an event
  /// 
  /// Returns a Right with success status on success or a Left with FeedFailure on error
  Future<Either<FeedFailure, bool>> rsvpToEvent(String eventId, bool attending);
  
  /// Repost an event
  /// 
  /// Returns a Right with RepostedEvent on success or a Left with FeedFailure on error
  Future<Either<FeedFailure, RepostedEvent?>> repostEvent({
    required String eventId,
    String? comment,
    String? userId,
  });
  
  /// Clear the repository cache
  Future<void> clearCache();

  /// Fetch events for the feed with optional filtering and pagination
  /// 
  /// Returns a Right with event data on success or a Left with FeedFailure on error
  Future<Either<FeedFailure, Map<String, dynamic>>> fetchFeedEvents({
    bool forceRefresh = false,
    int page = 1,
    int pageSize = 20,
    EventFilters? filters,
    bool userInitiated = false,
  });

  /// Fetch events directly from spaces
  /// 
  /// Returns a Right with events list on success or a Left with FeedFailure on error
  Future<Either<FeedFailure, List<Event>>> fetchEventsFromSpaces({int limit = 20});

  /// Fetch space recommendations for the feed
  /// 
  /// Returns a Right with space recommendations on success or a Left with FeedFailure on error
  Future<Either<FeedFailure, List<RecommendedSpace>>> fetchSpaceRecommendations({int limit = 5});

  /// Prioritize events based on user preferences
  /// 
  /// Returns a Right with prioritized events on success or a Left with FeedFailure on error
  Future<Either<FeedFailure, List<Event>>> prioritizeEvents({
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
  /// 
  /// The stream will emit new values as feed content updates
  Stream<Either<FeedFailure, List<Map<String, dynamic>>>> getFeedStream();
}
