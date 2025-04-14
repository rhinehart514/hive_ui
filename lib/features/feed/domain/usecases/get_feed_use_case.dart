import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/models/feed_state.dart';
import 'package:hive_ui/models/recommended_space.dart';
import '../repositories/feed_repository.dart';
import 'package:hive_ui/features/feed/domain/failures/feed_failures.dart';
import 'package:flutter/material.dart';

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
    final result = await repository.fetchFeedEvents(
      forceRefresh: forceRefresh,
      page: page,
      pageSize: pageSize,
      filters: filters,
      userInitiated: userInitiated,
    );
    
    return result.fold(
      (failure) {
        // Log the failure
        debugPrint('Feed fetch failure: ${failure.message}');
        // Return empty result with error indicator
        return {
          'events': <Event>[],
          'hasMore': false,
          'fromCache': false,
          'error': failure.message,
        };
      },
      (success) => success,
    );
  }

  /// Get events directly from spaces
  Future<List<Event>> getEventsFromSpaces({int limit = 20}) async {
    final result = await repository.fetchEventsFromSpaces(limit: limit);
    
    return result.fold(
      (failure) {
        // Log the failure
        debugPrint('Events from spaces fetch failure: ${failure.message}');
        // Return empty list on failure
        return <Event>[];
      },
      (events) => events,
    );
  }

  /// Get space recommendations
  Future<List<RecommendedSpace>> getSpaceRecommendations(
      {int limit = 5}) async {
    final result = await repository.fetchSpaceRecommendations(limit: limit);
    
    return result.fold(
      (failure) {
        // Log the failure
        debugPrint('Space recommendations fetch failure: ${failure.message}');
        // Return empty list on failure
        return <RecommendedSpace>[];
      },
      (recommendations) => recommendations,
    );
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
    final result = await repository.prioritizeEvents(
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
    
    return result.fold(
      (failure) {
        // Log the failure
        debugPrint('Event prioritization failure: ${failure.message}');
        // Return original events list on failure
        return events;
      },
      (prioritizedEvents) => prioritizedEvents,
    );
  }
}
