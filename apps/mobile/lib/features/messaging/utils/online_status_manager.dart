import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/messaging/controllers/messaging_controller.dart';
import 'package:hive_ui/features/messaging/application/providers/messaging_providers.dart';
import 'package:logging/logging.dart';

/// A utility class to manage the user's online status based on app lifecycle
class OnlineStatusManager with WidgetsBindingObserver {
  final Ref _ref;
  bool _hasInitialized = false;
  Timer? _heartbeatTimer;
  bool _isOnline = false;
  final _logger = Logger('OnlineStatusManager');
  
  /// Heartbeat interval for updating online status
  static const Duration heartbeatInterval = Duration(minutes: 1);

  OnlineStatusManager(this._ref) {
    WidgetsBinding.instance.addObserver(this);
    _initializeOnlineStatus();
  }

  void _initializeOnlineStatus() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null && !_hasInitialized) {
      // Set user as online
      _ref.read(updateOnlineStatusProvider)(true);
      _hasInitialized = true;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        // App is in the foreground
        _ref.read(updateOnlineStatusProvider)(true);
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // App is in the background or closed
        _ref.read(updateOnlineStatusProvider)(false);
        break;
      default:
        break;
    }
  }

  void dispose() {
    // Set user as offline before disposing
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      _ref.read(updateOnlineStatusProvider)(false);
    }
    WidgetsBinding.instance.removeObserver(this);
  }

  /// Initialize online status tracking
  void initialize() {
    // Set initial online status
    _setOnlineStatus(true);
    
    // Start heartbeat timer
    _startHeartbeat();
  }

  /// Update the online status of the current user
  Future<void> _setOnlineStatus(bool isOnline) async {
    if (_isOnline == isOnline) return;
    
    _isOnline = isOnline;
    
    try {
      final messagingController = _ref.read(messagingControllerProvider);
      await messagingController.updateOnlineStatus(isOnline);
    } catch (e) {
      _logger.warning('Error updating online status: $e');
    }
  }

  /// Start the heartbeat timer to keep online status updated
  void _startHeartbeat() {
    // Cancel any existing timer
    _heartbeatTimer?.cancel();
    
    // Create new periodic timer
    _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) {
      if (_isOnline) {
        // Update timestamp to show user is still active
        _setOnlineStatus(true);
      }
    });
  }

  /// Handle app entering background - set as offline
  void onBackground() {
    _setOnlineStatus(false);
  }

  /// Handle app entering foreground - set as online
  void onForeground() {
    _setOnlineStatus(true);
  }
}

/// Provider for the OnlineStatusManager
final onlineStatusManagerProvider = Provider<OnlineStatusManager>((ref) {
  final manager = OnlineStatusManager(ref);
  
  ref.onDispose(() {
    manager.dispose();
  });
  
  return manager;
});

/// Provider to ensure the OnlineStatusManager is initialized
final initializeOnlineStatusProvider = Provider<void>((ref) {
  // Just watching this provider will initialize the manager
  ref.watch(onlineStatusManagerProvider);
}); 