import 'package:flutter/material.dart';
import 'event.dart';
import 'repost_content_type.dart';
import 'space_recommendation_simple.dart';
import 'hive_lab_item_simple.dart';
import 'user_profile.dart';

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

  /// Quoted event with comment
  quote,

  /// Boosted event with higher visibility
  boostedEvent,

  /// Suggestion for a space
  spaceRecommendation,

  /// Friend recommendation
  friendRecommendation,

  /// HIVE Lab card for feature requests
  hiveLab,
}

/// Item representing a reposted event in the feed
class RepostItem {
  /// The reposted event
  final Event event;
  
  /// The user profile who reposted the event
  final UserProfile reposterProfile;
  
  /// The time when the event was reposted
  final DateTime repostTime;
  
  /// Optional comment text for quote reposts
  final String? comment;
  
  /// Type of repost (standard, quote, highlight)
  final RepostContentType contentType;
  
  /// Constructor
  const RepostItem({
    required this.event,
    required this.reposterProfile,
    required this.repostTime,
    this.comment,
    this.contentType = RepostContentType.standard,
  });
  
  /// Create a copy with some fields replaced
  RepostItem copyWith({
    Event? event,
    UserProfile? reposterProfile,
    DateTime? repostTime,
    String? comment,
    RepostContentType? contentType,
  }) {
    return RepostItem(
      event: event ?? this.event,
      reposterProfile: reposterProfile ?? this.reposterProfile,
      repostTime: repostTime ?? this.repostTime,
      comment: comment ?? this.comment,
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

/// Model for feed state
class FeedState {
  /// All events in the feed
  final List<Event> events;

  /// Reposts in the feed
  final List<RepostItem> reposts;

  /// Space recommendations
  final List<SpaceRecommendationSimple> spaceRecommendations;

  /// HIVE lab items
  final List<HiveLabItemSimple> hiveLabItems;

  /// Loading status
  final LoadingStatus status;

  /// Error message if status is error
  final String? errorMessage;

  /// Whether more events are being loaded
  final bool isLoadingMore;

  /// Current page number
  final int currentPage;

  /// Whether there are more events to load
  final bool hasMoreEvents;

  /// Event filters
  final EventFilters filters;

  /// Pagination state
  final PaginationState pagination;

  /// Feed items combined from events, reposts and other items
  final List<Map<String, dynamic>> feedItems;

  /// Get events categorized by their category
  Map<String, List<Event>> get categorizedEvents {
    final result = <String, List<Event>>{};
    for (final event in filteredEvents) {
      final category = event.category;
      if (!result.containsKey(category)) {
        result[category] = [];
      }
      result[category]!.add(event);
    }
    return result;
  }

  /// Constructor
  const FeedState({
    this.events = const [],
    this.reposts = const [],
    this.spaceRecommendations = const [],
    this.hiveLabItems = const [],
    this.status = LoadingStatus.initial,
    this.errorMessage,
    this.isLoadingMore = false,
    this.currentPage = 1,
    this.hasMoreEvents = true,
    this.filters = const EventFilters(),
    this.pagination = const PaginationState(),
    this.feedItems = const [],
  });

  /// Initial state
  factory FeedState.initial() {
    return const FeedState();
  }

  /// Loading state
  factory FeedState.loading() {
    return const FeedState(status: LoadingStatus.loading);
  }

  /// Error state
  factory FeedState.error(String message) {
    return FeedState(
      status: LoadingStatus.error,
      errorMessage: message,
    );
  }

  /// Create from items
  factory FeedState.fromItems({
    required List<Event> events,
    required List<RepostItem> reposts,
    required List<SpaceRecommendationSimple> spaceRecommendations,
    required List<HiveLabItemSimple> hiveLabItems,
    bool hasMoreEvents = true,
    int currentPage = 1,
    List<Map<String, dynamic>> feedItems = const [],
  }) {
    return FeedState(
      events: events,
      reposts: reposts,
      spaceRecommendations: spaceRecommendations,
      hiveLabItems: hiveLabItems,
      status: LoadingStatus.loaded,
      hasMoreEvents: hasMoreEvents,
      currentPage: currentPage,
      feedItems: feedItems,
    );
  }

  /// Create a copy with some fields replaced
  FeedState copyWith({
    List<Event>? events,
    List<RepostItem>? reposts,
    List<SpaceRecommendationSimple>? spaceRecommendations,
    List<HiveLabItemSimple>? hiveLabItems,
    LoadingStatus? status,
    String? errorMessage,
    bool? isLoadingMore,
    int? currentPage,
    bool? hasMoreEvents,
    EventFilters? filters,
    PaginationState? pagination,
    List<Event>? forYouEvents,
    List<Event>? allEvents,
    Map<String, List<Event>>? categorizedEvents,
    Map<String, List<Event>>? timeEvents,
    List<Map<String, dynamic>>? feedItems,
    bool clearErrorMessage = false,
  }) {
    return FeedState(
      events: allEvents ?? events ?? this.events,
      reposts: reposts ?? this.reposts,
      spaceRecommendations: spaceRecommendations ?? this.spaceRecommendations,
      hiveLabItems: hiveLabItems ?? this.hiveLabItems,
      status: status ?? this.status,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      currentPage: currentPage ?? this.currentPage,
      hasMoreEvents: hasMoreEvents ?? this.hasMoreEvents,
      filters: filters ?? this.filters,
      pagination: pagination ?? this.pagination,
      feedItems: feedItems ?? this.feedItems,
    );
  }

  /// Helper method to get filtered events based on current filters
  List<Event> get filteredEvents {
    if (!filters.hasActiveFilters) return events;
    return events.where((event) => filters.matches(event)).toList();
  }

  /// Get today's events
  List<Event> get filteredTodayEvents {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return filteredEvents.where((event) {
      final eventDate = DateTime(
        event.startDate.year,
        event.startDate.month,
        event.startDate.day,
      );
      return eventDate == today;
    }).toList();
  }

  /// Get this week's events
  List<Event> get filteredThisWeekEvents {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endOfWeek = today.add(const Duration(days: 7));
    return filteredEvents.where((event) {
      final eventDate = DateTime(
        event.startDate.year,
        event.startDate.month,
        event.startDate.day,
      );
      return eventDate.isAfter(today) && eventDate.isBefore(endOfWeek);
    }).toList();
  }

  /// Get upcoming events
  List<Event> get filteredUpcomingEvents {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return filteredEvents.where((event) {
      final eventDate = DateTime(
        event.startDate.year,
        event.startDate.month,
        event.startDate.day,
      );
      return eventDate.isAfter(today);
    }).toList();
  }

  /// Get personalized "For You" events
  List<Event> get forYouEvents => filteredEvents;

  /// Alias for events - for backward compatibility
  List<Event> get allEvents => events;

  /// Alias for categorizing events by time - for backward compatibility
  Map<String, List<Event>> get timeEvents {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final endOfWeek = today.add(const Duration(days: 7));
    
    return {
      'today': filteredTodayEvents,
      'thisWeek': filteredThisWeekEvents,
      'upcoming': filteredUpcomingEvents,
    };
  }
}
