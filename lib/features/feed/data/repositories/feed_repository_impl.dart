import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/models/feed_state.dart';
import 'package:hive_ui/models/recommended_space.dart';
import 'package:hive_ui/models/space_type.dart';
import 'package:hive_ui/models/space.dart';
import 'package:hive_ui/models/space_metrics.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/services/feed/feed_prioritizer.dart';
import 'package:hive_ui/services/space_event_manager.dart';
import '../../domain/repositories/feed_repository.dart';
import 'package:hive_ui/services/event_service.dart';
import 'package:hive_ui/models/reposted_event.dart';
import 'package:hive_ui/models/repost_content_type.dart';
import 'package:hive_ui/features/shared/infrastructure/platform_integration_manager.dart';
import 'package:hive_ui/features/feed/domain/failures/feed_failures.dart';
import 'package:hive_ui/features/shared/domain/failures/failure.dart';
import 'dart:async'; // Import for Stream
import 'package:rxdart/rxdart.dart'; // Import for CombineLatestStream

/// Implementation of the feed repository using existing services
/// Acts as a bridge between the new architecture and existing services
class FeedRepositoryImpl implements FeedRepository {
  /// Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Firebase auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// Platform integration manager
  final PlatformIntegrationManager _integrationManager;
  
  /// In-memory cache for events
  final Map<String, Event> _eventCache = {};
  
  /// In-memory RSVP status cache
  final Map<String, bool> _rsvpStatusCache = {};
  
  /// In-memory timestamp for last full feed fetch
  DateTime? _lastFeedFetchTime;
  
  /// Cache timeout
  static const Duration _cacheTimeout = Duration(minutes: 15);
  
  /// Constructor
  FeedRepositoryImpl({
    PlatformIntegrationManager? integrationManager,
  }) : _integrationManager = integrationManager ?? PlatformIntegrationManager();
  
  @override
  Future<Either<FeedFailure, List<Event>>> getEvents({
    bool forceRefresh = false,
    int limit = 20,
    Event? lastEvent,
  }) async {
    try {
      // If cache is valid and not forcing refresh, use it
      if (!forceRefresh && 
          _eventCache.isNotEmpty && 
          _lastFeedFetchTime != null &&
          DateTime.now().difference(_lastFeedFetchTime!) < _cacheTimeout) {
        
        final cachedEvents = _eventCache.values.toList();
        cachedEvents.sort((a, b) => a.startDate.compareTo(b.startDate));
        
        // Apply pagination if last event is provided
        if (lastEvent != null) {
          final lastIndex = cachedEvents.indexWhere((e) => e.id == lastEvent.id);
          if (lastIndex != -1 && lastIndex + 1 < cachedEvents.length) {
            return Either.right(cachedEvents.sublist(lastIndex + 1, 
                (lastIndex + 1 + limit) < cachedEvents.length 
                  ? lastIndex + 1 + limit 
                  : cachedEvents.length));
          }
        }
        
        // Return first page if no last event or not found
        return Either.right(cachedEvents.take(limit).toList());
      }
      
      // Use the existing service to get events
      final events = await EventService.getEvents(forceRefresh: forceRefresh);
      
      // Update cache
      for (final event in events) {
        _eventCache[event.id] = event;
      }
      
      // Update timestamp
      _lastFeedFetchTime = DateTime.now();
      
      // Sort and paginate
      events.sort((a, b) => a.startDate.compareTo(b.startDate));
      
      // Apply pagination if last event is provided
      if (lastEvent != null) {
        final lastIndex = events.indexWhere((e) => e.id == lastEvent.id);
        if (lastIndex != -1 && lastIndex + 1 < events.length) {
          return Either.right(events.sublist(lastIndex + 1, 
              (lastIndex + 1 + limit) < events.length 
                ? lastIndex + 1 + limit 
                : events.length));
        }
      }
      
      // Return first page if no last event or not found
      return Either.right(events.take(limit).toList());
    } catch (e) {
      debugPrint('Error in FeedRepository.getEvents: $e');
      return Either.left(EventsLoadFailure(
        originalException: e,
        context: 'Calling EventService.getEvents',
      ));
    }
  }
  
