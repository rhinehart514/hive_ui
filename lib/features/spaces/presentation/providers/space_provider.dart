import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/spaces/domain/entities/space.dart';
import 'package:hive_ui/features/spaces/domain/repositories/spaces_repository.dart';
import 'package:hive_ui/features/spaces/domain/usecases/create_space_usecase.dart';
import 'package:hive_ui/features/spaces/presentation/providers/spaces_providers.dart' as main_providers;

/// Provider for the current space creation state
final spaceCreationStateProvider = StateNotifierProvider<SpaceCreationNotifier, SpaceCreationState>((ref) {
  final spaceRepository = ref.watch(main_providers.spacesRepositoryProvider);
  final createSpaceUseCase = CreateSpaceUseCase(spaceRepository);
  return SpaceCreationNotifier(createSpaceUseCase);
});

/// Provider for space name validation
final spaceNameValidationProvider = StateProvider<SpaceNameValidation>((ref) => SpaceNameValidation.initial);

/// The possible validation states for a space name
enum SpaceNameValidation {
  initial,
  checking,
  valid,
  invalid,
  alreadyExists,
}

/// The state of space creation
class SpaceCreationState {
  final String name;
  final String description;
  final SpacePrivacy privacy;
  final SpaceType type;
  final File? coverImage;
  final bool isCreating;
  final String? errorMessage;
  
  SpaceCreationState({
    this.name = '',
    this.description = '',
    this.privacy = SpacePrivacy.public,
    this.type = SpaceType.community,
    this.coverImage,
    this.isCreating = false,
    this.errorMessage,
  });
  
  /// Create a copy of this state but with the given fields replaced with the new values
  SpaceCreationState copyWith({
    String? name,
    String? description,
    SpacePrivacy? privacy,
    SpaceType? type,
    File? coverImage,
    bool? isCreating,
    String? errorMessage,
  }) {
    return SpaceCreationState(
      name: name ?? this.name,
      description: description ?? this.description,
      privacy: privacy ?? this.privacy,
      type: type ?? this.type,
      coverImage: coverImage ?? this.coverImage,
      isCreating: isCreating ?? this.isCreating,
      errorMessage: errorMessage,
    );
  }
}

/// Notifier to manage space creation state
class SpaceCreationNotifier extends StateNotifier<SpaceCreationState> {
  final CreateSpaceUseCase _createSpaceUseCase;
  
  SpaceCreationNotifier(this._createSpaceUseCase) : super(SpaceCreationState());
  
  /// Update the space name
  void updateName(String name) {
    state = state.copyWith(name: name);
  }
  
  /// Update the space description
  void updateDescription(String description) {
    state = state.copyWith(description: description);
  }
  
  /// Update the space privacy
  void updatePrivacy(SpacePrivacy privacy) {
    state = state.copyWith(privacy: privacy);
  }
  
  /// Update the space type
  void updateType(SpaceType type) {
    state = state.copyWith(type: type);
  }
  
  /// Update the space cover image
  void updateCoverImage(File? coverImage) {
    state = state.copyWith(coverImage: coverImage);
  }
  
  /// Create a new space with the current state
  Future<bool> createSpace() async {
    state = state.copyWith(isCreating: true, errorMessage: null);
    
    try {
      final space = Space(
        id: '', // ID will be assigned by the backend
        name: state.name,
        description: state.description,
        ownerId: '', // Current user ID will be assigned
        moderatorIds: const [], // Initially empty - will be set by repository
        memberIds: const [], // Initially empty - will be set by repository
        createdAt: DateTime.now(),
      );
      
      final result = await _createSpaceUseCase.execute(
        space: space,
        coverImage: state.coverImage,
        privacy: state.privacy,
        spaceType: state.type,
      );
      
      state = state.copyWith(isCreating: false);
      return result;
    } catch (e) {
      state = state.copyWith(
        isCreating: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
  
  /// Reset the state to initial values
  void resetState() {
    state = SpaceCreationState();
  }
}

// TODO: Implement SpacesNotifier and SpacesState classes before uncommenting
// /// Provider for spaces state management
// final spacesStateProvider = StateNotifierProvider.autoDispose.family<SpacesNotifier, SpacesState, String>(
//   (ref, spaceId) => SpacesNotifier(ref.watch(spaceRepositoryProvider), spaceId),
// ); 