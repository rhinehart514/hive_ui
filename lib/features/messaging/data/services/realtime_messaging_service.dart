import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/utils/firebase_threading_fix.dart';
import 'package:hive_ui/utils/realtime_db_windows_fix.dart';

/// Service for real-time messaging features using Firebase Realtime Database
/// This service handles typing indicators, online status, and message delivery status
class RealtimeMessagingService {
  final FirebaseDatabase _database;

  // Root paths in Realtime Database
  static const String _typingPath = 'typing';
  static const String _onlinePath = 'online';
  static const String _deliveryPath = 'messageDelivery';

  // Typing expiration in seconds
  static const int _typingExpirationSeconds = 10;

  RealtimeMessagingService({FirebaseDatabase? database})
      : _database = database ?? FirebaseDatabase.instance {
    _initDatabase();
  }

  void _initDatabase() {
    try {
      // Apply Windows-specific fixes if needed
      RealtimeDbWindowsFix.initialize();
      
      // Only enable persistence on non-Windows platforms
      if (defaultTargetPlatform != TargetPlatform.windows) {
        // Enable persistence for offline support
        _database.setPersistenceEnabled(true);
        
        // Set cache size (default is 10MB)
        _database.setPersistenceCacheSizeBytes(10 * 1024 * 1024); // 10MB
      }
      
      debugPrint('RealtimeMessagingService initialized successfully');
    } catch (e) {
      debugPrint('Error setting up Realtime Database: $e');
    }
  }

  // TYPING INDICATORS

  /// Updates the typing status of a user in a chat
  Future<void> updateTypingStatus(String chatId, String userId, bool isTyping) async {
    try {
      return await RealtimeDbWindowsFix.runOperation(() async {
        final ref = _database.ref('$_typingPath/$chatId/$userId');
        
        if (isTyping) {
          // Set server timestamp when typing starts/continues
          await ref.set(ServerValue.timestamp);
        } else {
          // Remove the typing indicator when typing stops
          await ref.remove();
        }
      });
    } catch (e) {
      debugPrint('Error updating typing status: $e');
    }
  }

  /// Gets a stream of typing indicators for a chat
  Stream<Map<String, DateTime>> getTypingIndicatorsStream(String chatId) {
    try {
      final ref = _database.ref('$_typingPath/$chatId');
      
      return ref.onValue.map((event) {
        final snapshot = event.snapshot;
        final Map<String, DateTime> typingUsers = {};
        
        if (snapshot.exists && snapshot.value is Map) {
          final typingData = snapshot.value as Map<dynamic, dynamic>;
          
          typingData.forEach((userId, timestamp) {
            if (userId is String && timestamp is int) {
              final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
              
              // Only consider users typing in the last 10 seconds
              if (DateTime.now().difference(dateTime).inSeconds < _typingExpirationSeconds) {
                typingUsers[userId] = dateTime;
              }
            }
          });
        }
        
        return typingUsers;
      }).switchToUiThread();
    } catch (e) {
      debugPrint('Error getting typing indicators stream: $e');
      // Return an empty stream on error
      return Stream.value({});
    }
  }

  // ONLINE STATUS

