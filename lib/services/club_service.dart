import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/club.dart';
import '../models/event.dart';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClubService {
  static const String _clubPrefsKey = 'clubs_cache';
  static const String _lastFetchTimestampKey = 'clubs_last_fetch';
  static const String _eventsCacheKey = 'events_cache';
  static const Duration _cacheValidDuration = Duration(hours: 6);
  static const String _clubCollection = 'clubs';
  static const int _pageSize = 20;

  // In-memory cache
  static final Map<String, Club> _clubCache = {};
  static bool _isInitialized = false;
  static DateTime? _lastFirestoreSync;

  // Firestore reference
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize the service and load cache
  static Future<void> initialize() async {
    if (_isInitialized) return;

    await loadClubsFromCache();
    _isInitialized = true;
  }

  /// Get a club by ID with immediate return from cache
  static Club? getClubById(String id) {
    return _clubCache[id];
  }

  /// Get a club by organizer name with immediate return from cache
  static Club? getClubByOrganizerName(String organizerName) {
    final clubId = Club.createIdFromName(organizerName);
    return _clubCache[clubId];
  }

  /// Get all clubs immediately from cache
  static List<Club> getAllClubs() {
    return _clubCache.values.toList();
  }

  /// Get all clubs with a specific category immediately from cache
  static List<Club> getClubsByCategory(String category) {
    return _clubCache.values
        .where((club) =>
            club.category == category || club.categories.contains(category))
        .toList();
  }

  /// Add a single club to the memory cache and optionally save to persistent cache
  static Future<void> addClubToCache(Club club,
      {bool saveToDisk = false}) async {
    // Add to memory cache
    _clubCache[club.id] = club;

    // Optionally save to persistent cache
    if (saveToDisk) {
      await _saveClubsToCache([..._clubCache.values.toList()]);
    }

    debugPrint('Added club to cache: ${club.name} (${club.id})');
  }

  /// Check if cache needs refreshing and load clubs from network if needed
  /// Returns immediately with cached data and updates later if needed
  static Future<List<Club>> getRefreshedClubs(
      {bool forceRefresh = false}) async {
    // First return whatever we have in cache
    final List<Club> currentClubs = _clubCache.values.toList();

    // Check if cache is stale or forced refresh
    if (forceRefresh || await _isCacheStale()) {
      _refreshClubsAsync();
    }

    return currentClubs;
  }

  /// Loads clubs directly without waiting for events if cache available
  static Future<List<Club>> loadClubs({bool forceRefresh = false}) async {
    await initialize();

    // First check if we have clubs in memory
    if (_clubCache.isNotEmpty && !forceRefresh) {
      // Return the cached clubs immediately
      return _clubCache.values.toList();
    }

    return getRefreshedClubs(forceRefresh: forceRefresh);
  }

  /// Check if our cached data is stale
  static Future<bool> _isCacheStale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastFetchTimestamp = prefs.getInt(_lastFetchTimestampKey);

      if (lastFetchTimestamp == null) return true;

      final lastFetchTime =
          DateTime.fromMillisecondsSinceEpoch(lastFetchTimestamp);
      final now = DateTime.now();

      // Check if cache is older than the valid duration
      return now.difference(lastFetchTime) > _cacheValidDuration;
    } catch (e) {
      debugPrint('Error checking cache staleness: $e');
      return true;
    }
  }

  /// Background refresh without blocking the UI
  static Future<void> _refreshClubsAsync() async {
    try {
      // Try to load from Firestore first (most up-to-date)
      final firestoreClubs = await loadClubsFromFirestore();

      // If we got clubs from Firestore, we're done
      if (firestoreClubs.isNotEmpty) {
        debugPrint('Loaded ${firestoreClubs.length} clubs from Firestore');
        return;
      }

      // If no clubs from Firestore, fall back to event-based generation
      final allEvents = await _loadAllEventsFromCache();

      // Only proceed with event-based generation if we have events
      if (allEvents.isEmpty) {
        // Update timestamp to avoid multiple rapid refreshes
        _updateLastFetchTimestamp();
        return;
      }

      // Refresh from cached events
      await generateClubsFromEvents(allEvents);
    } catch (e, stackTrace) {
      debugPrint(
          'Failed to refresh clubs in background\nError: $e\nStack trace: $stackTrace');
      // Don't rethrow as this is a background operation
    }
  }

  /// Load clubs from Firestore with pagination and caching
  static Future<List<Club>> loadClubsFromFirestore({
    int page = 0,
    bool forceRefresh = false,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      // Check if we should use cache
      if (!forceRefresh && _lastFirestoreSync != null) {
        final timeSinceLastSync =
            DateTime.now().difference(_lastFirestoreSync!);
        if (timeSinceLastSync < const Duration(minutes: 15)) {
          debugPrint(
              'Using in-memory cache for clubs (last synced ${timeSinceLastSync.inMinutes} minutes ago)');
          return _clubCache.values.toList();
        }
      }

      debugPrint(
          'Loading clubs from Firestore using collectionGroup (page: $page, pageSize: $_pageSize)');

      // Use collectionGroup to query all "spaces" collections across all paths
      // This is the single source of truth for all clubs/spaces
      Query query = _firestore
          .collectionGroup('spaces') // Query across all 'spaces' collections
          .orderBy('memberCount', descending: true)
          .limit(_pageSize);

      // Apply cursor-based pagination if a starting document is provided
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      // Execute query
      final querySnapshot = await query.get();

      debugPrint(
          'Loaded ${querySnapshot.docs.length} clubs from Firestore collectionGroup');

      // Convert to Club objects
      final List<Club> clubs = [];

      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;

          // Extract space type from path if possible
          String category = 'general';
          try {
            final pathParts = doc.reference.path.split('/');
            if (pathParts.length > 1) {
              // For hierarchical structure: spaces/{typeCollection}/spaces/{docId}
              category = pathParts.length > 2 ? pathParts[1] : category;
            }
          } catch (e) {
            debugPrint('Error extracting category from path: $e');
          }

          // Ensure data contains category
          if (!data.containsKey('category') && category != 'general') {
            data['category'] = category;
          }

          // Create Club instance
          final club = Club.fromJson(data);

          // Add to result list and in-memory cache
          clubs.add(club);
          _clubCache[club.id] = club;
        } catch (e, stackTrace) {
          debugPrint('Error processing club document: $e\n$stackTrace');
        }
      }

      // Update last sync timestamp
      _lastFirestoreSync = DateTime.now();

      // Save to cache if we got data
      if (clubs.isNotEmpty) {
        await _saveClubsToCache(clubs);
      }

      // Update timestamp to avoid redundant refreshes
      _updateLastFetchTimestamp();

      return clubs;
    } catch (e, stackTrace) {
      debugPrint('Error loading clubs from Firestore: $e\n$stackTrace');
      return [];
    }
  }

  /// Create or update a club in Firestore
  static Future<void> saveClubToFirestore(Club club) async {
    try {
      debugPrint('Saving club ${club.name} to Firestore');

      // Update in Firestore with merge to preserve existing fields
      await _firestore.collection(_clubCollection).doc(club.id).set({
        ...club.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update memory cache
      _clubCache[club.id] = club;

      debugPrint('Club saved to Firestore successfully');
    } catch (e) {
      debugPrint('Error saving club to Firestore: $e');
      rethrow;
    }
  }

  /// Batch update multiple clubs to reduce Firestore writes
  static Future<void> batchUpdateClubs(List<Club> clubs) async {
    if (clubs.isEmpty) return;

    try {
      debugPrint('Batch updating ${clubs.length} clubs in Firestore');

      // Create a batch
      final batch = _firestore.batch();

      // Add each club to the batch
      for (final club in clubs) {
        final docRef = _firestore.collection(_clubCollection).doc(club.id);
        batch.set(
            docRef,
            {
              ...club.toJson(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true));

        // Update memory cache
        _clubCache[club.id] = club;
      }

      // Execute batch
      await batch.commit();

      debugPrint('Successfully batch updated ${clubs.length} clubs');
    } catch (e) {
      debugPrint('Error batch updating clubs: $e');
      rethrow;
    }
  }

  /// Listen to real-time updates for a specific club
  static Stream<Club?> listenToClub(String clubId) {
    return _firestore
        .collection(_clubCollection)
        .doc(clubId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;

      try {
        final data = snapshot.data() as Map<String, dynamic>;
        final club = Club.fromJson(data);

        // Update cache
        _clubCache[club.id] = club;

        return club;
      } catch (e) {
        debugPrint('Error parsing club from Firestore stream: $e');
        return null;
      }
    });
  }

  /// Load events from cache if available
  static Future<List<Event>> _loadAllEventsFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = prefs.getString(_eventsCacheKey);

      if (eventsJson == null || eventsJson.isEmpty) {
        // If no events in cache, try to get them from the RSS service directly
        // This is more efficient than doing a network fetch
        try {
          // Use a static method from a different service to avoid circular dependencies
          // but we don't want to expose this as public API
          return await _getEventsFromRssServiceCache();
        } catch (e) {
          debugPrint('Error getting events from RSS service: $e');
          return [];
        }
      }

      final List<dynamic> eventsList = jsonDecode(eventsJson);
      return eventsList.map((json) => Event.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading events from cache in ClubService: $e');
      return [];
    }
  }

  /// Internal helper to get events from RSS service without creating a circular dependency
  static Future<List<Event>> _getEventsFromRssServiceCache() async {
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = prefs.getString(_eventsCacheKey);

    if (eventsJson == null || eventsJson.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> eventsList = jsonDecode(eventsJson);
      return eventsList.map((json) => Event.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error parsing events from RSS cache: $e');
      return [];
    }
  }

  /// Extracts club information from an event and creates a club space if it doesn't exist
  static Club? extractClubFromEvent(Event event) {
    if (event.organizerName.isEmpty) return null;

    // Define common generic organizer names to handle specially
    final genericOrganizers = [
      'university at buffalo',
      'buffalo',
      'university',
      'ub',
      'suny',
      'suny buffalo',
      'university events',
      'campus events',
      'college events',
      'events',
      'student activities',
      'student life',
      'student union',
      'union',
      'center for the arts',
      'student association',
      'sa',
    ];

    String organizerName = event.organizerName;
    bool isGenericOrganizer =
        genericOrganizers.contains(organizerName.toLowerCase());

    // If it's a generic organizer, try to extract the real organization from the title
    if (isGenericOrganizer) {
      String potentialName = _extractOrganizerFromTitle(event.title);

      // Only use the extracted name if it's likely an organization and not just an event title
      if (_isLikelyOrganization(potentialName) &&
          potentialName != "University at Buffalo") {
        organizerName = potentialName;
        isGenericOrganizer = false;
      }
    }

    // If we still have a generic organizer, try to get clues from the description
    if (isGenericOrganizer && event.description.isNotEmpty) {
      String potentialName =
          _extractOrganizerFromDescription(event.description);
      if (_isLikelyOrganization(potentialName) &&
          potentialName != "University at Buffalo") {
        organizerName = potentialName;
        isGenericOrganizer = false;
      }
    }

    // Create or update the club with the extracted organizer name
    return _createOrUpdateClub(event, organizerName);
  }

  /// Helper method to extract organizer name from event title
  static String _extractOrganizerFromTitle(String title) {
    // Detect specific patterns that indicate an organization as the host

    // Pattern 1: "Organization: Event Name"
    if (title.contains(':')) {
      final colonParts = title.split(':');
      final beforeColon = colonParts[0].trim();

      // Check if the text before colon is likely an organization
      if (beforeColon.length > 3 && _isLikelyOrganization(beforeColon)) {
        return beforeColon;
      }
    }

    // Pattern 2: "Organization presents..."
    final presentsPattern = RegExp(r"(.*?)\s+presents\b", caseSensitive: false);
    final presentsMatch = presentsPattern.firstMatch(title);
    if (presentsMatch != null) {
      final org = presentsMatch.group(1)?.trim();
      if (org != null && org.length > 3 && _isLikelyOrganization(org)) {
        return org;
      }
    }

    // Pattern 3: "Organization hosts..."
    final hostsPattern = RegExp(r"(.*?)\s+hosts\b", caseSensitive: false);
    final hostsMatch = hostsPattern.firstMatch(title);
    if (hostsMatch != null) {
      final org = hostsMatch.group(1)?.trim();
      if (org != null && org.length > 3 && _isLikelyOrganization(org)) {
        return org;
      }
    }

    // Pattern 4: "Join Organization for..."
    final joinPattern = RegExp(r"Join\s+(.*?)\s+for\b", caseSensitive: false);
    final joinMatch = joinPattern.firstMatch(title);
    if (joinMatch != null) {
      final org = joinMatch.group(1)?.trim();
      if (org != null && org.length > 3 && _isLikelyOrganization(org)) {
        return org;
      }
    }

    // Pattern 5: "Organization's Event/Meeting/etc"
    final possessivePattern = RegExp(r"(.*?)(?:\'s|\s+of\s+the|\s+by\s+the)\s+",
        caseSensitive: false);
    final possessiveMatch = possessivePattern.firstMatch(title);
    if (possessiveMatch != null) {
      final org = possessiveMatch.group(1)?.trim();
      if (org != null && org.length > 3 && _isLikelyOrganization(org)) {
        return org;
      }
    }

    // Default to UB if no pattern matches
    return 'University at Buffalo';
  }

  /// Extract organization from event description
  static String _extractOrganizerFromDescription(String description) {
    // Try to find sentences that mention hosts or organizations
    final hostedByPattern = RegExp(
        r"(?:hosted|organized|presented|sponsored|brought to you)\s+by\s+(.*?)(?:\.|\,|\;|\n)",
        caseSensitive: false);
    final hostedByMatch = hostedByPattern.firstMatch(description);
    if (hostedByMatch != null) {
      final orgText = hostedByMatch.group(1)?.trim();
      if (orgText != null && orgText.length > 3) {
        // Extract just the organization name (avoid getting entire rest of description)
        final words = orgText.split(' ');
        // Try to limit to reasonable organization name length (up to 5-6 words)
        final maxWords = math.min(6, words.length);
        final potentialOrg = words.take(maxWords).join(' ');
        if (_isLikelyOrganization(potentialOrg)) {
          return potentialOrg;
        }
      }
    }

    // Look for "About [Organization Name]" pattern
    final aboutPattern =
        RegExp(r"About\s+(.*?)(?:\.|\,|\;|\n|:)", caseSensitive: false);
    final aboutMatch = aboutPattern.firstMatch(description);
    if (aboutMatch != null) {
      final orgText = aboutMatch.group(1)?.trim();
      if (orgText != null &&
          orgText.length > 3 &&
          _isLikelyOrganization(orgText)) {
        return orgText;
      }
    }

    // Check for organization at the beginning of description
    final firstSentenceEnd = description.indexOf('.');
    if (firstSentenceEnd > 10) {
      final firstSentence = description.substring(0, firstSentenceEnd).trim();
      // If the first sentence is short and looks like an org name
      if (firstSentence.length < 50 && _isLikelyOrganization(firstSentence)) {
        return firstSentence;
      }
    }

    return 'University at Buffalo';
  }

  /// Helper to check if a string is just a generic prefix
  static bool _isGenericPrefix(String text) {
    final lowerText = text.toLowerCase().trim();

    // Expanded list of generic prefixes that aren't organization names
    final genericPrefixes = [
      'event',
      'meeting',
      'workshop',
      'seminar',
      'the',
      'a',
      'an',
      'welcome to',
      'join us for',
      'join',
      'upcoming',
      'info session',
      'information session',
      'lecture',
      'presentation',
      'conference',
      'panel',
      'virtual',
      'online',
      'free',
      'special',
      'weekly',
      'monthly',
      'annual',
      'spring',
      'fall',
      'summer',
      'winter',
      'today',
      'tomorrow',
      'this week',
      'registration',
      'register now',
      'sign up',
      'kick-off',
      'kickoff',
      'grand opening',
      'announcement',
      'reminder',
      'final',
      'call for',
      'important',
      'session',
      'training',
      'celebration',
      'party',
      'open house',
      'townhall',
      'town hall',
      'forum',
      'expo',
      'fair',
      'festival',
      'contest',
      'competition',
      'championship',
      'tournament',
      'deadline',
      'save the date',
      'recurring',
    ];

    // Check for exact matches
    if (genericPrefixes.contains(lowerText)) {
      return true;
    }

    // Check for prefix matches
    for (final prefix in genericPrefixes) {
      if (lowerText.startsWith('$prefix ')) {
        return true;
      }
    }

    // Check for words that strongly indicate this is an event, not an organization
    final eventIndicators = [
      ' day',
      'event',
      'session',
      'class',
      'workshop',
      'open house',
      'webinar',
      ' fair',
      'festival',
      'lecture',
      'seminar',
      'symposium',
      'conference',
      'concert',
      'performance',
      'showcase',
      'exhibition',
      'tournament',
      'competition',
      'championship',
      'match',
      'game',
      'party',
      'celebration',
      'ceremony',
      'reception',
      'meeting',
      'info session',
      'information session',
      'orientation',
      'tour',
      'field trip',
      'excursion',
      'retreat',
      'panel',
      'networking',
      'social',
      'sale',
      'fundraiser',
      'drive',
      ' week',
      ' fest',
    ];

    // Check if text contains event indicators
    // and doesn't contain organization indicators
    if (eventIndicators.any((indicator) => lowerText.contains(indicator))) {
      // But make sure it's not a club with a legitimate name that includes these words
      if (!_containsOrganizationKeyword(lowerText)) {
        return true;
      }
    }

    // Check for date patterns that suggest this is an event title, not an organization
    final datePatterns = [
      RegExp(r'\d{1,2}/\d{1,2}'), // MM/DD
      RegExp(r'\d{1,2}-\d{1,2}'), // MM-DD
      RegExp(r'\d{1,2}\.\d{1,2}'), // MM.DD
      RegExp(r'\b\d{1,2}(?:st|nd|rd|th)\b'), // 1st, 2nd, etc.
      RegExp(
          r'\b(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\.?\s+\d{1,2}\b',
          caseSensitive: false), // Jan 1, etc.
      RegExp(
          r'\b(?:monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b',
          caseSensitive: false),
    ];

    for (final pattern in datePatterns) {
      if (pattern.hasMatch(lowerText)) {
        return true;
      }
    }

    return false;
  }

  /// Additional check to determine if a name is likely a legitimate organization
  static bool _isLikelyOrganization(String name) {
    if (name.isEmpty) return false;

    // If too short, probably not an org name
    if (name.length < 3) return false;

    // If name is extremely long, it's likely a description or title, not an org name
    if (name.length > 60) return false;

    // Always avoid common event-like structure
    if (_isGenericPrefix(name)) return false;

    // Check for club-specific keywords that strongly indicate organization status
    if (_containsOrganizationKeyword(name.toLowerCase())) {
      return true;
    }

    // Check if it contains both upper and lowercase (typical of proper names)
    if (name.contains(RegExp(r'[A-Z]')) && name.contains(RegExp(r'[a-z]'))) {
      // Check if it's likely a title case name (e.g., "Chess Club")
      final words = name.split(' ');
      if (words.length > 1 && words.length < 8) {
        // Real org names aren't usually super long
        int capitalized = 0;
        for (final word in words) {
          if (word.isNotEmpty && word[0].toUpperCase() == word[0]) {
            capitalized++;
          }
        }
        // If most words are capitalized, it's likely an organization name
        if (capitalized >= words.length * 0.6) {
          return true;
        }
      }
    }

    // Use a more conservative approach - look for strong indicators in the name
    final nameWords = name.toLowerCase().split(' ');

    // Check for UB-specific organizations
    if (nameWords.contains('ub') ||
        nameWords.contains('buffalo') ||
        name.contains('University at Buffalo')) {
      // Only count as org if has another qualifying word
      return nameWords.any((word) => _isOrganizationWord(word));
    }

    // Check for strong indicators of an organization vs event
    final hasOrgIndicator = nameWords.any((word) => _isOrganizationWord(word));
    final hasEventIndicator = nameWords.any((word) => _isEventWord(word));

    // If it has org indicators and no event indicators, likely an org
    if (hasOrgIndicator && !hasEventIndicator) {
      return true;
    }

    // If very short (1-2 words) and looks like a proper noun name (capitalized)
    // it could be a simple club name like "Chess Club"
    if (nameWords.length <= 3 &&
        name != name.toLowerCase() &&
        !hasEventIndicator) {
      final words = name.split(' ');
      // Check if all words start with uppercase
      bool allCapitalized = words
          .every((word) => word.isNotEmpty && word[0].toUpperCase() == word[0]);
      if (allCapitalized) {
        return true;
      }
    }

    return false;
  }

  /// Checks if a word strongly indicates an organization
  static bool _isOrganizationWord(String word) {
    final orgWords = [
      'club',
      'association',
      'society',
      'group',
      'committee',
      'organization',
      'federation',
      'council',
      'board',
      'team',
      'dept',
      'department',
      'office',
      'center',
      'initiative',
      'student',
      'faculty',
      'alumni',
      'alliance',
      'ub',
      'buffalo',
      'suny',
      'chapter',
      'fraternity',
      'sorority',
      'brotherhood',
      'sisterhood',
      'institute',
      'league',
      'collective',
      'brotherhood',
      'sisterhood',
      'consortium',
      'community',
      'network',
      'guild',
      'fellowship',
      'foundation',
      'members',
      'assembly',
      'coalition',
      'engineers',
      'students',
      'professionals',
      'scholars',
    ];

    return orgWords.contains(word) ||
        orgWords.any((orgWord) => word.contains(orgWord));
  }

  /// Checks if text contains organization keywords
  static bool _containsOrganizationKeyword(String text) {
    text = text.toLowerCase();
    final orgKeywords = [
      'club',
      'association',
      'society',
      'committee',
      'organization',
      'federation',
      'council',
      'student',
      'faculty',
      'alumni',
      'chapter',
      'fraternity',
      'sorority',
      'department',
      'coalition',
      'consortium',
    ];

    return orgKeywords.any((keyword) => text.contains(keyword));
  }

  /// Checks if a word strongly indicates an event rather than organization
  static bool _isEventWord(String word) {
    final eventWords = [
      'event',
      'workshop',
      'seminar',
      'session',
      'meeting',
      'lecture',
      'presentation',
      'conference',
      'panel',
      'seminar',
      'fair',
      'festival',
      'concert',
      'performance',
      'party',
      'celebration',
      'ceremony',
      'exhibition',
      'showcase',
      'tournament',
      'competition',
      'championship',
      'opening',
      'closing',
      'kickoff',
      'launch',
      'reception',
      'orientation',
    ];

    return eventWords.contains(word);
  }

  /// Create or update a club based on event information
  static Club _createOrUpdateClub(Event event, String organizerName) {
    // Clean up the organizer name
    organizerName = _cleanOrganizationName(organizerName);

    // Skip if the name looks like an event rather than an organization
    if (_isGenericPrefix(organizerName) ||
        !_isLikelyOrganization(organizerName)) {
      // Default to UB as a fallback if we can't determine a valid organization
      organizerName = 'University at Buffalo';
    }

    // Generate a consistent ID
    final clubId = Club.createIdFromName(organizerName);

    // Check if club exists in memory cache
    if (_clubCache.containsKey(clubId)) {
      final existingClub = _clubCache[clubId]!;

      // Get any new category that might not be in the existing club's categories
      final List<String> updatedCategories = List.from(existingClub.categories);
      if (!updatedCategories.contains(event.category) &&
          event.category != existingClub.category) {
        updatedCategories.add(event.category);
      }

      // Update club with new event information and any additional category
      final updatedClub = existingClub.copyWith(
        eventCount: existingClub.eventCount + 1,
        updatedAt: DateTime.now(),
        categories: updatedCategories,
        // If this event has a location and the club doesn't, add it
        location: existingClub.location ?? event.location,
        // If this event has an email and the club doesn't, add it
        email: existingClub.email ?? event.organizerEmail,
      );

      // Store the updated club
      _clubCache[clubId] = updatedClub;
      return updatedClub;
    }

    // Create a new club from event data
    String description =
        'Organization that hosts events at the University at Buffalo';
    if (event.description.length > 20) {
      // Try to extract a better description from the event
      final firstSentenceEnd = event.description.indexOf('.');
      if (firstSentenceEnd > 10 && firstSentenceEnd < 150) {
        description = event.description.substring(0, firstSentenceEnd + 1);
      } else {
        // Use a substring if no clear first sentence
        description = event.description.length > 150
            ? '${event.description.substring(0, 147)}...'
            : event.description;
      }
    }

    final club = Club(
      id: clubId,
      name: organizerName,
      description: description,
      category: event.category,
      memberCount: 0,
      status: 'active',
      icon: _getCategoryIcon(event.category),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      categories: [event.category],
      eventCount: 1,
      location: event.location,
      email: event.organizerEmail,
      isOfficial: _determineIfOfficial(organizerName),
    );

    // Store in memory cache
    _clubCache[clubId] = club;

    return club;
  }

  /// Determine if an organization is likely an official UB organization
  static bool _determineIfOfficial(String name) {
    name = name.toLowerCase();

    // Specific UB entities that are official
    final officialKeywords = [
      'department of',
      'school of',
      'college of',
      'institute of',
      'center for',
      'office of',
      'division of',
      'program in',
      'graduate',
      'undergraduate',
      'university at buffalo',
      'ub ',
    ];

    for (final keyword in officialKeywords) {
      if (name.contains(keyword)) {
        return true;
      }
    }

    // Check for fraternity/sorority indicators
    // (assuming they're official if they're recognized)
    if ((name.contains('fraternity') ||
            name.contains('sorority') ||
            name.contains('greek') ||
            name.contains('alpha') ||
            name.contains('beta') ||
            name.contains('gamma') ||
            name.contains('delta') ||
            name.contains('epsilon') ||
            name.contains('zeta') ||
            name.contains('eta') ||
            name.contains('theta') ||
            name.contains('iota') ||
            name.contains('kappa') ||
            name.contains('lambda') ||
            name.contains('mu') ||
            name.contains('nu') ||
            name.contains('xi') ||
            name.contains('omicron') ||
            name.contains('pi') ||
            name.contains('rho') ||
            name.contains('sigma') ||
            name.contains('tau') ||
            name.contains('upsilon') ||
            name.contains('phi') ||
            name.contains('chi') ||
            name.contains('psi') ||
            name.contains('omega')) &&
        (name.contains('chapter') || name.contains('buffalo'))) {
      return true;
    }

    return false;
  }

  /// Clean organization name to ensure consistent naming
  static String _cleanOrganizationName(String name) {
    // Skip cleaning if it's the default
    if (name == 'University at Buffalo') {
      return name;
    }

    // 1. Remove common prefixes
    final prefixesToRemove = [
      'the ',
      'The ',
      'UB ',
      'Buffalo ',
    ];

    for (final prefix in prefixesToRemove) {
      if (name.startsWith(prefix)) {
        name = name.substring(prefix.length);
      }
    }

    // 2. Remove quotes if they exist
    if (name.startsWith('"') && name.endsWith('"')) {
      name = name.substring(1, name.length - 1);
    }

    // 3. Fix common abbreviation inconsistencies
    name = name.replaceAll(' Assoc.', ' Association');
    name = name.replaceAll(' Assn.', ' Association');
    name = name.replaceAll(' Dept.', ' Department');
    name = name.replaceAll(' Org.', ' Organization');

    // 4. Truncate overly long names
    if (name.length > 60) {
      final shortened = '${name.substring(0, 57)}...';
      // But only if it still looks like an organization
      if (_isLikelyOrganization(shortened)) {
        name = shortened;
      }
    }

    // 5. First letter of each word uppercase (proper title case)
    final words = name.split(' ');
    final correctedWords = words.map((word) {
      if (word.isEmpty) return '';
      if (word.length == 1) return word.toUpperCase();
      return word[0].toUpperCase() + word.substring(1);
    });

    return correctedWords.join(' ').trim();
  }

  /// Gets all clubs that have been extracted from events
  static List<Club> getAllExtractedClubs() {
    return _clubCache.values.toList();
  }

  /// Load clubs from cache on app startup
  static Future<void> loadClubsFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final clubsJson = prefs.getString(_clubPrefsKey);

      if (clubsJson != null) {
        final List<dynamic> clubsList = jsonDecode(clubsJson);

        for (final clubData in clubsList) {
          final club = Club.fromJson(clubData);
          _clubCache[club.id] = club;
        }

        debugPrint('Loaded ${_clubCache.length} clubs from cache');
      }
    } catch (e) {
      debugPrint('Error loading clubs from cache: $e');
    }
  }

  /// Save clubs to cache
  static Future<void> _saveClubsToCache(List<Club> clubs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final clubsList = clubs.map((club) => club.toJson()).toList();
      await prefs.setString(_clubPrefsKey, jsonEncode(clubsList));

      // Update last fetch timestamp
      _updateLastFetchTimestamp();
    } catch (e) {
      debugPrint('Error saving clubs to cache: $e');
    }
  }

  static Future<void> _updateLastFetchTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          _lastFetchTimestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error updating timestamp: $e');
    }
  }

  /// Generate clubs from the list of events
  static Future<List<Club>> generateClubsFromEvents(List<Event> events) async {
    try {
      // First clear existing clubs to avoid stale data
      _clubCache.clear();

      for (final event in events) {
        // Skip events with no organizer name
        if (event.organizerName.isEmpty) {
          continue;
        }

        // Only create clubs for what are likely actual organizations
        extractClubFromEvent(event);
      }

      // Filter out likely non-organizations
      _clubCache.removeWhere((id, club) =>
          !_isLikelyOrganization(club.name) || _isGenericPrefix(club.name));

      // Save clubs to cache
      await _saveClubsToCache(_clubCache.values.toList());

      return _clubCache.values.toList();
    } catch (e) {
      debugPrint('Error generating clubs from events: $e');
      return [];
    }
  }

  /// Helper to get an appropriate icon for a category
  static IconData _getCategoryIcon(String category) {
    final lowerCategory = category.toLowerCase();

    if (lowerCategory.contains('tech') ||
        lowerCategory.contains('computer') ||
        lowerCategory.contains('programming')) {
      return Icons.computer;
    } else if (lowerCategory.contains('business') ||
        lowerCategory.contains('entrepreneur')) {
      return Icons.business;
    } else if (lowerCategory.contains('sport') ||
        lowerCategory.contains('athletic')) {
      return Icons.sports;
    } else if (lowerCategory.contains('music') ||
        lowerCategory.contains('band') ||
        lowerCategory.contains('choir')) {
      return Icons.music_note;
    } else if (lowerCategory.contains('art') ||
        lowerCategory.contains('design') ||
        lowerCategory.contains('paint')) {
      return Icons.palette;
    } else if (lowerCategory.contains('science') ||
        lowerCategory.contains('biology') ||
        lowerCategory.contains('chemistry') ||
        lowerCategory.contains('physics')) {
      return Icons.science;
    } else if (lowerCategory.contains('social') ||
        lowerCategory.contains('community')) {
      return Icons.groups;
    } else if (lowerCategory.contains('academic') ||
        lowerCategory.contains('education') ||
        lowerCategory.contains('learning')) {
      return Icons.school;
    } else if (lowerCategory.contains('food') ||
        lowerCategory.contains('cooking')) {
      return Icons.restaurant;
    } else if (lowerCategory.contains('culture') ||
        lowerCategory.contains('international')) {
      return Icons.public;
    } else if (lowerCategory.contains('volunteer') ||
        lowerCategory.contains('service')) {
      return Icons.volunteer_activism;
    }

    // Default icon
    return Icons.group;
  }

  /// Save all clubs to Firestore in proper organizational subcollections
  static Future<bool> syncAllClubsToFirestore() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final clubs = _clubCache.values.toList();

      debugPrint(
          'Organizing and syncing ${clubs.length} clubs to Firestore...');

      // Create maps for each branch
      final Map<String, List<Club>> branchMap = {
        'campus_living': [],
        'fraternity_sorority_life': [],
        'student_organizations': [],
        'university_departments': [],
        'other': [], // For any clubs that don't fit into the specified branches
      };

      // Organize clubs into proper branches
      for (final club in clubs) {
        if (club.isUniversityDepartment) {
          branchMap['university_departments']!.add(club);
        } else if (_isGreekLifeClub(club)) {
          branchMap['fraternity_sorority_life']!.add(club);
        } else if (_isCampusLivingClub(club)) {
          branchMap['campus_living']!.add(club);
        } else {
          // Default to student organizations
          branchMap['student_organizations']!.add(club);
        }
      }

      // Log breakdown of clubs by branch
      debugPrint('Club distribution by branch:');
      branchMap.forEach((branch, clubList) {
        debugPrint('  $branch: ${clubList.length} clubs');
      });

      // Process each branch separately
      const int batchSize =
          400; // Firestore allows max 500 operations per batch

      for (final entry in branchMap.entries) {
        final branchName = entry.key;
        final branchClubs = entry.value;

        if (branchClubs.isEmpty) {
          debugPrint('No clubs for branch: $branchName, skipping');
          continue;
        }

        debugPrint(
            '\nProcessing branch: $branchName with ${branchClubs.length} clubs');

        // Process clubs in smaller batches to avoid hitting Firestore limits
        for (int i = 0; i < branchClubs.length; i += batchSize) {
          final int end = (i + batchSize < branchClubs.length)
              ? i + batchSize
              : branchClubs.length;
          final currentBatch = branchClubs.sublist(i, end);

          debugPrint(
              '  Processing batch ${i ~/ batchSize + 1}: ${currentBatch.length} clubs (${i + 1}-$end of ${branchClubs.length})');

          final localBatch = firestore.batch();

          for (final club in currentBatch) {
            final docRef = firestore
                .collection('clubs')
                .doc(branchName)
                .collection('entities')
                .doc(club.id);
            final clubData = club.toJson();
            clubData['synced_at'] = FieldValue.serverTimestamp();
            clubData['branch'] = branchName; // Add branch information

            localBatch.set(docRef, clubData, SetOptions(merge: true));
          }

          // Commit this batch
          await localBatch.commit();
          debugPrint('  Committed batch ${i ~/ batchSize + 1}');
        }
      }

      // Create a master index of all clubs for quick lookup
      final indexBatch = firestore.batch();
      final indexCollection = firestore.collection('club_index');

      debugPrint('\nCreating master club index...');

      // Clear the existing index first
      final existingIndexDocs = await indexCollection.limit(500).get();
      final clearBatch = firestore.batch();
      for (final doc in existingIndexDocs.docs) {
        clearBatch.delete(doc.reference);
      }
      await clearBatch.commit();

      // Create new index entries in batches
      int indexCount = 0;
      for (int i = 0; i < clubs.length; i += batchSize) {
        final int end =
            (i + batchSize < clubs.length) ? i + batchSize : clubs.length;
        final currentBatch = clubs.sublist(i, end);
        final indexBatch = firestore.batch();

        for (final club in currentBatch) {
          final String branchName = _determineBranchForClub(club);
          final indexRef = indexCollection.doc(club.id);

          indexBatch.set(indexRef, {
            'id': club.id,
            'name': club.name,
            'branch': branchName,
            'path': 'clubs/$branchName/entities/${club.id}',
            'indexed_at': FieldValue.serverTimestamp(),
          });
          indexCount++;
        }

        await indexBatch.commit();
      }

      debugPrint('Created index for $indexCount clubs');

      // Update metadata
      final metadataRef = firestore.collection('metadata').doc('clubs_sync');
      await metadataRef.set({
        'last_sync': FieldValue.serverTimestamp(),
        'club_count': clubs.length,
        'branch_counts': {
          'campus_living': branchMap['campus_living']!.length,
          'fraternity_sorority_life':
              branchMap['fraternity_sorority_life']!.length,
          'student_organizations': branchMap['student_organizations']!.length,
          'university_departments': branchMap['university_departments']!.length,
          'other': branchMap['other']!.length,
        }
      }, SetOptions(merge: true));

      debugPrint(
          '\nSuccessfully synced ${clubs.length} clubs to Firestore organized by branch');
      return true;
    } catch (e, stackTrace) {
      debugPrint('Error syncing clubs to Firestore: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Determine which branch a club belongs to
  static String _determineBranchForClub(Club club) {
    if (club.isUniversityDepartment) {
      return 'university_departments';
    } else if (_isGreekLifeClub(club)) {
      return 'fraternity_sorority_life';
    } else if (_isCampusLivingClub(club)) {
      return 'campus_living';
    } else {
      return 'student_organizations';
    }
  }

  /// Check if a club is related to Greek life (fraternities or sororities)
  static bool _isGreekLifeClub(Club club) {
    final List<String> greekLifeKeywords = [
      'fraternity',
      'sorority',
      'greek life',
      'frat',
      'alpha',
      'beta',
      'gamma',
      'delta',
      'epsilon',
      'zeta',
      'eta',
      'theta',
      'iota',
      'kappa',
      'lambda',
      'mu',
      'nu',
      'xi',
      'omicron',
      'pi',
      'rho',
      'sigma',
      'tau',
      'upsilon',
      'phi',
      'chi',
      'psi',
      'omega',
      'interfraternity',
      'panhellenic'
    ];

    final String nameAndDesc =
        '${club.name.toLowerCase()} ${club.description.toLowerCase()}';
    final String categoryStr =
        '${club.category.toLowerCase()} ${club.categories.join(' ').toLowerCase()}';
    final String tagsStr = club.tags.join(' ').toLowerCase();

    return greekLifeKeywords.any((keyword) =>
        nameAndDesc.contains(keyword) ||
        categoryStr.contains(keyword) ||
        tagsStr.contains(keyword));
  }

  /// Check if a club is related to campus living/residence halls
  static bool _isCampusLivingClub(Club club) {
    final List<String> campusLivingKeywords = [
      'residence hall',
      'dorm',
      'housing',
      'residential',
      'living community',
      'campus living',
      'apartment',
      'dormitory',
      'hall council',
      'res life',
      'residence life'
    ];

    final String nameAndDesc =
        '${club.name.toLowerCase()} ${club.description.toLowerCase()}';
    final String categoryStr =
        '${club.category.toLowerCase()} ${club.categories.join(' ').toLowerCase()}';
    final String tagsStr = club.tags.join(' ').toLowerCase();

    return campusLivingKeywords.any((keyword) =>
        nameAndDesc.contains(keyword) ||
        categoryStr.contains(keyword) ||
        tagsStr.contains(keyword));
  }

  /// Join a club as a member
  static Future<bool> joinClub(String clubId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;

      if (currentUserId == null) {
        debugPrint('Cannot join club: user not authenticated');
        return false;
      }

      // First check if the user is already a member
      try {
        final memberDoc = await firestore
            .collectionGroup('members')
            .where('userId', isEqualTo: currentUserId)
            .where('clubId', isEqualTo: clubId)
            .limit(1)
            .get();

        if (memberDoc.docs.isNotEmpty) {
          debugPrint('User is already a member of this club');
          return true; // Already joined
        }
      } catch (e) {
        debugPrint('Error checking membership: $e');
        // Continue with join attempt even if check fails
      }

      // Find the club document using collectionGroup
      final spaceQuery = await firestore
          .collectionGroup('spaces')
          .where('id', isEqualTo: clubId)
          .limit(1)
          .get();

      if (spaceQuery.docs.isEmpty) {
        debugPrint('Club not found with ID: $clubId');
        return false;
      }

      final spaceRef = spaceQuery.docs.first.reference;

      // Add user to members subcollection
      final memberData = {
        'userId': currentUserId,
        'clubId': clubId,
        'joinedAt': FieldValue.serverTimestamp(),
        'status': 'active',
      };

      // Add member document to the correct subcollection
      await spaceRef.collection('members').doc(currentUserId).set(memberData);

      // Increment member count
      await spaceRef.update({
        'memberCount': FieldValue.increment(1),
      });

      debugPrint('Successfully joined club: $clubId');
      return true;
    } catch (e) {
      debugPrint('Error joining club: $e');
      return false;
    }
  }
}
