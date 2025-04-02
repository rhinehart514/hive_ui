import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/feed/data/repositories/feed_repository_impl.dart';
import 'package:hive_ui/features/feed/domain/repositories/feed_repository.dart';
import 'package:hive_ui/features/feed/domain/usecases/get_feed_use_case.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/models/feed_state.dart';
import 'package:hive_ui/models/recommended_space.dart';
import 'package:hive_ui/services/analytics_service.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart';
import 'package:hive_ui/models/interactions/interaction.dart';
import 'package:hive_ui/services/interactions/interaction_service.dart';
import 'package:hive_ui/models/space_recommendation_simple.dart';
import 'package:hive_ui/models/hive_lab_item_simple.dart';
import 'package:hive_ui/models/hive_lab_item.dart' as lab_models;

/// Provider for the feed repository
final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepositoryImpl();
});

/// Provider for the feed use case
final getFeedUseCaseProvider = Provider<GetFeedUseCase>((ref) {
  final repository = ref.watch(feedRepositoryProvider);
  return GetFeedUseCase(repository);
});

/// Provider for the feed state
final feedStateProvider =
    StateNotifierProvider<FeedStateNotifier, FeedState>((ref) {
  return FeedStateNotifier(ref, ref.watch(getFeedUseCaseProvider));
});

/// Provider for filtered today events
final todayEventsProvider = Provider<List<Event>>((ref) {
  return ref.watch(feedStateProvider).filteredTodayEvents;
});

/// Provider for filtered this week events
final thisWeekEventsProvider = Provider<List<Event>>((ref) {
  return ref.watch(feedStateProvider).filteredThisWeekEvents;
});

/// Provider for filtered upcoming events
final upcomingEventsProvider = Provider<List<Event>>((ref) {
  return ref.watch(feedStateProvider).filteredUpcomingEvents;
});

/// Provider for personalized "For You" events
final forYouEventsProvider = Provider<List<Event>>((ref) {
  return ref.watch(feedStateProvider).forYouEvents;
});

/// Controller for the feed state
class FeedStateNotifier extends StateNotifier<FeedState> {
  final Ref _ref;
  final GetFeedUseCase _getFeedUseCase;

  /// Constructor
  FeedStateNotifier(this._ref, this._getFeedUseCase)
      : super(FeedState.initial()) {
    // Initial load
    fetchEvents();
  }

  /// Fetch events and update state
  Future<void> fetchEvents(
      {bool refresh = false, bool userInitiated = false}) async {
    try {
      if (refresh) {
        state = state.copyWith(
          status: LoadingStatus.refreshing,
          pagination: const PaginationState(),
          errorMessage: null, // Clear error message
        );
      } else if (state.status == LoadingStatus.initial) {
        state = FeedState.loading();
      }

      // Track performance
      final startTime = DateTime.now();

      // Fetch events from repository
      final result = await _getFeedUseCase.execute(
        forceRefresh: refresh,
        page: state.pagination.currentPage,
        pageSize: state.pagination.pageSize,
        filters: state.filters,
        userInitiated: userInitiated,
      );

      final List<Event> events = result['events'] as List<Event>;

      // Generate personalized feed using the repository
      final personalizedEvents = await _generatePersonalizedFeed(events);

      // Fetch space recommendations
      final recommendedSpaces = await _fetchSpaceRecommendations();

      // Convert RecommendedSpace to SpaceRecommendationSimple
      final spaceRecommendations = recommendedSpaces
          .map((rec) => SpaceRecommendationSimple(
                name: rec.space.name,
                description: rec.displayPitch,
                imageUrl: rec.space.imageUrl,
                category: rec.space.tags.isNotEmpty
                    ? rec.space.tags.first
                    : 'General',
                score: 0.0, // Default score since it's not available in RecommendedSpace
              ))
          .toList();

      // Create dummy content for other feed items that we'll implement later
      final reposts = await _fetchReposts();
      final labItems = await _fetchHiveLabItems();

      // Convert HiveLabItem to HiveLabItemSimple
      final hiveLabItems = labItems.map((item) => HiveLabItemSimple(
            title: item.title,
            description: item.description,
            link: 'https://hive.app/lab/${item.title.toLowerCase().replaceAll(' ', '-')}',
            timestamp: DateTime.now(),
          )).toList();

      debugPrint('Updating feed with ${events.length} events and ' '${spaceRecommendations.length} space recommendations');

      // Update pagination info
      final hasMore = result['hasMore'] as bool? ?? false;
      final updatedPagination = state.pagination.copyWith(
        hasMore: hasMore,
        currentPage: hasMore
            ? state.pagination.currentPage + 1
            : state.pagination.currentPage,
      );

      // Track performance metrics
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      AnalyticsService.logEvent('feed_loaded', parameters: {
        'duration_ms': duration,
        'event_count': events.length,
        'from_cache': result['fromCache'] as bool? ?? false,
        'has_more': hasMore,
      });

      // Update feed state
      state = FeedState.fromItems(
        events: events,
        reposts: reposts,
        spaceRecommendations: spaceRecommendations,
        hiveLabItems: hiveLabItems,
      ).copyWith(
        pagination: updatedPagination,
        status: LoadingStatus.loaded,
      );

      // Log feed view interaction
      _logFeedViewInteraction();
    } catch (e) {
      debugPrint('Error in fetchEvents: $e');
      state = FeedState.error('Failed to load feed: $e');
    }
  }

