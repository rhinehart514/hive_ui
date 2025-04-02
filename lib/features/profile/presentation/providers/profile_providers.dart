import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/profile/data/datasources/profile_local_datasource.dart';
import 'package:hive_ui/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:hive_ui/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:hive_ui/features/profile/domain/repositories/profile_repository.dart';
import 'package:hive_ui/features/profile/domain/usecases/create_profile_usecase.dart';
import 'package:hive_ui/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:hive_ui/features/profile/domain/usecases/remove_profile_image_usecase.dart';
import 'package:hive_ui/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:hive_ui/features/profile/domain/usecases/update_user_interests_usecase.dart';
import 'package:hive_ui/features/profile/domain/usecases/upload_profile_image_usecase.dart';
import 'package:hive_ui/features/profile/domain/usecases/watch_profile_usecase.dart';
import 'package:hive_ui/models/user_profile.dart';

// State class for profile
class ProfileState {
  final UserProfile? profile;
  final bool isLoading;
  final String? error;
  final bool hasError;

  const ProfileState({
    this.profile,
    this.isLoading = false,
    this.error,
  }) : hasError = error != null;

  ProfileState copyWith({
    UserProfile? profile,
    bool? isLoading,
    String? error,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Getter to access the profile value safely
  UserProfile? get value => profile;

  /// Pattern matching method similar to AsyncValue
  T when<T>({
    required T Function(UserProfile) data,
    required T Function() loading,
    required T Function(String? error) error,
  }) {
    if (isLoading) return loading();
    if (hasError) return error(this.error);
    if (profile != null) return data(profile!);
    return loading();
  }

  /// Simplified pattern matching for widgets
  T mapState<T>({
    required T Function(UserProfile) data,
    required T Function() loading,
    required T Function(String? error) error,
  }) {
    if (isLoading) return loading();
    if (hasError) return error(this.error);
    if (profile != null) return data(profile!);
    return loading();
  }

  /// Widget-specific pattern matching for convenience
  Widget whenWidget({
    required Widget Function(UserProfile) data,
    Widget Function()? loading,
    Widget Function(String? error)? error,
  }) {
    return mapState<Widget>(
      data: data,
      loading:
          loading ?? () => const Center(child: CircularProgressIndicator()),
      error: error ?? (e) => Center(child: Text(e ?? 'An error occurred')),
    );
  }
}

// Data source providers
final profileRemoteDataSourceProvider =
    Provider<ProfileRemoteDataSource>((ref) {
  return ProfileRemoteDataSource();
});

final profileLocalDataSourceProvider = Provider<ProfileLocalDataSource>((ref) {
  return ProfileLocalDataSource();
});

// Repository provider
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final remoteDataSource = ref.watch(profileRemoteDataSourceProvider);
  final localDataSource = ref.watch(profileLocalDataSourceProvider);

  return ProfileRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
  );
});

// Use case providers
final getProfileUseCaseProvider = Provider<GetProfileUseCase>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return GetProfileUseCase(repository);
});

final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return UpdateProfileUseCase(repository);
});

final updateUserInterestsUseCaseProvider = Provider<UpdateUserInterestsUseCase>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return UpdateUserInterestsUseCase(repository);
});

final createProfileUseCaseProvider = Provider<CreateProfileUseCase>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return CreateProfileUseCase(repository);
});

final uploadProfileImageUseCaseProvider =
    Provider<UploadProfileImageUseCase>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return UploadProfileImageUseCase(repository);
});

final removeProfileImageUseCaseProvider =
    Provider<RemoveProfileImageUseCase>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return RemoveProfileImageUseCase(repository);
});

final watchProfileUseCaseProvider = Provider<WatchProfileUseCase>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return WatchProfileUseCase(repository);
});

