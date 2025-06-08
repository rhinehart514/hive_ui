import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/cache/cache_manager.dart';
import 'package:hive_ui/core/cache/cache_providers.dart';
import 'package:hive_ui/core/cache/cache_ttl_config.dart';
import 'package:hive_ui/features/profile/domain/repositories/profile_repository.dart';
import 'package:hive_ui/features/profile/domain/entities/user_profile.dart';
import 'package:hive_ui/features/profile/domain/entities/profile_analytics.dart';
import 'package:hive_ui/features/profile/domain/entities/user_search_filters.dart';
import 'package:hive_ui/features/profile/domain/entities/recommended_user.dart';
import 'package:hive_ui/features/profile/presentation/providers/profile_providers.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/models/space.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// A cached implementation of ProfileRepository that leverages the enhanced cache system
class CachedProfileRepository implements ProfileRepository {
  final ProfileRepository _delegate;
  final CacheManager _cacheManager;
  
  /// Constructor takes a delegate repository that will be used for actual data fetching
  CachedProfileRepository({
    required ProfileRepository delegate,
    required CacheManager cacheManager,
  }) : 
    _delegate = delegate,
    _cacheManager = cacheManager;
  
  @override
  Future<UserProfile?> getProfile([String? userId]) async {
    if (userId == null) {
      // For current user, use the delegate directly as we want fresh data
      return _delegate.getProfile();
    }
    
    // Check cache first
    final cacheKey = 'user:$userId:profile';
    final cachedProfile = _cacheManager.get<UserProfile>(cacheKey);
    
    if (cachedProfile != null) {
      debugPrint('📋 Cache hit for profile: $userId');
      return cachedProfile;
    }
    
    debugPrint('📋 Cache miss for profile: $userId');
    
    // Fetch from delegate repository
    final profile = await _delegate.getProfile(userId);
    
    // Cache the result if found
    if (profile != null) {
      final duration = _isCurrentUser(userId)
          ? CacheTTLConfig.currentUserProfile
          : CacheTTLConfig.userProfile;
          
      _cacheManager.put<UserProfile>(cacheKey, profile, ttl: duration);
    }
    
    return profile;
  }
  
