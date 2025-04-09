import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/cache/cache_manager.dart';
import 'package:hive_ui/core/cache/cache_providers.dart';
import 'package:hive_ui/features/analytics/data/models/analytics_event_model.dart';
import 'package:hive_ui/features/analytics/data/models/user_metrics_model.dart';
import 'package:hive_ui/features/analytics/domain/entities/analytics_event_entity.dart';

/// Repository interface for analytics operations
abstract class AnalyticsRepository {
  /// Track an analytics event
  Future<void> trackEvent({
    required AnalyticsEventType eventType,
    required Map<String, dynamic> properties,
    String? userId,
  });
  
  /// Get user metrics data
  Future<UserMetricsModel?> getUserMetrics(String userId);
  
  /// Get recent events for a user
  Future<List<AnalyticsEventModel>> getUserEvents(
    String userId, {
    int limit = 50,
    AnalyticsEventType? eventType,
  });
  
  /// Export user analytics data
  Future<Map<String, dynamic>> exportUserAnalytics(String userId);
}

/// Implementation of the analytics repository
class FirebaseAnalyticsRepository implements AnalyticsRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final CacheManager _cacheManager;
  
  FirebaseAnalyticsRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required CacheManager cacheManager,
  }) : 
    _firestore = firestore,
    _auth = auth,
    _cacheManager = cacheManager;
  
  @override
  Future<void> trackEvent({
    required AnalyticsEventType eventType,
    required Map<String, dynamic> properties,
    String? userId,
  }) async {
    try {
      // Get current user ID if not provided
      final uid = userId ?? _auth.currentUser?.uid;
      if (uid == null) {
        debugPrint('⚠️ Cannot track event: No user ID');
        return;
      }
      
      // Create analytics event
      final event = AnalyticsEventModel(
        eventType: eventType.value,
        userId: uid,
        properties: properties,
      );
      
      // Store in Firestore
      await _firestore
        .collection('analytics')
        .doc('events')
        .collection('user_events')
        .add(event.toFirestore());
      
      // Update metrics (with batched write)
      await _updateUserMetrics(uid, eventType);
      
      debugPrint('✅ Tracked event: ${eventType.value}');
    } catch (e) {
      debugPrint('⚠️ Error tracking event: $e');
    }
  }
  
  /// Update user metrics based on event type
  Future<void> _updateUserMetrics(String userId, AnalyticsEventType eventType) async {
    try {
      // Get reference to user metrics document
      final metricsRef = _firestore
        .collection('analytics')
        .doc('metrics')
        .collection('user_metrics')
        .doc(userId);
      
      // Update metrics with transaction to prevent race conditions
      await _firestore.runTransaction((transaction) async {
        final metricsDoc = await transaction.get(metricsRef);
        
        // Create or update metrics
        UserMetricsModel metrics;
        if (metricsDoc.exists) {
          metrics = UserMetricsModel.fromFirestore(metricsDoc);
        } else {
          metrics = UserMetricsModel(userId: userId);
        }
        
        // Update based on event type
        switch (eventType) {
          case AnalyticsEventType.profileView:
            metrics = metrics.incrementMetric('profileViews');
            break;
          case AnalyticsEventType.contentCreate:
          case AnalyticsEventType.contentEdit:
            metrics = metrics.incrementMetric('contentCreated');
            break;
          case AnalyticsEventType.contentReaction:
          case AnalyticsEventType.contentShare:
            metrics = metrics.incrementMetric('contentEngagement');
            break;
          case AnalyticsEventType.spaceJoin:
            metrics = metrics.incrementMetric('spacesJoined');
            break;
          case AnalyticsEventType.eventRsvp:
            metrics = metrics.incrementMetric('eventsAttended');
            break;
          default:
            // For all events, track hourly and daily activity
            break;
        }
        
        // Always track hourly and daily activity
        metrics = metrics.trackHourlyActivity();
        metrics = metrics.trackDailyActivity();
        
        // Update the document
        transaction.set(metricsRef, metrics.toFirestore());
        
        // Invalidate cache
        _cacheManager.invalidateCache('analytics:metrics:$userId');
      });
    } catch (e) {
      debugPrint('⚠️ Error updating user metrics: $e');
    }
  }
  
  @override
  Future<UserMetricsModel?> getUserMetrics(String userId) async {
    try {
      return await _cacheManager.getOrCompute<UserMetricsModel?>(
        'analytics:metrics:$userId',
        () async {
          final doc = await _firestore
            .collection('analytics')
            .doc('metrics')
            .collection('user_metrics')
            .doc(userId)
            .get();
          
          if (doc.exists) {
            return UserMetricsModel.fromFirestore(doc);
          }
          
          return UserMetricsModel(userId: userId);
        },
        ttl: const Duration(minutes: 15), // Cache for 15 minutes
      );
    } catch (e) {
      debugPrint('⚠️ Error getting user metrics: $e');
      return null;
    }
  }
  
  @override
  Future<List<AnalyticsEventModel>> getUserEvents(
    String userId, {
    int limit = 50,
    AnalyticsEventType? eventType,
  }) async {
    try {
      String cacheKey = 'analytics:events:$userId';
      if (eventType != null) {
        cacheKey += ':${eventType.value}';
      }
      
      return await _cacheManager.getOrCompute<List<AnalyticsEventModel>>(
        cacheKey,
        () async {
          Query query = _firestore
            .collection('analytics')
            .doc('events')
            .collection('user_events')
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .limit(limit);
          
          // Add event type filter if provided
          if (eventType != null) {
            query = query.where('eventType', isEqualTo: eventType.value);
          }
          
          final snapshot = await query.get();
          return snapshot.docs
            .map((doc) => AnalyticsEventModel.fromFirestore(doc))
            .toList();
        },
        ttl: const Duration(minutes: 5), // Cache for 5 minutes
      );
    } catch (e) {
      debugPrint('⚠️ Error getting user events: $e');
      return [];
    }
  }
  
  @override
  Future<Map<String, dynamic>> exportUserAnalytics(String userId) async {
    try {
      // Get user metrics
      final metrics = await getUserMetrics(userId);
      
      // Get recent events (up to 500)
      final events = await getUserEvents(userId, limit: 500);
      
      // Format for export
      return {
        'userId': userId,
        'exportDate': DateTime.now().toIso8601String(),
        'metrics': metrics?.toFirestore() ?? {},
        'recentEvents': events.map((e) => e.toFirestore()).toList(),
      };
    } catch (e) {
      debugPrint('⚠️ Error exporting user analytics: $e');
      return {
        'error': 'Failed to export analytics',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}

/// Provider for the analytics repository
final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  final cacheManager = ref.watch(cacheManagerProvider);
  
  return FirebaseAnalyticsRepository(
    firestore: firestore,
    auth: auth,
    cacheManager: cacheManager,
  );
}); 