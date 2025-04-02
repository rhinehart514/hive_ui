import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';
import 'package:xml/xml.dart';
import 'calendar_integration_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for handling event-related operations
class EventService {
  /// Cache key for storing events in shared preferences
  static const String _cacheKey = 'events_cache';
  static const String _lastFetchTimestampKey = 'events_last_fetch';
  static const String _rsvpStatusKey = 'events_rsvp_status';
  static const String _userEventsKey = 'user_created_events';

  /// In-memory cache of events
  static final List<Event> _cachedEvents = [];

  /// In-memory cache of RSVP status
  static final Map<String, bool> _rsvpStatusCache = {};

  /// Timeout duration for cache
  static const Duration _cacheTimeout = Duration(hours: 3);

  /// URL endpoints for UB events
  static const String rssFeedUrl = 'https://calendar.buffalo.edu/calendar.xml';

  /// We could add more URL sources here in the future

  /// Returns all events, potentially fetching them if needed
  static Future<List<Event>> getEvents({
    bool forceRefresh = false,
    bool sortByDate = true,
  }) async {
    try {
      /// Check if we have valid cache
      final bool needsRefresh = forceRefresh || await _isCacheStale();

      if (_cachedEvents.isEmpty || needsRefresh) {
        /// Load from cache first to return something quickly
        await _loadEventsFromCache();

        /// Then refresh asynchronously if needed
        if (needsRefresh) {
          _refreshEventsAsync();
        }
      }

      // Filter out past events that have already ended
      final now = DateTime.now();
      debugPrint('EventService: Filtering ${_cachedEvents.length} cached events to remove past events');
      
      final filteredEvents = _cachedEvents.where((event) { 
        final isUpcoming = event.endDate.isAfter(now);
        
        if (!isUpcoming) {
          // Log details about filtered events
          debugPrint('EventService: ⚠️ Filtering out past event: "${event.title}" - ended at ${event.endDate}');
        } else {
          // Log details about kept events 
          debugPrint('EventService: ✅ Keeping upcoming event: "${event.title}" - ends at ${event.endDate}');
        }
        
        return isUpcoming;
      }).toList();
      
      debugPrint('EventService: Filtered out ${_cachedEvents.length - filteredEvents.length} past events. Keeping ${filteredEvents.length} upcoming events.');

      if (sortByDate) {
        filteredEvents.sort((a, b) => a.startDate.compareTo(b.startDate));
      }

      /// Return filtered events only
      return filteredEvents;
    } catch (e) {
      debugPrint('Error fetching events: $e');

      /// If error occurs, try to return cached events if available, but still filter past events
      final now = DateTime.now();
      final filteredCachedEvents = _cachedEvents.where((event) => event.endDate.isAfter(now)).toList();
      debugPrint('EventService: Fallback - filtered ${_cachedEvents.length - filteredCachedEvents.length} past events from cache');
      return filteredCachedEvents;
    }
  }

  /// Refreshes events from all sources
  static Future<List<Event>> refreshEvents() async {
    try {
      final List<Event> newEvents = [];

      /// Fetch from RSS feed
      final List<Event> rssEvents = await _fetchEventsFromRss();
      newEvents.addAll(rssEvents);

      /// Additional sources could be added here

      /// Process and deduplicate events before storing
      final List<Event> processedEvents =
          _processAndDeduplicateEvents(newEvents);

      /// Save to memory and persistent cache
      _cachedEvents.clear();
      _cachedEvents.addAll(processedEvents);
      await _saveEventsToCache(processedEvents);

      return processedEvents;
    } catch (e) {
      debugPrint('Error refreshing events: $e');
      rethrow;

      /// Let the caller handle the error
    }
  }

  /// Check if the cache is stale based on last fetch timestamp
  static Future<bool> _isCacheStale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastFetchTimestamp = prefs.getInt(_lastFetchTimestampKey);

      if (lastFetchTimestamp == null) {
        return true;
      }