  @override
  Future<Either<FeedFailure, List<Event>>> getRecommendedEvents({
    int limit = 10,
  }) async {
    try {
      // Get events using our error-handled method
      final eventsResult = await getEvents();
      
      return eventsResult.fold(
        (failure) => Either.left(failure), // Pass through the failure
        (events) {
          try {
            // Simple recommendation - sort by date and filter upcoming
            final now = DateTime.now();
            final upcoming = events.where((e) => e.startDate.isAfter(now)).toList();
            
            // Sort by start date
            upcoming.sort((a, b) => a.startDate.compareTo(b.startDate));
            
            // Return a subset
            return Either.right(upcoming.take(limit).toList());
          } catch (e) {
            return Either.left(PersonalizationFailure(
              originalException: e,
            ));
          }
        }
      );
    } catch (e) {
      debugPrint('Error in FeedRepository.getRecommendedEvents: $e');
      return Either.left(EventsLoadFailure(
        originalException: e,
        context: 'Recommending events',
      ));
    }
  }
  
  @override
  Future<Either<FeedFailure, bool>> getEventRsvpStatus(String eventId) async {
    try {
      // Check cache first
      if (_rsvpStatusCache.containsKey(eventId)) {
        return Either.right(_rsvpStatusCache[eventId]!);
      }
      
      // Use existing service
      final status = await EventService.getEventRsvpStatus(eventId);
      
      // Update cache
      _rsvpStatusCache[eventId] = status;
      
      return Either.right(status);
    } catch (e) {
      debugPrint('Error in FeedRepository.getEventRsvpStatus: $e');
      
      // Check if error is due to auth
      if (e is FirebaseException && e.code == 'permission-denied' ||
          _auth.currentUser == null) {
        return Either.left(AuthenticationFailure());
      }
      
      return Either.left(RsvpFailure(
        eventId: eventId,
        wasAttending: false, // Just getting status, not attending
        originalException: e,
      ));
    }
  }
  
  @override
  Future<Either<FeedFailure, bool>> rsvpToEvent(String eventId, bool attending) async {
    try {
      // Check if user is logged in
      if (_auth.currentUser == null) {
        return Either.left(AuthenticationFailure());
      }
      
      // Use the platform integration manager for RSVP
      final success = await _integrationManager.processEventRsvp(
        eventId: eventId,
        attending: attending,
      );
      
      // Update cache if successful
      if (success) {
        _rsvpStatusCache[eventId] = attending;
        
        // Also update the event in the cache if it exists
        if (_eventCache.containsKey(eventId)) {
          debugPrint('Event cache update skipped: isRsvped field assumed missing or copyWith needs adjustment.');
        }
      }
      
      return Either.right(success);
    } catch (e) {
      debugPrint('Error in FeedRepository.rsvpToEvent: $e');
      
      // Check for network issues
      if (e.toString().contains('network') || 
          e.toString().contains('connection') ||
          e.toString().contains('socket')) {
        return Either.left(NetworkFailure());
      }
      
      return Either.left(RsvpFailure(
        eventId: eventId,
        wasAttending: attending,
        originalException: e,
      ));
    }
  }
  
