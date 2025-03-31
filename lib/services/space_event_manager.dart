import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/models/space_type.dart';
import 'package:hive_ui/utils/space_categorizer.dart';
import 'package:hive_ui/services/request_interceptor.dart';
import 'package:hive_ui/services/optimized_data_service.dart';
import 'package:hive_ui/services/firebase_monitor.dart';
import 'dart:math' show max;

/// A service for managing events within spaces
class SpaceEventManager {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache for space and event data
  static final Map<String, List<Event>> _eventsCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheDuration = Duration(minutes: 30);
  static bool _isInitialized = false;

  /// Initialize the service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize dependent services
    await OptimizedDataService.initialize();
    RequestInterceptor.initialize();

    _isInitialized = true;
    debugPrint('SpaceEventManager initialized');
  }

  /// Deletes an event from its space
  ///
  /// @param eventId The ID of the event to delete
  /// @param spaceId The ID of the space containing the event
  /// @param spaceType The type of space (student_organizations, university_organizations, etc.)
  static Future<bool> deleteEvent({
    required String eventId,
    required String spaceId,
    required String spaceType,
  }) async {
    try {
      // Reference to the event document
      final eventRef = _firestore
          .collection('spaces')
          .doc(spaceType)
          .collection('spaces')
          .doc(spaceId)
          .collection('events')
          .doc(eventId);

      // Delete the event
      await eventRef.delete();

      // Clear cache for this space
      _eventsCache.remove(spaceId);
      _eventsCache.remove(spaceType);

      // Clear optimized cache as well
      await OptimizedDataService.clearCache();

      debugPrint('Successfully deleted event $eventId from space $spaceId');
      return true;
    } catch (e) {
      debugPrint('Error deleting event $eventId from space $spaceId: $e');
      return false;
    }
  }

  /// Gets the type collection string from SpaceType enum
  static String getTypeCollectionString(SpaceType type) {
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

  /// Adds or updates an event to a space
  /// If the event already exists, it will be updated with merge: true to preserve existing fields
  static Future<bool> addOrUpdateEvent({
    required Event event,
    required String spaceId,
    required SpaceType spaceType,
  }) async {
    try {
      final typeCollection = getTypeCollectionString(spaceType);

      // Reference to the event document
      final eventRef = _firestore
          .collection('spaces')
          .doc(typeCollection)
          .collection('spaces')
          .doc(spaceId)
          .collection('events')
          .doc(event.id);

      // Convert event to data
      final eventData = event.toJson();
      eventData['last_modified'] = FieldValue.serverTimestamp();
      eventData['source'] = event.source.toString();

      // Set the event data with merge: true to preserve existing fields
      await eventRef.set(eventData, SetOptions(merge: true));

      // Clear cache for this space and type
      _eventsCache.remove(spaceId);
      _eventsCache.remove(typeCollection);

      // Clear optimized cache for this space
      await OptimizedDataService.clearCache();

      debugPrint(
          'Successfully added/updated event ${event.id} in space $spaceId');
      return true;
    } catch (e) {
      debugPrint(
          'Error adding/updating event ${event.id} in space $spaceId: $e');
      return false;
    }
  }

  /// Get all space types as a list of strings
  static List<String> getAllSpaceTypes() {
    return [
      'student_organizations',
      'university_organizations',
      'campus_living',
      'fraternity_and_sorority',
      'other',
    ];
  }

  /// Fetches specific events by ID from a space
  /// Useful for quickly displaying events in the main feed
  /// @param spaceId The ID of the space to fetch events from
  /// @param eventIds List of event IDs to fetch
  /// @param spaceType Optional space type (if known, improves performance)
  static Future<List<Event>> getEventsByIds({
    required String spaceId,
    required List<String> eventIds,
    String? spaceType,
  }) async {
    if (eventIds.isEmpty) return [];

    try {
      debugPrint(
          'Fetching ${eventIds.length} specific events from space $spaceId');

      final List<Event> events = [];

      // Try fetching from global events collection first (new approach)
      final globalEventsCollection = _firestore.collection('events');
      
      // Use batching to efficiently fetch multiple events (max 10 at a time)
      for (int i = 0; i < eventIds.length; i += 10) {
        final batchIds = eventIds.sublist(
            i, i + 10 < eventIds.length ? i + 10 : eventIds.length);

        final snapshot = await globalEventsCollection
            .where(FieldPath.documentId, whereIn: batchIds)
            .get();

        // Record Firebase reads
        FirebaseMonitor.recordRead(count: snapshot.docs.length);

        for (final doc in snapshot.docs) {
          try {
            final eventData = doc.data();
            final processedData = _processTimestamps(eventData);
            final event = Event.fromJson(processedData);
            events.add(event);
          } catch (e) {
            debugPrint('Error parsing event ${doc.id}: $e');
          }
        }
      }

      // If events found in global collection, return them
      if (events.isNotEmpty) {
        debugPrint('Found ${events.length} events in global collection');
        return events;
      }

      // Fall back to the old method if no events found in global collection
      debugPrint('No events found in global collection, falling back to space-based lookup');

      // If space type is known, we can directly target the collection
      if (spaceType != null) {
        final eventsRef = _firestore
            .collection('spaces')
            .doc(spaceType)
            .collection('spaces')
            .doc(spaceId)
            .collection('events');

        // Use batching to efficiently fetch multiple events (max 10 at a time)
        for (int i = 0; i < eventIds.length; i += 10) {
          final batchIds = eventIds.sublist(
              i, i + 10 < eventIds.length ? i + 10 : eventIds.length);

          final snapshot = await eventsRef
              .where(FieldPath.documentId, whereIn: batchIds)
              .get();

          // Record Firebase reads
          FirebaseMonitor.recordRead(count: snapshot.docs.length);

          for (final doc in snapshot.docs) {
            try {
              final eventData = doc.data();
              final processedData = _processTimestamps(eventData);
              final event = Event.fromJson(processedData);
              events.add(event);
            } catch (e) {
              debugPrint('Error parsing event ${doc.id}: $e');
            }
          }
        }
      
        // If space type is unknown, search across all types
        final spaceTypes = getAllSpaceTypes();

        for (final type in spaceTypes) {
          final eventsRef = _firestore
              .collection('spaces')
              .doc(type)
              .collection('spaces')
              .doc(spaceId)
              .collection('events');

          // Check if space exists in this type
          final spaceDoc = await _firestore
              .collection('spaces')
              .doc(type)
              .collection('spaces')
              .doc(spaceId)
              .get();

          // Skip if space doesn't exist in this type
          if (!spaceDoc.exists) continue;

          // Use batching to efficiently fetch multiple events (max 10 at a time)
          for (int i = 0; i < eventIds.length; i += 10) {
            final batchIds = eventIds.sublist(
                i, i + 10 < eventIds.length ? i + 10 : eventIds.length);

            final snapshot = await eventsRef
                .where(FieldPath.documentId, whereIn: batchIds)
                .get();

            // Record Firebase reads
            FirebaseMonitor.recordRead(count: snapshot.docs.length);

            for (final doc in snapshot.docs) {
              try {
                final eventData = doc.data();
                final processedData = _processTimestamps(eventData);
                final event = Event.fromJson(processedData);
                events.add(event);
              } catch (e) {
                debugPrint('Error parsing event ${doc.id}: $e');
              }
            }
          }

          // If we found events, no need to check other types
          if (events.isNotEmpty) break;
        }
      }

      return events;
    } catch (e) {
      debugPrint('Error fetching events by IDs: $e');
      return [];
    }
  }

  /// Get all events across spaces
  /// @param limit Maximum number of events to return
  /// @param startDate Optional start date filter
  /// @param endDate Optional end date filter
  /// @param category Optional category filter
  /// @param spaceType Optional space type filter (student_organizations, university_organizations, etc.)
  /// @param startAfter Optional document snapshot to start after (for pagination)
  static Future<List<Event>> getAllEvents({
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    String? spaceType,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      // OPTIMIZED APPROACH: Directly query the events collection first
      debugPrint('Using direct events query approach first');
      
      // Cache key for current request
      final cacheKey =
          'events_${spaceType ?? "all"}_${limit}_${startDate?.millisecondsSinceEpoch ?? 0}_${endDate?.millisecondsSinceEpoch ?? 0}_${category ?? ""}';
      
      // Check cache first
      if (_eventsCache.containsKey(cacheKey) &&
          _cacheTimestamps.containsKey(cacheKey) &&
          DateTime.now().difference(_cacheTimestamps[cacheKey]!) < _cacheDuration) {
        debugPrint('Returning ${_eventsCache[cacheKey]!.length} events from cache for key $cacheKey');
        return _eventsCache[cacheKey]!;
      }
      
      // Try getting events directly from the events collection
      final events = await getEventsDirectly(
        limit: limit,
        startDate: startDate,
        endDate: endDate,
        category: category,
      );
      
      // If we have enough events, cache and return them
      if (events.length >= limit / 2) {
        debugPrint('Found ${events.length} events directly from events collection');
        
        // Cache the results
        _eventsCache[cacheKey] = events;
        _cacheTimestamps[cacheKey] = DateTime.now();
        
        return events;
      }
      
      // If we didn't get enough events, try the space type specific approach
      if (spaceType != null) {
        debugPrint('Not enough events from direct query, trying space type approach for $spaceType');
        
        try {
          final spaceTypeEvents = await getEventsForSpaceType(
            spaceType: spaceType,
            limit: limit,
            startDate: startDate,
            endDate: endDate,
            category: category,
          );
          
          // Merge with existing events
          final mergedEvents = [...events];
          for (final event in spaceTypeEvents) {
            if (!mergedEvents.any((e) => e.id == event.id)) {
              mergedEvents.add(event);
            }
          }
          
          // Sort and limit
          mergedEvents.sort((a, b) => a.startDate.compareTo(b.startDate));
          final limitedEvents = mergedEvents.length > limit 
              ? mergedEvents.sublist(0, limit) 
              : mergedEvents;
          
          // Cache the results
          _eventsCache[cacheKey] = limitedEvents;
          _cacheTimestamps[cacheKey] = DateTime.now();
          
          debugPrint('Returning ${limitedEvents.length} combined events');
          return limitedEvents;
        } catch (e) {
          debugPrint('Error in space type approach: $e');
          // Fall back to just the events we got directly
          if (events.isNotEmpty) {
            return events;
          }
        }
      }
      
      // If all fails, return the events we got directly (even if not enough)
      return events;
    } catch (e) {
      debugPrint('Error in getAllEvents: $e');
      return [];
    }
  }

  /// Get events for a specific space type
  /// We're optimizing this method to fetch larger batches
  static Future<List<Event>> getEventsForSpaceType({
    required String spaceType,
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      // Cache key for this request
      final cacheKey =
          'events_${spaceType}_${limit}_${startDate?.millisecondsSinceEpoch}_${endDate?.millisecondsSinceEpoch}_$category';

      // Check cache first
      if (_eventsCache.containsKey(cacheKey) &&
          _cacheTimestamps.containsKey(cacheKey) &&
          DateTime.now().difference(_cacheTimestamps[cacheKey]!) <
              _cacheDuration) {
        debugPrint(
            'Returning ${_eventsCache[cacheKey]!.length} events for $spaceType from cache');
        FirebaseMonitor.recordRead(
            count: _eventsCache[cacheKey]!.length, cached: true);
        return _eventsCache[cacheKey]!;
      }

      // Try the optimized approach first
      try {
        // First get spaces of this type using optimized service
        final spaces =
            await OptimizedDataService.getSpacesByCategory(spaceType);
        debugPrint('Retrieved ${spaces.length} spaces for type $spaceType');

        // Track processed event IDs to avoid duplicates
        final Set<String> processedEventIds = {};
        final List<Event> allEvents = [];

        // Process more spaces (up to 20 spaces instead of 10)
        const int maxSpacesToProcess = 20;
        int processedSpaces = 0;

        // Collect futures for parallel processing
        final List<Future<List<Event>>> eventsFutures = [];

        for (final space in spaces) {
          if (processedSpaces >= maxSpacesToProcess) break;

          // Skip spaces with no events
          if (space.eventIds.isEmpty) continue;

          processedSpaces++;

          debugPrint('Processing events for space ${space.id}');

          // Fetch events for this space with increased limit
          eventsFutures.add(OptimizedDataService.getEventsForSpace(
            space.id,
            limit: 10, // Increased from 5 to 10 for more complete data
          ));
        }

        // Wait for all futures to complete
        final results = await Future.wait(eventsFutures);

        // Flatten results but ensure no duplicates
        for (final events in results) {
          for (final event in events) {
            if (!processedEventIds.contains(event.id)) {
              processedEventIds.add(event.id);
              allEvents.add(event);
            }
          }
        }

        // Don't exceed the requested limit
        final limitedEvents =
            allEvents.length > limit ? allEvents.sublist(0, limit) : allEvents;

        // Apply filters
        List<Event> filteredEvents = limitedEvents;

        if (startDate != null) {
          filteredEvents = filteredEvents
              .where((event) => event.startDate.isAfter(startDate))
              .toList();
        }

        if (endDate != null) {
          filteredEvents = filteredEvents
              .where((event) => event.endDate.isBefore(endDate))
              .toList();
        }

        if (category != null && category.isNotEmpty) {
          filteredEvents = filteredEvents
              .where((event) => event.category == category)
              .toList();
        }

        // Sort by start date (most recent first)
        filteredEvents.sort((a, b) => a.startDate.compareTo(b.startDate));

        // Cache the results
        _eventsCache[cacheKey] = filteredEvents;
        _cacheTimestamps[cacheKey] = DateTime.now();

        debugPrint(
            'Retrieved ${filteredEvents.length} events for $spaceType using optimized service');
        return filteredEvents;
      } catch (e) {
        debugPrint(
            'Error using optimized service for $spaceType events, falling back: $e');
      }

      // Fall back to traditional approach if optimized approach fails
      debugPrint(
          'Fetching events for space type $spaceType using traditional approach');

      final List<Event> events = [];

      // First, get all spaces of this type using the interceptor
      final spacesSnapshot = await _firestore
          .collection('spaces')
          .doc(spaceType)
          .collection('spaces')
          .limit(20) // Increased from 15 to 20 for more complete data
          .getWithInterception();

      if (spacesSnapshot.docs.isEmpty) {
        debugPrint('No spaces found for type: $spaceType');
        return [];
      }

      debugPrint(
          'Found ${spacesSnapshot.docs.length} spaces of type $spaceType');

      // Prepare batch of queries for all spaces to reduce reads
      final List<Future<QuerySnapshot<Map<String, dynamic>>>> eventQueries = [];

      // For each space, build a query for its events
      for (final spaceDoc in spacesSnapshot.docs) {
        final spaceId = spaceDoc.id;

        // Build the query for events
        Query<Map<String, dynamic>> eventsQuery = _firestore
            .collection('spaces')
            .doc(spaceType)
            .collection('spaces')
            .doc(spaceId)
            .collection('events')
            .orderBy('startDate');

        // Apply date filters if provided
        if (startDate != null) {
          eventsQuery = eventsQuery.where('startDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
        }

        if (endDate != null) {
          eventsQuery = eventsQuery.where('endDate',
              isLessThanOrEqualTo: Timestamp.fromDate(endDate));
        }

        // Apply category filter if provided
        if (category != null && category.isNotEmpty) {
          eventsQuery = eventsQuery.where('category', isEqualTo: category);
        }

        // Apply pagination
        if (startAfter != null) {
          eventsQuery = eventsQuery.startAfterDocument(startAfter);
        }

        // Limit results - ensure limit is at least 10 per space (increased from 5)
        int perSpaceLimit = max(10, limit ~/ spacesSnapshot.docs.length);
        eventsQuery = eventsQuery.limit(perSpaceLimit);

        // Add to batch using interceptor
        eventQueries.add(eventsQuery.getWithInterception());
      }

      // Execute all queries in parallel
      final queryResults = await Future.wait(eventQueries);

      // Process the results
      for (int i = 0; i < queryResults.length; i++) {
        final eventsSnapshot = queryResults[i];
        final spaceId = spacesSnapshot.docs[i].id;

        if (eventsSnapshot.docs.isNotEmpty) {
          debugPrint(
              'Found ${eventsSnapshot.docs.length} events for space $spaceId');

          // Parse events
          for (final eventDoc in eventsSnapshot.docs) {
            try {
              final eventData = eventDoc.data();
              final processedData = _processTimestamps(eventData);
              final event = Event.fromJson(processedData);
              events.add(event);
            } catch (e) {
              debugPrint('Error parsing event from space $spaceId: $e');
            }
          }
        }
      }

      // Cache the results
      _eventsCache[cacheKey] = events;
      _cacheTimestamps[cacheKey] = DateTime.now();

      return events;
    } catch (e) {
      debugPrint('Error fetching events for space type $spaceType: $e');
      return [];
    }
  }

  /// Process Firestore data to handle Timestamps
  static Map<String, dynamic> _processTimestamps(Map<String, dynamic> data) {
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

  /// Clears the event cache
  static void clearCache() {
    _eventsCache.clear();
    _cacheTimestamps.clear();
    debugPrint('SpaceEventManager cache cleared');
  }

  /// Gets a specific event by ID from any space
  /// This method searches across all space types and spaces
  static Future<Event?> getEventById(String eventId) async {
    try {
      debugPrint('Finding event $eventId in any space...');
      final spaceTypes = getAllSpaceTypes();

      for (final spaceType in spaceTypes) {
        // Get all spaces for this type
        final spacesSnapshot = await _firestore
            .collection('spaces')
            .doc(spaceType)
            .collection('spaces')
            .get();

        for (final spaceDoc in spacesSnapshot.docs) {
          final spaceId = spaceDoc.id;

          // Check if this space has the event
          final eventDoc = await _firestore
              .collection('spaces')
              .doc(spaceType)
              .collection('spaces')
              .doc(spaceId)
              .collection('events')
              .doc(eventId)
              .get();

          if (eventDoc.exists) {
            debugPrint(
                'Found event $eventId in space $spaceId (type: $spaceType)');
            return Event.fromJson(eventDoc.data() as Map<String, dynamic>);
          }
        }
      }

      // Check if the event is in the lost_events collection
      final lostEventDoc =
          await _firestore.collection('lost_events').doc(eventId).get();

      if (lostEventDoc.exists) {
        debugPrint('Found event $eventId in lost_events collection');
        return Event.fromJson(lostEventDoc.data() as Map<String, dynamic>);
      }

      debugPrint('Event $eventId not found in any space or lost_events');
      return null;
    } catch (e) {
      debugPrint('Error getting event by ID: $e');
      return null;
    }
  }

  /// Fetches events from the lost_events collection
  /// @param limit Maximum number of events to fetch
  /// @param startDate Optional start date filter
  /// @param endDate Optional end date filter
  /// @param category Optional category filter
  static Future<List<Event>> getLostEvents({
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  }) async {
    try {
      debugPrint('Fetching events from lost_events collection');
      final List<Event> events = [];

      // Build the query for lost events
      Query eventsQuery =
          _firestore.collection('lost_events').orderBy('startDate');

      // Apply date filters if provided
      if (startDate != null) {
        eventsQuery = eventsQuery.where('startDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        eventsQuery = eventsQuery.where('endDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      // Apply category filter if provided
      if (category != null && category.isNotEmpty) {
        eventsQuery = eventsQuery.where('category', isEqualTo: category);
      }

      // Limit results
      eventsQuery = eventsQuery.limit(limit);

      // Execute the query
      final eventsSnapshot = await eventsQuery.get();

      if (eventsSnapshot.docs.isNotEmpty) {
        debugPrint(
            'Found ${eventsSnapshot.docs.length} events in lost_events collection');

        // Parse events
        for (final eventDoc in eventsSnapshot.docs) {
          try {
            final eventData = eventDoc.data() as Map<String, dynamic>;
            final event = Event.fromJson(eventData);
            events.add(event);
          } catch (e) {
            debugPrint('Error parsing event from lost_events: $e');
          }
        }
      } else {
        debugPrint('No events found in lost_events collection');
      }

      return events;
    } catch (e) {
      debugPrint('Error fetching lost events: $e');
      return [];
    }
  }

  /// Saves an event to the lost_events collection
  /// Used for events that don't match any space
  static Future<bool> saveLostEvent(Event event) async {
    try {
      // Reference to the event document in lost_events collection
      final eventRef = _firestore.collection('lost_events').doc(event.id);

      // Convert event to data
      final eventData = event.toJson();
      eventData['last_modified'] = FieldValue.serverTimestamp();
      eventData['source'] = event.source.toString();

      // Set the event data with merge: true to preserve existing fields
      await eventRef.set(eventData, SetOptions(merge: true));

      debugPrint('Successfully added/updated event ${event.id} to lost_events');
      return true;
    } catch (e) {
      debugPrint('Error adding/updating event ${event.id} to lost_events: $e');
      return false;
    }
  }

  /// Syncs events from a source (like RSS) to the appropriate spaces
  /// This preserves existing event data and only updates what's changed
  static Future<int> syncEventsToSpaces(List<Event> events) async {
    try {
      int successCount = 0;
      int lostCount = 0;
      int spacesCreated = 0;
      int spacesReused = 0;

      for (final event in events) {
        try {
          // Skip if organizer name is empty
          if (event.organizerName.isEmpty) {
            // Save to lost_events
            final success = await saveLostEvent(event);
            if (success) lostCount++;
            continue;
          }

          // First, check if a space already exists for this organizer in any collection
          final existingSpace =
              await findExistingSpaceByOrganizerName(event.organizerName);

          DocumentReference spaceRef;
          SpaceType spaceType;
          String typeCollection;
          String spaceId;

          if (existingSpace != null) {
            // Use existing space instead of creating a new one
            spaceRef = existingSpace['ref'] as DocumentReference;
            typeCollection = existingSpace['type'] as String;
            spaceId = existingSpace['id'] as String;
            spaceType = spaceTypeFromCollection(typeCollection);

            debugPrint(
                'Using existing space in type $typeCollection for event: ${event.id}');
            spacesReused++;
          } else {
            // No existing space found, determine space type and create a new one
            // Determine the space ID from organizer name
            spaceId = _generateSpaceId(event.organizerName);

            // Determine the space type
            spaceType = SpaceCategorizer.categorizeFromEvent(event);
            typeCollection = getTypeCollectionString(spaceType);

            // Check if space exists in the specific type collection
            spaceRef = _firestore
                .collection('spaces')
                .doc(typeCollection)
                .collection('spaces')
                .doc(spaceId);

            final spaceDoc = await spaceRef.get();

            if (!spaceDoc.exists) {
              // Space doesn't exist, create it first with basic information
              debugPrint(
                  'Creating new space $spaceId for event organization ${event.organizerName}');

              try {
                // Create space with all standard fields
                await createNewSpace(
                    spaceId: spaceId,
                    typeCollection: typeCollection,
                    organizerName: event.organizerName,
                    description: 'Auto-created from event sync',
                    source: 'rss_sync');

                debugPrint('Successfully created space $spaceId');
                spacesCreated++;
              } catch (e) {
                debugPrint('Error creating space $spaceId: $e');

                // Save to lost_events collection
                final success = await saveLostEvent(event);
                if (success) lostCount++;

                continue;
              }
            }
          }

          // Add/update the event
          final success = await addOrUpdateEvent(
            event: event,
            spaceId: spaceId,
            spaceType: spaceType,
          );

          if (success) {
            // Update the space's eventIds array to include this event
            await spaceRef.update({
              'eventIds': FieldValue.arrayUnion([event.id]),
              'updated_at': FieldValue.serverTimestamp(),
            });

            successCount++;
          }
        } catch (e) {
          debugPrint('Error syncing event ${event.id}: $e');

          // Try to save to lost_events as fallback
          try {
            final success = await saveLostEvent(event);
            if (success) {
              lostCount++;
              debugPrint('Saved event ${event.id} as lost event after error');
            }
          } catch (savingError) {
            debugPrint('Failed to save as lost event: $savingError');
          }
        }
      }

      debugPrint(
          'Synced $successCount events to spaces, $lostCount events to lost_events');
      debugPrint(
          'Created $spacesCreated new spaces, reused $spacesReused existing spaces');
      return successCount + lostCount;
    } catch (e) {
      debugPrint('Error in syncEventsToSpaces: $e');
      return 0;
    }
  }

  /// Generate a space ID from organizer name
  static String _generateSpaceId(String organizerName) {
    // Normalize the name (lowercase, remove special chars)
    final normalized = organizerName
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');

    return 'space_$normalized';
  }

  /// Convert a space type collection string to SpaceType enum
  static SpaceType spaceTypeFromCollection(String typeCollection) {
    switch (typeCollection) {
      case 'student_organizations':
        return SpaceType.studentOrg;
      case 'university_organizations':
        return SpaceType.universityOrg;
      case 'campus_living':
        return SpaceType.campusLiving;
      case 'fraternity_and_sorority':
        return SpaceType.fraternityAndSorority;
      case 'other':
      default:
        return SpaceType.other;
    }
  }

  /// Find an existing space by organizer name across all space types
  /// Returns a map with space information if found, null otherwise
  static Future<Map<String, dynamic>?> findExistingSpaceByOrganizerName(
      String organizerName) async {
    try {
      debugPrint('Finding existing space for organizer: $organizerName');

      // Generate the space ID from organizer name
      final spaceId = _generateSpaceId(organizerName);

      // Check all space types
      final spaceTypes = getAllSpaceTypes();

      for (final spaceType in spaceTypes) {
        final spaceRef = _firestore
            .collection('spaces')
            .doc(spaceType)
            .collection('spaces')
            .doc(spaceId);

        final spaceDoc = await spaceRef.get();

        if (spaceDoc.exists) {
          debugPrint('Found existing space in type: $spaceType, id: $spaceId');
          return {
            'id': spaceId,
            'type': spaceType,
            'data': spaceDoc.data(),
            'ref': spaceRef,
          };
        }
      }

      // Also check for exact name match in case the space ID generation differs
      for (final spaceType in spaceTypes) {
        final spacesQuery = await _firestore
            .collection('spaces')
            .doc(spaceType)
            .collection('spaces')
            .where('name', isEqualTo: organizerName)
            .limit(1)
            .get();

        if (spacesQuery.docs.isNotEmpty) {
          final doc = spacesQuery.docs.first;
          debugPrint(
              'Found existing space by name match: ${doc.id} in type: $spaceType');
          return {
            'id': doc.id,
            'type': spaceType,
            'data': doc.data(),
            'ref': doc.reference,
          };
        }
      }

      debugPrint('No existing space found for organizer: $organizerName');
      return null;
    } catch (e) {
      debugPrint('Error finding existing space for organizer: $e');
      return null;
    }
  }

  /// Create a new space with consistent fields
  static Future<DocumentReference> createNewSpace({
    required String spaceId,
    required String typeCollection,
    required String organizerName,
    String? description,
    String source = 'lost_event_migration',
  }) async {
    final spaceRef = _firestore
        .collection('spaces')
        .doc(typeCollection)
        .collection('spaces')
        .doc(spaceId);

    // Create basic space document with all required fields
    await spaceRef.set({
      'id': spaceId,
      'name': organizerName,
      'description': description ?? 'Auto-created from event sync',
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'type': typeCollection,
      'source': source,
      'organizer_name': organizerName,
      'icon': 'group', // Default icon
      'tags': [],
      'imageUrl': null,
      'bannerUrl': null,
      'customData': {},
      'isPrivate': false,
      'moderators': [],
      'admins': [],
      'quickActions': {},
      'relatedSpaceIds': [],
      'eventIds': [],
      'metrics': {
        'memberCount': 0,
        'activeMembers': 0,
        'weeklyEvents': 0,
        'monthlyEngagements': 0,
        'lastActivity': FieldValue.serverTimestamp(),
        'hasNewContent': false,
        'isTrending': false,
        'engagementScore': 0.0,
      },
    });

    return spaceRef;
  }

  /// Migrates all events from the lost_events collection to appropriate spaces
  /// Creates spaces for events if they don't exist
  static Future<Map<String, int>> migrateLostEventsToSpaces() async {
    try {
      debugPrint('\n=== Starting Lost Events Migration ===');

      final result = {
        'total': 0,
        'migrated': 0,
        'failed': 0,
        'spaces_created': 0,
        'spaces_reused': 0,
      };

      // Get all events from lost_events collection
      final lostEventsSnapshot =
          await _firestore.collection('lost_events').get();

      if (lostEventsSnapshot.docs.isEmpty) {
        debugPrint('No lost events found to migrate');
        return result;
      }

      result['total'] = lostEventsSnapshot.docs.length;
      debugPrint('Found ${result['total']} lost events to migrate');

      // Process each lost event
      for (final eventDoc in lostEventsSnapshot.docs) {
        try {
          final eventData = eventDoc.data();
          final event = Event.fromJson(eventData);

          // Skip events with empty organizer name
          if (event.organizerName.isEmpty) {
            debugPrint('Skipping event ${event.id} with empty organizer name');
            result['failed'] = (result['failed'] ?? 0) + 1;
            continue;
          }

          // Find existing space by organizer name
          final existingSpace =
              await findExistingSpaceByOrganizerName(event.organizerName);

          DocumentReference spaceRef;
          SpaceType spaceType;
          String typeCollection;
          String spaceId;

          if (existingSpace != null) {
            // Use existing space instead of creating a new one
            spaceRef = existingSpace['ref'] as DocumentReference;
            typeCollection = existingSpace['type'] as String;
            spaceId = existingSpace['id'] as String;
            spaceType = spaceTypeFromCollection(typeCollection);

            debugPrint(
                'Using existing space: $spaceId in type: $typeCollection');
            result['spaces_reused'] = (result['spaces_reused'] ?? 0) + 1;
          } else {
            // No existing space, create new one
            spaceType = SpaceCategorizer.categorizeFromEvent(event);
            typeCollection = getTypeCollectionString(spaceType);
            spaceId = _generateSpaceId(event.organizerName);

            debugPrint(
                'Creating new space for organizer: ${event.organizerName}');
            spaceRef = await createNewSpace(
              spaceId: spaceId,
              typeCollection: typeCollection,
              organizerName: event.organizerName,
            );

            result['spaces_created'] = (result['spaces_created'] ?? 0) + 1;
            debugPrint(
                'Successfully created space $spaceId in $typeCollection');
          }

          // Add the event to the space
          final success = await addOrUpdateEvent(
            event: event,
            spaceId: spaceId,
            spaceType: spaceType,
          );

          if (success) {
            // Delete the event from lost_events collection
            await _firestore.collection('lost_events').doc(event.id).delete();

            // Update the space's eventIds array
            await spaceRef.update({
              'eventIds': FieldValue.arrayUnion([event.id]),
              'updated_at': FieldValue.serverTimestamp(),
            });

            result['migrated'] = (result['migrated'] ?? 0) + 1;
            debugPrint(
                'Successfully migrated event ${event.id} to space $spaceId');
          } else {
            result['failed'] = (result['failed'] ?? 0) + 1;
            debugPrint('Failed to migrate event ${event.id}');
          }
        } catch (e) {
          result['failed'] = (result['failed'] ?? 0) + 1;
          debugPrint('Error processing lost event ${eventDoc.id}: $e');
        }
      }

      debugPrint('\n=== Lost Events Migration Summary ===');
      debugPrint('Total events: ${result['total']}');
      debugPrint('Successfully migrated: ${result['migrated']}');
      debugPrint('Failed to migrate: ${result['failed']}');
      debugPrint('New spaces created: ${result['spaces_created']}');
      debugPrint('Existing spaces reused: ${result['spaces_reused']}');

      return result;
    } catch (e) {
      debugPrint('Error in migrateLostEventsToSpaces: $e');
      return {
        'total': 0,
        'migrated': 0,
        'failed': 0,
        'spaces_created': 0,
        'spaces_reused': 0,
        'error': 1,
      };
    }
  }

  /// Gets events directly from the events collection
  /// @param limit Maximum number of events to fetch
  /// @param startDate Optional start date filter
  /// @param endDate Optional end date filter
  /// @param category Optional category filter
  /// @param spaceId Optional space ID filter
  static Future<List<Event>> getEventsDirectly({
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    String? spaceId,
  }) async {
    try {
      debugPrint('Fetching events directly from events collection');
      final cacheKey = 'direct_events_${spaceId ?? "all"}_${limit}_${startDate?.toString() ?? ""}_${category ?? ""}';
      
      // Check cache first
      if (_eventsCache.containsKey(cacheKey) &&
          _cacheTimestamps.containsKey(cacheKey) &&
          DateTime.now().difference(_cacheTimestamps[cacheKey]!) <
              _cacheDuration) {
        debugPrint('Using cached events for $cacheKey (${_eventsCache[cacheKey]!.length} events)');
        return _eventsCache[cacheKey]!;
      }
      
      // Set default startDate to now if not provided
      final effectiveStartDate = startDate ?? DateTime.now();
      
      // Build the query - use ISO string format for consistency
      final isoStartDate = effectiveStartDate.toIso8601String();
      
      // Build the query
      Query eventsQuery = _firestore
          .collection('events')
          .where('startDate', isGreaterThanOrEqualTo: isoStartDate)
          .orderBy('startDate');
      
      // Apply end date filter if specified
      if (endDate != null) {
        final isoEndDate = endDate.toIso8601String();
        eventsQuery = eventsQuery.where('endDate', isLessThanOrEqualTo: isoEndDate);
      }
      
      // Apply category filter if specified
      if (category != null && category.isNotEmpty) {
        eventsQuery = eventsQuery.where('category', isEqualTo: category);
      }
      
      // Apply space filter if specified
      if (spaceId != null && spaceId.isNotEmpty) {
        // Try to find by organizerName first (legacy approach)
        final space = await OptimizedDataService.getSpaceById(spaceId);
        if (space != null && space.name.isNotEmpty) {
          eventsQuery = eventsQuery.where('organizerName', isEqualTo: space.name);
        }
      }
      
      // Apply limit with a buffer to account for potential filtering
      eventsQuery = eventsQuery.limit(limit * 2);
      
      // Execute query
      final snapshot = await eventsQuery.get();
      
      // Record Firebase reads
      FirebaseMonitor.recordRead(count: snapshot.docs.length);
      
      // Process results
      final List<Event> events = [];
      for (final doc in snapshot.docs) {
        try {
          // Create ID-embedded data map
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id; // Ensure ID is included
          
          // Parse into Event object
          final event = Event.fromJson(data);
          events.add(event);
        } catch (e) {
          debugPrint('Error parsing event ${doc.id}: $e');
        }
      }
      
      // Sort by start date
      events.sort((a, b) => a.startDate.compareTo(b.startDate));
      
      // Limit to requested number
      final limitedEvents = events.length > limit ? events.sublist(0, limit) : events;
      
      // Cache the results
      _eventsCache[cacheKey] = limitedEvents;
      _cacheTimestamps[cacheKey] = DateTime.now();
      
      debugPrint('Retrieved ${limitedEvents.length} events directly from events collection');
      return limitedEvents;
    } catch (e) {
      debugPrint('Error fetching events directly: $e');
      return [];
    }
  }
}
