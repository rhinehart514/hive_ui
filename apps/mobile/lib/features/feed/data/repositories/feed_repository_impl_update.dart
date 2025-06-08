// This is a snippet showing how to integrate the Feed Intelligence Layer
// into an existing Feed Repository implementation

import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/feed/domain/providers/feed_intelligence_provider.dart';
import 'package:hive_ui/features/feed/domain/services/feed_intelligence_service.dart';
import 'package:hive_ui/features/feed/domain/repositories/feed_repository.dart';
import 'package:hive_ui/features/feed/domain/failures/feed_failures.dart';
import 'package:hive_ui/features/shared/domain/failures/failure.dart'; // Use project's Either, not dartz
import 'package:hive_ui/models/event.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_ui/models/reposted_event.dart';
import 'package:hive_ui/models/recommended_space.dart';
import 'package:hive_ui/models/feed_state.dart';
import 'package:flutter/foundation.dart';

/// Authentication-related failure
class AuthenticationFailure extends FeedFailure {
  /// Constructor
  const AuthenticationFailure({
    String? message,
    Object? originalException,
  }) : super(
    message: message ?? 'User is not authenticated',
    originalException: originalException,
  );
}

/// Example implementation of the Feed Repository with intelligence layer
/// 
/// This class demonstrates how to integrate the Feed Intelligence Layer
/// into a concrete repository implementation
class FeedRepositoryWithIntelligence implements FeedRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FeedIntelligenceService _intelligenceService;
  
  /// Constructor
  FeedRepositoryWithIntelligence({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required FeedIntelligenceService intelligenceService,
  })  : _firestore = firestore,
        _auth = auth,
        _intelligenceService = intelligenceService;

  /// Prioritize events based on user preferences and behavior
  @override
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
  }) async {
    try {
      if (events.isEmpty) {
        return Either.right([]);
      }

      // Create a scoring map for each event
      final Map<String, double> eventScores = {};
      
      for (final event in events) {
        double score = 0;
        
        // Basic recency score - newer events get higher priority
        final now = DateTime.now();
        final DateTime eventDate = event.lastModified ?? now;
        final daysDifference = now.difference(eventDate).inDays;
        score += max(0, 10 - daysDifference); // Higher score for more recent events
        
        // Category preference
        if (categoryScores != null && categoryScores.containsKey(event.category)) {
          score += categoryScores[event.category]!.toDouble();
        }
        
        // Organizer preference
        if (organizerScores != null && event.createdBy != null && 
            organizerScores.containsKey(event.createdBy)) {
          score += organizerScores[event.createdBy]!.toDouble();
        }
        
        // Attending friends bonus
        if (friendIds != null) {
          final attendingFriends = event.attendees
              .where((attendee) => friendIds.contains(attendee))
              .length;
          score += attendingFriends * 5; // 5 points per attending friend
        }
        
        // User interests match
        if (userInterests != null) {
          final matchingTags = event.tags
              .where((tag) => userInterests.contains(tag))
              .length;
          score += matchingTags * 3; // 3 points per matching interest
        }
        
        // Boosted events get priority
        if (boostedEventIds != null && boostedEventIds.contains(event.id)) {
          score += 20; // Significant boost for promoted content
        }
        
        // Location relevance (if user's residence is known)
        if (userResidence != null && event.location.toLowerCase().contains(userResidence.toLowerCase())) {
          score += 5; // Bonus for events in user's residence area
        }
        
        eventScores[event.id] = score;
      }
      
      // Sort events by score
      final sortedEvents = List<Event>.from(events);
      sortedEvents.sort((a, b) => 
        (eventScores[b.id] ?? 0).compareTo(eventScores[a.id] ?? 0));
      
      return Either.right(sortedEvents);
    } catch (e) {
      return Either.left(PersonalizationFailure(originalException: e));
    }
  }
  
  @override
  Future<Either<FeedFailure, Map<String, dynamic>>> fetchFeedEvents({
    bool forceRefresh = false,
    int page = 1,
    int pageSize = 20,
    EventFilters? filters,
    bool userInitiated = false,
  }) async {
    try {
      // Implementation example
      final events = await _fetchEvents(
        page: page,
        pageSize: pageSize,
        filters: filters,
      );
      
      // Apply intelligent filtering and ranking if filters allow
      List<Event> processedEvents = events;
      
      // Apply filters if provided
      if (filters != null && filters.hasActiveFilters) {
        processedEvents = events.where((event) => filters.matches(event)).toList();
      }
      
      // Personalize events using intelligence service if no manual filter is active
      if ((filters == null || !filters.hasActiveFilters) && _auth.currentUser != null) {
        try {
          // Get user preferences - simplified example
          final userDoc = await _firestore
              .collection('users')
              .doc(_auth.currentUser!.uid)
              .get();
          
          final userData = userDoc.data();
          
          if (userData != null) {
            final userInterests = userData['interests'] is List 
                ? List<String>.from(userData['interests']) 
                : <String>[];
                
            final userMajor = userData['major'] as String?;
            
            // Use the intelligence service to prioritize events
            final prioritizedResult = await prioritizeEvents(
              events: processedEvents,
              userInterests: userInterests,
              userMajor: userMajor,
            );
            
            // Update the events if prioritization was successful
            if (prioritizedResult.isRight) {
              prioritizedResult.fold(
                (failure) => null, 
                (prioritized) => processedEvents = prioritized
              );
            }
          }
        } catch (e) {
          // Log but don't fail the operation
          debugPrint('Error in event personalization: $e');
        }
      }
      
      return Either.right({
        'events': processedEvents,
        'hasMore': events.length >= pageSize,
        'currentPage': page,
      });
    } catch (e) {
      return Either.left(EventsLoadFailure(originalException: e));
    }
  }
  
  /// Private method to fetch events with filtering
  Future<List<Event>> _fetchEvents({
    required int page,
    required int pageSize,
    EventFilters? filters,
  }) async {
    try {
      // Start with the events collection
      Query query = _firestore.collection('events');
      
      // Apply basic filters from EventFilters if provided
      if (filters != null) {
        // Filter by categories if specified
        if (filters.categories.isNotEmpty) {
          query = query.where('category', whereIn: filters.categories);
        }
        
        // Filter by date range if specified
        if (filters.dateRange != null) {
          // Start date is greater than or equal to the start of the range
          query = query.where('startDate', 
            isGreaterThanOrEqualTo: filters.dateRange!.start);
          
          // Start date is less than or equal to the end of the range
          query = query.where('startDate', 
            isLessThanOrEqualTo: filters.dateRange!.end);
        }
        
        // Filter by source if not all sources are selected
        if (filters.sources.length != 3) {
          // Convert EventSource enum to string values for the query
          final sourceValues = filters.sources
              .map((source) => source.toString().split('.').last)
              .toList();
          
          query = query.where('source', whereIn: sourceValues);
        }
        
        // Free text search can't be done directly in Firestore query
        // It would be handled client-side or with a search service
      }
      
      // Always filter to only show published events
      query = query.where('published', isEqualTo: true);
      
      // Order by start date by default
      query = query.orderBy('startDate', descending: false);
      
      // Apply pagination - Use limit() since Firestore doesn't support offset
      query = query.limit(pageSize);
      
      // For pagination beyond first page, we would need to use startAfter with a document reference
      // This would require keeping track of the last document from previous queries
      // For demonstration purposes, we'll just implement first page
      
      // Execute the query
      final snapshot = await query.get();
      
      // Convert to Event objects
      final events = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Ensure id is set from document
        data['id'] = doc.id;
        return Event.fromJson(data);
      }).toList();
      
      return events;
    } catch (e) {
      // Log the error and return empty list
      debugPrint('Error fetching events: $e');
      return [];
    }
  }
  
  @override
  Future<Either<FeedFailure, List<Event>>> getEvents({
    bool forceRefresh = false,
    int limit = 20,
    Event? lastEvent,
  }) async {
    // Example implementation
    try {
      return Either.right([]);
    } catch (e) {
      return Either.left(EventsLoadFailure(originalException: e));
    }
  }
  
  @override
  Future<Either<FeedFailure, List<Event>>> getRecommendedEvents({int limit = 10}) async {
    // Example implementation
    try {
      return Either.right([]);
    } catch (e) {
      return Either.left(EventsLoadFailure(originalException: e));
    }
  }
  
  @override
  Future<Either<FeedFailure, bool>> getEventRsvpStatus(String eventId) async {
    try {
      // Get the current user ID
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return Either.left(
          const AuthenticationFailure(message: 'User not authenticated')
        );
      }
      
      // Query the RSVP collection to check if this user has RSVP'd
      final rsvpDoc = await _firestore
          .collection('event_rsvps')
          .where('eventId', isEqualTo: eventId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      
      // Return true if the RSVP exists
      return Either.right(rsvpDoc.docs.isNotEmpty);
    } catch (e) {
      return Either.left(RsvpFailure(
        eventId: eventId,
        wasAttending: false,
        originalException: e,
      ));
    }
  }
  
  @override
  Future<Either<FeedFailure, bool>> rsvpToEvent(String eventId, bool attending) async {
    try {
      // Get the current user ID
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return Either.left(
          const AuthenticationFailure(message: 'User not authenticated')
        );
      }
      
      // Define the RSVP document ID
      final rsvpId = '${eventId}_$userId';
      
      if (attending) {
        // Create a new RSVP document
        await _firestore.collection('event_rsvps').doc(rsvpId).set({
          'eventId': eventId,
          'userId': userId,
          'attending': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        // Increment the event's attendee count
        await _firestore.collection('events').doc(eventId).update({
          'attendeeCount': FieldValue.increment(1),
        });
        
        // Record this action in the user's activity trail
        await _recordRsvpInTrail(userId, eventId, true);
      } else {
        // Delete the RSVP document
        await _firestore.collection('event_rsvps').doc(rsvpId).delete();
        
        // Decrement the event's attendee count
        await _firestore.collection('events').doc(eventId).update({
          'attendeeCount': FieldValue.increment(-1),
        });
        
        // Record this action in the user's activity trail
        await _recordRsvpInTrail(userId, eventId, false);
      }
      
      return Either.right(attending);
    } catch (e) {
      return Either.left(RsvpFailure(
        eventId: eventId,
        wasAttending: attending,
        originalException: e,
      ));
    }
  }
  
  /// Record RSVP action in the user's activity trail
  Future<void> _recordRsvpInTrail(String userId, String eventId, bool attending) async {
    try {
      // Get event details for the trail record
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      final eventData = eventDoc.data();
      
      if (eventData != null) {
        // Create activity trail record
        await _firestore.collection('users').doc(userId).collection('trail').add({
          'type': 'event_rsvp',
          'action': attending ? 'rsvp' : 'cancel_rsvp',
          'eventId': eventId,
          'eventTitle': eventData['title'] ?? 'Unknown Event',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Log error but don't fail the RSVP operation
      debugPrint('Error recording RSVP in trail: $e');
    }
  }
  
  @override
  Future<Either<FeedFailure, RepostedEvent?>> repostEvent({
    required String eventId,
    String? comment,
    String? userId,
  }) async {
    // Example implementation
    try {
      return Either.right(null);
    } catch (e) {
      return Either.left(RepostFailure(
        contentId: eventId,
        contentType: 'event',
        originalException: e,
      ));
    }
  }
  
  @override
  Future<void> clearCache() async {
    // Example implementation - would clear any cached data
  }
  
  @override
  Future<Either<FeedFailure, List<Event>>> fetchEventsFromSpaces({int limit = 20}) async {
    // Example implementation
    try {
      return Either.right([]);
    } catch (e) {
      return Either.left(EventsLoadFailure(originalException: e));
    }
  }
  
  @override
  Future<Either<FeedFailure, List<RecommendedSpace>>> fetchSpaceRecommendations({int limit = 5}) async {
    // Example implementation
    try {
      return Either.right([]);
    } catch (e) {
      return Either.left(
        PersonalizationFailure(originalException: e)
      );
    }
  }
  
  @override
  Stream<Either<FeedFailure, List<Map<String, dynamic>>>> getFeedStream() {
    // Example implementation - returns empty stream
    return Stream.value(Either.right([{}]));
  }
}

/// Example of how to provide the repository with intelligence service
final feedRepositoryWithIntelligenceProvider = Provider<FeedRepository>((ref) {
  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  final intelligenceService = ref.watch(feedIntelligenceServiceProvider);
  
  return FeedRepositoryWithIntelligence(
    firestore: firestore,
    auth: auth,
    intelligenceService: intelligenceService,
  );
}); 