// State notifier
class ProfileNotifier extends StateNotifier<ProfileState> {
  final GetProfileUseCase _getProfileUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;
  final CreateProfileUseCase _createProfileUseCase;
  final UploadProfileImageUseCase _uploadProfileImageUseCase;
  final RemoveProfileImageUseCase _removeProfileImageUseCase;
  final WatchProfileUseCase _watchProfileUseCase;
  final UpdateUserInterestsUseCase _updateUserInterestsUseCase;

  ProfileNotifier({
    required GetProfileUseCase getProfileUseCase,
    required UpdateProfileUseCase updateProfileUseCase,
    required CreateProfileUseCase createProfileUseCase,
    required UploadProfileImageUseCase uploadProfileImageUseCase,
    required RemoveProfileImageUseCase removeProfileImageUseCase,
    required WatchProfileUseCase watchProfileUseCase,
    required UpdateUserInterestsUseCase updateUserInterestsUseCase,
  })  : _getProfileUseCase = getProfileUseCase,
        _updateProfileUseCase = updateProfileUseCase,
        _createProfileUseCase = createProfileUseCase,
        _uploadProfileImageUseCase = uploadProfileImageUseCase,
        _removeProfileImageUseCase = removeProfileImageUseCase,
        _watchProfileUseCase = watchProfileUseCase,
        _updateUserInterestsUseCase = updateUserInterestsUseCase,
        super(const ProfileState());

  /// Load the current user's profile
  Future<void> loadProfile([String? userId]) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final profile = await _getProfileUseCase.execute(userId);

