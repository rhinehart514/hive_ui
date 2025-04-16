import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/domain/repositories/spaces_repository.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart';

/// Provider for managing the joining/leaving state of a space
final spaceJoinProvider = StateNotifierProvider.family<SpaceJoinNotifier, SpaceJoinState, String>(
  (ref, spaceId) => SpaceJoinNotifier(
    spaceId: spaceId,
    repository: ref.watch(spacesRepositoryProvider),
    ref: ref,
  ),
);

/// Repository provider for space operations
final spacesRepositoryProvider = Provider<SpacesRepository>(
  (ref) => throw UnimplementedError('spacesRepositoryProvider not implemented'),
);

/// State for managing join operations
class SpaceJoinState {
  final bool isJoined;
  final bool isLoading;
  final String? errorMessage;

  const SpaceJoinState({
    this.isJoined = false,
    this.isLoading = false,
    this.errorMessage,
  });

  SpaceJoinState copyWith({
    bool? isJoined,
    bool? isLoading,
    String? errorMessage,
  }) {
    return SpaceJoinState(
      isJoined: isJoined ?? this.isJoined,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Notifier for managing the join state of a space
class SpaceJoinNotifier extends StateNotifier<SpaceJoinState> {
  /// The space ID
  final String spaceId;
  
  /// The space repository
  final SpacesRepository repository;
  
  /// The ref object to access providers
  final Ref ref;
  
  /// Constructor
  SpaceJoinNotifier({
    required this.spaceId,
    required this.repository,
    required this.ref,
  }) : super(const SpaceJoinState()) {
    // Initialize the state by checking if the user has joined the space
    _checkJoinStatus();
  }

  /// Check if the user has joined the space
  Future<void> _checkJoinStatus() async {
    try {
      final isJoined = await repository.hasJoinedSpace(spaceId);
      state = state.copyWith(isJoined: isJoined);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to check join status: $e');
    }
  }
  
  /// Toggle joining/leaving a space
  Future<bool> toggleJoin() async {
    // Get current user
    final currentUser = ref.read(currentUserProvider);
    
    if (currentUser == null || currentUser.id.isEmpty) {
      state = state.copyWith(
        errorMessage: 'You need to be signed in to join spaces'
      );
      return false;
    }
    
    // Set state to loading
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      bool success;
      
      if (state.isJoined) {
        // Leave the space
        success = await repository.leaveSpace(spaceId, userId: currentUser.id);
      } else {
        // Join the space
        success = await repository.joinSpace(spaceId, userId: currentUser.id);
      }
      
      if (success) {
        // Update state to reflect the action completed
        state = state.copyWith(
          isJoined: !state.isJoined,
          isLoading: false
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: state.isJoined 
              ? 'Failed to leave the space' 
              : 'Failed to join the space'
        );
        return false;
      }
    } catch (e) {
      // Set state back to not loading on error with error message
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error: ${e.toString()}'
      );
      return false;
    }
  }
}

/// Interface for space repository operations
abstract class SpacesRepository {
  /// Check if the user has joined a space
  Future<bool> hasJoinedSpace(String spaceId);
  
  /// Join a space
  Future<bool> joinSpace(String spaceId, {required String userId});
  
  /// Leave a space
  Future<bool> leaveSpace(String spaceId, {required String userId});
  
  /// Get all spaces
  Future<List<SpaceEntity>> getAllSpaces();
  
  /// Get spaces that the user has joined
  Future<List<SpaceEntity>> getJoinedSpaces();
} 