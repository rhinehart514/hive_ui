import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/events/domain/usecases/get_events_use_case.dart';
import 'package:hive_ui/features/events/domain/usecases/save_rsvp_status_use_case.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/models/feed_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ui/models/repost_content_type.dart';
import 'package:hive_ui/models/space_recommendation.dart' as model;
import 'package:hive_ui/features/feed/domain/providers/space_recommendations_provider.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'dart:math' show min;
import 'package:hive_ui/features/feed/domain/models/quote_item.dart';

/// State class for feed events
class FeedEventsState {
  /// Loading status
  final LoadingStatus status;
  
  /// List of events
  final List<Event> events;
  
  /// List of reposts
  final List<RepostItem> reposts;
  
  /// List of quotes
  final List<QuoteItem> quotes;
  
  /// List of space recommendations
  final List<model.SpaceRecommendation> spaceRecommendations;
  
  /// Combined feed items for display
  final List<Map<String, dynamic>> feedItems;
  
  /// Whether there are more events to load
  final bool hasMoreEvents;
  
  /// Current page for pagination
  final int currentPage;
  
  /// Error message if any
  final String? errorMessage;
  
  /// Whether the feed is loading more events
  final bool isLoadingMore;

  /// Constructor
  FeedEventsState({
    this.status = LoadingStatus.initial,
    this.events = const [],
    this.reposts = const [],
    this.quotes = const [],
    this.spaceRecommendations = const [],
    this.feedItems = const [],
    this.hasMoreEvents = true,
    this.currentPage = 1,
    this.errorMessage,
    this.isLoadingMore = false,
  });

