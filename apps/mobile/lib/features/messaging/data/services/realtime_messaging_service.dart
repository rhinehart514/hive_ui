import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/utils/firebase_threading_fix.dart';
import 'package:hive_ui/utils/realtime_db_windows_fix.dart';

/// Service for real-time messaging features using Firebase Realtime Database
/// This service handles typing indicators, online status, and message delivery status
class RealtimeMessagingService {
  final FirebaseDatabase _database;
  final Map<String, StreamController<dynamic>> _controllers = {};
  bool _isInitialized = false;
  
  // Flag to track if we're running on Windows
  final bool _isWindowsPlatform = defaultTargetPlatform == TargetPlatform.windows;

  // Root paths in Realtime Database
  static const String _typingPath = 'typing';
  static const String _onlinePath = 'online';
  static const String _deliveryPath = 'messageDelivery';

  // Typing expiration in seconds
  static const int _typingExpirationSeconds = 10;

  RealtimeMessagingService({
    FirebaseDatabase? database,
  }) : _database = database ?? FirebaseDatabase.instance {
    // Initialize Windows fixes if needed
    if (_isWindowsPlatform) {
      debugPrint('🔧 RealtimeMessagingService initialized with Windows compatibility');
      // Windows doesn't fully support Realtime Database, so we'll initialize with stubbed functionality
      _isInitialized = true; // Mark as initialized to prevent initialization loops
    }
  }

  // TYPING INDICATORS

