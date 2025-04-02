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
import '../models/repost_content_type.dart';
import '../services/space_event_manager.dart';
import '../utils/space_categorizer.dart';
import '../models/space_type.dart';
import '../providers/personalization_provider.dart';
import '../features/auth/providers/auth_providers.dart';
import '../models/interactions/interaction.dart';
import '../services/interactions/interaction_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/space_recommendation_simple.dart';
import '../models/hive_lab_item_simple.dart';

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
      final now = DateTime.now();

      // Directly query the global events collection for upcoming events
      final eventsQuery = await firestore
          .collection('events')
          .where('startDate', isGreaterThan: Timestamp.fromDate(now))
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
          
          // Double-check that event is in the future
          if (event.endDate.isAfter(now) && !processedEventIds.contains(event.id)) {
            processedEventIds.add(event.id);
            allEvents.add(event);
          }
        } catch (e) {
          debugPrint('Error parsing event ${doc.id}: $e');
        }
      }

      // Sort events by start date (soonest first)
      allEvents.sort((a, b) => a.startDate.compareTo(b.startDate));

      // Get reposts to integrate them into the feed
      final reposts = await _fetchReposts();
      
      // Filter reposts to only include those with future events
      final filteredReposts = reposts.where((repost) => 
          repost.event.endDate.isAfter(now)).toList();
      
      // Create a combined list of events and reposts
      final List<Map<String, dynamic>> feedItems = [];
      
      // Add original events as regular feed items
      for (final event in allEvents) {
        feedItems.add({
          'type': 'event',
          'data': event,
          'sortKey': event.startDate.millisecondsSinceEpoch
        });
      }
      
      // Add reposts as repost feed items
      for (final repost in filteredReposts) {
        // Skip reposts of events we've already added
        if (!allEvents.any((e) => e.id == repost.event.id)) {
          feedItems.add({
            'type': 'repost',
            'data': RepostItem(
              event: repost.event,
              reposterProfile: repost.reposterProfile,
              repostTime: repost.repostTime,
              comment: repost.comment,
              contentType: repost.contentType == 'quote' 
                ? RepostContentType.quote 
                : RepostContentType.standard,
            ),
            'sortKey': repost.event.startDate.millisecondsSinceEpoch
          });
        }
      }
      
      // Sort combined feed - events by start date (soonest first)
      feedItems.sort((a, b) {
        final aType = a['type'] as String;
        final bType = b['type'] as String;
        
        // If both are events, sort by start date (soonest first)
        if (aType == 'event' && bType == 'event') {
          final aEvent = a['data'] as Event;
          final bEvent = b['data'] as Event;
          return aEvent.startDate.compareTo(bEvent.startDate);
        }
        
        // If one is an event and one is a repost, prioritize the event
        if (aType == 'event' && bType == 'repost') {
          return -1;
        }
        if (aType == 'repost' && bType == 'event') {
          return 1;
        }
        
        // For reposts, sort by the event's start date
        final aRepost = a['data'] as RepostItem;
        final bRepost = b['data'] as RepostItem;
        return aRepost.event.startDate.compareTo(bRepost.event.startDate);
      });

      // Generate personalized feed using the personalization engine
      final personalizedEvents = await _generatePersonalizedFeed(allEvents);

      // Fetch additional content for feed
      final spaceRecommendations = await _fetchSpaceRecommendations();
      final hiveLabItems = await _fetchHiveLabItems();

      debugPrint('Updating feed with ${allEvents.length} events and ${filteredReposts.length} reposts');

      // Determine if there might be more events
      final hasMore = allEvents.length >= 20;

      state = state.copyWith(
        feedItems: feedItems,
        events: allEvents,
        reposts: filteredReposts,
        spaceRecommendations: spaceRecommendations,
        hiveLabItems: hiveLabItems,
        forYouEvents: personalizedEvents,
        status: LoadingStatus.loaded,
        hasMoreEvents: hasMore,
        currentPage: 1,
        clearErrorMessage: true,
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
      case SpaceType.hiveExclusive:
        return 'hive_exclusive';
      case SpaceType.other:
        return 'other';
    }
  }

  /// Generate personalized "For You" feed based on user interactions and interests
  Future<List<Event>> _generatePersonalizedFeed(List<Event> events) async {
    if (events.isEmpty) return [];

    try {
      final user = _ref.read(currentUserProvider);
      if (user.isNotEmpty == false) {
        return _generateGenericRecommendations(events);
      }
      final scoredEvents =
          await _ref.read(personalizedEventsProvider(events).future);
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

  /// Load more events for infinite scrolling
  Future<void> loadMoreEvents() async {
    try {
      if (state.isLoadingMore || !state.hasMoreEvents) {
        return;
      }
      setLoadingMore(true);
      debugPrint('Loading more events (page ${state.currentPage + 1})...');
      
      final lastEventId = state.events.isNotEmpty ? state.events.last.id : null;
      if (lastEventId == null) {
        setLoadingMore(false);
        return;
      }
      
      final lastEvent = state.events.last;
      final lastTimestamp = lastEvent.startDate;
      final firestore = FirebaseFirestore.instance;
      final now = DateTime.now();
      
      // Query for events after the last one we have
      final newEventsQuery = await firestore
          .collection('events')
          .where('startDate', isGreaterThan: lastTimestamp)
          .orderBy('startDate')
          .limit(20)
          .get();

      final List<Event> newEvents = [];
      for (final doc in newEventsQuery.docs) {
        try {
          final data = doc.data();
          final processedData = _processTimestamps(data);
          final event = Event.fromJson(processedData);
          
          // Only add future events
          if (event.endDate.isAfter(now)) {
            newEvents.add(event);
          }
        } catch (e) {
          debugPrint('Error parsing event ${doc.id}: $e');
        }
      }

      if (newEvents.isEmpty) {
        state = state.copyWith(hasMoreEvents: false, isLoadingMore: false);
        return;
      }

      // Combine with existing events
      final combinedEvents = [...state.events, ...newEvents];
      final processedEventIds = state.events.map((e) => e.id).toSet();
      final newFeedItems = <Map<String, dynamic>>[];
      
      // Add new events to feed items
      for (final event in newEvents) {
        if (!processedEventIds.contains(event.id)) {
          newFeedItems.add({
            'type': 'event',
            'data': event,
            'sortKey': event.startDate.millisecondsSinceEpoch,
          });
        }
      }
      
      // Combine with existing feed items
      final combinedFeedItems = [...state.feedItems, ...newFeedItems];
      
      // Re-sort the entire feed to ensure proper ordering
      combinedFeedItems.sort((a, b) {
        final aType = a['type'] as String;
        final bType = b['type'] as String;
        
        // If both are events, sort by start date (soonest first)
        if (aType == 'event' && bType == 'event') {
          final aEvent = a['data'] as Event;
          final bEvent = b['data'] as Event;
          return aEvent.startDate.compareTo(bEvent.startDate);
        }
        
        // If one is an event and one is a repost, prioritize the event
        if (aType == 'event' && bType == 'repost') {
          return -1;
        }
        if (aType == 'repost' && bType == 'event') {
          return 1;
        }
        
        // For reposts, sort by event's start date
        final aRepost = a['data'] as RepostItem;
        final bRepost = b['data'] as RepostItem;
        return aRepost.event.startDate.compareTo(bRepost.event.startDate);
      });
      
      state = state.copyWith(
        events: combinedEvents,
        feedItems: combinedFeedItems,
        currentPage: state.currentPage + 1,
        hasMoreEvents: newEvents.length >= 20,
        isLoadingMore: false,
      );

      debugPrint('Loaded ${newEvents.length} more events (total: ${combinedEvents.length})');
    } catch (e) {
      debugPrint('Error loading more events: $e');
      state = state.copyWith(isLoadingMore: false);
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
      final newEvents = [...state.events, event];

      state = state.copyWith(
        events: newEvents,
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
      final event = state.events.firstWhere(
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
            state.events.where((e) => e.id != eventId).toList();

        state = state.copyWith(
          events: newEvents,
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
      final event = state.events.firstWhere(
        (e) => e.id == eventId,
        orElse: () => throw Exception('Event not found'),
      );

      final profileNotifier = _ref.read(profileProvider.notifier);

      // Update backend first
      final success = await EventService.rsvpToEvent(eventId, rsvp);
      
      if (success) {
        if (rsvp) {
          await profileNotifier.saveEvent(event);
        } else {
          await profileNotifier.removeEvent(eventId);
        }
        
        // Refresh profile to ensure UI is up to date
        await profileNotifier.refreshProfile();
        
        // Update local feed state
        final updatedEvents = state.events.map((e) {
          if (e.id == eventId) {
            final currentAttendees = List<String>.from(e.attendees);
            final userId = _getCurrentUserId();
            
            if (rsvp && !currentAttendees.contains(userId)) {
              currentAttendees.add(userId);
            } else if (!rsvp && currentAttendees.contains(userId)) {
              currentAttendees.remove(userId);
            }
            
            return e.copyWith(attendees: currentAttendees);
          }
          return e;
        }).toList();
        
        state = state.copyWith(
          events: updatedEvents,
          categorizedEvents: _categorizeByCategory(updatedEvents),
          timeEvents: _categorizeByTime(updatedEvents),
        );
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
        errorMessage: null,
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

  /// Get reposts for the current feed state
  List<RepostItem> getReposts(FeedState state) {
    if (state.events.isEmpty) return [];
    return [];  // Return empty list instead of mock data
  }

  /// Fetch reposts from Firestore
  Future<List<RepostItem>> _fetchReposts() async {
    try {
      final repostsSnapshot = await FirebaseFirestore.instance
          .collection('reposts')
          .orderBy('repostedAt', descending: true)
          .limit(20)
          .get();
      
      if (repostsSnapshot.docs.isEmpty) {
        debugPrint('No reposts found in database');
        return [];
      }
      
      // Process reposts and load associated events and users
      final List<RepostItem> loadedReposts = [];
      
      for (final doc in repostsSnapshot.docs) {
        try {
          final data = doc.data();
          final eventId = data['eventId'] as String;
          final repostedById = data['repostedById'] as String;
          
          // Get the event document
          final eventDoc = await FirebaseFirestore.instance
              .collection('events')
              .doc(eventId)
              .get();
          
          if (!eventDoc.exists) {
            debugPrint('Event ${eventId} not found for repost');
            continue;
          }
          
          // Get the user profile document
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(repostedById)
              .get();
          
          if (!userDoc.exists) {
            debugPrint('User ${repostedById} not found for repost');
            continue;
          }
          
          // Create Event and UserProfile objects
          final eventData = eventDoc.data()!;
          eventData['id'] = eventDoc.id;
          final event = Event.fromJson(eventData);
          
          final userData = userDoc.data() ?? {};
          final userProfile = UserProfile(
            id: userDoc.id,
            displayName: userData['displayName'] ?? 'User',
            username: userData['username'] ?? 'user_${userDoc.id.substring(0, 5)}',
            profileImageUrl: userData['profileImageUrl'],
            email: userData['email'] ?? '',
            year: userData['year'] ?? '',
            major: userData['major'] ?? '',
            residence: userData['residence'] ?? '',
            eventCount: userData['eventCount'] ?? 0,
            clubCount: userData['clubCount'] ?? 0,
            friendCount: userData['friendCount'] ?? 0,
            createdAt: _parseTimestamp(userData['createdAt']),
            updatedAt: _parseTimestamp(userData['updatedAt']),
          );
          
          // Create RepostItem for feed
          final repost = RepostItem(
            event: event,
            reposterProfile: userProfile,
            repostTime: _parseTimestamp(data['repostedAt']),
            comment: data['comment'] as String?,
            contentType: data['repostType'] == 'quote' 
              ? RepostContentType.quote 
              : RepostContentType.standard,
          );
          
          loadedReposts.add(repost);
        } catch (e) {
          debugPrint('Error processing repost document: $e');
          continue;
        }
      }
      
      debugPrint('Loaded ${loadedReposts.length} reposts from database');
      return loadedReposts;
    } catch (e) {
      debugPrint('Error loading reposts: $e');
      return [];
    }
  }

  /// Fetch space recommendations from Firestore
  Future<List<SpaceRecommendationSimple>> _fetchSpaceRecommendations() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return [];

      final recommendationsQuery = await firestore
          .collection('users')
          .doc(userId)
          .collection('recommendations')
          .where('type', isEqualTo: 'space')
          .orderBy('score', descending: true)
          .limit(5)
          .get();

      return Future.wait(recommendationsQuery.docs.map((doc) async {
        final data = doc.data();
        final spaceDoc = await firestore
            .collection('spaces')
            .doc(data['spaceId'] as String)
            .get();
            
        if (!spaceDoc.exists) return null;
        
        final spaceData = spaceDoc.data()!;
        return SpaceRecommendationSimple(
          name: spaceData['name'] ?? '',
          description: spaceData['description'] ?? '',
          imageUrl: spaceData['imageUrl'],
          category: spaceData['category'] ?? 'Other',
          score: (data['score'] as num?)?.toDouble() ?? 0.0,
        );
      })).then((list) => list.whereType<SpaceRecommendationSimple>().toList());
    } catch (e) {
      debugPrint('Error fetching space recommendations: $e');
      return [];
    }
  }

  /// Fetch HIVE lab items from Firestore
  Future<List<HiveLabItemSimple>> _fetchHiveLabItems() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final hiveLabQuery = await firestore
          .collection('hive_lab')
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      return hiveLabQuery.docs.map((doc) {
        final data = doc.data();
        return HiveLabItemSimple(
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          link: data['link'] ?? '',
          timestamp: (data['createdAt'] as Timestamp).toDate(),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching HIVE lab items: $e');
      return [];
    }
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
          'feedSize': state.events.length,
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

      // Determine content type based on comment
      final contentType = (repostInfo.comment != null && repostInfo.comment!.isNotEmpty)
          ? RepostContentType.quote.toString()
          : RepostContentType.standard.toString();

      // Create repost data for Firestore
      final repostData = {
        'eventId': event.id,
        'userId': repostInfo.userId,
        'userName': repostInfo.userName,
        'avatarUrl': repostInfo.avatarUrl,
        'comment': repostInfo.comment,
        'contentType': contentType,
        'createdAt': Timestamp.fromDate(repostInfo.createdAt),
      };

      // Add to reposts collection
      await FirebaseFirestore.instance.collection('reposts').add(repostData);
      
      // Don't modify the feed state - the repost will just be associated with 
      // the original event and not appear as a separate item in the feed
      debugPrint('✓ Repost saved to Firestore (not adding to feed items)');

      // Return success
      return true;
    } catch (e) {
      debugPrint('Error reposting event: $e');
      rethrow;
    }
  }

  /// Refresh feed with proper filtering and deduplication
  Future<void> refreshFeed() async {
    try {
      debugPrint('🔄 Refreshing feed with proper filtering...');
      
      // Get fresh events from the database
      await fetchEvents(refresh: true);
      
      // Explicitly fetch reposts 
      final repostItems = await _fetchReposts();
      
      // Filter out past events - strict filtering to only show future events
      final now = DateTime.now();
      final filteredEvents = state.events
          .where((event) => event.endDate.isAfter(now))
          .toList();
      
      // Sort filtered events by start date (soonest first)
      filteredEvents.sort((a, b) => a.startDate.compareTo(b.startDate));
      
      // Create a set of event IDs to track duplicates
      final processedEventIds = <String>{};
      
      // Create feed items with proper deduplication
      final List<Map<String, dynamic>> feedItems = [];
      
      // Add events to feed items (only if not already processed)
      for (final event in filteredEvents) {
        if (!processedEventIds.contains(event.id)) {
          feedItems.add({
            'type': 'event',
            'data': event,
            'sortKey': event.startDate.millisecondsSinceEpoch,
          });
          processedEventIds.add(event.id);
        }
      }
      
      // Add reposts to feed items (only if not already processed and the event is not past)
      for (final repost in repostItems) {
        if (!processedEventIds.contains(repost.event.id) && repost.event.endDate.isAfter(now)) {
          feedItems.add({
            'type': 'repost',
            'data': repost,
            'sortKey': repost.repostTime.millisecondsSinceEpoch,
          });
          processedEventIds.add(repost.event.id);
        }
      }
      
      // Sort feed items - events by start date (soonest first), then reposts
      feedItems.sort((a, b) {
        final aType = a['type'] as String;
        final bType = b['type'] as String;
        
        // If both are events, sort by start date (soonest first)
        if (aType == 'event' && bType == 'event') {
          final aEvent = a['data'] as Event;
          final bEvent = b['data'] as Event;
          return aEvent.startDate.compareTo(bEvent.startDate);
        }
        
        // If one is an event and one is a repost, prioritize the event
        if (aType == 'event' && bType == 'repost') {
          return -1;
        }
        if (aType == 'repost' && bType == 'event') {
          return 1;
        }
        
        // If both are reposts, sort by repost time (most recent first)
        final aRepost = a['data'] as RepostItem;
        final bRepost = b['data'] as RepostItem;
        return bRepost.repostTime.compareTo(aRepost.repostTime);
      });
      
      // Update state with filtered events, reposts, and deduplicated feed items
      state = state.copyWith(
        events: filteredEvents,
        reposts: repostItems,
        feedItems: feedItems,
      );
      
      debugPrint('Feed refreshed with ${feedItems.length} total unique items');
    } catch (e) {
      debugPrint('Error refreshing feed: $e');
    }
  }
  
  /// Hide an event from the feed when user swipes it away
  void hideEvent(String eventId) {
    try {
      // Filter out the event from events list
      final updatedEvents = state.events.where((event) => event.id != eventId).toList();
      
      // Filter out any reposts containing the event
      final updatedReposts = state.reposts.where((repost) => repost.event.id != eventId).toList();
      
      // Update feed items
      final updatedFeedItems = state.feedItems.where((item) {
        final itemType = item['type'] as String;
        if (itemType == 'event') {
          final event = item['data'] as Event;
          return event.id != eventId;
        } else if (itemType == 'repost') {
          final repost = item['data'] as RepostItem;
          return repost.event.id != eventId;
        }
        return true;
      }).toList();
      
      // Update the state
      state = state.copyWith(
        events: updatedEvents,
        reposts: updatedReposts,
        feedItems: updatedFeedItems,
      );
      
      // Log the action
      debugPrint('🚫 User hid event: $eventId (${updatedFeedItems.length} items remaining)');
      
      // In a real app, you might want to store this preference in user settings
      // or send it to an analytics/personalization service
    } catch (e) {
      debugPrint('Error hiding event: $e');
    }
  }

  /// Helper function to parse timestamp from various formats
  DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) {
      return DateTime.now();
    }
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    if (timestamp is DateTime) {
      return timestamp;
    }
    if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }
}

