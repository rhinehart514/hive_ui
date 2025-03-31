import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/messaging/application/providers/messaging_providers.dart';

/// A utility class to manage the user's online status based on app lifecycle
class OnlineStatusManager with WidgetsBindingObserver {
  final Ref _ref;
  bool _hasInitialized = false;

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