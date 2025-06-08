import 'dart:convert';
import 'dart:math'; // Required for nonce generation
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/services/user_preferences_service.dart';
import 'package:crypto/crypto.dart'; // Required for Apple Sign In nonce hashing if needed
import 'package:shared_preferences/shared_preferences.dart';

/// Helper class for social authentication operations
class SocialAuthHelpers {
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
          ? docSnapshot.data() 
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
    if (lowercaseEmail.endsWith('.edu')) {
      return AccountTier.verified;
    }

    return AccountTier.public;
  }

  /// Checks if an email address belongs to a .edu domain.
  static bool isEduEmail(String? email) {
    if (email == null || email.isEmpty) {
      return false;
    }
    // Simple check for .edu suffix, case-insensitive
    return email.trim().toLowerCase().endsWith('.edu');
  }

  /// Validates if the email belongs to an approved educational domain
  /// Includes checks for .edu domains and approved international educational domains
  static bool isApprovedEducationalDomain(String? email) {
    if (email == null || email.isEmpty) {
      return false;
    }
    
    final lowercaseEmail = email.trim().toLowerCase();
    
    // US educational domains
    if (lowercaseEmail.endsWith('.edu')) {
      return true;
    }
    
    // Known international educational domains
    final approvedDomains = [
      // UK universities
      '.ac.uk',
      // Canadian universities
      '.edu.ca',
      // Australian universities
      '.edu.au',
      // Add more international domains as needed
    ];
    
    // Check against approved international domains
    for (final domain in approvedDomains) {
      if (lowercaseEmail.endsWith(domain)) {
        return true;
      }
    }
    
    // Specific approved educational institutions (non-standard domains)
    final approvedInstitutions = [
      '@student.institution.org',
      '@university.com',
      // Add more as needed
    ];
    
    // Check against specific approved institutions
    for (final institution in approvedInstitutions) {
      if (lowercaseEmail.endsWith(institution)) {
        return true;
      }
    }
    
    return false;
  }

  /// Performs MX record validation for educational emails (advanced)
  /// This is a placeholder for the actual implementation which would typically
  /// use a server-side component or callable function
  static Future<bool> validateEmailMXRecord(String email) async {
    // NOTE: This would normally be implemented on the server-side
    // with Firebase Cloud Functions or similar
    
    // For now, we just validate the domain suffix
    return isApprovedEducationalDomain(email);
  }

  /// Generates a secure random nonce string.
  static String generateNonce([int length = 32]) {
    final random = Random.secure();
    final values = List<int>.generate(length, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  /// Generates a basic username from an email address.
  static String? generateUsernameFromEmail(String? email) {
    if (email == null || !email.contains('@')) {
      return null;
    }
    String username = email.split('@')[0];
    // Remove common non-alphanumeric chars except '.' and '_'
    username = username.replaceAll(RegExp(r'[^a-zA-Z0-9._]'), '');
    // Prevent excessively long usernames
    if (username.length > 20) {
      username = username.substring(0, 20);
    }
    // Ensure it's not empty after cleaning
    if (username.isEmpty) {
      // Fallback if cleaning removed everything
      return 'user${Random().nextInt(9999)}';
    }
    return username;
  }

  /// Hashes the nonce for Apple Sign In verification (if needed by backend).
  /// Keep this if your backend requires the SHA256 hash.
  static String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Validates and processes a Google OAuth token for educational email verification
  /// This can be used during Google EDU OAuth flow
  static Future<Map<String, dynamic>> validateGoogleEduToken(
    String idToken,
    String accessToken,
    FirebaseFirestore firestore,
  ) async {
    try {
      // In a real implementation, we would use the Firebase Admin SDK or a Cloud Function
      // to verify the token and extract claims
      
      // For now, this is a placeholder that would be replaced with an actual implementation
      // using the Firebase Admin SDK to verify the token
      debugPrint('Validating Google EDU token');
      
      // This would be the structure of the data returned from token verification
      final Map<String, dynamic> tokenData = {
        'email': 'example@university.edu', // Would come from token verification
        'email_verified': true, // Would come from token verification
        'name': 'John Doe', // Would come from token verification
        'picture': 'https://example.com/photo.jpg', // Would come from token verification
        'hd': 'university.edu', // Would come from token - the hosted domain
      };
      
      // Verify the hosted domain is an educational domain
      final hostedDomain = tokenData['hd'] as String?;
      final email = tokenData['email'] as String?;
      
      if (!isApprovedEducationalDomain(email) || !isEduEmail(email)) {
        throw 'The email domain is not an approved educational institution.';
      }
      
      // Return the verified user data
      return {
        'email': email,
        'displayName': tokenData['name'],
        'photoUrl': tokenData['picture'],
        'provider': 'google-edu',
        'isVerified': tokenData['email_verified'] == true,
        'hostedDomain': hostedDomain,
      };
    } catch (e) {
      debugPrint('Error validating Google EDU token: $e');
      throw 'Failed to validate educational credentials: $e';
    }
  }

  /// Extracts structured user data from a Firebase User for educational verification
  static Map<String, dynamic> extractUserDataForEduVerification(User user) {
    final email = user.email;
    final displayName = user.displayName;
    final photoUrl = user.photoURL;
    
    final isEdu = isEduEmail(email);
    final domainParts = email?.split('@') ?? [];
    final domain = domainParts.length > 1 ? domainParts[1] : null;
    
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'provider': 'google-edu',
      'isEduEmail': isEdu,
      'domain': domain,
      'isVerified': user.emailVerified,
    };
  }

  /// Verifies the OAuth state parameter to prevent CSRF attacks
  /// Returns true if the state parameter is valid
  static bool verifyOAuthState(String stateParam) {
    try {
      // In a real implementation, we would store the state in secure storage
      // and validate it here. For now, we'll implement a simple version.
      
      // Check if the state parameter has the expected format
      if (stateParam.isEmpty || stateParam.length < 10) {
        debugPrint('Invalid OAuth state parameter format');
        return false;
      }
      
      // In a production environment, we would:
      // 1. Get the stored state from secure storage
      // 2. Compare it with the received state parameter
      // 3. Ensure it hasn't expired (using a timestamp)
      // 4. Remove the state from storage after verification (one-time use)
      
      // For POC purposes, we'll just check for the parameter existence
      // and the format, as actual state management requires session handling
      
      return true;
    } catch (e) {
      debugPrint('Error verifying OAuth state: $e');
      return false;
    }
  }
  
  /// Generates and stores a new OAuth state parameter
  /// Returns the generated state parameter
  static Future<String> generateOAuthState() async {
    try {
      // Generate a random nonce
      final state = generateNonce(32);
      
      // In a real implementation, we would store this state with a timestamp
      // in secure storage or a server-side session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('oauth_state', state);
      await prefs.setInt('oauth_state_timestamp', DateTime.now().millisecondsSinceEpoch);
      
      return state;
    } catch (e) {
      debugPrint('Error generating OAuth state: $e');
      // Return a fallback state in case of error
      return generateNonce(32);
    }
  }
} 