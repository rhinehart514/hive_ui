import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:hive_ui/models/user_profile.dart';

/// Service for managing user preferences and app state
class UserPreferencesService {
  static const String _hasCompletedOnboardingKey = 'has_completed_onboarding';
  static const String _userProfileKey = 'user_profile_data';
  static const String _userEmailKey = 'user_email';
  static const String _userIdKey = 'user_id';
  static const String _onboardingDataKey = 'onboarding_data';

  static SharedPreferences? _preferences;

  /// Initialize the preferences service
  static Future<void> initialize() async {
    if (_preferences != null) {
      debugPrint('UserPreferencesService: Already initialized');
      return;
    }

    try {
      debugPrint('UserPreferencesService: Initializing...');
      _preferences = await SharedPreferences.getInstance();
      debugPrint('UserPreferencesService: Initialized successfully');

      // Create a default profile if none exists
      final hasProfile = _preferences!.containsKey(_userProfileKey);
      debugPrint('UserPreferencesService: Has stored profile: $hasProfile');

      if (!hasProfile) {
        debugPrint('UserPreferencesService: Creating default profile');
        // Create a default profile
        final defaultProfile = UserProfile(
          id: DateTime.now().toString(),
          username: 'New User',
          displayName: 'New User',
          year: 'Freshman',
          major: 'Undecided',
          residence: 'Off Campus',
          eventCount: 0,
          clubCount: 0,
          friendCount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          accountTier: AccountTier.public,
        );

        // Store the default profile
        await storeProfile(defaultProfile);
      }

      // Perform a quick verification that preferences are working correctly
      const testKey = 'preference_test_key';
      await _preferences!.setString(testKey, 'test_value');
      final verificationValue = _preferences!.getString(testKey);

      if (verificationValue != 'test_value') {
        debugPrint(
            'WARNING: Preference verification failed! Expected "test_value" but got "$verificationValue"');
        throw Exception(
            'Preferences verification failed - values not being stored correctly');
      }

      await _preferences!.remove(testKey);
      debugPrint(
          'UserPreferencesService: Verified preferences are working correctly');
    } catch (e) {
      debugPrint('UserPreferencesService: Error initializing: $e');

      // Fallback to shared preferences mock for emergency situations
      try {
        SharedPreferences.setMockInitialValues({});
        _preferences = await SharedPreferences.getInstance();
        debugPrint(
            'UserPreferencesService: Using mock preferences after error');
      } catch (mockError) {
        debugPrint(
            'UserPreferencesService: Even mock preferences failed: $mockError');
        _preferences = null;
      }
    }
  }

  /// Check if user has completed onboarding with error handling
  static bool hasCompletedOnboarding() {
    try {
      _ensureInitialized();

      // First try to get the explicit onboarding flag
      final hasCompleted =
          _preferences?.getBool(_hasCompletedOnboardingKey) ?? false;

      // If the flag indicates onboarding is completed, just return true
      if (hasCompleted) {
        return true;
      }

      // If the explicit flag is false, check if there's other evidence the user might have completed onboarding

      // 1. Check if user has email saved - existing users with email should be considered onboarded
      final savedEmail = getUserEmail();
      if (savedEmail.isNotEmpty) {
        debugPrint(
            'User has email ($savedEmail) but no onboarding flag. Treating as potentially onboarded user.');

        // 2. Check if there's a stored profile which indicates they've likely done onboarding
        final hasStoredProfile =
            _preferences?.containsKey(_userProfileKey) ?? false;
        if (hasStoredProfile) {
          debugPrint(
              'User has a stored profile. Auto-correcting onboarding status to completed.');

          // Fix the inconsistency by setting the flag
          _preferences?.setBool(_hasCompletedOnboardingKey, true);
          return true;
        }
      }

      return hasCompleted;
    } catch (e) {
      debugPrint('Error checking onboarding status: $e');
      // Default to false if there's an error
      return false;
    }
  }

