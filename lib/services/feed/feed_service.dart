import 'package:flutter/material.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/models/feed_state.dart';
import 'package:hive_ui/services/analytics_service.dart';
import 'package:hive_ui/services/event_service.dart';
import 'package:hive_ui/services/space_event_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for handling feed data operations including fetching, filtering and caching
class FeedService {
  static const String _feedCacheKey = 'feed_cache';
  static const String _feedLastFetchKey = 'feed_last_fetch';
  // Increase cache duration to 12 hours to prevent frequent RSS polling
  static const Duration _cacheDuration = Duration(hours: 12);
  // Add minimum refresh interval to prevent excessive feed refreshes
  static const Duration _minimumRefreshInterval = Duration(minutes: 5);
  // Last refresh timestamp to limit frequency
  static DateTime? _lastRefreshTime;

  // Flag to control RSS feed fetching
  static bool _enableRssFeedFetching = false;
  // Flag to track if a fetch is in progress
  static bool _isFetchInProgress = false;

  /// Set whether RSS feed fetching is enabled
  static void setRssFeedFetchingEnabled(bool enabled) {
    _enableRssFeedFetching = enabled;
    debugPrint(
        'FeedService: RSS feed fetching ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Fetch events for the feed with pagination and caching
  static Future<Map<String, dynamic>> fetchFeedEvents({
    bool forceRefresh = false,
    int page = 1,
    int pageSize = 20,
    EventFilters? filters,
    bool userInitiated = false,
  }) async {
    // Prevent multiple simultaneous fetches
    if (_isFetchInProgress) {
      debugPrint('Feed fetch already in progress, returning empty results');
      return {
        'events': <Event>[],
        'totalCount': 0,
        'hasMore': false,
        'fromCache': true,
        'page': page,
        'pageSize': pageSize,
        'error': 'Another fetch is already in progress'
      };
    }

    // Rate limit refreshes unless forced
    if (!forceRefresh && _lastRefreshTime != null) {
      final timeSinceLastRefresh = DateTime.now().difference(_lastRefreshTime!);
      if (timeSinceLastRefresh < _minimumRefreshInterval) {
        debugPrint('Skipping refresh due to rate limiting (last refresh: ${timeSinceLastRefresh.inSeconds}s ago)');
        forceRefresh = false;
      }
    }

    _isFetchInProgress = true;
    try {
      final now = DateTime.now();
      final prefs = await SharedPreferences.getInstance();

      // Check cache first
      if (!forceRefresh) {
        final lastFetchStr = prefs.getString(_feedLastFetchKey);
        final cacheStr = prefs.getString(_feedCacheKey);

        if (lastFetchStr != null && cacheStr != null) {
          final lastFetch = DateTime.parse(lastFetchStr);

          // Cache is still valid
          if (now.difference(lastFetch) < _cacheDuration) {
            try {
              final cachedData = json.decode(cacheStr) as Map<String, dynamic>;
              final events = (cachedData['events'] as List)
                  .map((e) => Event.fromJson(e as Map<String, dynamic>))
                  .toList();

              // Apply time filters - only show relevant events
              final relevantEvents = _filterPastEvents(events, now);

              // Normalize dates to fix events with incorrect future years
              final normalizedEvents = _normalizeEventDates(relevantEvents);

              // Apply additional filters if needed
              final filteredEvents = filters != null
                  ? normalizedEvents.where((event) => filters.matches(event)).toList()
                  : normalizedEvents;

              // Apply pagination with the updated batch size
              final paginatedEvents =
                  _paginateEvents(filteredEvents, page, pageSize);

              final hasMore = page * pageSize < filteredEvents.length;

              // Log batch information
              debugPrint('Loaded batch $page (size: $pageSize) from cache. ' +
                  'Total events: ${filteredEvents.length}, ' +
                  'Batch events: ${paginatedEvents.length}, ' +
                  'Has more: $hasMore');

              return {
                'events': paginatedEvents,
                'totalCount': filteredEvents.length,
                'hasMore': hasMore,
                'fromCache': true,
                'page': page,
                'pageSize': pageSize,
              };
            } catch (cacheError) {
              debugPrint('Error parsing cache data: $cacheError');
              // Cache is corrupted, continue to fetch from data sources
            }
          }
        }
      }

      // Cache invalid or force refresh, fetch from data sources
      List<Event> events = [];

      // Only proceed with RSS feed fetching if explicitly enabled or user initiated
      bool shouldFetchRss =
          _enableRssFeedFetching || userInitiated || forceRefresh;

      // Track fetch start time for performance monitoring
      final fetchStartTime = DateTime.now();
      
      // Try direct events query first - this is typically much faster
      debugPrint('======= FETCHING EVENTS DIRECTLY FROM EVENTS COLLECTION =======');
      try {
        debugPrint('Attempting to fetch events from SpaceEventManager');
        debugPrint('Using direct events query approach first');
        debugPrint('Fetching events directly from events collection');
        
        // Query Firestore directly for faster response
        final eventsSnapshot = await FirebaseFirestore.instance
            .collection('events')
            .where('startDate', isGreaterThan: Timestamp.fromDate(
                now.subtract(const Duration(days: 1))))
            .orderBy('startDate')
            .limit(50) // Limit to a reasonable number
            .get();
            
        if (eventsSnapshot.docs.isNotEmpty) {
          debugPrint('Retrieved ${eventsSnapshot.docs.length} events from events collection');
          
          // Convert to Event objects
          events = eventsSnapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Event.fromJson(data);
          }).toList();
          
          debugPrint('Updating feed with ${events.length} events');
        }
        
        if (events.isNotEmpty) {
          debugPrint('Retrieved ${events.length} events directly from events collection');
          debugPrint('Found ${events.length} events directly from events collection');
        } else {
          debugPrint('No events found in direct query, falling back to SpaceEventManager');
          // Fall back to SpaceEventManager if direct query returns no results
          events = await SpaceEventManager.getAllEvents(
            limit: page * pageSize * 2,
            startDate: filters?.dateRange?.start ?? now.subtract(const Duration(hours: 6)),
            endDate: filters?.dateRange?.end,
            category: filters?.categories.isNotEmpty == true
                ? filters?.categories.first
                : null,
          );
        }
      } catch (e) {
        debugPrint('Error fetching events from direct query: $e');

        // Second attempt: Try to get events through SpaceEventManager
        try {
          debugPrint('Falling back to SpaceEventManager.getAllEvents()');
          events = await SpaceEventManager.getAllEvents(
            limit: page * pageSize * 2,
            startDate: filters?.dateRange?.start ?? now.subtract(const Duration(hours: 6)),
            endDate: filters?.dateRange?.end,
            category: filters?.categories.isNotEmpty == true
                ? filters?.categories.first
                : null,
          );
        } catch (managerError) {
          debugPrint('Error fetching events from SpaceEventManager: $managerError');

          // Third attempt: Try fetching through EventService only if RSS is enabled
          if (shouldFetchRss) {
            try {
              debugPrint(
                  'Attempting to fetch events from EventService (RSS feeds)');
              events = await EventService.getEvents(forceRefresh: userInitiated);
            } catch (fallbackError) {
              debugPrint('RSS event fetch failed: $fallbackError');

              // Fourth attempt: Try to get mock/sample events as a last resort
              try {
                debugPrint('Attempting to create mock events as last resort');
                events = _createSampleEvents();
              } catch (mockError) {
                debugPrint('Failed to create mock events: $mockError');
                // Return empty array but don't fail
                events = [];
              }
            }
          } else {
            debugPrint('Skipping RSS feed fetching (disabled)');
            // Try to use mock events directly since RSS fetching is disabled
            events = _createSampleEvents();
          }
        }
      }

      // Filter out past events
      final relevantEvents = _filterPastEvents(events, now);

      // Normalize dates to fix events with incorrect future years
      final normalizedEvents = _normalizeEventDates(relevantEvents);

      // Apply additional filters if needed
      final filteredEvents = (normalizedEvents.isNotEmpty && filters != null)
          ? normalizedEvents.where((event) => filters.matches(event)).toList()
          : normalizedEvents;

      // Update cache with all events
      if (events.isNotEmpty) {
        await _updateCache(events);
      }

      // Update last refresh time
      _lastRefreshTime = DateTime.now();
      
      // Log performance metrics
      final fetchDuration = _lastRefreshTime!.difference(fetchStartTime);
      debugPrint('Feed fetch completed in ${fetchDuration.inMilliseconds}ms');

      // Track performance
      AnalyticsService.logEvent('feed_events_loaded', parameters: {
        'count': events.length,
        'filtered_count': filteredEvents.length,
        'force_refresh': forceRefresh,
        'user_initiated': userInitiated,
        'rss_fetch_enabled': shouldFetchRss,
        'page': page,
        'page_size': pageSize,
        'fetch_duration_ms': fetchDuration.inMilliseconds,
      });

      // Apply pagination
      final paginatedEvents = _paginateEvents(filteredEvents, page, pageSize);
      final hasMore = page * pageSize < filteredEvents.length;

      // Log batch information
      debugPrint('Loaded batch $page (size: $pageSize) from network. ' +
          'Total events: ${filteredEvents.length}, ' +
          'Batch events: ${paginatedEvents.length}, ' +
          'Has more: $hasMore');

      return {
        'events': paginatedEvents,
        'totalCount': filteredEvents.length,
        'hasMore': hasMore,
        'fromCache': false,
        'page': page,
        'pageSize': pageSize,
      };
    } catch (e) {
      debugPrint('Error fetching feed events: $e');

      // Track error
      AnalyticsService.logEvent('feed_events_error', parameters: {
        'error': e.toString(),
      });

      return {
        'events': <Event>[],
        'totalCount': 0,
        'hasMore': false,
        'error': e.toString(),
        'page': page,
        'pageSize': pageSize,
      };
    } finally {
      _isFetchInProgress = false;
    }
  }

