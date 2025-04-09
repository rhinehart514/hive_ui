import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/profile/data/datasources/profile_local_datasource.dart';
import 'package:hive_ui/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:hive_ui/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:hive_ui/features/profile/domain/repositories/profile_repository.dart';
import 'package:hive_ui/features/profile/domain/entities/user_profile.dart' as domain;
import 'package:hive_ui/features/profile/data/mappers/user_profile_mapper.dart';
import 'package:hive_ui/models/user_profile.dart' as model;
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/models/space.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Provider for the remote data source
final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((ref) {
  return ProfileRemoteDataSource();
});

// Provider for the local data source
final profileLocalDataSourceProvider = Provider<ProfileLocalDataSource>((ref) {
  return ProfileLocalDataSource();
});

// Base profile repository implementation provider
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final remoteDataSource = ref.watch(profileRemoteDataSourceProvider);
  final localDataSource = ref.watch(profileLocalDataSourceProvider);
  
  return ProfileRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
  );
});

// Profile sync service provider
class ProfileSyncState {
  final bool isSyncing;
  final DateTime? lastSyncTime;
  final String? error;

  const ProfileSyncState({
    this.isSyncing = false,
    this.lastSyncTime,
    this.error,
  });

  ProfileSyncState copyWith({
    bool? isSyncing,
    DateTime? lastSyncTime,
    String? error,
  }) {
    return ProfileSyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      error: error,
    );
  }
}

class ProfileSyncNotifier extends StateNotifier<ProfileSyncState> {
  final ProfileRepository _repository;
  
  ProfileSyncNotifier(this._repository) : super(const ProfileSyncState());
  
  Future<void> syncProfile() async {
    try {
      state = state.copyWith(isSyncing: true, error: null);
      
      // Simulate profile sync - in a real app, this would perform
      // actual synchronization with backend services
      await Future.delayed(const Duration(seconds: 1));
      
      state = state.copyWith(
        isSyncing: false,
        lastSyncTime: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error syncing profile: $e');
      state = state.copyWith(
        isSyncing: false,
        error: 'Failed to sync profile: $e',
      );
    }
  }
  
  Future<void> scheduleSyncProfile() async {
    // Check if we recently synced
    final lastSync = state.lastSyncTime;
    if (lastSync != null) {
      final now = DateTime.now();
      final difference = now.difference(lastSync);
      
      // If we synced within the last 5 minutes, don't sync again
      if (difference.inMinutes < 5) {
        debugPrint('Skipping profile sync: last sync was ${difference.inMinutes} minutes ago');
        return;
      }
    }
    
    return syncProfile();
  }
}

// The profileSyncProvider that's referenced in other files
final profileSyncProvider = StateNotifierProvider<ProfileSyncNotifier, ProfileSyncState>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return ProfileSyncNotifier(repository);
});

// ProfileState class to manage profile state
class ProfileState {
  final model.UserProfile? profile;
  final bool isLoading;
  final String? error;
  final bool hasError;

  const ProfileState({
    this.profile,
    this.isLoading = false,
    this.error,
  }) : hasError = error != null;

  ProfileState copyWith({
    model.UserProfile? profile,
    bool? isLoading,
    String? error,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  // Getter to access the profile value safely
  model.UserProfile? get value => profile;

  // Pattern matching method similar to AsyncValue
  T when<T>({
    required T Function(model.UserProfile) data,
    required T Function() loading,
    required T Function(String? error) error,
  }) {
    if (isLoading) return loading();
    if (hasError) return error(this.error);
    if (profile != null) return data(profile!);
    return loading();
  }

  // Simplified pattern matching for widgets
  Widget whenWidget({
    required Widget Function(model.UserProfile) data,
    Widget Function()? loading,
    Widget Function(String? error)? error,
  }) {
    return when<Widget>(
      data: data,
      loading: loading ?? () => const Center(child: CircularProgressIndicator()),
      error: error ?? (e) => Center(child: Text(e ?? 'An error occurred')),
    );
  }
}

// ProfileNotifier class to manage profile operations
class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileRepository _repository;
  
  ProfileNotifier(this._repository) : super(const ProfileState());

  // Load profile for the current user or specified user ID
  Future<void> loadProfile([String? userId]) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final domainProfile = await _repository.getProfile(userId);
      
      if (domainProfile == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Profile not found',
        );
        return;
      }
      
      // Convert domain profile to model
      final modelProfile = UserProfileMapper.mapToModel(domainProfile);
      