  /// Mark onboarding as completed with robust error handling
  static Future<bool> setOnboardingCompleted(bool completed) async {
    try {
      _ensureInitialized();

      // Try to set the value
      final result =
          await _preferences?.setBool(_hasCompletedOnboardingKey, completed) ??
              false;

      // Verify it was actually set
      final verifyValue =
          _preferences?.getBool(_hasCompletedOnboardingKey) ?? false;

      if (verifyValue != completed) {
        debugPrint(
            'Warning: Failed to verify onboarding completed flag was set');

        // Try one more time
        await _preferences?.setBool(_hasCompletedOnboardingKey, completed);

        // Final verification
        final finalCheck =
            _preferences?.getBool(_hasCompletedOnboardingKey) ?? false;
        debugPrint('Final onboarding completion state: $finalCheck');

        return finalCheck == completed;
      }

      debugPrint('Onboarding completion successfully saved: $verifyValue');
      return result;
    } catch (e) {
      debugPrint('Error setting onboarding completed: $e');
      return false;
    }
  }

  /// Reset onboarding status (for testing or account reset)
  static Future<bool> resetOnboardingStatus() async {
    _ensureInitialized();
    return await _preferences?.setBool(_hasCompletedOnboardingKey, false) ??
        false;
  }

  /// Store user profile data
  static Future<bool> storeProfile(UserProfile profile) async {
    try {
      _ensureInitialized();

      // If preferences is null, we can't store the profile
      if (_preferences == null) {
        debugPrint(
            'UserPreferencesService: preferences is null, cannot store profile');
        return false;
      }

      // Convert profile to JSON and then to string
      final profileJson = profile.toJson();
      final profileString = jsonEncode(profileJson);

      // Save to preferences
      final result =
          await _preferences?.setString(_userProfileKey, profileString) ??
              false;

      debugPrint('UserPreferencesService: Profile saved successfully: $result');
      return result;
    } catch (e) {
      debugPrint('UserPreferencesService: Error storing profile: $e');
      return false;
    }
  }

  /// Retrieve stored user profile
  static Future<UserProfile?> getStoredProfile() async {
    try {
      _ensureInitialized();

      // If preferences is null, return a default profile
      if (_preferences == null) {
        debugPrint(
            'UserPreferencesService: preferences is null, returning default profile');
        return UserProfile(
          id: DateTime.now().toString(),
          username: 'Default User',
          displayName: 'Default User',
          year: 'Freshman',
          major: 'Undecided',
          residence: 'Off Campus',
          eventCount: 0,
          clubCount: 0,
          friendCount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          accountTier: AccountTier.public,
        );
      }

      // Get profile string from preferences
      final profileString = _preferences?.getString(_userProfileKey);

      if (profileString == null || profileString.isEmpty) {
        debugPrint('UserPreferencesService: No stored profile found');
        return null;
      }

      // Convert string to JSON then to UserProfile object
      final profileJson = jsonDecode(profileString) as Map<String, dynamic>;
      final profile = UserProfile.fromJson(profileJson);

      debugPrint(
          'UserPreferencesService: Retrieved profile for user: ${profile.username}');
      return profile;
    } catch (e) {
      debugPrint('UserPreferencesService: Error retrieving profile: $e');
      // Return a default profile on error
      return UserProfile(
        id: DateTime.now().toString(),
        username: 'Default User',
        displayName: 'Default User',
        year: 'Freshman',
        major: 'Undecided',
        residence: 'Off Campus',
        eventCount: 0,
        clubCount: 0,
        friendCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        accountTier: AccountTier.public,
      );
    }
  }

  /// Ensure the preferences service is initialized
  static void _ensureInitialized() {
    if (_preferences == null) {
      debugPrint(
          'UserPreferencesService: Not initialized. Attempting to initialize now...');
      // Throw an exception that will be handled by the caller
      throw Exception('UserPreferencesService not initialized. Call initialize() first.');
    }
  }

  /// Save user email
  static Future<bool> saveUserEmail(String email) async {
    try {
      _ensureInitialized();
      final result =
          await _preferences?.setString(_userEmailKey, email) ?? false;
      debugPrint('UserPreferencesService: Email saved: $email');
      return result;
    } catch (e) {
      debugPrint('UserPreferencesService: Error saving email: $e');
      return false;
    }
  }

  /// Get stored user email
  static String getUserEmail() {
    try {
      _ensureInitialized();
      final email = _preferences?.getString(_userEmailKey) ?? '';
      return email;
    } catch (e) {
      debugPrint('UserPreferencesService: Error getting email: $e');
      return '';
    }
  }