  /// Filter out past events that are no longer relevant
  static List<Event> _filterPastEvents(List<Event> events, DateTime now) {
    debugPrint('Filtering ${events.length} events to remove past events');
    
    // Only keep events that haven't ended yet (strictly in the future)
    final filteredEvents = events.where((event) {
      // Check if event has ended - only keep events where end date is after now
      final isUpcoming = event.endDate.isAfter(now);
      
      if (!isUpcoming) {
        // Log details about filtered events
        final hoursAgo = now.difference(event.endDate).inHours;
        debugPrint('⚠️ Filtering out past event: "${event.title}" - ended ${hoursAgo} hours ago at ${event.endDate}');
      } else {
        // For upcoming events, calculate and log how soon they are
        final hoursUntilStart = event.startDate.difference(now).inHours;
        final hoursUntilEnd = event.endDate.difference(now).inHours;
        
        if (hoursUntilStart <= 0) {
          // Event is happening now
          debugPrint('✅ Keeping currently happening event: "${event.title}" - started ${-hoursUntilStart} hours ago, ends in ${hoursUntilEnd} hours');
        } else {
          // Event is in the future
          debugPrint('✅ Keeping upcoming event: "${event.title}" - starts in ${hoursUntilStart} hours, ends in ${hoursUntilEnd} hours');
        }
      }
      
      return isUpcoming;
    }).toList();
    
    // Sort events by start date (soonest first)
    filteredEvents.sort((a, b) => a.startDate.compareTo(b.startDate));
    
    debugPrint('Filtered out ${events.length - filteredEvents.length} past events, keeping ${filteredEvents.length} upcoming events');
    return filteredEvents;
  }

