import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/models/event.dart';

/// Model to represent a boosted item
class BoostedItem {
  /// The event being boosted
  final Event event;
  
  /// When the boost was created
  final DateTime createdAt;
  
  /// Duration of the boost in hours
  final int durationHours;
  
  /// When the boost expires
  final DateTime expiresAt;
  
  /// Constructor
  BoostedItem({
    required this.event,
    required this.durationHours,
    DateTime? createdAt,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    expiresAt = (createdAt ?? DateTime.now()).add(Duration(hours: durationHours));
  
  /// Check if the boost is active
  bool get isActive => DateTime.now().isBefore(expiresAt);
  
  /// Calculate remaining time in hours (rounded down)
  int get remainingHours {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) return 0;
    
    final diff = expiresAt.difference(now);
    return diff.inHours;
  }
}

/// State for tracking boosted items
class BoostState {
  /// Currently active boost
  final BoostedItem? activeBoost;
  
  /// History of past boosts
  final List<BoostedItem> boostHistory;
  
  /// Error message if any
  final String? errorMessage;
  
  /// Loading state
  final bool isLoading;
  
  /// Constructor
  const BoostState({
    this.activeBoost,
    this.boostHistory = const [],
    this.errorMessage,
    this.isLoading = false,
  });
  
  /// Create a copy with some fields replaced
  BoostState copyWith({
    BoostedItem? activeBoost,
    List<BoostedItem>? boostHistory,
    String? errorMessage,
    bool? isLoading,
  }) {
    return BoostState(
      activeBoost: activeBoost ?? this.activeBoost,
      boostHistory: boostHistory ?? this.boostHistory,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
  
  /// Check if the user can create a new boost
  bool get canBoost => activeBoost == null || !activeBoost!.isActive;
}

/// Notifier for boost state
class BoostNotifier extends StateNotifier<BoostState> {
  /// Constructor
  BoostNotifier() : super(const BoostState());
  
  /// Boost an event
  Future<void> boostEvent(Event event, int durationHours) async {
    try {
      state = state.copyWith(isLoading: true);
      
      // Check if user can boost
      if (!state.canBoost) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'You already have an active boost',
        );
        return;
      }
      
      // Create a new boost
      final newBoost = BoostedItem(
        event: event,
        durationHours: durationHours,
      );
      
      // Update boost history
      final updatedHistory = [
        ...state.boostHistory,
        if (state.activeBoost != null && !state.activeBoost!.isActive) 
          state.activeBoost!,
      ];
      
      // Update state
      state = state.copyWith(
        activeBoost: newBoost,
        boostHistory: updatedHistory,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to boost event: $e',
      );
    }
  }
  
  /// Cancel the current boost
  void cancelBoost() {
    if (state.activeBoost == null) return;
    
    final updatedHistory = [...state.boostHistory, state.activeBoost!];
    
    state = state.copyWith(
      activeBoost: null,
      boostHistory: updatedHistory,
    );
  }
}

/// Provider for boost state
final boostProvider = StateNotifierProvider<BoostNotifier, BoostState>((ref) {
  return BoostNotifier();
});

/// Provider to check if an event is boosted
final isEventBoostedProvider = Provider.family<bool, String>((ref, eventId) {
  final boostState = ref.watch(boostProvider);
  if (boostState.activeBoost == null || !boostState.activeBoost!.isActive) {
    return false;
  }
  
  return boostState.activeBoost!.event.id == eventId;
});

/// Provider to check if the user can boost
final canBoostProvider = Provider<bool>((ref) {
  return ref.watch(boostProvider).canBoost;
});

/// Provider to get the active boost
final activeBoostedEventProvider = Provider<Event?>((ref) {
  final boostState = ref.watch(boostProvider);
  if (boostState.activeBoost == null || !boostState.activeBoost!.isActive) {
    return null;
  }
  
  return boostState.activeBoost!.event;
}); 