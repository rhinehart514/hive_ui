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
  static const String _socialAuthRedirectPathKey = 'social_auth_redirect_path';
  static const String _emailForSignInKey = 'email_for_sign_in';

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
          spaceCount: 0,
          friendCount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          accountTier: AccountTier.public,
          interests: const [],
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
        // Note: setMockInitialValues is only for testing - don't use in production
        // SharedPreferences.setMockInitialValues({});
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

      // Check the explicit onboarding flag
      final hasCompleted = _preferences?.getBool(_hasCompletedOnboardingKey) ?? false;
      
      // For debugging
      final savedEmail = getUserEmail();
      final hasProfile = _preferences?.containsKey(_userProfileKey) ?? false;
      final hasUserId = _preferences?.containsKey(_userIdKey) ?? false;
      
      debugPrint('UserPreferencesService: hasCompletedOnboarding check - '
          'flag: $hasCompleted, email: $savedEmail, hasProfile: $hasProfile, hasUserId: $hasUserId');

      // Only use the explicit flag value - no auto-correction
      return hasCompleted;
    } catch (e) {
      debugPrint('Error checking onboarding status: $e');
      // Default to false if there's an error - force onboarding to be shown
      return false;
    }
  }

  /// Mark onboarding as completed with robust error handling
  static Future<bool> setOnboardingCompleted(bool completed) async {
    try {
      _ensureInitialized();

      debugPrint('UserPreferencesService: Setting onboarding completed to $completed');
      
      // Get current values for debugging
      final hasProfile = _preferences?.containsKey(_userProfileKey) ?? false;
      final hasUserId = _preferences?.containsKey(_userIdKey) ?? false;
      final email = getUserEmail();
      
      debugPrint('UserPreferencesService: Current state - hasProfile: $hasProfile, '
          'hasUserId: $hasUserId, email: $email');

      // Try to set the value
      final result =
          await _preferences?.setBool(_hasCompletedOnboardingKey, completed) ??
              false;

      // Verify it was actually set
      final verifyValue =
          _preferences?.getBool(_hasCompletedOnboardingKey) ?? false;

      if (verifyValue != completed) {
        debugPrint(
            'Warning: Failed to verify onboarding completed flag was set. Expected: $completed, got: $verifyValue');

        // Try one more time
        await _preferences?.setBool(_hasCompletedOnboardingKey, completed);

        // Final verification
        final finalCheck =
            _preferences?.getBool(_hasCompletedOnboardingKey) ?? false;
        debugPrint('Final onboarding completion state: $finalCheck (Expected: $completed)');

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
    try {
      _ensureInitialized();
      
      // Clear any stored profile first to prevent auto-correction
      await _preferences?.remove(_userProfileKey);
      debugPrint('UserPreferencesService: Removed stored profile during onboarding reset');
      
      // Clear stored email as well
      await _preferences?.remove(_userEmailKey);
      
      // Set onboarding flag to false
      final result = await _preferences?.setBool(_hasCompletedOnboardingKey, false) ?? false;
      
      // Verify the flag was set
      final verifyValue = _preferences?.getBool(_hasCompletedOnboardingKey) ?? false;
      debugPrint('UserPreferencesService: Onboarding reset - flag is now $verifyValue');
      
      return result;
    } catch (e) {
      debugPrint('UserPreferencesService: Error resetting onboarding status: $e');
      return false;
    }
  }

  /// Mark that a user needs to complete onboarding (for new accounts)
  static Future<bool> setNeedsOnboarding(bool needsOnboarding) async {
    try {
      await initialize();
      
      // Set onboarding flag to the opposite of needsOnboarding
      // (since hasCompletedOnboarding is the opposite of needsOnboarding)
      final completed = !needsOnboarding;
      final result = await _preferences?.setBool(_hasCompletedOnboardingKey, completed) ?? false;
      
      // Verify the flag was set correctly
      final verifyValue = _preferences?.getBool(_hasCompletedOnboardingKey) ?? !completed;
      
      debugPrint('UserPreferencesService: Set needs onboarding to $needsOnboarding, '
          'hasCompletedOnboarding flag is now ${!needsOnboarding}');
      
      // If verification failed, try one more time
      if (verifyValue != completed) {
        debugPrint('UserPreferencesService: Failed to set onboarding flag - trying again');
        await _preferences?.setBool(_hasCompletedOnboardingKey, completed);
        
        // Final verification
        final finalCheck = _preferences?.getBool(_hasCompletedOnboardingKey) ?? !completed;
        return finalCheck == completed;
      }
      
      return true;
    } catch (e) {
      debugPrint('UserPreferencesService: Error setting onboarding status: $e');
      return false;
    }
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
          spaceCount: 0,
          friendCount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          accountTier: AccountTier.public,
          interests: const [],
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
        spaceCount: 0,
        friendCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        accountTier: AccountTier.public,
        interests: const [],
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

  /// Force reset onboarding status - for use when regular reset fails
  static Future<bool> forceResetOnboardingStatus() async {
    try {
      debugPrint('UserPreferencesService: Performing FORCE reset of onboarding status');
      
      // Get a fresh instance of SharedPreferences to bypass any caching issues
      final prefs = await SharedPreferences.getInstance();
      
      // Clear everything related to user state
      await prefs.remove(_userProfileKey);
      await prefs.remove(_userEmailKey);
      await prefs.remove(_onboardingDataKey);
      
      // Set the onboarding flag to false directly
      final result = await prefs.setBool(_hasCompletedOnboardingKey, false);
      
      // Verify the flag is now false
      final verifyValue = prefs.getBool(_hasCompletedOnboardingKey) ?? false;
      debugPrint('UserPreferencesService: Force reset - flag is now: $verifyValue (result: $result)');
      
      // Update our cached instance
      _preferences = prefs;
      
      return result;
    } catch (e) {
      debugPrint('UserPreferencesService: Error in force reset of onboarding: $e');
      return false;
    }
  }
  
  /// Get the stored user ID (synchronous version)
  static String getUserIdSync() {
    _ensureInitialized();
    return _preferences?.getString(_userIdKey) ?? '';
  }
  
  /// Save the user ID
  static Future<bool> saveUserId(String userId) async {
    _ensureInitialized();
    debugPrint('UserPreferencesService: Saving user ID: $userId');
    return await _preferences?.setString(_userIdKey, userId) ?? false;
  }

  /// Store the path to redirect to after social authentication
  static Future<bool> setSocialAuthRedirectPath(String path) async {
    try {
      _ensureInitialized();
      
      final result = await _preferences?.setString(_socialAuthRedirectPathKey, path) ?? false;
      debugPrint('UserPreferencesService: Social auth redirect path saved: $path');
      return result;
    } catch (e) {
      debugPrint('UserPreferencesService: Error storing social auth redirect path: $e');
      return false;
    }
  }
  
  /// Get the stored redirect path for social authentication
  static String getSocialAuthRedirectPath() {
    try {
      _ensureInitialized();
      final path = _preferences?.getString(_socialAuthRedirectPathKey) ?? '';
      return path;
    } catch (e) {
      debugPrint('UserPreferencesService: Error getting social auth redirect path: $e');
      return '';
    }
  }
  
  /// Clear the stored redirect path after using it
  static Future<bool> clearSocialAuthRedirectPath() async {
    try {
      _ensureInitialized();
      final result = await _preferences?.remove(_socialAuthRedirectPathKey) ?? false;
      debugPrint('UserPreferencesService: Social auth redirect path cleared');
      return result;
    } catch (e) {
      debugPrint('UserPreferencesService: Error clearing social auth redirect path: $e');
      return false;
    }
  }

  /// Stores email for magic link sign-in
  /// 
  /// This is used to remember which email the magic link was sent to
  /// so it can be provided automatically during the sign-in process
  static Future<bool> storeEmailForSignIn(String email) async {
    try {
      await initialize();
      debugPrint('UserPreferencesService: Storing email for sign-in: $email');
      return await _preferences?.setString(_emailForSignInKey, email) ?? false;
    } catch (e) {
      debugPrint('UserPreferencesService: Error storing email for sign-in: $e');
      return false;
    }
  }
  
  /// Gets the stored email for magic link sign-in
  /// 
  /// Returns the email that was stored for magic link authentication
  /// or empty string if none is found
  static String getEmailForSignIn() {
    try {
      _ensureInitialized();
      final email = _preferences?.getString(_emailForSignInKey) ?? '';
      return email;
    } catch (e) {
      debugPrint('UserPreferencesService: Error getting email for sign-in: $e');
      return '';
    }
  }
  
  /// Clears the email stored for magic link sign-in
  /// 
  /// This should be called after successful sign-in
  static Future<bool> clearEmailForSignIn() async {
    try {
      _ensureInitialized();
      debugPrint('UserPreferencesService: Clearing email for sign-in');
      return await _preferences?.remove(_emailForSignInKey) ?? false;
    } catch (e) {
      debugPrint('UserPreferencesService: Error clearing email for sign-in: $e');
      return false;
    }
  }
}