  /// Normalize event dates to ensure they are in the correct year range
  /// This fixes issues with events showing dates far in the future
  static List<Event> _normalizeEventDates(List<Event> events) {
    final now = DateTime.now();
    final currentYear = now.year;
    
    return events.map((event) {
      // Check if event is more than 3 months in the future
      final monthsInFuture = (event.startDate.year - currentYear) * 12 +
          event.startDate.month - now.month;
          
      // If event is in a future year and more than 3 months ahead, adjust it
      if (event.startDate.year > currentYear && monthsInFuture > 3) {
        // Create a new date with the current year
        final newStartDate = DateTime(
          currentYear,
          event.startDate.month,
          event.startDate.day,
          event.startDate.hour,
          event.startDate.minute,
        );
        
        // Calculate end date based on original duration
        final duration = event.endDate.difference(event.startDate);
        final newEndDate = newStartDate.add(duration);
        
        // Return a new event with adjusted dates
        return event.copyWith(
          startDate: newStartDate,
          endDate: newEndDate,
        );
      }
      
      return event;
    }).toList();
  }

  /// Paginate events into batches
  static List<Event> _paginateEvents(
      List<Event> events, int page, int pageSize) {
    if (events.isEmpty) return [];
    
    final startIndex = (page - 1) * pageSize;
    if (startIndex >= events.length) return [];
    
    final endIndex = startIndex + pageSize > events.length
        ? events.length
        : startIndex + pageSize;
    
    return events.sublist(startIndex, endIndex);
  }