  /// Check if the user has a Buffalo.edu email
  static bool hasBuffaloEmail() {
    final email = getUserEmail();
    return email.toLowerCase().endsWith('buffalo.edu');
  }

  /// Get the currently stored user ID
  static Future<String?> getUserId() async {
    try {
      _ensureInitialized();
      return _preferences?.getString(_userIdKey);
    } catch (e) {
      debugPrint('UserPreferencesService: Error getting user ID: $e');
      return null;
    }
  }

  /// Set the current user ID
  static Future<bool> setUserId(String userId) async {
    try {
      _ensureInitialized();
      final result = await _preferences?.setString(_userIdKey, userId) ?? false;
      debugPrint(
          'UserPreferencesService: User ID saved: $userId, result: $result');
      return result;
    } catch (e) {
      debugPrint('UserPreferencesService: Error saving user ID: $e');
      return false;
    }
  }

  /// Clear all profile data
  static Future<bool> clearProfile() async {
    try {
      _ensureInitialized();
      final result = await _preferences?.remove(_userProfileKey) ?? false;
      debugPrint('UserPreferencesService: Profile cleared, result: $result');
      return result;
    } catch (e) {
      debugPrint('UserPreferencesService: Error clearing profile: $e');
      return false;
    }
  }

  /// Clear all user data - useful for sign out or abandoned onboarding
  static Future<bool> clearUserData() async {
    try {
      _ensureInitialized();

      // List of all keys to clear
      final keysToRemove = [
        _hasCompletedOnboardingKey,
        _userProfileKey,
        _userEmailKey,
        _userIdKey
      ];

      // Track success status
      bool allSuccessful = true;

      // Clear each key and track success
      for (final key in keysToRemove) {
        final success = await _preferences?.remove(key) ?? false;
        if (!success) {
          debugPrint('UserPreferencesService: Failed to clear $key');
          allSuccessful = false;
        }
      }

      debugPrint(
          'UserPreferencesService: All user data cleared, success: $allSuccessful');
      return allSuccessful;
    } catch (e) {
      debugPrint('UserPreferencesService: Error clearing user data: $e');
      return false;
    }
  }

  /// Store onboarding data during the onboarding process
  static Future<bool> setOnboardingData(Map<String, dynamic> data) async {
    try {
      _ensureInitialized();

      // If preferences is null, we can't store the data
      if (_preferences == null) {
        debugPrint(
            'UserPreferencesService: preferences is null, cannot store onboarding data');
        return false;
      }

      // Convert data to JSON string
      final dataString = jsonEncode(data);

      // Save to preferences
      final result =
          await _preferences?.setString(_onboardingDataKey, dataString) ??
              false;

      debugPrint(
          'UserPreferencesService: Onboarding data saved successfully: $result');
      return result;
    } catch (e) {
      debugPrint('UserPreferencesService: Error storing onboarding data: $e');
      return false;
    }
  }

  /// Retrieve stored onboarding data
  static Future<Map<String, dynamic>?> getOnboardingData() async {
    try {
      _ensureInitialized();

      // If preferences is null or key doesn't exist, return null
      if (_preferences == null ||
          !(_preferences!.containsKey(_onboardingDataKey))) {
        return null;
      }

      // Get the stored data
      final dataString = _preferences!.getString(_onboardingDataKey);

      if (dataString == null || dataString.isEmpty) {
        return null;
      }

      // Parse the JSON string
      final data = jsonDecode(dataString) as Map<String, dynamic>;

      return data;
    } catch (e) {
      debugPrint(
          'UserPreferencesService: Error retrieving onboarding data: $e');
      return null;
    }
  }

  /// Clear onboarding data when onboarding is complete or abandoned
  static Future<bool> clearOnboardingData() async {
    try {
      _ensureInitialized();

      if (_preferences == null) {
        return false;
      }

      return await _preferences!.remove(_onboardingDataKey);
    } catch (e) {
      debugPrint('UserPreferencesService: Error clearing onboarding data: $e');
      return false;
    }
  }

  /// Get the SharedPreferences instance (initializes if needed)
  static SharedPreferences getPreferences() {
    if (_preferences == null) {
      throw Exception(
          'UserPreferencesService not initialized. Call initialize() first.');
    }
    return _preferences!;
  }
}
