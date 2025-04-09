import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import 'package:hive_ui/models/space.dart';
import 'package:hive_ui/models/club.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/models/space_type.dart';
import 'package:hive_ui/services/firebase_monitor.dart';

/// Centralized cache service to eliminate redundant Firestore reads
class OptimizedDataService {
  // Firestore reference
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Memory cache for all entities
  static final Map<String, Space> _spaceCache = {};
  static final Map<String, Event> _eventCache = {};
  static final Map<String, List<Event>> _spaceEventsCache = {};
  static final Map<String, List<Space>> _spacesByCategoryCache = {};

  // Cache control
  static final Map<String, DateTime> _cacheTimes = {};
  static bool _isInitialized = false;
  static const Duration _longCacheDuration = Duration(hours: 6);
  static const Duration _shortCacheDuration =
      Duration(minutes: 60); // Extended from 15 to 60 minutes

  // Keys for persistent cache
  static const String _spacesKey = 'optimized_spaces_cache';
  static const String _eventsKey = 'optimized_events_cache';
  static const String _lastSyncKey = 'optimized_last_sync';

  // Pagination
  static const int _defaultPageSize =
      50; // Increased from 30 to 50 for faster loading
  static const int _batchSize = 30; // Batch size for parallel processing

  // Pending operations tracking
  static final Map<String, Future<dynamic>> _pendingOperations = {};

  // Request sequencing
  static int _requestCounter = 0;
  static final Map<String, int> _requestSequence = {};

