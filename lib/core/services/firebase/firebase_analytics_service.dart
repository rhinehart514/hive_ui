import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/services/firebase/firebase_core_service.dart';

/// Service for handling Firebase Analytics
class FirebaseAnalyticsService {
  static FirebaseAnalyticsService? _instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  bool _isInitialized = false;

  FirebaseAnalyticsService._();

  static FirebaseAnalyticsService get instance {
    _instance ??= FirebaseAnalyticsService._();
    return _instance!;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final coreService = FirebaseCoreService.instance;
      if (!coreService.isInitialized) {
        debugPrint('Firebase Core must be initialized before Analytics - initializing core first');
        await coreService.initializeWithRetry();
      }

      // Only enable analytics in non-debug mode or when explicitly testing analytics
      if (!kDebugMode) {
        await _analytics.setAnalyticsCollectionEnabled(true);
      } else {
        debugPrint('Analytics collection disabled in debug mode');
      }
      
      _isInitialized = true;
      debugPrint('Firebase Analytics initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Firebase Analytics: $e');
      // Don't rethrow - we want to fail gracefully
      _isInitialized = false;
    }
  }

  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    if (!_isInitialized) {
      debugPrint('Analytics not initialized, skipping event: $name');
      return;
    }
    
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (e) {
      debugPrint('Error logging analytics event: $e');
    }
  }

  Future<void> setUserProperties({
    required String userId,
    Map<String, String>? properties,
  }) async {
    if (!_isInitialized) {
      debugPrint('Analytics not initialized, skipping user properties for: $userId');
      return;
    }
    
    try {
      await _analytics.setUserId(id: userId);
      
      if (properties != null) {
        for (final entry in properties.entries) {
          await _analytics.setUserProperty(
            name: entry.key,
            value: entry.value,
          );
        }
      }
    } catch (e) {
      debugPrint('Error setting user properties: $e');
    }
  }
}

/// Provider for the Firebase Analytics service
final firebaseAnalyticsServiceProvider = Provider<FirebaseAnalyticsService>((ref) {
  return FirebaseAnalyticsService.instance;
});
