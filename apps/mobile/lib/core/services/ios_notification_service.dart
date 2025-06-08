import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Service to handle iOS-specific notification setup and handling.
/// 
/// This includes:
/// - Requesting notification permissions
/// - Configuring notification presentation options
/// - Handling notification responses
class IOSNotificationService {
  /// Singleton instance
  static final IOSNotificationService _instance = IOSNotificationService._internal();
  
  /// Factory constructor
  factory IOSNotificationService() => _instance;
  
  /// Private constructor
  IOSNotificationService._internal();
  
  /// Local notifications plugin instance
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  /// Firebase messaging instance
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  /// Notification permission status
  bool _hasPermission = false;
  
  /// Returns true if the app has notification permission
  bool get hasPermission => _hasPermission;
  
  /// Initialize iOS notifications
  Future<void> initialize() async {
    if (!Platform.isIOS) return;
    
    // iOS-specific initialization settings
    final DarwinInitializationSettings iOSSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
      notificationCategories: _createNotificationCategories(),
    );
    
    // Initialize the notifications plugin
    final InitializationSettings initSettings = InitializationSettings(
      iOS: iOSSettings,
      // Add other platform settings as needed
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
    
    // Configure iOS foreground notification presentation options
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    
    // Request notification permission
    await _requestPermission();
    
    debugPrint('iOS notification service initialized');
  }
  
  /// Create iOS notification categories (action buttons)
  List<DarwinNotificationCategory> _createNotificationCategories() {
    // Event notification category with "View" and "RSVP" actions
    final eventCategory = DarwinNotificationCategory(
      'event_category',
      actions: [
        DarwinNotificationAction.plain(
          'view_event',
          'View',
          options: {DarwinNotificationActionOption.foreground},
        ),
        DarwinNotificationAction.plain(
          'rsvp_event',
          'RSVP',
          options: {DarwinNotificationActionOption.foreground},
        ),
      ],
      options: {
        DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
      },
    );
    
    // Message notification category with "Reply" action
    final messageCategory = DarwinNotificationCategory(
      'message_category',
      actions: [
        DarwinNotificationAction.plain(
          'reply_message', 
          'Reply',
          options: {DarwinNotificationActionOption.foreground},
        ),
      ],
    );
    
    return [eventCategory, messageCategory];
  }
  
  /// Request notification permission
  Future<void> _requestPermission() async {
    if (!Platform.isIOS) return;
    
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );
    
    _hasPermission = settings.authorizationStatus == AuthorizationStatus.authorized || 
                     settings.authorizationStatus == AuthorizationStatus.provisional;
                     
    debugPrint('iOS notification permission status: ${settings.authorizationStatus}');
  }
  
  /// Handle notification responses (when user taps on notification)
  void _onNotificationResponse(NotificationResponse response) {
    // Handle the notification response
    final String? payload = response.payload;
    final String? actionId = response.actionId;
    
    debugPrint('Notification response: $actionId with payload: $payload');
    
    // Handle specific action IDs
    if (actionId == 'view_event') {
      _handleViewEvent(payload);
    } else if (actionId == 'rsvp_event') {
      _handleRSVPEvent(payload);
    } else if (actionId == 'reply_message') {
      _handleReplyMessage(payload);
    } else if (payload != null) {
      // Default action (notification was tapped without specific action)
      _handleNotificationTap(payload);
    }
  }
  
  /// Handle the "View Event" action
  void _handleViewEvent(String? payload) {
    if (payload == null) return;
    // Example implementation - parse event ID from payload
    // final eventId = json.decode(payload)['eventId'];
    // Navigate to event details page
    debugPrint('Handle View Event with payload: $payload');
  }
  
  /// Handle the "RSVP" action
  void _handleRSVPEvent(String? payload) {
    if (payload == null) return;
    // Example implementation - parse event ID and show RSVP dialog
    debugPrint('Handle RSVP Event with payload: $payload');
  }
  
  /// Handle the "Reply" action
  void _handleReplyMessage(String? payload) {
    if (payload == null) return;
    // Example implementation - parse message data and show reply screen
    debugPrint('Handle Reply Message with payload: $payload');
  }
  
  /// Handle a general notification tap
  void _handleNotificationTap(String payload) {
    // Parse the payload and navigate to appropriate screen
    debugPrint('Handle notification tap with payload: $payload');
  }
  
  /// Show a local notification with iOS-specific configuration
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? imageUrl,
    String? category,
  }) async {
    if (!Platform.isIOS) return;
    
    // Configure iOS-specific notification details
    final DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      badgeNumber: 1,
      categoryIdentifier: category,
      // Attachments require file paths, not URLs - would need to download image first
      // attachments: imageUrl != null ? [DarwinNotificationAttachment(downloadedFilePath)] : null,
    );
    
    final NotificationDetails details = NotificationDetails(iOS: iOSDetails);
    
    // Show the notification
    await _localNotifications.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }
  
  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    if (!Platform.isIOS) return;
    
    await _localNotifications.cancelAll();
  }
  
  /// Set the app badge count (iOS-specific)
  Future<void> setBadgeCount(int count) async {
    if (!Platform.isIOS) return;
    
    try {
      // For iOS, directly set the badge number on the notification plugin
      await _localNotifications.initialize(
        const InitializationSettings(),
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );
      
      // Set badge using local notifications (alternative approach)
      await _localNotifications.show(
        0,
        '',
        '',
        const NotificationDetails(
          iOS: DarwinNotificationDetails(
            presentAlert: false,
            presentBadge: true,
            presentSound: false,
            badgeNumber: 0,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error setting badge count: $e');
    }
  }
  
  /// Reset the app badge count to zero
  Future<void> resetBadgeCount() async {
    await setBadgeCount(0);
  }
} 