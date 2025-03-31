import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/models/interactions/interaction.dart';
import 'package:hive_ui/services/firebase_monitor.dart';
import 'package:hive_ui/services/interactions/interaction_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;

/// Engine for personalizing feed content based on user interactions
class FeedPersonalizationEngine {
  // Firebase references
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache keys
  static const String _userInterestsKey = 'user_interests';
  static const String _userScoresKey = 'user_event_scores';

  // Default feature weights
  static const Map<String, double> _defaultWeights = {
    'recency': 5.0,
    'popularity': 3.0,
    'userInterest': 4.0,
    'previousEngagement': 4.5,
    'friendsAttending': 2.0,
    'distance': 1.5,
  };

  // In-memory cache
  static final Map<String, Map<String, double>> _userInterestsCache = {};
  static final Map<String, Map<String, double>> _eventScoreCache = {};

  /// Generate personalized event scores for a given user
  static Future<List<ScoredEvent>> scoreEvents(
    String userId,
    List<Event> events, {
    Map<String, double>? featureWeights,
    double? userLocation,
  }) async {
    // Use default weights if none provided
    final weights = featureWeights ?? _defaultWeights;

    // Get user interests
    final userInterests = await _getUserInterests(userId);

    // Score each event
    final List<ScoredEvent> scoredEvents = [];
    for (final event in events) {
      final score = await _computeEventScore(
        userId,
        event,
        userInterests,
        weights,
        userLocation,
      );

      scoredEvents.add(ScoredEvent(
        event: event,
        score: score,
        featureScores: score.scores,
      ));
    }

    // Sort by score (highest first)
    scoredEvents.sort((a, b) => b.score.total.compareTo(a.score.total));

    return scoredEvents;
  }

