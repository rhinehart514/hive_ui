import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/services/firebase/firebase_core_service.dart';
import 'package:hive_ui/core/services/firebase/fcm_token_manager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_ui/features/notifications/presentation/notification_handler.dart';

/// Service for handling Firebase Cloud Messaging
class FirebaseMessagingService {
  static FirebaseMessagingService? _instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _isInitialized = false;
  
  // Local notifications plugin for displaying notifications when app is in foreground
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final AndroidNotificationChannel _channel = const AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

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

      // Set up local notifications
      await _setupLocalNotifications();

      // Request permission for notifications
      try {
        final settings = await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          debugPrint('Notification permissions granted');
          
          // Initialize the FCM token manager to handle token storage
          await FCMTokenManager.instance.initialize();

          // Set up background message handler
          FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
          
          // Handle incoming messages when the app is in the foreground
          FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

          // Handle message opens when the app is in the background
          FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
          
          // Handle initial message (app was terminated)
          _checkForInitialMessage();
          
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

  // Check if app was opened from a notification
  Future<void> _checkForInitialMessage() async {
    try {
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('App was opened from terminated state by notification');
        // Delay handling to ensure app is fully initialized
        Future.delayed(const Duration(seconds: 1), () {
          _handleBackgroundMessage(initialMessage);
        });
      }
    } catch (e) {
      debugPrint('Error checking for initial message: $e');
    }
  }

  // Set up local notifications for foreground messages
  Future<void> _setupLocalNotifications() async {
    // Initialize Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Initialize iOS notification settings
    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification clicked: ${response.payload}');
        
        // Process the notification click
        if (response.payload != null) {
          try {
            final data = <String, dynamic>{
              'type': response.payload,
              // Extract any other data from the payload if available
            };
            
            // Use the notification handler to process this tap
            NotificationHandler.instance.handleNotificationTap(data);
          } catch (e) {
            debugPrint('Error processing notification tap: $e');
          }
        }
      },
    );
  }

  void _handleForegroundMessage(RemoteMessage message) {
    try {
      debugPrint('Received foreground message: ${message.messageId}');
      
      final notification = message.notification;
      final android = message.notification?.android;
      
      // If notification payload is available, display a local notification
      if (notification != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              icon: android?.smallIcon ?? 'mipmap/ic_launcher',
              // Add a custom sound if needed
              // sound: RawResourceAndroidNotificationSound('notification_sound'),
            ),
            iOS: const DarwinNotificationDetails(
              // Add custom sound for iOS if needed
              // sound: 'notification_sound.aiff',
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: message.data['type'],
        );
      }
    } catch (e) {
      debugPrint('Error handling foreground message: $e');
    }
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    try {
      debugPrint('Opened app from background message: ${message.messageId}');
      
      // Use the notification handler to process this message
      NotificationHandler.instance.processRemoteMessage(message);
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
  
  // Clean up resources when service is disposed
  Future<void> dispose() async {
    if (_isInitialized) {
      await FCMTokenManager.instance.clearToken();
    }
  }
}

/// Background message handler that runs when the app is in the background or terminated
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Need to initialize Firebase Core since this runs in an isolated environment
  await FirebaseCoreService.instance.initializeWithRetry();
  
  debugPrint('Handling a background message: ${message.messageId}');
  // No need to do more processing here - we'll handle the notification
  // when the user taps on it and the app is opened
}

/// Provider for the Firebase Messaging service
final firebaseMessagingServiceProvider = Provider<FirebaseMessagingService>((ref) {
  final service = FirebaseMessagingService.instance;
  
  // Clean up on provider disposal
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});
