import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/services/user_preferences_service.dart';

/// Helper class for social authentication operations
class SocialAuthHelper {
  /// Merges social profile data with existing user profile
  /// Creates a new profile if one doesn't exist
  static Future<void> mergeSocialProfileData({
    required User user,
    required Map<String, dynamic> socialData,
    required FirebaseFirestore firestore,
    required Function(User) createUserProfile,
    required Function(User) saveUserProfileLocally,
  }) async {
    try {
      debugPrint('Merging social profile data for user: ${user.uid}');
      
      // Get the Firestore document reference
      final userDocRef = firestore.collection('users').doc(user.uid);
      
      // Check if the user profile exists
      final docSnapshot = await userDocRef.get();
      final bool isNewUser = !docSnapshot.exists;
      
      if (isNewUser) {
        // If the profile doesn't exist, create a new one
        debugPrint('No existing profile found. Creating new profile from social data.');
        await createUserProfile(user);
      }
      
      // Get the document data if it exists
      final Map<String, dynamic>? data = docSnapshot.exists 
          ? docSnapshot.data() as Map<String, dynamic>? 
          : null;
      
      // Prepare data for merging
      final Map<String, dynamic> dataToUpdate = {};
      
      // Handle displayName - only update if current one is empty or default
      final String currentDisplayName = data?['displayName'] ?? '';
      if (currentDisplayName.isEmpty || 
          currentDisplayName == 'New User' || 
          currentDisplayName.startsWith('User ')) {
        dataToUpdate['displayName'] = socialData['displayName'] ?? user.displayName ?? '';
      }
      
      // Only update profile image if current one is empty
      final String currentPhotoUrl = data?['profileImageUrl'] ?? '';
      if (currentPhotoUrl.isEmpty && (socialData['photoUrl'] != null && socialData['photoUrl'] != '')) {
        dataToUpdate['profileImageUrl'] = socialData['photoUrl'];
      }
      
      // Always add the provider to providers list using proper FieldValue syntax
      if (socialData['provider'] != null) {
        final List<String> providerList = [socialData['provider']];
        dataToUpdate['providers'] = FieldValue.arrayUnion(providerList);
      }
      
      // Only add email if the current one is empty
      final String currentEmail = data?['email'] ?? '';
      if (currentEmail.isEmpty && (socialData['email'] != null && socialData['email'] != '')) {
        dataToUpdate['email'] = socialData['email'];
      }
      
      // Update first/last name if provided and empty in profile
      if (socialData.containsKey('firstName') && socialData['firstName'] != null) {
        final String currentFirstName = data?['firstName'] ?? '';
        if (currentFirstName.isEmpty) {
          dataToUpdate['firstName'] = socialData['firstName'];
        }
      }
      
      if (socialData.containsKey('lastName') && socialData['lastName'] != null) {
        final String currentLastName = data?['lastName'] ?? '';
        if (currentLastName.isEmpty) {
          dataToUpdate['lastName'] = socialData['lastName'];
        }
      }
      
      // Update account tier based on email domain for new users
      if (isNewUser && socialData.containsKey('email') && socialData['email'] != null) {
        final accountTier = _parseEmailToAccountTier(socialData['email']).name;
        dataToUpdate['accountTier'] = accountTier;
      }
      
      // Always mark as updated
      dataToUpdate['updatedAt'] = FieldValue.serverTimestamp();
      
      // Update Firestore if we have data to update
      if (dataToUpdate.isNotEmpty) {
        debugPrint('Updating profile with social data: ${dataToUpdate.keys}');
        await userDocRef.set(dataToUpdate, SetOptions(merge: true));
      } else {
        debugPrint('No profile fields need updating from social data');
      }
      
      // Update the local cache if we have data
      await updateLocalProfileCache(user, socialData);
      
    } catch (e) {
      // Log error but don't prevent auth flow
      debugPrint('Error merging social profile data: $e');
      // Try to create/update local profile as fallback
      saveUserProfileLocally(user);
    }
  }
  
  /// Updates the local profile cache with social data
  static Future<void> updateLocalProfileCache(User user, Map<String, dynamic> socialData) async {
    try {
      await UserPreferencesService.initialize();
      
      // Get current profile if it exists
      final currentProfile = await UserPreferencesService.getStoredProfile();
      
      if (currentProfile == null) {
        // No existing profile, create a new one
        final profile = UserProfile(
          id: user.uid,
          username: socialData['displayName'] ?? user.displayName ?? 'User ${user.uid.substring(0, 4)}',
          displayName: socialData['displayName'] ?? user.displayName ?? 'User ${user.uid.substring(0, 4)}',
          profileImageUrl: socialData['photoUrl'] ?? user.photoURL,
          email: socialData['email'] ?? user.email,
          bio: '',
          year: 'Freshman',
          major: 'Undecided',
          residence: 'Off Campus',
          eventCount: 0,
          spaceCount: 0,
          friendCount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          accountTier: _parseEmailToAccountTier(socialData['email'] ?? user.email),
          interests: const [],
        );
        
        await UserPreferencesService.storeProfile(profile);
      } else {
        // Profile exists, update only necessary fields
        final updatedProfile = currentProfile.copyWith(
          displayName: currentProfile.displayName.isEmpty || 
                       currentProfile.displayName == 'New User' || 
                       currentProfile.displayName.startsWith('User ') 
                      ? socialData['displayName'] ?? user.displayName ?? currentProfile.displayName
                      : currentProfile.displayName,
          profileImageUrl: currentProfile.profileImageUrl == null || currentProfile.profileImageUrl!.isEmpty
                           ? socialData['photoUrl'] ?? user.photoURL
                           : currentProfile.profileImageUrl,
          email: currentProfile.email == null || currentProfile.email!.isEmpty 
                 ? socialData['email'] ?? user.email 
                 : currentProfile.email,
          updatedAt: DateTime.now(),
        );
        
        await UserPreferencesService.storeProfile(updatedProfile);
      }
    } catch (e) {
      debugPrint('Error updating local profile cache with social data: $e');
    }
  }
  
  /// Parse email domain to determine account tier
  static AccountTier _parseEmailToAccountTier(String? email) {
    if (email == null) return AccountTier.public;

    final lowercaseEmail = email.toLowerCase();
    // Check for educational emails
    if (lowercaseEmail.endsWith('.edu') ||
        lowercaseEmail.contains('buffalo.edu')) {
      return AccountTier.verified;
    }

    return AccountTier.public;
  }
} 