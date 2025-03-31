import 'package:flutter/material.dart';
import 'event.dart';
import 'repost_content_type.dart';

/// Status of the feed loading process
enum LoadingStatus {
  /// Initial state before any loading occurs
  initial,

  /// Loading data for the first time
  loading,

  /// Successfully loaded data
  loaded,

  /// An error occurred during loading
  error,

  /// Refreshing already loaded data
  refreshing,
}

/// Model for event filters
class EventFilters {
  /// Categories to filter by
  final List<String> categories;

  /// Date range to filter by
  final DateTimeRange? dateRange;

  /// Sources to include
  final List<EventSource> sources;

  /// Search query for filtering
  final String? searchQuery;

  /// Default constructor
  const EventFilters({
    this.categories = const [],
    this.dateRange,
    this.sources = const [
      EventSource.external,
      EventSource.user,
      EventSource.club
    ],
    this.searchQuery,
  });

  /// Create a copy with some fields replaced
  EventFilters copyWith({
    List<String>? categories,
    DateTimeRange? dateRange,
    List<EventSource>? sources,
    String? searchQuery,
    bool clearDateRange = false,
    bool clearSearchQuery = false,
  }) {
    return EventFilters(
      categories: categories ?? this.categories,
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      sources: sources ?? this.sources,
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
    );
  }

  /// Check if any filters are active
  bool get hasActiveFilters =>
      categories.isNotEmpty ||
      dateRange != null ||
      sources.length != 3 || // Not all sources
      (searchQuery != null && searchQuery!.isNotEmpty);

  /// Check if a specific event matches the current filters
  bool matches(Event event) {
    // Category filter
    if (categories.isNotEmpty && !categories.contains(event.category)) {
      return false;
    }

    // Date range filter
    if (dateRange != null) {
      final start = DateTime(
        dateRange!.start.year,
        dateRange!.start.month,
        dateRange!.start.day,
      );

      // End of end date (23:59:59)
      final end = DateTime(
        dateRange!.end.year,
        dateRange!.end.month,
        dateRange!.end.day,
        23,
        59,
        59,
      );

      if (event.startDate.isBefore(start) || event.startDate.isAfter(end)) {
        return false;
      }
    }

    // Source filter
    if (!sources.contains(event.source)) {
      return false;
    }

    // Search query filter
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final query = searchQuery!.toLowerCase();
      final title = event.title.toLowerCase();
      final description = event.description.toLowerCase();
      final organizer = event.organizerName.toLowerCase();
      final location = event.location.toLowerCase();

      if (!title.contains(query) &&
          !description.contains(query) &&
          !organizer.contains(query) &&
          !location.contains(query)) {
        return false;
      }
    }

    // All filters passed
    return true;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'categories': categories,
      'dateRange': dateRange != null
          ? {
              'start': dateRange!.start.toIso8601String(),
              'end': dateRange!.end.toIso8601String(),
            }
          : null,
      'sources': sources.map((s) => s.toString().split('.').last).toList(),
      'searchQuery': searchQuery,
    };
  }

  /// Create from JSON
  factory EventFilters.fromJson(Map<String, dynamic> json) {
    return EventFilters(
      categories: json['categories'] != null
          ? List<String>.from(json['categories'])
          : const [],
      dateRange: json['dateRange'] != null
          ? DateTimeRange(
              start: DateTime.parse(json['dateRange']['start']),
              end: DateTime.parse(json['dateRange']['end']),
            )
          : null,
      sources: json['sources'] != null
          ? (json['sources'] as List).map((s) {
              final sourceStr = s.toString();
              if (sourceStr == 'user') return EventSource.user;
              if (sourceStr == 'club') return EventSource.club;
              return EventSource.external;
            }).toList()
          : const [EventSource.external, EventSource.user, EventSource.club],
      searchQuery: json['searchQuery'] as String?,
    );
  }
}

/// Model for pagination state
class PaginationState {
  /// Current page number
  final int currentPage;

  /// Number of items per page
  final int pageSize;

  /// Whether there are more items to load
  final bool hasMore;

