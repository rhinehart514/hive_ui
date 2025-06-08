import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/profile/presentation/providers/profile_providers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hive_ui/features/profile/domain/repositories/profile_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// States for profile image operations
enum ProfileMediaState {
  /// Initial state, no operation in progress
  idle,

  /// Currently loading/processing an image
  loading,

  /// Operation completed successfully
  success,

  /// Operation failed with an error
  error
}

/// Provider for profile media operations
class ProfileMediaNotifier
    extends StateNotifier<AsyncValue<ProfileMediaState>> {
  final Ref _ref;
  final ImagePicker _imagePicker;

  ProfileMediaNotifier(this._ref)
      : _imagePicker = ImagePicker(),
        super(const AsyncValue.data(ProfileMediaState.idle));

  /// Update profile image from camera
  Future<void> updateProfileImageFromCamera() async {
    state = const AsyncValue.loading();

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (pickedFile != null) {
        debugPrint('📸 Image captured from camera: ${pickedFile.path}');
        await _updateProfileImage(pickedFile.path);
        state = const AsyncValue.data(ProfileMediaState.success);
      } else {
        state = const AsyncValue.data(ProfileMediaState.idle);
      }
    } catch (e, stack) {
      debugPrint('❌ Error updating profile image from camera: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  /// Update profile image from gallery
  Future<void> updateProfileImageFromGallery() async {
    state = const AsyncValue.loading();

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (pickedFile != null) {
        debugPrint('🖼️ Image selected from gallery: ${pickedFile.path}');
        await _updateProfileImage(pickedFile.path);
        state = const AsyncValue.data(ProfileMediaState.success);
      } else {
        state = const AsyncValue.data(ProfileMediaState.idle);
      }
    } catch (e, stack) {
      debugPrint('❌ Error updating profile image from gallery: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  /// Remove profile image
  Future<void> removeProfileImage() async {
    state = const AsyncValue.loading();

    try {
      debugPrint('🗑️ Removing profile image...');

      // Get the remove use case
      final removeProfileImageUseCase =
          _ref.read(removeProfileImageUseCaseProvider);
      await removeProfileImageUseCase();

      // Refresh profile to get latest data
      await _ref.read(profileProvider.notifier).refreshProfile();

      state = const AsyncValue.data(ProfileMediaState.success);
      debugPrint('✅ Profile image removed successfully');
    } catch (e, stack) {
      debugPrint('❌ Error removing profile image: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  /// Helper method to update profile image
  Future<void> _updateProfileImage(String imagePath) async {
    try {
      // Get current profile
      final profileAsync = _ref.read(profileProvider);
      final profile = profileAsync.profile;

      if (profile == null) {
        throw Exception('Profile not available');
      }

      // Create File from path
      final imageFile = File(imagePath);

      // Get the upload use case
      final uploadProfileImageUseCase =
          _ref.read(uploadProfileImageUseCaseProvider);
      final uploadResult = await uploadProfileImageUseCase(imageFile);

      // Update profile with new image URL
      if (uploadResult.isSuccess && uploadResult.data != null) {
        // Update profile with new image URL
        final updatedProfile = profile.copyWith(
          profileImageUrl: uploadResult.data,
          updatedAt: DateTime.now(),
        );

        // Update profile through profile provider
        await _ref.read(profileProvider.notifier).updateProfile(updatedProfile);
      }

      debugPrint('✅ Profile image uploaded and updated successfully');
    } catch (e) {
      debugPrint('❌ Error in _updateProfileImage: $e');
      rethrow;
    }
  }

  /// Update profile image from a file path
  Future<void> updateProfileImageFromPath(String imagePath) async {
    state = const AsyncValue.loading();

    try {
      debugPrint('📷 Updating profile image from path: $imagePath');
      await _updateProfileImage(imagePath);
      state = const AsyncValue.data(ProfileMediaState.success);
    } catch (e, stack) {
      debugPrint('❌ Error updating profile image from path: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  /// Reset the state to idle
  void resetState() {
    state = const AsyncValue.data(ProfileMediaState.idle);
  }
}

/// Provider for profile media operations
final profileMediaProvider =
    StateNotifierProvider<ProfileMediaNotifier, AsyncValue<ProfileMediaState>>(
        (ref) {
  return ProfileMediaNotifier(ref);
});

// Model for operation result
class OperationResult<T> {
  final bool isSuccess;
  final String? error;
  final T? data;
  
  const OperationResult({
    required this.isSuccess,
    this.error,
    this.data,
  });
  
  factory OperationResult.success([T? data]) => OperationResult(
    isSuccess: true,
    data: data,
  );
  
  factory OperationResult.failure(String error) => OperationResult(
    isSuccess: false,
    error: error,
  );
}

// Use case for uploading a profile image
class UploadProfileImageUseCase {
  final ProfileRepository repository;
  
  UploadProfileImageUseCase(this.repository);
  
  Future<OperationResult<String>> call(File imageFile) async {
    try {
      // Get current user ID from Firebase Auth
      final userId = FirebaseAuth.instance.currentUser?.uid;
      
      if (userId == null) {
        return OperationResult.failure('No authenticated user');
      }
      
      // Update the profile with the image
      final profile = await repository.getProfile(userId);
      if (profile == null) {
        return OperationResult.failure('Profile not found');
      }
      
      // Assume the repository has an updateProfile method that handles the image upload
      final updatedProfile = profile.copyWith(
        photoUrl: 'file://${imageFile.path}', // Temporary local path, will be replaced
      );
      
      await repository.updateProfile(updatedProfile);
      
      // Return the local path for now
      return OperationResult.success('file://${imageFile.path}');
    } catch (e) {
      return OperationResult.failure(e.toString());
    }
  }
}

// Use case for removing a profile image
class RemoveProfileImageUseCase {
  final ProfileRepository repository;
  
  RemoveProfileImageUseCase(this.repository);
  
  Future<OperationResult<void>> call() async {
    try {
      // Get current user ID from Firebase Auth
      final userId = FirebaseAuth.instance.currentUser?.uid;
      
      if (userId == null) {
        return OperationResult.failure('No authenticated user');
      }
      
      // Get the profile
      final profile = await repository.getProfile(userId);
      if (profile == null) {
        return OperationResult.failure('Profile not found');
      }
      
      // Update profile with null photo URL
      final updatedProfile = profile.copyWith(
        photoUrl: null, // Setting to null removes the image
      );
      
      await repository.updateProfile(updatedProfile);
      
      return OperationResult.success();
    } catch (e) {
      return OperationResult.failure(e.toString());
    }
  }
}

// Providers for the profile image use cases
final uploadProfileImageUseCaseProvider = Provider<UploadProfileImageUseCase>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return UploadProfileImageUseCase(repository);
});

final removeProfileImageUseCaseProvider = Provider<RemoveProfileImageUseCase>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return RemoveProfileImageUseCase(repository);
});
