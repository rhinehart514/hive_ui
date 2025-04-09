import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service that monitors the device's connectivity status
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  ConnectivityResult _lastResult = ConnectivityResult.none;
  final StreamController<ConnectivityResult> _controller = 
      StreamController<ConnectivityResult>.broadcast();
  
  /// Stream of connectivity status updates
  Stream<ConnectivityResult> get statusStream => _controller.stream;
  
  /// The current connectivity status
  ConnectivityResult get currentStatus => _lastResult;
  
  /// Whether the device currently has connectivity
  bool get hasConnectivity => 
      _lastResult == ConnectivityResult.wifi || 
      _lastResult == ConnectivityResult.mobile ||
      _lastResult == ConnectivityResult.ethernet;
      
  /// Constructor
  ConnectivityService() {
    _initConnectivity();
    _subscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }
  
  /// Initialize connectivity monitoring
  Future<void> _initConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      // Use the highest priority result (wifi > mobile > ethernet > none)
      final result = _getHighestPriorityResult(results);
      _lastResult = result;
      _controller.add(result);
      debugPrint('🔌 ConnectivityService: Initial connection status: $_lastResult');
    } catch (e) {
      debugPrint('🔌 ConnectivityService: Failed to get connectivity: $e');
    }
  }
  
  /// Update the connection status based on connectivity change events
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    // Get the highest priority connectivity result
    final result = _getHighestPriorityResult(results);
    
    if (_lastResult != result) {
      _lastResult = result;
      _controller.add(result);
      
      if (hasConnectivity) {
        debugPrint('🔌 ConnectivityService: Connection restored: $result');
      } else {
        debugPrint('🔌 ConnectivityService: Connection lost: $result');
      }
    }
  }
  
  /// Get the highest priority connectivity result from a list of results
  ConnectivityResult _getHighestPriorityResult(List<ConnectivityResult> results) {
    if (results.isEmpty) {
      return ConnectivityResult.none;
    }
    
    // Priority: wifi > mobile > ethernet > other > none
    if (results.contains(ConnectivityResult.wifi)) {
      return ConnectivityResult.wifi;
    } else if (results.contains(ConnectivityResult.mobile)) {
      return ConnectivityResult.mobile;
    } else if (results.contains(ConnectivityResult.ethernet)) {
      return ConnectivityResult.ethernet;
    } else if (results.contains(ConnectivityResult.none)) {
      return ConnectivityResult.none;
    } else {
      // If none of the expected results are present, return the first one
      return results.first;
    }
  }
  
  /// Check the current connectivity status
  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final result = _getHighestPriorityResult(results);
      _updateConnectionStatus(results);
      return result == ConnectivityResult.wifi || 
             result == ConnectivityResult.mobile || 
             result == ConnectivityResult.ethernet;
    } catch (e) {
      debugPrint('🔌 ConnectivityService: Failed to check connectivity: $e');
      return false;
    }
  }
  
  /// Dispose the service
  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}

/// Provider for the connectivity service
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// Provider that exposes the current connectivity status
final connectivityStatusProvider = StreamProvider<ConnectivityResult>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.statusStream;
});

/// Provider that exposes whether the device has connectivity
final hasConnectivityProvider = Provider<bool>((ref) {
  final status = ref.watch(connectivityStatusProvider);
  return status.when(
    data: (result) => result == ConnectivityResult.wifi || 
                      result == ConnectivityResult.mobile || 
                      result == ConnectivityResult.ethernet,
    loading: () => false,
    error: (_, __) => false,
  );
}); 