  /// Initialize the service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    await _loadFromPersistentCache();
    _isInitialized = true;
    debugPrint(
        'OptimizedDataService initialized with ${_spaceCache.length} spaces and ${_eventCache.length} events');
  }

  /// Get all spaces with optimized caching
  static Future<List<Space>> getAllSpaces({bool forceRefresh = false}) async {
    const cacheKey = 'all_spaces';

    // Return from memory if cache is valid and not forced refresh
    if (!forceRefresh &&
        _cacheTimes.containsKey(cacheKey) &&
        DateTime.now().difference(_cacheTimes[cacheKey]!) <
            _shortCacheDuration &&
        _spaceCache.isNotEmpty) {
      debugPrint(
          'Returning all spaces from memory cache (${_spaceCache.length} spaces)');
      FirebaseMonitor.recordRead(count: _spaceCache.length, cached: true);
      return _spaceCache.values.toList();
    }

    // Check for pending operation to avoid duplicate calls
    if (_pendingOperations.containsKey(cacheKey)) {
      debugPrint('Reusing pending operation for all spaces');
      await _pendingOperations[cacheKey];
      FirebaseMonitor.recordRead(count: _spaceCache.length, cached: true);
      return _spaceCache.values.toList();
    }

    // Create operation and store it
    final operation = _fetchAllSpaces();
    _pendingOperations[cacheKey] = operation;

    try {
      final spaces = await operation;
      _cacheTimes[cacheKey] = DateTime.now();
      _pendingOperations.remove(cacheKey);
      return spaces;
    } catch (e) {
      _pendingOperations.remove(cacheKey);
      rethrow;
    }
  }

  /// Actual spaces fetch operation
  static Future<List<Space>> _fetchAllSpaces() async {
    try {
      debugPrint('Fetching all spaces from Firestore with optimized query');
      final List<Space> result = [];

      // Batch by space type for better efficiency
      final spaceTypes = [
        'student_organizations',
        'university_organizations',
        'campus_living',
        'fraternity_and_sorority',
        'other'
      ];

      // Process each space type separately to allow partial caching
      for (final spaceType in spaceTypes) {
        try {
          final spaceTypeDocs = await _firestore
              .collection('spaces')
              .doc(spaceType)
              .collection('spaces')
              .limit(100) // Increased from default
              .get();

          // Record Firebase reads
          FirebaseMonitor.recordRead(count: spaceTypeDocs.docs.length);

          debugPrint(
              'Retrieved ${spaceTypeDocs.docs.length} spaces from $spaceType');

          for (final doc in spaceTypeDocs.docs) {
            try {
              final data = doc.data();

              // Process the data to handle Timestamps
              final processedData = _processFirestoreData(data);

              final space = Space.fromJson(processedData);

              // Update cache
              _spaceCache[space.id] = space;
              result.add(space);
            } catch (e) {
              debugPrint('Error processing space document: $e');
            }
          }
        } catch (e) {
          debugPrint('Error fetching spaces for type $spaceType: $e');
        }
      }

      // Also check for legacy spaces at root level
      try {
        final legacyDocs =
            await _firestore.collection('spaces').limit(30).get();

        // Record Firebase reads
        FirebaseMonitor.recordRead(count: legacyDocs.docs.length);

        for (final doc in legacyDocs.docs) {
          try {
            if (!doc.id.contains('_')) {
              // Skip type documents
              final data = doc.data();
              final processedData = _processFirestoreData(data);
              final space = Space.fromJson(processedData);

              // Only add if not already in cache
              if (!_spaceCache.containsKey(space.id)) {
                _spaceCache[space.id] = space;
                result.add(space);
              }
            }
          } catch (e) {
            debugPrint('Error processing legacy space: $e');
          }
        }
      } catch (e) {
        debugPrint('Error fetching legacy spaces: $e');
      }

      // Save to persistent cache
      if (result.isNotEmpty) {
        _saveToPersistentCache();
      }

      debugPrint('Fetched total of ${result.length} spaces');
      return result;
    } catch (e) {
      debugPrint('Error fetching spaces: $e');
      // Return cached data as fallback
      final cachedSpaces = _spaceCache.values.toList();
      debugPrint('Returning ${cachedSpaces.length} spaces from fallback cache');
      FirebaseMonitor.recordRead(count: cachedSpaces.length, cached: true);
      return cachedSpaces;
    }
  }

  /// Process Firestore data to handle Timestamps
  static Map<String, dynamic> _processFirestoreData(Map<String, dynamic> data) {
    final result = <String, dynamic>{};

    // Process each field
    data.forEach((key, value) {
      if (value is Timestamp) {
        // Convert Timestamp to ISO string for serialization
        result[key] = value.toDate().toIso8601String();
      } else if (value is Map) {
        // Recursively process nested maps
        result[key] = _processFirestoreData(value.cast<String, dynamic>());
      } else if (value is List) {
        // Process lists
        result[key] = _processListData(value);
      } else {
        // Keep other values as is
        result[key] = value;
      }
    });

    return result;
  }

  /// Process list data to handle Timestamps in lists
  static List _processListData(List items) {
    return items.map((item) {
      if (item is Timestamp) {
        return item.toDate().toIso8601String();
      } else if (item is Map) {
        return _processFirestoreData(item.cast<String, dynamic>());
      } else if (item is List) {
        return _processListData(item);
      } else {
        return item;
      }
    }).toList();
  }

  /// Get spaces by category with optimized caching
  static Future<List<Space>> getSpacesByCategory(String category,
      {bool forceRefresh = false}) async {
    final cacheKey = 'spaces_category_$category';

    // Return from cache if valid and not forced refresh
    if (!forceRefresh &&
        _spacesByCategoryCache.containsKey(category) &&
        _cacheTimes.containsKey(cacheKey) &&
        DateTime.now().difference(_cacheTimes[cacheKey]!) <
            _shortCacheDuration) {
      debugPrint(
          'Returning ${_spacesByCategoryCache[category]?.length} spaces for category $category from memory cache');
      FirebaseMonitor.recordRead(
          count: _spacesByCategoryCache[category]?.length ?? 0, cached: true);
      return _spacesByCategoryCache[category] ?? [];
    }

    // Check for pending operation
    if (_pendingOperations.containsKey(cacheKey)) {
      debugPrint('Reusing pending operation for category $category');
      await _pendingOperations[cacheKey];
      FirebaseMonitor.recordRead(
          count: _spacesByCategoryCache[category]?.length ?? 0, cached: true);
      return _spacesByCategoryCache[category] ?? [];
    }

    // Create operation and store it
    final operation = _fetchSpacesByCategory(category);
    _pendingOperations[cacheKey] = operation;

    try {
      final spaces = await operation;
      _cacheTimes[cacheKey] = DateTime.now();
      _pendingOperations.remove(cacheKey);
      return spaces;
    } catch (e) {
      _pendingOperations.remove(cacheKey);
      rethrow;
    }
  }

  /// Actual category fetch operation
  static Future<List<Space>> _fetchSpacesByCategory(String category) async {
    try {
      // Optimize by checking if we have all spaces cached already
      if (_spaceCache.isNotEmpty) {
        // Try to derive from existing cache
        final spaces = _spaceCache.values
            .where((space) => _matchesCategory(space, category))
            .toList();

        if (spaces.isNotEmpty) {
          debugPrint(
              'Derived ${spaces.length} spaces for category $category from existing cache');
          _spacesByCategoryCache[category] = spaces;
          FirebaseMonitor.recordRead(count: spaces.length, cached: true);
          return spaces;
        }
      }

      // Fetch from Firestore with optimized query
      debugPrint('Fetching spaces for category $category from Firestore');

      // Convert category to SpaceType
      final spaceType = _getCategorySpaceType(category);

      // Use appropriate query path based on type
      final fieldPath = category.contains('_') ? 'spaceType' : 'tags';
      final fieldValue =
          category.contains('_') ? spaceType.toString() : category;

      // Execute optimized query
      final querySnapshot = await _firestore
          .collectionGroup('spaces')
          .where(fieldPath, isEqualTo: fieldValue)
          .limit(50)
          .get();

      // Record Firebase reads
      FirebaseMonitor.recordRead(count: querySnapshot.docs.length);

      debugPrint(
          'Retrieved ${querySnapshot.docs.length} spaces for category $category');

      final List<Space> spaces = [];

      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          final processedData = _processFirestoreData(data);
          final space = Space.fromJson(processedData);

          // Update cache
          _spaceCache[space.id] = space;
          spaces.add(space);
        } catch (e) {
          debugPrint('Error processing space document: $e');
        }
      }

      // Update category cache
      _spacesByCategoryCache[category] = spaces;

      // Save to persistent cache if significant data
      if (spaces.length > 10) {
        _saveToPersistentCache();
      }

      return spaces;
    } catch (e) {
      debugPrint('Error fetching spaces by category: $e');
      // Return whatever we have in cache as fallback
      final cachedSpaces = _spacesByCategoryCache[category] ?? [];
      FirebaseMonitor.recordRead(count: cachedSpaces.length, cached: true);
      return cachedSpaces;
    }
  }

  /// Get all events for a specific space
  static Future<List<Event>> getEventsForSpace(String spaceId,
      {int limit = 20}) async {
    // Check if the space exists in cache
    if (!_spaceCache.containsKey(spaceId)) {
      // Try to fetch the space first
      final space = await getSpaceById(spaceId);
      if (space == null) {
        debugPrint('Space $spaceId not found');
        return [];
      }
    }

    final space = _spaceCache[spaceId]!;
    final cacheKey = 'events_for_space_$spaceId';

    // Check memory cache first
    if (_spaceEventsCache.containsKey(cacheKey) &&
        _cacheTimes.containsKey(cacheKey) &&
        DateTime.now().difference(_cacheTimes[cacheKey]!) <
            _shortCacheDuration) {
      // Return events from cache, limiting to requested number
      final events = _spaceEventsCache[cacheKey]!;
      final limitedEvents =
          events.length > limit ? events.sublist(0, limit) : events;
      debugPrint(
          'Returning ${limitedEvents.length} events for space $spaceId from memory cache');
      FirebaseMonitor.recordRead(count: limitedEvents.length, cached: true);
      return limitedEvents;
    }

    // Check for pending operation
    if (_pendingOperations.containsKey(cacheKey)) {
      await _pendingOperations[cacheKey];
      final events = _spaceEventsCache[cacheKey]!;
      final limitedEvents =
          events.length > limit ? events.sublist(0, limit) : events;
      debugPrint(
          'Returning ${limitedEvents.length} events for space $spaceId from completed operation');
      FirebaseMonitor.recordRead(count: limitedEvents.length, cached: true);
      return limitedEvents;
    }

    // Start operation
    final operation = _fetchEventsForSpace(spaceId, limit: limit);
    _pendingOperations[cacheKey] = operation;

    try {
      final events = await operation;
      _pendingOperations.remove(cacheKey);
      return events;
    } catch (e) {
      _pendingOperations.remove(cacheKey);
      rethrow;
    }
  }

  /// Actual event fetch operation for a space
  static Future<List<Event>> _fetchEventsForSpace(String spaceId,
      {int limit = 20}) async {
    try {
      final space = _spaceCache[spaceId]!;
      final cacheKey = 'events_for_space_$spaceId';
      final List<Event> results = [];

      debugPrint('Fetching events for space $spaceId (${space.name})');

      // If the space has eventIds, use them for efficient batch fetching
      if (space.eventIds.isNotEmpty) {
        // Take more event IDs to ensure we get enough data
        final eventIds =
            space.eventIds.take(min(limit * 2, space.eventIds.length)).toList();
        debugPrint(
            'Space has ${eventIds.length} event IDs (out of ${space.eventIds.length} total)');

        // Check which events we already have in cache
        final List<String> idsToFetch = [];

        for (final id in eventIds) {
          if (_eventCache.containsKey(id)) {
            results.add(_eventCache[id]!);
          } else {
            idsToFetch.add(id);
          }
        }

        // If we have enough cached results, return early
        if (results.length >= limit && idsToFetch.isEmpty) {
          debugPrint(
              'Using ${results.length} cached events for space $spaceId');
          _spaceEventsCache[cacheKey] = results;
          _cacheTimes[cacheKey] = DateTime.now();
          FirebaseMonitor.recordRead(count: results.length, cached: true);

          // Sort by start date
          results.sort((a, b) => a.startDate.compareTo(b.startDate));
          return results.take(limit).toList();
        }

        // If we need to fetch more events, use whereIn batches of up to 10
        // to avoid Firestore limitations
        if (idsToFetch.isNotEmpty) {
          debugPrint(
              'Fetching ${idsToFetch.length} uncached events for space $spaceId');

          // Process in batches
          const batchSize = 10; // Firestore limitation for whereIn
          final fetchBatches = <List<String>>[];

          for (int i = 0; i < idsToFetch.length; i += batchSize) {
            final end = (i + batchSize < idsToFetch.length)
                ? i + batchSize
                : idsToFetch.length;
            fetchBatches.add(idsToFetch.sublist(i, end));
          }

          // Process all batches in parallel for better performance
          final List<Future<List<Event>>> batchFutures = [];

          for (final batch in fetchBatches) {
            batchFutures.add(_fetchEventsBatch(batch));
          }

          // Wait for all fetches to complete
          final batchResults = await Future.wait(batchFutures);

          // Combine results
          for (final events in batchResults) {
            results.addAll(events);
          }
        }
      } else {
        // Space doesn't have eventIds, we need to query by organizer name
        debugPrint(
            'No event IDs for space $spaceId, querying by organizer name: ${space.name}');

        if (space.name.isEmpty) {
          debugPrint('Space has no name to query by');
          _spaceEventsCache[cacheKey] = [];
          _cacheTimes[cacheKey] = DateTime.now();
          return [];
        }

        // Query directly from events collection
        final querySnapshot = await _firestore
            .collection('events')
            .where('organizerName', isEqualTo: space.name)
            .limit(limit * 2) // Double the limit for more complete data
            .get();

        // Record Firebase reads
        FirebaseMonitor.recordRead(count: querySnapshot.docs.length);

        for (final doc in querySnapshot.docs) {
          try {
            final data = doc.data();
            final processedData = _processFirestoreData(data);
            final event = Event.fromJson(processedData);

            // Only add if not already in results
            if (!results.any((e) => e.id == event.id)) {
              results.add(event);
              _eventCache[event.id] = event;
            }
          } catch (e) {
            debugPrint('Error processing event document: $e');
          }
        }
      }

      // Sort by start date
      results.sort((a, b) => a.startDate.compareTo(b.startDate));

      // Cache the results
      _spaceEventsCache[cacheKey] = results;
      _cacheTimes[cacheKey] = DateTime.now();

      // Limit to requested number
      final limitedResults =
          results.length > limit ? results.sublist(0, limit) : results;

      debugPrint('Fetched ${limitedResults.length} events for space $spaceId');
      return limitedResults;
    } catch (e) {
      debugPrint('Error fetching events for space $spaceId: $e');
      return [];
    }
  }

  /// Helper method to fetch a batch of events by ID
  static Future<List<Event>> _fetchEventsBatch(List<String> eventIds) async {
    if (eventIds.isEmpty) return [];

    try {
      final List<Event> batchResults = [];

      final querySnapshot = await _firestore
          .collection('events')
          .where(FieldPath.documentId, whereIn: eventIds)
          .get();

      // Record Firebase reads
      FirebaseMonitor.recordRead(count: querySnapshot.docs.length);

      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          final processedData = _processFirestoreData(data);
          final event = Event.fromJson(processedData);

          // Update cache
          _eventCache[event.id] = event;
          batchResults.add(event);
        } catch (e) {
          debugPrint('Error processing event document in batch: $e');
        }
      }

      return batchResults;
    } catch (e) {
      debugPrint('Error fetching event batch: $e');
      return [];
    }
  }

  /// Load from persistent cache
  static Future<void> _loadFromPersistentCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load spaces
      final spacesJson = prefs.getString(_spacesKey);
      if (spacesJson != null) {
        try {
          final List<dynamic> spacesList = jsonDecode(spacesJson);

          for (final spaceData in spacesList) {
            if (spaceData is Map<String, dynamic>) {
              try {
                final space = Space.fromJson(spaceData);
                _spaceCache[space.id] = space;
              } catch (e) {
                debugPrint('Error parsing space from cache: $e');
              }
            }
          }

          debugPrint(
              'Loaded ${_spaceCache.length} spaces from persistent cache');
        } catch (e) {
          debugPrint('Error parsing spaces JSON: $e');
        }
      }

      // Load events
      final eventsJson = prefs.getString(_eventsKey);
      if (eventsJson != null) {
        try {
          final List<dynamic> eventsList = jsonDecode(eventsJson);

          for (final eventData in eventsList) {
            if (eventData is Map<String, dynamic>) {
              try {
                final event = Event.fromJson(eventData);
                _eventCache[event.id] = event;
              } catch (e) {
                debugPrint('Error parsing event from cache: $e');
              }
            }
          }

          debugPrint(
              'Loaded ${_eventCache.length} events from persistent cache');
        } catch (e) {
          debugPrint('Error parsing events JSON: $e');
        }
      }

      // Check cache timestamp
      final lastSync = prefs.getInt(_lastSyncKey);
      if (lastSync != null) {
        final lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSync);
        final difference = DateTime.now().difference(lastSyncTime);

        if (difference.inHours < 24) {
          // Cache is recent enough
          for (final key in _cacheTimes.keys) {
            _cacheTimes[key] = lastSyncTime;
          }
          debugPrint('Cache is ${difference.inHours} hours old');
        } else {
          debugPrint(
              'Cache is too old (${difference.inHours} hours), forcing refresh');
        }
      }
    } catch (e) {
      debugPrint('Error loading from persistent cache: $e');
    }
  }

  /// Save to persistent cache
  static Future<void> _saveToPersistentCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Only save if we have significant data
      if (_spaceCache.length > 5) {
        // Save spaces (limited to 500 to avoid memory issues)
        final spaces = _spaceCache.values.take(500).toList();

        // Convert to JSON-safe format
        final spacesJsonData = spaces.map((space) => space.toJson()).toList();
        final spacesJson = jsonEncode(spacesJsonData);
        await prefs.setString(_spacesKey, spacesJson);
      }

      // Only save if we have significant data
      if (_eventCache.length > 5) {
        // Save events (limited to 500 to avoid memory issues)
        final events = _eventCache.values.take(500).toList();

        // Convert to JSON-safe format
        final eventsJsonData = events.map((event) => event.toMap()).toList();
        final eventsJson = jsonEncode(eventsJsonData);
        await prefs.setString(_eventsKey, eventsJson);
      }

      // Update last sync timestamp
      await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);

      debugPrint(
          'Saved ${_spaceCache.length} spaces and ${_eventCache.length} events to persistent cache');
    } catch (e) {
      debugPrint('Error saving to persistent cache: $e');
    }
  }

  /// Clear all caches (for testing or logout)
  static Future<void> clearCache() async {
    _spaceCache.clear();
    _eventCache.clear();
    _spaceEventsCache.clear();
    _spacesByCategoryCache.clear();
    _cacheTimes.clear();
    _pendingOperations.clear();
    _requestSequence.clear();
    _requestCounter = 0;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_spacesKey);
      await prefs.remove(_eventsKey);
      await prefs.remove(_lastSyncKey);
    } catch (e) {
      debugPrint('Error clearing persistent cache: $e');
    }

    debugPrint('All caches cleared');
  }

  /// Helper to check if a space matches a category
  static bool _matchesCategory(Space space, String category) {
    if (category.contains('_')) {
      // It's a space type
      final spaceType = _getCategorySpaceType(category);
      return space.spaceType == spaceType;
    } else {
      // It's a tag
      return space.tags.contains(category);
    }
  }

  /// Helper to convert a category string to a SpaceType
  static SpaceType _getCategorySpaceType(String category) {
    switch (category) {
      case 'student_organizations':
        return SpaceType.studentOrg;
      case 'university_organizations':
        return SpaceType.universityOrg;
      case 'fraternity_and_sorority':
        return SpaceType.fraternityAndSorority;
      case 'campus_living':
        return SpaceType.campusLiving;
      default:
        return SpaceType.other;
    }
  }

  /// Club compatibility method - get a club from a space
  static Club? getClubFromSpace(String spaceId) {
    final space = _spaceCache[spaceId];
    if (space == null) return null;

    return Club.fromSpace(space.toJson());
  }

  /// Get the currently cached spaces without making a network request
  static List<Space> getCachedSpaces() {
    FirebaseMonitor.recordRead(count: _spaceCache.length, cached: true);
    return _spaceCache.values.toList();
  }

  /// Get a space by ID with optimized caching
  static Future<Space?> getSpaceById(String spaceId,
      {bool forceRefresh = false}) async {
    // Check memory cache first
    if (!forceRefresh && _spaceCache.containsKey(spaceId)) {
      debugPrint('Returning space $spaceId from memory cache');
      FirebaseMonitor.recordRead(count: 1, cached: true);
      return _spaceCache[spaceId];
    }

    // Check for pending operation
    final cacheKey = 'space_$spaceId';
    if (_pendingOperations.containsKey(cacheKey)) {
      debugPrint('Reusing pending operation for space $spaceId');
      await _pendingOperations[cacheKey];
      if (_spaceCache.containsKey(spaceId)) {
        FirebaseMonitor.recordRead(count: 1, cached: true);
        return _spaceCache[spaceId];
      }
      return null;
    }

    // Create operation and store it
    final operation = _fetchSpaceById(spaceId);
    _pendingOperations[cacheKey] = operation;

    try {
      final space = await operation;
      _pendingOperations.remove(cacheKey);
      return space;
    } catch (e) {
      _pendingOperations.remove(cacheKey);
      rethrow;
    }
  }

  /// Actual space fetch operation
  static Future<Space?> _fetchSpaceById(String spaceId) async {
    try {
      // First try the spaces collection to find which type it belongs to
      final spaceTypes = [
        'student_organizations',
        'university_organizations',
        'campus_living',
        'fraternity_and_sorority',
        'other'
      ];

      // Try to find in each space type
      for (final type in spaceTypes) {
        try {
          final docRef = _firestore
              .collection('spaces')
              .doc(type)
              .collection('spaces')
              .doc(spaceId);
          final docSnapshot = await docRef.get();

          // Record Firebase reads
          FirebaseMonitor.recordRead(count: 1);

          if (docSnapshot.exists) {
            final data = docSnapshot.data()!;
            final processedData = _processFirestoreData(data);
            final space = Space.fromJson(processedData);

            // Update cache
            _spaceCache[space.id] = space;
            return space;
          }
        } catch (e) {
          debugPrint('Error checking space $spaceId in $type: $e');
        }
      }

      // Also check legacy spaces at root level
      try {
        final docRef = _firestore.collection('spaces').doc(spaceId);
        final docSnapshot = await docRef.get();

        // Record Firebase reads
        FirebaseMonitor.recordRead(count: 1);

        if (docSnapshot.exists) {
          final data = docSnapshot.data()!;
          final processedData = _processFirestoreData(data);
          final space = Space.fromJson(processedData);

          // Update cache
          _spaceCache[space.id] = space;
          return space;
        }
      } catch (e) {
        debugPrint('Error checking space $spaceId at root level: $e');
      }

      debugPrint('Space $spaceId not found in any collection');
      return null;
    } catch (e) {
      debugPrint('Error fetching space $spaceId: $e');
      return null;
    }
  }
}
