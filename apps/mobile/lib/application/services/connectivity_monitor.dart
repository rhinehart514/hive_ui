import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// The current status of the device's network connection.
enum ConnectionStatus {
  /// Device is connected to the internet.
  online,

  /// Device is not connected to the internet.
  offline,
}

/// Monitors and reports changes in network connectivity.
abstract class ConnectivityMonitor {
  /// Initializes the connectivity monitoring.
  Future<void> init();

  /// Stream of connection status changes.
  Stream<ConnectionStatus> get connectionStatusChanges;

  /// The current connection status.
  ConnectionStatus get currentStatus;

  /// Checks if the device is currently online.
  bool get isOnline;
}

/// Implementation of [ConnectivityMonitor] using the connectivity_plus package.
class ConnectivityPlusMonitor implements ConnectivityMonitor {
  final Connectivity _connectivity;
  
  /// Stream controller for connectivity status changes.
  final StreamController<ConnectionStatus> _controller = 
      StreamController<ConnectionStatus>.broadcast();
      
  /// The current connection status.
  ConnectionStatus _status = ConnectionStatus.online;
  
  /// Subscription to connectivity events.
  StreamSubscription? _subscription;
  
  /// Creates a new instance with the given connectivity service.
  ConnectivityPlusMonitor(this._connectivity);
  
  @override
  Future<void> init() async {
    try {
      // Check current connectivity
      List<ConnectivityResult> results = await _connectivity.checkConnectivity();
      _handleConnectivityChange(results);
      
      // Listen for future changes
      _subscription = _connectivity.onConnectivityChanged.listen(_handleConnectivityChange);
    } catch (e) {
      debugPrint('Error initializing connectivity: $e');
      // Default to online if unable to determine status
      _status = ConnectionStatus.online;
      _controller.add(_status);
    }
  }
  
  @override
  Stream<ConnectionStatus> get connectionStatusChanges => _controller.stream;
  
  @override
  ConnectionStatus get currentStatus => _status;
  
  @override
  bool get isOnline => _status == ConnectionStatus.online;
  
  /// Handles connectivity change events.
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final wasOnline = isOnline;
    
    // If any connection is available (not none), consider online
    final isNowOnline = results.isNotEmpty && 
        results.any((result) => result != ConnectivityResult.none);
    
    // Update status if changed
    if (wasOnline != isNowOnline) {
      _status = isNowOnline ? ConnectionStatus.online : ConnectionStatus.offline;
      _controller.add(_status);
    }
  }
  
  /// Disposes resources used by this monitor.
  Future<void> dispose() async {
    await _subscription?.cancel();
    await _controller.close();
  }
} 