  /// Updates the typing status of a user in a chat
  Future<void> updateTypingStatus(String chatId, String userId, bool isTyping) async {
    if (!_isInitialized) {
      debugPrint('RealtimeMessagingService not initialized');
      return;
    }
    
    // Skip actual database operations on Windows
    if (_isWindowsPlatform) {
      debugPrint('🪟 Skipping updateTypingStatus on Windows');
      return;
    }
    
    try {
      return await RealtimeDbWindowsFix.safeOperation<void>(() async {
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
    // Return empty stream on Windows
    if (_isWindowsPlatform) {
      debugPrint('🪟 Returning empty typing indicators stream on Windows');
      return Stream.value({});
    }
    
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
    if (!_isInitialized) {
      debugPrint('RealtimeMessagingService not initialized');
      return;
    }
    
    // Skip actual database operations on Windows
    if (_isWindowsPlatform) {
      debugPrint('🪟 Skipping updateOnlineStatus on Windows');
      return;
    }
    
    try {
      return await RealtimeDbWindowsFix.safeOperation<void>(() async {
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
    // Return all users as offline on Windows
    if (_isWindowsPlatform) {
      debugPrint('🪟 Returning offline status for all users on Windows');
      return Stream.value(Map.fromEntries(userIds.map((id) => MapEntry(id, false))));
    }
    
    if (userIds.isEmpty) return Stream.value({});
    
    // For a single user, just use a direct stream mapping
    if (userIds.length == 1) {
      final userId = userIds.first;
      final ref = _database.ref('$_onlinePath/$userId/online');
      
      return ref.onValue.map((event) {
        final snapshot = event.snapshot;
        final bool isOnline = (snapshot.exists && snapshot.value is bool) 
            ? snapshot.value as bool 
            : false;
        return {userId: isOnline};
      }).switchToUiThread();
    }
    
    // For multiple users, create a merged stream
    // Create a broadcast stream that will be automatically closed when no longer listened to
    final controller = StreamController<Map<String, bool>>.broadcast();
    final controllerId = 'online_status_${DateTime.now().millisecondsSinceEpoch}';
    _controllers[controllerId] = controller;
    
    // Initialize status map
    final onlineStatus = <String, bool>{};
    for (final userId in userIds) {
      onlineStatus[userId] = false; // Default to offline
    }
    
    // Add a subscription for each user's online status
    final subscriptions = <StreamSubscription>[];
    
    for (final userId in userIds) {
      final ref = _database.ref('$_onlinePath/$userId/online');
      
      final subscription = ref.onValue.listen((event) {
        final snapshot = event.snapshot;
        
        if (snapshot.exists && snapshot.value is bool) {
          onlineStatus[userId] = snapshot.value as bool;
        } else {
          onlineStatus[userId] = false;
        }
        
        if (!controller.isClosed) {
          controller.add(Map<String, bool>.from(onlineStatus));
        }
      }, onError: (error) {
        debugPrint('Error in online status stream for $userId: $error');
      });
      
      subscriptions.add(subscription);
    }
    
    // Clean up when the stream is no longer needed
    controller.onCancel = () {
      // Cancel all subscriptions
      for (final subscription in subscriptions) {
        subscription.cancel();
      }
      
      // Remove from tracked controllers and close
      _controllers.remove(controllerId);
      controller.close();
    };
    
    return controller.stream.switchToUiThread();
  }

  /// Gets a single user's online status
  Future<bool> getUserOnlineStatus(String userId) async {
    // Always return offline on Windows
    if (_isWindowsPlatform) {
      debugPrint('🪟 Returning offline status on Windows for user $userId');
      return false; 
    }
    
    try {
      return await RealtimeDbWindowsFix.safeOperation<bool>(() async {
        final ref = _database.ref('$_onlinePath/$userId/online');
        final snapshot = await ref.get();
        
        if (snapshot.exists && snapshot.value is bool) {
          return snapshot.value as bool;
        }
        
        return false;
      }, defaultValue: false) ?? false;
    } catch (e) {
      debugPrint('Error getting user online status: $e');
      return false;
    }
  }

  /// Gets a user's last active timestamp
  Future<DateTime?> getUserLastActive(String userId) async {
    // Return current time on Windows
    if (_isWindowsPlatform) {
      debugPrint('🪟 Returning current time as last active on Windows for user $userId');
      return DateTime.now().subtract(const Duration(minutes: 5)); // Pretend user was active 5 min ago
    }
    
    try {
      return await RealtimeDbWindowsFix.safeOperation<DateTime?>(() async {
        final ref = _database.ref('$_onlinePath/$userId/lastActive');
        final snapshot = await ref.get();
        
        if (snapshot.exists && snapshot.value is int) {
          return DateTime.fromMillisecondsSinceEpoch(snapshot.value as int);
        }
        
        return null;
      }, defaultValue: null);
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
    if (!_isInitialized) {
      debugPrint('RealtimeMessagingService not initialized');
      return;
    }
    
    // Skip actual database operations on Windows
    if (_isWindowsPlatform) {
      debugPrint('🪟 Skipping updateMessageDeliveryStatus on Windows');
      return;
    }
    
    try {
      return await RealtimeDbWindowsFix.safeOperation<void>(() async {
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
    // Return empty delivery status on Windows
    if (_isWindowsPlatform) {
      debugPrint('🪟 Returning empty delivery status stream on Windows');
      return Stream.value({});
    }
    
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
    // Close all stream controllers
    for (final controller in _controllers.values) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
    _controllers.clear();
  }

  /// Initialize the Realtime Messaging Service
  Future<void> initialize() async {
    // If already initialized or on Windows, don't try again
    if (_isInitialized) {
      debugPrint('✅ Realtime Messaging Service already initialized');
      return;
    }
    
    try {
      // Handle initialization differently based on platform
      if (_isWindowsPlatform) {
        // No need to initialize Firebase Realtime Database on Windows
        // Instead, we'll use in-memory or fake implementations
        debugPrint('🪟 Initializing Realtime Messaging Service with Windows compatibility mode');
        await RealtimeDbWindowsFix.initialize(persistData: true);
        _isInitialized = true;
        debugPrint('✅ Windows-compatible Realtime Messaging Service initialized');
      } else {
        // Standard initialization for supported platforms
        debugPrint('🚀 Initializing Realtime Messaging Service');
        _isInitialized = true;
        debugPrint('✅ Realtime Messaging Service initialized');
      }
    } catch (e) {
      debugPrint('❌ Error initializing Realtime Messaging Service: $e');
    }
  }

  // TODO: Implement these methods when ready
  // Future<void> _listenForUserMessages(String userId) async {
  //   // Implementation pending
  // }
}

/// Enum representing the delivery status of a message
enum MessageDeliveryStatus {
  /// Message has been sent but not yet delivered
  sent,
  
  /// Message has been delivered to the recipient's device
  delivered,
  
  /// Message has been seen by the recipient
  seen,
} 