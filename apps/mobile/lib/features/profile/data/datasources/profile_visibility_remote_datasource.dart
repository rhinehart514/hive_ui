import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ui/features/profile/data/models/profile_visibility_settings_model.dart';

/// Remote data source for profile visibility settings
class ProfileVisibilityRemoteDataSource {
  /// Firebase instance for database operations
  final FirebaseFirestore _firestore;

  /// Constructor
  ProfileVisibilityRemoteDataSource({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Collection reference for profile visibility settings
  CollectionReference get _visibilityCollection => 
      _firestore.collection('profileVisibilitySettings');

  /// Get visibility settings for a user
  Future<ProfileVisibilitySettingsModel> getVisibilitySettings(String userId) async {
    try {
      final doc = await _visibilityCollection.doc(userId).get();
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        return ProfileVisibilitySettingsModel.fromFirestore({
          ...data,
          'userId': userId,
        });
      }
      
      // Return default settings if not found
      final defaultSettings = ProfileVisibilitySettingsModel(
        userId: userId,
        updatedAt: DateTime.now(),
      );
      
      // Save default settings to Firestore
      await _visibilityCollection.doc(userId).set(defaultSettings.toFirestore());
      
      return defaultSettings;
    } catch (e) {
      throw Exception('Failed to get visibility settings: $e');
    }
  }

  /// Update visibility settings for a user
  Future<void> updateVisibilitySettings(ProfileVisibilitySettingsModel settings) async {
    try {
      await _visibilityCollection.doc(settings.userId).set(
        settings.toFirestore(),
        SetOptions(merge: true),
      );
    } catch (e) {
      throw Exception('Failed to update visibility settings: $e');
    }
  }

  /// Get friend status between two users
  Future<bool> areFriends(String userId1, String userId2) async {
    try {
      // Check in both friendships collections to see if users are connected
      final query1 = await _firestore
          .collection('users')
          .doc(userId1)
          .collection('friends')
          .doc(userId2)
          .get();
          
      return query1.exists;
    } catch (e) {
      throw Exception('Failed to check friend status: $e');
    }
  }
} 