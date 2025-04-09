import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:xml/xml.dart' as xml;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event.dart';
import '../models/club.dart';
import 'club_service.dart';
import 'dart:math' as math;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ui/services/space_event_service.dart';
import 'package:hive_ui/services/space_event_manager.dart';
import 'package:hive_ui/utils/space_categorizer.dart';

class RssService {
  static const String ubEventsRssUrl =
      'https://buffalo.campuslabs.com/engage/events.rss';
  static const String _eventsCacheKey = 'events_cache';
  static const String _eventsTimestampKey = 'events_last_fetch';
  static const String _userPreferencesKey = 'user_preferences';
  static const String _eventInteractionsKey = 'event_interactions';
  static const Duration _cacheValidDuration = Duration(hours: 3);
  static const String firestoreEventsCollection = 'events';
  static const String firestoreLastSyncKey = 'last_sync_timestamp';

  static List<Event> _cachedEvents = [];
  static bool _isLoadingEvents = false;
  static bool _timeZoneInitialized = false;
  static const bool _isSyncingToFirestore = false;

  /// Force refresh flag to prevent multiple concurrent refreshes
  static const bool _isForceRefreshing = false;

  /// Initialize RssService - enabled but limited to once per week
  static Future<void> initialize() async {
    debugPrint('RssService initialization - checking weekly schedule');

    try {
      // Check if we've already performed a sync in the last week
      final metadataRef =
          FirebaseFirestore.instance.collection('metadata').doc('rss_sync');
      final metadataDoc = await metadataRef.get();

      if (metadataDoc.exists &&
          metadataDoc.data()?['last_sync_timestamp'] != null) {
        final timestamp =
            metadataDoc.data()?['last_sync_timestamp'] as Timestamp;
        final lastSync = timestamp.toDate();
        final now = DateTime.now();

        // Check if last sync was less than 7 days ago
        if (now.difference(lastSync).inDays < 7) {
          debugPrint(
              'RSS sync already performed in the last week (${now.difference(lastSync).inDays} days ago). Skipping.');
          return;
        } else {
          debugPrint(
              'Last RSS sync was ${now.difference(lastSync).inDays} days ago. Weekly sync is due.');
          // Schedule sync but don't wait for it
          _scheduleWeeklySync();
        }
      } else {
        debugPrint('No previous RSS sync found. Scheduling initial sync.');
        _scheduleWeeklySync();
      }
    } catch (e) {
      debugPrint('Error checking RSS sync schedule: $e');
    }
  }

  /// Fetch events - disabled
  static Future<List<Event>> fetchEvents(
      {bool forceRefresh = false, int? limit}) async {
    debugPrint('RssService fetchEvents disabled');
    return [];
  }

  /// Sync events with Firestore - disabled
  static Future<void> syncEventsWithFirestore(List<Event> events) async {
    debugPrint('RssService syncEventsWithFirestore disabled');
    return;
  }

  /// Check if sync is needed - always returns false
  static Future<bool> isSyncNeeded() async {
    debugPrint('RssService isSyncNeeded disabled');
    return false;
  }

  /// Force a sync with Firestore regardless of timing - disabled
  static Future<void> forceSyncWithFirestore() async {
    debugPrint('RssService forceSyncWithFirestore disabled');
    return;
  }

  /// Helper method to parse date-time strings in various formats - kept for reference
  static DateTime? _parseDateTime(String dateTimeStr) {
    debugPrint('RssService _parseDateTime disabled');
    return null;
  }

  /// Extract date from description text - kept for reference
  static DateTime? _extractDateFromDescription(String description) {
    debugPrint('RssService _extractDateFromDescription disabled');
    return null;
  }

  // Initialize timezone data
  static void _initializeTimeZone() {
    if (!_timeZoneInitialized) {
      tz.initializeTimeZones();
      _timeZoneInitialized = true;
    }
  }

  // Get Eastern Time Zone
  static tz.Location _getEasternTimeZone() {
    _initializeTimeZone();
    try {
      return tz.getLocation('America/New_York');
    } catch (e) {
      debugPrint('Error getting Eastern Time Zone: $e');
      // Fallback to default
      return tz.local;
    }
  }

