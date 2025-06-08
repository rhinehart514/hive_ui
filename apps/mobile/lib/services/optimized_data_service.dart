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
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

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
  
  // Offline sync related keys
  static const String _pendingChangesKey = 'optimized_pending_changes';
  static const String _lastOnlineKey = 'optimized_last_online';
  static const String _offlineModeKey = 'optimized_offline_mode';

  // Pagination
  static const int _defaultPageSize =
      50; // Increased from 30 to 50 for faster loading
  static const int _batchSize = 30; // Batch size for parallel processing

  // Pending operations tracking
  static final Map<String, Future<dynamic>> _pendingOperations = {};
  
  // Offline changes tracking
  static final Map<String, Map<String, dynamic>> _pendingChanges = {};
  static bool _offlineMode = false;
  static DateTime? _lastOnlineTime;

  // Request sequencing
  static int _requestCounter = 0;
  static final Map<String, int> _requestSequence = {};
  
  // Connectivity monitoring
  static StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  /// Check if we're in offline mode
  static bool get isOfflineMode => _offlineMode;
  
  /// Get timestamp of when we were last online
  static DateTime? get lastOnlineTime => _lastOnlineTime;

  /// Initialize the service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    await _loadFromPersistentCache();
    await _loadOfflineState();
    _startConnectivityMonitoring();
    _isInitialized = true;
    debugPrint(
        'OptimizedDataService initialized with ${_spaceCache.length} spaces and ${_eventCache.length} events, offline mode: $_offlineMode');
  }
  
  /// Load the offline state from persistent storage
  static Future<void> _loadOfflineState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load offline mode flag
      _offlineMode = prefs.getBool(_offlineModeKey) ?? false;
      
      // Load last online timestamp
      final lastOnlineMs = prefs.getInt(_lastOnlineKey);
      if (lastOnlineMs != null) {
        _lastOnlineTime = DateTime.fromMillisecondsSinceEpoch(lastOnlineMs);
      }
      
      // Load pending changes
      final pendingChangesJson = prefs.getString(_pendingChangesKey);
      if (pendingChangesJson != null) {
        final decoded = jsonDecode(pendingChangesJson) as Map<String, dynamic>;
        decoded.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            _pendingChanges[key] = value;
          }
        });
        debugPrint('Loaded ${_pendingChanges.length} pending changes from persistent storage');
      }
    } catch (e) {
      debugPrint('Error loading offline state: $e');
    }
  }
  
  /// Set the offline mode state
  static Future<void> setOfflineMode(bool enabled) async {
    if (_offlineMode == enabled) return;
    
    _offlineMode = enabled;
    
    if (!enabled) {
      // We're going online, update the last online time
      _lastOnlineTime = DateTime.now();
      
      // Trigger sync of pending changes
      await _syncPendingChanges();
    }
    
    // Persist the state
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_offlineModeKey, _offlineMode);
      
      if (_lastOnlineTime != null) {
        await prefs.setInt(_lastOnlineKey, _lastOnlineTime!.millisecondsSinceEpoch);
      }
    } catch (e) {
      debugPrint('Error saving offline mode state: $e');
    }
    
    debugPrint('Offline mode set to: $_offlineMode');
  }
  
  /// Track a change made while offline
  static Future<void> trackOfflineChange(String entityType, String entityId, Map<String, dynamic> change) async {
    final key = '$entityType:$entityId';
    
    // Store in memory
    if (!_pendingChanges.containsKey(key)) {
      _pendingChanges[key] = {};
    }
    
    // Merge with existing changes
    _pendingChanges[key]!.addAll(change);
    
    // Persist the changes
    await _savePendingChanges();
    
    debugPrint('Tracked offline change for $entityType:$entityId');
  }
  
  /// Check if an entity has pending offline changes
  static bool hasOfflineChanges(String entityType, String entityId) {
    final key = '$entityType:$entityId';
    return _pendingChanges.containsKey(key);
  }
  
  /// Get pending changes for an entity
  static Map<String, dynamic>? getOfflineChanges(String entityType, String entityId) {
    final key = '$entityType:$entityId';
    return _pendingChanges[key];
  }
  
  /// Apply offline changes to an entity
  static T applyOfflineChanges<T>(T entity, String entityType, String entityId) {
    if (!hasOfflineChanges(entityType, entityId)) {
      return entity;
    }
    
    final changes = getOfflineChanges(entityType, entityId);
    if (changes == null) {
      return entity;
    }
    
    // Handle different entity types
    if (entity is Space && entityType == 'space') {
      final spaceJson = (entity as Space).toJson();
      // Apply changes to the JSON
      spaceJson.addAll(changes);
      // Create a new entity with the changes
      return Space.fromJson(spaceJson) as T;
    } else if (entity is Event && entityType == 'event') {
      final eventJson = (entity as Event).toJson();
      // Apply changes to the JSON
      eventJson.addAll(changes);
      // Create a new entity with the changes
      return Event.fromJson(eventJson) as T;
    }
    
    // Default fallback if entity type isn't handled
    return entity;
  }
  
  /// Save pending changes to persistent storage
  static Future<void> _savePendingChanges() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(_pendingChanges);
      await prefs.setString(_pendingChangesKey, jsonData);
      debugPrint('Saved ${_pendingChanges.length} pending changes to persistent storage');
    } catch (e) {
      debugPrint('Error saving pending changes: $e');
    }
  }
  
  /// Sync pending changes when going online
  static Future<void> _syncPendingChanges() async {
    if (_pendingChanges.isEmpty) {
      debugPrint('No pending changes to sync');
      return;
    }
    
    debugPrint('Syncing ${_pendingChanges.length} pending changes');
    
    final changesList = List.of(_pendingChanges.entries);
    final failedChanges = <String, Map<String, dynamic>>{};
    
    for (final entry in changesList) {
      final key = entry.key;
      final changes = entry.value;
      
      // Parse the key (format: entityType:entityId)
      final parts = key.split(':');
      if (parts.length != 2) {
        debugPrint('Invalid change key format: $key');
        continue;
      }
      
      final entityType = parts[0];
      final entityId = parts[1];
      
      try {
        bool success = false;
        
        if (entityType == 'space') {
          success = await _syncSpaceChanges(entityId, changes);
        } else if (entityType == 'event') {
          success = await _syncEventChanges(entityId, changes);
        } else {
          debugPrint('Unsupported entity type for sync: $entityType');
        }
        
        if (success) {
          // Remove from pending changes
          _pendingChanges.remove(key);
          debugPrint('Successfully synced changes for $entityType:$entityId');
        } else {
          // Keep track of failed changes
          failedChanges[key] = changes;
          debugPrint('Failed to sync changes for $entityType:$entityId');
        }
      } catch (e) {
        // Keep track of failed changes
        failedChanges[key] = changes;
        debugPrint('Error syncing changes for $entityType:$entityId: $e');
      }
    }
    
    // Update pending changes with only the failed ones
    _pendingChanges.clear();
    _pendingChanges.addAll(failedChanges);
    
    // Save the updated pending changes
    await _savePendingChanges();
    
    debugPrint('Sync completed. ${failedChanges.length} changes failed to sync.');
  }
  
  /// Sync changes for a space entity
  static Future<bool> _syncSpaceChanges(String spaceId, Map<String, dynamic> changes) async {
    try {
      // Find the space collection
      final spaceTypes = [
        'student_organizations',
        'university_organizations',
        'campus_living',
        'fraternity_and_sorority',
        'other'
      ];
      
      // Try each space type to find where this space lives
      for (final type in spaceTypes) {
        final docRef = _firestore
            .collection('spaces')
            .doc(type)
            .collection('spaces')
            .doc(spaceId);
        
        final docSnapshot = await docRef.get();
        
        if (docSnapshot.exists) {
          // Update the document
          await docRef.update(changes);
          return true;
        }
      }
      
      // Also check legacy spaces at root level
      final legacyDocRef = _firestore.collection('spaces').doc(spaceId);
      final legacySnapshot = await legacyDocRef.get();
      
      if (legacySnapshot.exists) {
        await legacyDocRef.update(changes);
        return true;
      }
      
      debugPrint('Space $spaceId not found for syncing changes');
      return false;
    } catch (e) {
      debugPrint('Error syncing space changes: $e');
      return false;
    }
  }
  
  /// Sync changes for an event entity
  static Future<bool> _syncEventChanges(String eventId, Map<String, dynamic> changes) async {
    try {
      // Find the event document
      final docRef = _firestore.collection('events').doc(eventId);
      final docSnapshot = await docRef.get();
      
      if (docSnapshot.exists) {
        // Update the document
        await docRef.update(changes);
        return true;
      }
      
      debugPrint('Event $eventId not found for syncing changes');
      return false;
    } catch (e) {
      debugPrint('Error syncing event changes: $e');
      return false;
    }
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
      return _applyOfflineChangesToSpaces(_spaceCache.values.toList());
    }

    // If we're in offline mode, prioritize cache regardless of cache age
    if (_offlineMode && _spaceCache.isNotEmpty) {
      debugPrint(
          'Offline mode: Returning all spaces from memory cache (${_spaceCache.length} spaces)');
      FirebaseMonitor.recordRead(count: _spaceCache.length, cached: true);
      return _applyOfflineChangesToSpaces(_spaceCache.values.toList());
    }

    // Check for pending operation to avoid duplicate calls
    if (_pendingOperations.containsKey(cacheKey)) {
      debugPrint('Reusing pending operation for all spaces');
      await _pendingOperations[cacheKey];
      FirebaseMonitor.recordRead(count: _spaceCache.length, cached: true);
      return _applyOfflineChangesToSpaces(_spaceCache.values.toList());
    }

    // If we're in offline mode and have no cache, return empty list
    if (_offlineMode && _spaceCache.isEmpty) {
      debugPrint('Offline mode: No spaces in cache, returning empty list');
      return [];
    }

    // Create operation and store it
    final operation = _fetchAllSpaces();
    _pendingOperations[cacheKey] = operation;

    try {
      final spaces = await operation;
      _cacheTimes[cacheKey] = DateTime.now();
      _pendingOperations.remove(cacheKey);
      return _applyOfflineChangesToSpaces(spaces);
    } catch (e) {
      _pendingOperations.remove(cacheKey);
      if (_offlineMode) {
        // In offline mode, fall back to cache if fetch fails
        debugPrint('Fetch failed in offline mode, using cache fallback');
        return _applyOfflineChangesToSpaces(_spaceCache.values.toList());
      }
      rethrow;
    }
  }
  
  /// Apply any pending offline changes to a list of spaces
  static List<Space> _applyOfflineChangesToSpaces(List<Space> spaces) {
    if (_pendingChanges.isEmpty) {
      return spaces;
    }
    
    return spaces.map((space) {
      if (hasOfflineChanges('space', space.id)) {
        return applyOfflineChanges(space, 'space', space.id);
      }
      return space;
    }).toList();
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
      return _applyOfflineChangesToEvents(limitedEvents);
    }

    // If we're in offline mode, prioritize cache regardless of cache age
    if (_offlineMode && _spaceEventsCache.containsKey(cacheKey)) {
      final events = _spaceEventsCache[cacheKey]!;
      final limitedEvents =
          events.length > limit ? events.sublist(0, limit) : events;
      debugPrint(
          'Offline mode: Returning ${limitedEvents.length} events for space $spaceId from memory cache');
      FirebaseMonitor.recordRead(count: limitedEvents.length, cached: true);
      return _applyOfflineChangesToEvents(limitedEvents);
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
      return _applyOfflineChangesToEvents(limitedEvents);
    }

    // If we're in offline mode with no cache, return empty list
    if (_offlineMode && !_spaceEventsCache.containsKey(cacheKey)) {
      debugPrint('Offline mode: No events for space $spaceId in cache, returning empty list');
      return [];
    }

    // Start operation
    final operation = _fetchEventsForSpace(spaceId, limit: limit);
    _pendingOperations[cacheKey] = operation;

    try {
      final events = await operation;
      _pendingOperations.remove(cacheKey);
      return _applyOfflineChangesToEvents(events);
    } catch (e) {
      _pendingOperations.remove(cacheKey);
      
      if (_offlineMode && _spaceEventsCache.containsKey(cacheKey)) {
        // In offline mode, fall back to cache if fetch fails
        debugPrint('Fetch failed in offline mode, using cache for events of space $spaceId');
        final events = _spaceEventsCache[cacheKey]!;
        final limitedEvents =
            events.length > limit ? events.sublist(0, limit) : events;
        return _applyOfflineChangesToEvents(limitedEvents);
      }
      
      rethrow;
    }
  }
  
  /// Apply any pending offline changes to a list of events
  static List<Event> _applyOfflineChangesToEvents(List<Event> events) {
    if (_pendingChanges.isEmpty) {
      return events;
    }
    
    return events.map((event) {
      if (hasOfflineChanges('event', event.id)) {
        return applyOfflineChanges(event, 'event', event.id);
      }
      return event;
    }).toList();
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
      
      // Apply any offline changes
      if (hasOfflineChanges('space', spaceId)) {
        return applyOfflineChanges(_spaceCache[spaceId]!, 'space', spaceId);
      }
      
      return _spaceCache[spaceId];
    }

    // If we're in offline mode, prioritize cache regardless of refresh flag
    if (_offlineMode && _spaceCache.containsKey(spaceId)) {
      debugPrint('Offline mode: Returning space $spaceId from memory cache');
      FirebaseMonitor.recordRead(count: 1, cached: true);
      
      // Apply any offline changes
      if (hasOfflineChanges('space', spaceId)) {
        return applyOfflineChanges(_spaceCache[spaceId]!, 'space', spaceId);
      }
      
      return _spaceCache[spaceId];
    }

    // Check for pending operation
    final cacheKey = 'space_$spaceId';
    if (_pendingOperations.containsKey(cacheKey)) {
      debugPrint('Reusing pending operation for space $spaceId');
      await _pendingOperations[cacheKey];
      if (_spaceCache.containsKey(spaceId)) {
        FirebaseMonitor.recordRead(count: 1, cached: true);
        
        // Apply any offline changes
        if (hasOfflineChanges('space', spaceId)) {
          return applyOfflineChanges(_spaceCache[spaceId]!, 'space', spaceId);
        }
        
        return _spaceCache[spaceId];
      }
      return null;
    }

    // If we're in offline mode and the space is not in cache, return null
    if (_offlineMode && !_spaceCache.containsKey(spaceId)) {
      debugPrint('Offline mode: Space $spaceId not in cache, returning null');
      return null;
    }

    // Create operation and store it
    final operation = _fetchSpaceById(spaceId);
    _pendingOperations[cacheKey] = operation;

    try {
      final space = await operation;
      _pendingOperations.remove(cacheKey);
      
      // Apply any offline changes
      if (space != null && hasOfflineChanges('space', spaceId)) {
        return applyOfflineChanges(space, 'space', spaceId);
      }
      
      return space;
    } catch (e) {
      _pendingOperations.remove(cacheKey);
      
      if (_offlineMode && _spaceCache.containsKey(spaceId)) {
        // In offline mode, fall back to cache if fetch fails
        debugPrint('Fetch failed in offline mode, using cache for space $spaceId');
        
        // Apply any offline changes
        if (hasOfflineChanges('space', spaceId)) {
          return applyOfflineChanges(_spaceCache[spaceId]!, 'space', spaceId);
        }
        
        return _spaceCache[spaceId];
      }
      
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

  /// Update a space with optimistic updates handling offline mode
  static Future<bool> updateSpace(String spaceId, Map<String, dynamic> updates, {bool force = false}) async {
    // First check if space exists in cache
    if (!_spaceCache.containsKey(spaceId)) {
      // Try to get the space first
      final space = await getSpaceById(spaceId);
      if (space == null) {
        debugPrint('Cannot update space $spaceId - not found');
        return false;
      }
    }
    
    // If we're in offline mode or force offline update
    if (_offlineMode || force) {
      debugPrint('Updating space $spaceId locally (offline mode)');
      
      // Track the change for later sync
      await trackOfflineChange('space', spaceId, updates);
      
      // Update the space in memory cache
      final space = _spaceCache[spaceId]!;
      final spaceJson = space.toJson();
      
      // Apply updates to the space
      spaceJson.addAll(updates);
      
      // Create updated space
      final updatedSpace = Space.fromJson(spaceJson);
      
      // Update cache
      _spaceCache[spaceId] = updatedSpace;
      
      // Mark cache as updated
      _cacheTimes['space_$spaceId'] = DateTime.now();
      
      return true;
    }
    
    // Online mode - update directly in Firestore
    try {
      debugPrint('Updating space $spaceId in Firestore');
      
      // Find the space collection
      final spaceTypes = [
        'student_organizations',
        'university_organizations',
        'campus_living',
        'fraternity_and_sorority',
        'other'
      ];
      
      bool updated = false;
      
      // Try each space type to find where this space lives
      for (final type in spaceTypes) {
        try {
          final docRef = _firestore
              .collection('spaces')
              .doc(type)
              .collection('spaces')
              .doc(spaceId);
          
          final docSnapshot = await docRef.get();
          
          if (docSnapshot.exists) {
            // Update the document
            await docRef.update(updates);
            
            // Update the space in memory cache
            if (_spaceCache.containsKey(spaceId)) {
              final space = _spaceCache[spaceId]!;
              final spaceJson = space.toJson();
              
              // Apply updates to the space
              spaceJson.addAll(updates);
              
              // Create updated space
              final updatedSpace = Space.fromJson(spaceJson);
              
              // Update cache
              _spaceCache[spaceId] = updatedSpace;
              
              // Mark cache as updated
              _cacheTimes['space_$spaceId'] = DateTime.now();
            }
            
            updated = true;
            break;
          }
        } catch (e) {
          debugPrint('Error updating space in $type: $e');
        }
      }
      
      // Also check legacy spaces at root level if not updated yet
      if (!updated) {
        try {
          final legacyDocRef = _firestore.collection('spaces').doc(spaceId);
          final legacySnapshot = await legacyDocRef.get();
          
          if (legacySnapshot.exists) {
            await legacyDocRef.update(updates);
            
            // Update the space in memory cache
            if (_spaceCache.containsKey(spaceId)) {
              final space = _spaceCache[spaceId]!;
              final spaceJson = space.toJson();
              
              // Apply updates to the space
              spaceJson.addAll(updates);
              
              // Create updated space
              final updatedSpace = Space.fromJson(spaceJson);
              
              // Update cache
              _spaceCache[spaceId] = updatedSpace;
              
              // Mark cache as updated
              _cacheTimes['space_$spaceId'] = DateTime.now();
            }
            
            updated = true;
          }
        } catch (e) {
          debugPrint('Error updating legacy space: $e');
        }
      }
      
      return updated;
    } catch (e) {
      debugPrint('Error updating space: $e');
      
      // If failed due to network error, do offline update
      if (e.toString().contains('network') || e.toString().contains('connection')) {
        debugPrint('Network error, falling back to offline update');
        return updateSpace(spaceId, updates, force: true);
      }
      
      return false;
    }
  }

  /// Update an event with optimistic updates handling offline mode
  static Future<bool> updateEvent(String eventId, Map<String, dynamic> updates, {bool force = false}) async {
    // First check if event exists in cache
    if (!_eventCache.containsKey(eventId)) {
      // Event not in cache, try to fetch it
      try {
        if (_offlineMode) {
          // Can't fetch in offline mode
          debugPrint('Cannot update event $eventId - not in cache and offline');
          return false;
        }
        
        final docRef = _firestore.collection('events').doc(eventId);
        final docSnapshot = await docRef.get();
        
        if (!docSnapshot.exists) {
          debugPrint('Cannot update event $eventId - not found in Firestore');
          return false;
        }
        
        // Add to cache
        final data = docSnapshot.data()!;
        final processedData = _processFirestoreData(data);
        final event = Event.fromJson(processedData);
        _eventCache[eventId] = event;
      } catch (e) {
        debugPrint('Error fetching event $eventId: $e');
        return false;
      }
    }
    
    // If we're in offline mode or force offline update
    if (_offlineMode || force) {
      debugPrint('Updating event $eventId locally (offline mode)');
      
      // Track the change for later sync
      await trackOfflineChange('event', eventId, updates);
      
      // Update the event in memory cache
      final event = _eventCache[eventId]!;
      final eventJson = event.toJson();
      
      // Apply updates to the event
      eventJson.addAll(updates);
      
      // Create updated event
      final updatedEvent = Event.fromJson(eventJson);
      
      // Update cache
      _eventCache[eventId] = updatedEvent;
      
      // Update any event lists that contain this event
      _updateEventInCaches(eventId, updatedEvent);
      
      return true;
    }
    
    // Online mode - update directly in Firestore
    try {
      debugPrint('Updating event $eventId in Firestore');
      
      final docRef = _firestore.collection('events').doc(eventId);
      await docRef.update(updates);
      
      // Update the event in memory cache
      if (_eventCache.containsKey(eventId)) {
        final event = _eventCache[eventId]!;
        final eventJson = event.toJson();
        
        // Apply updates to the event
        eventJson.addAll(updates);
        
        // Create updated event
        final updatedEvent = Event.fromJson(eventJson);
        
        // Update cache
        _eventCache[eventId] = updatedEvent;
        
        // Update any event lists that contain this event
        _updateEventInCaches(eventId, updatedEvent);
      }
      
      return true;
    } catch (e) {
      debugPrint('Error updating event: $e');
      
      // If failed due to network error, do offline update
      if (e.toString().contains('network') || e.toString().contains('connection')) {
        debugPrint('Network error, falling back to offline update');
        return updateEvent(eventId, updates, force: true);
      }
      
      return false;
    }
  }
  
  /// Update an event in all cached lists that contain it
  static void _updateEventInCaches(String eventId, Event updatedEvent) {
    // Update in space events caches
    for (final entry in _spaceEventsCache.entries) {
      final events = entry.value;
      final index = events.indexWhere((e) => e.id == eventId);
      
      if (index >= 0) {
        // Replace the event
        events[index] = updatedEvent;
      }
    }
  }

  /// Start monitoring connectivity changes
  static void _startConnectivityMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) async {
      final hasConnection = results.isNotEmpty && 
          results.first != ConnectivityResult.none;
      
      final wasOffline = _offlineMode;
      
      if (wasOffline && hasConnection) {
        // We just came back online
        debugPrint('🔌 Connection restored, transitioning from offline to online mode');
        await setOfflineMode(false);
      } else if (!wasOffline && !hasConnection) {
        // We just went offline
        debugPrint('🔌 Connection lost, transitioning to offline mode');
        await setOfflineMode(true);
      }
    });
    
    // Perform initial check
    Connectivity().checkConnectivity().then((results) async {
      final hasConnection = results.isNotEmpty && 
          results.first != ConnectivityResult.none;
      
      if (!hasConnection && !_offlineMode) {
        debugPrint('🔌 No connection detected during initialization, enabling offline mode');
        await setOfflineMode(true);
      } else if (hasConnection && _offlineMode) {
        debugPrint('🔌 Connection detected during initialization, disabling offline mode');
        await setOfflineMode(false);
      }
    });
  }
  
  /// Clean up resources
  static void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  /// Prefetch common data for offline use
  static Future<void> prefetchForOffline() async {
    if (_offlineMode) {
      debugPrint('Already in offline mode, skipping prefetch');
      return;
    }
    
    debugPrint('🔄 Prefetching data for offline use...');
    
    try {
      // Use forceRefresh to bypass cache and ensure fresh data
      final stopwatch = Stopwatch()..start();
      
      // Fetch all spaces
      final spaces = await getAllSpaces(forceRefresh: true);
      debugPrint('📋 Prefetched ${spaces.length} spaces for offline use');
      
      // Fetch events for some popular spaces
      // Limit to 10 spaces to avoid excessive reads
      final popularSpaces = spaces.take(10).toList();
      int eventCount = 0;
      
      for (final space in popularSpaces) {
        final events = await getEventsForSpace(space.id, limit: 50);
        eventCount += events.length;
      }
      
      debugPrint('📋 Prefetched $eventCount events for offline use');
      
      // Save to persistent cache
      await _saveToPersistentCache();
      
      stopwatch.stop();
      debugPrint('✅ Prefetch completed in ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      debugPrint('❌ Error during offline prefetch: $e');
    }
  }
  
  /// Check if we have sufficient data cached for offline use
  static bool hasSufficientOfflineData() {
    return _spaceCache.length > 10 && _eventCache.length > 20;
  }

  /// Get all entity IDs with pending changes for a specific entity type
  static List<String> getIdsWithPendingChanges(String entityType) {
    final result = <String>[];
    
    for (final key in _pendingChanges.keys) {
      // Parse the key (format: entityType:entityId)
      final parts = key.split(':');
      if (parts.length == 2 && parts[0] == entityType) {
        result.add(parts[1]);
      }
    }
    
    return result;
  }
  
  /// Get total count of pending changes
  static int getPendingChangesCount() {
    return _pendingChanges.length;
  }
}
