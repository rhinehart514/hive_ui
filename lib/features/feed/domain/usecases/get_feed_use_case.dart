import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/models/feed_state.dart';
import 'package:hive_ui/models/recommended_space.dart';
import '../repositories/feed_repository.dart';

/// Use case for fetching feed data
class GetFeedUseCase {
  /// The repository that will be used to get the data
  final FeedRepository repository;

  /// Constructor
  GetFeedUseCase(this.repository);

  /// Execute the use case to fetch feed events
  Future<Map<String, dynamic>> execute({
    bool forceRefresh = false,
    int page = 1,
    int pageSize = 20,
    EventFilters? filters,
    bool userInitiated = false,
  }) async {
    return repository.fetchFeedEvents(
      forceRefresh: forceRefresh,
      page: page,
      pageSize: pageSize,
      filters: filters,
      userInitiated: userInitiated,
    );
  }

  /// Get events directly from spaces
  Future<List<Event>> getEventsFromSpaces({int limit = 20}) async {
    return repository.fetchEventsFromSpaces(limit: limit);
  }

  /// Get space recommendations
  Future<List<RecommendedSpace>> getSpaceRecommendations(
      {int limit = 5}) async {
    return repository.fetchSpaceRecommendations(limit: limit);
  }

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
  }) async {
    return repository.prioritizeEvents(
      events: events,
      categoryScores: categoryScores,
      organizerScores: organizerScores,
      userInterests: userInterests,
      userMajor: userMajor,
      userYear: userYear,
      userResidence: userResidence,
      joinedSpaceIds: joinedSpaceIds,
      rsvpedEventIds: rsvpedEventIds,
      friendIds: friendIds,
      boostedEventIds: boostedEventIds,
    );
  }
}