  /// Updates a user's online status
  Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    try {
      return await RealtimeDbWindowsFix.runOperation(() async {
        final ref = _database.ref('$_onlinePath/$userId');
        
        if (isOnline) {
          // Set presence and last active timestamp
          await ref.set({
            'online': true,
            'lastActive': ServerValue.timestamp,
          });
          
          // Set up an onDisconnect operation to update status when client disconnects
          await ref.onDisconnect().update({
            'online': false,
            'lastActive': ServerValue.timestamp,
          });
        } else {
          // Explicitly set offline and cancel any pending onDisconnect operations
          await ref.update({
            'online': false,
            'lastActive': ServerValue.timestamp,
          });
          await ref.onDisconnect().cancel();
        }
      });
    } catch (e) {
      debugPrint('Error updating online status: $e');
    }
  }

  /// Gets a stream of online status for a list of users
  Stream<Map<String, bool>> getOnlineStatusStream(List<String> userIds) {
    if (userIds.isEmpty) return Stream.value({});
    
    // Create a controller to merge multiple streams
    final controller = StreamController<Map<String, bool>>.broadcast();
    final onlineStatus = <String, bool>{};
    
    // Listen to each user's online status
    for (final userId in userIds) {
      final ref = _database.ref('$_onlinePath/$userId/online');
      
      ref.onValue.listen((event) {
        final snapshot = event.snapshot;
        
        if (snapshot.exists && snapshot.value is bool) {
          onlineStatus[userId] = snapshot.value as bool;
        } else {
          onlineStatus[userId] = false;
        }
        
        controller.add(Map<String, bool>.from(onlineStatus));
      }, onError: (error) {
        debugPrint('Error in online status stream for $userId: $error');
      });
    }
    
    return controller.stream.switchToUiThread();
  }

  /// Gets a single user's online status
  Future<bool> getUserOnlineStatus(String userId) async {
    try {
      return await RealtimeDbWindowsFix.runOperation(() async {
        final ref = _database.ref('$_onlinePath/$userId/online');
        final snapshot = await ref.get();
        
        if (snapshot.exists && snapshot.value is bool) {
          return snapshot.value as bool;
        }
        
        return false;
      });
    } catch (e) {
      debugPrint('Error getting user online status: $e');
      return false;
    }
  }

  /// Gets a user's last active timestamp
  Future<DateTime?> getUserLastActive(String userId) async {
    try {
      return await RealtimeDbWindowsFix.runOperation(() async {
        final ref = _database.ref('$_onlinePath/$userId/lastActive');
        final snapshot = await ref.get();
        
        if (snapshot.exists && snapshot.value is int) {
          return DateTime.fromMillisecondsSinceEpoch(snapshot.value as int);
        }
        
        return null;
      });
    } catch (e) {
      debugPrint('Error getting user last active: $e');
      return null;
    }
  }

  // MESSAGE DELIVERY STATUS

  /// Updates the delivery status of a message
  Future<void> updateMessageDeliveryStatus(
    String messageId,
    String receiverId,
    MessageDeliveryStatus status,
  ) async {
    try {
      return await RealtimeDbWindowsFix.runOperation(() async {
        final ref = _database.ref('$_deliveryPath/$messageId/$receiverId');
        
        await ref.set({
          'status': status.index,
          'timestamp': ServerValue.timestamp,
        });
      });
    } catch (e) {
      debugPrint('Error updating message delivery status: $e');
    }
  }

  /// Gets a stream of delivery status updates for a message
  Stream<Map<String, MessageDeliveryStatus>> getMessageDeliveryStatusStream(String messageId) {
    final ref = _database.ref('$_deliveryPath/$messageId');
    
    return ref.onValue.map((event) {
      final snapshot = event.snapshot;
      final Map<String, MessageDeliveryStatus> deliveryStatus = {};
      
      if (snapshot.exists && snapshot.value is Map) {
        final statusData = snapshot.value as Map<dynamic, dynamic>;
        
        statusData.forEach((userId, data) {
          if (userId is String && data is Map && data.containsKey('status')) {
            final statusIndex = data['status'] as int;
            if (statusIndex >= 0 && statusIndex < MessageDeliveryStatus.values.length) {
              deliveryStatus[userId] = MessageDeliveryStatus.values[statusIndex];
            }
          }
        });
      }
      
      return deliveryStatus;
    }).switchToUiThread();
  }

  /// Cleanup method to call when disposing the service
  void dispose() {
    // Nothing to dispose at the moment
  }
}

/// Enum representing message delivery status
enum MessageDeliveryStatus {
  sent,       // Message sent to server
  delivered,  // Message delivered to recipient's device
  read        // Message read by recipient
} 