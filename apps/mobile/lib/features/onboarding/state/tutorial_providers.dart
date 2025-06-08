import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for tracking the current page in the tutorial.
final tutorialCurrentPageProvider = StateProvider<int>((ref) => 0);

/// Provider to determine if an active ritual is available.
/// This is used to conditionally display content in the tutorial.
final hasActiveRitualProvider = Provider<bool>((ref) {
  // TODO: This should be replaced with actual ritual status check
  // For now, returning a static value for demonstration
  return true;
});

/// Provider to calculate the completion percentage of the tutorial.
final tutorialCompletionPercentageProvider = Provider<double>((ref) {
  final currentIndex = ref.watch(tutorialCurrentPageProvider);
  const totalPages = 4;
  return (currentIndex + 1) / totalPages;
});

const _tutorialCompletedKey = 'has_completed_tutorial';

/// Manages the state of whether the user has completed the onboarding tutorial.
///
/// Reads and writes the completion status to SharedPreferences.
final tutorialCompletionProvider =
    StateNotifierProvider<TutorialCompletionNotifier, bool>((ref) {
  // Reading SharedPreferences initially is asynchronous, which StateNotifierProvider
  // doesn't directly support in its create callback. We'll initialize assuming
  // the tutorial is not completed and update asynchronously.
  // A FutureProvider/AsyncNotifier could be used if needing to wait for the value,
  // but for this flag, assuming false initially is acceptable.
  final notifier = TutorialCompletionNotifier(false);
  notifier.loadInitialState();
  return notifier;
});

class TutorialCompletionNotifier extends StateNotifier<bool> {
  TutorialCompletionNotifier(super.initialState);

  SharedPreferences? _prefs;

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Loads the initial completion state from SharedPreferences.
  Future<void> loadInitialState() async {
    await _initPrefs();
    state = _prefs?.getBool(_tutorialCompletedKey) ?? false;
  }

  /// Marks the tutorial as completed and saves the state.
  Future<void> completeTutorial() async {
    await _initPrefs();
    await _prefs?.setBool(_tutorialCompletedKey, true);
    state = true;
  }

  /// Resets the tutorial completion status (for debugging/testing).
  Future<void> resetTutorial() async {
    await _initPrefs();
    await _prefs?.setBool(_tutorialCompletedKey, false);
    state = false;
  }
}

/// Provider for tracking the current page index in the tutorial PageView.
final tutorialPageIndexProvider =
    StateNotifierProvider<TutorialPageIndexNotifier, int>((ref) {
  return TutorialPageIndexNotifier();
});

class TutorialPageIndexNotifier extends StateNotifier<int> {
  TutorialPageIndexNotifier() : super(0); // Start at the first page (index 0)

  void setPage(int index) {
    state = index;
  }
}

/// Provider that calculates the tutorial progress (0.0 to 1.0).
final tutorialProgressProvider = Provider<double>((ref) {
  // Define the total number of pages (adjust if cards change)
  const totalPages = 3; // Feed, Events, Spaces
  final currentIndex = ref.watch(tutorialPageIndexProvider);

  // Ensure index is within bounds and calculate progress
  if (totalPages <= 0) return 0.0;
  // Progress should be based on completing the *current* page,
  // so index 0 means 1/3 complete, index 1 means 2/3, etc.
  return (currentIndex + 1).toDouble() / totalPages.toDouble();
}); 