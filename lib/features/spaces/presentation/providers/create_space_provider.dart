import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/auth/domain/repositories/auth_repository.dart';
import 'package:hive_ui/features/auth/presentation/providers/auth_provider.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_member_entity.dart';
import 'package:hive_ui/features/spaces/domain/repositories/spaces_repository.dart';
import 'package:hive_ui/features/spaces/domain/usecases/create_space_usecase.dart';
import 'package:hive_ui/features/spaces/presentation/providers/spaces_repository_provider.dart';
import 'package:hive_ui/models/event.dart' as model_event;
import 'package:hive_ui/features/events/domain/entities/event.dart' as event_entity;
import 'package:hive_ui/features/events/data/mappers/event_mapper.dart';
import 'package:hive_ui/models/space.dart';

/// Adapter class to bridge between SpacesRepository interfaces
/// @deprecated Consider using SpacesRepository directly
class SpaceRepositoryAdapter implements SpacesRepository {
  final SpacesRepository _spacesRepository;
  
  SpaceRepositoryAdapter(this._spacesRepository);
  
  // Forward all methods to the spacesRepository
  
  @override
  Future<List<SpaceEntity>> getAllSpaces({
    bool forceRefresh = false,
    bool includePrivate = false,
    bool includeJoined = true,
  }) {
    return _spacesRepository.getAllSpaces(
      forceRefresh: forceRefresh,
      includePrivate: includePrivate,
      includeJoined: includeJoined,
    );
  }

  @override
  Future<SpaceEntity?> getSpaceById(String id, {String? spaceType}) {
    return _spacesRepository.getSpaceById(id, spaceType: spaceType);
  }
  
  @override
  Future<List<SpaceEntity>> getSpacesByCategory(String category) {
    return _spacesRepository.getSpacesByCategory(category);
  }
  
  @override
  Future<List<SpaceEntity>> getJoinedSpaces({String? userId}) {
    return _spacesRepository.getJoinedSpaces(userId: userId);
  }
  
  @override
  Future<List<SpaceEntity>> getInvitedSpaces({String? userId}) {
    return _spacesRepository.getInvitedSpaces(userId: userId);
  }
  
  @override
  Future<List<SpaceEntity>> getRecommendedSpaces({String? userId}) {
    return _spacesRepository.getRecommendedSpaces(userId: userId);
  }
  
  @override
  Future<List<SpaceEntity>> searchSpaces(String query) {
    return _spacesRepository.searchSpaces(query);
  }
  
  @override
  Future<bool> joinSpace(String spaceId, {String? userId}) {
    return _spacesRepository.joinSpace(spaceId, userId: userId);
  }
  
  @override
  Future<bool> leaveSpace(String spaceId, {String? userId}) {
    return _spacesRepository.leaveSpace(spaceId, userId: userId);
  }
  
  @override
  Future<bool> hasJoinedSpace(String spaceId, {String? userId}) {
    return _spacesRepository.hasJoinedSpace(spaceId, userId: userId);
  }
  
  @override
  Future<List<SpaceEntity>> getSpacesWithUpcomingEvents() {
    return _spacesRepository.getSpacesWithUpcomingEvents();
  }
  
  @override
  Future<List<SpaceEntity>> getTrendingSpaces() {
    return _spacesRepository.getTrendingSpaces();
  }
  
  @override
  Future<SpaceEntity> createSpace({
    required String name,
    required String description,
    required int iconCodePoint,
    required SpaceType spaceType,
    required List<String> tags,
    required bool isPrivate,
    required String creatorId,
    required bool isHiveExclusive,
    File? coverImage,
    DateTime? lastActivityAt,
  }) {
    return _spacesRepository.createSpace(
      name: name,
      description: description,
      iconCodePoint: iconCodePoint,
      spaceType: spaceType,
      tags: tags,
      isPrivate: isPrivate,
      creatorId: creatorId,
      isHiveExclusive: isHiveExclusive,
      coverImage: coverImage,
      lastActivityAt: lastActivityAt,
    );
  }
  
