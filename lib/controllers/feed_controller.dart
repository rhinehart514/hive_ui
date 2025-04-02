import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/models/feed_state.dart';
import 'package:hive_ui/providers/profile_provider.dart';
import 'package:hive_ui/providers/feed_provider.dart'; // Main feed state
import 'package:hive_ui/services/feed/feed_service.dart';
import 'package:hive_ui/services/feed/feed_analytics.dart';

/// Provider for the feed controller
final feedControllerProvider = Provider<FeedController>((ref) {
  return FeedController(ref);
});

/// Provider for RSS feed enabling
final rssFeedEnabledProvider = StateProvider<bool>((ref) => false);

/// Controller for the feed page
class FeedController extends StateNotifier<FeedState> {
  /// Riverpod reference
  final Ref _ref;

  /// Session view start time for analytics
  DateTime? _viewStartTime;

  /// Get the view start time for analytics
  DateTime? get viewStartTime => _viewStartTime;

  /// Track initialization state
  bool _isInitialized = false;

  /// Track failed attempts
  int _failedAttempts = 0;

  /// Current page for pagination
  int _currentPage = 1;

  /// Page size for batch loading
  static const int _pageSize = 15;

  /// Whether more events are available
  bool _hasMoreEvents = true;

  /// Flag to prevent duplicate loading
  bool _isLoadingMore = false;

  /// Current search query
  String? _currentSearchQuery;
  
  /// Last feed refresh timestamp
  DateTime? _lastFeedRefreshTime;

  /// Timer for search debounce
  Timer? _searchDebounceTimer;

  /// Constructor
  FeedController(this._ref) : super(FeedState.initial()) {
    _viewStartTime = DateTime.now();
    _lastFeedRefreshTime = DateTime.now();

    // Set RSS feed fetching to disabled by default
    _updateRssFeedFetchingState(false);
  }

