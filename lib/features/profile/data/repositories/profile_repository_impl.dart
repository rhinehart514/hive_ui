import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_ui/features/profile/data/datasources/profile_local_datasource.dart';
import 'package:hive_ui/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:hive_ui/features/profile/domain/repositories/profile_repository.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/models/space.dart';
import 'package:hive_ui/features/shared/infrastructure/platform_integration_manager.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;
  final ProfileLocalDataSource _localDataSource;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final PlatformIntegrationManager _integrationManager;

  ProfileRepositoryImpl({
    required ProfileRemoteDataSource remoteDataSource,
    required ProfileLocalDataSource localDataSource,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    PlatformIntegrationManager? integrationManager,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _integrationManager = integrationManager ?? PlatformIntegrationManager();

  @override
  Future<UserProfile?> getProfile([String? userId]) async {
    try {
      // Get current user ID if not provided
      final currentUserId = userId ?? _auth.currentUser?.uid;
      if (currentUserId == null) {
        debugPrint('ProfileRepositoryImpl: No authenticated user found');
        return null;
      }

      // Try to get from remote first
      try {
        final profile = await _remoteDataSource.getProfile(currentUserId);

        // Debug interests data from Firestore
        if (kDebugMode && false) { // Set to true only when debugging interests issues
          if (profile != null) {
            debugPrint('ProfileRepositoryImpl: Got profile with interests = ${profile.interests}');
            if (profile.interests != null) {
              debugPrint('ProfileRepositoryImpl: Interests count = ${profile.interests!.length}');
            }
          }
        }

        // Cache profile locally if successful
        if (profile != null) {
          await _localDataSource.cacheProfile(profile);
          return profile;
        }
      } catch (e) {
        debugPrint('ProfileRepositoryImpl: Error fetching remote profile: $e');
        // If remote fetch fails, try to get from local cache
      }

      // Fallback to local cache
      return await _localDataSource.getProfile();
    } catch (e) {
      debugPrint('ProfileRepositoryImpl: Error fetching profile: $e');
      throw Exception('Failed to get profile: $e');
    }
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    try {
      // Check if user is authenticated
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      // Verify that we're updating the authenticated user's profile
      if (profile.id != currentUser.uid) {
        throw Exception('Cannot update another user\'s profile');
      }

      // Update in Firestore
      await _remoteDataSource.updateProfile(profile);

      // Update local cache
      await _localDataSource.cacheProfile(profile);
    } catch (e) {
      debugPrint('ProfileRepositoryImpl: Error updating profile: $e');
      throw Exception('Failed to update profile: $e');
    }
  }

  @override
  Future<String> uploadProfileImage(File imageFile) async {
    try {
      // Check if user is authenticated
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      return await _remoteDataSource.uploadProfileImage(
          imageFile, currentUser.uid);
    } catch (e) {
      debugPrint('ProfileRepositoryImpl: Error uploading profile image: $e');
      throw Exception('Failed to upload profile image: $e');
    }
  }

  @override
  Stream<UserProfile?> watchProfile(String userId) {
    return _remoteDataSource.watchProfile(userId);
  }

  @override
  Future<void> createProfile(UserProfile profile) async {
    try {
      // Check if user is authenticated
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      // Create profile with the current user's ID
      final updatedProfile = profile.copyWith(
        id: currentUser.uid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Create in Firestore
      await _remoteDataSource.createProfile(updatedProfile);

      // Cache locally
      await _localDataSource.cacheProfile(updatedProfile);
    } catch (e) {
      debugPrint('ProfileRepositoryImpl: Error creating profile: $e');
      throw Exception('Failed to create profile: $e');
    }
  }

  @override
  Future<void> removeProfileImage() async {
    try {
      // Check if user is authenticated
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      // Get current profile
      final profile = await getProfile();
      if (profile == null) {
        throw Exception('Profile not found');
      }

      // Update profile with null image URL
      await _firestore.collection('users').doc(currentUser.uid).update({
        'profileImageUrl': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local cache
      await _localDataSource.cacheProfile(profile.copyWith(
        profileImageUrl: null,
        updatedAt: DateTime.now(),
      ));
    } catch (e) {
      debugPrint('ProfileRepositoryImpl: Error removing profile image: $e');
      throw Exception('Failed to remove profile image: $e');
    }
  }

  @override
  Future<void> updateUserInterests(String userId, List<String> interests) async {
    try {
      // Validate inputs
      if (userId.isEmpty) {
        throw Exception('User ID cannot be empty');
      }
      
      // Use a Firestore transaction for atomic update
      await _firestore.runTransaction((transaction) async {
        // Reference to the user document
        final userRef = _firestore.collection('users').doc(userId);
        
        // Get the current document
        final snapshot = await transaction.get(userRef);
        
        if (!snapshot.exists) {
          throw Exception('User document not found');
        }
        
        // Update the document with new interests
        transaction.update(userRef, {
          'interests': interests,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      
      // Update local cache if this is the current user
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.uid == userId) {
        final profile = await _localDataSource.getProfile();
        if (profile != null) {
          await _localDataSource.cacheProfile(
            profile.copyWith(
              interests: interests,
              updatedAt: DateTime.now(),
            ),
          );
        }
      }
      
      debugPrint('ProfileRepositoryImpl: Successfully updated interests for user $userId');
    } catch (e) {
      debugPrint('ProfileRepositoryImpl: Error updating user interests: $e');
      throw Exception('Failed to update user interests: $e');
    }
  }

  /// Get saved events for a user
  ///
  /// This method uses the platform integration manager to ensure consistency
  /// with how events are stored and retrieved across the platform
  Future<List<Event>> getSavedEvents(String userId) async {
    try {
      return await _integrationManager.getSavedEventsForUser(userId);
    } catch (e) {
      debugPrint('ProfileRepositoryImpl: Error getting saved events: $e');
      return [];
    }
  }

  /// Get spaces joined by a user
  ///
  /// This method uses the platform integration manager to ensure consistency
  /// with how spaces are stored and retrieved across the platform
  Future<List<Space>> getJoinedSpaces(String userId) async {
    try {
      return await _integrationManager.getSpacesForUser(userId);
    } catch (e) {
      debugPrint('ProfileRepositoryImpl: Error getting joined spaces: $e');
      return [];
    }
  }
}
