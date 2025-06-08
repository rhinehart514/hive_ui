import 'package:flutter/foundation.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/services/user_preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Local data source for profile operations
class ProfileLocalDataSource {
  static const String _userProfileKey = 'user_profile_data';
  final SharedPreferences _preferences;

  ProfileLocalDataSource({SharedPreferences? preferences})
      : _preferences = preferences ?? UserPreferencesService.getPreferences();

  /// Cache a profile to local storage
  Future<bool> cacheProfile(UserProfile profile) async {
    try {
      debugPrint(
          'ProfileLocalDataSource: Caching profile for user ${profile.id}');

      // Convert profile to JSON and then to string
      final profileJson = profile.toJson();
      final profileString = jsonEncode(profileJson);

      // Save to preferences
      return await _preferences.setString(_userProfileKey, profileString);
    } catch (e) {
      debugPrint('ProfileLocalDataSource: Error caching profile: $e');
      return false;
    }
  }

  /// Get a profile from local storage
  Future<UserProfile?> getProfile() async {
    try {
      debugPrint('ProfileLocalDataSource: Retrieving cached profile');

      // Get profile string from preferences
      final profileString = _preferences.getString(_userProfileKey);

      if (profileString == null || profileString.isEmpty) {
        debugPrint('ProfileLocalDataSource: No cached profile found');
        return null;
      }

      // Convert string to JSON then to UserProfile object
      final profileJson = jsonDecode(profileString) as Map<String, dynamic>;
      final profile = UserProfile.fromJson(profileJson);

      debugPrint(
          'ProfileLocalDataSource: Retrieved profile for user: ${profile.username}');
      return profile;
    } catch (e) {
      debugPrint('ProfileLocalDataSource: Error retrieving profile: $e');
      return null;
    }
  }

  /// Clear the cached profile
  Future<bool> clearProfile() async {
    try {
      debugPrint('ProfileLocalDataSource: Clearing cached profile');
      return await _preferences.remove(_userProfileKey);
    } catch (e) {
      debugPrint('ProfileLocalDataSource: Error clearing profile: $e');
      return false;
    }
  }
}