      if (profile == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Profile not found',
        );
        return;
      }

      state = state.copyWith(
        profile: profile,
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

  /// Update profile with new data
  Future<void> updateProfile(UserProfile updatedProfile) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _updateProfileUseCase.execute(updatedProfile);

      state = state.copyWith(
        profile: updatedProfile,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error updating profile: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update profile: $e',
      );
    }
  }

  /// Create a new profile
  Future<void> createProfile(UserProfile profile) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _createProfileUseCase.execute(profile);

      state = state.copyWith(
        profile: profile,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error creating profile: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create profile: $e',
      );
    }
  }

  /// Upload profile image
  Future<String?> uploadProfileImage(File imageFile) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final imageUrl = await _uploadProfileImageUseCase.execute(imageFile);

      // Update profile with new image URL
      if (state.profile != null) {
        final updatedProfile = state.profile!.copyWith(
          profileImageUrl: imageUrl,
          updatedAt: DateTime.now(),
        );

        await _updateProfileUseCase.execute(updatedProfile);

        state = state.copyWith(
          profile: updatedProfile,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }

      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to upload profile image: $e',
      );
      return null;
    }
  }

  /// Remove profile image
  Future<void> removeProfileImage() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _removeProfileImageUseCase.execute();

      // Update profile with null image URL
      if (state.profile != null) {
        final updatedProfile = state.profile!.copyWith(
          profileImageUrl: null,
          updatedAt: DateTime.now(),
        );

        state = state.copyWith(
          profile: updatedProfile,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      debugPrint('Error removing profile image: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to remove profile image: $e',
      );
    }
  }

  /// Refresh profile with latest data
  Future<void> refreshProfile() async {
    try {
      // If we already have a profile, keep it and show loading indicator
      final currentProfile = state.profile;
      state =
          state.copyWith(isLoading: true, error: null, profile: currentProfile);

      final profile = await _getProfileUseCase.execute();

      if (profile == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Profile not found',
        );
        return;
      }

      state = state.copyWith(
        profile: profile,
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

  /// Watch profile for real-time updates
  void watchProfile(String userId) {
    try {
      _watchProfileUseCase.execute(userId).listen(
        (profile) {
          if (profile != null) {
            state = state.copyWith(
              profile: profile,
              isLoading: false,
            );
          }
        },
        onError: (e) {
          debugPrint('Error watching profile: $e');
          state = state.copyWith(
            isLoading: false,
            error: 'Failed to watch profile: $e',
          );
        },
      );
    } catch (e) {
      debugPrint('Error setting up profile watch: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to set up profile watch: $e',
      );
    }
  }

  /// Create a mock profile for cases where real profile data can't be loaded
  /// Used for suggested friends or other scenarios where we need fallback data
  Future<void> createMockProfile(String userId) async {
    try {
      // Check if we already have this profile loaded
      if (state.profile?.id == userId) return;
      
      // Set loading state
      state = state.copyWith(isLoading: true, error: null);
      
      // Map of known mock user IDs to their profiles
      // This ensures consistency between suggested friends and their profiles
      final mockProfiles = {
        'mz9JUBBh8TQB5TSqGYUukL1PVmr1': UserProfile(
          id: 'mz9JUBBh8TQB5TSqGYUukL1PVmr1',
          username: 'alex_rivera',
          email: 'alex.rivera@example.com',
          displayName: 'Alex Rivera',
          bio: "CS student passionate about AI and machine learning. Always looking to connect with fellow developers for hackathons and projects!",
          major: 'Computer Science',
          year: 'Junior',
          residence: 'North Campus Housing',
          eventCount: 7,
          clubCount: 3,
          friendCount: 24,
          createdAt: DateTime.now().subtract(const Duration(days: 110)),
          updatedAt: DateTime.now().subtract(const Duration(days: 2)),
          interests: const ['Hackathons', 'Programming', 'Machine Learning', 'Game Development'],
          isVerified: true,
          profileImageUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=80',
        ),
        
        'CrwYdwfLPuVUkgUHoXlIBPXx7Os1': UserProfile(
          id: 'CrwYdwfLPuVUkgUHoXlIBPXx7Os1',
          username: 'jordan_chen',
          email: 'jordan.chen@example.com',
          displayName: 'Jordan Chen',
          bio: "Psychology major researching cognitive development. Love playing piano in my spare time and attending local concerts.",
          major: 'Psychology',
          year: 'Sophomore',
          residence: 'South Quad',
          eventCount: 5,
          clubCount: 2,
          friendCount: 18,
          createdAt: DateTime.now().subtract(const Duration(days: 85)),
          updatedAt: DateTime.now().subtract(const Duration(days: 5)),
          interests: const ['Music Production', 'Classical Piano', 'Concert Photography', 'Vinyl Collection'],
          isVerified: false,
          profileImageUrl: 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=80',
        ),
        
        '5LKGjm9Zt0WgfFIZMlpRzSWO2362': UserProfile(
          id: '5LKGjm9Zt0WgfFIZMlpRzSWO2362',
          username: 'taylor_kim',
          email: 'taylor.kim@example.com',
          displayName: 'Taylor Kim',
          bio: "Business student specializing in marketing. Enjoy filming short documentaries and working on my photography portfolio.",
          major: 'Business Administration',
          year: 'Senior',
          residence: 'North Campus Housing',
          eventCount: 12,
          clubCount: 4,
          friendCount: 35,
          createdAt: DateTime.now().subtract(const Duration(days: 210)),
          updatedAt: DateTime.now().subtract(const Duration(days: 1)),
          interests: const ['Film Studies', 'Screenwriting', 'Photography', 'Visual Arts'],
          isVerified: true,
          profileImageUrl: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=80',
        ),
        
        'bTp0tBLTnXcHJYSXCYiYHQqMAyH3': UserProfile(
          id: 'bTp0tBLTnXcHJYSXCYiYHQqMAyH3',
          username: 'morgan_singh',
          email: 'morgan.singh@example.com',
          displayName: 'Morgan Singh',
          bio: "Mechanical engineering student focusing on sustainable design. Sports enthusiast and outdoor adventure seeker.",
          major: 'Mechanical Engineering',
          year: 'Freshman',
          residence: 'College Town Suites',
          eventCount: 3,
          clubCount: 1,
          friendCount: 9,
          createdAt: DateTime.now().subtract(const Duration(days: 45)),
          updatedAt: DateTime.now().subtract(const Duration(days: 3)),
          interests: const ['Basketball', 'Tennis', 'Hiking', 'Rock Climbing'],
          isVerified: false,
          profileImageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=80',
        ),
        
        'l7oRGYSH5mTtpCzwqkB0RQrpLwl1': UserProfile(
          id: 'l7oRGYSH5mTtpCzwqkB0RQrpLwl1',
          username: 'casey_patel',
          email: 'casey.patel@example.com',
          displayName: 'Casey Patel',
          bio: "Graduate design student creating interactive digital experiences. Avid reader and writer of short fiction.",
          major: 'Graphic Design',
          year: 'Graduate',
          residence: 'Downtown Apartments',
          eventCount: 9,
          clubCount: 2,
          friendCount: 28,
          createdAt: DateTime.now().subtract(const Duration(days: 150)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
          interests: const ['Book Club', 'Poetry Writing', 'Literary Criticism', 'Creative Writing'],
          isVerified: true,
          profileImageUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=80',
        ),
      };
      
      // Create a mock profile based on known ID or generate a generic one
      final mockProfile = mockProfiles[userId] ?? UserProfile(
        id: userId,
        username: 'user_${userId.substring(0, 4)}',
        email: 'user@example.com',
        displayName: 'User ${userId.substring(0, 4).toUpperCase()}',
        bio: 'This is a sample profile for demonstration purposes.',
        major: 'Computer Science',
        year: 'Junior',
        residence: 'Campus Housing',
        eventCount: 5,
        clubCount: 2, 
        friendCount: 15,
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        updatedAt: DateTime.now(),
        interests: const ['Technology', 'Programming', 'Design', 'Music'],
        isVerified: false,
        profileImageUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=80',
      );
      
      // Update state with mock profile
      state = state.copyWith(
        profile: mockProfile,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error creating mock profile: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create mock profile: $e',
      );
    }
  }

  /// Update just the interests for a user
  Future<void> updateUserInterests(String userId, List<String> interests) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // Validate inputs
      if (userId.isEmpty) {
        throw Exception('User ID cannot be empty');
      }
      
      // Update interests using dedicated use case
      await _updateUserInterestsUseCase.execute(userId, interests);
      
      // If this is the current user's profile, update the state
      if (state.profile != null && state.profile!.id == userId) {
        state = state.copyWith(
          profile: state.profile!.copyWith(
            interests: interests,
            updatedAt: DateTime.now(),
          ),
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      debugPrint('ProfileNotifier: Error updating interests: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update interests: $e',
      );
    }
  }
}

// Profile state notifier provider
final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  // Get use cases from providers
  final getProfileUseCase = ref.watch(getProfileUseCaseProvider);
  final updateProfileUseCase = ref.watch(updateProfileUseCaseProvider);
  final createProfileUseCase = ref.watch(createProfileUseCaseProvider);
  final uploadProfileImageUseCase =
      ref.watch(uploadProfileImageUseCaseProvider);
  final removeProfileImageUseCase =
      ref.watch(removeProfileImageUseCaseProvider);
  final watchProfileUseCase = ref.watch(watchProfileUseCaseProvider);
  final updateUserInterestsUseCase = ref.watch(updateUserInterestsUseCaseProvider);

  return ProfileNotifier(
    getProfileUseCase: getProfileUseCase,
    updateProfileUseCase: updateProfileUseCase,
    createProfileUseCase: createProfileUseCase,
    uploadProfileImageUseCase: uploadProfileImageUseCase,
    removeProfileImageUseCase: removeProfileImageUseCase,
    watchProfileUseCase: watchProfileUseCase,
    updateUserInterestsUseCase: updateUserInterestsUseCase,
  );
});

// Provider to check if currently viewing own profile
final isCurrentUserProfileProvider = StateProvider<bool>((ref) => true);
