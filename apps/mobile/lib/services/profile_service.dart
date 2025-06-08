import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';

/// Service for managing user profiles
class ProfileService {
  static const String _logPrefix = '[ProfileService]';
  
  /// Cache of user profiles (userId -> UserProfile)
  static final Map<String, UserProfile> _profileCache = {};
  
  /// Get a user profile by user ID
  static Future<UserProfile?> getProfile(String userId) async {
    try {
      // Check cache first
      if (_profileCache.containsKey(userId)) {
        return _profileCache[userId];
      }
      
      // Get from Firestore
      final firestore = FirebaseFirestore.instance;
      final userDoc = await firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        debugPrint('$_logPrefix User $userId not found');
        return null;
      }
      
      // Create user profile
      final userProfile = UserProfile.fromJson({'id': userId, ...userDoc.data()!});
      
      // Cache for future use
      _profileCache[userId] = userProfile;
      
      return userProfile;
    } catch (e) {
      debugPrint('$_logPrefix Error getting profile for user $userId: $e');
      return null;
    }
  }
  
  /// Clear the profile cache for a specific user
  static void clearProfileCache(String userId) {
    _profileCache.remove(userId);
  }
  
  /// Clear the entire profile cache
  static void clearAllProfileCache() {
    _profileCache.clear();
  }
  
  /// Update a user profile
  static Future<bool> updateProfile(UserProfile profile) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final userRef = firestore.collection('users').doc(profile.id);
      
      await userRef.update(profile.toJson()..remove('id'));
      
      // Update cache
      _profileCache[profile.id] = profile;
      
      return true;
    } catch (e) {
      debugPrint('$_logPrefix Error updating profile: $e');
      return false;
    }
  }
} 