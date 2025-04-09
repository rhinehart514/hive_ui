import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/services/user_preferences_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Exception thrown when profile operations fail
class ProfileSyncException implements Exception {
  final String message;
  final Object? originalError;

  ProfileSyncException(this.message, [this.originalError]);

  @override
  String toString() =>
      'ProfileSyncException: $message${originalError != null ? ' ($originalError)' : ''}';
}

/// Provider for ProfileSyncService
final profileSyncServiceProvider = Provider<ProfileSyncService>((ref) {
  final service = ProfileSyncService(
    firestore: FirebaseFirestore.instance,
    storage: FirebaseStorage.instance,
  );

  // Configure persistence on initialization
  service.configurePersistence();

  return service;
});

/// Service for syncing user profile between Firestore and local storage
class ProfileSyncService {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  ProfileSyncService({
    required this.firestore,
    required this.storage,
  });

  // Constants
  static const String _logPrefix = 'ProfileSyncService:';
  static const String _profileCollection = 'users';
  static const String _profileImagePath = 'profile_images';
  static const Duration _authStatePropagationDelay =
      Duration(milliseconds: 300);
  static const int _imageQuality = 85;
  static const int _maxImageDimension = 800;

  // Cache for optimistic updates
  UserProfile? _cachedProfile;

  // Cache for profile data with timestamp
  final Map<String, _CachedProfile> _profileCache = {};

  // Cache duration - 2 minutes
  static const Duration _cacheDuration = Duration(minutes: 2);

  /// Configure Firebase Auth persistence to ensure users stay logged in
  /// across app restarts on mobile platforms
  Future<void> configurePersistence() async {
    try {
      _log('Configuring Firebase Auth persistence');

      // For Flutter applications, Firebase Auth SDK doesn't expose setPersistence directly
      // as it does in web. On mobile platforms, Firebase Auth uses LOCAL persistence by default.
      // We'll make sure to initialize Firebase properly and log any issues

      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;

      // Log current authentication state
      if (currentUser != null) {
        _log('User is already authenticated (uid: ${currentUser.uid})');
        _log('Email verification status: ${currentUser.emailVerified}');

        // Check if tokens refresh properly - this helps ensure persistence is working
        try {
          final idTokenResult = await currentUser.getIdTokenResult(true);
          if (idTokenResult.expirationTime != null) {
            final expirationTimestamp =
                idTokenResult.expirationTime!.millisecondsSinceEpoch;
            final now = DateTime.now().millisecondsSinceEpoch;
            final validFor =
                (expirationTimestamp - now) ~/ 1000 ~/ 60; // minutes

            _log(
                'Auth token refreshed successfully (valid for ~$validFor minutes)');
          } else {
            _log('Token expiration time is null');
          }
        } catch (e) {
          _log('Token refresh check failed: $e');
        }
      } else {
        _log('No user currently authenticated');
      }

      // Note: Firebase Auth on mobile platforms (iOS and Android) uses LOCAL persistence by default
      // which means users stay logged in across app restarts automatically

      // Store a flag in shared preferences to confirm configuration was attempted
      await _storePersistenceConfigured();

      _log(
          'Firebase Auth persistence checked - using default LOCAL persistence');
    } catch (e) {
      _log('Error checking persistence: $e');
    }
  }

