import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Handles navigation and actions when notifications are tapped
class NotificationHandler {
  static NotificationHandler? _instance;
  
  // Router for navigation
  GoRouter? _router;
  // Context reference needed for some navigation scenarios
  BuildContext? _context;
  
  NotificationHandler._();

  static NotificationHandler get instance {
    _instance ??= NotificationHandler._();
    return _instance!;
  }
  
  /// Set up the handler with navigation tools
  void setup({GoRouter? router, BuildContext? context}) {
    _router = router;
    _context = context;
  }
  
  /// Handle a notification tap based on the message data
  Future<void> handleNotificationTap(Map<String, dynamic> data) async {
    try {
      if (_router == null) {
        debugPrint('Cannot handle notification tap - router not set');
        return;
      }
      
      final notificationType = data['type'] as String?;
      
      switch (notificationType) {
        case 'message':
          final messageId = data['messageId'] as String?;
          final senderId = data['senderId'] as String?;
          
          if (messageId != null && senderId != null) {
            _router!.push('/chat/$senderId');
          }
          break;
          
        case 'event':
          final eventId = data['eventId'] as String?;
          
          if (eventId != null) {
            _router!.push('/event/$eventId');
          }
          break;
          
        case 'invitation':
          final invitationId = data['invitationId'] as String?;
          
          if (invitationId != null) {
            _router!.push('/invitations');
          }
          break;
          
        default:
          debugPrint('Unknown notification type: $notificationType');
          // Default to home screen
          _router!.go('/');
      }
    } catch (e) {
      debugPrint('Error handling notification tap: $e');
    }
  }
  
  /// Process a newly received RemoteMessage
  void processRemoteMessage(RemoteMessage message) {
    final data = message.data;
    
    if (data.isNotEmpty) {
      handleNotificationTap(data);
    }
  }
}

/// Provider for the notification handler
final notificationHandlerProvider = Provider<NotificationHandler>((ref) {
  return NotificationHandler.instance;
}); 