import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/auth/domain/repositories/auth_repository.dart';
import 'package:hive_ui/features/auth/presentation/providers/auth_provider.dart';
import 'package:hive_ui/features/spaces/domain/entities/space.dart' as domain_space;
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/domain/repositories/space_repository.dart';
import 'package:hive_ui/features/spaces/domain/repositories/spaces_repository.dart';
import 'package:hive_ui/features/spaces/domain/usecases/create_space_usecase.dart';
import 'package:hive_ui/features/spaces/presentation/providers/spaces_repository_provider.dart';
import 'package:hive_ui/utils/auth_utils.dart';

/// Adapter class to bridge between SpacesRepository and SpaceRepository interfaces
class SpaceRepositoryAdapter implements SpaceRepository {
  final SpacesRepository _spacesRepository;
  
  SpaceRepositoryAdapter(this._spacesRepository);
  
  @override
  Future<bool> createSpace(domain_space.Space space, {File? coverImage}) async {
    try {
      await _spacesRepository.createSpace(
        name: space.name,
        description: space.description,
        spaceType: _mapSpaceType(space.type),
        tags: space.tags,
        isPrivate: space.privacy == domain_space.SpacePrivacy.private,
        iconCodePoint: 0xe491, // Default icon
        creatorId: space.ownerId,
        isHiveExclusive: true,
      );
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Maps from Space.SpaceType to SpaceEntity.SpaceType
  SpaceType _mapSpaceType(domain_space.SpaceType type) {
    switch (type) {
      case domain_space.SpaceType.academic:
        return SpaceType.studentOrg;
      case domain_space.SpaceType.community:
        return SpaceType.other;
      case domain_space.SpaceType.club:
        return SpaceType.universityOrg;
      case domain_space.SpaceType.event:
        return SpaceType.other;
      default:
        return SpaceType.other;
    }
  }
  
  @override
  Future<domain_space.Space?> getSpaceById(String spaceId) async {
    // Implementation omitted for brevity
    throw UnimplementedError();
  }
  
  @override
  Future<List<domain_space.Space>> getUserSpaces() async {
    // Implementation omitted for brevity
    throw UnimplementedError();
  }
  
  @override
  Future<List<domain_space.Space>> getTrendingSpaces() async {
    // Implementation omitted for brevity
    throw UnimplementedError();
  }
  
  @override
  Future<List<domain_space.Space>> getRecommendedSpaces() async {
    // Implementation omitted for brevity
    throw UnimplementedError();
  }
  
  @override
  Future<bool> joinSpace(String spaceId) async {
    // Implementation omitted for brevity
    throw UnimplementedError();
  }
  
  @override
  Future<bool> leaveSpace(String spaceId) async {
    // Implementation omitted for brevity
    throw UnimplementedError();
  }
  
  @override
  Future<bool> updateSpace(domain_space.Space space, {File? coverImage}) async {
    // Implementation omitted for brevity
    throw UnimplementedError();
  }
  
  @override
  Future<bool> deleteSpace(String spaceId) async {
    // Implementation omitted for brevity
    throw UnimplementedError();
  }
  
  @override
  Future<bool> isSpaceNameAvailable(String name) async {
    final isTaken = await _spacesRepository.isSpaceNameTaken(name);
    return !isTaken;
  }
  
  @override
  Future<List<domain_space.Space>> searchSpaces(String query) async {
    // Implementation omitted for brevity
    throw UnimplementedError();
  }
  
  @override
  Future<List<SpaceEntity>> getSuggestedSpacesForUser({
    required String userId,
    int limit = 5,
  }) async {
    try {
      // Use the available getRecommendedSpaces method as a substitute
      final recommendedSpaces = await _spacesRepository.getRecommendedSpaces();
      
      // Limit the number of spaces returned
      final limitedSpaces = recommendedSpaces.take(limit).toList();
      
      return limitedSpaces;
    } catch (e) {
      // Return empty list on error
      return [];
    }
  }
}

/// Provider for the SpaceRepository adapter
final spaceRepositoryAdapterProvider = Provider<SpaceRepository>((ref) {
  final spacesRepository = ref.watch(spacesRepositoryProvider);
  return SpaceRepositoryAdapter(spacesRepository);
});

/// Provider for CreateSpaceUseCase
final createSpaceUseCaseProvider = Provider<CreateSpaceUseCase>((ref) {
  final spaceRepository = ref.watch(spaceRepositoryAdapterProvider);
  return CreateSpaceUseCase(spaceRepository);
});

/// State class for create space
class CreateSpaceState {
  final bool isLoading;
  final bool isCheckingName;
  final String? errorMessage;
  final SpaceEntity? createdSpace;
  final bool? isNameAvailable;

  const CreateSpaceState({
    this.isLoading = false,
    this.isCheckingName = false,
    this.errorMessage,
    this.createdSpace,
    this.isNameAvailable,
  });

  CreateSpaceState copyWith({
    bool? isLoading,
    bool? isCheckingName,
    String? errorMessage,
    SpaceEntity? createdSpace,
    bool? isNameAvailable,
  }) {
    return CreateSpaceState(
      isLoading: isLoading ?? this.isLoading,
      isCheckingName: isCheckingName ?? this.isCheckingName,
      errorMessage: errorMessage ?? this.errorMessage,
      createdSpace: createdSpace ?? this.createdSpace,
      isNameAvailable: isNameAvailable ?? this.isNameAvailable,
    );
  }

  /// Reset the state to initial
  CreateSpaceState reset() {
    return const CreateSpaceState();
  }
}

/// Notifier for create space operations
class CreateSpaceNotifier extends StateNotifier<CreateSpaceState> {
  final CreateSpaceUseCase _createSpaceUseCase;
  final SpacesRepository _spacesRepository;
  final AuthRepository _authRepository;

  CreateSpaceNotifier(
    this._createSpaceUseCase, 
    this._spacesRepository,
    this._authRepository
  ) : super(const CreateSpaceState());

  /// Check if a space name is available
  Future<void> checkSpaceNameAvailability(String name) async {
    if (name.trim().isEmpty) return;
    
    try {
      state = state.copyWith(isCheckingName: true, isNameAvailable: null);
      
      // Query if name exists through the repository
      final nameExists = await _spacesRepository.isSpaceNameTaken(name);
      
      state = state.copyWith(
        isCheckingName: false,
        isNameAvailable: !nameExists,
      );
    } catch (e) {
      state = state.copyWith(
        isCheckingName: false,
        isNameAvailable: null,
        errorMessage: 'Error checking name availability: ${e.toString()}',
      );
    }
  }

  /// Create a new space
  Future<void> createSpace({
    required String name,
    required String description,
    required SpaceType spaceType,
    required List<String> tags,
    required int iconCodePoint,
    bool isHiveExclusive = true,
  }) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      // First check if the name is available (double-check even if UI checked)
      await checkSpaceNameAvailability(name);
      
      // If name isn't available, stop the creation process
      if (state.isNameAvailable == false) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'A space with this name already exists. Please choose a different name.',
        );
        return;
      }

      // Get current user ID from auth
      final creatorId = _authRepository.getCurrentUser().id;

      // Create space through repository
      final createdSpace = await _spacesRepository.createSpace(
        name: name,
        description: description,
        spaceType: spaceType,
        tags: tags,
        isPrivate: true, // Enforced by business rule
        iconCodePoint: iconCodePoint,
        isHiveExclusive: isHiveExclusive,
        creatorId: creatorId,
      );
      
      state = state.copyWith(
        isLoading: false,
        createdSpace: createdSpace,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Reset state after navigation or when needed
  void reset() {
    state = state.reset();
  }
}

/// Provider for the create space state
final createSpaceProvider = StateNotifierProvider<CreateSpaceNotifier, CreateSpaceState>((ref) {
  final createSpaceUseCase = ref.watch(createSpaceUseCaseProvider);
  final spacesRepository = ref.watch(spacesRepositoryProvider);
  final authRepository = ref.watch(authRepositoryProvider);
  return CreateSpaceNotifier(createSpaceUseCase, spacesRepository, authRepository);
}); 