import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/services/firebase/firebase_core_service.dart';

/// Service for handling Firebase Cloud Messaging
class FirebaseMessagingService {
  static FirebaseMessagingService? _instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _isInitialized = false;

  FirebaseMessagingService._();

  static FirebaseMessagingService get instance {
    _instance ??= FirebaseMessagingService._();
    return _instance!;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final coreService = FirebaseCoreService.instance;
      if (!coreService.isInitialized) {
        debugPrint('Firebase Core must be initialized before Messaging - initializing core first');
        await coreService.initializeWithRetry();
        if (!coreService.isInitialized) {
          throw Exception('Firebase Core initialization failed');
        }
      }

      // Skip actual initialization in debug mode to prevent potential issues
      if (kDebugMode) {
        debugPrint('Messaging setup skipped in debug mode');
        _isInitialized = true;
        return;
      }

      // Request permission for notifications
      try {
        final settings = await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          debugPrint('Notification permissions granted');
          
          // Get the token
          await coreService.runWithErrorHandling<String?>(
            () async => await _messaging.getToken(),
            operationName: 'Get FCM Token',
          ).then((token) {
            if (token != null) {
              debugPrint('FCM Token received successfully');
            }
          });

          // Handle incoming messages when the app is in the foreground
          FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

          // Handle message opens when the app is in the background
          FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
          
          _isInitialized = true;
          debugPrint('Firebase Messaging initialized successfully');
        } else {
          debugPrint('User declined or has not accepted notification permissions');
          _isInitialized = true; // Still mark as initialized but with limited functionality
        }
      } catch (e) {
        debugPrint('Error requesting notification permissions: $e');
        _isInitialized = false;
      }
    } catch (e) {
      debugPrint('Error initializing Firebase Messaging: $e');
      _isInitialized = false;
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    try {
      debugPrint('Received foreground message: ${message.messageId}');
      // TODO: Implement foreground message handling
    } catch (e) {
      debugPrint('Error handling foreground message: $e');
    }
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    try {
      debugPrint('Opened app from background message: ${message.messageId}');
      // TODO: Implement background message handling
    } catch (e) {
      debugPrint('Error handling background message: $e');
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    if (!_isInitialized) {
      debugPrint('Messaging not initialized, skipping topic subscription to: $topic');
      return;
    }
    
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('Successfully subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic $topic: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    if (!_isInitialized) {
      debugPrint('Messaging not initialized, skipping topic unsubscription from: $topic');
      return;
    }
    
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('Successfully unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic $topic: $e');
    }
  }
}

/// Provider for the Firebase Messaging service
final firebaseMessagingServiceProvider = Provider<FirebaseMessagingService>((ref) {
  return FirebaseMessagingService.instance;
});
