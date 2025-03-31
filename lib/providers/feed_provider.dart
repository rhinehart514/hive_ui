import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/feed_state.dart';
import '../models/event.dart';
import '../models/event_creation_request.dart';
import '../services/rss_service.dart';
import '../services/event_service.dart';
import '../providers/profile_provider.dart';
import '../models/user_profile.dart';
import '../services/space_event_manager.dart';
import '../utils/space_categorizer.dart';
import 'dart:math';
import '../services/optimized_data_service.dart';
import '../models/space_type.dart';
import '../providers/personalization_provider.dart';
import '../features/auth/providers/auth_providers.dart';
import '../models/interactions/interaction.dart';
import '../services/interactions/interaction_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Simple RepostInfo class to replace the deleted implementation
class RepostInfo {
  final String userId;
  final String userName;
  final String? avatarUrl;
  final String? comment;
  final DateTime createdAt;

  const RepostInfo({
    required this.userId,
    required this.userName,
    this.avatarUrl,
    this.comment,
    required this.createdAt,
  });
}

/// Provider for the feed state
final feedStateProvider = StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  return FeedNotifier(ref);
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

/// Provider for event categories
final eventCategoriesProvider = Provider<List<String>>((ref) {
  final state = ref.watch(feedStateProvider);
  final categories = state.categorizedEvents.keys.toList();
  categories.sort();
  return categories;
});

/// Provider to track RSVP state for each event
final eventRsvpStateProvider =
    StateProvider.family<bool, String>((ref, eventId) => false);

/// Provider to track saved events
final savedEventsProvider = StateProvider<List<String>>((ref) => []);

/// Provider to track events with reminders set
final eventRemindersProvider = StateProvider<List<String>>((ref) => []);

/// Controller for the feed state
class FeedNotifier extends StateNotifier<FeedState> {
  final Ref _ref;

  /// Constructor
  FeedNotifier(this._ref) : super(FeedState.initial()) {
    // Initial load
    fetchEvents();
  }

  /// Set loading more state
  void setLoadingMore(bool isLoading) {
    state = state.copyWith(isLoadingMore: isLoading);
  }

  /// Fetch events and update state
  Future<void> fetchEvents({bool refresh = false}) async {
    try {
      if (refresh) {
        state = state.copyWith(
          status: LoadingStatus.refreshing,
          pagination: const PaginationState(),
          currentPage: 1,
          hasMoreEvents: true,
        );
      } else if (state.status == LoadingStatus.initial) {
        state = FeedState.loading();
      }

      debugPrint('======= FETCHING EVENTS DIRECTLY FROM EVENTS COLLECTION =======');
      
      final firestore = FirebaseFirestore.instance;
      final List<Event> allEvents = [];
      final Set<String> processedEventIds = {};

      // Directly query the global events collection
      final eventsQuery = await firestore
          .collection('events')
          .orderBy('startDate')
          .limit(30) // Increased limit to get more events initially
          .get();
      
      debugPrint('Retrieved ${eventsQuery.docs.length} events from events collection');

      // Process events
      for (final doc in eventsQuery.docs) {
        try {
          final data = doc.data();
          // Process timestamps if needed
          final processedData = _processTimestamps(data);
          final event = Event.fromJson(processedData);
          
          if (!processedEventIds.contains(event.id)) {
            processedEventIds.add(event.id);
            allEvents.add(event);
          }
        } catch (e) {
          debugPrint('Error parsing event ${doc.id}: $e');
        }
      }

      // Sort events by start date
      allEvents.sort((a, b) => a.startDate.compareTo(b.startDate));

      // Generate personalized feed using the personalization engine
      final personalizedEvents = await _generatePersonalizedFeed(allEvents);

      // Fetch additional content for feed
      final reposts = await _fetchReposts();
      final spaceRecommendations = await _fetchSpaceRecommendations();
      final hiveLabItems = await _fetchHiveLabItems();

      debugPrint('Updating feed with ${allEvents.length} events');

      // Determine if there might be more events
      final hasMore = allEvents.length >= 20;

      state = FeedState.fromItems(
        events: allEvents,
        reposts: reposts,
        spaceRecommendations: spaceRecommendations,
        hiveLabItems: hiveLabItems,
        hasMoreEvents: hasMore,
        currentPage: 1,
      ).copyWith(
        forYouEvents: personalizedEvents,
      );

      // Log feed view interaction
      _logFeedViewInteraction();
    } catch (e) {
      debugPrint('Error in fetchEvents: $e');
      state = FeedState.error('Failed to load feed: $e');
    }
  }
  
