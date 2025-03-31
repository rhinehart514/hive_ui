import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/models/interactions/interaction.dart';
import 'package:hive_ui/models/interactions/interaction_stats.dart';
import 'package:hive_ui/services/firebase_monitor.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

/// Service for tracking and managing user interactions with app entities
class InteractionService {
  // Firebase references
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _interactionsCollection =
      _firestore.collection('interactions');
  static final CollectionReference _statsCollection =
      _firestore.collection('interaction_stats');

  // Local storage keys
  static const String _pendingInteractionsKey = 'pending_interactions';
  static const String _interactionCacheKey = 'interaction_cache';
  static const String _statsCacheKey = 'interaction_stats_cache';

  // Memory cache for interaction stats
  static final Map<String, InteractionStats> _statsCache = {};

  // Batch processing
  static final List<Map<String, dynamic>> _pendingInteractions = [];
  static Timer? _batchTimer;
  static bool _initialized = false;

  // Session tracking
  static String? _currentSessionId;

  /// Initialize the interaction service
  static Future<void> initialize() async {
    if (_initialized) return;

    // Load pending interactions from local storage
    await _loadPendingInteractions();

    // Start batch processing timer
    _startBatchProcessing();

    // Generate new session ID
    _currentSessionId = _generateSessionId();

    _initialized = true;
    debugPrint('InteractionService initialized');
  }

  /// Log a user interaction with an entity
  static Future<void> logInteraction({
    required String userId,
    required String entityId,
    required EntityType entityType,
    required InteractionAction action,
    Map<String, dynamic>? metadata,
    bool highPriority = false,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      // Create interaction data
      final interactionData = {
        'userId': userId,
        'entityId': entityId,
        'entityType': entityType.toString().split('.').last,
        'action': action.toString().split('.').last,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'sessionId': _currentSessionId,
        'metadata': metadata ?? {},
        'deviceInfo': DeviceInfo.current().toMap(),
      };

      // Record Firebase operation for monitoring
      FirebaseMonitor.recordRead(count: 1);

      // For high-priority interactions (like RSVP), write directly
      if (highPriority) {
        await _interactionsCollection.add(interactionData);
        await _updateEntityStats(entityId, entityType, action);
        return;
      }

      // Otherwise, queue for batch processing
      _pendingInteractions.add(interactionData);

      // If we have enough interactions, process immediately
      if (_pendingInteractions.length >= 10) {
        _processPendingInteractions();
      }

      // Update local cache
      _updateLocalCache(entityId, entityType, action);

      // Save pending interactions to local storage for persistence
      _savePendingInteractions();
    } catch (e) {
      debugPrint('Error logging interaction: $e');
    }
  }

  /// Get user interactions for an entity
  static Future<List<Interaction>> getEntityInteractions(
    String entityId, {
    int limit = 20,
    String? userId,
  }) async {
    try {
      // Build query
      Query query = _interactionsCollection
          .where('entityId', isEqualTo: entityId)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      // Add user filter if specified
      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      // Execute query
      final snapshot = await query.get();

      // Record Firebase operation
      FirebaseMonitor.recordRead(count: snapshot.docs.length);

      // Parse results
      return snapshot.docs.map((doc) {
        return Interaction.fromFirestore(doc);
      }).toList();
    } catch (e) {
      debugPrint('Error getting entity interactions: $e');
      return [];
    }
  }