  /// Default constructor
  const PaginationState({
    this.currentPage = 1,
    this.pageSize = 20,
    this.hasMore = true,
  });

  /// Create a copy with some fields replaced
  PaginationState copyWith({
    int? currentPage,
    int? pageSize,
    bool? hasMore,
  }) {
    return PaginationState(
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  /// Next page state
  PaginationState nextPage() {
    return copyWith(currentPage: currentPage + 1);
  }

  /// Reset to first page
  PaginationState reset() {
    return const PaginationState();
  }
}

/// Enum representing different types of feed items
enum FeedItemType {
  /// Standard event card
  event,

  /// Reposted event with comment
  repost,

  /// Suggestion for a space
  spaceRecommendation,

  /// HIVE Lab card for feature requests
  hiveLab,
}

/// Class representing a repost in the feed
class RepostItem {
  /// The reposted event
  final Event event;

  /// Comment added by the reposter
  final String? comment;

  /// Name of the user who reposted
  final String reposterName;

  /// Time of the repost
  final DateTime repostTime;

  /// URL of the reposter's profile image
  final String? reposterImageUrl;

  /// Type of repost content
  final RepostContentType contentType;

  /// Constructor
  const RepostItem({
    required this.event,
    this.comment,
    required this.reposterName,
    required this.repostTime,
    this.reposterImageUrl,
    this.contentType = RepostContentType.standard,
  });

  /// Create a copy with some fields replaced
  RepostItem copyWith({
    Event? event,
    String? comment,
    String? reposterName,
    DateTime? repostTime,
    String? reposterImageUrl,
    RepostContentType? contentType,
  }) {
    return RepostItem(
      event: event ?? this.event,
      comment: comment ?? this.comment,
      reposterName: reposterName ?? this.reposterName,
      repostTime: repostTime ?? this.repostTime,
      reposterImageUrl: reposterImageUrl ?? this.reposterImageUrl,
      contentType: contentType ?? this.contentType,
    );
  }
}

/// Class representing a space recommendation
class SpaceRecommendation {
  /// Name of the recommended space
  final String name;

  /// Category of the space
  final String category;

  /// Brief description of the space
  final String description;

  /// URL of the space's image
  final String? imageUrl;

  /// Number of members in the space
  final int memberCount;

  /// Whether this is an official space
  final bool isOfficial;

  /// Constructor
  const SpaceRecommendation({
    required this.name,
    required this.category,
    required this.description,
    this.imageUrl,
    this.memberCount = 0,
    this.isOfficial = false,
  });
}

/// Class representing a HIVE Lab item
class HiveLabItem {
  /// Title of the lab item
  final String title;

  /// Description of the lab item
  final String description;

  /// Label for the primary action button
  final String actionLabel;

  /// Constructor
  const HiveLabItem({
    required this.title,
    required this.description,
    this.actionLabel = 'Join Lab',
  });
}

/// Feed state class
class FeedState {
  /// Current status of the feed
  final LoadingStatus status;

  /// List of all events in the feed
  final List<Event> allEvents;

  /// List of repost items in the feed
  final List<RepostItem> reposts;

  /// List of space recommendations in the feed
  final List<SpaceRecommendation> spaceRecommendations;

  /// List of HIVE lab items in the feed
  final List<HiveLabItem> hiveLabItems;

  /// Personalized "For You" events
  final List<Event> forYouEvents;

  /// Feed items with mixed content types
  final List<Map<String, dynamic>> feedItems;

  /// Current filters applied to the feed
  final EventFilters filters;

  /// Pagination state
  final PaginationState pagination;
  
  /// Whether there are more events to load
  final bool hasMoreEvents;
  
  /// Current page number for batch loading
  final int currentPage;
  
  /// Whether we're currently loading more items
  final bool isLoadingMore;

  /// Error message if the feed failed to load
  final String? errorMessage;
  
  /// Map of events by category
  final Map<String, List<Event>> categorizedEvents;
  
  /// Map of events by timeframe (today, this_week, upcoming)
  final Map<String, List<Event>> timeEvents;
  
  /// Whether the feed has been initialized
  final bool isInitialized;
  
  /// Search results when search is active
  final List<Event> searchResults;
  
  /// Flag indicating if search is active
  final bool isSearchActive;
  
  /// Current search query
  final String? searchQuery;

  /// Default constructor
  const FeedState({
    this.status = LoadingStatus.initial,
    this.allEvents = const [],
    this.reposts = const [],
    this.spaceRecommendations = const [],
    this.hiveLabItems = const [],
    this.forYouEvents = const [],
    this.feedItems = const [],
    this.filters = const EventFilters(),
    this.pagination = const PaginationState(),
    this.hasMoreEvents = true,
    this.currentPage = 1,
    this.isLoadingMore = false,
    this.errorMessage,
    this.categorizedEvents = const {},
    this.timeEvents = const {},
    this.isInitialized = false,
    this.searchResults = const [],
    this.isSearchActive = false,
    this.searchQuery,
  });

  /// Create an initial state
  factory FeedState.initial() {
    return const FeedState(
      status: LoadingStatus.initial,
      hasMoreEvents: true,
      currentPage: 1,
      isLoadingMore: false,
      isInitialized: false,
    );
  }

  /// Create a loading state
  factory FeedState.loading() {
    return const FeedState(
      status: LoadingStatus.loading,
      hasMoreEvents: true,
      currentPage: 1,
      isLoadingMore: false,
    );
  }

  /// Create a loaded state
  factory FeedState.loaded(
    List<Event> events, {
    List<RepostItem> reposts = const [],
    List<SpaceRecommendation> spaceRecommendations = const [],
    List<HiveLabItem> hiveLabItems = const [],
    bool hasMoreEvents = true, 
    int currentPage = 1,
  }) {
    // Create categorized events
    final categorizedEvents = <String, List<Event>>{};
    for (final event in events) {
      final category = event.category;
      if (!categorizedEvents.containsKey(category)) {
        categorizedEvents[category] = [];
      }
      categorizedEvents[category]!.add(event);
    }

    // Create time-based events
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endOfWeek = today.add(const Duration(days: 7));

    final todayEvents = <Event>[];
    final thisWeekEvents = <Event>[];
    final upcomingEvents = <Event>[];

    for (final event in events) {
      final eventDate = DateTime(
        event.startDate.year,
        event.startDate.month,
        event.startDate.day,
      );

      if (eventDate == today) {
        todayEvents.add(event);
      } else if (eventDate.isAfter(today) && eventDate.isBefore(endOfWeek)) {
        thisWeekEvents.add(event);
      } else if (eventDate.isAfter(today)) {
        upcomingEvents.add(event);
      }
    }

    final timeEvents = <String, List<Event>>{
      'today': todayEvents,
      'this_week': thisWeekEvents,
      'upcoming': upcomingEvents,
    };

    return FeedState(
      status: LoadingStatus.loaded,
      allEvents: events,
      reposts: reposts,
      spaceRecommendations: spaceRecommendations,
      hiveLabItems: hiveLabItems,
      hasMoreEvents: hasMoreEvents,
      currentPage: currentPage,
      isLoadingMore: false,
      categorizedEvents: categorizedEvents,
      timeEvents: timeEvents,
      isInitialized: true,
    );
  }

  /// Create a state from individual items
  factory FeedState.fromItems({
    required List<Event> events,
    List<RepostItem> reposts = const [],
    List<SpaceRecommendation> spaceRecommendations = const [],
    List<HiveLabItem> hiveLabItems = const [],
    bool hasMoreEvents = true,
    int currentPage = 1,
  }) {
    // Create a feed with just events as feed items
    final feedItems = events.map((event) {
      return <String, dynamic>{
        'type': 'event',
        'data': event,
      };
    }).toList();
    
    // Create categorized events
    final categorizedEvents = <String, List<Event>>{};
    for (final event in events) {
      final category = event.category;
      if (!categorizedEvents.containsKey(category)) {
        categorizedEvents[category] = [];
      }
      categorizedEvents[category]!.add(event);
    }

    // Create time-based events
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endOfWeek = today.add(const Duration(days: 7));

    final todayEvents = <Event>[];
    final thisWeekEvents = <Event>[];
    final upcomingEvents = <Event>[];

    for (final event in events) {
      final eventDate = DateTime(
        event.startDate.year,
        event.startDate.month,
        event.startDate.day,
      );

      if (eventDate == today) {
        todayEvents.add(event);
      } else if (eventDate.isAfter(today) && eventDate.isBefore(endOfWeek)) {
        thisWeekEvents.add(event);
      } else if (eventDate.isAfter(today)) {
        upcomingEvents.add(event);
      }
    }

    final timeEvents = <String, List<Event>>{
      'today': todayEvents,
      'this_week': thisWeekEvents,
      'upcoming': upcomingEvents,
    };

    return FeedState(
      status: LoadingStatus.loaded,
      allEvents: events,
      reposts: reposts,
      spaceRecommendations: spaceRecommendations,
      hiveLabItems: hiveLabItems,
      feedItems: feedItems,
      hasMoreEvents: hasMoreEvents,
      currentPage: currentPage,
      isLoadingMore: false,
      categorizedEvents: categorizedEvents,
      timeEvents: timeEvents,
      isInitialized: true,
    );
  }

  /// Create an error state
  factory FeedState.error(String message) {
    return FeedState(
      status: LoadingStatus.error,
      errorMessage: message,
      hasMoreEvents: false,
      isLoadingMore: false,
    );
  }

  /// Create a copy with some fields replaced
  FeedState copyWith({
    LoadingStatus? status,
    List<Event>? allEvents,
    List<RepostItem>? reposts,
    List<SpaceRecommendation>? spaceRecommendations,
    List<HiveLabItem>? hiveLabItems,
    List<Event>? forYouEvents,
    List<Map<String, dynamic>>? feedItems,
    EventFilters? filters,
    PaginationState? pagination,
    String? errorMessage,
    bool? hasMoreEvents,
    int? currentPage,
    bool? isLoadingMore,
    Map<String, List<Event>>? categorizedEvents,
    Map<String, List<Event>>? timeEvents,
    bool? isInitialized,
    List<Event>? searchResults,
    bool? isSearchActive,
    String? searchQuery,
    bool clearError = false,
    bool clearSearchQuery = false,
  }) {
    return FeedState(
      status: status ?? this.status,
      allEvents: allEvents ?? this.allEvents,
      reposts: reposts ?? this.reposts,
      spaceRecommendations: spaceRecommendations ?? this.spaceRecommendations,
      hiveLabItems: hiveLabItems ?? this.hiveLabItems,
      forYouEvents: forYouEvents ?? this.forYouEvents,
      feedItems: feedItems ?? this.feedItems,
      filters: filters ?? this.filters,
      pagination: pagination ?? this.pagination,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      hasMoreEvents: hasMoreEvents ?? this.hasMoreEvents,
      currentPage: currentPage ?? this.currentPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      categorizedEvents: categorizedEvents ?? this.categorizedEvents,
      timeEvents: timeEvents ?? this.timeEvents,
      isInitialized: isInitialized ?? this.isInitialized,
      searchResults: searchResults ?? this.searchResults,
      isSearchActive: isSearchActive ?? this.isSearchActive,
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
    );
  }

  /// Helper method to get filtered events based on current filters
  List<Event> get filteredEvents {
    if (!filters.hasActiveFilters) return allEvents;
    return allEvents.where((event) => filters.matches(event)).toList();
  }

  /// Get filtered today events
  List<Event> get filteredTodayEvents {
    final todayEvents = timeEvents['today'] ?? [];
    return todayEvents.where((event) => filters.matches(event)).toList();
  }

  /// Get filtered this week events
  List<Event> get filteredThisWeekEvents {
    final thisWeekEvents = timeEvents['this_week'] ?? [];
    return thisWeekEvents.where((event) => filters.matches(event)).toList();
  }

  /// Get filtered upcoming events
  List<Event> get filteredUpcomingEvents {
    final upcomingEvents = timeEvents['upcoming'] ?? [];
    return upcomingEvents.where((event) => filters.matches(event)).toList();
  }
}
