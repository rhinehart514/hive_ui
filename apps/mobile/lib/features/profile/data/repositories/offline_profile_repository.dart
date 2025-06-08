import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/core/cache/cache_manager.dart';
import 'package:hive_ui/core/cache/cache_ttl_config.dart';
import 'package:hive_ui/core/network/conflict_resolver.dart';
import 'package:hive_ui/core/network/connectivity_service.dart';
import 'package:hive_ui/core/network/offline_action.dart';
import 'package:hive_ui/core/network/offline_queue_manager.dart';
import 'package:hive_ui/core/network/offline_repository_mixin.dart';
import 'package:hive_ui/core/network/operation_recovery_manager.dart';
import 'package:hive_ui/features/profile/domain/repositories/profile_repository.dart';
import 'package:hive_ui/features/profile/presentation/providers/profile_providers.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/models/user_profile.dart' as model;
import 'package:hive_ui/models/space.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_ui/features/profile/data/mappers/user_profile_mapper.dart';
import 'package:hive_ui/features/profile/domain/entities/user_profile.dart' as domain;
import 'package:hive_ui/features/profile/domain/entities/profile_analytics.dart';
import 'package:hive_ui/features/profile/domain/entities/user_search_filters.dart';
import 'package:hive_ui/features/profile/domain/entities/recommended_user.dart';

/// An offline-aware implementation of the ProfileRepository
class OfflineProfileRepository with OfflineRepositoryMixin implements ProfileRepository {
  final ProfileRepository _delegate;
  final CacheManager _cacheManager;
  final OfflineQueueManager _offlineQueueManager;
  final ConnectivityService _connectivityService;
  final ConflictResolver _conflictResolver;
  final OperationRecoveryManager _operationRecoveryManager;
  static const String _resourceType = 'profile';
  
  @override
  CacheManager get cacheManager => _cacheManager;
  
  @override
  OfflineQueueManager get offlineQueueManager => _offlineQueueManager;
  
  @override
  ConnectivityService get connectivityService => _connectivityService;
  
  @override
  OperationRecoveryManager get operationRecoveryManager => _operationRecoveryManager;
  
  /// Constructor
  OfflineProfileRepository({
    required ProfileRepository delegate,
    required CacheManager cacheManager,
    required OfflineQueueManager offlineQueueManager,
    required ConnectivityService connectivityService,
    required ConflictResolver conflictResolver,
    required OperationRecoveryManager operationRecoveryManager,
  }) : 
    _delegate = delegate,
    _cacheManager = cacheManager,
    _offlineQueueManager = offlineQueueManager,
    _connectivityService = connectivityService,
    _conflictResolver = conflictResolver,
    _operationRecoveryManager = operationRecoveryManager;
  
  @override
  void registerExecutors() {
    // Register profile executor with conflict resolution
    registerExecutorWithConflictResolution<model.UserProfile>(
      resourceType: _resourceType,
      executor: _executeProfileAction,
      remoteFetcher: _fetchProfileForConflictResolution,
      conflictHandler: _createProfileMergeHandler(),
      conflictStrategy: ConflictStrategy.customMerge,
    );
    
    // Register saved events executor
    offlineQueueManager.registerExecutor(
      'profile_saved_event',
      _executeSavedEventAction,
    );
  }
  
  @override
  bool _resolveCreateFunctionForType(String resourceType) {
    // Support recovery for the profile type
    return resourceType == _resourceType || resourceType == 'profile_saved_event';
  }
  
  @override
  bool _resolveUpdateFunctionForType(String resourceType) {
    // Support recovery for the profile type
    return resourceType == _resourceType;
  }
  
  @override
  bool _resolveDeleteFunctionForType(String resourceType) {
    // Support recovery for saved events
    return resourceType == 'profile_saved_event';
  }
  
  /// Create a conflict handler for profile merging
  ConflictHandler _createProfileMergeHandler() {
    return createMergeHandler<model.UserProfile>(
      getResourceId: (profile) => profile.id,
      fromJson: (json) => model.UserProfile.fromJson(json),
      toJson: (profile) => profile.toJson(),
      mergeEntities: _mergeProfiles,
      cacheKeyPrefix: 'user',
    );
  }
  