  /// Get interaction stats for an entity
  static Future<InteractionStats> getEntityStats(
    String entityId,
    EntityType entityType,
  ) async {
    // Check memory cache first
    if (_statsCache.containsKey(entityId)) {
      return _statsCache[entityId]!;
    }

    // Try to get from local storage to avoid Firestore read
    final prefs = await SharedPreferences.getInstance();
    final cachedStatsJson = prefs.getString('$_statsCacheKey:$entityId');

    if (cachedStatsJson != null) {
      try {
        final cachedData = jsonDecode(cachedStatsJson) as Map<String, dynamic>;
        final cachedTimestamp = cachedData['cachedAt'] as int;
        final now = DateTime.now().millisecondsSinceEpoch;

        // Use cache if it's less than 30 minutes old
        if (now - cachedTimestamp < 30 * 60 * 1000) {
          final statsData = cachedData['stats'] as Map<String, dynamic>;

          // Create stats object
          final stats = InteractionStats(
            entityId: entityId,
            entityType: entityType,
            viewCount: statsData['viewCount'] as int? ?? 0,
            rsvpCount: statsData['rsvpCount'] as int? ?? 0,
            shareCount: statsData['shareCount'] as int? ?? 0,
            commentCount: statsData['commentCount'] as int? ?? 0,
            ctr: (statsData['ctr'] as num?)?.toDouble() ?? 0.0,
            conversionRate:
                (statsData['conversionRate'] as num?)?.toDouble() ?? 0.0,
            engagementScore:
                (statsData['engagementScore'] as num?)?.toDouble() ?? 0.0,
            lastUpdated: DateTime.fromMillisecondsSinceEpoch(
              statsData['lastUpdated'] as int? ?? now,
            ),
            actionCounts:
                (statsData['actionCounts'] as Map<String, dynamic>?)?.map(
                      (key, value) => MapEntry(key, value as int),
                    ) ??
                    {},
          );

          // Cache in memory
          _statsCache[entityId] = stats;

          return stats;
        }
      } catch (e) {
        debugPrint('Error parsing cached stats: $e');
      }
    }

    try {
      // Get from Firestore
      final doc = await _statsCollection.doc(entityId).get();

      // Record Firebase operation
      FirebaseMonitor.recordRead();

      if (doc.exists) {
        final stats = InteractionStats.fromFirestore(doc);

        // Cache in memory
        _statsCache[entityId] = stats;

        // Cache locally
        _cacheStatsLocally(entityId, stats);

        return stats;
      } else {
        // Create empty stats object
        final emptyStats = InteractionStats.empty(entityId, entityType);

        // Cache in memory
        _statsCache[entityId] = emptyStats;

        return emptyStats;
      }
    } catch (e) {
      debugPrint('Error getting entity stats: $e');
      return InteractionStats.empty(entityId, entityType);
    }
  }

  /// Process pending interactions in a batch
  static Future<void> _processPendingInteractions() async {
    if (_pendingInteractions.isEmpty) return;

    try {
      final batch = _firestore.batch();
      final processedStats = <String, InteractionStats>{};

      // Process each interaction
      final interactionsToProcess =
          List<Map<String, dynamic>>.from(_pendingInteractions);
      _pendingInteractions.clear();

      // Group interactions by entity to minimize stats updates
      final groupedInteractions = <String, List<Map<String, dynamic>>>{};

      for (final interaction in interactionsToProcess) {
        final entityId = interaction['entityId'] as String;
        if (!groupedInteractions.containsKey(entityId)) {
          groupedInteractions[entityId] = [];
        }
        groupedInteractions[entityId]!.add(interaction);
      }

      // Process interactions in batches
      for (final interaction in interactionsToProcess) {
        // Add to batch
        final docRef = _interactionsCollection.doc();
        batch.set(docRef, interaction);
      }

      // Process entity stats
      for (final entry in groupedInteractions.entries) {
        final entityId = entry.key;
        final interactions = entry.value;

        // Only need to get stats once per entity
        if (!processedStats.containsKey(entityId)) {
          // Get entity type from first interaction
          final entityTypeStr = interactions.first['entityType'] as String;
          EntityType entityType;

          switch (entityTypeStr) {
            case 'event':
              entityType = EntityType.event;
              break;
            case 'space':
              entityType = EntityType.space;
              break;
            case 'profile':
              entityType = EntityType.profile;
              break;
            case 'post':
              entityType = EntityType.post;
              break;
            default:
              continue; // Skip unknown entity types
          }

          // Get current stats
          InteractionStats stats;
          if (_statsCache.containsKey(entityId)) {
            stats = _statsCache[entityId]!;
          } else {
            // Get from Firestore
            final statsDoc = await _statsCollection.doc(entityId).get();
            if (statsDoc.exists) {
              stats = InteractionStats.fromFirestore(statsDoc);
            } else {
              stats = InteractionStats.empty(entityId, entityType);
            }
          }

          // Process each interaction
          for (final interaction in interactions) {
            final actionStr = interaction['action'] as String;
            InteractionAction action;

            switch (actionStr) {
              case 'view':
                action = InteractionAction.view;
                break;
              case 'rsvp':
                action = InteractionAction.rsvp;
                break;
              case 'share':
                action = InteractionAction.share;
                break;
              case 'comment':
                action = InteractionAction.comment;
                break;
              case 'save':
                action = InteractionAction.save;
                break;
              case 'click':
                action = InteractionAction.click;
                break;
              default:
                continue; // Skip unknown actions
            }

            // Update stats
            stats = stats.incrementAction(action);
          }

          // Store updated stats
          processedStats[entityId] = stats;
        }
      }

      // Update stats documents
      for (final entry in processedStats.entries) {
        final statsRef = _statsCollection.doc(entry.key);
        batch.set(statsRef, entry.value.toFirestore(), SetOptions(merge: true));

        // Update memory cache
        _statsCache[entry.key] = entry.value;

        // Update local storage cache
        _cacheStatsLocally(entry.key, entry.value);
      }

      // Commit batch
      await batch.commit();

      // Clear pending interactions
      await _clearPendingInteractions();
    } catch (e) {
      debugPrint('Error processing interactions: $e');

      // Keep pending interactions for retry
      _savePendingInteractions();
    }
  }

