import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/providers/profile_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:hive_ui/utils/file_path_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

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

/// Provider state for profile media operations
class ProfileMediaNotifier
    extends StateNotifier<AsyncValue<ProfileMediaState>> {
  /// Reference to read other providers
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  ProfileMediaNotifier(this._ref)
      : super(const AsyncValue.data(ProfileMediaState.idle));

  /// Update profile image from camera
  Future<void> updateProfileImageFromCamera() async {
    state = const AsyncValue.loading();

    try {
      final imagePicker = ImagePicker();
      final XFile? pickedFile = await imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (pickedFile != null) {
        debugPrint('📸 Image captured from camera: ${pickedFile.path}');
        await _uploadAndUpdateProfileImage(pickedFile.path);
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
      final imagePicker = ImagePicker();
      final XFile? pickedFile = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (pickedFile != null) {
        debugPrint('🖼️ Image selected from gallery: ${pickedFile.path}');
        await _uploadAndUpdateProfileImage(pickedFile.path);
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

      final currentProfile = _ref.read(profileProvider).value;
      if (currentProfile != null) {
        // Update profile in Firestore with null image URL
        await _firestore.collection('users').doc(currentProfile.id).update({
          'profileImageUrl': null,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update local profile
        final updatedProfile = currentProfile.copyWith(
          profileImageUrl: null,
          updatedAt: DateTime.now(),
        );

        await _ref
            .read(profileProvider.notifier)
            .updateProfile(updatedProfile.toJson());
        state = const AsyncValue.data(ProfileMediaState.success);
        debugPrint('✅ Profile image removed successfully');
      }
    } catch (e, stack) {
      debugPrint('❌ Error removing profile image: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  /// Helper method to upload and update the profile image
  Future<void> _uploadAndUpdateProfileImage(String localImagePath) async {
    // Get the current profile
    final profile = _ref.read(profileProvider).value;
    if (profile == null) {
      throw Exception('Profile not available');
    }

    try {
      // Convert the path to a proper format for the current platform
      final properPath = FilePathHandler.getProperPath(localImagePath);

      // Upload image to Firebase Storage
      final imageFile = File(properPath);
      final storageRef =
          _storage.ref().child('profile_images/${profile.id}.jpg');

      // Upload with metadata
      final uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'userId': profile.id,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Get download URL after upload completes
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Create updated profile with new image URL
      final updatedProfile = profile.copyWith(
        profileImageUrl: downloadUrl,
        updatedAt: DateTime.now(),
      );

      // Update only the specific fields in Firestore
      await _firestore.collection('users').doc(profile.id).update({
        'profileImageUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update profile in provider
      await _ref
          .read(profileProvider.notifier)
          .updateProfile(updatedProfile.toJson());
      debugPrint('✅ Profile image uploaded and updated successfully');
    } catch (e) {
      debugPrint('❌ Error in _uploadAndUpdateProfileImage: $e');
      rethrow;
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
