import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/features/profile/data/datasources/profile_local_datasource.dart';
import 'package:hive_ui/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:hive_ui/features/profile/domain/repositories/profile_repository.dart';
import 'package:hive_ui/models/user_profile.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;
  final ProfileLocalDataSource _localDataSource;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  ProfileRepositoryImpl({
    required ProfileRemoteDataSource remoteDataSource,
    required ProfileLocalDataSource localDataSource,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

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
}
