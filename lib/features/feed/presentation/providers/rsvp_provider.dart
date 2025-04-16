import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/feed/domain/usecases/rsvp_use_case.dart';
import 'package:hive_ui/models/event.dart';

/// Represents RSVP loading status for UI feedback
enum RsvpLoadingStatus {
  /// Not loading, settled state
  idle,
  
  /// In the process of RSVPing to an event
  rsvping,
  
  /// In the process of cancelling RSVP
  cancelling
}

/// Provider for RSVP state
final rsvpStateProvider = StateNotifierProvider<RsvpStateNotifier, Map<String, bool>>((ref) {
  final rsvpUseCase = ref.watch(rsvpUseCaseProvider);
  return RsvpStateNotifier(ref, rsvpUseCase);
});

/// Provider for tracking loading state of RSVP actions
final rsvpLoadingProvider = StateNotifierProvider<RsvpLoadingNotifier, Map<String, RsvpLoadingStatus>>((ref) {
  return RsvpLoadingNotifier();
});

/// Notifier for managing RSVP state
class RsvpStateNotifier extends StateNotifier<Map<String, bool>> {
  final Ref _ref;
  final RsvpUseCase _rsvpUseCase;
  
  RsvpStateNotifier(this._ref, this._rsvpUseCase) : super({});
  
  /// Toggle RSVP status for an event
  Future<bool> toggleRsvp(Event event) async {
    final eventId = event.id;
    
    // Get current RSVP status
    final isCurrentlyRsvped = state[eventId] ?? false;
    final newRsvpStatus = !isCurrentlyRsvped;
    
    // Update loading state
    _ref.read(rsvpLoadingProvider.notifier).setLoading(
      eventId, 
      newRsvpStatus ? RsvpLoadingStatus.rsvping : RsvpLoadingStatus.cancelling
    );
    
    // Optimistically update state
    state = {...state, eventId: newRsvpStatus};
    
    try {
      // Call use case to handle RSVP
      final success = await _rsvpUseCase.toggleRsvp(eventId, newRsvpStatus);
      
      if (!success) {
        // Revert state if failed
        state = {...state, eventId: isCurrentlyRsvped};
      }
      
      // Set loading to idle
      _ref.read(rsvpLoadingProvider.notifier).setLoading(eventId, RsvpLoadingStatus.idle);
      
      return success;
    } catch (e) {
      // Handle error and revert state
      debugPrint('Error in toggleRsvp: $e');
      state = {...state, eventId: isCurrentlyRsvped};
      _ref.read(rsvpLoadingProvider.notifier).setLoading(eventId, RsvpLoadingStatus.idle);
      return false;
    }
  }
  
  /// Load RSVP status for an event from backend
  Future<void> loadRsvpStatus(String eventId) async {
    if (state.containsKey(eventId)) return; // Skip if already loaded
    
    try {
      final isRsvped = await _rsvpUseCase.getRsvpStatus(eventId);
      state = {...state, eventId: isRsvped};
    } catch (e) {
      debugPrint('Error loading RSVP status: $e');
    }
  }
  
  /// Load RSVP statuses for multiple events
  Future<void> loadRsvpStatuses(List<Event> events) async {
    for (final event in events) {
      await loadRsvpStatus(event.id);
    }
  }
  
  /// Set RSVP status without backend call (for prefetched data)
  void setRsvpStatus(String eventId, bool isRsvped) {
    state = {...state, eventId: isRsvped};
  }
  
  /// Clear all RSVP states
  void clear() {
    state = {};
  }
}

/// Notifier for tracking loading state of RSVP actions
class RsvpLoadingNotifier extends StateNotifier<Map<String, RsvpLoadingStatus>> {
  RsvpLoadingNotifier() : super({});
  
  /// Set loading status for an event
  void setLoading(String eventId, RsvpLoadingStatus status) {
    state = {...state, eventId: status};
  }
  
  /// Check if an event is in loading state
  bool isLoading(String eventId) {
    return state[eventId] != null && state[eventId] != RsvpLoadingStatus.idle;
  }
  
  /// Clear loading state for an event
  void clearLoading(String eventId) {
    final newState = Map<String, RsvpLoadingStatus>.from(state);
    newState.remove(eventId);
    state = newState;
  }
} 