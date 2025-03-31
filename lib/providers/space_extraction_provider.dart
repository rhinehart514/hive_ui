import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/services/space_event_service.dart';

/// The state of the space extraction process
class SpaceExtractionState {
  final bool isExtracting;
  final int processedSpaces;
  final int totalEvents;
  final double progress;
  final String? error;
  final bool isComplete;

  const SpaceExtractionState({
    this.isExtracting = false,
    this.processedSpaces = 0,
    this.totalEvents = 0,
    this.progress = 0.0,
    this.error,
    this.isComplete = false,
  });

  SpaceExtractionState copyWith({
    bool? isExtracting,
    int? processedSpaces,
    int? totalEvents,
    double? progress,
    String? error,
    bool? isComplete,
  }) {
    return SpaceExtractionState(
      isExtracting: isExtracting ?? this.isExtracting,
      processedSpaces: processedSpaces ?? this.processedSpaces,
      totalEvents: totalEvents ?? this.totalEvents,
      progress: progress ?? this.progress,
      error: error ?? this.error,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

/// StateNotifier for managing space extraction
class SpaceExtractionNotifier extends StateNotifier<SpaceExtractionState> {
  SpaceExtractionNotifier() : super(const SpaceExtractionState());

  /// Start the space extraction process
  Future<void> startExtraction() async {
    if (state.isExtracting) return;

    state = state.copyWith(isExtracting: true, error: null, isComplete: false);

    try {
      // Process all events and extract spaces
      debugPrint('Starting space extraction from events...');
      final processedSpaces =
          await SpaceEventService.processAllExistingEvents();

      // Update state with completion info
      state = state.copyWith(
        isExtracting: false,
        processedSpaces: processedSpaces,
        progress: 1.0,
        isComplete: true,
      );

      debugPrint(
          'Space extraction completed: $processedSpaces spaces extracted');
    } catch (e) {
      debugPrint('Error during space extraction: $e');
      state = state.copyWith(
        isExtracting: false,
        error: e.toString(),
        isComplete: true,
      );
    }
  }

  /// Reset the extraction state
  void reset() {
    state = const SpaceExtractionState();
  }
}

/// Provider for space extraction
final spaceExtractionProvider =
    StateNotifierProvider<SpaceExtractionNotifier, SpaceExtractionState>((ref) {
  return SpaceExtractionNotifier();
});

/// Provider to trigger space extraction from events (one-time operation)
final extractSpacesFromEventsProvider = FutureProvider<int>((ref) async {
  final notifier = ref.read(spaceExtractionProvider.notifier);
  await notifier.startExtraction();
  return ref.read(spaceExtractionProvider).processedSpaces;
});
