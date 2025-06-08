import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/profile/data/repositories/profile_repository.dart';
import 'package:hive_ui/features/profile/domain/entities/user_profile.dart';

/// State for the profile controller
class ProfileState {
  /// Whether a profile operation is loading
  final bool isLoading;
  
  /// Current error message, if any
  final String? errorMessage;
  
  /// The current user profile
  final UserProfile? profile;
  
  /// Constructor
  const ProfileState({
    this.isLoading = false,
    this.errorMessage,
    this.profile,
  });
  
  /// Create a copy with updated values
  ProfileState copyWith({
    bool? isLoading,
    String? errorMessage,
    UserProfile? profile,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      profile: profile ?? this.profile,
    );
  }
  
  /// Create a loading state
  ProfileState loading() => copyWith(isLoading: true, errorMessage: null);
  
  /// Create an error state
  ProfileState error(String message) => copyWith(
    isLoading: false,
    errorMessage: message,
  );
  
  /// Create a success state
  ProfileState success(UserProfile profile) => copyWith(
    isLoading: false, 
    errorMessage: null,
    profile: profile,
  );
}

/// Notifier for profile operations
class ProfileController extends StateNotifier<ProfileState> {
  final ProfileRepository _repository;
  
  /// Constructor
  ProfileController(this._repository) : super(const ProfileState());
  
  /// Load a user's profile
  Future<void> loadProfile(String userId) async {
    state = state.loading();
    
    try {
      final profile = await _repository.getProfile(userId);
      state = state.success(profile);
    } catch (e) {
      debugPrint('Error loading profile: $e');
      state = state.error('Failed to load profile');
    }
  }
  
  /// Update a user's profile
  Future<bool> updateProfile(String userId, UserProfile profile) async {
    state = state.loading();
    
    try {
      final success = await _repository.updateProfile(userId, profile);
      
      if (success) {
        state = state.success(profile);
      } else {
        state = state.error('Failed to update profile');
      }
      
      return success;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      state = state.error('Failed to update profile: ${e.toString()}');
      return false;
    }
  }
}

/// Provider for the profile controller
final profileControllerProvider = StateNotifierProvider<ProfileController, ProfileState>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return ProfileController(repository);
});

/// Provider for a specific user profile
final userProfileProvider = FutureProvider.family<UserProfile, String>((ref, userId) async {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getProfile(userId);
}); 