  /// Create a copy with new values
  FeedEventsState copyWith({
    LoadingStatus? status,
    List<Event>? events,
    List<RepostItem>? reposts,
    List<QuoteItem>? quotes,
    List<model.SpaceRecommendation>? spaceRecommendations,
    List<Map<String, dynamic>>? feedItems,
    bool? hasMoreEvents,
    int? currentPage,
    String? errorMessage,
    bool? isLoadingMore,
  }) {
    return FeedEventsState(
      status: status ?? this.status,
      events: events ?? this.events,
      reposts: reposts ?? this.reposts,
      quotes: quotes ?? this.quotes,
      spaceRecommendations: spaceRecommendations ?? this.spaceRecommendations,
      feedItems: feedItems ?? this.feedItems,
      hasMoreEvents: hasMoreEvents ?? this.hasMoreEvents,
      currentPage: currentPage ?? this.currentPage,
      errorMessage: errorMessage ?? this.errorMessage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// Provider for feed events state
final feedEventsProvider = StateNotifierProvider<FeedEventsNotifier, FeedEventsState>((ref) {
  debugPrint('📱 FEED EVENTS PROVIDER: Creating FeedEventsNotifier...');
  final getEventsUseCase = ref.watch(getEventsUseCaseProvider);
  final saveRsvpStatusUseCase = ref.watch(saveRsvpStatusUseCaseProvider);
  
  debugPrint('📱 FEED EVENTS PROVIDER: Got dependencies:');
  debugPrint('   - GetEventsUseCase: ${getEventsUseCase.runtimeType}');
  debugPrint('   - SaveRsvpStatusUseCase: ${saveRsvpStatusUseCase.runtimeType}');
  
  return FeedEventsNotifier(
    getEventsUseCase: getEventsUseCase,
    saveRsvpStatusUseCase: saveRsvpStatusUseCase,
    ref: ref,
  );
});

/// Notifier for feed events state
class FeedEventsNotifier extends StateNotifier<FeedEventsState> {
  final GetEventsUseCase _getEventsUseCase;
  final SaveRsvpStatusUseCase _saveRsvpStatusUseCase;
  final Ref _ref;
  final bool _disposed = false;
  
  /// Constructor
  FeedEventsNotifier({
    required GetEventsUseCase getEventsUseCase,
    required SaveRsvpStatusUseCase saveRsvpStatusUseCase,
    required Ref ref,
  }) : _getEventsUseCase = getEventsUseCase,
       _saveRsvpStatusUseCase = saveRsvpStatusUseCase,
       _ref = ref,
       super(FeedEventsState()) {
    debugPrint('📱 FEED EVENTS NOTIFIER: Created with initial state: ${state.status}');
  }

  /// Calculate a score for feed item prioritization
  double _calculateItemScore(dynamic item) {
    if (item is Event) {
      double score = 1.0;
      
      // Boost score based on engagement
      score += ((item.attendees.length) * 0.1); // Use attendees length
      score += ((item.reposts.length) * 0.2); // Use reposts length
      
      // Boost score for upcoming events
      final now = DateTime.now();
      final timeUntilEvent = item.startDate.difference(now).inHours;
      if (timeUntilEvent > 0 && timeUntilEvent < 48) {
        score += 2.0; // Boost events happening soon
      }
      
      // Boost verified organizers or spaces
      if (item.organizer?.isVerified == true) {
        score += 1.5;
      }

      return score;
    }
    
    if (item is RepostItem) {
      double score = 0.8; // Base score for reposts
      score += _calculateItemScore(item.event) * 0.5; // Add half of event score
      return score;
    }
    
    if (item is QuoteItem) {
      double score = 0.9; // Base score for quotes
      score += _calculateItemScore(item.event) * 0.6; // Add 60% of event score
      return score;
    }

    if (item is model.SpaceRecommendation) {
      return 0.5; // Base score for recommendations
    }

    return 0.0; // Default score
  }

  /// Build feed items from events, reposts, and recommendations
  Future<List<Map<String, dynamic>>> _buildFeedItems({
    required List<Event> events,
    required List<RepostItem> reposts,
    required List<model.SpaceRecommendation> spaceRecommendations,
  }) async {
    if (_disposed) return [];
    
    final List<Map<String, dynamic>> feedItems = [];
    final processedEventIds = <String>{};
    final now = DateTime.now();
    
    // Filter events to only include future events
    final filteredEvents = events.where((event) => event.endDate.isAfter(now)).toList();
    
    // Add events to feed items
    for (final event in filteredEvents) {
      if (!processedEventIds.contains(event.id)) {
        feedItems.add({
          'type': 'event',
          'data': event,
          'eventStartDate': event.startDate.millisecondsSinceEpoch,
          'score': _calculateItemScore(event),
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        processedEventIds.add(event.id);
      }
    }
    
    // Add reposts to feed items (only if event is not past)
    for (final repost in reposts) {
      if (!processedEventIds.contains(repost.event.id) && repost.event.endDate.isAfter(now)) {
        feedItems.add({
          'type': 'repost',
          'data': repost,
          'eventStartDate': repost.event.startDate.millisecondsSinceEpoch,
          'score': _calculateItemScore(repost),
          'timestamp': repost.repostTime.millisecondsSinceEpoch,
        });
        processedEventIds.add(repost.event.id);
      }
    }

    // Add quotes to feed items
    for (final quote in state.quotes) {
      // Only add quotes for events that haven't ended
      if (quote.event.endDate.isAfter(now)) {
        feedItems.add({
          'type': 'quote',
          'data': quote,
          'eventStartDate': quote.event.startDate.millisecondsSinceEpoch,
          'score': _calculateItemScore(quote),
          'timestamp': quote.createdAt.millisecondsSinceEpoch,
        });
      }
    }
    
    // Sort all items primarily by event start date (soonest first)
    // For items with the same start date, use the score as a secondary sort
    feedItems.sort((a, b) {
      // Primary sort by event start date
      final startDateComparison = (a['eventStartDate'] as int).compareTo(b['eventStartDate'] as int);
      if (startDateComparison != 0) return startDateComparison;
      
      // Secondary sort by score (higher score first)
      final scoreComparison = (b['score'] as double).compareTo(a['score'] as double);
      if (scoreComparison != 0) return scoreComparison;
      
      // Finally sort by timestamp (most recent first) for items with same start date and score
      return (b['timestamp'] as int).compareTo(a['timestamp'] as int);
    });

    // Add space recommendations
    if (spaceRecommendations.isNotEmpty && feedItems.length > 3) {
      for (int i = 0; i < spaceRecommendations.length; i++) {
        final insertPosition = 3 + (i * 6);
        if (insertPosition < feedItems.length) {
          feedItems.insert(insertPosition, {
            'type': 'spaceRecommendation',
            'data': spaceRecommendations[i],
            'eventStartDate': DateTime.now().millisecondsSinceEpoch,
            'score': _calculateItemScore(spaceRecommendations[i]),
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
        }
      }
    }
    
    return feedItems;
  }

  /// Add an event to the feed
  void addEvent(Event event) {
    state = state.copyWith(events: [...state.events, event]);
  }

  /// Add a quote to the feed
  void addQuote(QuoteItem quote) {
    state = state.copyWith(quotes: [...state.quotes, quote]);
  }

  /// Remove an item from the feed
  void removeItem(dynamic item) {
    state = state.copyWith(events: state.events.where((i) => i != item).toList());
    state = state.copyWith(reposts: state.reposts.where((i) => i != item).toList());
    state = state.copyWith(quotes: state.quotes.where((i) => i != item).toList());
    state = state.copyWith(spaceRecommendations: state.spaceRecommendations.where((i) => i != item).toList());
    state = state.copyWith(feedItems: state.feedItems.where((i) => i['data'] != item).toList());
  }

  /// Update an event in the feed
  void updateEvent(Event event) {
    state = state.copyWith(events: state.events.map((item) {
      if (item is Event && item.id == event.id) {
        return event;
      }
      return item;
    }).toList());
  }

  /// Update a quote in the feed
  void updateQuote(QuoteItem quote) {
    state = state.copyWith(quotes: state.quotes.map((item) {
      if (item is QuoteItem && item.id == quote.id) {
        return quote;
      }
      return item;
    }).toList());
  }

  /// Clear all items from the feed
  void clear() {
    state = FeedEventsState();
  }

  /// Get all events from the feed
  List<Event> getEvents() {
    return state.events;
  }

  /// Get all quotes from the feed
  List<QuoteItem> getQuotes() {
    return state.quotes;
  }

  /// Filter feed items by type
  List<T> getItemsByType<T>() {
    return state.feedItems
        .where((item) => item['data'] is T)
        .map((item) => item['data'] as T)
        .toList();
  }

  /// Initialize feed with first batch of events
  Future<void> initializeFeed() async {
    debugPrint('📱 FEED EVENTS NOTIFIER: Initializing feed...');
    
    // Set loading state
    state = state.copyWith(status: LoadingStatus.loading);
    debugPrint('📱 FEED EVENTS NOTIFIER: Set state to loading');
    
    try {
      debugPrint('📱 FEED EVENTS NOTIFIER: Calling getEventsUseCase.execute() with forceRefresh=true');
      
      // Fetch events - force refresh on first load to ensure we get data
      final result = await _getEventsUseCase.execute(
        forceRefresh: true, // Force refresh on first load
        page: 1,
        pageSize: 20,
      );
      
      // Check if disposed during async operation
      if (_disposed) {
        debugPrint('⚠️ FEED EVENTS NOTIFIER: Disposed during event fetch, abandoning initialization');
        return;
      }
      
      debugPrint('📱 FEED EVENTS NOTIFIER: Got result from use case');
      
      // Check for errors
      if (result.containsKey('error')) {
        throw Exception(result['error']);
      }
      
      final events = result['events'] as List<Event>;
      final hasMore = result['hasMore'] as bool;
      
      debugPrint('📱 FEED EVENTS NOTIFIER: Retrieved ${events.length} events, hasMore: $hasMore');
      
      // Log event details for debugging
      for (var i = 0; i < events.length; i++) {
        final event = events[i];
        debugPrint('📱 EVENT ${i+1}: ${event.title} (${event.id}) - ${event.startDate}');
      }
      
      // Fetch reposts
      final reposts = await _fetchReposts();
      if (_disposed) return;
      
      debugPrint('📱 FEED EVENTS NOTIFIER: Retrieved ${reposts.length} reposts');
      
      // Handle space recommendations
      List<model.SpaceRecommendation> spaceRecommendations = [];
      if (!_disposed) {
        final recommendationsState = _ref.read(spaceRecommendationsProvider);
        recommendationsState.whenData((recommendations) {
          spaceRecommendations = recommendations;
          debugPrint('📱 FEED EVENTS NOTIFIER: Got ${spaceRecommendations.length} space recommendations');
        });
      } else {
        return;
      }
      
      // Build a comprehensive feed
      final feedItems = await _buildFeedItems(
        events: events, 
        reposts: reposts, 
        spaceRecommendations: spaceRecommendations
      );
      
      if (_disposed) return;
      
      // Update state
      state = state.copyWith(
        status: LoadingStatus.loaded,
        events: events,
        reposts: reposts,
        spaceRecommendations: spaceRecommendations,
        feedItems: feedItems,
        hasMoreEvents: hasMore,
        currentPage: 1,
      );
      
      debugPrint('📱 FEED EVENTS NOTIFIER: Feed initialized with ${state.feedItems.length} feed items');
    } catch (e) {
      debugPrint('❌ FEED EVENTS NOTIFIER: Error initializing feed: $e');
      
      // Only update state if not disposed
      if (!_disposed) {
        state = state.copyWith(
          status: LoadingStatus.error,
          errorMessage: e.toString(),
        );
      }
    }
  }
  
  /// Refresh feed with new data
  Future<void> refreshFeed() async {
    debugPrint('📱 FEED EVENTS NOTIFIER: Refreshing feed with force refresh...');
    
    // Set refreshing state
    state = state.copyWith(status: LoadingStatus.refreshing);
    
    try {
      // Force refresh to ensure we get test data if there are no real events
      final result = await _getEventsUseCase.execute(
        forceRefresh: true, // Explicitly force refresh
        page: 1,
        pageSize: 20,
      );
      
      if (_disposed) return;
      
      // Check for errors
      if (result.containsKey('error')) {
        throw Exception(result['error']);
      }
      
      final events = result['events'] as List<Event>;
      final hasMore = result['hasMore'] as bool;
      
      // Fetch reposts
      final reposts = await _fetchReposts();
      if (_disposed) return;
      
      // Refresh space recommendations
      List<model.SpaceRecommendation> spaceRecommendations = [];
      if (!_disposed) {
        await _ref.read(spaceRecommendationsProvider.notifier).refresh();
        final recommendationsState = _ref.read(spaceRecommendationsProvider);
        recommendationsState.whenData((recommendations) {
          spaceRecommendations = recommendations;
        });
      } else {
        return;
      }
      
      // Build a comprehensive feed
      final feedItems = await _buildFeedItems(
        events: events, 
        reposts: reposts, 
        spaceRecommendations: spaceRecommendations
      );
      
      if (_disposed) return;
      
      debugPrint('📱 FEED EVENTS NOTIFIER: Refreshed with ${feedItems.length} feed items');
      
      // Update state
      state = state.copyWith(
        status: LoadingStatus.loaded,
        events: events,
        reposts: reposts,
        spaceRecommendations: spaceRecommendations,
        feedItems: feedItems,
        hasMoreEvents: hasMore,
        currentPage: 1,
      );
    } catch (e) {
      debugPrint('❌ FEED EVENTS NOTIFIER: Error refreshing feed: $e');
      if (!_disposed) {
        state = state.copyWith(
          status: LoadingStatus.error,
          errorMessage: e.toString(),
        );
      }
    }
  }
  
  /// Load more events
  Future<void> loadMoreEvents() async {
    // Don't load more if already loading or no more events
    if (state.isLoadingMore || !state.hasMoreEvents) {
      return;
    }
    
    debugPrint('Loading more events...');
    
    // Set loading more state
    state = state.copyWith(isLoadingMore: true);
    
    try {
      // Fetch events
      final result = await _getEventsUseCase.execute(
        forceRefresh: false,
        page: state.currentPage + 1,
        pageSize: 20,
      );
      
      if (_disposed) return;
      
      // Check for errors
      if (result.containsKey('error')) {
        throw Exception(result['error']);
      }
      
      // Get new events
      final newEvents = result['events'] as List<Event>;
      final hasMore = result['hasMore'] as bool;
      
      // Get current events and add new ones (avoid duplicates)
      final allEvents = [...state.events];
      final existingIds = allEvents.map((e) => e.id).toSet();
      
      for (final event in newEvents) {
        if (!existingIds.contains(event.id)) {
          allEvents.add(event);
          existingIds.add(event.id);
        }
      }
      
      // Build updated feed items with new events
      final updatedFeedItems = await _buildFeedItems(
        events: allEvents, 
        reposts: state.reposts, 
        spaceRecommendations: state.spaceRecommendations
      );
      
      if (_disposed) return;
      
      debugPrint('📱 FEED EVENTS NOTIFIER: Loaded ${newEvents.length} more events, now have ${allEvents.length} total');
      
      // Update state
      state = state.copyWith(
        events: allEvents,
        feedItems: updatedFeedItems,
        hasMoreEvents: hasMore,
        currentPage: state.currentPage + 1,
        isLoadingMore: false,
      );
    } catch (e) {
      debugPrint('❌ FEED EVENTS NOTIFIER: Error loading more events: $e');
      // Only set error message, keep the current events
      if (!_disposed) {
        state = state.copyWith(
          errorMessage: e.toString(),
          isLoadingMore: false,
        );
      }
    }
  }
  
  /// Update RSVP status for an event
  Future<void> updateRsvpStatus(String eventId, bool isAttending) async {
    debugPrint('📱 FEED EVENTS NOTIFIER: Updating RSVP status for event $eventId to $isAttending');
    
    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      // Apply optimistic update - update locally first
      state = state.copyWith(
        events: state.events.map((event) {
          if (event.id == eventId) {
            // Create new attendees list
            final List<String> updatedAttendees = List.from(event.attendees);
            
            if (isAttending && !updatedAttendees.contains(user.uid)) {
              updatedAttendees.add(user.uid);
            } else if (!isAttending && updatedAttendees.contains(user.uid)) {
              updatedAttendees.remove(user.uid);
            }
            
            // Return updated event
            return event.copyWith(attendees: updatedAttendees);
          }
          return event;
        }).toList(),
      );
      
      if (_disposed) return;
      
      // Update feed items too
      final updatedFeedItems = state.feedItems.map((item) {
        if (item['type'] == 'event' && (item['data'] as Event).id == eventId) {
          final updatedEvent = state.events.firstWhere((e) => e.id == eventId);
          return {
            ...item,
            'data': updatedEvent,
          };
        } else if (item['type'] == 'repost' && (item['data'] as RepostItem).event.id == eventId) {
          final RepostItem repost = item['data'] as RepostItem;
          final updatedEvent = state.events.firstWhere((e) => e.id == eventId);
          // Use copyWith method on RepostItem
          return {
            ...item,
            'data': repost.copyWith(event: updatedEvent),
          };
        }
        return item;
      }).toList();
      
      state = state.copyWith(feedItems: updatedFeedItems);
      
      // Save to backend
      await _saveRsvpStatusUseCase.execute(eventId, user.uid, isAttending);
      
      debugPrint('📱 FEED EVENTS NOTIFIER: Successfully updated RSVP status');
    } catch (e) {
      debugPrint('❌ FEED EVENTS NOTIFIER: Error updating RSVP status: $e');
      // Revert optimistic update on error
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        state = state.copyWith(
          events: state.events.map((event) {
            if (event.id == eventId) {
              final List<String> updatedAttendees = List.from(event.attendees);
              if (isAttending) {
                // Remove user from attendees if we failed to add them
                updatedAttendees.remove(user.uid);
              } else {
                // Add user back to attendees if we failed to remove them
                if (!updatedAttendees.contains(user.uid)) {
                  updatedAttendees.add(user.uid);
                }
              }
              return event.copyWith(attendees: updatedAttendees);
            }
            return event;
          }).toList(),
        );
      }
    }
  }
  
  /// Fetch reposts for the feed
  Future<List<RepostItem>> _fetchReposts() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final repostsQuery = await firestore
          .collection('reposts')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      if (_disposed) return [];

      final List<RepostItem?> repostsWithNulls = await Future.wait(repostsQuery.docs.map((doc) async {
        if (_disposed) return null;
        
        final data = doc.data();
        
        // Ensure we have both eventId and userId
        if (!data.containsKey('eventId') || !data.containsKey('userId')) {
          debugPrint('Repost doc ${doc.id} missing eventId or userId');
          return null;
        }
        
        final eventId = data['eventId'] as String;
        final userId = data['userId'] as String;
        
        try {
          // Fetch the associated event
          final eventDoc = await firestore.collection('events').doc(eventId).get();
          if (_disposed) return null;
          if (!eventDoc.exists) {
            debugPrint('Event doc $eventId not found for repost ${doc.id}');
            return null;
          }
          final eventData = eventDoc.data();
          if (eventData == null) return null;
          eventData['id'] = eventDoc.id;
          final event = Event.fromJson(eventData);
          
          // Fetch the reposter's profile directly from Firestore
          UserProfile? reposterProfile;
          try {
            final userDoc = await firestore.collection('users').doc(userId).get();
            if (_disposed) return null;
            if (userDoc.exists) {
              reposterProfile = UserProfile.fromFirestore(userDoc);
            } else {
              debugPrint('Reposter profile $userId not found for repost ${doc.id}');
            }
          } catch (profileError) {
            debugPrint('Error fetching reposter profile for $userId: $profileError');
            // Continue without profile if fetch fails
          }
          
          if (_disposed) return null;
          
          return RepostItem(
            event: event,
            reposterProfile: reposterProfile ?? UserProfile(
              id: userId,
              displayName: 'Unknown User',
              username: 'user_${userId.substring(0, min(5, userId.length))}',
              email: '',
              year: '',
              major: '',
              residence: '',
              profileImageUrl: null,
              eventCount: 0,
              clubCount: 0,
              friendCount: 0,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            repostTime: (data['createdAt'] as Timestamp).toDate(),
            comment: data['comment'] as String?,
            contentType: data['contentType'] != null 
                ? RepostContentType.values.firstWhere(
                    (e) => e.name == data['contentType'],
                    orElse: () => data['comment'] != null && (data['comment'] as String).isNotEmpty
                        ? RepostContentType.quote
                        : RepostContentType.standard
                  )
                : data['comment'] != null && (data['comment'] as String).isNotEmpty
                    ? RepostContentType.quote
                    : RepostContentType.standard,
          );
        } catch (e) {
          debugPrint('Error processing repost document ${doc.id}: $e');
          return null;
        }
      }));

      if (_disposed) return [];

      // Filter out null items
      final List<RepostItem> reposts = repostsWithNulls.whereType<RepostItem>().toList();
      debugPrint('Fetched ${reposts.length} valid reposts from ${repostsWithNulls.length} total reposts');
      return reposts;
    } catch (e) {
      debugPrint('Error fetching reposts collection: $e');
      // Return empty list instead of null
      return [];
    }
  }
  
  /// Add a quote to the feed
  Future<void> addQuoteToFeed(QuoteItem quote) async {
    state = state.copyWith(quotes: [...state.quotes, quote]);
    _updateFeedItems();
  }

  /// Update a quote in the feed
  Future<void> updateQuoteInFeed(QuoteItem quote) async {
    state = state.copyWith(quotes: state.quotes.map((q) {
      if (q.id == quote.id) return quote;
      return q;
    }).toList());
    _updateFeedItems();
  }

  /// Remove a quote from the feed
  Future<void> removeQuoteFromFeed(String quoteId) async {
    state = state.copyWith(quotes: state.quotes.where((q) => q.id != quoteId).toList());
    _updateFeedItems();
  }

  /// Update feed items after state changes
  Future<void> _updateFeedItems() async {
    final updatedFeedItems = await _buildFeedItems(
      events: state.events,
      reposts: state.reposts,
      spaceRecommendations: state.spaceRecommendations,
    );
    if (!_disposed) {
      state = state.copyWith(feedItems: updatedFeedItems);
    }
  }
} 