  /// Merge two profile entities intelligently
  model.UserProfile _mergeProfiles(model.UserProfile current, model.UserProfile update) {
    return current.copyWith(
      displayName: update.displayName != current.displayName ? update.displayName : current.displayName,
      bio: update.bio != current.bio ? update.bio : current.bio,
      profileImageUrl: update.profileImageUrl != current.profileImageUrl ? update.profileImageUrl : current.profileImageUrl,
      year: update.year != current.year ? update.year : current.year,
      major: update.major != current.major ? update.major : current.major,
      residence: update.residence != current.residence ? update.residence : current.residence,
      interests: update.interests != current.interests ? update.interests : current.interests,
      updatedAt: DateTime.now(),
    );
  }
  
  /// Fetch the current remote profile data for conflict resolution
  Future<Map<String, dynamic>?> _fetchProfileForConflictResolution(OfflineAction action) async {
    try {
      final userId = action.resourceId;
      if (userId == null) return null;
      
      final domainProfile = await _delegate.getProfile(userId);
      if (domainProfile == null) return null;
      
      // Convert domain profile to model
      final modelProfile = UserProfileMapper.mapToModel(domainProfile);
      return modelProfile.toJson();
    } catch (e) {
      debugPrint('❌ OfflineProfileRepository: Error fetching profile for conflict resolution: $e');
      return null;
    }
  }
  
  /// Execute a profile-related offline action
  Future<bool> _executeProfileAction(OfflineAction action) async {
    try {
      switch (action.type) {
        case OfflineActionType.update:
          if (action.resourceId != null) {
            final modelProfile = model.UserProfile.fromJson(action.payload);
            final domainProfile = UserProfileMapper.mapToDomain(modelProfile);
            await _delegate.updateProfile(domainProfile);
            
            // Clear offline update markers
            _cacheManager.invalidateCache('user:${modelProfile.id}:profile:offlineUpdate');
            _cacheManager.invalidateCache('user:${modelProfile.id}:profile:markedForDeletion');
            
            return true;
          }
          return false;
          
        case OfflineActionType.create:
          final modelProfile = model.UserProfile.fromJson(action.payload);
          final domainProfile = UserProfileMapper.mapToDomain(modelProfile);
          await _delegate.createProfile(domainProfile);
          return true;
          
        default:
          debugPrint('❌ OfflineProfileRepository: Unsupported action type: ${action.type}');
          return false;
      }
    } catch (e) {
      debugPrint('❌ OfflineProfileRepository: Error executing action: $e');
      return false;
    }
  }
  
  /// Execute a saved event-related offline action
  Future<bool> _executeSavedEventAction(OfflineAction action) async {
    try {
      final userId = action.payload['userId'] as String;
      final eventId = action.payload['eventId'] as String;
      
      switch (action.type) {
        case OfflineActionType.create:
          final event = Event.fromJson(action.payload['event']);
          await _delegate.saveEvent(userId, event);
          
          // Clear offline markers
          _cacheManager.invalidateCache('user:$userId:savedEvents:$eventId:offlineUpdate');
          
          return true;
          
        case OfflineActionType.delete:
          await _delegate.removeEvent(userId, eventId);
          
          // Clear offline markers
          _cacheManager.invalidateCache('user:$userId:savedEvents:$eventId:markedForDeletion');
          
          return true;
          
        default:
          debugPrint('❌ OfflineProfileRepository: Unsupported saved event action type: ${action.type}');
          return false;
      }
    } catch (e) {
      debugPrint('❌ OfflineProfileRepository: Error executing saved event action: $e');
      return false;
    }
  }
  