  /// Helper method to process Firestore timestamps into DateTime
  Map<String, dynamic> _processTimestamps(Map<String, dynamic> data) {
    final result = Map<String, dynamic>.from(data);

    // Convert Timestamps to DateTime for serialization
    result.forEach((key, value) {
      if (value is Timestamp) {
        result[key] = value.toDate();
      } else if (value is Map) {
        result[key] = _processTimestamps(Map<String, dynamic>.from(value));
      }
    });

    return result;
  }

  /// Helper method to convert Space.spaceType to collection string
  String getTypeCollectionFromSpaceType(SpaceType type) {
    switch (type) {
      case SpaceType.studentOrg:
        return 'student_organizations';
      case SpaceType.universityOrg:
        return 'university_organizations';
      case SpaceType.campusLiving:
        return 'campus_living';
      case SpaceType.fraternityAndSorority:
        return 'fraternity_and_sorority';
      case SpaceType.other:
        return 'other';
    }
  }

  /// Generate personalized "For You" feed based on user interactions and interests
  Future<List<Event>> _generatePersonalizedFeed(List<Event> events) async {
    if (events.isEmpty) return [];

    try {
      // Get current user
      final user = _ref.read(currentUserProvider);

      // If no user, return generic recommendations
      if (user.isNotEmpty == false) {
        return _generateGenericRecommendations(events);
      }

      // Use personalization engine to score events
      final scoredEvents =
          await _ref.read(personalizedEventsProvider(events).future);

      // Return events sorted by score
      return scoredEvents.map((scored) => scored.event).toList();
    } catch (e) {
      debugPrint('Error generating personalized feed: $e');
      return _generateGenericRecommendations(events);
    }
  }

  /// Generate generic recommendations when user profile not available
  List<Event> _generateGenericRecommendations(List<Event> events) {
    if (events.isEmpty) return [];

    // Sort by date, with preference for upcoming events
    final now = DateTime.now();
    final upcomingEvents =
        events.where((e) => e.startDate.isAfter(now)).toList();

    // Sort by start date
    upcomingEvents.sort((a, b) => a.startDate.compareTo(b.startDate));

    // Take the closest 20 events
    return upcomingEvents.take(20).toList();
  }

  /// Categorize events by category
  static Map<String, List<Event>> _categorizeByCategory(List<Event> events) {
    final result = <String, List<Event>>{};

    for (final event in events) {
      final category = event.category;
      if (!result.containsKey(category)) {
        result[category] = [];
      }
      result[category]!.add(event);
    }

    return result;
  }

  /// Categorize events by time
  static Map<String, List<Event>> _categorizeByTime(List<Event> events) {
    final result = <String, List<Event>>{
      'today': [],
      'thisWeek': [],
      'upcoming': [],
    };

    final now = DateTime.now();

    for (final event in events) {
      if (event.isToday) {
        result['today']!.add(event);
      } else if (event.isThisWeek) {
        result['thisWeek']!.add(event);
      } else if (event.startDate.isAfter(now)) {
        result['upcoming']!.add(event);
      }
    }

    return result;
  }

  /// Load more events for infinite scrolling (pagination)
  Future<void> loadMoreEvents() async {
    if (!state.pagination.hasMore ||
        state.status == LoadingStatus.loading ||
        state.status == LoadingStatus.refreshing) {
      return;
    }

    try {
      // Update pagination state
      final newPagination = state.pagination.nextPage();
      state = state.copyWith(pagination: newPagination);

      // Simplified pagination - we'll just get more events without using startAfter
      // In a real implementation, we would track the last document cursor

      // Fetch next page of events
      final currentEvents = state.allEvents;
      final nextPageEvents = await SpaceEventManager.getAllEvents(
        limit: state.pagination.pageSize,
        startDate: DateTime.now(),
      );

      // Filter out events we already have
      final existingIds = currentEvents.map((e) => e.id).toSet();
      final newEvents =
          nextPageEvents.where((e) => !existingIds.contains(e.id)).toList();

      // If no new events or less than expected, we're at the end
      if (newEvents.isEmpty || newEvents.length < state.pagination.pageSize) {
        state = state.copyWith(
          pagination: state.pagination.copyWith(hasMore: false),
        );
      }

      // Add new events to state
      if (newEvents.isNotEmpty) {
        final combinedEvents = [...currentEvents, ...newEvents];
        final personalizedEvents =
            await _generatePersonalizedFeed(combinedEvents);

        state = state.copyWith(
          allEvents: combinedEvents,
          forYouEvents: personalizedEvents,
          categorizedEvents: _categorizeByCategory(combinedEvents),
          timeEvents: _categorizeByTime(combinedEvents),
        );
      }
    } catch (e) {
      // Don't change to error state - just keep current state and show a snackbar
      debugPrint('Error loading more events: $e');
    }
  }

