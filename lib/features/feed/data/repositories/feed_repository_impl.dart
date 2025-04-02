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
  Future<List<Event>> getEvents({
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
            return cachedEvents.sublist(lastIndex + 1, 
                (lastIndex + 1 + limit) < cachedEvents.length 
                  ? lastIndex + 1 + limit 
                  : cachedEvents.length);
          }
        }
        
        // Return first page if no last event or not found
        return cachedEvents.take(limit).toList();
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
          return events.sublist(lastIndex + 1, 
              (lastIndex + 1 + limit) < events.length 
                ? lastIndex + 1 + limit 
                : events.length);
        }
      }
      
      // Return first page if no last event or not found
      return events.take(limit).toList();
    } catch (e) {
      debugPrint('Error in FeedRepository.getEvents: $e');
      rethrow;
    }
  }
  
  @override
  Future<List<Event>> getRecommendedEvents({
    int limit = 10,
  }) async {
    try {
      // For now, reuse the regular events with a recommendation algorithm
      final events = await getEvents();
      
      // Simple recommendation - sort by date and filter upcoming
      final now = DateTime.now();
      final upcoming = events.where((e) => e.startDate.isAfter(now)).toList();
      
      // Sort by start date
      upcoming.sort((a, b) => a.startDate.compareTo(b.startDate));
      
      // Return a subset
      return upcoming.take(limit).toList();
    } catch (e) {
      debugPrint('Error in FeedRepository.getRecommendedEvents: $e');
      return [];
    }
  }
  
  @override
  Future<bool> getEventRsvpStatus(String eventId) async {
    try {
      // Check cache first
      if (_rsvpStatusCache.containsKey(eventId)) {
        return _rsvpStatusCache[eventId]!;
      }
      
      // Use existing service
      final status = await EventService.getEventRsvpStatus(eventId);
      
      // Update cache
      _rsvpStatusCache[eventId] = status;
      
      return status;
    } catch (e) {
      debugPrint('Error in FeedRepository.getEventRsvpStatus: $e');
      return false;
    }
  }
  
  @override
  Future<bool> rsvpToEvent(String eventId, bool attending) async {
    try {
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
      
      return success;
    } catch (e) {
      debugPrint('Error in FeedRepository.rsvpToEvent: $e');
      return false;
    }
  }
  
  @override
  Future<RepostedEvent?> repostEvent({
    required String eventId,
    String? comment,
    String? userId,
  }) async {
    try {
      // Ensure we have a user ID
      userId ??= _auth.currentUser?.uid;
      if (userId == null) {
        return null;
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
          return null; // Event not found
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
        return null; // Cannot create repost without profile
      }

      if (reposterProfile == null) {
        debugPrint('Reposter profile not found for ID: $userId');
        return null;
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
      
      return repost;
    } catch (e) {
      debugPrint('Error in FeedRepository.repostEvent: $e');
      return null;
    }
  }
  
  @override
  Future<void> clearCache() async {
    _eventCache.clear();
    _rsvpStatusCache.clear();
    _lastFeedFetchTime = null;
  }

  // Implement fetchFeedEvents using the correct EventFilters class
  @override
  Future<Map<String, dynamic>> fetchFeedEvents({
    bool forceRefresh = false,
    int page = 1,
    int pageSize = 20,
    EventFilters? filters,
    bool userInitiated = false,
  }) async {
    debugPrint('fetchFeedEvents called on bridge implementation');
    try {
      // Get events from our getEvents method
      final events = await getEvents(
        forceRefresh: forceRefresh, 
        limit: pageSize,
      );
      
      // Apply filters if provided
      List<Event> filteredEvents = events;
      if (filters != null && filters.hasActiveFilters) {
        filteredEvents = events.where((event) => filters.matches(event)).toList();
      }
      
      return {
        'events': filteredEvents,
        'hasMore': events.length >= pageSize,
      };
    } catch (e) {
      debugPrint('Error in fetchFeedEvents: $e');
      return {
        'events': <Event>[],
        'hasMore': false,
        'error': e.toString(),
      };
    }
  }

  /// Fetch events directly from spaces
  @override
  Future<List<Event>> fetchEventsFromSpaces({int limit = 20}) async {
    try {
      // Get current user for joined spaces
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('FeedRepositoryImpl: No authenticated user for fetching space events');
        // Fall back to global events for non-authenticated users
        return _fetchGlobalEvents(limit: limit);
      }
      
      // Use the Platform Integration Manager to get events from spaces the user follows
      // This implements the "Feed ↔ Spaces Integration" described in the platform overview
      return await _integrationManager.getEventsFromFollowedSpaces(
        userId: user.uid,
        limit: limit,
        startDate: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error in FeedRepositoryImpl.fetchEventsFromSpaces: $e');
      
      // Fall back to the existing method if the optimized approach fails
      return _fetchGlobalEvents(limit: limit);
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
  Future<List<RecommendedSpace>> fetchSpaceRecommendations(
      {int limit = 5}) async {
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

      return recommendations;
    } catch (e) {
      debugPrint('Error in FeedRepositoryImpl.fetchSpaceRecommendations: $e');

      // Fall back to sample recommendations if Firebase query fails
      return _createSampleSpaceRecommendations();
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

      return FeedPrioritizer.prioritizeEvents(
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
      );
    } catch (e) {
      debugPrint('Error in FeedRepositoryImpl.prioritizeEvents: $e');
      // Return original order if prioritization fails
      return events;
    }
  }

  /// Get user preferences from Firestore
  Future<Map<String, dynamic>> _getUserPreferences(String userId) async {
    try {
      final docSnapshot =
          await _firestore.collection('users').doc(userId).get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        return data ?? {};
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
}