  /// Start batch processing timer
  static void _startBatchProcessing() {
    _batchTimer?.cancel();
    _batchTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_pendingInteractions.isNotEmpty) {
        _processPendingInteractions();
      }
    });
  }

  /// Save pending interactions to local storage
  static Future<void> _savePendingInteractions() async {
    if (_pendingInteractions.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(_pendingInteractions);
      await prefs.setString(_pendingInteractionsKey, jsonData);
    } catch (e) {
      debugPrint('Error saving pending interactions: $e');
    }
  }

  /// Load pending interactions from local storage
  static Future<void> _loadPendingInteractions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = prefs.getString(_pendingInteractionsKey);

      if (jsonData != null) {
        final List<dynamic> data = jsonDecode(jsonData);
        _pendingInteractions.addAll(
          data.map((item) => item as Map<String, dynamic>).toList(),
        );
      }
    } catch (e) {
      debugPrint('Error loading pending interactions: $e');
    }
  }

  /// Clear pending interactions from local storage
  static Future<void> _clearPendingInteractions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingInteractionsKey);
    } catch (e) {
      debugPrint('Error clearing pending interactions: $e');
    }
  }

  /// Update entity stats with a new interaction
  static Future<void> _updateEntityStats(
    String entityId,
    EntityType entityType,
    InteractionAction action,
  ) async {
    try {
      // Get current stats (from cache or Firestore)
      final InteractionStats currentStats =
          await getEntityStats(entityId, entityType);

      // Update stats with new interaction
      final updatedStats = currentStats.incrementAction(action);

      // Update Firestore
      await _statsCollection.doc(entityId).set(
            updatedStats.toFirestore(),
            SetOptions(merge: true),
          );

      // Update memory cache
      _statsCache[entityId] = updatedStats;

      // Update local storage cache
      _cacheStatsLocally(entityId, updatedStats);
    } catch (e) {
      debugPrint('Error updating entity stats: $e');
    }
  }

  /// Update local cache with new interaction
  static void _updateLocalCache(
    String entityId,
    EntityType entityType,
    InteractionAction action,
  ) {
    // Update memory cache if exists
    if (_statsCache.containsKey(entityId)) {
      final currentStats = _statsCache[entityId]!;
      final updatedStats = currentStats.incrementAction(action);
      _statsCache[entityId] = updatedStats;

      // Update local storage asynchronously
      _cacheStatsLocally(entityId, updatedStats);
    }
  }

  /// Cache interaction stats in local storage
  static Future<void> _cacheStatsLocally(
    String entityId,
    InteractionStats stats,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert to serializable map
      final statsMap = {
        'cachedAt': DateTime.now().millisecondsSinceEpoch,
        'stats': {
          'entityId': stats.entityId,
          'entityType': stats.entityType.toString().split('.').last,
          'viewCount': stats.viewCount,
          'rsvpCount': stats.rsvpCount,
          'shareCount': stats.shareCount,
          'commentCount': stats.commentCount,
          'ctr': stats.ctr,
          'conversionRate': stats.conversionRate,
          'engagementScore': stats.engagementScore,
          'lastUpdated': stats.lastUpdated.millisecondsSinceEpoch,
          'actionCounts': stats.actionCounts,
        },
      };

      // Save to local storage
      await prefs.setString(
        '$_statsCacheKey:$entityId',
        jsonEncode(statsMap),
      );
    } catch (e) {
      debugPrint('Error caching stats locally: $e');
    }
  }

  /// Generate a unique session ID
  static String _generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp % 10000;
    return 'session_${timestamp}_$random';
  }

  /// Dispose the service
  static void dispose() {
    _batchTimer?.cancel();
    _batchTimer = null;

    // Process any pending interactions
    if (_pendingInteractions.isNotEmpty) {
      _processPendingInteractions();
    }
  }
}
