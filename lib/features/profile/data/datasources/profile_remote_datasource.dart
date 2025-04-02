import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/utils/file_path_handler.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Remote data source for profile operations
class ProfileRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  static const String _usersCollection = 'users';
  static const int _imageQuality = 85;
  static const int _maxImageDimension = 800;

  ProfileRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  /// Get a profile from Firestore
  Future<UserProfile?> getProfile(String userId) async {
    try {
      final docSnapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get(const GetOptions(source: Source.server));

      if (!docSnapshot.exists) {
        debugPrint(
            'ProfileRemoteDataSource: No profile found for user $userId');
        return null;
      }

      final dynamic rawData = docSnapshot.data();
      
      // Check if we received a valid map
      if (rawData == null) {
        debugPrint('ProfileRemoteDataSource: Null data received for user $userId');
        return null;
      }
      
      if (rawData is! Map<String, dynamic>) {
        debugPrint('ProfileRemoteDataSource: Invalid data type received for user $userId. Expected Map<String, dynamic> but got ${rawData.runtimeType}');
        // Try to recover by creating a minimal profile
        return UserProfile(
          id: userId,
          username: 'user_$userId',
          displayName: 'User',
          year: '',
          major: '',
          residence: '',
          eventCount: 0,
          clubCount: 0,
          friendCount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      
      final data = rawData as Map<String, dynamic>;
      data['id'] = docSnapshot.id; // Ensure ID is set
      return UserProfile.fromJson(data);
    } catch (e) {
      debugPrint('ProfileRemoteDataSource: Error getting profile: $e');
      throw Exception('Failed to get profile: $e');
    }
  }

  /// Update a profile in Firestore
  Future<void> updateProfile(UserProfile profile) async {
    try {
      // Handle profile image update if present
      if (profile.tempProfileImageFile != null) {
        final imageUrl =
            await uploadProfileImage(profile.tempProfileImageFile!, profile.id);

        // Create updated profile with new image URL
        profile = profile.copyWith(
          profileImageUrl: imageUrl,
          tempProfileImageFile: null,
        );
      }

      // Convert to Firestore-compatible data
      final Map<String, dynamic> profileData = profile.toFirestore();

      // Update in Firestore
      await _firestore
          .collection(_usersCollection)
          .doc(profile.id)
          .update(profileData);
    } catch (e) {
      debugPrint('ProfileRemoteDataSource: Error updating profile: $e');
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Create a new profile in Firestore
  Future<void> createProfile(UserProfile profile) async {
    try {
      // Handle profile image upload if present
      String? profileImageUrl = profile.profileImageUrl;
      if (profile.tempProfileImageFile != null) {
        profileImageUrl =
            await uploadProfileImage(profile.tempProfileImageFile!, profile.id);
      }

      // Create updated profile with new image URL and without the temp file
      final updatedProfile = profile.copyWith(
        profileImageUrl: profileImageUrl,
        tempProfileImageFile: null,
      );

      // Convert to Firestore-compatible data
      final Map<String, dynamic> profileData = updatedProfile.toFirestore();

      // Create in Firestore
      await _firestore
          .collection(_usersCollection)
          .doc(profile.id)
          .set(profileData);
    } catch (e) {
      debugPrint('ProfileRemoteDataSource: Error creating profile: $e');
      throw Exception('Failed to create profile: $e');
    }
  }

  /// Upload a profile image to Firebase Storage
  Future<String> uploadProfileImage(File imageFile, String userId) async {
    try {
      // Optimize image before upload
      final optimizedImageFile = await _optimizeImage(imageFile);

      // Create a unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = optimizedImageFile.path.split('.').last;
      final storageRef = _storage
          .ref()
          .child('profile_images/$userId/profile_$timestamp.$ext');

      // Upload with metadata
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

      return downloadUrl;
    } catch (e) {
      debugPrint('ProfileRemoteDataSource: Error uploading profile image: $e');
      throw Exception('Failed to upload profile image: $e');
    }
  }

  /// Stream to watch profile updates in real-time
  Stream<UserProfile?> watchProfile(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;

      try {
        final dynamic rawData = snapshot.data();
        
        // Check if we received valid data
        if (rawData == null) {
          debugPrint('ProfileRemoteDataSource: Null data received in stream for user $userId');
          return null;
        }
        
        if (rawData is! Map<String, dynamic>) {
          debugPrint('ProfileRemoteDataSource: Invalid data type received in stream for user $userId. Expected Map<String, dynamic> but got ${rawData.runtimeType}');
          // Try to recover by creating a minimal profile
          return UserProfile(
            id: userId,
            username: 'user_$userId',
            displayName: 'User',
            year: '',
            major: '',
            residence: '',
            eventCount: 0,
            clubCount: 0,
            friendCount: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }
        
        final data = rawData as Map<String, dynamic>;
        data['id'] = snapshot.id;
        return UserProfile.fromJson(data);
      } catch (e) {
        debugPrint('ProfileRemoteDataSource: Error processing profile stream data: $e');
        return null;
      }
    });
  }

  /// Optimize image for upload (resize and compress)
  Future<File> _optimizeImage(File imageFile) async {
    try {
      // Convert path to proper format for the current platform
      final properPath = FilePathHandler.getProperPath(imageFile.path);
      final bytes = await File(properPath).readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) throw Exception('Could not decode image');

      // Resize if needed
      var processedImage = image;
      if (image.width > _maxImageDimension ||
          image.height > _maxImageDimension) {
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
    } catch (e) {
      debugPrint('ProfileRemoteDataSource: Error optimizing image: $e');
      throw Exception('Failed to optimize image: $e');
    }
  }
}
