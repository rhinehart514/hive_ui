import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/services/optimized_data_service.dart';
import 'dart:async';

/// A notifier for managing offline mode state
class OfflineModeNotifier extends StateNotifier<bool> {
  Timer? _syncTimer;
  
  OfflineModeNotifier() : super(OptimizedDataService.isOfflineMode) {
    // Start a periodic check for offline status changes
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      // Check if our state matches the service state
      if (state != OptimizedDataService.isOfflineMode) {
        state = OptimizedDataService.isOfflineMode;
      }
    });
  }
  
  /// Enable or disable offline mode manually
  Future<void> setOfflineMode(bool enabled) async {
    if (state == enabled) return;
    
    await OptimizedDataService.setOfflineMode(enabled);
    state = enabled;
  }
  
  /// Prefetch data for offline use
  Future<void> prefetchData() async {
    await OptimizedDataService.prefetchForOffline();
  }
  
  /// Check if we have sufficient data for offline use
  bool hasSufficientOfflineData() {
    return OptimizedDataService.hasSufficientOfflineData();
  }
  
  /// Clean up resources
  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}

/// Provider for offline mode status
final offlineModeProvider = StateNotifierProvider<OfflineModeNotifier, bool>((ref) {
  return OfflineModeNotifier();
});

/// Provider that exposes whether we have sufficient offline data
final hasSufficientOfflineDataProvider = Provider<bool>((ref) {
  final offlineNotifier = ref.watch(offlineModeProvider.notifier);
  return offlineNotifier.hasSufficientOfflineData();
});

/// Provider for the last online timestamp
final lastOnlineTimeProvider = Provider<DateTime?>((ref) {
  // Watch the offline mode to trigger refreshes when it changes
  ref.watch(offlineModeProvider);
  return OptimizedDataService.lastOnlineTime;
});

/// Provider for the count of pending offline changes
final pendingChangesCountProvider = Provider<int>((ref) {
  // Watch the offline mode to trigger refreshes when it changes
  ref.watch(offlineModeProvider);
  return OptimizedDataService.getPendingChangesCount();
});

/// Get all entity IDs with offline changes
List<String> getAllIdsWithOfflineChanges(String entityType) {
  return OptimizedDataService.getIdsWithPendingChanges(entityType);
} 