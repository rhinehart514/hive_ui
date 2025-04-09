import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/labs/data/repositories/hive_lab_repository_impl.dart';
import 'package:hive_ui/features/labs/domain/hive_lab_action.dart';
import 'package:hive_ui/features/labs/domain/hive_lab_repository.dart';

/// Provider for the HiveLab repository
final hiveLabRepositoryProvider = Provider<HiveLabRepository>((ref) {
  return HiveLabRepositoryImpl();
});

/// Provider for the HiveLab controller
final hiveLabProvider = StateNotifierProvider<HiveLabNotifier, HiveLabState>((ref) {
  final repository = ref.watch(hiveLabRepositoryProvider);
  return HiveLabNotifier(repository);
});

/// Provider for HiveLab actions
/// 
/// Parameters:
/// - maxCount: Maximum number of actions to return
/// - includeExperimental: Whether to include experimental actions
/// - includePremium: Whether to include premium actions
final hiveLabActionsProvider = FutureProvider.family<List<HiveLabAction>, HiveLabActionsParams>(
  (ref, params) async {
    final repository = ref.watch(hiveLabRepositoryProvider);
    return repository.getAvailableActions(
      maxCount: params.maxCount,
      includeExperimental: params.includeExperimental, 
      includePremium: params.includePremium,
    );
  },
);

/// Parameters for the HiveLab actions provider
class HiveLabActionsParams {
  final int maxCount;
  final bool includeExperimental;
  final bool includePremium;

  const HiveLabActionsParams({
    this.maxCount = 5,
    this.includeExperimental = false,
    this.includePremium = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HiveLabActionsParams &&
           other.maxCount == maxCount &&
           other.includeExperimental == includeExperimental &&
           other.includePremium == includePremium;
  }

  @override
  int get hashCode => 
    maxCount.hashCode ^ 
    includeExperimental.hashCode ^ 
    includePremium.hashCode;
}

/// The state class for the HiveLab
class HiveLabState {
  final bool isLoading;
  final String? error;
  final List<String> recentActionIds;

  const HiveLabState({
    this.isLoading = false,
    this.error,
    this.recentActionIds = const [],
  });

  HiveLabState copyWith({
    bool? isLoading,
    String? error,
    List<String>? recentActionIds,
  }) {
    return HiveLabState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      recentActionIds: recentActionIds ?? this.recentActionIds,
    );
  }
}

/// The notifier for HiveLab state
class HiveLabNotifier extends StateNotifier<HiveLabState> {
  final HiveLabRepository _repository;

  HiveLabNotifier(this._repository) : super(const HiveLabState());

  /// Track a user clicking on a HiveLab action
  Future<bool> trackActionClick(String actionId) async {
    state = state.copyWith(isLoading: true);
    
    try {
      final success = await _repository.trackActionClick(actionId);
      
      if (success) {
        // Add to recent action ids
        final newRecentIds = List<String>.from(state.recentActionIds);
        
        // Add to the beginning
        if (!newRecentIds.contains(actionId)) {
          newRecentIds.insert(0, actionId);
          
          // Keep only the 10 most recent
          if (newRecentIds.length > 10) {
            newRecentIds.removeLast();
          }
        } else {
          // Move to beginning if already exists
          newRecentIds.remove(actionId);
          newRecentIds.insert(0, actionId);
        }
        
        state = state.copyWith(
          isLoading: false, 
          recentActionIds: newRecentIds,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to track action click',
        );
      }
      
      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error tracking action: $e',
      );
      return false;
    }
  }

  /// Submit a HiveLab idea
  Future<bool> submitIdea({
    required String title,
    required String description,
    String? category,
  }) async {
    state = state.copyWith(isLoading: true);
    
    try {
      final success = await _repository.submitIdea(
        title: title,
        description: description,
        category: category,
      );
      
      state = state.copyWith(
        isLoading: false,
        error: success ? null : 'Failed to submit idea',
      );
      
      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error submitting idea: $e',
      );
      return false;
    }
  }

  /// Submit feedback through HiveLab
  Future<bool> submitFeedback({
    required String feedbackText,
    String? category,
    int? rating,
  }) async {
    state = state.copyWith(isLoading: true);
    
    try {
      final success = await _repository.submitFeedback(
        feedbackText: feedbackText,
        category: category,
        rating: rating,
      );
      
      state = state.copyWith(
        isLoading: false,
        error: success ? null : 'Failed to submit feedback',
      );
      
      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error submitting feedback: $e',
      );
      return false;
    }
  }
} 