  /// Load more events for pagination
  Future<void> loadMoreEvents() async {
    if (state.status == LoadingStatus.loading ||
        state.status == LoadingStatus.refreshing ||
        !state.pagination.hasMore) {
      return;
    }

    try {
      // Set loading state for pagination
      state = state.copyWith(
        status: LoadingStatus.loading,
      );

      // Fetch next page
      final result = await _getFeedUseCase.execute(
        forceRefresh: false,
        page: state.pagination.currentPage + 1,
        pageSize: state.pagination.pageSize,
        filters: state.filters,
      );

      final List<Event> newEvents = result['events'] as List<Event>;
      final hasMore = result['hasMore'] as bool? ?? false;

      // Combine existing and new events
      final List<Event> combinedEvents = [...state.events, ...newEvents];

      // Update pagination info
      final updatedPagination = state.pagination.copyWith(
        hasMore: hasMore,
        currentPage: state.pagination.currentPage + 1,
      );

      // Update state
      state = state.copyWith(
        status: LoadingStatus.loaded,
        events: combinedEvents,
        pagination: updatedPagination,
      );

      // Generate personalized feed with the new events
      final personalizedEvents = await _generatePersonalizedFeed(combinedEvents);
      state = state.copyWith(events: personalizedEvents);
    } catch (e) {
      debugPrint('Error in loadMoreEvents: $e');
      // Reset to loaded state but keep existing events
      state = state.copyWith(status: LoadingStatus.loaded);
    }
  }

  /// Apply filters to events
  void applyFilters(EventFilters filters) {
    state = state.copyWith(
      filters: filters,
      pagination: const PaginationState(), // Reset pagination
    );

    // Re-fetch with new filters
    fetchEvents(refresh: true);
  }

  /// Reset filters
  void resetFilters() {
    state = state.copyWith(
      filters: const EventFilters(),
      pagination: const PaginationState(), // Reset pagination
    );

    // Re-fetch with no filters
    fetchEvents(refresh: true);
  }

  /// Generate personalized feed
  Future<List<Event>> _generatePersonalizedFeed(List<Event> events) async {
    try {
      // Check if user is authenticated
      final isAuthenticated = _ref.watch(isAuthenticatedProvider);

      if (!isAuthenticated || events.isEmpty) {
        return events;
      }

      // Get current user for personalization
      final currentUser = _ref.read(currentUserProvider);
      if (currentUser == null) {
        return events;
      }

      // Prioritize events based on user preferences using the repository
      return _getFeedUseCase.prioritizeEvents(
        events: events,
        // These could be fetched from a user preferences repository
        userInterests: null, // Will be fetched from Firebase by repository
        joinedSpaceIds: null, // Will be fetched from Firebase by repository
      );
    } catch (e) {
      debugPrint('Error in _generatePersonalizedFeed: $e');
      return events;
    }
  }

  /// Fetch space recommendations
  Future<List<RecommendedSpace>> _fetchSpaceRecommendations() async {
    try {
      // Use use case to get space recommendations
      return _getFeedUseCase.getSpaceRecommendations();
    } catch (e) {
      debugPrint('Error in _fetchSpaceRecommendations: $e');
      return [];
    }
  }

  /// Log feed view interaction
  void _logFeedViewInteraction() {
    try {
      // Check if user is authenticated
      final authState = _ref.watch(isAuthenticatedProvider);

      // Only track interactions for authenticated users
      if (authState) {
        final user = _ref.read(currentUserProvider);

        InteractionService.logInteraction(
          userId: user.id, // User is non-null here since we already checked authentication
          entityId: 'feed',
          entityType: EntityType.event,
          action: InteractionAction.view,
        );
      }
    } catch (e) {
      debugPrint('Error logging feed view: $e');
    }
  }

  /// Temporary method to fetch reposts (to be implemented with real data)
  Future<List<RepostItem>> _fetchReposts() async {
    // In a real implementation, these would come from a repository
    return [];
  }

  /// Temporary method to fetch HIVE lab items (to be implemented with real data)
  Future<List<lab_models.HiveLabItem>> _fetchHiveLabItems() async {
    // In a real implementation, these would come from a repository
    return [];
  }
}