  /// Create sample events for fallback scenario
  static List<Event> _createSampleEvents() {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final nextWeek = now.add(const Duration(days: 7));

    return [
      Event(
        id: 'fallback_1',
        title: 'Campus Social Mixer',
        description: 'Meet new friends and connect with campus organizations.',
        startDate: tomorrow,
        endDate: tomorrow.add(const Duration(hours: 2)),
        location: 'Student Center',
        imageUrl:
            'https://images.unsplash.com/photo-1529156069898-49953e39b3ac',
        organizerName: 'Student Affairs',
        organizerEmail: 'student.affairs@university.edu',
        category: 'Social',
        tags: const ['networking', 'campus life'],
        source: EventSource.external,
        status: 'active',
        link: 'https://university.edu/events/social-mixer',
      ),
      Event(
        id: 'fallback_2',
        title: 'Career Development Workshop',
        description:
            'Learn skills to enhance your job prospects after graduation.',
        startDate: tomorrow.add(const Duration(days: 2)),
        endDate: tomorrow.add(const Duration(days: 2, hours: 3)),
        location: 'Business Building Room 201',
        imageUrl: 'https://images.unsplash.com/photo-1552664730-d307ca884978',
        organizerName: 'Career Services',
        organizerEmail: 'career.services@university.edu',
        category: 'Workshop',
        tags: const ['career', 'professional development'],
        source: EventSource.external,
        status: 'active',
        link: 'https://university.edu/events/career-workshop',
      ),
      Event(
        id: 'fallback_3',
        title: 'Campus Movie Night',
        description: 'Free movie screening with popcorn and drinks provided.',
        startDate: nextWeek,
        endDate: nextWeek.add(const Duration(hours: 3)),
        location: 'University Theater',
        imageUrl:
            'https://images.unsplash.com/photo-1517604931442-7e0c8ed2963c',
        organizerName: 'Campus Activities Board',
        organizerEmail: 'campus.activities@university.edu',
        category: 'Entertainment',
        tags: const ['movie', 'free food'],
        source: EventSource.external,
        status: 'active',
        link: 'https://university.edu/events/movie-night',
      ),
    ];
  }

  /// Update the feed cache
  static Future<void> _updateCache(List<Event> events) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = events.map((e) => e.toJson()).toList();

