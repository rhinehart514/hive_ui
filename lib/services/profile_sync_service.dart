import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/services/user_preferences_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Exception thrown when profile operations fail
class ProfileSyncException implements Exception {
  final String message;
  final Object? originalError;

  ProfileSyncException(this.message, [this.originalError]);

  @override
  String toString() =>
      'ProfileSyncException: $message${originalError != null ? ' ($originalError)' : ''}';
}

/// Service for syncing user profile between Firestore and local storage
class ProfileSyncService {
  // Constants
  static const String _logPrefix = 'ProfileSyncService:';
  static const String _profileCollection = 'users';
  static const String _profileImagePath = 'profile_images';
  static const int _imageQuality = 85;
  static const int _maxImageDimension = 800;

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Cache for optimistic updates
  UserProfile? _cachedProfile;

  /// Load a user profile from Firestore
  Future<UserProfile?> loadProfileFromFirestore([String? userId]) async {
    try {
      // Get the current user ID from preferences if not provided
      final currentUserId = userId ?? await UserPreferencesService.getUserId();
      if (currentUserId == null || currentUserId.isEmpty) {
        _log('No user ID available for profile lookup');
        return null;
      }

      // Check if Firebase Auth is authenticated
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _log('User not authenticated, cannot load from Firestore');
        return await UserPreferencesService.getStoredProfile();
      }

      // Check if the requested profile matches the authenticated user
      if (currentUser.uid != currentUserId) {
        _log(
            'Current user (${currentUser.uid}) does not match requested profile ($currentUserId)');
        return await UserPreferencesService.getStoredProfile();
      }

      _log('Loading profile for user $currentUserId');

      // Try to get the document
      final docSnapshot = await _firestore
          .collection(_profileCollection)
          .doc(currentUserId)
          .get();

      if (!docSnapshot.exists) {
        _log('No profile found in Firestore for user $currentUserId');
        return null;
      }

      // Create the UserProfile object
      final data = Map<String, dynamic>.from(docSnapshot.data()!);
      data['id'] = currentUserId; // Ensure ID is set

      _cachedProfile = UserProfile.fromJson(data);
      _log('Successfully created UserProfile from Firestore data');

      // Save to local storage as backup
      await UserPreferencesService.storeProfile(_cachedProfile!);

      return _cachedProfile;
    } catch (e) {
      _log('Error loading profile from Firestore: $e');
      return await UserPreferencesService.getStoredProfile();
    }
  }

  /// Upload and optimize a profile image
  Future<String?> uploadProfileImage(File imageFile, String userId) async {
    try {
      _log('Uploading profile image for user $userId');

      // Check if user is authenticated
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _log('User not authenticated, cannot upload to Firebase Storage');
        return null;
      }

      // Verify that we're updating the authenticated user's profile
      if (userId != currentUser.uid) {
        _log('Cannot upload image for another user ($userId)');
        return null;
      }

      // Compress and resize the image
      final optimizedImageFile = await _optimizeImage(imageFile);

      // Upload to Firebase Storage
      final storageRef = _storage.ref().child('$_profileImagePath/$userId.jpg');
      final uploadTask = storageRef.putFile(
        optimizedImageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'userId': userId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Get download URL after upload completes
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Update profile with new image URL
      await _firestore.collection(_profileCollection).doc(userId).update({
        'profileImageUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _log('Image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      _log('Error uploading profile image: $e');
      return null;
    }
  }

  /// Optimize image for upload (resize and compress)
  Future<File> _optimizeImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) throw Exception('Could not decode image');

    // Resize if needed
    var processedImage = image;
    if (image.width > _maxImageDimension || image.height > _maxImageDimension) {
      processedImage = img.copyResize(
        image,
        width: image.width > image.height ? _maxImageDimension : null,
        height: image.height >= image.width ? _maxImageDimension : null,
      );
    }

    // Compress
    final compressedBytes =
        img.encodeJpg(processedImage, quality: _imageQuality);

    // Save to temporary file
    final tempDir = await getTemporaryDirectory();
    final tempFile = File(
        '${tempDir.path}/optimized_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await tempFile.writeAsBytes(compressedBytes);

    return tempFile;
  }

  /// Helper for logging
  void _log(String message) {
    debugPrint('$_logPrefix $message');
  }
}

/// Provider for the profile sync service
final profileSyncServiceProvider = Provider<ProfileSyncService>((ref) {
  return ProfileSyncService();
});