  /// Store persistence configuration status in shared preferences
  Future<void> _storePersistenceConfigured() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auth_persistence_configured', true);
    } catch (e) {
      _log('Error storing persistence configuration status: $e');
    }
  }

  /// Load a user profile from Firestore
  /// Returns null if profile doesn't exist or there's an error
  Future<UserProfile?> loadProfileFromFirestore(String userId) async {
    try {
      final doc = await firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        // Create a default profile if none exists
        final defaultProfile = UserProfile(
          id: userId,
          username: 'New User',
          displayName: 'New User',
          year: 'Freshman',
          major: 'Undecided',
          residence: 'Off Campus',
          eventCount: 0,
          spaceCount: 0,
          friendCount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          interests: const [],
        );

        await firestore
            .collection('users')
            .doc(userId)
            .set(defaultProfile.toFirestore());

        return defaultProfile;
      }

      return UserProfile.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error loading profile from Firestore: $e');
      return null;
    }
  }

  /// Create a repair profile when the normal profile creation fails
  UserProfile _createRepairProfile(String userId, Map<String, dynamic> data) {
    // Get the space count value, with fallback to clubCount for compatibility
    int spaceCount = 0;
    if (data.containsKey('spaceCount')) {
      spaceCount = data['spaceCount'] as int? ?? 0;
    } else if (data.containsKey('clubCount')) {
      spaceCount = data['clubCount'] as int? ?? 0;
    }

    return UserProfile(
      id: userId,
      username: data['username'] as String? ?? 'User',
      displayName: data['displayName'] as String? ?? 'User',
      year: data['year'] as String? ?? 'Freshman',
      major: data['major'] as String? ?? 'Undecided',
      residence: data['residence'] as String? ?? 'Off Campus',
      eventCount: data['eventCount'] as int? ?? 0,
      spaceCount: spaceCount,
      friendCount: data['friendCount'] as int? ?? 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      interests: data['interests'] != null 
          ? List<String>.from(data['interests']) 
          : const [],
    );
  }

  /// Get local profile as fallback
  Future<UserProfile?> _getLocalProfileFallback() async {
    final profile = await UserPreferencesService.getStoredProfile();
    if (profile != null) {
      _log('Using locally stored profile as fallback');
    }
    return profile;
  }

  /// Helper to check if the user is authenticated
  bool _isAuthenticated() {
    try {
      final auth = FirebaseAuth.instance;
      return auth.currentUser != null;
    } catch (e) {
      _log('Error checking authentication: $e');
      return false;
    }
  }

  /// Sync a profile to Firestore and local storage
  /// Returns true if the operation was successful
  Future<bool> syncProfileToFirestore(UserProfile profile) async {
    try {
      _log('Syncing profile to Firestore for user ${profile.id}');

      // Store the user ID in preferences for future use
      await UserPreferencesService.setUserId(profile.id);

      // Create an updated profile with current timestamp
      final updatedProfile = profile.copyWith(
        updatedAt: DateTime.now(),
      );

      // Update cache immediately for optimistic updates
      _cachedProfile = updatedProfile;

      // Check if user is authenticated before trying to write to Firestore
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _log('User not authenticated, cannot write to Firestore');
        // Still save to local storage
        await UserPreferencesService.storeProfile(updatedProfile);
        return false;
      }

      // Verify that the profile matches the authenticated user
      if (profile.id != currentUser.uid) {
        _log(
            'Profile ID (${profile.id}) does not match authenticated user (${currentUser.uid})');
        await UserPreferencesService.storeProfile(updatedProfile);
        return false;
      }

      // Save profile to Firestore
      await firestore
          .collection(_profileCollection)
          .doc(profile.id)
          .set(updatedProfile.toJson(), SetOptions(merge: true));

      // Save profile to local storage as backup
      await UserPreferencesService.storeProfile(updatedProfile);

      _log('Profile synced successfully');
      return true;
    } catch (e) {
      _log('Error syncing profile to Firestore: $e');

      // Try to save to local storage at least
      try {
        await UserPreferencesService.storeProfile(profile);
        _log('Profile saved to local storage as fallback');
      } catch (localError) {
        _log('Even local storage failed: $localError');
      }

      return false;
    }
  }

  /// Batch update multiple profile fields at once to reduce Firestore write operations
  Future<bool> batchUpdateProfile(
      String userId, Map<String, dynamic> fields) async {
    try {
      _log('Batch updating profile for user $userId');

      // Check if user is authenticated before trying to write to Firestore
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _log('User not authenticated, cannot write to Firestore');
        return await _updateLocalProfileOnly(userId, fields);
      }

      // Verify that we're updating the authenticated user's profile
      if (userId != currentUser.uid) {
        _log('Cannot update profile for another user ($userId)');
        return false;
      }

      // Add updated timestamp
      fields['updatedAt'] = FieldValue.serverTimestamp();

      // Update in Firestore
      await firestore.collection(_profileCollection).doc(userId).update(fields);

      // Update in local storage and cache
      await _updateLocalAndCachedProfile(userId, fields);

      _log('Profile batch updated successfully');
      return true;
    } catch (e) {
      _log('Error in batch update: $e');
      return false;
    }
  }

  /// Updates only the local profile when Firestore is not available
  Future<bool> _updateLocalProfileOnly(
      String userId, Map<String, dynamic> fields) async {
    try {
      // Update cached profile for optimistic UI updates
      if (_cachedProfile != null && _cachedProfile!.id == userId) {
        _cachedProfile =
            _updateCachedProfileWithFields(_cachedProfile!, fields);
      }

      // Update local storage
      final storedProfile = await UserPreferencesService.getStoredProfile();
      if (storedProfile != null && storedProfile.id == userId) {
        final updatedProfile =
            _updateCachedProfileWithFields(storedProfile, fields);
        await UserPreferencesService.storeProfile(updatedProfile);
        _log('Profile updated in local storage only');
        return true;
      }

      return false;
    } catch (e) {
      _log('Error updating local profile: $e');
      return false;
    }
  }

  /// Updates both local storage and cached profile
  Future<void> _updateLocalAndCachedProfile(
      String userId, Map<String, dynamic> fields) async {
    // Update the cached profile for optimistic rendering
    if (_cachedProfile != null && _cachedProfile!.id == userId) {
      _cachedProfile = _updateCachedProfileWithFields(_cachedProfile!, fields);
    }

    // Also update in local storage
    final storedProfile = await UserPreferencesService.getStoredProfile();
    if (storedProfile != null && storedProfile.id == userId) {
      final updatedProfile =
          _updateCachedProfileWithFields(storedProfile, fields);
      await UserPreferencesService.storeProfile(updatedProfile);
    }
  }

  /// Helper to update cached profile with fields
  UserProfile _updateCachedProfileWithFields(
      UserProfile profile, Map<String, dynamic> fields) {
    // Parse potential DateTime fields
    DateTime? parseDate(dynamic dateValue) {
      if (dateValue == null) return null;

      if (dateValue is DateTime) {
        return dateValue;
      }

      // Handle Firestore Timestamp
      if (dateValue.runtimeType.toString().contains('Timestamp')) {
        try {
          final seconds = dateValue.seconds as int? ?? 0;
          final nanoseconds = dateValue.nanoseconds as int? ?? 0;
          return DateTime.fromMicrosecondsSinceEpoch(
            seconds * 1000000 + (nanoseconds ~/ 1000),
          );
        } catch (e) {
          debugPrint('Error parsing Timestamp: $e');
          return null;
        }
      }

      return null;
    }

    return profile.copyWith(
      username: fields['username'] ?? profile.username,
      profileImageUrl: fields['profileImageUrl'] ?? profile.profileImageUrl,
      bio: fields['bio'] ?? profile.bio,
      year: fields['year'] ?? profile.year,
      major: fields['major'] ?? profile.major,
      residence: fields['residence'] ?? profile.residence,
      interests: fields['interests'] != null
          ? List<String>.from(fields['interests'])
          : profile.interests,
      eventCount: fields['eventCount'] ?? profile.eventCount,
      spaceCount: fields['spaceCount'] ?? profile.spaceCount,
      friendCount: fields['friendCount'] ?? profile.friendCount,
      clubAffiliation: fields['clubAffiliation'] ?? profile.clubAffiliation,
      clubRole: fields['clubRole'] ?? profile.clubRole,
      accountTier: fields['accountTier'] != null
          ? AccountTier.values.firstWhere(
              (tier) => tier.name == fields['accountTier'],
              orElse: () => profile.accountTier,
            )
          : profile.accountTier,
      updatedAt: parseDate(fields['updatedAt']) ?? DateTime.now(),
    );
  }

  /// Upload and optimize a profile image
  Future<String?> uploadProfileImage(File imageFile, String userId) async {
    try {
      _log('Uploading profile image for user $userId');

      // Check if user is authenticated before trying to upload to Firebase Storage
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
      final storageRef = storage.ref().child('$_profileImagePath/$userId.jpg');
      final uploadTask = storageRef.putFile(
        optimizedImageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Get download URL after upload completes
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Update profile with new image URL
      await batchUpdateProfile(userId, {'profileImageUrl': downloadUrl});

      _log('Image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      _log('Error uploading profile image: $e');
      return null;
    }
  }

  /// Optimize image for upload (resize and compress)
  Future<File> _optimizeImage(File imageFile) async {
    // Read the image
    final bytes = await imageFile.readAsBytes();
    var decodedImage = img.decodeImage(bytes);

    if (decodedImage == null) {
      throw ProfileSyncException('Could not decode image');
    }

    // Resize if too large (max 800px on largest dimension)
    if (decodedImage.width > _maxImageDimension ||
        decodedImage.height > _maxImageDimension) {
      final resizeWidth =
          decodedImage.width > decodedImage.height ? _maxImageDimension : null;
      final resizeHeight =
          decodedImage.height >= decodedImage.width ? _maxImageDimension : null;
      decodedImage = img.copyResize(
        decodedImage,
        width: resizeWidth,
        height: resizeHeight,
      );
    }

    // Encode as JPEG with quality setting
    final optimizedBytes = img.encodeJpg(decodedImage, quality: _imageQuality);

    // Save to temporary file
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/optimized_profile_image.jpg');
    await tempFile.writeAsBytes(optimizedBytes);

    return tempFile;
  }

  /// Updates specific fields of a user profile
  Future<bool> updateProfileFields(
      String userId, Map<String, dynamic> fields) async {
    try {
      _log('Updating profile fields for user $userId');

      // Check if user is authenticated
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _log('User not authenticated, cannot update profile');
        return false;
      }

      // Verify we're updating the authenticated user's profile
      if (userId != currentUser.uid) {
        _log('Cannot update profile for another user ($userId)');
        return false;
      }

      // Add updated timestamp
      fields['updatedAt'] = FieldValue.serverTimestamp();

      // Update in Firestore
      await firestore.collection(_profileCollection).doc(userId).update(fields);

      // Also update in local storage (need to get full profile first)
      final storedProfile = await UserPreferencesService.getStoredProfile();
      if (storedProfile != null && storedProfile.id == userId) {
        final updatedProfile =
            _updateCachedProfileWithFields(storedProfile, fields);
        await UserPreferencesService.storeProfile(updatedProfile);
      }

      _log('Profile fields updated successfully');
      return true;
    } catch (e) {
      _log('Error updating profile fields: $e');
      return false;
    }
  }

  /// Delete a user profile from Firestore
  Future<bool> deleteProfile(String userId) async {
    try {
      _log('Deleting profile for user $userId');

      // Check if user is authenticated
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _log('User not authenticated, cannot delete profile');
        return false;
      }

      // Only admins can delete profiles according to security rules
      // For now, just prevent deleting other users' profiles
      if (userId != currentUser.uid) {
        _log('Cannot delete another user\'s profile ($userId)');
        return false;
      }

      await firestore.collection(_profileCollection).doc(userId).delete();

      // Also clear from local storage
      await UserPreferencesService.clearProfile();

      // Clear the cache
      _cachedProfile = null;

      _log('Profile deleted successfully');
      return true;
    } catch (e) {
      _log('Error deleting profile: $e');
      return false;
    }
  }

  /// Invalidate the cache to force refresh from Firestore next time
  void invalidateCache() {
    _cachedProfile = null;
  }

  /// Refresh the profile from Firestore with caching and monitoring
  Future<UserProfile?> refreshProfile(String userId,
      {bool forceFresh = false}) async {
    try {
      final operationName = 'refreshProfile_$userId';

      // Check cache first
      if (!forceFresh) {
        final cachedProfile = _getCachedProfile(userId);
        if (cachedProfile != null && !cachedProfile.isStale) {
          _log(
              'Using cached profile for user $userId (age: ${DateTime.now().difference(cachedProfile.cachedAt).inSeconds}s)');
          return cachedProfile.profile;
        }
      }

      _log(
          'Loading fresh profile for user $userId from collection $_profileCollection');

      // Try to get the document
      final documentSnapshot =
          await firestore.collection(_profileCollection).doc(userId).get();

      if (!documentSnapshot.exists) {
        _log('No profile found in Firestore for user $userId');
        return null;
      }

      // Add the id field if it doesn't exist
      final data = Map<String, dynamic>.from(documentSnapshot.data()!);
      if (!data.containsKey('id') || data['id'] == null) {
        data['id'] = userId;
      }

      // Create the UserProfile object
      try {
        final refreshedProfile = UserProfile.fromJson(data);
        _log(
            'Successfully refreshed UserProfile from Firestore (id: ${refreshedProfile.id})');

        // Cache the profile
        _updateProfileCache(userId, refreshedProfile);

        // Save to local storage as backup
        await UserPreferencesService.storeProfile(refreshedProfile);

        return refreshedProfile;
      } catch (e) {
        _log('Error creating UserProfile from Firestore data: $e');
        return null;
      }
    } catch (e) {
      _log('Error refreshing profile: $e');
      return null;
    }
  }

  /// Update the profile cache
  void _updateProfileCache(String userId, UserProfile profile) {
    _profileCache[userId] = _CachedProfile(
      profile: profile,
      cachedAt: DateTime.now(),
    );

    // Also update the global cached profile
    _cachedProfile = profile;
  }

  /// Get a cached profile if available
  _CachedProfile? _getCachedProfile(String userId) {
    return _profileCache[userId];
  }

  /// Helper for logging
  void _log(String message) {
    debugPrint('$_logPrefix $message');
  }

  /// Ensure the app remembers logged-in users between sessions
  Future<bool> ensureUserPersistence() async {
    try {
      _log('Checking user persistence');

      // Firebase Auth on mobile platforms already uses LOCAL persistence by default
      // But we'll also ensure the user ID is stored in local preferences as backup
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        _log('Current user found: ${currentUser.uid}');

        // Store the user ID in preferences for extra persistence
        await UserPreferencesService.setUserId(currentUser.uid);

        // Check for preferences to determine if user has completed required setup
        final prefs = await SharedPreferences.getInstance();
        final onboardingCompleted =
            prefs.getBool('onboarding_completed') ?? false;
        _log(
            'Onboarding status: ${onboardingCompleted ? 'completed' : 'not completed'}');

        // If we have a profile locally, also ensure it's updated with the latest Firebase data
        final localProfile = await UserPreferencesService.getStoredProfile();
        if (localProfile == null || localProfile.id != currentUser.uid) {
          _log('Local profile missing or mismatch - refreshing from Firestore');
          await refreshProfile(currentUser.uid, forceFresh: false);
        }

        return true;
      } else {
        _log('No currently authenticated user');
        return false;
      }
    } catch (e) {
      _log('Error ensuring user persistence: $e');
      return false;
    }
  }
}

/// Data class for cached profiles
class _CachedProfile {
  final UserProfile profile;
  final DateTime cachedAt;

  _CachedProfile({required this.profile, required this.cachedAt});

  bool get isStale =>
      DateTime.now().difference(cachedAt) > const Duration(minutes: 5);
}