  @override
  Future<void> updateProfile(UserProfile profile) async {
    try {
      // Always perform update operation on delegate
      await _delegate.updateProfile(profile);
      
      // Invalidate and update cache immediately
      _cacheManager.invalidateCache('user:${profile.id}:profile');
      _cacheManager.put<UserProfile>(
        'user:${profile.id}:profile', 
        profile, 
        ttl: CacheTTLConfig.currentUserProfile,
      );
      
      // Also invalidate related caches
      _cacheManager.invalidateCache('user:${profile.id}:friends');
      _cacheManager.invalidateCache('user:${profile.id}:spaces');
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> createProfile(UserProfile profile) async {
    // Create operations should go directly to the delegate
    await _delegate.createProfile(profile);
    
    // Cache the newly created profile
    _cacheManager.put<UserProfile>(
      'user:${profile.id}:profile', 
      profile, 
      ttl: CacheTTLConfig.currentUserProfile,
    );
  }
  
  @override
  Future<String> uploadProfileImage(File imageFile) async {
    // This operation should go directly to the delegate
    return await _delegate.uploadProfileImage(imageFile);
  }
  
  @override
  Future<void> removeProfileImage() async {
    // This operation should go directly to the delegate
    await _delegate.removeProfileImage();
    
    // Invalidate the profile cache to ensure we fetch the updated profile
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _cacheManager.invalidateCache('user:${currentUser.uid}:profile');
    }
  }
  
  @override
  Stream<UserProfile?> watchProfile(String userId) {
    // For real-time streams, we should use the delegate directly
    return _delegate.watchProfile(userId);
  }
  
  @override
  Future<void> updateUserInterests(String userId, List<String> interests) async {
    // This operation should go directly to the delegate
    await _delegate.updateUserInterests(userId, interests);
    
    // Invalidate the profile cache to ensure we fetch the updated profile
    _cacheManager.invalidateCache('user:$userId:profile');
  }
  
  @override
  Future<void> saveEvent(String userId, Event event) async {
    await _delegate.saveEvent(userId, event);
    
    // Invalidate the saved events cache
    _cacheManager.invalidateCache('user:$userId:savedEvents');
  }
  
  @override
  Future<void> removeEvent(String userId, String eventId) async {
    await _delegate.removeEvent(userId, eventId);
    
    // Invalidate the saved events cache
    _cacheManager.invalidateCache('user:$userId:savedEvents');
  }
  
  @override
  Future<List<Event>> getSavedEvents(String userId) async {
    // Check cache first
    final cacheKey = 'user:$userId:savedEvents';
    final cachedEvents = _cacheManager.get<List<Event>>(cacheKey);
    
    if (cachedEvents != null) {
      debugPrint('📋 Cache hit for saved events: $userId');
      return cachedEvents;
    }
    
    debugPrint('📋 Cache miss for saved events: $userId');
    
    // Fetch from delegate repository
    final events = await _delegate.getSavedEvents(userId);
    
    // Cache the result
    _cacheManager.put<List<Event>>(
      cacheKey, 
      events, 
      ttl: CacheTTLConfig.userSavedEvents,
    );
    
    return events;
  }
  
  @override
  Future<bool> isEventSaved(String userId, String eventId) async {
    // This operation is small and used frequently, so we should cache it
    final cacheKey = 'user:$userId:isSaved:$eventId';
    final cachedResult = _cacheManager.get<bool>(cacheKey);
    
    if (cachedResult != null) {
      return cachedResult;
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
      debugPrint('📋 Cache hit for joined spaces: $userId');
      return cachedSpaces;
    }
    
    debugPrint('📋 Cache miss for joined spaces: $userId');
    
    // Fetch from delegate repository
    final spaces = await _delegate.getJoinedSpaces(userId);
    
    // Cache the result
    _cacheManager.put<List<Space>>(
      cacheKey, 
      spaces, 
      ttl: CacheTTLConfig.userSpaces,
    );
    
    return spaces;
  }
  
  @override
  Future<ProfileAnalytics?> getProfileAnalytics(String userId) async {
    // Check cache first
    final cacheKey = 'user:$userId:analytics';
    final cachedAnalytics = _cacheManager.get<ProfileAnalytics>(cacheKey);
    
    if (cachedAnalytics != null) {
      debugPrint('📋 Cache hit for profile analytics: $userId');
      return cachedAnalytics;
    }
    
    debugPrint('📋 Cache miss for profile analytics: $userId');
    
    // Delegate to the repository impl
    final analytics = await _delegate.getProfileAnalytics(userId);
    
    // Cache the result if found
    if (analytics != null) {
      _cacheManager.put<ProfileAnalytics>(
        cacheKey, 
        analytics, 
        ttl: CacheTTLConfig.defaultTTL,
      );
    }
    
    return analytics;
  }

  @override
  Future<void> recordProfileInteraction({
    required String viewedUserId,
    required String viewerId,
    required String interactionType,
  }) async {
    // This is purely a write operation, so we delegate directly
    await _delegate.recordProfileInteraction(
      viewedUserId: viewedUserId,
      viewerId: viewerId,
      interactionType: interactionType,
    );
    
    // Invalidate relevant caches since interaction may affect analytics
    if (interactionType == 'profile_view') {
      _cacheManager.invalidateCache('user:$viewedUserId:analytics');
    }
  }

  @override
  Future<List<UserProfile>> searchProfiles({
    required String query, 
    UserSearchFilters? filters, 
    int limit = 20,
  }) async {
    // For searches, we'll use a very short TTL since results may change frequently
    final cacheKey = 'search:profiles:${query}_${filters?.hashCode ?? 0}_$limit';
    final cachedResults = _cacheManager.get<List<UserProfile>>(cacheKey);
    
    if (cachedResults != null) {
      debugPrint('📋 Cache hit for profile search: $query');
      return cachedResults;
    }
    
    debugPrint('📋 Cache miss for profile search: $query');
    
    // Delegate to the repository impl
    final results = await _delegate.searchProfiles(
      query: query,
      filters: filters,
      limit: limit,
    );
    
    // Cache results for a short time
    _cacheManager.put<List<UserProfile>>(
      cacheKey, 
      results, 
      ttl: const Duration(minutes: 5), // Short TTL for search results
    );
    
    return results;
  }

  @override
  Future<List<RecommendedUser>> getRecommendedUsers({
    String? basedOnUserId,
    int limit = 10,
  }) async {
    final userId = basedOnUserId ?? FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return [];
    }
    
    // Check cache first
    final cacheKey = 'user:$userId:recommended_users:$limit';
    final cachedRecommendations = _cacheManager.get<List<RecommendedUser>>(cacheKey);
    
    if (cachedRecommendations != null) {
      debugPrint('📋 Cache hit for recommended users: $userId');
      return cachedRecommendations;
    }
    
    debugPrint('📋 Cache miss for recommended users: $userId');
    
    // Delegate to the repository impl
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
    
    return recommendations;
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
    // This operation should likely go directly to the delegate and invalidate relevant user cache
    await _delegate.updateUserRestriction(
      userId,
      isRestricted: isRestricted,
      reason: reason,
      endDate: endDate,
      restrictedBy: restrictedBy,
    );
    // Invalidate user profile cache as restriction status might affect profile view
    _cacheManager.invalidateCache('user:$userId:profile');
    debugPrint('📋 Invalidated profile cache for $userId due to restriction update.');
  }
}

/// Provider for the cached profile repository
final cachedProfileRepositoryProvider = Provider<ProfileRepository>((ref) {
  // Get the original repository implementation
  final originalRepository = ref.watch(profileRepositoryProvider);
  
  // Get the cache manager
  final cacheManager = ref.watch(cacheManagerProvider);
  
  // Create and return the cached repository
  return CachedProfileRepository(
    delegate: originalRepository,
    cacheManager: cacheManager,
  );
});

/// Ready-to-use providers for profile data with caching
final userProfileProvider = createCachedProvider<UserProfile?, String>(
  keyBuilder: (userId) => 'user:$userId:profile',
  fetcher: (ref, userId) => ref.read(profileRepositoryProvider).getProfile(userId),
  ttl: CacheTTLConfig.userProfile,
);

final userSavedEventsProvider = createCachedProvider<List<Event>, String>(
  keyBuilder: (userId) => 'user:$userId:savedEvents',
  fetcher: (ref, userId) => ref.read(profileRepositoryProvider).getSavedEvents(userId),
  ttl: CacheTTLConfig.userSavedEvents,
);

final userJoinedSpacesProvider = createCachedProvider<List<Space>, String>(
  keyBuilder: (userId) => 'user:$userId:spaces',
  fetcher: (ref, userId) => ref.read(profileRepositoryProvider).getJoinedSpaces(userId),
  ttl: CacheTTLConfig.userSpaces,
); 