      state = state.copyWith(
        profile: modelProfile,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error loading profile: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load profile: $e',
      );
    }
  }
  
  // Refresh profile data
  Future<void> refreshProfile() async {
    final currentProfile = state.profile;
    if (currentProfile == null) {
      return loadProfile();
    }
    
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final domainProfile = await _repository.getProfile(currentProfile.id);
      
      if (domainProfile == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Profile not found',
        );
        return;
      }
      
      // Convert domain profile to model
      final modelProfile = UserProfileMapper.mapToModel(domainProfile);
      
      state = state.copyWith(
        profile: modelProfile,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error refreshing profile: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to refresh profile: $e',
      );
    }
  }
  
  // Update profile
  Future<bool> updateProfile(model.UserProfile updatedProfile) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // Convert model profile to domain
      final domainProfile = UserProfileMapper.mapToDomain(updatedProfile);
      
      await _repository.updateProfile(domainProfile);
      
      state = state.copyWith(
        profile: updatedProfile,
        isLoading: false,
      );
      
      return true;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update profile: $e',
      );
      return false;
    }
  }
  
  // Update profile interests
  Future<bool> updateUserInterests(List<String> interests) async {
    final currentProfile = state.profile;
    if (currentProfile == null) {
      state = state.copyWith(
        error: 'No profile found to update interests',
      );
      return false;
    }
    
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      await _repository.updateUserInterests(currentProfile.id, interests);
      
      // Create updated profile with new interests
      final updatedProfile = currentProfile.copyWith(
        interests: interests,
        updatedAt: DateTime.now(),
      );
      
      state = state.copyWith(
        profile: updatedProfile,
        isLoading: false,
      );
      
      return true;
    } catch (e) {
      debugPrint('Error updating interests: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update interests: $e',
      );
      return false;
    }
  }
  
  // Save event to profile
  Future<void> saveEvent(Event event) async {
    final currentProfile = state.profile;
    if (currentProfile == null) return;
    
    try {
      await _repository.saveEvent(currentProfile.id, event);
      
      // Optimistically update the UI
      final updatedEvents = List<Event>.from(currentProfile.savedEvents)..add(event);
      final updatedProfile = currentProfile.copyWith(
        savedEvents: updatedEvents,
        eventCount: currentProfile.eventCount + 1,
      );
      
      state = state.copyWith(profile: updatedProfile);
    } catch (e) {
      debugPrint('Error saving event: $e');
    }
  }
  
  // Remove event from profile
  Future<void> removeEvent(String eventId) async {
    final currentProfile = state.profile;
    if (currentProfile == null) return;
    
    try {
      await _repository.removeEvent(currentProfile.id, eventId);
      
      // Optimistically update the UI
      final updatedEvents = currentProfile.savedEvents
          .where((event) => event.id != eventId)
          .toList();
          
      final updatedProfile = currentProfile.copyWith(
        savedEvents: updatedEvents,
        eventCount: currentProfile.eventCount > 0 ? currentProfile.eventCount - 1 : 0,
      );
      
      state = state.copyWith(profile: updatedProfile);
    } catch (e) {
      debugPrint('Error removing event: $e');
    }
  }
  
  // Check if an event is saved by the user
  Future<bool> isEventSaved(String eventId) async {
    final currentProfile = state.profile;
    if (currentProfile == null) return false;
    
    try {
      return await _repository.isEventSaved(currentProfile.id, eventId);
    } catch (e) {
      debugPrint('Error checking saved event: $e');
      return false;
    }
  }
  
  // Update cached profile (used for initial state updates)
  void updateCachedProfile(model.UserProfile cachedProfile) {
    state = state.copyWith(
      profile: cachedProfile,
      isLoading: false,
    );
  }
  
  // Load saved events
  Future<List<Event>> loadSavedEvents() async {
    final currentProfile = state.profile;
    if (currentProfile == null) return [];
    
    try {
      final events = await _repository.getSavedEvents(currentProfile.id);
      
      // Update profile with loaded events
      final updatedProfile = currentProfile.copyWith(
        savedEvents: events,
        eventCount: events.length,
      );
      
      state = state.copyWith(profile: updatedProfile);
      
      return events;
    } catch (e) {
      debugPrint('Error loading saved events: $e');
      return [];
    }
  }
}

// Provider for the current user profile
final currentUserProfileProvider = FutureProvider<domain.UserProfile?>((ref) async {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getProfile();
});

// Provider to watch the current user's profile in real-time
final currentUserProfileStreamProvider = StreamProvider<domain.UserProfile?>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  final currentUser = FirebaseAuth.instance.currentUser;
  
  if (currentUser == null) {
    return Stream.value(null);
  }
  
  return repository.watchProfile(currentUser.uid);
});

/// Provider for user profile by ID
final userProfileProvider = FutureProvider.family<domain.UserProfile?, String>((ref, userId) async {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getProfile(userId);
});

/// Provider for the current user's profile
final currentUserProvider = FutureProvider<model.UserProfile>((ref) async {
  final authService = FirebaseAuth.instance;
  
  // Get the current user ID
  final currentUserId = authService.currentUser?.uid;
  if (currentUserId == null) {
    throw Exception('Not logged in');
  }
  
  // Create a mock profile for testing
  return model.UserProfile(
    id: currentUserId,
    username: 'user_${currentUserId.substring(0, 5)}',
    displayName: 'User ${currentUserId.substring(0, 5)}',
    year: 'Senior',
    major: 'Computer Science',
    residence: 'On Campus',
    eventCount: 5,
    spaceCount: 3,
    friendCount: 120,
    createdAt: DateTime.now().subtract(const Duration(days: 100)),
    updatedAt: DateTime.now(),
    interests: const ['technology', 'music', 'sports'],
    isVerified: true,
    isVerifiedPlus: false,
  );
});

// The main profileProvider used by the UI
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return ProfileNotifier(repository);
});

// Provider for user saved events
final userSavedEventsProvider = FutureProvider.family<List<Event>, String>((ref, userId) async {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getSavedEvents(userId);
});

// Provider for spaces joined by a user
final userJoinedSpacesProvider = FutureProvider.family<List<Space>, String>((ref, userId) async {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getJoinedSpaces(userId);
});

// Provider to check if an event is saved by a user
final isEventSavedProvider = FutureProvider.family<bool, ({String userId, String eventId})>((ref, params) async {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.isEventSaved(params.userId, params.eventId);
});

// Provider to check if the profile being viewed is the current user's profile
final isCurrentUserProfileProvider = StateProvider<bool>((ref) => true); 