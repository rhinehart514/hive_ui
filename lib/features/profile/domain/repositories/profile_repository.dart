import 'dart:io';
import 'package:hive_ui/models/user_profile.dart';

/// Repository for accessing and managing user profiles
abstract class ProfileRepository {
  /// Get a user profile by ID (or current user if ID is not provided)
  Future<UserProfile?> getProfile([String? userId]);

  /// Update a user profile
  Future<void> updateProfile(UserProfile profile);

  /// Create a new user profile
  Future<void> createProfile(UserProfile profile);

  /// Upload a profile image and return the URL
  Future<String> uploadProfileImage(File imageFile);

  /// Remove the profile image
  Future<void> removeProfileImage();

  /// Stream to watch profile updates in real-time
  Stream<UserProfile?> watchProfile(String userId);
}