  @override
  Future<SpaceEntity> updateSpace(SpaceEntity space) {
    return _spacesRepository.updateSpace(space);
  }
  
  @override
  Future<String> uploadBannerImage(String spaceId, File bannerImage) {
    return _spacesRepository.uploadBannerImage(spaceId, bannerImage);
  }
  
  @override
  Future<String> uploadProfileImage(String spaceId, File profileImage) {
    return _spacesRepository.uploadProfileImage(spaceId, profileImage);
  }
  
  @override
  Future<List<event_entity.Event>> getSpaceEvents(String spaceId, {int limit = 10}) async {
    return _spacesRepository.getSpaceEvents(spaceId, limit: limit);
  }
  
  // New separate method for UI that needs model events
  Future<List<model_event.Event>> getModelSpaceEvents(String spaceId, {int limit = 10}) async {
    try {
      // Fetch domain events from the repository
      final domainEvents = await _spacesRepository.getSpaceEvents(spaceId, limit: limit);
      
      // Map domain events to model events
      return domainEvents.map(EventMapper.toModel).toList();
    } catch (e) {
      debugPrint('Error getting space events in adapter: $e');
      return [];
    }
  }
  
  @override
  Future<bool> isSpaceNameTaken(String name) {
    return _spacesRepository.isSpaceNameTaken(name);
  }
  
  @override
  Future<bool> inviteUsers(String spaceId, List<String> userIds) {
    return _spacesRepository.inviteUsers(spaceId, userIds);
  }
  
  @override
  Future<bool> removeInvites(String spaceId, List<String> userIds) {
    return _spacesRepository.removeInvites(spaceId, userIds);
  }
  
  @override
  Future<bool> addAdmin(String spaceId, String userId) {
    return _spacesRepository.addAdmin(spaceId, userId);
  }
  
  @override
  Future<bool> removeAdmin(String spaceId, String userId) {
    return _spacesRepository.removeAdmin(spaceId, userId);
  }
  
  @override
  Future<List<String>> getSpaceMembers(String spaceId) {
    return _spacesRepository.getSpaceMembers(spaceId);
  }
  
  @override
  Future<SpaceMemberEntity?> getSpaceMember(String spaceId, String memberId) {
    return _spacesRepository.getSpaceMember(spaceId, memberId);
  }
  
  @override
  Future<SpaceMetrics> getSpaceMetrics(String spaceId) {
    return _spacesRepository.getSpaceMetrics(spaceId);
  }
  
  @override
  Future<bool> updateSpaceVerification(String spaceId, bool isVerified) {
    return _spacesRepository.updateSpaceVerification(spaceId, isVerified);
  }
  
  @override
  Future<String?> createSpaceChat(String spaceId, String spaceName, {String? imageUrl}) {
    return _spacesRepository.createSpaceChat(spaceId, spaceName, imageUrl: imageUrl);
  }
  
  @override
  Future<String?> getSpaceChatId(String spaceId) {
    return _spacesRepository.getSpaceChatId(spaceId);
  }
  
  // Implement missing methods from SpacesRepository
  
  @override
  Future<bool> addModerator(String spaceId, String userId) {
    return _spacesRepository.addModerator(spaceId, userId);
  }
  
  @override
  Future<bool> removeModerator(String spaceId, String userId) {
    return _spacesRepository.removeModerator(spaceId, userId);
  }
  
  @override
  Future<bool> updateLifecycleState(
    String spaceId,
    SpaceLifecycleState lifecycleState, {
    DateTime? lastActivityAt,
  }) {
    return _spacesRepository.updateLifecycleState(
      spaceId,
      lifecycleState,
      lastActivityAt: lastActivityAt,
    );
  }
  
  @override
  Future<bool> updateClaimStatus(
    String spaceId,
    SpaceClaimStatus claimStatus, {
    String? claimId,
  }) {
    return _spacesRepository.updateClaimStatus(
      spaceId,
      claimStatus,
      claimId: claimId,
    );
  }