  /// Create a new user event
  Future<bool> createEvent(EventCreationRequest request) async {
    try {
      // Create a user event following the existing pattern in Event class
      final userId = _getCurrentUserId();
      final userName = _getCurrentUserName();

      final event = Event.createUserEvent(
        title: request.title,
        description: request.description,
        location: request.location,
        startDate: request.startDate,
        endDate: request.endDate,
        userId: userId,
        organizerName:
            request.organizerName.isNotEmpty ? request.organizerName : userName,
        category: request.category,
        organizerEmail: request.organizerEmail,
        visibility: request.visibility,
        tags: request.tags,
        imageUrl: request.imageUrl,
      );

      // Save to persistent storage
      await EventService.saveUserEvent(event);

      // Add to state
      final newEvents = [...state.allEvents, event];

      state = state.copyWith(
        allEvents: newEvents,
        categorizedEvents: _categorizeByCategory(newEvents),
        timeEvents: _categorizeByTime(newEvents),
      );

      return true;
    } catch (e) {
      debugPrint('Error creating event: $e');
      return false;
    }
  }

  /// Helper method to get current user ID
  String _getCurrentUserId() {
    final userProfileState = _ref.read(profileProvider);
    return userProfileState.profile?.id ??
        'unknown_user_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Helper method to get current user name
  String _getCurrentUserName() {
    final userProfileState = _ref.read(profileProvider);
    return userProfileState.profile?.username ?? 'Unknown User';
  }

  /// Update saved events for a user
  Future<void> updateSavedEvents(
      UserProfile profile, Event event, bool isSaving) async {
    try {
      // Create a new list from the current saved events or an empty list if null
      final currentEvents = List<Event>.from(profile.savedEvents);
      List<Event> updatedEvents;

      if (isSaving) {
        updatedEvents = [...currentEvents, event];
      } else {
        updatedEvents = currentEvents.where((e) => e.id != event.id).toList();
      }

      // Create updated profile with new saved events
      final updatedProfile = profile.copyWith(
        savedEvents: updatedEvents,
        updatedAt: DateTime.now(),
      );

      // Convert to Map<String, dynamic> for Firestore
      final profileData = updatedProfile.toJson();

      // Update profile in Firestore
      await _ref.read(profileProvider.notifier).updateProfile(profileData);
    } catch (e) {
      debugPrint('Error updating saved events: $e');
    }
  }

  /// Delete an event
  Future<bool> deleteEvent(String eventId) async {
    try {
      // Find the event in our state to get its space info
      final event = state.allEvents.firstWhere(
        (e) => e.id == eventId,
        orElse: () => throw Exception('Event not found'),
      );

      // Generate a space ID from organizer name
      final normalizedName = event.organizerName
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .trim()
          .replaceAll(RegExp(r'\s+'), '_');
      final spaceId = 'space_$normalizedName';

      // Determine the space type
      final spaceType = SpaceCategorizer.categorizeFromEvent(event);
      final typeCollection =
          SpaceEventManager.getTypeCollectionString(spaceType);

      // Delete the event
      final success = await SpaceEventManager.deleteEvent(
        eventId: eventId,
        spaceId: spaceId,
        spaceType: typeCollection,
      );

      if (success) {
        // Update state
        final newEvents =
            state.allEvents.where((e) => e.id != eventId).toList();

        state = state.copyWith(
          allEvents: newEvents,
          categorizedEvents: _categorizeByCategory(newEvents),
          timeEvents: _categorizeByTime(newEvents),
        );
      }

      return success;
    } catch (e) {
      debugPrint('Error deleting event: $e');
      return false;
    }
  }

  /// RSVP to (or un-RSVP from) an event
  Future<void> rsvpToEvent(String eventId, bool rsvp) async {
    try {
      // Find the event in our state
      final event = state.allEvents.firstWhere(
        (e) => e.id == eventId,
        orElse: () => throw Exception('Event not found'),
      );

      final profileNotifier = _ref.read(profileProvider.notifier);

      if (rsvp) {
        await profileNotifier.saveEvent(event);
      } else {
        // Profile provider method signature is different
        // In a production app, you would need to add a removeEvent method
        // that takes an eventId
        // This is a simplified implementation
        final profileState = _ref.read(profileProvider);
        if (profileState is AsyncData<UserProfile>) {
          final newSavedEvents = profileState.value?.savedEvents
                  .where((e) => e.id != eventId)
                  .toList() ??
              [];

          final updatedProfile = profileState.value?.copyWith(
            savedEvents: newSavedEvents,
          );

          if (updatedProfile != null) {
            await profileNotifier.updateProfile(updatedProfile.toJson());
          }
        }
      }
    } catch (e) {
      debugPrint('Error updating RSVP status: $e');
    }
  }

  /// Set search query filter
  void setSearchQuery(String query) {
    final newFilters = state.filters.copyWith(
      searchQuery: query.isEmpty ? null : query,
    );

    state = state.copyWith(filters: newFilters);
  }

  /// Set category filter
  void setCategoryFilter(List<String> categories) {
    final newFilters = state.filters.copyWith(
      categories: categories,
    );

    state = state.copyWith(filters: newFilters);
  }

  /// Set date range filter
  void setDateRangeFilter(DateTimeRange? dateRange) {
    final newFilters = state.filters.copyWith(
      dateRange: dateRange,
    );

    state = state.copyWith(filters: newFilters);
  }

  /// Clear all filters
  void clearFilters() {
    state = state.copyWith(filters: const EventFilters());
  }

  /// Resyncs all RSS events and refreshes the feed
  /// This will ensure all events are properly stored in spaces
  /// Events that don't match a space will be stored in the lost_events collection
  Future<Map<String, dynamic>> resyncRssEvents() async {
    try {
      // Set state to refreshing
      state = state.copyWith(
        status: LoadingStatus.refreshing,
        clearError: true,
      );

      // Resync all RSS events
      final results = await RssService.resyncAllRssEvents();

      // After resync, fetch events to update the feed
      await fetchEvents(refresh: true);

      return results;
    } catch (e) {
      // Handle error but don't change feed state since fetchEvents will do that
      debugPrint('Error resyncing RSS events: $e');
      return {
        'error': 1,
        'message': e.toString(),
      };
    }
  }

  /// Create sample repost items for demonstration
  List<RepostItem> _createSampleReposts(List<Event> events) {
    if (events.isEmpty) return [];

    // Use up to 3 events for reposts
    final repostEvents = events.length > 3 ? events.sublist(0, 3) : events;

    // Sample reposter names
    final reposterNames = [
      'Alex Turner',
      'Jamie Smith',
      'Michael Johnson',
      'Emma Davis',
    ];

    // Sample comments
    final comments = [
      'This event looks amazing! Who\'s going?',
      'Can\'t wait for this one!',
      'I attended this last year and it was fantastic.',
      'Anyone interested in joining me?',
      null, // Some reposts won't have comments
    ];

    // Create reposts
    final random = Random();
    final reposts = <RepostItem>[];

    for (final event in repostEvents) {
      final reposterName = reposterNames[random.nextInt(reposterNames.length)];
      final comment = comments[random.nextInt(comments.length)];

      // Create a repost 1-3 days ago
      final repostTime = DateTime.now().subtract(
        Duration(
          days: random.nextInt(3) + 1,
          hours: random.nextInt(24),
          minutes: random.nextInt(60),
        ),
      );

      reposts.add(
        RepostItem(
          event: event,
          comment: comment,
          reposterName: reposterName,
          repostTime: repostTime,
          reposterImageUrl:
              'https://picsum.photos/200?random=${random.nextInt(100)}',
        ),
      );
    }

    return reposts;
  }

  /// Create sample space recommendations
  List<SpaceRecommendation> _createSampleSpaceRecommendations() {
    // Create a diverse set of space recommendations
    return [
      const SpaceRecommendation(
        name: 'Photography Club',
        category: 'Arts',
        description: 'Share your passion for photography with fellow students.',
        memberCount: 128,
        isOfficial: true,
      ),
      const SpaceRecommendation(
        name: 'AI Research Group',
        category: 'Technology',
        description:
            'Explore the latest in artificial intelligence and machine learning.',
        memberCount: 75,
        isOfficial: true,
      ),
      const SpaceRecommendation(
        name: 'Basketball Team',
        category: 'Sports',
        description: 'Join us for weekly games and practice sessions.',
        memberCount: 42,
      ),
    ];
  }

  /// Create sample HIVE Lab items
  List<HiveLabItem> _createSampleHiveLabItems() {
    return [
      const HiveLabItem(
        title: 'Help Shape HIVE',
        description:
            'Suggest features, report bugs, and help make HIVE better for everyone.',
        actionLabel: 'Join HIVE Lab',
      ),
      const HiveLabItem(
        title: 'Upcoming Feature: Group Chats',
        description:
            'Group messaging is coming soon! Help us test this feature early.',
        actionLabel: 'Join Beta',
      ),
    ];
  }

  /// Create sample repost items for demonstration
  Future<List<RepostItem>> _fetchReposts() async {
    // Implementation of _createSampleReposts
    return _createSampleReposts(state.allEvents);
  }

  /// Create sample space recommendations
  Future<List<SpaceRecommendation>> _fetchSpaceRecommendations() async {
    // Implementation of _createSampleSpaceRecommendations
    return _createSampleSpaceRecommendations();
  }

  /// Create sample HIVE Lab items
  Future<List<HiveLabItem>> _fetchHiveLabItems() async {
    // Implementation of _createSampleHiveLabItems
    return _createSampleHiveLabItems();
  }

  /// Log feed view interaction
  void _logFeedViewInteraction() {
    try {
      // Get current user
      final user = _ref.read(currentUserProvider);

      // Skip if no user
      if (user.isNotEmpty == false) return;

      // Log interaction
      InteractionService.logInteraction(
        userId: user.id,
        entityId: 'main_feed',
        entityType: EntityType.event, // Using event type for feed
        action: InteractionAction.view,
        metadata: {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'feedSize': state.allEvents.length,
        },
      );
    } catch (e) {
      // Silently fail - logging interaction is not critical
      debugPrint('Error logging feed view interaction: $e');
    }
  }

  /// Log event view interaction
  Future<void> logEventView(Event event) async {
    try {
      // Get current user
      final user = _ref.read(currentUserProvider);

      // Skip if no user
      if (user.isNotEmpty == false) return;

      // Log interaction
      await InteractionService.logInteraction(
        userId: user.id,
        entityId: event.id,
        entityType: EntityType.event,
        action: InteractionAction.view,
        metadata: {
          'title': event.title,
          'category': event.category,
          'tags': event.tags,
        },
      );
    } catch (e) {
      // Silently fail - logging interaction is not critical
      debugPrint('Error logging event view interaction: $e');
    }
  }

  /// Log event RSVP interaction
  Future<void> logEventRSVP(Event event) async {
    try {
      // Get current user
      final user = _ref.read(currentUserProvider);

      // Skip if no user
      if (user.isNotEmpty == false) return;

      // Log interaction (high priority to ensure it's processed immediately)
      await InteractionService.logInteraction(
        userId: user.id,
        entityId: event.id,
        entityType: EntityType.event,
        action: InteractionAction.rsvp,
        metadata: {
          'title': event.title,
          'category': event.category,
          'tags': event.tags,
        },
        highPriority: true,
      );
    } catch (e) {
      // Silently fail - logging interaction is not critical
      debugPrint('Error logging event RSVP interaction: $e');
    }
  }

  /// Repost an event
  Future<bool> repostEvent({
    required Event event,
    required RepostInfo repostInfo,
  }) async {
    try {
      // Get the current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('You must be logged in to repost');
      }

      // Create repost data for Firestore
      final repostData = {
        'eventId': event.id,
        'userId': repostInfo.userId,
        'userName': repostInfo.userName,
        'avatarUrl': repostInfo.avatarUrl,
        'comment': repostInfo.comment,
        'createdAt': Timestamp.fromDate(repostInfo.createdAt),
      };

      // Add to reposts collection
      await FirebaseFirestore.instance.collection('reposts').add(repostData);

      // Update local state with new repost
      // In a real app, you might fetch all reposts from Firestore

      // Return success
      return true;
    } catch (e) {
      debugPrint('Error reposting event: $e');
      rethrow;
    }
  }
}
