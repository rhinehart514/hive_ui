import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/features/feed/data/repositories/signal_repository_impl.dart';
import 'package:hive_ui/features/feed/domain/entities/signal_content.dart';
import 'package:hive_ui/features/feed/domain/repositories/signal_repository.dart';
import 'package:hive_ui/core/services/firebase/firebase_services.dart';
import 'package:hive_ui/firebase_init_tracker.dart';

/// Provider for the Signal repository
final signalRepositoryProvider = Provider<SignalRepository>((ref) {
  // Check if Firebase is initialized
  if (!FirebaseInitTracker.isInitialized) {
    debugPrint('Creating SignalRepository: Firebase not initialized. Ensuring initialization...');
    // Try to initialize Firebase if not already initialized
    verifyFirebaseInitialization().then((initialized) {
      debugPrint('Firebase initialization check completed: $initialized');
    });
  }
  
  return SignalRepositoryImpl();
});

/// Provider for getting Signal Strip content
/// 
/// Parameters:
/// - maxItems: Maximum number of items to return
/// - types: Optional list of signal types to filter by
final signalContentProvider = FutureProvider.family<List<SignalContent>, SignalContentParams>(
  (ref, params) async {
    final repository = ref.watch(signalRepositoryProvider);
    return repository.getSignalContent(
      maxItems: params.maxItems,
      types: params.types,
    );
  },
);

/// Provider for managing Signal Strip state
final signalStripProvider = StateNotifierProvider<SignalStripNotifier, SignalStripState>((ref) {
  final repository = ref.watch(signalRepositoryProvider);
  return SignalStripNotifier(repository);
});

/// Parameters for the signal content provider
class SignalContentParams {
  final int maxItems;
  final List<SignalType>? types;

  const SignalContentParams({
    this.maxItems = 5,
    this.types,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is SignalContentParams &&
           other.maxItems == maxItems &&
           _listEquals(other.types, types);
  }

  @override
  int get hashCode => maxItems.hashCode ^ (types?.hashCode ?? 0);
  
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// State for Signal Strip
class SignalStripState {
  final bool isLoading;
  final String? error;
  final List<String> viewedContentIds;
  final List<String> tappedContentIds;
  final bool isExpanded;

  const SignalStripState({
    this.isLoading = false,
    this.error,
    this.viewedContentIds = const [],
    this.tappedContentIds = const [],
    this.isExpanded = false,
  });

  SignalStripState copyWith({
    bool? isLoading,
    String? error,
    List<String>? viewedContentIds,
    List<String>? tappedContentIds,
    bool? isExpanded,
  }) {
    return SignalStripState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      viewedContentIds: viewedContentIds ?? this.viewedContentIds,
      tappedContentIds: tappedContentIds ?? this.tappedContentIds,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }
}

/// Notifier for Signal Strip state
class SignalStripNotifier extends StateNotifier<SignalStripState> {
  final SignalRepository _repository;

  SignalStripNotifier(this._repository) : super(const SignalStripState());

  /// Log that a user viewed a signal content
  Future<bool> logContentView(String contentId) async {
    // Prevent duplicate logs
    if (state.viewedContentIds.contains(contentId)) {
      // Already viewed, no need to log again
      return true;
    }
    
    // Set loading state first
    state = state.copyWith(isLoading: true);
    
    try {
      // Ensure Firebase is initialized
      if (!FirebaseInitTracker.isInitialized) {
        final initialized = await verifyFirebaseInitialization();
        if (!initialized) {
          debugPrint('Firebase failed to initialize in logContentView');
          // Update state but don't fail completely
          final newViewedIds = List<String>.from(state.viewedContentIds)..add(contentId);
          state = state.copyWith(
            isLoading: false,
            viewedContentIds: newViewedIds,
            error: 'Firebase not available',
          );
          return false;
        }
      }
    
      // Try to log the view
      final success = await _repository.logSignalContentView(contentId);
      
      if (success) {
        final newViewedIds = List<String>.from(state.viewedContentIds)..add(contentId);
        state = state.copyWith(
          isLoading: false,
          viewedContentIds: newViewedIds,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to log content view',
        );
      }
      
      return success;
    } catch (e) {
      debugPrint('Error in logContentView: $e');
      // Update the state with the error
      state = state.copyWith(
        isLoading: false,
        error: 'Error logging content view: $e',
      );
      return false;
    }
  }

  /// Log that a user tapped on a signal content
  Future<bool> logContentTap(String contentId) async {
    state = state.copyWith(isLoading: true);
    
    try {
      // Ensure Firebase is initialized
      if (!FirebaseInitTracker.isInitialized) {
        final initialized = await verifyFirebaseInitialization();
        if (!initialized) {
          debugPrint('Firebase failed to initialize in logContentTap');
          // Update state but don't fail completely
          final newTappedIds = List<String>.from(state.tappedContentIds);
          if (!newTappedIds.contains(contentId)) {
            newTappedIds.add(contentId);
          }
          state = state.copyWith(
            isLoading: false,
            tappedContentIds: newTappedIds,
            error: 'Firebase not available',
          );
          return false;
        }
      }
      
      final success = await _repository.logSignalContentTap(contentId);
      
      if (success) {
        final newTappedIds = List<String>.from(state.tappedContentIds);
        
        if (!newTappedIds.contains(contentId)) {
          newTappedIds.add(contentId);
        }
        
        state = state.copyWith(
          isLoading: false,
          tappedContentIds: newTappedIds,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to log content tap',
        );
      }
      
      return success;
    } catch (e) {
      debugPrint('Error in logContentTap: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Error logging content tap: $e',
      );
      return false;
    }
  }

  /// Toggle the expanded state of the Signal Strip
  void toggleExpanded() {
    state = state.copyWith(isExpanded: !state.isExpanded);
  }

  /// Set the expanded state of the Signal Strip
  void setExpanded(bool expanded) {
    state = state.copyWith(isExpanded: expanded);
  }
} 