  @override
  Future<List<SpaceMemberEntity>> getSpaceMembersWithDetails(String spaceId) {
    return _spacesRepository.getSpaceMembersWithDetails(spaceId);
  }
  
  @override
  Future<bool> submitLeadershipClaim({
    required String spaceId,
    required String userId,
    required String userName,
    required String email,
    required String reason,
    required String credentials,
  }) {
    return _spacesRepository.submitLeadershipClaim(
      spaceId: spaceId,
      userId: userId,
      userName: userName,
      email: email,
      reason: reason,
      credentials: credentials,
    );
  }
  
  @override
  Future<bool> updateSpaceMemberRole(
    String spaceId,
    String userId,
    String role,
  ) {
    return _spacesRepository.updateSpaceMemberRole(spaceId, userId, role);
  }

  // --- Add Stubs for Missing Methods ---

  @override
  Future<void> requestToJoinSpace(String spaceId, String userId) {
    return _spacesRepository.requestToJoinSpace(spaceId, userId);
  }

  @override
  Future<List<String>> getJoinRequests(String spaceId) {
    return _spacesRepository.getJoinRequests(spaceId);
  }

  @override
  Future<bool> approveJoinRequest(String spaceId, String userIdToApprove) {
    return _spacesRepository.approveJoinRequest(spaceId, userIdToApprove);
  }

  @override
  Future<bool> denyJoinRequest(String spaceId, String userIdToDeny) {
    return _spacesRepository.denyJoinRequest(spaceId, userIdToDeny);
  }

  @override
  Future<bool> initiateSpaceArchive(String spaceId, String initiatorId) {
    return _spacesRepository.initiateSpaceArchive(spaceId, initiatorId);
  }

  @override
  Future<bool> voteOnSpaceArchive(String spaceId, String userId, bool approve) {
    return _spacesRepository.voteOnSpaceArchive(spaceId, userId, approve);
  }

  @override
  Future<Map<String, dynamic>> getSpaceArchiveStatus(String spaceId) {
    return _spacesRepository.getSpaceArchiveStatus(spaceId);
  }

  @override
  Future<List<SpaceEntity>> getFeaturedSpaces({int limit = 20}) {
    return _spacesRepository.getFeaturedSpaces(limit: limit);
  }

  @override
  Future<List<SpaceEntity>> getNewestSpaces({int limit = 20}) {
    return _spacesRepository.getNewestSpaces(limit: limit);
  }

  @override
  Future<bool> updateSpaceActivity(String spaceId) {
    return _spacesRepository.updateSpaceActivity(spaceId);
  }

  @override
  Future<bool> isSpaceAdmin(String spaceId, String userId) {
    return _spacesRepository.isSpaceAdmin(spaceId, userId);
  }

  @override
  Future<SpaceClaimStatus> getClaimStatus(String spaceId) {
    return _spacesRepository.getClaimStatus(spaceId);
  }

  @override
  Future<bool> claimLeadership(String spaceId, String userId, {String? verificationInfo}) {
    return _spacesRepository.claimLeadership(spaceId, userId, verificationInfo: verificationInfo);
  }

  @override
  Future<bool> updateVisibility(String spaceId, bool isPrivate) {
    return _spacesRepository.updateVisibility(spaceId, isPrivate);
  }

  // --- End Stubs ---
}

/// Provider for the SpaceRepository adapter
final spaceRepositoryAdapterProvider = Provider<SpacesRepository>((ref) {
  final spacesRepository = ref.watch(spacesRepositoryProvider);
  return SpaceRepositoryAdapter(spacesRepository);
});

/// Provider for model events that can be used in UI components
final spaceEventsModelProvider = FutureProvider.family<List<model_event.Event>, String>((ref, spaceId) async {
  final adapter = ref.watch(spaceRepositoryAdapterProvider) as SpaceRepositoryAdapter;
  return adapter.getModelSpaceEvents(spaceId);
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