  /// User preferences for event filtering and sorting
  static Future<Map<String, dynamic>> getUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final prefsJson = prefs.getString(_userPreferencesKey);
    if (prefsJson != null) {
      return jsonDecode(prefsJson);
    }
    return {
      'interests': <String>[],
      'preferred_locations': <String>[],
      'preferred_times': <String>[],
      'excluded_organizers': <String>[],
    };
  }

  /// Save user preferences
  static Future<void> saveUserPreferences(
      Map<String, dynamic> preferences) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userPreferencesKey, jsonEncode(preferences));
  }

  /// Track event interaction (view, RSVP, etc.)
  static Future<void> trackEventInteraction(
      String eventId, String organizerName, String interactionType) async {
    final prefs = await SharedPreferences.getInstance();
    final interactionsJson = prefs.getString(_eventInteractionsKey);
    final interactions = interactionsJson != null
        ? jsonDecode(interactionsJson) as Map<String, dynamic>
        : {};

    // Update organizer interaction count
    final organizerInteractions =
        interactions[organizerName] as Map<String, dynamic>? ?? {};
    organizerInteractions['count'] =
        (organizerInteractions['count'] as int? ?? 0) + 1;
    organizerInteractions['lastInteraction'] = DateTime.now().toIso8601String();

    // Track specific interaction types
    final interactionTypes =
        organizerInteractions['types'] as Map<String, int>? ?? {};
    interactionTypes[interactionType] =
        (interactionTypes[interactionType] ?? 0) + 1;
    organizerInteractions['types'] = interactionTypes;

    interactions[organizerName] = organizerInteractions;

    await prefs.setString(_eventInteractionsKey, jsonEncode(interactions));
  }

  /// Get past attendance data for relevance scoring
  static Future<Map<String, int>> getPastAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    final interactionsJson = prefs.getString(_eventInteractionsKey);
    if (interactionsJson == null) return {};

    final interactions = jsonDecode(interactionsJson) as Map<String, dynamic>;
    final attendance = <String, int>{};

    for (final entry in interactions.entries) {
      final organizerData = entry.value as Map<String, dynamic>;
      attendance[entry.key] = organizerData['count'] as int? ?? 0;
    }

    return attendance;
  }

  /// Deduplicate similar events with optimized algorithm
  static List<Event> _deduplicateEvents(List<Event> events) {
    // If there are very few events, no need to deduplicate
    if (events.length <= 1) return events;

    final uniqueEvents = <Event>[];
    // Using a map instead of a list for faster lookups of previously seen titles
    final seenTitles = <String, double>{}; // title -> similarity threshold

    // Create an optimized version where we normalize all titles first
    final normalizedTitles =
        events.map((e) => e.title.toLowerCase().trim()).toList();

    for (int i = 0; i < events.length; i++) {
      final event = events[i];
      final normalizedTitle = normalizedTitles[i];

      // Skip empty titles
      if (normalizedTitle.isEmpty) {
        uniqueEvents.add(event);
        continue;
      }

      // Use a more efficient duplicate detection
      bool isDuplicate = false;

      // First check for exact matches which is faster
      if (seenTitles.containsKey(normalizedTitle)) {
        isDuplicate = true;
      } else {
        // Only check for similarity with titles of similar length
        // This reduces unnecessary comparisons
        for (final entry in seenTitles.entries) {
          final seenTitle = entry.key;
          final similarityThreshold = entry.value;

          // Skip comparing if length differs too much - quick filter
          if ((normalizedTitle.length - seenTitle.length).abs() >
              normalizedTitle.length * 0.3) {
            continue;
          }

          // Quick character frequency check to avoid expensive Levenshtein
          if (_quickSimilarityCheck(normalizedTitle, seenTitle)) {
            final similarity =
                _calculateTitleSimilarity(normalizedTitle, seenTitle);
            if (similarity > similarityThreshold) {
              isDuplicate = true;
              break;
            }
          }
        }
      }

      if (!isDuplicate) {
        uniqueEvents.add(event);
        // Store similarity threshold based on title length - longer titles can have a higher threshold
        double similarityThreshold = 0.8;
        if (normalizedTitle.length > 30) similarityThreshold = 0.85;
        if (normalizedTitle.length < 15) similarityThreshold = 0.75;
        seenTitles[normalizedTitle] = similarityThreshold;
      }
    }

    return uniqueEvents;
  }

  /// Quick check to see if strings are similar enough to warrant expensive Levenshtein distance calculation
  static bool _quickSimilarityCheck(String s1, String s2) {
    // If first few characters match, it's worth checking in detail
    if (s1.length > 3 &&
        s2.length > 3 &&
        s1.substring(0, 3) == s2.substring(0, 3)) {
      return true;
    }

    // Count character frequencies for rapid comparison
    final counter1 = <String, int>{};
    final counter2 = <String, int>{};

    for (var i = 0; i < s1.length; i++) {
      final char = s1[i];
      counter1[char] = (counter1[char] ?? 0) + 1;
    }

    for (var i = 0; i < s2.length; i++) {
      final char = s2[i];
      counter2[char] = (counter2[char] ?? 0) + 1;
    }

    // Calculate quick similarity based on character frequencies
    int commonChars = 0;
    int totalChars = 0;

    for (var entry in counter1.entries) {
      final char = entry.key;
      final count1 = entry.value;
      final count2 = counter2[char] ?? 0;

      commonChars += math.min(count1, count2);
      totalChars += count1;
    }

    // If we have at least 60% character overlap, do the expensive check
    return commonChars / totalChars > 0.6;
  }

  /// Calculate similarity between two titles (simple Levenshtein-based approach)
  static double _calculateTitleSimilarity(String title1, String title2) {
    if (title1 == title2) return 1.0;
    if (title1.isEmpty || title2.isEmpty) return 0.0;

    final distance = _levenshteinDistance(title1, title2);
    final maxLength = math.max(title1.length, title2.length);

    return 1 - (distance / maxLength);
  }

  /// Calculate Levenshtein distance between two strings
  static int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;

      for (int j = 0; j < s2.length; j++) {
        int cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = math.min(v1[j] + 1, math.min(v0[j + 1] + 1, v0[j] + cost));
      }

      for (int j = 0; j <= s2.length; j++) {
        v0[j] = v1[j];
      }
    }

    return v1[s2.length];
  }

  /// Primary event fetching method - now Firestore-only for normal operation
  /// RSS parsing is removed from the main app flow and will only happen
  /// through scheduled background tasks
  /* Original fetchEvents method commented out to avoid duplication with the stub
  static Future<List<Event>> fetchEvents({
    bool forceRefresh = false,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
    String? organizerName,
  }) async {
    debugPrint('\n======== Fetching Events (Firestore-Only) ========');
    
    try {
      // Always attempt to load from Firestore first with optimal query
      final events = await loadEventsFromFirestore(
        includeExpired: false,
        limit: limit,
        startDate: startDate,
        endDate: endDate,
        category: category,
        organizerName: organizerName,
      );
      
      // If we have events from Firestore, use them
      if (events.isNotEmpty) {
        debugPrint('Retrieved ${events.length} events from Firestore');
        
        // Update local cache for offline access
        _cachedEvents = events;
        await _saveEventsToCache(events);
        
        return events;
      }
      
      // If Firestore had no events, check local cache as fallback
      debugPrint('No events found in Firestore, checking local cache...');
      await _loadEventsFromCache();
      
      if (_cachedEvents.isNotEmpty) {
        debugPrint('Using ${_cachedEvents.length} events from local cache');
        
        return _filterEvents(
          _cachedEvents,
          category: category,
          startDate: startDate,
          endDate: endDate,
          limit: limit,
          organizerName: organizerName,
        );
      }
      
      // In production, we should never reach here unless it's a new installation
      // or there's an issue with Firestore. Return empty list.
      debugPrint(
          'WARNING: No events found in Firestore or cache. Is the database empty?');
      
      // Trigger a background sync if we have no events, but don't wait for it
      // This will populate Firestore for future requests without blocking the UI
      if (forceRefresh) {
        debugPrint('Force refresh requested, scheduling background sync...');
        _startBackgroundSync();
      }
      
      return [];
    } catch (e, stackTrace) {
      debugPrint('Error fetching events: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // On error, try to return cached events if available
      if (_cachedEvents.isNotEmpty) {
        return _filterEvents(
          _cachedEvents,
          category: category,
          startDate: startDate,
          endDate: endDate,
          limit: limit,
          organizerName: organizerName,
        );
      }
      
      return [];
    }
  }
  */

  /// Filter events based on criteria
  static List<Event> _filterEvents(
    List<Event> events, {
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
    String? organizerName,
  }) {
    var filtered = events;

    // Apply filters
    if (category != null && category.isNotEmpty) {
      filtered = filtered
          .where((e) =>
              e.category.toLowerCase() == category.toLowerCase() ||
              e.tags.any((t) => t.toLowerCase() == category.toLowerCase()))
          .toList();
    }

    if (startDate != null) {
      filtered = filtered
          .where((e) =>
              e.startDate.isAfter(startDate) ||
              e.startDate.isAtSameMomentAs(startDate))
          .toList();
    }

    if (endDate != null) {
      filtered = filtered
          .where((e) =>
              e.endDate.isBefore(endDate) ||
              e.endDate.isAtSameMomentAs(endDate))
          .toList();
    }

    if (organizerName != null && organizerName.isNotEmpty) {
      filtered = filtered
          .where((e) => e.organizerName
              .toLowerCase()
              .contains(organizerName.toLowerCase()))
          .toList();
    }

    // Sort by start date
    filtered.sort((a, b) => a.startDate.compareTo(b.startDate));

    // Apply limit
    if (filtered.length > limit) {
      filtered = filtered.sublist(0, limit);
    }

    return filtered;
  }

  /// Check if sync is needed and start background sync if necessary
  static Future<void> _checkAndSyncInBackground() async {
    // Only check for sync if not already syncing
    if (!_isSyncingToFirestore) {
      final needsSync = await isSyncNeeded();
      if (needsSync) {
        debugPrint('Sync needed, starting background sync...');
        _startBackgroundSync();
      }
    }
  }

  /// Start a background sync without awaiting the result
  /// Respects a minimum interval between syncs to prevent frequent RSS parsing
  static void _startBackgroundSync() async {
    // Don't start if already syncing
    if (_isSyncingToFirestore) {
      debugPrint('Already syncing, skipping duplicate request');
      return;
    }

    try {
      // Check when the last sync was performed
      final prefs = await SharedPreferences.getInstance();
      final lastSyncTimestamp = prefs.getInt('last_rss_update_timestamp') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Minimum interval: 6 hours between syncs (in milliseconds)
      const minimumSyncInterval = 6 * 60 * 60 * 1000;

      if ((now - lastSyncTimestamp) < minimumSyncInterval) {
        // If we synced recently, don't sync again
        final nextSyncTime = DateTime.fromMillisecondsSinceEpoch(
            lastSyncTimestamp + minimumSyncInterval);
        debugPrint('Skipping background sync: last sync was too recent.');
        debugPrint('Next scheduled sync: $nextSyncTime');
        return;
      }

      // If we've passed the interval check, start the background sync
      debugPrint('Starting background sync process...');
      _fetchEventsFromNetworkInBackground();

      // Update the timestamp
      await prefs.setInt('last_rss_update_timestamp', now);
    } catch (e) {
      debugPrint('Error checking sync interval: $e');
      // On error, fall back to the original behavior
      _fetchEventsFromNetworkInBackground();
    }
  }

  /// Loads events from Firestore with optimized queries for minimal reads
  static Future<List<Event>> loadEventsFromFirestore({
    bool includeExpired = false,
    int limit = 100,
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    String? organizerName,
  }) async {
    try {
      debugPrint(
          '\n======== Loading events from Firestore with optimized query ========');
      final firestore = FirebaseFirestore.instance;
      final eventsCollection = firestore.collection(firestoreEventsCollection);

      // Build query with optimization in mind - add filters only when needed
      Query query = eventsCollection;
      bool hasFilter = false;

      // Only include upcoming events by default (most common use case)
      if (!includeExpired) {
        final now = DateTime.now();
        query = query.where('endDate',
            isGreaterThanOrEqualTo: now.toIso8601String());
        hasFilter = true;
      }

      // Add date range filters if provided
      if (startDate != null) {
        query = query.where('startDate',
            isGreaterThanOrEqualTo: startDate.toIso8601String());
        hasFilter = true;
      }

      if (endDate != null) {
        query = query.where('endDate',
            isLessThanOrEqualTo: endDate.toIso8601String());
        hasFilter = true;
      }

      // Category filter - if present, use a special query
      if (category != null && category.isNotEmpty) {
        // Try to match category or tags
        query = query.where('category', isEqualTo: category);
        hasFilter = true;
        // Note: Filtering by tags would require a separate query and array-contains operator
      }

      // Organizer filter
      if (organizerName != null && organizerName.isNotEmpty) {
        query = query.where('organizerName', isEqualTo: organizerName);
        hasFilter = true;
      }

      // Always order by start date for consistent results
      query = query.orderBy('startDate');

      // Limit results to reduce read operations
      query = query.limit(limit);

      // Execute the query
      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        debugPrint('No events found in Firestore matching criteria');
        return [];
      }

      // Parse events from Firestore documents
      final List<Event> events = snapshot.docs
          .map((doc) {
            try {
              return Event.fromJson(doc.data() as Map<String, dynamic>);
            } catch (e) {
              debugPrint('Error parsing event document ${doc.id}: $e');
              return null;
            }
          })
          .whereType<Event>()
          .toList();

      debugPrint('Successfully loaded ${events.length} events from Firestore');

      // Extract spaces from events if needed
      await _extractSpacesFromEventsIfNeeded(events);

      return events;
    } catch (e) {
      debugPrint('Error loading events from Firestore: $e');
      return [];
    }
  }

  /// Internal method to check if refresh needed and do it in background
  static Future<void> _checkAndRefreshEventsIfNeeded() async {
    if (_isLoadingEvents) return;

    try {
      if (await _isCacheStale()) {
        _fetchEventsFromNetwork();
      }
    } catch (e) {
      debugPrint('Error checking for events refresh: $e');
    }
  }

  /// Check if our cached events are stale
  static Future<bool> _isCacheStale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastFetchTimestamp = prefs.getInt(_eventsTimestampKey);

      if (lastFetchTimestamp == null) return true;

      final lastFetchTime =
          DateTime.fromMillisecondsSinceEpoch(lastFetchTimestamp);
      final now = DateTime.now();

      // Check if cache is older than the valid duration
      return now.difference(lastFetchTime) > _cacheValidDuration;
    } catch (e) {
      debugPrint('Error checking events cache staleness: $e');
      return true;
    }
  }

  /// Load events from persistent cache
  static Future<List<Event>> _loadEventsFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = prefs.getString(_eventsCacheKey);

      if (eventsJson == null || eventsJson.isEmpty) {
        return [];
      }

      final List<dynamic> eventsList = jsonDecode(eventsJson);
      return eventsList.map((json) => Event.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading events from cache: $e');
      return [];
    }
  }

  /// Save events to persistent cache
  static Future<void> _saveEventsToCache(List<Event> events) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsList = events.map((event) => event.toMap()).toList();
      await prefs.setString(_eventsCacheKey, jsonEncode(eventsList));
      await prefs.setInt(
          _eventsTimestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error saving events to cache: $e');
    }
  }

  /// Fetch fresh events from network
  static Future<List<Event>> _fetchEventsFromNetwork() async {
    if (_isLoadingEvents) {
      while (_isLoadingEvents) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _cachedEvents;
    }

    _isLoadingEvents = true;
    debugPrint('\n=== Starting Network Fetch ===');
    debugPrint('Fetching from URL: $ubEventsRssUrl');

    try {
      final response = await http.get(Uri.parse(ubEventsRssUrl));

      if (response.statusCode == 200) {
        // Reduced debug output to prevent flooding
        debugPrint('Received response with status: ${response.statusCode}');
        debugPrint('Response length: ${response.body.length} characters');

        // Check if response is not empty
        if (response.body.isEmpty) {
          throw Exception('Empty response from RSS feed');
        }

        debugPrint('\nSuccessfully fetched RSS feed, starting to parse...');

        // Parse the RSS feed using XML library
        final events = await _parseEventsFromXml(response.body);

        debugPrint('Parsed ${events.length} events from RSS feed');

        // Cache the results
        _cachedEvents = events;
        await _saveEventsToCache(events);

        // Generate club spaces from events
        await ClubService.generateClubsFromEvents(events);

        // Sync events to Firestore if needed
        if (await isSyncNeeded()) {
          // Don't await this call so we don't block returning events
          syncEventsWithFirestore(events).then((_) {
            debugPrint(
                'Completed background Firestore sync after fetching events');
          }).catchError((e) {
            debugPrint('Error in background Firestore sync: $e');
          });
        }

        return events;
      } else {
        debugPrint('Failed to load RSS feed: ${response.statusCode}');
        debugPrint(
            'Response body: ${response.body.substring(0, min(100, response.body.length))}...');
        throw Exception('Failed to load RSS feed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching RSS feed: $e');
      throw Exception('Error fetching RSS feed: $e');
    } finally {
      _isLoadingEvents = false;
    }
  }

  /// Parses RSS feed XML and extracts event data
  static Future<List<Event>> _parseEventsFromXml(String xmlString) async {
    final events = <Event>[];

    debugPrint('\n=== Starting RSS Feed Parse ===');

    try {
      // Debug: Print a sample of the XML to help diagnose issues
      final xmlPreview = xmlString.length > 500
          ? '${xmlString.substring(0, 500)}...'
          : xmlString;
      debugPrint('XML Preview: $xmlPreview');

      // Try to identify namespaces in the XML document
      final document = xml.XmlDocument.parse(xmlString);

      // DEBUG: Let's list all namespaces in the document to ensure we're using the correct ones
      debugPrint('\n=== XML Namespaces ===');
      try {
        // Try to access the namespaces directly from the document
        final rootElement = document.rootElement;
        final attributes = rootElement.attributes;
        for (final attribute in attributes) {
          if (attribute.name.prefix == 'xmlns') {
            debugPrint(
                'Namespace: ${attribute.name.local}, URI: ${attribute.value}');
          }
        }
      } catch (e) {
        debugPrint('Error listing namespaces: $e');
      }

      final items = document.findAllElements('item').toList();

      debugPrint('Found ${items.length} items in RSS feed');

      for (final item in items) {
        try {
          final title = _getElementText(item, 'title') ?? 'Untitled Event';
          String description = _getElementText(item, 'description') ?? '';

          debugPrint('\n--- Processing Event: "$title" ---');

          // Setting default values
          String organizerName = 'University at Buffalo';
          String organizerEmail = '';

          // ENHANCED HOST EXTRACTION - Try multiple approaches

          // 1. Look for host tag in all possible namespaces
          bool hostFound = false;

          // Try the standard 'events' namespace first
          final hostElements =
              item.findAllElements('host', namespace: 'events').toList();
          debugPrint(
              'Checking for host with events namespace: found ${hostElements.length} elements');

          if (hostElements.isNotEmpty) {
            final hostName = hostElements.first.innerText.trim();
            if (hostName.isNotEmpty) {
              organizerName = hostName;
              hostFound = true;
              debugPrint(
                  '✓ Found organizer in host tag with events namespace: $organizerName');
            }
          }

          // If not found with 'events' namespace, try without namespace
          if (!hostFound) {
            final plainHostElements = item.findElements('host').toList();
            debugPrint(
                'Checking for host without namespace: found ${plainHostElements.length} elements');

            if (plainHostElements.isNotEmpty) {
              final hostName = plainHostElements.first.innerText.trim();
              if (hostName.isNotEmpty) {
                organizerName = hostName;
                hostFound = true;
                debugPrint(
                    '✓ Found organizer in host tag without namespace: $organizerName');
              }
            }
          }

          // If not found with host elements, try category tag as some feeds use it for organization
          if (!hostFound) {
            final categoryElements = item.findElements('category').toList();
            debugPrint(
                'Checking categories for potential organization: found ${categoryElements.length} elements');

            if (categoryElements.isNotEmpty) {
              // Use the first category as a potential organization name if appropriate
              final category = categoryElements.first.innerText.trim();
              if (category.isNotEmpty &&
                  !category.contains("Event") &&
                  category != "UB" &&
                  !category.startsWith("University")) {
                organizerName = category;
                hostFound = true;
                debugPrint(
                    '✓ Using category as organization name: $organizerName');
              }
            }
          }

          // Look for creator tag which some feeds use
          if (!hostFound) {
            // Try Dublin Core creator element
            final creatorElements =
                item.findAllElements('creator', namespace: 'dc').toList();
            debugPrint(
                'Checking DC creator: found ${creatorElements.length} elements');

            if (creatorElements.isNotEmpty) {
              final creator = creatorElements.first.innerText.trim();
              if (creator.isNotEmpty) {
                organizerName = creator;
                hostFound = true;
                debugPrint(
                    '✓ Found organizer in DC creator tag: $organizerName');
              }
            }
          }

          // 2. FALLBACK: Check for author tag with email and organization in parentheses
          if (!hostFound) {
            final authorText = _getElementText(item, 'author') ?? '';
            if (authorText.isNotEmpty) {
              debugPrint('Author tag content: $authorText');
              organizerEmail = authorText.trim();

              // Try to extract organization name from email if in format: name@domain.com (Organization Name)
              final emailWithOrgRegex = RegExp(r'(.*?)\s*\((.*?)\)');
              final match = emailWithOrgRegex.firstMatch(authorText);

              if (match != null && match.groupCount >= 2) {
                final email = match.group(1)?.trim() ?? '';
                final org = match.group(2)?.trim() ?? '';

                if (email.isNotEmpty) organizerEmail = email;
                if (org.isNotEmpty &&
                    (organizerName == 'University at Buffalo' || !hostFound)) {
                  organizerName = org;
                  hostFound = true;
                  debugPrint(
                      '✓ Found organizer in author tag parentheses: $organizerName');
                }
              }

              // If no parentheses but there's an @ symbol, try using the domain part
              if (!hostFound && authorText.contains('@')) {
                final atParts = authorText.split('@');
                if (atParts.length > 1) {
                  final domainPart = atParts[1].split('.').first;
                  if (domainPart.isNotEmpty &&
                      domainPart.length > 3 &&
                      !domainPart.contains('buffalo')) {
                    // Convert domain to title case and use as org name
                    final orgFromDomain =
                        domainPart[0].toUpperCase() + domainPart.substring(1);
                    organizerName = '$orgFromDomain Club';
                    hostFound = true;
                    debugPrint(
                        '✓ Created organizer name from email domain: $organizerName');
                  }
                }
              }
            }
          }

          debugPrint(
              'Final organizer name: $organizerName, Email: $organizerEmail');

          // ENHANCED DATE EXTRACTION

          DateTime? startDate;
          DateTime? endDate;

          // Debug date-related elements
          debugPrint('\n--- Date Elements ---');

          // Try to find all date/time related elements using multiple approaches
          final pubDateText = _getElementText(item, 'pubDate');
          debugPrint('pubDate: $pubDateText');

          final dateElements = item.findElements('date').toList();
          if (dateElements.isNotEmpty) {
            debugPrint('date element: ${dateElements.first.innerText}');
          }

          // 1. First try the events namespace
          final startElements =
              item.findAllElements('start', namespace: 'events').toList();
          debugPrint(
              'start (events namespace): ${startElements.isNotEmpty ? startElements.first.innerText : "not found"}');

          final endElements =
              item.findAllElements('end', namespace: 'events').toList();
          debugPrint(
              'end (events namespace): ${endElements.isNotEmpty ? endElements.first.innerText : "not found"}');

          // 2. Try without namespace
          final plainStartElements = item.findElements('start').toList();
          debugPrint(
              'start (no namespace): ${plainStartElements.isNotEmpty ? plainStartElements.first.innerText : "not found"}');

          final plainEndElements = item.findElements('end').toList();
          debugPrint(
              'end (no namespace): ${plainEndElements.isNotEmpty ? plainEndElements.first.innerText : "not found"}');

          // Try standard events namespace first
          if (startElements.isNotEmpty) {
            try {
              final startTimeStr = startElements.first.innerText;
              startDate = _parseDateTime(startTimeStr);
              if (startDate != null) {
                debugPrint(
                    '✓ Parsed start date (events namespace): ${startDate.toString()}');
              }
            } catch (e) {
              debugPrint('❌ Error parsing start date (events namespace): $e');
            }
          }

          if (endElements.isNotEmpty) {
            try {
              final endTimeStr = endElements.first.innerText;
              endDate = _parseDateTime(endTimeStr);
              if (endDate != null) {
                debugPrint(
                    '✓ Parsed end date (events namespace): ${endDate.toString()}');
              }
            } catch (e) {
              debugPrint('❌ Error parsing end date (events namespace): $e');
            }
          }

          // If events namespace failed, try without namespace
          if (startDate == null && plainStartElements.isNotEmpty) {
            try {
              final startTimeStr = plainStartElements.first.innerText;
              startDate = _parseDateTime(startTimeStr);
              if (startDate != null) {
                debugPrint(
                    '✓ Parsed start date (no namespace): ${startDate.toString()}');
              }
            } catch (e) {
              debugPrint('❌ Error parsing start date (no namespace): $e');
            }
          }

          if (endDate == null && plainEndElements.isNotEmpty) {
            try {
              final endTimeStr = plainEndElements.first.innerText;
              endDate = _parseDateTime(endTimeStr);
              if (endDate != null) {
                debugPrint(
                    '✓ Parsed end date (no namespace): ${endDate.toString()}');
              }
            } catch (e) {
              debugPrint('❌ Error parsing end date (no namespace): $e');
            }
          }

          // If still no date found, look for it in the description
          if (startDate == null) {
            startDate = _extractDateFromDescription(description);
            if (startDate != null) {
              debugPrint(
                  '✓ Extracted start date from description: ${startDate.toString()}');
              // If no end time but start time found in description, assume 2 hours
              if (endDate == null) {
                endDate = startDate.add(const Duration(hours: 2));
                debugPrint(
                    'Set default end date to 2 hours after start: ${endDate.toString()}');
              }
            }
          }

          // If all else fails, use current time as fallback
          if (startDate == null) {
            startDate = DateTime.now().add(const Duration(days: 1));
            debugPrint('⚠ Using fallback start date: ${startDate.toString()}');
          }

          if (endDate == null) {
            endDate = startDate.add(const Duration(hours: 2));
            debugPrint('⚠ Using fallback end date: ${endDate.toString()}');
          }

          // Extract image URL from enclosure tag
          String imageUrl = '';
          final enclosureElements = item.findElements('enclosure').toList();
          debugPrint('Processing event: "$title"');
          debugPrint('Found ${enclosureElements.length} enclosure elements');

          if (enclosureElements.isNotEmpty) {
            for (final enclosure in enclosureElements) {
              final url = enclosure.getAttribute('url');
              final type = enclosure.getAttribute('type');

              debugPrint('Enclosure URL: $url, Type: $type');

              if (url != null && type != null && type.startsWith('image/')) {
                imageUrl = _normalizeImageUrl(url);
                debugPrint('✓ Found image URL in enclosure: $imageUrl');
                break;
              } else if (url != null && type == null) {
                // If type is not specified but URL looks like an image
                if (url.toLowerCase().endsWith('.jpg') ||
                    url.toLowerCase().endsWith('.jpeg') ||
                    url.toLowerCase().endsWith('.png') ||
                    url.toLowerCase().endsWith('.gif')) {
                  imageUrl = _normalizeImageUrl(url);
                  debugPrint(
                      '✓ Found potential image URL by extension: $imageUrl');
                  break;
                }
              }
            }
          } else {
            debugPrint('No enclosure elements found');
          }

          // Fallback: Look for media:content tags (alternative format for images)
          if (imageUrl.isEmpty) {
            final mediaElements =
                item.findAllElements('content', namespace: 'media').toList();
            debugPrint('Found ${mediaElements.length} media:content elements');

            if (mediaElements.isNotEmpty) {
              for (final media in mediaElements) {
                final url = media.getAttribute('url');
                final type = media.getAttribute('type');

                debugPrint('Media Content URL: $url, Type: $type');

                if (url != null &&
                    (type == null || type.startsWith('image/'))) {
                  imageUrl = _normalizeImageUrl(url);
                  debugPrint('✓ Found image URL in media:content: $imageUrl');
                  break;
                }
              }
            }
          }

          // Fallback: Look for image URL in description content
          if (imageUrl.isEmpty && description.contains('<img')) {
            debugPrint(
                'Looking for <img> tags in description: ${description.substring(0, min(100, description.length))}...');

            final imgRegex = RegExp(r'<img[^>]+src="([^">]+)"');
            final match = imgRegex.firstMatch(description);

            if (match != null && match.groupCount >= 1) {
              final extractedUrl = match.group(1) ?? '';
              debugPrint('Extracted URL from img tag: $extractedUrl');

              imageUrl = _normalizeImageUrl(extractedUrl);
              if (imageUrl.isNotEmpty) {
                debugPrint('✓ Found image URL in description HTML: $imageUrl');
              }
            } else {
              debugPrint('No image tag found in description');
            }
          }

          // Extract category (can be multiple)
          final categories = item
              .findElements('category')
              .map((e) => e.innerText)
              .where((c) => c.isNotEmpty)
              .toList();
          final String category =
              categories.isNotEmpty ? categories.first : 'Event';

          // Extract location from the events namespace
          String location = 'UB Campus';
          final locationElements =
              item.findAllElements('location', namespace: 'events').toList();

          if (locationElements.isNotEmpty) {
            location = locationElements.first.innerText.trim();
          }

          // Clean HTML from description
          description = _cleanHtml(description);

          // Create a unique ID for the event
          final guid =
              '${title.hashCode}_${startDate.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}';

          // Add the event
          final event = Event(
            id: guid,
            title: title,
            description: description,
            location: location,
            startDate: startDate,
            endDate: endDate,
            organizerEmail: organizerEmail,
            organizerName: organizerName,
            category: category,
            status: 'confirmed',
            link: _getElementText(item, 'link') ?? '',
            originalTitle: title,
            imageUrl: imageUrl,
            source: EventSource.external,
          );

          events.add(event);

          debugPrint('\nAdded event:');
          debugPrint('Title: ${event.title}');
          debugPrint('Organizer: ${event.organizerName}');
          debugPrint('Email: ${event.organizerEmail}');
          debugPrint('Location: ${event.location}');
          debugPrint('Category: ${event.category}');
          debugPrint(
              'Image URL: ${event.imageUrl.isNotEmpty ? event.imageUrl : "No image available"}');

          // Test image URL validity
          if (event.imageUrl.isNotEmpty) {
            try {
              final uri = Uri.parse(event.imageUrl);
              debugPrint('Image URL parsing successful: $uri');
            } catch (e) {
              debugPrint('❌ Error parsing image URL: $e');
            }
          }
        } catch (e, stackTrace) {
          debugPrint('Error parsing RSS item: $e');
          debugPrint('Stack trace: $stackTrace');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error parsing RSS XML: $e');
      debugPrint('Stack trace: $stackTrace');
    }

    debugPrint('\n=== RSS Feed Parse Complete ===');
    debugPrint('Successfully parsed ${events.length} events');
    for (final event in events) {
      debugPrint('Event: ${event.title} - Organizer: ${event.organizerName}');
    }

    return events;
  }

  /// Helper method to get text from an XML element
  static String? _getElementText(xml.XmlElement parent, String elementName) {
    final element = parent.findElements(elementName).firstOrNull;
    return element?.innerText;
  }

  /// Helper method to parse month name to number
  static int _parseMonth(String monthName) {
    const months = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12
    };
    return months[monthName] ?? 1;
  }

  /// Removes HTML tags from text
  static String _cleanHtml(String htmlString) {
    // Remove HTML tags
    final text = htmlString.replaceAll(RegExp(r'<[^>]*>'), '');
    // Decode HTML entities
    return text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
  }

  /// Normalizes an image URL to ensure it uses HTTPS and is properly formatted
  static String _normalizeImageUrl(String url) {
    if (url.isEmpty) return url;

    debugPrint('Normalizing URL: $url');

    // Convert HTTP to HTTPS
    String normalizedUrl = url;
    if (normalizedUrl.startsWith('http:')) {
      normalizedUrl = 'https:${normalizedUrl.substring(5)}';
      debugPrint('Converted HTTP to HTTPS: $normalizedUrl');
    }

    // Handle relative URLs
    if (normalizedUrl.startsWith('//')) {
      normalizedUrl = 'https:$normalizedUrl';
      debugPrint('Added https to protocol-relative URL: $normalizedUrl');
    }

    // If URL contains encoded characters, decode them
    if (normalizedUrl.contains('%')) {
      try {
        final decoded = Uri.decodeFull(normalizedUrl);
        normalizedUrl = decoded;
        debugPrint('Decoded URL: $normalizedUrl');
      } catch (e) {
        debugPrint('Error decoding URL: $e');
      }
    }

    // Try to validate the URL
    try {
      final uri = Uri.parse(normalizedUrl);
      if (!uri.hasScheme) {
        debugPrint('URL is missing scheme, adding https://');
        normalizedUrl = 'https://$normalizedUrl';
      }
    } catch (e) {
      debugPrint('Error parsing URL: $e');
    }

    debugPrint('Final normalized URL: $normalizedUrl');
    return normalizedUrl;
  }

  /// Helper method to calculate the minimum of two integers
  static int min(int a, int b) {
    return a < b ? a : b;
  }

  /// Gets all the clubs extracted from fetched events
  static Future<List<Club>> getExtractedClubs() async {
    return ClubService.getAllExtractedClubs();
  }

  /// Gets a specific club by the organizer name
  static Club? getClubByOrganizerName(String organizerName) {
    final clubId = Club.createIdFromName(organizerName);
    return ClubService.getClubById(clubId);
  }

  /// Force refresh method - schedules a background sync task instead of direct RSS parsing
  static Future<List<Event>> forceRefresh() async {
    debugPrint('Force refresh requested - scheduling background sync task');

    // Schedule background sync without awaiting completion
    _startBackgroundSync();

    // Return current events from Firestore with increased limit for better coverage
    return fetchEvents(limit: 500, forceRefresh: false);
  }

  /// Gets events from Firestore
  static Future<List<Event>> getEventsFromFirestore({
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    String? organizerName,
    int? limit,
  }) async {
    debugPrint('RssService getEventsFromFirestore called');

    // Instead of using Firestore, just return an empty list
    return [];
  }

  /// Gets a specific event from Firestore by ID
  static Future<Event?> getEventFromFirestore(String eventId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final docSnapshot = await firestore
          .collection(firestoreEventsCollection)
          .doc(eventId)
          .get();

      if (!docSnapshot.exists) {
        return null;
      }

      final event = Event.fromJson(docSnapshot.data()!);

      // Link event to space if needed
      if (event.organizerName.isNotEmpty) {
        await _linkEventToSpaceIfNeeded(event);
      }

      return event;
    } catch (e) {
      debugPrint('Error getting event from Firestore: $e');
      return null;
    }
  }

  /// Helper method to extract spaces from events if needed
  static Future<void> _extractSpacesFromEventsIfNeeded(
      List<Event> events) async {
    try {
      // Only extract spaces during weekly sync or when explicitly needed
      // Check if we've recently extracted spaces - use a simple timestamp check
      final lastSpaceExtraction = await _getLastSpaceExtractionTime();
      final now = DateTime.now();

      // Only extract spaces weekly at most
      if (lastSpaceExtraction != null &&
          now.difference(lastSpaceExtraction).inDays < 7) {
        debugPrint(
            'Skipping space extraction - last extraction was within 7 days');
        return;
      }

      // Extract spaces from events
      await SpaceEventService.extractSpacesFromEvents(events);

      // Save the extraction time
      await _updateLastSpaceExtractionTime();
    } catch (e) {
      debugPrint('Error extracting spaces from events: $e');
    }
  }

  /// Get the last time spaces were extracted
  static Future<DateTime?> _getLastSpaceExtractionTime() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final metadataDoc =
          await firestore.collection('metadata').doc('space_extraction').get();

      if (metadataDoc.exists &&
          metadataDoc.data()!.containsKey('last_extraction')) {
        final timestamp = metadataDoc.data()!['last_extraction'] as Timestamp?;
        return timestamp?.toDate();
      }
      return null;
    } catch (e) {
      debugPrint('Error getting last space extraction time: $e');
      return null;
    }
  }

  /// Update the last space extraction time
  static Future<void> _updateLastSpaceExtractionTime() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final metadataRef =
          firestore.collection('metadata').doc('space_extraction');
      await metadataRef.set({
        'last_extraction': FieldValue.serverTimestamp(),
        'count': FieldValue.increment(1),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating last space extraction time: $e');
    }
  }

  /// Helper method to link an event to its space
  static Future<void> _linkEventToSpaceIfNeeded(Event event) async {
    try {
      // Link event to space
      await SpaceEventService.linkEventToSpace(event.id, event.organizerName);
    } catch (e) {
      debugPrint('Error linking event to space: $e');
    }
  }

  /// Updates a specific event in Firestore
  static Future<bool> updateEventInFirestore(Event event) async {
    try {
      // First, try to determine the space this event belongs to
      if (event.organizerName.isNotEmpty) {
        final spaceType = SpaceCategorizer.categorizeFromEvent(event);
        final spaceId = _generateSpaceId(event.organizerName);

        // Try to update the event in its space
        final success = await SpaceEventManager.addOrUpdateEvent(
          event: event,
          spaceId: spaceId,
          spaceType: spaceType,
        );

        if (success) {
          debugPrint(
              'Successfully updated event ${event.id} in space $spaceId');
          return true;
        }
      }

      // Fallback to the old method if the above fails
      final firestore = FirebaseFirestore.instance;

      // Add last_modified field when updating
      final eventData = event.toMap();
      eventData['last_modified'] = FieldValue.serverTimestamp();

      await firestore
          .collection(firestoreEventsCollection)
          .doc(event.id)
          .set(eventData, SetOptions(merge: true));

      debugPrint(
          'Successfully updated event ${event.id} in Firestore root collection');
      return true;
    } catch (e) {
      debugPrint('Error updating event in Firestore: $e');
      return false;
    }
  }

  /// Helper method to generate a space ID from organizer name
  static String _generateSpaceId(String organizerName) {
    // Normalize the name (lowercase, remove special chars)
    final normalized = organizerName
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');

    return 'space_$normalized';
  }

  /// Updates the last sync time in Firestore
  static Future<void> _updateLastSyncTime() async {
    try {
      // Update the last sync timestamp in Firestore
      final metadataRef =
          FirebaseFirestore.instance.collection('metadata').doc('rss_sync');
      await metadataRef.set({
        firestoreLastSyncKey: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('Updated last sync timestamp in Firestore');
    } catch (e) {
      debugPrint('Error updating last sync time: $e');
    }
  }

  /// Background fetch for events without blocking UI
  static Future<void> _fetchEventsFromNetworkInBackground() async {
    try {
      debugPrint('Starting background fetch of events from RSS...');
      final events = await _fetchEventsFromNetwork();

      // Save to Firestore
      await syncEventsWithFirestore(events);

      // Update sync metadata
      await FirebaseFirestore.instance
          .collection('metadata')
          .doc('rss_sync')
          .set({
        'last_sync_timestamp': FieldValue.serverTimestamp(),
        'status': 'success',
        'processed_count': events.length,
        'lost_count': 0,
        'total_count': events.length,
      }, SetOptions(merge: true));

      debugPrint('Background fetch completed with ${events.length} events');
    } catch (e) {
      debugPrint('Error in background event fetch: $e');
    }
  }

  /// Gets all RSS events and syncs them to Firestore - limited to once per week
  static Future<Map<String, dynamic>> resyncAllRssEvents() async {
    try {
      // Check if we've synced in the last week to prevent multiple syncs
      final metadataRef =
          FirebaseFirestore.instance.collection('metadata').doc('rss_sync');
      final metadataDoc = await metadataRef.get();

      if (metadataDoc.exists &&
          metadataDoc.data()?['last_sync_timestamp'] != null) {
        final timestamp =
            metadataDoc.data()?['last_sync_timestamp'] as Timestamp;
        final lastSync = timestamp.toDate();
        final now = DateTime.now();

        // If sync happened less than 7 days ago, skip
        if (now.difference(lastSync).inDays < 7) {
          debugPrint(
              'Skipping RSS sync - already performed in the last week (${now.difference(lastSync).inDays} days ago)');
          return {
            'events_processed': 0,
            'spaces_updated': 0,
            'error': 0,
            'skipped': true,
            'reason': 'Already synced in the last week'
          };
        }
      }

      debugPrint('Starting full RSS event resync...');

      final results = <String, dynamic>{
        'total': 0,
        'processed': 0,
        'lost': 0,
      };

      // First, check if we already have spaces created
      final firestore = FirebaseFirestore.instance;
      final spaceTypes = SpaceEventManager.getAllSpaceTypes();

      debugPrint('======= CHECKING SPACES BEFORE SYNC =======');
      for (final spaceType in spaceTypes) {
        final spacesSnapshot = await firestore
            .collection('spaces')
            .doc(spaceType)
            .collection('spaces')
            .get();

        debugPrint('Found ${spacesSnapshot.docs.length} spaces in $spaceType');
      }
      debugPrint('======= END SPACES CHECK =======');

      // Get events from RSS feed - using the existing method
      try {
        debugPrint('Fetching events from RSS feed');
        final events = await _fetchEventsFromNetwork();

        if (events.isNotEmpty) {
          debugPrint('Retrieved ${events.length} events from RSS feed');
          results['total'] = events.length;

          // Detailed event info
          debugPrint('======= EVENT DETAILS =======');
          for (int i = 0; i < min(5, events.length); i++) {
            final event = events[i];
            debugPrint('Event ${i + 1}: ${event.title}');
            debugPrint('  ID: ${event.id}');
            debugPrint('  Organizer: ${event.organizerName}');
          }
          debugPrint('======= END EVENT DETAILS =======');

          // Sync events to spaces using SpaceEventManager
          debugPrint('Syncing ${events.length} events to spaces...');
          final processedCount =
              await SpaceEventManager.syncEventsToSpaces(events);

          results['processed'] = processedCount;
        }
      } catch (e) {
        debugPrint('Error fetching from RSS feed: $e');
      }

      // Calculate how many were "lost" (saved to lost_events)
      try {
        // Get count of events in lost_events collection
        final lostEventsSnapshot =
            await FirebaseFirestore.instance.collection('lost_events').get();

        results['lost'] = lostEventsSnapshot.docs.length;

        // Check spaces again after sync
        debugPrint('======= CHECKING SPACES AFTER SYNC =======');
        for (final spaceType in spaceTypes) {
          final spacesSnapshot = await firestore
              .collection('spaces')
              .doc(spaceType)
              .collection('spaces')
              .get();

          debugPrint(
              'Found ${spacesSnapshot.docs.length} spaces in $spaceType after sync');

          // Count events in each space
          int totalEvents = 0;
          for (final spaceDoc in spacesSnapshot.docs) {
            final spaceId = spaceDoc.id;
            final eventsSnapshot = await firestore
                .collection('spaces')
                .doc(spaceType)
                .collection('spaces')
                .doc(spaceId)
                .collection('events')
                .get();

            totalEvents += eventsSnapshot.docs.length;
          }

          debugPrint('Total events in $spaceType after sync: $totalEvents');
        }
        debugPrint('======= END SPACES CHECK =======');
      } catch (e) {
        debugPrint('Error counting lost events: $e');
      }

      debugPrint('RSS resync complete: ${results['total']} total events, '
          '${results['processed']} processed, ${results['lost']} in lost_events');

      // Update sync metadata
      await _updateSyncMetadata(results);

      return results;
    } catch (e) {
      debugPrint('Error in resyncAllRssEvents: $e');
      return {'total': 0, 'processed': 0, 'lost': 0, 'error': 1};
    }
  }

  /// Update sync metadata for RSS resync
  static Future<void> _updateSyncMetadata(Map<String, dynamic> results) async {
    try {
      await FirebaseFirestore.instance
          .collection('metadata')
          .doc('rss_sync')
          .set({
        'last_sync_timestamp': FieldValue.serverTimestamp(),
        'status': 'success',
        'processed_count': results['processed'],
        'lost_count': results['lost'],
        'total_count': results['total'],
        'sync_type': 'manual_resync',
      }, SetOptions(merge: true));

      debugPrint('Updated sync metadata successfully');
    } catch (e) {
      debugPrint('Error updating sync metadata: $e');
    }
  }

  /// Migrates lost events to appropriate spaces
  /// This creates spaces for events if they don't exist already
  static Future<Map<String, dynamic>> migrateLostEventsToSpaces() async {
    debugPrint('Starting migration of lost events to spaces...');
    final result = await SpaceEventManager.migrateLostEventsToSpaces();

    // Update metadata to record this migration operation
    try {
      await FirebaseFirestore.instance
          .collection('metadata')
          .doc('lost_events_migration')
          .set({
        'last_run': FieldValue.serverTimestamp(),
        'total_processed': result['total'],
        'migrated': result['migrated'],
        'failed': result['failed'],
        'spaces_created': result['spaces_created'],
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating migration metadata: $e');
    }

    // Trigger a re-sync to make sure all events are in the right places
    if ((result['migrated'] ?? 0) > 0) {
      debugPrint('Triggering a re-sync to update event placements');
      await resyncAllRssEvents();
    }

    return result;
  }

  /// Batch sync all events to Firestore in one operation
  /// This is an alias for resyncAllRssEvents for backward compatibility
  static Future<Map<String, dynamic>> batchSyncAllEventsToFirestore() async {
    debugPrint(
        'batchSyncAllEventsToFirestore called - forwarding to resyncAllRssEvents');
    return await resyncAllRssEvents();
  }

  // Helper to schedule weekly sync without blocking
  static void _scheduleWeeklySync() {
    // Run sync in the background
    Future.delayed(const Duration(seconds: 2), () async {
      try {
        await resyncAllRssEvents();
      } catch (e) {
        debugPrint('Error in weekly RSS sync: $e');
      }
    });
  }
}