  /// Compute a score for an event based on multiple factors
  static Future<EventScore> _computeEventScore(
    String userId,
    Event event,
    Map<String, double> userInterests,
    Map<String, double> weights,
    double? userLocation,
  ) async {
    // Check cache first
    final cacheKey = '${userId}_${event.id}';
    if (_eventScoreCache.containsKey(cacheKey)) {
      final cachedScore = _eventScoreCache[cacheKey]!;
      // If cache is less than 30 minutes old, use it
      final cachedTime = cachedScore['cachedAt'] ?? 0.0;
      final now = DateTime.now().millisecondsSinceEpoch / 1000;
      if (now - cachedTime < 30 * 60) {
        return EventScore(
          total: cachedScore['total'] ?? 0.0,
          scores: {
            'recency': cachedScore['recency'] ?? 0.0,
            'popularity': cachedScore['popularity'] ?? 0.0,
            'userInterest': cachedScore['userInterest'] ?? 0.0,
            'previousEngagement': cachedScore['previousEngagement'] ?? 0.0,
            'friendsAttending': cachedScore['friendsAttending'] ?? 0.0,
            'distance': cachedScore['distance'] ?? 0.0,
          },
        );
      }
    }

    // Get event stats
    final stats = await InteractionService.getEntityStats(
      event.id,
      EntityType.event,
    );

    // Calculate individual feature scores
    final Map<String, double> scores = {};

    // Recency score (higher for newer events)
    final now = DateTime.now();
    final eventTime = event.startDate;
    final daysDifference = eventTime.difference(now).inHours / 24;

    // Events in the past get a very low score
    if (daysDifference < 0) {
      scores['recency'] = 0.01;
    } else if (daysDifference > 30) {
      // Events more than a month away get a lower score
      scores['recency'] = 0.5;
    } else {
      // Events in the next 2 weeks get higher scores
      scores['recency'] = math.max(0, 1 - (daysDifference / 14));
    }

    // Popularity score (based on views, RSVPs, etc.)
    const viewsWeight = 0.3;
    const rsvpsWeight = 0.5;
    const sharesWeight = 0.2;

    // Normalize counts (clamp to avoid outliers)
    final normalizedViews = math.min(stats.viewCount / 1000, 1.0);
    final normalizedRsvps = math.min(stats.rsvpCount / 100, 1.0);
    final normalizedShares = math.min(stats.shareCount / 20, 1.0);

    scores['popularity'] = (normalizedViews * viewsWeight) +
        (normalizedRsvps * rsvpsWeight) +
        (normalizedShares * sharesWeight);

    // User interest score (based on tags matching user interests)
    double interestScore = 0.0;
    for (final tag in event.tags) {
      if (userInterests.containsKey(tag)) {
        interestScore += userInterests[tag]! / 10;
      }
    }
    scores['userInterest'] = math.min(interestScore, 1.0);

    // Previous engagement score (whether user has engaged with similar events)
    double previousEngagementScore = 0.0;

    try {
      // Check if user has interacted with this event before
      final interactions = await InteractionService.getEntityInteractions(
        event.id,
        limit: 5,
        userId: userId,
      );

      if (interactions.isNotEmpty) {
        // User has already interacted with this event
        for (final interaction in interactions) {
          switch (interaction.action) {
            case InteractionAction.view:
              previousEngagementScore += 0.1;
              break;
            case InteractionAction.rsvp:
              previousEngagementScore += 0.6;
              break;
            case InteractionAction.save:
              previousEngagementScore += 0.4;
              break;
            default:
              previousEngagementScore += 0.05;
              break;
          }
        }
      }

      // Look for similar events by tags
      final eventTags = event.tags;
      if (eventTags.isNotEmpty) {
        for (final tag in eventTags) {
          // Limit to 3 random tags to avoid excessive querying
          if (math.Random().nextDouble() > 0.3) continue;

          // Find events with this tag that user has interacted with
          final taggedEvents = await _firestore
              .collection('events')
              .where('tags', arrayContains: tag)
              .limit(3)
              .get();

          FirebaseMonitor.recordRead(count: taggedEvents.docs.length);

          // Check for interactions with these events
          for (final doc in taggedEvents.docs) {
            final eventId = doc.id;
            if (eventId == event.id) continue; // Skip current event

            final similarInteractions =
                await InteractionService.getEntityInteractions(
              eventId,
              limit: 1,
              userId: userId,
            );

            if (similarInteractions.isNotEmpty) {
              previousEngagementScore += 0.1;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error calculating previous engagement: $e');
    }

    scores['previousEngagement'] = math.min(previousEngagementScore, 1.0);

    // Friends attending score - would need social graph data
    // For now, use a placeholder implementation
    // In a real app, this would query the RSVPs and check if any are friends
    scores['friendsAttending'] = 0.0;

    // Distance score - would need geolocation
    // For now, use a placeholder implementation
    scores['distance'] = 0.5; // Default to medium distance

    // Calculate weighted total score
    double totalScore = 0.0;
    double totalWeight = 0.0;

    for (final entry in scores.entries) {
      final feature = entry.key;
      final score = entry.value;
      final weight = weights[feature] ?? 1.0;

      totalScore += score * weight;
      totalWeight += weight;
    }

    // Normalize total score
    final normalizedTotal = totalWeight > 0 ? totalScore / totalWeight : 0.0;

    // Create score object
    final eventScore = EventScore(
      total: normalizedTotal,
      scores: scores,
    );

    // Cache the score
    _eventScoreCache[cacheKey] = {
      'total': normalizedTotal,
      'recency': scores['recency'] ?? 0.0,
      'popularity': scores['popularity'] ?? 0.0,
      'userInterest': scores['userInterest'] ?? 0.0,
      'previousEngagement': scores['previousEngagement'] ?? 0.0,
      'friendsAttending': scores['friendsAttending'] ?? 0.0,
      'distance': scores['distance'] ?? 0.0,
      'cachedAt': DateTime.now().millisecondsSinceEpoch / 1000,
    };

    return eventScore;
  }

  /// Get user interests based on their previous interactions
  static Future<Map<String, double>> _getUserInterests(String userId) async {
    // Check memory cache first
    if (_userInterestsCache.containsKey(userId)) {
      return _userInterestsCache[userId]!;
    }

    // Check local storage next
    final prefs = await SharedPreferences.getInstance();
    final cachedInterestsStr = prefs.getString('$_userInterestsKey:$userId');

    if (cachedInterestsStr != null) {
      try {
        final cachedData =
            jsonDecode(cachedInterestsStr) as Map<String, dynamic>;
        final cachedTimestamp = cachedData['cachedAt'] as int;
        final now = DateTime.now().millisecondsSinceEpoch;

        // Use cache if it's less than 24 hours old
        if (now - cachedTimestamp < 24 * 60 * 60 * 1000) {
          final interestsData = cachedData['interests'] as Map<String, dynamic>;
          final interests = interestsData.map(
            (key, value) => MapEntry(key, (value as num).toDouble()),
          );

          // Store in memory cache
          _userInterestsCache[userId] = interests;

          return interests;
        }
      } catch (e) {
        debugPrint('Error parsing cached interests: $e');
      }
    }

    // If no valid cache, compute from interactions
    final interests = await _computeUserInterests(userId);

    // Cache the results
    _userInterestsCache[userId] = interests;

    // Store in local storage
    await prefs.setString(
        '$_userInterestsKey:$userId',
        jsonEncode({
          'cachedAt': DateTime.now().millisecondsSinceEpoch,
          'interests': interests,
        }));

    return interests;
  }

  /// Compute user interests based on their interactions
  static Future<Map<String, double>> _computeUserInterests(
      String userId) async {
    // This would ideally be done in a cloud function or background job
    // For client implementation, we'll use a simplified approach

    final Map<String, double> interests = {};

    try {
      // Query user's recent event interactions
      final query = _firestore
          .collection('interactions')
          .where('userId', isEqualTo: userId)
          .where('entityType', isEqualTo: 'event')
          .orderBy('timestamp', descending: true)
          .limit(50);

      final snapshot = await query.get();

      // Record Firebase read
      FirebaseMonitor.recordRead(count: snapshot.docs.length);

      // Process interactions
      final List<String> eventIds = [];
      final Map<String, double> eventWeights = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final entityId = data['entityId'] as String;
        final action = data['action'] as String;
        final timestamp = data['timestamp'] as int;

        // Skip if we've already seen this event
        if (eventIds.contains(entityId)) continue;

        eventIds.add(entityId);

        // Assign weight based on action type
        double weight = 0.0;
        switch (action) {
          case 'view':
            weight = 0.5;
            break;
          case 'rsvp':
            weight = 5.0;
            break;
          case 'share':
            weight = 3.0;
            break;
          case 'save':
            weight = 4.0;
            break;
          default:
            weight = 0.1;
            break;
        }

        // Apply recency decay (more recent interactions have higher weight)
        final age = (DateTime.now().millisecondsSinceEpoch - timestamp) /
            (1000 * 60 * 60 * 24); // in days
        final recencyFactor = math.max(0.1, 1.0 - (age / 30.0)); // 30-day decay

        eventWeights[entityId] = weight * recencyFactor;
      }

      // Fetch the events to get their tags
      for (final eventId in eventIds) {
        final eventDoc =
            await _firestore.collection('events').doc(eventId).get();

        // Record Firebase read
        FirebaseMonitor.recordRead();

        if (eventDoc.exists) {
          final data = eventDoc.data() as Map<String, dynamic>;
          final tags = List<String>.from(data['tags'] ?? []);
          final weight = eventWeights[eventId] ?? 1.0;

          // Update interest scores for each tag
          for (final tag in tags) {
            interests[tag] = (interests[tag] ?? 0.0) + weight;
          }
        }
      }

      // Normalize interest scores (0-10 scale)
      if (interests.isNotEmpty) {
        final maxInterest = interests.values.reduce(math.max);
        if (maxInterest > 0) {
          interests.forEach((tag, score) {
            interests[tag] = (score / maxInterest) * 10;
          });
        }
      }
    } catch (e) {
      debugPrint('Error computing user interests: $e');
    }

    // If no interests found, provide some defaults
    if (interests.isEmpty) {
      interests['technology'] = 5.0;
      interests['networking'] = 5.0;
      interests['social'] = 5.0;
    }

    return interests;
  }

  /// Update user interests when a new interaction occurs
  static Future<void> updateUserInterestsForInteraction(
    String userId,
    String eventId,
    InteractionAction action,
  ) async {
    try {
      // Get current interests
      final interests = await _getUserInterests(userId);

      // Get event tags
      final eventDoc = await _firestore.collection('events').doc(eventId).get();

      // Record Firebase read
      FirebaseMonitor.recordRead();

      if (eventDoc.exists) {
        final data = eventDoc.data() as Map<String, dynamic>;
        final tags = List<String>.from(data['tags'] ?? []);

        // Determine weight based on action
        double weight = 0.0;
        switch (action) {
          case InteractionAction.view:
            weight = 0.2;
            break;
          case InteractionAction.rsvp:
            weight = 2.0;
            break;
          case InteractionAction.share:
            weight = 1.2;
            break;
          case InteractionAction.save:
            weight = 1.5;
            break;
          default:
            weight = 0.1;
            break;
        }

        // Update interest scores
        for (final tag in tags) {
          interests[tag] = math.min(
            10.0, // Cap at 10
            (interests[tag] ?? 0.0) + weight,
          );
        }

        // Cache updated interests
        _userInterestsCache[userId] = interests;

        // Store in local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            '$_userInterestsKey:$userId',
            jsonEncode({
              'cachedAt': DateTime.now().millisecondsSinceEpoch,
              'interests': interests,
            }));
      }
    } catch (e) {
      debugPrint('Error updating user interests: $e');
    }
  }

  /// Clear cached data for a user
  static Future<void> clearUserCache(String userId) async {
    // Clear memory cache
    _userInterestsCache.remove(userId);

    // Clear relevant entries from event score cache
    final userKeyPrefix = '${userId}_';
    _eventScoreCache.removeWhere((key, _) => key.startsWith(userKeyPrefix));

    // Clear local storage cache
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_userInterestsKey:$userId');
  }
}

/// Represents an event with its personalization score
class ScoredEvent {
  final Event event;
  final EventScore score;
  final Map<String, double> featureScores;

  const ScoredEvent({
    required this.event,
    required this.score,
    required this.featureScores,
  });
}

/// Represents a score for an event with component scores
class EventScore {
  final double total;
  final Map<String, double> scores;

  const EventScore({
    required this.total,
    required this.scores,
  });
}