  @override
  Future<Either<FeedFailure, RepostedEvent?>> repostEvent({
    required String eventId,
    String? comment,
    String? userId,
  }) async {
    try {
      // Ensure we have a user ID
      userId ??= _auth.currentUser?.uid;
      if (userId == null) {
        return Either.left(AuthenticationFailure());
      }
      
      // Get the event if not in cache
      Event? event = _eventCache[eventId];
      if (event == null) {
        // Try to fetch it - simplified approach
        final events = await EventService.getEvents();
        
        // Corrected: Use try-catch to find the event or handle not found
        try {
          event = events.firstWhere((e) => e.id == eventId);
        } on StateError {
          debugPrint('Event with ID $eventId not found for reposting.');
          return Either.left(EventNotFoundFailure(
            eventId: eventId,
          ));
        }
        
        _eventCache[eventId] = event; // Add fetched event to cache
      }

      // Fetch user profile for repostedBy
      UserProfile? reposterProfile;
      try {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          reposterProfile = UserProfile.fromJson(userDoc.data()!);
        }
      } catch (e) {
        debugPrint('Error fetching reposter profile: $e');
        return Either.left(ReposterProfileFailure(
          originalException: e,
        ));
      }

      if (reposterProfile == null) {
        debugPrint('Reposter profile not found for ID: $userId');
        return Either.left(ReposterProfileFailure(
          originalException: Exception('Reposter profile not found'),
        ));
      }
      
      // Create the repost document in Firestore
      final repostRef = _firestore.collection('reposts').doc();
      
      // Provide all required parameters for RepostedEvent
      final repost = RepostedEvent.create(
        event: event,
        repostedBy: reposterProfile,
        comment: comment,
        repostType: RepostContentType.standard.name, // Default type for this bridge implementation
      );
      
      // Save to Firestore using correct field names from RepostedEvent.toJson
      await repostRef.set(repost.toJson());
      
      return Either.right(repost);
    } catch (e) {
      debugPrint('Error in FeedRepository.repostEvent: $e');
      return Either.left(RepostFailure(
        contentId: eventId,
        contentType: 'event',
        originalException: e,
      ));
    }
  }
  
  @override
  Future<void> clearCache() async {
    _eventCache.clear();
    _rsvpStatusCache.clear();
    _lastFeedFetchTime = null;
  }

  // Ensure signature matches FeedRepository interface EXACTLY
  @override
  Future<Either<FeedFailure, Map<String, dynamic>>> fetchFeedEvents({
    bool forceRefresh = false,
    int page = 1,
    int pageSize = 20,
    EventFilters? filters,
    bool userInitiated = false,
  }) async {
    try {
      debugPrint('fetchFeedEvents called with filters: ${filters?.toJson()}'); // Log filters
      
      // Get events with error handling
      final eventsResult = await getEvents(forceRefresh: forceRefresh);
      
      // Extract events from the Either, handling potential failures
      final List<Event> events = eventsResult.fold(
        (failure) => [], // Return empty list on failure
        (eventList) => eventList, // Use the events on success
      );
      
      // Apply filters if provided
      List<Event> filteredEvents = events;
      if (filters != null && filters.hasActiveFilters) {
        filteredEvents = events.where((event) => filters.matches(event)).toList();
      }

      // Apply pagination
      final startIndex = (page - 1) * pageSize;
      final endIndex = (startIndex + pageSize < filteredEvents.length) 
          ? startIndex + pageSize 
          : filteredEvents.length;
      final paginatedEvents = (startIndex < filteredEvents.length) 
          ? filteredEvents.sublist(startIndex, endIndex) 
          : <Event>[];

      debugPrint('fetchFeedEvents: Page $page, Fetched ${events.length} total, Returning ${paginatedEvents.length}');

      // Return paginated results
      return Either.right({
        'events': paginatedEvents,
        'hasMore': endIndex < filteredEvents.length,
        'fromCache': !forceRefresh && _lastFeedFetchTime != null && DateTime.now().difference(_lastFeedFetchTime!) < _cacheTimeout,
      });
    } catch (e) {
      debugPrint('Error in FeedRepositoryImpl.fetchFeedEvents: $e');
      return Either.left(EventsLoadFailure(
        originalException: e,
        context: 'Error fetching feed events',
      ));
    }
  }

  /// Fetch events directly from spaces
  @override
  Future<Either<FeedFailure, List<Event>>> fetchEventsFromSpaces({int limit = 20}) async {
    try {
      // Get current user for joined spaces
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('FeedRepositoryImpl: No authenticated user for fetching space events');
        // Fall back to global events for non-authenticated users
        final events = await _fetchGlobalEvents(limit: limit);
        return Either.right(events);
      }
      
      // Use the Platform Integration Manager to get events from spaces the user follows
      final events = await _integrationManager.getEventsFromFollowedSpaces(
        userId: user.uid,
        limit: limit,
        startDate: DateTime.now(),
      );
      return Either.right(events);
    } catch (e) {
      debugPrint('Error in FeedRepositoryImpl.fetchEventsFromSpaces: $e');
      
      try {
        // Fall back to the existing method if the optimized approach fails
        final events = await _fetchGlobalEvents(limit: limit);
        return Either.right(events);
      } catch (fallbackError) {
        debugPrint('Error in fallback to _fetchGlobalEvents: $fallbackError');
        return Either.left(EventsLoadFailure(
          originalException: e,
          context: 'Failed to fetch events from spaces',
        ));
      }
    }
  }
  
  /// Fallback method to fetch global events
  Future<List<Event>> _fetchGlobalEvents({int limit = 20}) async {
    try {
      final now = DateTime.now();
      final isoNow = now.toIso8601String();
      
      final snapshot = await _firestore
          .collection('events')
          .where('startDate', isGreaterThanOrEqualTo: isoNow)
          .orderBy('startDate')
          .limit(limit)
          .get();
          
      final events = snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Event.fromJson(data);
          })
          .toList();
      
      // Sort events by start date
      events.sort((a, b) => a.startDate.compareTo(b.startDate));
      
      return events;
    } catch (e) {
      debugPrint('Error in FeedRepositoryImpl._fetchGlobalEvents: $e');
      return SpaceEventManager.getAllEvents(
        limit: limit,
        startDate: DateTime.now(),
      );
    }
  }

  /// Fetch space recommendations for the feed
  @override
  Future<Either<FeedFailure, List<RecommendedSpace>>> fetchSpaceRecommendations({int limit = 5}) async {
    try {
      // Get current user for personalization if available
      final user = _auth.currentUser;
      List<RecommendedSpace> recommendations = [];

      if (user != null) {
        // Try to get personalized recommendations first
        recommendations =
            await _getPersonalizedSpaceRecommendations(user.uid, limit);
      }

      // If we didn't get enough recommendations, get trending spaces
      if (recommendations.length < limit) {
        final moreRecommendations = await _getTrendingSpaceRecommendations(
          limit - recommendations.length,
          recommendations.map((r) => r.space.id).toList(),
        );
        recommendations.addAll(moreRecommendations);
      }

      return Either.right(recommendations);
    } catch (e) {
      debugPrint('Error in FeedRepositoryImpl.fetchSpaceRecommendations: $e');

      // Fall back to sample recommendations if Firebase query fails
      return Either.right(_createSampleSpaceRecommendations());
    }
  }

  /// Get personalized space recommendations based on user profile
  Future<List<RecommendedSpace>> _getPersonalizedSpaceRecommendations(
      String userId, int limit) async {
    try {
      // Get user profile to understand interests
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        return [];
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final UserProfile profile = UserProfile.fromJson(userData);

      // Get spaces that match user interests
      Query spacesQuery = _firestore.collection('spaces');

      // If user has interests, filter by them
      final userInterests = profile.interests ?? [];
      if (userInterests.isNotEmpty) {
        // Use arrayContainsAny to find spaces with matching tags
        // Note: Firebase only allows one arrayContainsAny per query
        spacesQuery = spacesQuery.where('tags',
            arrayContainsAny: userInterests.take(10).toList());
      }

      // Filter out spaces the user has already joined
      final followedSpaceIds = profile.followedSpaces;

      final snapshot = await spacesQuery.limit(limit * 2).get();

      // Convert to spaces and filter out already joined
      final spaces = snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return Space.fromJson(data);
          })
          .where((space) => !followedSpaceIds.contains(space.id))
          .take(limit)
          .toList();

      // Transform spaces to recommended spaces
      return spaces.map((space) => RecommendedSpace(
        space: space,
        customPitch: 'Based on your interests',
        recommendationReason: 'Matches your interests',
      )).toList();
    } catch (e) {
      debugPrint('Error getting personalized recommendations: $e');
      return [];
    }
  }

  /// Get trending space recommendations
  Future<List<RecommendedSpace>> _getTrendingSpaceRecommendations(
    int limit,
    List<String> excludeIds,
  ) async {
    try {
      // Query for trending spaces (high activity score)
      final snapshot = await _firestore
          .collection('spaces')
          .orderBy('activityScore', descending: true)
          .limit(limit + excludeIds.length) // Get extra to handle filtering
          .get();

      // Filter and convert to recommendations
      final recommendations = snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Space.fromJson(data);
          })
          .where((space) => !excludeIds.contains(space.id))
          .take(limit)
          .map((space) => RecommendedSpace(
                space: space,
                customPitch: 'Popular space with active community',
                recommendationReason: 'Trending now',
              ))
          .toList();

      return recommendations;
    } catch (e) {
      debugPrint('Error getting trending recommendations: $e');
      return [];
    }
  }

  /// Prioritize events based on user preferences
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
      // If user is logged in, get their preferences
      final user = _auth.currentUser;

      if (user != null && (userInterests == null || joinedSpaceIds == null)) {
        // Get user data from Firestore
        final userData = await _getUserPreferences(user.uid);
        
        // Also get space engagement scores to improve prioritization
        final spaceEngagementScores = await _integrationManager.getSpaceEngagementScores(user.uid);
        
        // Convert space engagement scores to organizer scores for the prioritizer
        final derivedOrganizerScores = <String, int>{};
        for (final entry in spaceEngagementScores.entries) {
          // Convert double score to int range (0-10)
          derivedOrganizerScores[entry.key] = (entry.value * 2).round().clamp(0, 10);
        }
        
        // Merge with any existing organizer scores, prioritizing explicit ones
        organizerScores = {
          ...derivedOrganizerScores,
          ...(organizerScores ?? {}),
        };

        // Use provided values or fall back to retrieved ones
        userInterests ??= userData['interests'] as List<String>?;
        userMajor ??= userData['major'] as String?;
        userYear ??= userData['year'] as int?;
        userResidence ??= userData['residence'] as String?;
        joinedSpaceIds ??= userData['joinedSpaces'] as List<String>?;
        rsvpedEventIds ??= userData['rsvpedEvents'] as List<String>?;
      }

      return Either.right(FeedPrioritizer.prioritizeEvents(
        events,
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
      ));
    } catch (e) {
      debugPrint('Error in FeedRepositoryImpl.prioritizeEvents: $e');
      // Return original order if prioritization fails
      return Either.right(events);
    }
  }

  /// Get user preferences from Firestore
  Future<Map<String, dynamic>> _getUserPreferences(String userId) async {
    try {
      final docSnapshot =
          await _firestore.collection('users').doc(userId).get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        return data!;
      }

      return {};
    } catch (e) {
      debugPrint('Error fetching user preferences: $e');
      return {};
    }
  }

  /// Create sample space recommendations (temporary)
  List<RecommendedSpace> _createSampleSpaceRecommendations() {
    return [
      RecommendedSpace(
        space: Space(
          id: 'space1',
          name: 'Computer Science Club',
          description:
              'For students interested in computer science and programming',
          icon: Icons.computer,
          imageUrl: 'https://via.placeholder.com/150',
          tags: const ['programming', 'technology', 'computer science'],
          spaceType: SpaceType.studentOrg,
          createdAt: DateTime.now().subtract(const Duration(days: 365)),
          updatedAt: DateTime.now(),
          eventIds: const [],
          metrics: SpaceMetrics.initial('space1'),
        ),
        customPitch: 'Connect with CS enthusiasts',
        recommendationReason: 'Based on your interests',
      ),
      RecommendedSpace(
        space: Space(
          id: 'space2',
          name: 'Film Society',
          description: 'For cinema enthusiasts and filmmakers',
          icon: Icons.movie,
          imageUrl: 'https://via.placeholder.com/150',
          tags: const ['film', 'movies', 'entertainment'],
          spaceType: SpaceType.studentOrg,
          createdAt: DateTime.now().subtract(const Duration(days: 730)),
          updatedAt: DateTime.now(),
          eventIds: const [],
          metrics: SpaceMetrics.initial('space2'),
        ),
        customPitch: 'Share your passion for film',
        recommendationReason: 'Popular on campus',
      ),
      RecommendedSpace(
        space: Space(
          id: 'space3',
          name: 'Business Leaders',
          description:
              'Networking and career development for business students',
          icon: Icons.business,
          imageUrl: 'https://via.placeholder.com/150',
          tags: const ['business', 'networking', 'career'],
          spaceType: SpaceType.studentOrg,
          createdAt: DateTime.now().subtract(const Duration(days: 545)),
          updatedAt: DateTime.now(),
          eventIds: const [],
          metrics: SpaceMetrics.initial('space3'),
        ),
        customPitch: 'Connect with future entrepreneurs',
        recommendationReason: 'Trending now',
      ),
    ];
  }

  @override
  Stream<Either<FeedFailure, List<Map<String, dynamic>>>> getFeedStream() {
    try {
      final now = DateTime.now();
      final firestoreNow = Timestamp.fromDate(now);

      // Stream 1: Upcoming Events
      final eventsStream = _firestore
          .collection('events')
          // REMOVED: .where('endDate', isGreaterThan: firestoreNow) // Cannot compare String with Timestamp server-side
          .orderBy('endDate') // Still ordering by string, might not be perfect chronologically
          .limit(50) // Fetching first 50 ordered by string
          .snapshots()
          .map((snapshot) {
            // Process the snapshot into a list of Event objects
            debugPrint('🔄 FEED STREAM: Received ${snapshot.docs.length} event snapshots for client-side filtering.');
            final now = DateTime.now(); // Get current time for client-side comparison
            final events = snapshot.docs.map((doc) {
              try {
                final data = _processTimestamps(doc.data());
                data['id'] = doc.id;
                // Assuming Event.fromJson correctly parses the endDate string to DateTime
                return Event.fromJson(data); 
              } catch (e) {
                debugPrint('❌ FEED STREAM: Error parsing event ${doc.id}: $e');
                return null;
              }
            }).whereType<Event>()
              // ADDED: Client-side filtering after parsing
              .where((event) => event.endDate.isAfter(now)) 
              .toList();
            
            // Optionally sort again by actual DateTime if needed, as string sort wasn't chronological
            events.sort((a, b) => a.startDate.compareTo(b.startDate)); 
            
            debugPrint('✅ FEED STREAM: Found ${events.length} future events after client-side filtering.');
            return events;
          }).handleError((error) {
            debugPrint('❌ FEED STREAM: Error in eventsStream: $error');
            return <Event>[];
          });

      // Stream 2: Recent Reposts
      final repostsStream = _firestore
          .collection('reposts')
          .where('repostTime', isGreaterThan: Timestamp.fromDate(now.subtract(const Duration(days: 1))))
          .orderBy('repostTime', descending: true)
          .limit(30)
          .snapshots()
          .asyncMap((snapshot) async {
            // Process the snapshot into a list of RepostedEvent objects
            debugPrint('🔄 FEED STREAM: Received ${snapshot.docs.length} repost snapshots.');
            final repostFutures = snapshot.docs.map((doc) async {
              try {
                final data = doc.data();
                // RepostedEvent.fromJson needs UserProfile and Event, requires async fetching

                // Fetch Event data
                final eventRef = data['eventRef'] as DocumentReference?;
                if (eventRef == null) return null;
                final eventSnap = await eventRef.get();
                if (!eventSnap.exists) return null;
                final eventData = _processTimestamps(eventSnap.data() as Map<String, dynamic>);
                // Add event document ID
                eventData['id'] = eventSnap.id;
                final event = Event.fromJson(eventData);

                // Filter out reposts for past events
                if (event.endDate.isBefore(now)) {
                  return null;
                }

                // Fetch UserProfile data
                final userRef = data['repostedByRef'] as DocumentReference?;
                if (userRef == null) return null;
                final userSnap = await userRef.get();
                if (!userSnap.exists) return null;
                final userData = _processTimestamps(userSnap.data() as Map<String, dynamic>);
                // Add user document ID
                userData['id'] = userSnap.id;
                final userProfile = UserProfile.fromJson(userData);

                // Create RepostedEvent (using the fromStreamData factory)
                return RepostedEvent.fromStreamData(
                  id: doc.id, // Use the repost doc id here
                  event: event,
                  repostedBy: userProfile,
                  repostTime: (data['repostTime'] as Timestamp).toDate(),
                  comment: data['comment'] as String?,
                  repostType: data['repostType'] ?? RepostContentType.standard.name,
                );
              } catch (e) {
                debugPrint('❌ FEED STREAM: Error parsing repost ${doc.id}: $e');
                return null;
              }
            });
            final reposts = (await Future.wait(repostFutures)).whereType<RepostedEvent>().toList();
            return reposts;
          }).handleError((error) {
            debugPrint('❌ FEED STREAM: Error in repostsStream: $error');
            return <RepostedEvent>[];
          });

      // Combine streams and wrap result in Either.right
      return CombineLatestStream.combine2(
        eventsStream,
        repostsStream,
        (List<Event> events, List<RepostedEvent> reposts) {
          // Process the combined stream data into feed items
          final List<Map<String, dynamic>> feedItems = _processCombinedFeedData(events, reposts);
          return Either<FeedFailure, List<Map<String, dynamic>>>.right(feedItems);
        },
      ).handleError((error) {
        // Handle errors by returning a left Either with the appropriate failure
        debugPrint('❌ FEED STREAM: Error in combined stream: $error');
        return Either<FeedFailure, List<Map<String, dynamic>>>.left(
          EventsLoadFailure(originalException: error),
        );
      });
    } catch (e) {
      // Return a stream with a single error emission if setup fails
      debugPrint('❌ FEED STREAM: Error setting up stream: $e');
      return Stream.value(
        Either<FeedFailure, List<Map<String, dynamic>>>.left(
          EventsLoadFailure(originalException: e),
        ),
      );
    }
  }

  // Helper method to process combined feed data
  List<Map<String, dynamic>> _processCombinedFeedData(List<Event> events, List<RepostedEvent> reposts) {
    debugPrint('🔄 FEED STREAM: Combining ${events.length} events and ${reposts.length} reposts.');
    final List<Map<String, dynamic>> feedItems = [];
    final Set<String> includedEventIds = {};

    // Add Events
    for (final event in events) {
      feedItems.add({
        'type': 'event',
        'data': event,
        'sortKey': event.startDate.millisecondsSinceEpoch,
      });
      includedEventIds.add(event.id);
    }

    // Add Reposts (only if original event isn't already included)
    for (final repost in reposts) {
      if (!includedEventIds.contains(repost.event.id)) {
        feedItems.add({
          'type': 'repost',
          'data': repost,
          'sortKey': repost.repostedAt.millisecondsSinceEpoch,
        });
        includedEventIds.add(repost.event.id);
      }
    }

    // Sort combined list
    feedItems.sort((a, b) {
      if (a['type'] == b['type']) {
        final aKey = a['sortKey'] as int;
        final bKey = b['sortKey'] as int;
        return a['type'] == 'event' ? aKey.compareTo(bKey) : bKey.compareTo(aKey);
      }
      return a['type'] == 'repost' ? -1 : 1;
    });

    debugPrint('✅ FEED STREAM: Combined list has ${feedItems.length} items.');
    return feedItems;
  }

  // Helper method to process Firestore timestamps into DateTime
  // Ensure this exists or add it
  Map<String, dynamic> _processTimestamps(Map<String, dynamic> data) {
    final result = Map<String, dynamic>.from(data);
    result.forEach((key, value) {
      if (value is Timestamp) {
        result[key] = value.toDate();
      } else if (value is Map) {
        // Recursively process nested maps
        result[key] = _processTimestamps(value as Map<String, dynamic>);
      } else if (value is List) {
        // Process items in lists (check if they are maps or timestamps)
        result[key] = value.map((item) {
          if (item is Map) {
            return _processTimestamps(item as Map<String, dynamic>);
          } else if (item is Timestamp) {
            return item.toDate();
          }
          return item;
        }).toList();
      }
    });
    // Explicitly convert known timestamp fields
    const List<String> timestampKeys = [
      'startDate', 'endDate', 'repostTime', 'createdAt', 'updatedAt', 'lastActivity'
    ];
    for (final key in timestampKeys) {
      if (data[key] is Timestamp) {
        result[key] = (data[key] as Timestamp).toDate();
      }
    }
    return result;
  }
}

// Ensure RepostedEvent has a suitable factory/constructor for stream data
// Example:
// extension RepostedEventStreamFactory on RepostedEvent {
//   static RepostedEvent fromStreamData({
//     required String id,
//     required Event event,
//     required UserProfile repostedBy,
//     required DateTime repostTime,
//     String? comment,
//     required String repostType,
//   }) {
//     return RepostedEvent(
//       id: id,
//       event: event,
//       repostedBy: repostedBy,
//       repostTime: repostTime,
//       comment: comment,
//       contentType: RepostContentType.values.firstWhere(
//         (e) => e.name == repostType,
//         orElse: () => RepostContentType.standard,
//       ),
//       // Initialize other fields like interactionCounts, etc.
//       interactionCounts: {}, // Default or fetch separately if needed
//     );
//   }
// }
