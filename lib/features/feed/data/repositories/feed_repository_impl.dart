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
import 'package:hive_ui/services/feed/feed_service.dart';
import 'package:hive_ui/services/feed/feed_prioritizer.dart';
import 'package:hive_ui/services/space_event_manager.dart';
import 'package:hive_ui/services/analytics_service.dart';
import '../../domain/repositories/feed_repository.dart';

/// Implementation of the feed repository that interacts with Firebase
class FeedRepositoryImpl implements FeedRepository {
  /// Firestore instance for database operations
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Auth instance for current user
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Fetch events for the feed with optional filtering and pagination
  @override
  Future<Map<String, dynamic>> fetchFeedEvents({
    bool forceRefresh = false,
    int page = 1,
    int pageSize = 20,
    EventFilters? filters,
    bool userInitiated = false,
  }) async {
    try {
      // Track the start time for performance monitoring
      final startTime = DateTime.now();

      // First try to fetch directly from Firebase
      try {
        final events = await _fetchEventsFromFirebase(
            page: page, pageSize: pageSize, filters: filters);

        // Track performance
        final duration = DateTime.now().difference(startTime).inMilliseconds;
        AnalyticsService.logEvent('feed_firebase_fetch_success', parameters: {
          'duration_ms': duration,
          'event_count': events.length,
          'filter_applied': filters?.hasActiveFilters ?? false,
        });

        // Return successful response
        return {
          'events': events,
          'hasMore': events.length >= pageSize,
          'fromCache': false,
        };
      } catch (firestoreError) {
        debugPrint('Error fetching events from Firestore: $firestoreError');

        // Fall back to feed service if Firebase direct query fails
        final result = await FeedService.fetchFeedEvents(
          forceRefresh: forceRefresh,
          page: page,
          pageSize: pageSize,
          filters: filters,
          userInitiated: userInitiated,
        );

        // Add error info to the result
        result['firebaseError'] = firestoreError.toString();

        return result;
      }
    } catch (e) {
      debugPrint('Error in FeedRepositoryImpl.fetchFeedEvents: $e');
      return {
        'events': <Event>[],
        'hasMore': false,
        'error': e.toString(),
      };
    }
  }

  /// Fetch events directly from Firebase
  Future<List<Event>> _fetchEventsFromFirebase({
    required int page,
    required int pageSize,
    EventFilters? filters,
  }) async {
    // Start with the events collection
    Query query = _firestore.collection('events');

    // Apply date filters if specified
    final dateRangeFilter = filters?.dateRange; // Get potential dateRange
    if (dateRangeFilter != null) {
      // Now we know dateRangeFilter is definitely not null
      query = query.where('startDate',
          isGreaterThanOrEqualTo: dateRangeFilter.start.toIso8601String());
    
      query = query.where('startDate',
          isLessThanOrEqualTo: dateRangeFilter.end.toIso8601String());
    } else {
      // Default to showing future events
      query = query.where('startDate',
          isGreaterThanOrEqualTo: DateTime.now().toIso8601String());
    }

    // Apply category filters
    if (filters?.categories.isNotEmpty == true) {
      // For multiple categories, we need to use 'in' operator
      if (filters!.categories.length > 1) {
        query = query.where('category', whereIn: filters.categories);
      } else {
        // For a single category, we can use '=='
        query = query.where('category', isEqualTo: filters.categories.first);
      }
    }

    // Apply source filters
    if (filters?.sources.isNotEmpty == true &&
        filters!.sources.length < EventSource.values.length) {
      // Convert enum values to strings for Firestore query
      final sourceStrings = filters.sources
          .map((source) => source.toString().split('.').last)
          .toList();

      query = query.where('source', whereIn: sourceStrings);
    }

    // Apply search query if provided
    if (filters?.searchQuery != null && filters!.searchQuery!.isNotEmpty) {
      final searchLower = filters.searchQuery!.toLowerCase();

      // Note: Full-text search would require a different approach
      // This is a basic implementation that checks if the title contains the query
      query = query
          .where('titleLowercase', isGreaterThanOrEqualTo: searchLower)
          .where('titleLowercase', isLessThan: '${searchLower}z');
    }

    // Order by start date
    query = query.orderBy('startDate', descending: false);

    // Apply pagination - Firebase doesn't have offset, but we can implement
    // pagination using limit and startAfter
    query = query.limit(pageSize);

    // If we need a specific page (not the first one)
    if (page > 1) {
      // Get a document to start after
      final lastDocQuery = query.limit((page - 1) * pageSize);
      final snapshot = await lastDocQuery.get();

      if (snapshot.docs.isNotEmpty) {
        // Get the last document from previous page
        final lastVisibleDoc = snapshot.docs.last;

        // Start after this document for the next page
        query = query.startAfter([lastVisibleDoc]);
      }
    }

    // Execute query
    final snapshot = await query.get();

    // Map results to Event objects
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id; // Ensure ID is included
      return Event.fromJson(data);
    }).toList();
  }

  /// Fetch events directly from spaces
  @override
  Future<List<Event>> fetchEventsFromSpaces({int limit = 20}) async {
    try {
      // Get current user for joined spaces
      final user = _auth.currentUser;
      List<String> joinedSpaceIds = [];
      
      // Get user's joined spaces if authenticated
      if (user != null) {
        try {
          final userSnapshot = await _firestore.collection('users').doc(user.uid).get();
          
          if (userSnapshot.exists) {
            final userData = userSnapshot.data() as Map<String, dynamic>;
            joinedSpaceIds = List<String>.from(userData['joinedSpaces'] ?? []);
          }
        } catch (e) {
          debugPrint('Error fetching user joined spaces: $e');
        }
      }

      // OPTIMIZED APPROACH: Directly query events collection for upcoming events
      final now = DateTime.now();
      final isoNow = now.toIso8601String();
      final List<Event> allEvents = [];
      
      // First try to get events from joined spaces (if any)
      if (joinedSpaceIds.isNotEmpty) {
        // We can only use "in" queries on non-array fields with up to 10 values
        // so we may need to do multiple queries if user has joined >10 spaces
        const batchSize = 10;
        
        for (var i = 0; i < joinedSpaceIds.length; i += batchSize) {
          // Query events where organizerName matches the space name
          // Note: We could add a spaceId field to events for better querying
          try {
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
                
            allEvents.addAll(events);
          } catch (e) {
            debugPrint('Error querying events for joined spaces batch: $e');
          }
        }
      }
      
      // If we don't have enough events from joined spaces, get recent events
      if (allEvents.length < limit) {
        try {
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
              .where((event) => !allEvents.any((e) => e.id == event.id)) // Avoid duplicates
              .take(limit - allEvents.length)
              .toList();
              
          allEvents.addAll(events);
        } catch (e) {
          debugPrint('Error querying global events: $e');
        }
      }
      
      // Sort events by start date
      allEvents.sort((a, b) => a.startDate.compareTo(b.startDate));
      
      // Return only up to the requested limit
      return allEvents.take(limit).toList();
    } catch (e) {
      debugPrint('Error in FeedRepositoryImpl.fetchEventsFromSpaces: $e');
      
      // Fall back to the existing method if the optimized approach fails
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
      return spaces.map((space) {
        // Calculate relevance score based on interest overlap - Removed as unused
        // final interestOverlap =
        //     space.tags.where((tag) => userInterests.contains(tag)).length;

        return RecommendedSpace(
          space: space,
          customPitch: 'Based on your interests',
          recommendationReason: 'Matches your interests',
        );
      }).toList();
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
        return docSnapshot.data() ?? {};
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