  @override
  Future<domain.UserProfile?> getProfile([String? userId]) async {
    if (userId == null) {
      // For current user, use the delegate directly as we want fresh data
      return _delegate.getProfile();
    }
    
    // Check cache first
    final cacheKey = 'user:$userId:profile';
    final cachedModelProfile = getWithOfflineUpdates<model.UserProfile>(
      resourceId: userId,
      cacheKeyPrefix: 'user',
      applyOfflineUpdate: (profile, update) {
        // Apply offline updates to the profile
        return model.UserProfile.fromJson({...profile.toJson(), ...update});
      },
    );
    
    if (cachedModelProfile != null) {
      debugPrint('📱 OfflineProfileRepository: Cache hit for profile: $userId');
      return UserProfileMapper.mapToDomain(cachedModelProfile);
    }
    
    if (!await _connectivityService.checkConnectivity()) {
      debugPrint('📱 OfflineProfileRepository: Offline, returning null for profile: $userId');
      return null;
    }
    
    debugPrint('📱 OfflineProfileRepository: Cache miss for profile: $userId');
    
    // Create an operation record for tracking
    final operationRecord = await operationRecoveryManager.trackOperation(
      operationType: 'fetch',
      resourceType: _resourceType,
      resourceId: userId,
      description: 'Fetch user profile: $userId',
    );
    
    try {
      // Fetch from delegate repository
      final domainProfile = await _delegate.getProfile(userId);
      
      // Cache the result if found
      if (domainProfile != null) {
        final modelProfile = UserProfileMapper.mapToModel(domainProfile);
        final duration = _isCurrentUser(userId)
            ? CacheTTLConfig.currentUserProfile
            : CacheTTLConfig.userProfile;
            
        _cacheManager.put<model.UserProfile>(cacheKey, modelProfile, ttl: duration);
      }
      
      // Mark operation as completed
      await operationRecoveryManager.updateOperation(
        operationRecord.id, 
        OperationStatus.completed,
      );
      
      return domainProfile;
    } catch (e) {
      // Mark operation as failed
      await operationRecoveryManager.updateOperation(
        operationRecord.id, 
        OperationStatus.failed,
        e.toString(),
      );
      
      debugPrint('❌ OfflineProfileRepository: Error fetching profile: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> updateProfile(domain.UserProfile profile) async {
    final modelProfile = UserProfileMapper.mapToModel(profile);
    
    await updateResource<model.UserProfile>(
      resourceType: _resourceType,
      resourceId: profile.id,
      data: modelProfile.toJson(),
      onlineOperation: () => _delegate.updateProfile(profile).then((_) => modelProfile),
      cacheKeyPrefix: 'user',
      priority: 10, // High priority for profile updates
      operationDescription: 'Update profile for ${profile.displayName}',
      // The remoteFetcher and conflictHandler are registered globally in registerExecutors
    );
  }
  
  @override
  Future<void> createProfile(domain.UserProfile profile) async {
    final modelProfile = UserProfileMapper.mapToModel(profile);
    
    await createResource<model.UserProfile>(
      resourceType: _resourceType,
      data: modelProfile.toJson(),
      onlineOperation: () => _delegate.createProfile(profile).then((_) => modelProfile),
      getResourceId: (p) => p.id,
      cacheKeyPrefix: 'user',
      priority: 10, // High priority for profile creation
      operationDescription: 'Create profile for ${profile.displayName}',
    );
  }
  
  @override
  Future<String> uploadProfileImage(File imageFile) async {
    // This operation requires connectivity and can't be queued
    if (!await _connectivityService.checkConnectivity()) {
      throw Exception('Cannot upload profile image in offline mode');
    }
    
    // Track the operation
    final operationRecord = await operationRecoveryManager.trackOperation(
      operationType: 'upload_image',
      resourceType: _resourceType,
      description: 'Upload profile image',
    );
    
    try {
      final result = await _delegate.uploadProfileImage(imageFile);
      
      // Mark operation as completed
      await operationRecoveryManager.updateOperation(
        operationRecord.id, 
        OperationStatus.completed,
      );
      
      return result;
    } catch (e) {
      // Mark operation as failed
      await operationRecoveryManager.updateOperation(
        operationRecord.id, 
        OperationStatus.failed,
        e.toString(),
      );
      
      debugPrint('❌ OfflineProfileRepository: Error uploading profile image: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> removeProfileImage() async {
    // This operation requires connectivity and can't be queued
    if (!await _connectivityService.checkConnectivity()) {
      throw Exception('Cannot remove profile image in offline mode');
    }
    
    // Track the operation
    final operationRecord = await operationRecoveryManager.trackOperation(
      operationType: 'remove_image',
      resourceType: _resourceType,
      description: 'Remove profile image',
    );
    
    try {
      await _delegate.removeProfileImage();
      
      // Invalidate the profile cache to ensure we fetch the updated profile
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        _cacheManager.invalidateCache('user:${currentUser.uid}:profile');
      }
      
      // Mark operation as completed
      await operationRecoveryManager.updateOperation(
        operationRecord.id, 
        OperationStatus.completed,
      );
    } catch (e) {
      // Mark operation as failed
      await operationRecoveryManager.updateOperation(
        operationRecord.id, 
        OperationStatus.failed,
        e.toString(),
      );
      
      debugPrint('❌ OfflineProfileRepository: Error removing profile image: $e');
      rethrow;
    }
  }
  
  @override
  Stream<domain.UserProfile?> watchProfile(String userId) {
    // For real-time streams, we use the delegate directly
    return _delegate.watchProfile(userId);
  }
  
  @override
  Future<void> updateUserInterests(String userId, List<String> interests) async {
    await updateResource<model.UserProfile>(
      resourceType: _resourceType,
      resourceId: userId,
      data: {'interests': interests},
      onlineOperation: () async {
        await _delegate.updateUserInterests(userId, interests);
        // Convert domain profile to model
        final domainProfile = await _delegate.getProfile(userId);
        if (domainProfile != null) {
          return UserProfileMapper.mapToModel(domainProfile);
        }
        // Return a placeholder if no profile was found
        return model.UserProfile(
          id: userId,
          username: userId,
          displayName: '',
          email: '',
          year: '',
          major: '',
          residence: '',
          interests: interests,
          eventCount: 0,
          spaceCount: 0,
          friendCount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isPublic: true,
          isVerified: false,
          isVerifiedPlus: false,
        );
      },
      cacheKeyPrefix: 'user',
      operationDescription: 'Update user interests',
    );
  }
  
  @override
  Future<void> saveEvent(String userId, Event event) async {
    await createResource<bool>(
      resourceType: 'profile_saved_event',
      data: {
        'userId': userId,
        'eventId': event.id,
        'event': event.toJson(),
      },
      onlineOperation: () => _delegate.saveEvent(userId, event).then((_) => true),
      getResourceId: (_) => event.id,
      cacheKeyPrefix: 'user:$userId:savedEvents',
      operationDescription: 'Save event: ${event.title}',
    );
    
    // Optimistically update the saved events cache
    final cachedEvents = _cacheManager.get<List<Event>>('user:$userId:savedEvents');
    if (cachedEvents != null) {
      final updatedEvents = [...cachedEvents];
      if (!updatedEvents.any((e) => e.id == event.id)) {
        updatedEvents.add(event);
        _cacheManager.put('user:$userId:savedEvents', updatedEvents);
      }
    }
  }
  
  @override
  Future<void> removeEvent(String userId, String eventId) async {
    await deleteResource(
      resourceType: 'profile_saved_event',
      resourceId: eventId,
      onlineOperation: () => _delegate.removeEvent(userId, eventId).then((_) => true),
      cacheKeyPrefix: 'user:$userId:savedEvents',
      operationDescription: 'Remove saved event',
    );
    
    // Optimistically update the saved events cache
    final cachedEvents = _cacheManager.get<List<Event>>('user:$userId:savedEvents');
    if (cachedEvents != null) {
      final updatedEvents = cachedEvents.where((e) => e.id != eventId).toList();
      _cacheManager.put('user:$userId:savedEvents', updatedEvents);
    }
  }
  
  @override
  Future<List<Event>> getSavedEvents(String userId) async {
    // Check cache first
    final cacheKey = 'user:$userId:savedEvents';
    final cachedEvents = _cacheManager.get<List<Event>>(cacheKey);
    
    if (cachedEvents != null) {
      debugPrint('📱 OfflineProfileRepository: Cache hit for saved events: $userId');
      
      // Filter out events marked for deletion
      return cachedEvents.where((event) {
        return !hasOfflineUpdates(
          resourceId: event.id,
          cacheKeyPrefix: 'user:$userId:savedEvents',
        );
      }).toList();
    }
    
    if (!await _connectivityService.checkConnectivity()) {
      debugPrint('📱 OfflineProfileRepository: Offline, returning empty list for saved events: $userId');
      return [];
    }
    
    debugPrint('📱 OfflineProfileRepository: Cache miss for saved events: $userId');
    
    // Track the operation
    final operationRecord = await operationRecoveryManager.trackOperation(
      operationType: 'fetch_events',
      resourceType: 'profile_saved_event',
      resourceId: userId,
      description: 'Fetch saved events for user: $userId',
    );
    
    try {
      // Fetch from delegate repository
      final events = await _delegate.getSavedEvents(userId);
      
      // Cache the result
      _cacheManager.put<List<Event>>(
        cacheKey, 
        events, 
        ttl: CacheTTLConfig.userSavedEvents,
      );
      
      // Mark operation as completed
      await operationRecoveryManager.updateOperation(
        operationRecord.id, 
        OperationStatus.completed,
      );
      
      return events;
    } catch (e) {
      // Mark operation as failed
      await operationRecoveryManager.updateOperation(
        operationRecord.id, 
        OperationStatus.failed,
        e.toString(),
      );
      
      debugPrint('❌ OfflineProfileRepository: Error fetching saved events: $e');
      rethrow;
    }
  }
  
  @override
  Future<bool> isEventSaved(String userId, String eventId) async {
    // This operation is small and used frequently, so we should cache it
    final cacheKey = 'user:$userId:isSaved:$eventId';
    final cachedResult = _cacheManager.get<bool>(cacheKey);
    
    if (cachedResult != null) {
      // Check if it's marked for deletion
      final markedForDeletion = _cacheManager.get<bool>('user:$userId:savedEvents:$eventId:markedForDeletion');
      if (markedForDeletion == true) {
        return false;
      }
      return cachedResult;
    }
    
    if (!await _connectivityService.checkConnectivity()) {
      // In offline mode, check if we have a pending action to save this event
      final pendingActions = _offlineQueueManager.pendingActions
          .where((action) => 
              action.resourceType == 'profile_saved_event' && 
              action.payload['eventId'] == eventId &&
              action.type == OfflineActionType.create)
          .toList();
          
      if (pendingActions.isNotEmpty) {
        return true;
      }
      
      return false;
    }
    
    // Delegate to the repository
    final result = await _delegate.isEventSaved(userId, eventId);
    
    // Cache the result with a short TTL
    _cacheManager.put<bool>(cacheKey, result, ttl: CacheTTLConfig.rsvpStatus);
    
    return result;
  }
  
  @override
  Future<List<Space>> getJoinedSpaces(String userId) async {
    // Check cache first
    final cacheKey = 'user:$userId:spaces';
    final cachedSpaces = _cacheManager.get<List<Space>>(cacheKey);
    
    if (cachedSpaces != null) {
      debugPrint('📱 OfflineProfileRepository: Cache hit for joined spaces: $userId');
      return cachedSpaces;
    }
    
    if (!await _connectivityService.checkConnectivity()) {
      debugPrint('📱 OfflineProfileRepository: Offline, returning empty list for joined spaces: $userId');
      return [];
    }
    
    debugPrint('📱 OfflineProfileRepository: Cache miss for joined spaces: $userId');
    
    // Track the operation
    final operationRecord = await operationRecoveryManager.trackOperation(
      operationType: 'fetch_spaces',
      resourceType: 'space',
      resourceId: userId,
      description: 'Fetch joined spaces for user: $userId',
    );
    
    try {
      // Fetch from delegate repository
      final spaces = await _delegate.getJoinedSpaces(userId);
      
      // Cache the result
      _cacheManager.put<List<Space>>(
        cacheKey, 
        spaces, 
        ttl: CacheTTLConfig.userSpaces,
      );
      
      // Mark operation as completed
      await operationRecoveryManager.updateOperation(
        operationRecord.id, 
        OperationStatus.completed,
      );
      
      return spaces;
    } catch (e) {
      // Mark operation as failed
      await operationRecoveryManager.updateOperation(
        operationRecord.id, 
        OperationStatus.failed,
        e.toString(),
      );
      
      debugPrint('❌ OfflineProfileRepository: Error fetching joined spaces: $e');
      rethrow;
    }
  }
  
  /// Helper method to check if user ID is the current user
  bool _isCurrentUser(String userId) {
    final currentUser = FirebaseAuth.instance.currentUser;
    return currentUser != null && currentUser.uid == userId;
  }

  @override
  Future<void> updateUserRestriction(String userId, {
    required bool isRestricted,
    String? reason,
    DateTime? endDate,
    String? restrictedBy,
  }) async {
    // Restrictions are critical and should ideally not be handled offline,
    // or require specific handling (e.g., queuing with high priority and admin auth).
    // For now, we delegate directly and don't support offline restriction updates.
    if (!await _connectivityService.checkConnectivity()) {
      throw Exception('User restriction updates require an active internet connection.');
    }

    // Track the operation
    final operationRecord = await operationRecoveryManager.trackOperation(
      operationType: 'update_restriction',
      resourceType: _resourceType,
      resourceId: userId,
      description: 'Update restriction for user: $userId',
    );

    try {
      await _delegate.updateUserRestriction(
        userId,
        isRestricted: isRestricted,
        reason: reason,
        endDate: endDate,
        restrictedBy: restrictedBy,
      );

      // Mark operation as completed
      await operationRecoveryManager.updateOperation(
        operationRecord.id, 
        OperationStatus.completed,
      );

      // Invalidate user profile cache
      _cacheManager.invalidateCache('user:$userId:profile');
      debugPrint('📱 Invalidated profile cache for $userId due to restriction update.');
    } catch (e) {
      // Mark operation as failed
      await operationRecoveryManager.updateOperation(
        operationRecord.id, 
        OperationStatus.failed,
        e.toString(),
      );
      debugPrint('❌ OfflineProfileRepository: Error updating user restriction: $e');
      rethrow;
    }
  }

  @override
  Future<ProfileAnalytics?> getProfileAnalytics(String userId) async {
    // Try to get from cache first
    final cacheKey = 'user:$userId:analytics';
    final cachedAnalytics = _cacheManager.get<ProfileAnalytics>(cacheKey);
    
    if (cachedAnalytics != null) {
      debugPrint('📱 OfflineProfileRepository: Cache hit for profile analytics: $userId');
      return cachedAnalytics;
    }

    if (!await _connectivityService.checkConnectivity()) {
      debugPrint('📱 OfflineProfileRepository: Offline, returning null for profile analytics');
      return null;
    }
    
    // Track the operation
    final operationRecord = await operationRecoveryManager.trackOperation(
      operationType: 'fetch_analytics',
      resourceType: _resourceType,
      resourceId: userId,
      description: 'Fetch profile analytics for: $userId',
    );
    
    try {
      // Delegate to online repository
      final analytics = await _delegate.getProfileAnalytics(userId);
      
      // Cache the result if found
      if (analytics != null) {
        _cacheManager.put<ProfileAnalytics>(
          cacheKey, 
          analytics, 
          ttl: CacheTTLConfig.defaultTTL,
        );
      }
      
      // Mark operation as completed
      await operationRecoveryManager.updateOperation(
        operationRecord.id, 
        OperationStatus.completed,
      );
      
      return analytics;
    } catch (e) {
      // Mark operation as failed
      await operationRecoveryManager.updateOperation(
        operationRecord.id, 
        OperationStatus.failed,
        e.toString(),
      );
      
      debugPrint('❌ OfflineProfileRepository: Error fetching profile analytics: $e');
      rethrow;
    }
  }

  @override
  Future<void> recordProfileInteraction({
    required String viewedUserId,
    required String viewerId,
    required String interactionType,
  }) async {
    // This is an analytics operation that doesn't need to be queued when offline
    if (!await _connectivityService.checkConnectivity()) {
      // Simply log the interaction locally if offline
      debugPrint('📱 OfflineProfileRepository: Offline, skipping profile interaction recording');
      return;
    }
    
    // If online, delegate to the repository
    await _delegate.recordProfileInteraction(
      viewedUserId: viewedUserId,
      viewerId: viewerId,
      interactionType: interactionType,
    );
  }

  @override
  Future<List<domain.UserProfile>> searchProfiles({
    required String query,
    UserSearchFilters? filters,
    int limit = 20,
  }) async {
    // This operation requires connectivity and can't be cached reliably
    if (!await _connectivityService.checkConnectivity()) {
      debugPrint('📱 OfflineProfileRepository: Offline, returning empty list for search');
      return [];
    }
    
    // Delegate to online repository
    return _delegate.searchProfiles(
      query: query,
      filters: filters,
      limit: limit,
    );
  }

  @override
  Future<List<RecommendedUser>> getRecommendedUsers({
    String? basedOnUserId,
    int limit = 10,
  }) async {
    // Check cache first
    final userId = basedOnUserId ?? FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return [];
    }
    
    final cacheKey = 'user:$userId:recommended_users:$limit';
    final cachedRecommendations = _cacheManager.get<List<RecommendedUser>>(cacheKey);
    
    if (cachedRecommendations != null) {
      debugPrint('📱 OfflineProfileRepository: Cache hit for recommended users: $userId');
      return cachedRecommendations;
    }
    
    if (!await _connectivityService.checkConnectivity()) {
      debugPrint('📱 OfflineProfileRepository: Offline, returning empty list for recommended users');
      return [];
    }
    
    // Track the operation
    final operationRecord = await operationRecoveryManager.trackOperation(
      operationType: 'fetch_recommendations',
      resourceType: _resourceType,
      resourceId: userId,
      description: 'Fetch recommended users for: $userId',
    );
    
    try {
      // Delegate to the repository
      final recommendations = await _delegate.getRecommendedUsers(
        basedOnUserId: userId,
        limit: limit,
      );
      
      // Cache the result
      _cacheManager.put<List<RecommendedUser>>(
        cacheKey, 
        recommendations, 
        ttl: CacheTTLConfig.defaultTTL,
      );
      
      // Mark operation as completed
      await operationRecoveryManager.updateOperation(
        operationRecord.id, 
        OperationStatus.completed,
      );
      
      return recommendations;
    } catch (e) {
      // Mark operation as failed
      await operationRecoveryManager.updateOperation(
        operationRecord.id, 
        OperationStatus.failed,
        e.toString(),
      );
      
      debugPrint('❌ OfflineProfileRepository: Error fetching recommended users: $e');
      return [];
    }
  }
}

/// Provider for the offline profile repository
final offlineProfileRepositoryProvider = createOfflineRepositoryProvider<ProfileRepository>(
  create: (offlineQueueManager, connectivityService, cacheManager, conflictResolver, operationRecoveryManager, ref) {
    // Get the original repository implementation
    final delegate = ref.read(profileRepositoryProvider);
    
    // Create and return the offline repository
    return OfflineProfileRepository(
      delegate: delegate,
      cacheManager: cacheManager,
      offlineQueueManager: offlineQueueManager,
      connectivityService: connectivityService,
      conflictResolver: conflictResolver,
      operationRecoveryManager: operationRecoveryManager,
    );
  },
  name: 'offlineProfileRepository',
); 