      final lastFetchTime =
          DateTime.fromMillisecondsSinceEpoch(lastFetchTimestamp);
      final now = DateTime.now();

      return now.difference(lastFetchTime) > _cacheTimeout;
    } catch (e) {
      debugPrint('Error checking cache staleness: $e');
      return true;
    }
  }

  /// Update the timestamp of the last fetch
  static Future<void> _updateLastFetchTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          _lastFetchTimestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error updating last fetch timestamp: $e');
    }
  }

  /// Load events from shared preferences cache
  static Future<List<Event>> _loadEventsFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cacheKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> eventsJson = jsonDecode(jsonString);
      final List<Event> events =
          eventsJson.map((e) => Event.fromJson(e)).toList();

      /// Update memory cache
      _cachedEvents.clear();
      _cachedEvents.addAll(events);

      return events;
    } catch (e) {
      debugPrint('Error loading events from cache: $e');
      return [];
    }
  }

  /// Save events to shared preferences cache
  static Future<void> _saveEventsToCache(List<Event> events) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(events.map((e) => e.toJson()).toList());
      await prefs.setString(_cacheKey, jsonString);
      await _updateLastFetchTimestamp();
    } catch (e) {
      debugPrint('Error saving events to cache: $e');
    }
  }

  /// Non-blocking refresh for better UX
  static Future<void> _refreshEventsAsync() async {
    try {
      await refreshEvents();
    } catch (e, stackTrace) {
      debugPrint(
          'Background refresh error in EventService\nError: $e\nStack trace: $stackTrace');
      // Don't rethrow as this is a background operation
    }
  }

  /// Fetch events from RSS feed
  static Future<List<Event>> _fetchEventsFromRss() async {
    try {
      final http.Response response = await http.get(Uri.parse(rssFeedUrl));

      if (response.statusCode != 200) {
        throw Exception('Failed to load RSS feed: ${response.statusCode}');
      }

      final String xmlData = response.body;

      /// Try to parse XML data
      final document = XmlDocument.parse(xmlData);
      final items = document.findAllElements('item');

      final List<Event> events = [];

      for (final item in items) {
        try {
          final title = _getXmlElementText(item, 'title');
          final guid = _getXmlElementText(item, 'guid');

          /// Skip if no title or guid (these are required)
          if (title.isEmpty || guid.isEmpty) continue;

          final link = _getXmlElementText(item, 'link');
          final description = _getXmlElementText(item, 'description');

          /// Parse dates
          var pubDate = _getXmlElementText(item, 'pubDate');
          DateTime? publishDate;
          if (pubDate.isNotEmpty) {
            try {
              publishDate =
                  DateFormat('EEE, dd MMM yyyy HH:mm:ss Z').parse(pubDate);
            } catch (e) {
              /// Try alternate format
              try {
                publishDate = DateTime.parse(pubDate);
              } catch (e2) {
                publishDate = null;
              }
            }
          }

          /// Extract custom fields for events
          final category = _getXmlElementTextWithFallback(
              item, ['category', 'x-trumba:ealcategories'], 'General');

          final location = _getXmlElementTextWithFallback(
              item, ['x-trumba:location', 'location'], '');

          final organizerName = _getXmlElementTextWithFallback(
              item,
              ['x-trumba:organization', 'x-trumba:organizername', 'organizer'],
              'University at Buffalo');

          final organizerEmail = _getXmlElementTextWithFallback(
              item, ['x-trumba:organizeremail', 'email'], '');

          /// Try to extract start and end dates from special fields
          DateTime? startDate;
          DateTime? endDate;
          final startDateStr = _getXmlElementTextWithFallback(
              item, ['x-trumba:begintime', 'startdate', 'dtstart'], '');
          final endDateStr = _getXmlElementTextWithFallback(
              item, ['x-trumba:endtime', 'enddate', 'dtend'], '');

          /// Helper method to get date format strings
          List<String> getDateFormats() {
            return [
              'yyyy-MM-ddTHH:mm:ssZ', // ISO format with timezone
              'yyyy-MM-dd HH:mm:ss', // SQL format
              'yyyy-MM-dd', // Simple date
              'EEE, dd MMM yyyy HH:mm:ss Z', // RSS format
            ];
          }

          /// Try different format strategies based on XML source
          if (startDateStr.isNotEmpty) {
            try {
              /// Try multiple formats
              final formats = getDateFormats();

              for (final format in formats) {
                try {
                  startDate = DateFormat(format).parse(startDateStr);
                  break;
                } catch (e) {
                  /// Continue to next format
                }
              }

              /// Last resort - try direct parsing
              startDate ??= DateTime.parse(startDateStr);
            } catch (e) {
              /// If all parsing fails, fall back to published date
              startDate = publishDate;
            }
          } else {
            /// If no explicit start date, use publish date
            startDate = publishDate;
          }

          /// Similar approach for end date
          if (endDateStr.isNotEmpty) {
            try {
              final formats = getDateFormats();

              for (final format in formats) {
                try {
                  endDate = DateFormat(format).parse(endDateStr);
                  break;
                } catch (e) {
                  /// Continue to next format
                }
              }

              /// Last resort - try direct parsing
              endDate ??= DateTime.parse(endDateStr);
            } catch (e) {
              /// If all parsing fails, set end date to start date + 1 hour
              endDate = startDate?.add(const Duration(hours: 1));
            }
          } else {
            /// If no explicit end date, use start date + 1 hour
            endDate = startDate?.add(const Duration(hours: 1));
          }

          /// Clean up the title for better display
          final cleanTitle = _cleanEventTitle(title);

          /// Refine event category for easier organization
          final refinedCategory =
              _refineEventCategory(category, title, description);

          /// Refine organizer name for better organization grouping
          final refinedOrganizerName =
              _refineOrganizerName(organizerName, title, description);

          /// Skip events that we determine are not from real organizations
          if (!_isLikelyFromRealOrganization(
              refinedOrganizerName, title, description)) {
            continue;
          }

          /// Create the event and add to list
          final event = Event(
            id: guid,
            title: cleanTitle,
            description: description,
            startDate: startDate ?? DateTime.now(),
            endDate: endDate ?? DateTime.now().add(const Duration(hours: 1)),
            location: location,
            link: link,
            category: refinedCategory,
            organizerName: refinedOrganizerName,
            organizerEmail: organizerEmail,
            imageUrl: _extractImageUrlFromDescription(description),
            status: 'confirmed', // Default status
          );

          events.add(event);
        } catch (e) {
          /// Skip this event on error
          debugPrint('Error parsing event: $e');
          continue;
        }
      }

      return events;
    } catch (e) {
      debugPrint('Error fetching events from RSS: $e');
      return [];
    }
  }

  /// Determines if an event is likely from a real organization rather than a generic event
  static bool _isLikelyFromRealOrganization(
      String organizerName, String title, String description) {
    /// Generic organizers that should be scrutinized more carefully
    final genericOrganizers = [
      'university at buffalo',
      'ub',
      'buffalo',
      'suny',
      'university',
      'student association',
      'campus life',
      'student life',
      'events',
    ];

    /// Skip extremely generic organizerName when the title is also generic
    if (genericOrganizers.contains(organizerName.toLowerCase()) &&
        !_containsOrganizationIndicator(title) &&
        !_containsOrganizationIndicator(description)) {
      return false;
    }

    /// Skip events that are clearly just deadlines or announcements
    if (title.toLowerCase().contains('deadline') ||
        title.toLowerCase().contains('reminder') ||
        title.toLowerCase().contains('announcement')) {
      return false;
    }

    /// Skip academic calendar events
    if (title.toLowerCase().contains('last day to') ||
        title.toLowerCase().contains('first day of') ||
        title.contains('registration')) {
      return false;
    }

    return true;
  }

  /// Check if text contains organization indicators
  static bool _containsOrganizationIndicator(String text) {
    final organizationIndicators = [
      'club',
      'association',
      'society',
      'organization',
      'committee',
      'council',
      'board',
      'fraternity',
      'sorority',
      'department of',
      'school of',
      'college of',
      'team',
      'chapter',
      'students for',
    ];

    for (final indicator in organizationIndicators) {
      if (text.toLowerCase().contains(indicator)) {
        return true;
      }
    }

    return false;
  }

  /// Helper to safely extract element text with check for null
  static String _getXmlElementText(XmlElement item, String elementName) {
    try {
      final element = item.findElements(elementName).firstOrNull;
      return element?.innerText ?? '';
    } catch (e) {
      return '';
    }
  }

  /// Helper to try multiple element names with a fallback
  static String _getXmlElementTextWithFallback(
      XmlElement item, List<String> elementNames, String fallback) {
    for (final name in elementNames) {
      final value = _getXmlElementText(item, name);
      if (value.isNotEmpty) {
        return value;
      }
    }
    return fallback;
  }

  /// Extract image URL from HTML description if available
  static String _extractImageUrlFromDescription(String description) {
    try {
      /// Look for image tag in description
      final imgRegExp = RegExp(r'<img[^>]+src="([^">]+)"[^>]*>');
      final match = imgRegExp.firstMatch(description);
      if (match != null && match.groupCount >= 1) {
        return match.group(1) ?? '';
      }

      /// Also try looking for image URL in a background style
      // Use a simpler pattern to avoid RegExp issues
      if (description.contains('background') && description.contains('url(')) {
        // Manual extraction as a fallback approach
        final start = description.indexOf('url(') + 4;
        final end = description.indexOf(')', start);
        if (end > start) {
          String url = description.substring(start, end);
          // Clean quotes if present
          url = url.replaceAll('"', '').replaceAll("'", '').trim();
          return url;
        }
      }
    } catch (e) {
      /// Ignore errors in image extraction
    }

    return '';
  }

  /// Cleans up event titles for better display
  static String _cleanEventTitle(String title) {
    /// Remove excessive whitespace
    String cleaned = title.trim().replaceAll(RegExp(r'\s+'), ' ');

    /// Remove "UB" or "University at Buffalo" prefix if present
    final prefixes = [
      'UB: ',
      'UB - ',
      'University at Buffalo: ',
      'University at Buffalo - ',
    ];

    for (final prefix in prefixes) {
      if (cleaned.startsWith(prefix)) {
        cleaned = cleaned.substring(prefix.length).trim();
        break;
      }
    }

    return cleaned;
  }

  /// Refines the category for better organization
  static String _refineEventCategory(
      String originalCategory, String title, String description) {
    /// Default mappings for common categories
    final categoryMappings = {
      'student life': 'Student Life',
      'general': 'General',
      'academic': 'Academic',
      'lecture': 'Academic',
      'conference': 'Academic',
      'workshop': 'Educational',
      'seminar': 'Educational',
      'athletics': 'Sports',
      'sports': 'Sports',
      'recreation': 'Sports',
      'arts': 'Arts & Culture',
      'culture': 'Arts & Culture',
      'music': 'Arts & Culture',
      'performance': 'Arts & Culture',
      'theatre': 'Arts & Culture',
      'exhibit': 'Arts & Culture',
      'social': 'Social',
      'networking': 'Social',
      'career': 'Career',
      'job': 'Career',
      'professional': 'Career',
      'volunteer': 'Community Service',
      'service': 'Community Service',
      'health': 'Health & Wellness',
      'wellness': 'Health & Wellness',
      'fitness': 'Health & Wellness',
      'religious': 'Religious & Spiritual',
      'spiritual': 'Religious & Spiritual',
      'faith': 'Religious & Spiritual',
      'club': 'Student Organizations',
      'organization': 'Student Organizations',
      'fraternity': 'Greek Life',
      'sorority': 'Greek Life',
      'greek': 'Greek Life',
      'diversity': 'Diversity & Inclusion',
      'inclusion': 'Diversity & Inclusion',
      'equity': 'Diversity & Inclusion',
      'international': 'International',
      'global': 'International',
      'food': 'Food & Dining',
      'dining': 'Food & Dining',
      'tech': 'Technology',
      'technology': 'Technology',
      'engineering': 'Engineering',
    };

    /// Try to find a matching category from the original
    final lowerCategory = originalCategory.toLowerCase();
    for (final entry in categoryMappings.entries) {
      if (lowerCategory.contains(entry.key)) {
        return entry.value;
      }
    }

    /// If no match in original category, try to infer from title or description
    final lowerTitle = title.toLowerCase();
    final lowerDescription = description.toLowerCase();
    final combinedText = '$lowerTitle $lowerDescription';

    for (final entry in categoryMappings.entries) {
      if (combinedText.contains(entry.key)) {
        return entry.value;
      }
    }

    /// Default category if nothing matches
    return 'General';
  }

  /// Refines the organizer name for better organization grouping
  static String _refineOrganizerName(
      String originalOrganizer, String title, String description) {
    /// Skip if already a non-generic name
    if (originalOrganizer != 'University at Buffalo' &&
        originalOrganizer != 'UB' &&
        originalOrganizer != 'Buffalo') {
      return originalOrganizer.trim();
    }

    /// Extract organizer from title if possible
    if (title.contains(':')) {
      final parts = title.split(':');
      if (parts[0].length > 3 &&
          !parts[0].toLowerCase().contains('ub') &&
          !parts[0].toLowerCase().contains('university at buffalo')) {
        return parts[0].trim();
      }
    }

    /// Check for "presents" pattern
    final presentsPattern = RegExp(r"(.*?)\s+presents\b", caseSensitive: false);
    final presentsMatch = presentsPattern.firstMatch(title);
    if (presentsMatch != null && presentsMatch.group(1)!.length > 3) {
      return presentsMatch.group(1)!.trim();
    }

    /// Try to extract from description - look for "organized by" or similar patterns
    final organizerPattern = RegExp(
        r"(?:organized|presented|hosted|sponsored)\s+by\s+(.*?)(?:\.|\,|\;|and|\n)",
        caseSensitive: false);
    final match = organizerPattern.firstMatch(description);
    if (match != null &&
        match.group(1)!.length > 3 &&
        !match.group(1)!.toLowerCase().contains('university at buffalo')) {
      /// Limit to reasonable organizer name length
      final orgName = match.group(1)!.trim();
      if (orgName.split(' ').length <= 6) {
        return orgName;
      }
    }

    /// Default back to original
    return originalOrganizer;
  }

  /// Process and deduplicate events
  static List<Event> _processAndDeduplicateEvents(List<Event> events) {
    /// Track seen event IDs to avoid duplicates
    final Set<String> seenIds = {};
    final List<Event> uniqueEvents = [];

    for (final event in events) {
      /// Skip empty or invalid events
      if (event.title.isEmpty || event.id.isEmpty) {
        continue;
      }

      /// Skip older events (more than 7 days in the past)
      final now = DateTime.now();
      if (event.startDate.isBefore(now.subtract(const Duration(days: 7)))) {
        continue;
      }

      /// Skip if we've seen this ID
      if (seenIds.contains(event.id)) {
        continue;
      }

      /// Add to tracking and result
      seenIds.add(event.id);
      uniqueEvents.add(event);
    }

    return uniqueEvents;
  }

  /// RSVP to an event
  static Future<bool> rsvpToEvent(String eventId, bool attending) async {
    try {
      // Get current user ID from Firebase Auth
      final FirebaseAuth auth = FirebaseAuth.instance;
      final String? userId = auth.currentUser?.uid;
      
      if (userId == null) {
        debugPrint('Cannot RSVP: No authenticated user');
        return false;
      }

      // Update in-memory cache
      _rsvpStatusCache[eventId] = attending;

      // Persist RSVP status to shared preferences
      await _saveRsvpStatus();

      // Use a transaction to ensure data consistency
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      bool success = false;
      
      await firestore.runTransaction((transaction) async {
        // Get event document
        final eventDoc = await transaction.get(
          firestore.collection('events').doc(eventId)
        );
        
        // Get user document
        final userDoc = await transaction.get(
          firestore.collection('users').doc(userId)
        );

        if (attending) {
          // Add user to attendees
          transaction.update(
            firestore.collection('events').doc(eventId),
            {
              'attendees': FieldValue.arrayUnion([userId]),
              'rsvpCount': FieldValue.increment(1),
              'updatedAt': FieldValue.serverTimestamp(),
            },
          );
          
          // Add event to user's saved events
          transaction.update(
            firestore.collection('users').doc(userId),
            {
              'savedEvents': FieldValue.arrayUnion([eventId]),
              'eventCount': FieldValue.increment(1),
              'updatedAt': FieldValue.serverTimestamp(),
            },
          );
        } else {
          // Remove user from attendees
          transaction.update(
            firestore.collection('events').doc(eventId),
            {
              'attendees': FieldValue.arrayRemove([userId]),
              'rsvpCount': FieldValue.increment(-1),
              'updatedAt': FieldValue.serverTimestamp(),
            },
          );
          
          // Remove event from user's saved events
          transaction.update(
            firestore.collection('users').doc(userId),
            {
              'savedEvents': FieldValue.arrayRemove([eventId]),
              'eventCount': FieldValue.increment(-1),
              'updatedAt': FieldValue.serverTimestamp(),
            },
          );
        }
        
        success = true;
        return success;
      });
      
      return success;
    } catch (e) {
      debugPrint('Error RSVPing to event: $e');
      return false;
    }
  }
  
  /// Helper method to get space ID for an event
  static String? _getSpaceIdForEvent(Event event) {
    if (event.organizerName.isEmpty) return null;
    
    // Generate space ID from organizer name
    return 'space_${event.organizerName.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim().replaceAll(RegExp(r'\s+'), '_')}';
  }
  
  /// Update user's RSVP status in their profile document
  static Future<void> _updateUserRsvpStatus(String userId, String eventId, bool attending) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final userRef = firestore.collection('users').doc(userId);
      
      if (attending) {
        // Add event to user's rsvpedEvents list
        await userRef.update({
          'rsvpedEvents': FieldValue.arrayUnion([eventId]),
        });
      } else {
        // Remove event from user's rsvpedEvents list
        await userRef.update({
          'rsvpedEvents': FieldValue.arrayRemove([eventId]),
        });
      }
    } catch (e) {
      debugPrint('Error updating user RSVP status: $e');
    }
  }

  /// Get RSVP status for an event
  static Future<bool> getEventRsvpStatus(String eventId) async {
    try {
      // Get current user ID from Firebase Auth
      final FirebaseAuth auth = FirebaseAuth.instance;
      final String? userId = auth.currentUser?.uid;
      
      if (userId == null) {
        debugPrint('Cannot get RSVP status: No authenticated user');
        return false;
      }
      
      // Try to get RSVP status from Firestore first (more accurate)
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      
      // Check if user is in the event's attendees list
      final eventDoc = await firestore.collection('events').doc(eventId).get();
      if (eventDoc.exists) {
        final data = eventDoc.data() as Map<String, dynamic>;
        final List<dynamic> attendees = data['attendees'] as List<dynamic>? ?? [];
        if (attendees.contains(userId)) {
          // Update local cache for faster access next time
          _rsvpStatusCache[eventId] = true;
          await _saveRsvpStatus();
          return true;
        }
      }
      
      // Also check user's rsvpedEvents list in their profile
      final userDoc = await firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final List<dynamic> rsvpedEvents = userData['rsvpedEvents'] as List<dynamic>? ?? [];
        if (rsvpedEvents.contains(eventId)) {
          // Update local cache for faster access next time
          _rsvpStatusCache[eventId] = true;
          await _saveRsvpStatus();
          return true;
        }
      }
      
      // Fall back to checking in-memory cache next
      if (_rsvpStatusCache.containsKey(eventId)) {
        return _rsvpStatusCache[eventId]!;
      }

      // Try to load from shared preferences
      await _loadRsvpStatus();

      // Return status or default to false
      return _rsvpStatusCache[eventId] ?? false;
    } catch (e) {
      debugPrint('Error checking RSVP status: $e');
      
      // Fall back to local cache in case of error
      if (_rsvpStatusCache.containsKey(eventId)) {
        return _rsvpStatusCache[eventId]!;
      }
      
      await _loadRsvpStatus();
      return _rsvpStatusCache[eventId] ?? false;
    }
  }

  /// Get all events user has RSVP'd to
  static Future<List<Event>> getRsvpedEvents() async {
    try {
      // Get current user ID from Firebase Auth
      final FirebaseAuth auth = FirebaseAuth.instance;
      final String? userId = auth.currentUser?.uid;
      
      if (userId == null) {
        debugPrint('Cannot get RSVPed events: No authenticated user');
        return [];
      }
      
      // Get RSVPed events from Firestore
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final List<String> rsvpedEventIds = [];
      final List<Event> rsvpedEvents = [];
      
      // Check user's rsvpedEvents list in their profile
      final userDoc = await firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final List<dynamic> userRsvpedEvents = userData['rsvpedEvents'] as List<dynamic>? ?? [];
        rsvpedEventIds.addAll(userRsvpedEvents.map((e) => e.toString()));
      }
      
      // If we have rsvpedEventIds, fetch the events
      if (rsvpedEventIds.isNotEmpty) {
        // We need to batch the queries as Firestore supports max 10 items in whereIn
        const int batchSize = 10;
        for (int i = 0; i < rsvpedEventIds.length; i += batchSize) {
          final int end = (i + batchSize < rsvpedEventIds.length) 
              ? i + batchSize 
              : rsvpedEventIds.length;
          final List<String> batchIds = rsvpedEventIds.sublist(i, end);
          
          final querySnapshot = await firestore
              .collection('events')
              .where(FieldPath.documentId, whereIn: batchIds)
              .get();
              
          for (final doc in querySnapshot.docs) {
            try {
              final eventData = doc.data();
              final event = Event.fromJson({'id': doc.id, ...eventData});
              rsvpedEvents.add(event);
            } catch (e) {
              debugPrint('Error parsing event ${doc.id}: $e');
            }
          }
        }
      }
      
      // Look for events where the user is in attendees field (as backup)
      final attendeeQuerySnapshot = await firestore
          .collection('events')
          .where('attendees', arrayContains: userId)
          .get();
      
      for (final doc in attendeeQuerySnapshot.docs) {
        // Check if we already have this event
        if (!rsvpedEvents.any((e) => e.id == doc.id)) {
          try {
            final eventData = doc.data();
            final event = Event.fromJson({'id': doc.id, ...eventData});
            rsvpedEvents.add(event);
            
            // Also update user's rsvpedEvents list if needed
            if (!rsvpedEventIds.contains(doc.id)) {
              await firestore.collection('users').doc(userId).update({
                'rsvpedEvents': FieldValue.arrayUnion([doc.id]),
              });
            }
          } catch (e) {
            debugPrint('Error parsing event ${doc.id}: $e');
          }
        }
      }
      
      // Update local cache with server data for future use
      for (final event in rsvpedEvents) {
        _rsvpStatusCache[event.id] = true;
      }
      await _saveRsvpStatus();
      
      // Ensure RSVP status is loaded from local as fallback
      await _loadRsvpStatus();
      
      // Get all cached events
      final allEvents = await getEvents();
      
      // Combine results - server events + local events from cache
      final List<Event> finalResult = [...rsvpedEvents];
      
      // Add events from local cache that are not already in the result
      for (final event in allEvents) {
        if (_rsvpStatusCache[event.id] == true && 
            !finalResult.any((e) => e.id == event.id)) {
          finalResult.add(event);
        }
      }
      
      return finalResult;
    } catch (e) {
      debugPrint('Error getting RSVPed events: $e');
      
      // Fall back to local cache if there's an error
      await _loadRsvpStatus();
      
      // Get all events
      final allEvents = await getEvents();
      
      // Filter events based on RSVP status
      return allEvents
          .where((event) => _rsvpStatusCache[event.id] == true)
          .toList();
    }
  }

  /// Save user event to local storage
  static Future<bool> saveUserEvent(Event event) async {
    try {
      // Add event to in-memory cache if not already there
      if (!_cachedEvents.any((e) => e.id == event.id)) {
        _cachedEvents.add(event);
      } else {
        // Update the existing event
        final index = _cachedEvents.indexWhere((e) => e.id == event.id);
        if (index >= 0) {
          _cachedEvents[index] = event;
        }
      }

      // Save to local storage
      await _saveUserEvents();

      // Also update the main cache
      await _saveEventsToCache(_cachedEvents);

      return true;
    } catch (e) {
      debugPrint('Error saving user event: $e');
      return false;
    }
  }

  /// Private method to load RSVP status from shared preferences
  static Future<void> _loadRsvpStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rsvpJson = prefs.getString(_rsvpStatusKey);

      if (rsvpJson != null && rsvpJson.isNotEmpty) {
        final Map<String, dynamic> rsvpData = jsonDecode(rsvpJson);

        // Clear existing cache and populate from storage
        _rsvpStatusCache.clear();
        rsvpData.forEach((key, value) {
          if (value is bool) {
            _rsvpStatusCache[key] = value;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading RSVP status: $e');
    }
  }

  /// Private method to save RSVP status to shared preferences
  static Future<void> _saveRsvpStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rsvpJson = jsonEncode(_rsvpStatusCache);
      await prefs.setString(_rsvpStatusKey, rsvpJson);
    } catch (e) {
      debugPrint('Error saving RSVP status: $e');
    }
  }

  /// Private method to save user created events
  static Future<void> _saveUserEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Filter out only user-created events
      final userEvents = _cachedEvents.where((e) => e.isUserCreated).toList();

      // Save as JSON
      final eventsJson = userEvents.map((e) => e.toJson()).toList();
      await prefs.setString(_userEventsKey, jsonEncode(eventsJson));
    } catch (e) {
      debugPrint('Error saving user events: $e');
    }
  }

  /// Add to calendar without RSVPing
  static Future<bool> addEventToCalendar(String eventId) async {
    try {
      // Find the event
      final event = _findEventById(eventId);

      if (event != null) {
        return await CalendarIntegrationService.addEventToCalendar(event);
      }

      return false;
    } catch (e) {
      debugPrint('Error adding event to calendar: $e');
      return false;
    }
  }

  /// Repost an event
  static Future<bool> repostEvent(String eventId) async {
    try {
      /// Simulate network delay
      await Future.delayed(const Duration(milliseconds: 300));

      /// In a real app, this would make an API call
      return true;
    } catch (e) {
      debugPrint('Error reposting event: $e');
      return false;
    }
  }

  /// Get events by user ID (for profile page)
  static Future<List<Event>> getEventsByUser(String userId) async {
    try {
      /// Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      /// In a real app, this would make an API call
      return [];
    } catch (e) {
      debugPrint('Error fetching user events: $e');
      return [];
    }
  }

  /// Helper method to find an event by ID
  static Event? _findEventById(String eventId) {
    try {
      return _cachedEvents.firstWhere((e) => e.id == eventId);
    } catch (e) {
      // Event not found
      return null;
    }
  }
}
