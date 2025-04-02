import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/auth/domain/repositories/auth_repository.dart';
import 'package:hive_ui/features/auth/presentation/providers/auth_provider.dart';
import 'package:hive_ui/features/spaces/domain/entities/space.dart' as domain_space;
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_metrics_entity.dart';
import 'package:hive_ui/features/spaces/domain/repositories/space_repository.dart';
import 'package:hive_ui/features/spaces/domain/repositories/spaces_repository.dart';
import 'package:hive_ui/features/spaces/domain/usecases/create_space_usecase.dart';
import 'package:hive_ui/features/spaces/presentation/providers/spaces_repository_provider.dart';
import 'package:hive_ui/models/event.dart';

/// Adapter class to bridge between SpacesRepository and SpaceRepository interfaces
class SpaceRepositoryAdapter implements SpaceRepository {
  final SpacesRepository _spacesRepository;
  
  SpaceRepositoryAdapter(this._spacesRepository);
  
  @override
  Future<bool> createSpace(SpaceEntity space, {File? coverImage}) async {
    try {
      await _spacesRepository.createSpace(
        name: space.name,
        description: space.description,
        spaceType: space.spaceType,
        tags: space.tags,
        isPrivate: space.isPrivate,
        iconCodePoint: space.iconCodePoint,
        creatorId: space.admins.isNotEmpty ? space.admins.first : '',
        isHiveExclusive: space.hiveExclusive,
      );
      return true;
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<SpaceEntity?> getSpaceById(String spaceId, {String? spaceType}) async {
    try {
      // Pass the spaceType to the underlying repository if it supports it
      return await _spacesRepository.getSpaceById(spaceId);
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<List<SpaceEntity>> getUserSpaces(String userId) async {
    try {
      // SpacesRepository doesn't have a method that takes userId, 
      // using getJoinedSpaces() as a fallback
      return await _spacesRepository.getJoinedSpaces();
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<List<SpaceEntity>> getInvitedSpaces(String userId) async {
    // Not directly supported by SpacesRepository, return empty list
    return [];
  }
  
  @override
  Future<List<SpaceEntity>> getTrendingSpaces() async {
    try {
      return await _spacesRepository.getTrendingSpaces();
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<List<SpaceEntity>> getRecommendedSpaces(String userId) async {
    try {
      // Ignoring userId parameter since the underlying repository 
      // doesn't support it
      return await _spacesRepository.getRecommendedSpaces();
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<bool> joinSpace(String spaceId, String userId) async {
    try {
      // SpacesRepository's joinSpace doesn't take userId
      await _spacesRepository.joinSpace(spaceId);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<bool> leaveSpace(String spaceId, String userId) async {
    try {
      // SpacesRepository's leaveSpace doesn't take userId
      await _spacesRepository.leaveSpace(spaceId);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<bool> updateSpace(SpaceEntity space, {File? coverImage}) async {
    // Not directly supported by SpacesRepository
    // In a real implementation, you would call a method to update the space
    return false;
  }
  
  @override
  Future<bool> deleteSpace(String spaceId) async {
    // Not directly supported by SpacesRepository
    // In a real implementation, you would call a method to delete the space
    return false;
  }
  
  @override
  Future<bool> isSpaceNameAvailable(String name) async {
    final isTaken = await _spacesRepository.isSpaceNameTaken(name);
    return !isTaken;
  }
  
  @override
  Future<List<SpaceEntity>> searchSpaces(String query) async {
    try {
      return await _spacesRepository.searchSpaces(query);
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<bool> inviteUsers(String spaceId, List<String> userIds) async {
    // Not directly supported by SpacesRepository
    return false;
  }
  
  @override
  Future<bool> removeInvites(String spaceId, List<String> userIds) async {
    // Not directly supported by SpacesRepository
    return false;
  }
  
  @override
  Future<bool> addAdmin(String spaceId, String userId) async {
    // Not directly supported by SpacesRepository
    return false;
  }
  
  @override
  Future<bool> removeAdmin(String spaceId, String userId) async {
    // Not directly supported by SpacesRepository
    return false;
  }
  
  @override
  Future<bool> createSpaceEvent(String spaceId, String eventId, String creatorId) async {
    // Not directly supported by SpacesRepository
    return false;
  }
  
  @override
  Future<SpaceMetrics> getSpaceMetrics(String spaceId) async {
    // Not directly supported by SpacesRepository
    return const SpaceMetrics(
      memberCount: 0,
      eventCount: 0,
      activeMembers: 0,
    );
  }
  
  @override
  Future<List<String>> getUserInterests(String userId) async {
    // Not directly supported by SpacesRepository
    return [];
  }
  
  @override
  Future<bool> updateSpaceVerification(String spaceId, bool isVerified) async {
    // Not directly supported by SpacesRepository
    return false;
  }
  
  @override
  Future<List<Event>> getSpaceEvents(String spaceId) async {
    try {
      // Get events from the space's events subcollection
      final events = await _spacesRepository.getSpaceEvents(spaceId);
      
      // Convert to Event objects and sort by start date
      final List<Event> eventsList = events.map((eventData) {
        return Event(
          id: eventData.id,
          title: eventData.title,
          description: eventData.description,
          startDate: eventData.startDate,
          endDate: eventData.endDate,
          location: eventData.location,
          organizerEmail: eventData.organizerEmail,
          organizerName: eventData.organizerName,
          category: eventData.category,
          status: eventData.status,
          link: eventData.link,
          imageUrl: eventData.imageUrl,
          source: eventData.source,
          createdBy: eventData.createdBy,
          lastModified: eventData.lastModified,
          visibility: eventData.visibility,
          attendees: eventData.attendees ?? [],
          spaceId: spaceId, // Set the spaceId for the event
        );
      }).toList();

      // Sort events by start date
      eventsList.sort((a, b) => a.startDate.compareTo(b.startDate));
      
      return eventsList;
    } catch (e) {
      print('Error fetching space events: $e');
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
  final SpacesRepository _spacesRepository;
  final AuthRepository _authRepository;

  CreateSpaceNotifier(
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

      // Create space through repository - force HIVE exclusive type regardless of passed spaceType
      final createdSpace = await _spacesRepository.createSpace(
        name: name,
        description: description,
        spaceType: SpaceType.hiveExclusive, // Always force HIVE exclusive type
        tags: tags,
        isPrivate: true, // Enforced by business rule
        iconCodePoint: iconCodePoint,
        isHiveExclusive: true, // Always set to true
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
  final spacesRepository = ref.watch(spacesRepositoryProvider);
  final authRepository = ref.watch(authRepositoryProvider);
  return CreateSpaceNotifier(spacesRepository, authRepository);
}); 