  /// Initialize the feed - without RSS polling
  Future<void> initializeFeed() async {
    if (_isInitialized) return;

    debugPrint('🔄 Initializing feed controller...');
    _isInitialized = true;

    // Reset pagination state
    _currentPage = 1;
    _hasMoreEvents = true;
    _isLoadingMore = false;

    try {
      await refreshFeed(showLoading: true, userInitiated: false);
    } catch (e) {
      debugPrint('⚠️ Error during feed initialization: $e');
      // Update state to show error
      state = FeedState.error(
        'Unable to initialize feed. Please check your connection and try again.'
      );
      
      // Log error for analytics
      FeedAnalytics.logError('feed_initialization_failed', {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Refresh the feed with new data
  Future<void> refreshFeed({bool showLoading = false, bool userInitiated = true}) async {
    debugPrint('🔄 Refreshing feed data... (user initiated: $userInitiated)');
    
    // Update last refresh time
    _lastFeedRefreshTime = DateTime.now();
    
    // Reset pagination state on refresh
    _currentPage = 1;
    _hasMoreEvents = true;
    _isLoadingMore = false;

    try {
      // Update loading state
      if (showLoading) {
        state = FeedState.loading();
      }

      // Fetch events from service
      final result = await FeedService.fetchFeedEvents(
        forceRefresh: userInitiated,
        userInitiated: userInitiated,
        page: _currentPage,
        pageSize: _pageSize,
      );

      // Check if we got an error from the service
      if (result.containsKey('error')) {
        debugPrint('⚠️ Feed service returned error: ${result['error']}');
      }

      // Get the regular events from the result
      final events = result['events'] as List<Event>;
      _hasMoreEvents = result['hasMore'] as bool;

      // If no events were returned, handle the error case
      if (events.isEmpty) {
        debugPrint('❗ No events returned from feed service');

        // Increment failed attempts counter
        _failedAttempts++;

        // If we've failed multiple times, show an error
        if (_failedAttempts > 3) {
          state = FeedState.error(
            'Unable to load feed data. Please check your connection and try again later.'
          );
          
          // Log error for analytics
          FeedAnalytics.logError('feed_load_failed', {
            'attempts': _failedAttempts,
            'timestamp': DateTime.now().toIso8601String(),
          });
          return;
        }

        // Return empty state but don't show error yet
        state = FeedState.fromItems(
          events: [],
          reposts: [],
          spaceRecommendations: [],
          hiveLabItems: [],
          hasMoreEvents: false,
          currentPage: 1,
        );
        return;
      }

      // Reset failed attempts counter since we got data
      _failedAttempts = 0;

      // Create new state with loaded data
      state = state.copyWith(
        events: events,
        hasMoreEvents: _hasMoreEvents,
        currentPage: _currentPage,
      );

    } catch (e) {
      debugPrint('⚠️ Error refreshing feed: $e');
      state = FeedState.error('Unable to refresh feed: ${e.toString()}');
      
      // Log error for analytics
      FeedAnalytics.logError('feed_refresh_failed', {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Load more events for infinite scrolling
  Future<void> loadMoreEvents() async {
    if (!state.hasMoreEvents || _isLoadingMore) return;

    _isLoadingMore = true;
    _currentPage++;

    try {
      final result = await FeedService.fetchFeedEvents(
        forceRefresh: false,
        userInitiated: false,
        page: _currentPage,
        pageSize: _pageSize,
      );

      final newEvents = result['events'] as List<Event>;
      _hasMoreEvents = result['hasMore'] as bool;

      if (newEvents.isNotEmpty) {
        // Update state with new events
        state = state.copyWith(
          events: [...state.events, ...newEvents],
          hasMoreEvents: _hasMoreEvents,
          currentPage: _currentPage,
          pagination: state.pagination.copyWith(
            currentPage: _currentPage,
            hasMore: _hasMoreEvents,
          ),
        );
      } else {
        // No more events to load
        state = state.copyWith(
          hasMoreEvents: false,
          pagination: state.pagination.copyWith(
            hasMore: false,
          ),
        );
      }
    } catch (e) {
      debugPrint('⚠️ Error loading more events: $e');
      // Keep existing state but mark no more events
      state = state.copyWith(
        hasMoreEvents: false,
        pagination: state.pagination.copyWith(
          hasMore: false,
        ),
      );
    } finally {
      _isLoadingMore = false;
    }
  }

  /// Handle RSVP to an event
  Future<void> rsvpToEvent(Event event) async {
    try {
      // Save event using profile provider
      await _ref.read(profileProvider.notifier).saveEvent(event);

      // Track interaction for personalization
      await FeedAnalytics.trackEventInteraction(event, 'rsvp');
    } catch (e) {
      debugPrint('Error RSVPing to event: $e');
    }
  }

  /// Track event view
  Future<void> trackEventView(Event event) async {
    await FeedAnalytics.trackEventView(event);
  }

  /// Search events in the feed
  Future<void> searchEvents(String query) async {
    _currentSearchQuery = query;

    if (query.isEmpty) {
      // Reset search
      state = state.copyWith(
        filters: state.filters.copyWith(searchQuery: null, clearSearchQuery: true),
      );
      return;
    }

    try {
      // Update state with search query
      state = state.copyWith(
        filters: state.filters.copyWith(searchQuery: query),
      );
    } catch (e) {
      debugPrint('⚠️ Error searching events: $e');
      FeedAnalytics.logError('feed_search_failed', {
        'query': query,
        'error': e.toString(),
      });
    }
  }

  /// Dispose the controller
  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    // Track session time
    if (_viewStartTime != null) {
      final sessionDuration =
          DateTime.now().difference(_viewStartTime!).inSeconds;
      FeedAnalytics.trackFeedSessionTime(sessionDuration);
    }
    super.dispose();
  }

  /// Enable or disable RSS feed fetching
  void toggleRssFeedFetching(bool enabled) {
    _updateRssFeedFetchingState(enabled);

    // If enabling, immediately refresh the feed with RSS data
    if (enabled) {
      refreshFeed(showLoading: true, userInitiated: true);
    }
  }

  /// Update the RSS feed fetching state
  void _updateRssFeedFetchingState(bool enabled) {
    // Update the provider state
    _ref.read(rssFeedEnabledProvider.notifier).state = enabled;

    // Update the service configuration
    FeedService.setRssFeedFetchingEnabled(enabled);

    // Log the change
    debugPrint('RSS feed fetching ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Search the feed for events matching the given query
  void searchFeed(String query) {
    if (query.isEmpty) {
      clearSearch();
      return;
    }

    debugPrint('🔍 Searching feed for: $query');
    _currentSearchQuery = query.toLowerCase();

    // Get current feed state
    final feedState = _ref.read(feedStateProvider);
    final events = feedState.events;

    // Filter events based on search query
    final filteredEvents = events.where((event) {
      return event.title.toLowerCase().contains(_currentSearchQuery!) ||
          event.description.toLowerCase().contains(_currentSearchQuery!) ||
          event.organizerName.toLowerCase().contains(_currentSearchQuery!) ||
          event.location.toLowerCase().contains(_currentSearchQuery!) ||
          event.category.toLowerCase().contains(_currentSearchQuery!) ||
          event.tags.any((tag) => tag.toLowerCase().contains(_currentSearchQuery!));
    }).toList();

    debugPrint('🔍 Found ${filteredEvents.length} matching events');

    // Update feed state with filtered events
    final searchState = feedState.copyWith(
      events: filteredEvents,
      filters: feedState.filters.copyWith(searchQuery: query),
    );

    _ref.read(feedStateProvider.notifier).state = searchState;
  }

  /// Clear the search results and return to normal feed
  void clearSearch() {
    debugPrint('🔍 Clearing search results');
    _currentSearchQuery = null;

    // Get current feed state and clear search data
    final feedState = _ref.read(feedStateProvider);
    final clearedState = feedState.copyWith(
      filters: feedState.filters.copyWith(searchQuery: null, clearSearchQuery: true),
    );

    _ref.read(feedStateProvider.notifier).state = clearedState;
  }

  /// Gets feed information for a specific event by its ID
  /// Returns a detailed object containing event, engagement, and activity data
  Future<Map<String, dynamic>> getEventFeedById(String eventId) async {
    try {
      // Update feed state to show loading
      final feedNotifier = _ref.read(feedStateProvider.notifier);
      final currentState = _ref.read(feedStateProvider);
      
      // Only update state if not already loading
      if (currentState.status != LoadingStatus.loading && 
          currentState.status != LoadingStatus.refreshing) {
        feedNotifier.state = currentState.copyWith(
          status: LoadingStatus.loading,
        );
      }
      
      final feedData = await FeedService.getEventFeedById(eventId);
      
      // Set state back to loaded
      feedNotifier.state = currentState.copyWith(
        status: LoadingStatus.loaded,
      );
      
      return feedData;
    } catch (e) {
      // Update state to show error
      final feedNotifier = _ref.read(feedStateProvider.notifier);
      final currentState = _ref.read(feedStateProvider);
      
      feedNotifier.state = currentState.copyWith(
        status: LoadingStatus.error,
      );
      
      debugPrint('Error getting event feed: $e');
      return {
        'success': false,
        'error': e.toString(),
        'eventId': eventId,
      };
    }
  }

  /// Check if we have cached feed data available
  bool hasCachedFeed() {
    final feedState = _ref.read(feedStateProvider);
    
    // Check if we have items and the state is not error or initial loading
    return feedState.events.isNotEmpty && 
           feedState.status != LoadingStatus.error && 
           feedState.status != LoadingStatus.initial;
  }
  
  /// Load cached feed data into state
  void loadCachedFeed() {
    final feedState = _ref.read(feedStateProvider);
    
    // If we have cached data, update state to show it's loaded from cache
    if (feedState.events.isNotEmpty) {
      state = feedState.copyWith(
        status: LoadingStatus.loaded,
      );
      
      debugPrint('Loaded cached feed data with ${feedState.events.length} items');
    }
  }
  
  /// Check if the cached data is stale and needs refresh
  bool isCacheStale() {
    // If we have a last refresh timestamp, check if it's older than our threshold
    if (_lastFeedRefreshTime != null) {
      final now = DateTime.now();
      const staleDuration = Duration(minutes: 15); // Fixed const usage
      
      return now.difference(_lastFeedRefreshTime!) > staleDuration;
    }
    
    // Default to true if no timestamp (needs refresh)
    return true;
  }
  
  /// Pre-cache event details for faster navigation
  Future<void> precacheEventDetails(String eventId) async {
    try {
      // This could fetch and cache full event details
      // For now, just retrieve the event from the current feed
      final feedState = _ref.read(feedStateProvider);
      final events = feedState.events
          .where((event) => event.id == eventId)
          .toList();
      
      if (events.isNotEmpty) {
        debugPrint('Event details found in cache for ID: $eventId');
        
        // Store in a more accessible cache if needed
        // Or prefetch related data for this event
      }
    } catch (e) {
      debugPrint('Error pre-caching event details: $e');
      // Non-critical, so just log the error
    }
  }

  /// Get filtered events based on current filters
  List<Event> get filteredEvents => state.filteredEvents;

  /// Get today's events
  List<Event> get todayEvents => state.filteredTodayEvents;

  /// Get this week's events
  List<Event> get thisWeekEvents => state.filteredThisWeekEvents;

  /// Get upcoming events
  List<Event> get upcomingEvents => state.filteredUpcomingEvents;
}