      await prefs.setString(_feedCacheKey, json.encode({'events': eventsJson}));
      await prefs.setString(
          _feedLastFetchKey, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Error updating feed cache: $e');
    }
  }

  /// Track user interaction with feed items
  static Future<void> trackFeedInteraction(
      String eventId, String interactionType) async {
    try {
      // Get event details
      final event = await SpaceEventManager.getEventById(eventId);
      if (event == null) return;

      // Track in analytics
      AnalyticsService.logEvent('feed_interaction', parameters: {
        'event_id': eventId,
        'event_title': event.title,
        'organizer': event.organizerName,
        'interaction_type': interactionType,
      });

      // Store interaction for personalization
      await _storeInteractionForPersonalization(event, interactionType);
    } catch (e) {
      debugPrint('Error tracking feed interaction: $e');
    }
  }

  /// Store interaction data for future personalization
  static Future<void> _storeInteractionForPersonalization(
      Event event, String interactionType) async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'user_interactions';
    final interactionsStr = prefs.getString(key);

    final interactions = interactionsStr != null
        ? json.decode(interactionsStr) as Map<String, dynamic>
        : <String, dynamic>{};

    // Track by category
    final categories =
        interactions['categories'] as Map<String, dynamic>? ?? {};
    categories[event.category] = (categories[event.category] as int? ?? 0) + 1;
    interactions['categories'] = categories;

    // Track by organizer
    final organizers =
        interactions['organizers'] as Map<String, dynamic>? ?? {};
    organizers[event.organizerName] =
        (organizers[event.organizerName] as int? ?? 0) + 1;
    interactions['organizers'] = organizers;

    // Track by tags
    final tags = interactions['tags'] as Map<String, dynamic>? ?? {};
    for (final tag in event.tags) {
      tags[tag] = (tags[tag] as int? ?? 0) + 1;
    }
    interactions['tags'] = tags;

    // Track recent interactions (keep last 20)
    final recent = interactions['recent'] as List<dynamic>? ?? [];
    recent.insert(0, {
      'event_id': event.id,
      'interaction_type': interactionType,
      'timestamp': DateTime.now().toIso8601String(),
    });

    if (recent.length > 20) {
      recent.removeRange(20, recent.length);
    }

    interactions['recent'] = recent;

    // Save updated interactions
    await prefs.setString(key, json.encode(interactions));
  }

  /// Generate personalized feed items based on user interactions
  static Future<List<Event>> generatePersonalizedFeed(
      List<Event> events, List<String> userInterests) async {
    if (events.isEmpty) return [];

    try {
      final prefs = await SharedPreferences.getInstance();
      const key = 'user_interactions';
      final interactionsStr = prefs.getString(key);

      // If no interaction data, return chronological items
      if (interactionsStr == null) {
        events.sort((a, b) => a.startDate.compareTo(b.startDate));
        return events.take(20).toList();
      }

      final interactions = json.decode(interactionsStr) as Map<String, dynamic>;
      final categories =
          interactions['categories'] as Map<String, dynamic>? ?? {};
      final organizers =
          interactions['organizers'] as Map<String, dynamic>? ?? {};
      final tags = interactions['tags'] as Map<String, dynamic>? ?? {};

      // Score events based on user preferences and interactions
      final scoredEvents = <MapEntry<Event, double>>[];

      for (final event in events) {
        double score = 0;

        // Base score for recency (0-5 points)
        final daysUntil = event.startDate.difference(DateTime.now()).inDays;
        if (daysUntil >= 0) {
          score += daysUntil <= 7 ? 5 - (daysUntil / 2) : 0;
        }

        // Category preference (0-3 points)
        final categoryScore = categories[event.category] as int? ?? 0;
        score += categoryScore > 0 ? 3 * (categoryScore / 5).clamp(0, 1) : 0;

        // Organizer preference (0-4 points)
        final organizerScore = organizers[event.organizerName] as int? ?? 0;
        score += organizerScore > 0 ? 4 * (organizerScore / 5).clamp(0, 1) : 0;

        // Tags preference (0-3 points)
        double tagScore = 0;
        for (final tag in event.tags) {
          tagScore += tags[tag] as int? ?? 0;
        }
        score += tagScore > 0 ? 3 * (tagScore / 10).clamp(0, 1) : 0;

        // Explicit user interests (0-5 points)
        for (final interest in userInterests) {
          if (event.category.toLowerCase() == interest.toLowerCase() ||
              event.tags
                  .any((tag) => tag.toLowerCase() == interest.toLowerCase())) {
            score += 5;
            break;
          }
        }

        scoredEvents.add(MapEntry(event, score));
      }

      // Sort by score (descending)
      scoredEvents.sort((a, b) => b.value.compareTo(a.value));

      // Return top 20 events
      return scoredEvents.take(20).map((e) => e.key).toList();
    } catch (e) {
      debugPrint('Error generating personalized feed: $e');

      // Fallback to chronological sort
      events.sort((a, b) => a.startDate.compareTo(b.startDate));
      return events.take(20).toList();
    }
  }

  /// Clear feed cache
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_feedCacheKey);
      await prefs.remove(_feedLastFetchKey);
    } catch (e) {
      debugPrint('Error clearing feed cache: $e');
    }
  }

  /// Get feed information for a specific event by its ID
  /// Returns a detailed object containing the event, related content, engagement metrics, and activity feed
  static Future<Map<String, dynamic>> getEventFeedById(String eventId) async {
    try {
      // Get the core event data
      final event = await SpaceEventManager.getEventById(eventId);
      
      if (event == null) {
        return {
          'success': false,
          'error': 'Event not found',
          'eventId': eventId,
        };
      }
      
      // Get engagement metrics
      final attendees = event.attendees.length;
      
      // Get user's RSVP status if logged in
      bool? userRsvpStatus;
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        userRsvpStatus = await EventService.getEventRsvpStatus(eventId);
      }
      
      // Get related events from same organizer
      final organizerEvents = await _getEventsFromSameOrganizer(
        event.organizerName, 
        excludeEventId: eventId,
        limit: 3,
      );
      
      // Get comments if available
      final comments = await _getEventComments(eventId);
      
      // Get activity feed for this event
      final activityFeed = await _getEventActivityFeed(eventId);
      
      return {
        'success': true,
        'event': event,
        'engagement': {
          'attendees': attendees,
          'userRsvpStatus': userRsvpStatus,
        },
        'relatedEvents': organizerEvents,
        'comments': comments,
        'activityFeed': activityFeed,
      };
    } catch (e) {
      debugPrint('Error getting event feed by ID: $e');
      return {
        'success': false,
        'error': e.toString(),
        'eventId': eventId,
      };
    }
  }
  
  /// Helper method to get events from the same organizer
  static Future<List<Event>> _getEventsFromSameOrganizer(
    String organizerName, {
    String? excludeEventId,
    int limit = 5,
  }) async {
    try {
      // Find events from the same organizer
      final List<Event> events = [];
      
      // Find which space this organizer belongs to
      final existingSpace = await SpaceEventManager.findExistingSpaceByOrganizerName(organizerName);
      
      if (existingSpace != null) {
        final spaceId = existingSpace['id'] as String;
        final typeCollection = existingSpace['type'] as String;
        
        // Get events for this space
        final eventsSnapshot = await FirebaseFirestore.instance
            .collection('spaces')
            .doc(typeCollection)
            .collection('spaces')
            .doc(spaceId)
            .collection('events')
            .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
            .orderBy('startDate')
            .limit(limit + 1) // Get one extra to account for excluded event
            .get();
            
        for (final doc in eventsSnapshot.docs) {
          // Skip the excluded event
          if (excludeEventId != null && doc.id == excludeEventId) {
            continue;
          }
          
          try {
            final event = Event.fromJson(doc.data());
            events.add(event);
            
            // Break if we have enough events
            if (events.length >= limit) {
              break;
            }
          } catch (e) {
            debugPrint('Error parsing event from same organizer: $e');
          }
        }
      }
      
      return events;
    } catch (e) {
      debugPrint('Error getting events from same organizer: $e');
      return [];
    }
  }
  
  /// Helper method to get comments for an event
  static Future<List<Map<String, dynamic>>> _getEventComments(String eventId) async {
    try {
      final commentsSnapshot = await FirebaseFirestore.instance
          .collection('event_comments')
          .doc(eventId)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();
          
      final comments = commentsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'text': data['text'] ?? '',
          'userId': data['userId'] ?? '',
          'userName': data['userName'] ?? 'Anonymous',
          'timestamp': data['timestamp'] != null ? 
              (data['timestamp'] as Timestamp).toDate().toIso8601String() : 
              DateTime.now().toIso8601String(),
          'userPhotoUrl': data['userPhotoUrl'] ?? '',
        };
      }).toList();
      
      return comments;
    } catch (e) {
      debugPrint('Error getting event comments: $e');
      return [];
    }
  }
  
  /// Helper method to get activity feed for an event
  static Future<List<Map<String, dynamic>>> _getEventActivityFeed(String eventId) async {
    try {
      final activitySnapshot = await FirebaseFirestore.instance
          .collection('event_activity')
          .doc(eventId)
          .collection('activities')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();
          
      final activities = activitySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'type': data['type'] ?? 'unknown', // rsvp, comment, share, etc.
          'userId': data['userId'] ?? '',
          'userName': data['userName'] ?? 'Anonymous',
          'timestamp': data['timestamp'] != null ? 
              (data['timestamp'] as Timestamp).toDate().toIso8601String() : 
              DateTime.now().toIso8601String(),
          'userPhotoUrl': data['userPhotoUrl'] ?? '',
          'metadata': data['metadata'] ?? {},
        };
      }).toList();
      
      return activities;
    } catch (e) {
      debugPrint('Error getting event activity feed: $e');
      return [];
    }
  }
}
