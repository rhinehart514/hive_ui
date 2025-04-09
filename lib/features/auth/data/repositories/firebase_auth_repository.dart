import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'
    show debugPrint, kIsWeb, TargetPlatform, defaultTargetPlatform;
import 'package:hive_ui/features/auth/domain/entities/auth_user.dart';
import 'package:hive_ui/features/auth/domain/repositories/auth_repository.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_ui/services/user_preferences_service.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/services/optimized_club_adapter.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_ui/firebase_options.dart';
import 'package:hive_ui/firebase_init_tracker.dart';
import 'package:hive_ui/features/auth/data/repositories/social_auth_helpers.dart';

/// Firebase implementation of the AuthRepository
class FirebaseAuthRepository implements AuthRepository {
  // Firebase instances - make _firebaseAuth final as it's required
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn? _googleSignIn;
  // Make _firestore final as it's now required
  final FirebaseFirestore _firestore;
  final FacebookAuth? _facebookAuth;

  // Cache for reducing unnecessary database reads/writes
  AuthUser? _cachedUser;
  DateTime? _lastUserCheck;

  // Constants for optimizing Firebase operations
  static const Duration _userCacheDuration = Duration(minutes: 5);
  static const String _usersCollection = 'users';

  // Encryption related variables
  late final String _keyName;
  late final String _ivName;
  late final encrypt.Encrypter _encrypter;
  late final encrypt.IV _iv;

  /// Creates a new FirebaseAuthRepository.
  /// Requires FirebaseAuth and FirebaseFirestore instances.
  FirebaseAuthRepository({
    required FirebaseAuth firebaseAuth,
    // Make firestore required
    required FirebaseFirestore firestore,
    GoogleSignIn? googleSignIn,
    FacebookAuth? facebookAuth,
  }) : 
    _firebaseAuth = firebaseAuth, 
    // Initialize required _firestore directly
    _firestore = firestore,
    // Keep other initializations (remove fallback for _firestore)
    _googleSignIn = googleSignIn ??
        (kIsWeb ||
                defaultTargetPlatform == TargetPlatform.android ||
                defaultTargetPlatform == TargetPlatform.iOS
            ? GoogleSignIn()
            : null),
    _facebookAuth = facebookAuth ??
        (kIsWeb ||
                defaultTargetPlatform == TargetPlatform.android ||
                defaultTargetPlatform == TargetPlatform.iOS
            ? FacebookAuth.instance
            : null)
  {
    // Set up auth state listener using the provided _firebaseAuth
    _setupAuthStateListener();
  }

  /// Listen to auth state changes to invalidate cache
  void _setupAuthStateListener() {
    _firebaseAuth.authStateChanges().listen((_) {
      // Invalidate cache when auth state changes
      _cachedUser = null;
      _lastUserCheck = null;
    });
  }

  /// Helper method to convert FirebaseAuth user to domain AuthUser
  /// Includes optimizations to avoid unnecessary computations
  AuthUser _mapFirebaseUserToAuthUser(User? user) {
    if (user == null) {
      return AuthUser.empty();
    }

    // Get the user metadata for timestamps
    final metadata = user.metadata;
    final DateTime? creationTime = metadata.creationTime;
    final DateTime? lastSignInTime = metadata.lastSignInTime;

    return AuthUser(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      isEmailVerified: user.emailVerified,
      // Use metadata for timestamps, or fallback to current time
      createdAt: creationTime ?? DateTime.now(),
      lastSignInTime: lastSignInTime ?? DateTime.now(),
      // Add provider information
      providers: user.providerData.map((userInfo) => userInfo.providerId).toList(),
    );
  }

  @override
  AuthUser getCurrentUser() {
    // Check if we have a cached user that's still valid
    final now = DateTime.now();
    if (_cachedUser != null &&
        _lastUserCheck != null &&
        now.difference(_lastUserCheck!) < _userCacheDuration) {
      return _cachedUser!;
    }

    // Get the current user and update cache
    final user = _mapFirebaseUserToAuthUser(_firebaseAuth.currentUser);
    _cachedUser = user;
    _lastUserCheck = now;

    return user;
  }

  @override
  Stream<AuthUser> get authStateChanges =>
      _firebaseAuth.authStateChanges().map(_mapFirebaseUserToAuthUser);

  @override
  Future<AuthUser> signInWithEmailPassword(
      String email, String password) async {
    try {
      debugPrint('Starting email/password sign in');
      
      // Ensure Firebase is initialized
      _ensureFirebaseInitialized();

      // Windows-specific error handling for PigeonUserDetails issue
      try {
        final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );

        final user = userCredential.user;
        if (user != null) {
          // Fire and forget profile update to reduce blocking time
          _updateUserLoginTime(user.uid);
        }

        // Return the mapped user
        final authUser = _mapFirebaseUserToAuthUser(user);
        _cachedUser = authUser;
        _lastUserCheck = DateTime.now();

        return authUser;
      } catch (e) {
        // Handle Windows-specific PigeonUserDetails error
        if (e.toString().contains('PigeonUserDetails')) {
          debugPrint('Handling Windows-specific PigeonUserDetails error');
          // Wait for auth state to propagate
          await Future.delayed(const Duration(milliseconds: 200));
          
          // Check if the user was actually signed in
          final currentUser = _firebaseAuth.currentUser;
          if (currentUser != null) {
            debugPrint('User successfully signed in despite PigeonUserDetails error');
            // Update login time
            _updateUserLoginTime(currentUser.uid);
            
            // Return the user object
            final authUser = _mapFirebaseUserToAuthUser(currentUser);
            _cachedUser = authUser;
            _lastUserCheck = DateTime.now();
            return authUser;
          }
        }
        rethrow;
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase auth error: ${e.code} - ${e.message}');
      throw _mapFirebaseAuthExceptionToMessage(e);
    } catch (e) {
      debugPrint('Error during sign in: $e');
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  @override
  Future<AuthUser> createUserWithEmailPassword(
      String email, String password) async {
    try {
      // Ensure Firebase is initialized
      _ensureFirebaseInitialized();

      // Input validation
      if (email.isEmpty || !email.contains('@')) {
        throw 'Please enter a valid email address';
      }
      if (password.isEmpty || password.length < 6) {
        throw 'Password must be at least 6 characters long';
      }

      // Windows-specific error handling for PigeonUserDetails issue
      try {
        // Create user account
        final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        
        final user = userCredential.user;
        if (user == null) {
          throw 'Account creation failed: No user returned';
        }

        // Create the initial user profile in Firestore
        try {
          await _createUserProfile(user).timeout(
            const Duration(seconds: 5),  // Mobile-optimized timeout
            onTimeout: () {
              debugPrint('Profile creation timed out, continuing with local save');
              _saveUserProfileLocally(user);
            },
          );
        } catch (e) {
          debugPrint('Error creating user profile: $e');
          // Continue despite profile creation error - we can fix this later
          _saveUserProfileLocally(user);
        }

        // Return the mapped user
        final authUser = _mapFirebaseUserToAuthUser(user);
        _cachedUser = authUser;
        _lastUserCheck = DateTime.now();

        return authUser;
      } catch (e) {
        // Handle Windows-specific PigeonUserDetails error
        if (e.toString().contains('PigeonUserDetails')) {
          debugPrint('Handling Windows-specific PigeonUserDetails error');
          // Wait for auth state to propagate
          await Future.delayed(const Duration(milliseconds: 200));
          
          // Check if the user was actually created
          final currentUser = _firebaseAuth.currentUser;
          if (currentUser != null) {
            // Create profile for the user
            await _createUserProfile(currentUser);
            
            // Return the user object
            final authUser = _mapFirebaseUserToAuthUser(currentUser);
            _cachedUser = authUser;
            _lastUserCheck = DateTime.now();
            return authUser;
          }
        }
        rethrow;
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase auth error: ${e.code} - ${e.message}');
      throw _mapFirebaseAuthExceptionToMessage(e);
    } catch (e) {
      debugPrint('Error during account creation: $e');
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    try {
      if (_googleSignIn == null) {
        throw 'Google sign-in is not available on this platform';
      }

      // Sign in with Google and get authentication details
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw 'Google sign-in was cancelled';
      }

      final googleAuth = await googleUser.authentication;

      // Create a credential for Firebase using Google tokens
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with Firebase
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;
      
      if (user == null) {
        throw 'Failed to complete Google sign-in';
      }

      // Get additional user information from Google
      final Map<String, dynamic> socialData = {
        'displayName': googleUser.displayName,
        'email': googleUser.email,
        'photoUrl': googleUser.photoUrl,
        'provider': 'google.com',
        // Add any other fields specific to Google that you want to use
      };

      // Merge the social profile data with the user's profile
      await SocialAuthHelper.mergeSocialProfileData(
        user: user,
        socialData: socialData,
        firestore: _firestore,
        createUserProfile: _createUserProfile,
        saveUserProfileLocally: _saveUserProfileLocally,
      );
      
      // Update last login time without blocking
      _updateUserLoginTime(user.uid);
      
      // Return the mapped user
      final authUser = _mapFirebaseUserToAuthUser(user);
      _cachedUser = authUser;
      _lastUserCheck = DateTime.now();

      return authUser;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase auth error: ${e.code} - ${e.message}');
      throw _mapFirebaseAuthExceptionToMessage(e);
    } catch (e) {
      debugPrint('Error during Google sign-in: $e');
      if (e.toString().contains('sign-in was cancelled')) {
        throw 'Google sign-in was cancelled';
      }
      throw 'Could not complete Google sign-in. Please try again.';
    }
  }
  
  @override
  Future<AuthUser> signInWithApple() async {
    try {
      // Check platform support
      if (!(kIsWeb || defaultTargetPlatform == TargetPlatform.iOS || 
           (defaultTargetPlatform == TargetPlatform.android && 
            await SignInWithApple.isAvailable()))) {
        throw 'Apple Sign-In is not supported on this platform';
      }
      
      // Generate nonce for Apple Sign In
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);
      
      // Request Apple credential
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );
      
      // Create OAuthCredential
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );
      
      // Sign in with Firebase
      final userCredential = await _firebaseAuth.signInWithCredential(oauthCredential);
      final user = userCredential.user;
      
      if (user == null) {
        throw 'Failed to complete Apple sign-in';
      }
      
      // Prepare social data from Apple
      String fullName = '';
      if (appleCredential.givenName != null) fullName += appleCredential.givenName!;
      if (appleCredential.familyName != null) {
        if (fullName.isNotEmpty) fullName += ' ';
        fullName += appleCredential.familyName!;
      }
      
      final Map<String, dynamic> socialData = {
        'displayName': fullName.isNotEmpty ? fullName : user.displayName,
        'email': appleCredential.email ?? user.email,
        'photoUrl': user.photoURL,
        'provider': 'apple.com',
        'firstName': appleCredential.givenName,
        'lastName': appleCredential.familyName,
      };
      
      // Merge social profile data
      await SocialAuthHelper.mergeSocialProfileData(
        user: user,
        socialData: socialData,
        firestore: _firestore,
        createUserProfile: _createUserProfile,
        saveUserProfileLocally: _saveUserProfileLocally,
      );
      
      // Update last login time
      _updateUserLoginTime(user.uid);
      
      // Return the mapped user
      final authUser = _mapFirebaseUserToAuthUser(user);
      _cachedUser = authUser;
      _lastUserCheck = DateTime.now();
      
      return authUser;
    } catch (e) {
      debugPrint('Error during Apple sign-in: $e');
      
      // Handle specific known exceptions
      if (e.toString().contains('canceled')) {
        throw 'Apple sign-in was cancelled';
      }
      
      // For all other exceptions
      throw 'Could not complete Apple sign-in. Please try again.';
    }
  }
  
  @override
  Future<AuthUser> signInWithFacebook() async {
    try {
      if (_facebookAuth == null) {
        throw 'Facebook Sign-In is not supported on this platform';
      }
      
      // Login with Facebook
      final loginResult = await _facebookAuth.login();
      
      if (loginResult.status != LoginStatus.success) {
        throw 'Facebook sign-in was cancelled or failed';
      }
      
      // Get access token
      final accessToken = loginResult.accessToken;
      if (accessToken == null || accessToken.token.isEmpty) {
        throw 'Failed to get Facebook access token';
      }
      
      // Create credential
      final credential = FacebookAuthProvider.credential(accessToken.token);
      
      // Sign in with Firebase
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;
      
      if (user == null) {
        throw 'Failed to complete Facebook sign-in';
      }
      
      // Get additional user profile data
      final userData = await _facebookAuth.getUserData();
      
      final Map<String, dynamic> socialData = {
        'displayName': userData['name'],
        'email': userData['email'] ?? user.email,
        'photoUrl': userData['picture']?['data']?['url'] ?? user.photoURL,
        'provider': 'facebook.com',
        // Add any other Facebook-specific fields you want
      };
      
      // Merge social profile data
      await SocialAuthHelper.mergeSocialProfileData(
        user: user,
        socialData: socialData,
        firestore: _firestore,
        createUserProfile: _createUserProfile,
        saveUserProfileLocally: _saveUserProfileLocally,
      );
      
      // Update last login time
      _updateUserLoginTime(user.uid);
      
      // Return the mapped user
      final authUser = _mapFirebaseUserToAuthUser(user);
      _cachedUser = authUser;
      _lastUserCheck = DateTime.now();
      
      return authUser;
    } catch (e) {
      debugPrint('Error during Facebook sign-in: $e');
      if (e.toString().contains('cancelled')) {
        throw 'Facebook sign-in was cancelled';
      }
      throw 'Could not complete Facebook sign-in. Please try again.';
    }
  }

  @override
  Future<void> signOut() async {
    try {
      // Clear cache immediately
      _cachedUser = null;
      _lastUserCheck = null;

      // Clear optimized data caches
      try {
        await UserPreferencesService.initialize();
        final optimizedAdapterAvailable =
            await OptimizedClubAdapter.clearCache()
                .timeout(const Duration(seconds: 1))
                .then((_) => true)
                .catchError((_) => false);

        debugPrint(
            'OptimizedClubAdapter cache cleared: $optimizedAdapterAvailable');
      } catch (cacheError) {
        // Log but don't prevent sign out if cache clearing fails
        debugPrint('Non-critical error clearing optimized cache: $cacheError');
      }

      // Sign out from all providers
      await Future.wait([
        _firebaseAuth.signOut(),
        if (_googleSignIn != null) _googleSignIn.signOut(),
        if (_facebookAuth != null) _facebookAuth.logOut(),
      ]);
    } catch (e) {
      debugPrint('Error during sign out: $e');
      throw 'Failed to sign out. Please try again.';
    }
  }

  /// Creates a new user profile in Firestore
  /// Optimized to reduce data size and write operations
  Future<void> _createUserProfile(User user) async {
    try {
      // Verify we have a valid user with ID
      if (user.uid.isEmpty) {
        debugPrint('Cannot create profile: User ID is empty');
        return;
      }

      final userDocRef = _firestore.collection(_usersCollection).doc(user.uid);
      
      // Add retry logic for profile creation
      int retryCount = 0;
      const maxRetries = 3;
      const retryDelay = Duration(milliseconds: 500);

      while (retryCount < maxRetries) {
        try {
          // Use server timestamp for consistent timing
          final now = FieldValue.serverTimestamp();

          // Create minimal profile data with proper type safety
          final Map<String, dynamic> profileData = {
            'id': user.uid,
            'email': user.email ?? '',
            'displayName': user.displayName ?? 'New User',
            'username': user.displayName ?? 'User ${user.uid.substring(0, 4)}',
            'profileImageUrl': user.photoURL ?? '',
            'createdAt': now,
            'updatedAt': now,
            'lastLogin': now,
            'isEmailVerified': user.emailVerified,
            'accountTier': 'public',
            // Add required fields for UserProfile model with explicit types
            'year': 'Freshman',
            'major': 'Undecided',
            'residence': 'Off Campus',
            'eventCount': 0,
            'clubCount': 0,
            'friendCount': 0,
            'interests': <String>[],
            'savedEvents': <Map<String, dynamic>>[],
            'followedSpaces': <String>[],
            'isPublic': false,
            'isVerified': false,
            'isVerifiedPlus': false,
            'bio': '',
            // Ensure all fields from UserProfile model are included with proper types
            'clubAffiliation': '',
            'clubRole': '',
            // Add provider information
            'providers': user.providerData.map((info) => info.providerId).toList(),
          };

          // Set the document with merge option
          await userDocRef.set(profileData, SetOptions(merge: true));
          debugPrint('User profile created in Firestore successfully');
          
          // Also save to local storage as backup
          _saveUserProfileLocally(user);
          return;
        } catch (e) {
          retryCount++;
          if (retryCount < maxRetries) {
            debugPrint('Retry $retryCount: Error creating profile, retrying after delay: $e');
            await Future.delayed(retryDelay);
          } else {
            debugPrint('Final attempt failed. Error creating profile: $e');
            rethrow;
          }
        }
      }
    } catch (e) {
      debugPrint('Error creating user profile after all retries: $e');
      // Fallback to local storage
      _saveUserProfileLocally(user);
      // Rethrow to handle in the UI
      throw 'Failed to create user profile. Please try again.';
    }
  }

  /// Updates just the login time for returning users
  /// Fire-and-forget approach to reduce authentication blocking time
  void _updateUserLoginTime(String userId) {
    try {
      // Don't await this operation - it's not critical for auth flow
      _firestore.collection(_usersCollection).doc(userId).update({
        'lastLogin': FieldValue.serverTimestamp(),
        // Also update providers list if needed
        'providers': FieldValue.arrayUnion(
          _firebaseAuth.currentUser?.providerData.map((info) => info.providerId).toList() ?? []
        ),
      }).catchError((e) {
        debugPrint('Non-critical error updating login time: $e');
      });
    } catch (e) {
      // Just log, never throw from this method
      debugPrint('Error in _updateUserLoginTime: $e');
    }
  }

  /// Save basic user profile to local storage when Firestore is unavailable
  void _saveUserProfileLocally(User user) {
    try {
      debugPrint('Saving user profile to local storage as fallback');

      // Create minimal profile and save to preferences
      final profile = UserProfile(
        id: user.uid,
        username: user.displayName ?? 'User ${user.uid.substring(0, 4)}',
        displayName: user.displayName ?? 'User ${user.uid.substring(0, 4)}',
        profileImageUrl: user.photoURL,
        bio: '',
        year: 'Freshman',
        major: 'Undecided',
        residence: 'Off Campus',
        eventCount: 0,
        spaceCount: 0,
        friendCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        accountTier: _parseEmailToAccountTier(user.email),
        interests: const [],
      );

      // Store in user preferences
      UserPreferencesService.storeProfile(profile);
    } catch (e) {
      // Just log errors, don't throw
      debugPrint('Error saving profile locally: $e');
    }
  }

  /// Parse email domain to determine account tier
  AccountTier _parseEmailToAccountTier(String? email) {
    if (email == null) return AccountTier.public;

    final lowercaseEmail = email.toLowerCase();
    // Check for educational emails
    if (lowercaseEmail.endsWith('.edu') ||
        lowercaseEmail.contains('buffalo.edu')) {
      return AccountTier.verified;
    }

    return AccountTier.public;
  }

  /// Generate a random string for OAuth nonce
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    return List.generate(length, (i) => charset[int.parse(random[i % random.length]) % charset.length])
        .join();
  }

  /// Returns the SHA-256 hash of the input string as a hex string
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Map Firebase Auth exceptions to user-friendly messages
  String _mapFirebaseAuthExceptionToMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-credential':
        return 'Invalid login credentials';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'operation-not-allowed':
        return 'This login method is not enabled';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters';
      case 'invalid-email':
        return 'Invalid email format';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      case 'popup-closed-by-user':
        return 'Sign-in was cancelled';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method';
      default:
        return e.message ?? 'Authentication failed';
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Error in password reset: $e');
      rethrow;
    }
  }

  @override
  Future<bool> checkIfUserExists(String email) async {
    try {
      final methods = await _firebaseAuth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking if user exists: $e');
      return false;
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
      } else {
        throw 'No user logged in';
      }
    } catch (e) {
      throw 'Failed to send verification email: ${e.toString()}';
    }
  }

  @override
  Future<bool> checkEmailVerified() async {
    try {
      // Get fresh user data to ensure email status is current
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return false;
      }

      // Reload user to get latest verification status
      await user.reload();
      final refreshedUser = _firebaseAuth.currentUser;

      // Update cached user
      if (refreshedUser != null) {
        _cachedUser = _mapFirebaseUserToAuthUser(refreshedUser);
        _lastUserCheck = DateTime.now();
      }

      return refreshedUser?.emailVerified ?? false;
    } catch (e) {
      debugPrint('Error checking email verification: $e');
      return false;
    }
  }

  @override
  Future<void> updateEmailVerificationStatus() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw 'No user logged in';
      }

      // Reload user to get latest data
      await user.reload();
      final refreshedUser = _firebaseAuth.currentUser;

      if (refreshedUser != null && refreshedUser.emailVerified) {
        // Update verification status in Firestore
        final userDocRef =
            _firestore.collection(_usersCollection).doc(refreshedUser.uid);
        await userDocRef.update({
          'isEmailVerified': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update cache
        _cachedUser = _mapFirebaseUserToAuthUser(refreshedUser);
        _lastUserCheck = DateTime.now();
      }
    } catch (e) {
      debugPrint('Error updating email verification status: $e');
      throw 'Failed to update verification status: ${e.toString()}';
    }
  }
  
  @override
  Future<List<String>> getAvailableSignInMethods(String email) async {
    try {
      return await _firebaseAuth.fetchSignInMethodsForEmail(email);
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase error getting sign in methods: ${e.code} - ${e.message}');
      throw _mapFirebaseAuthExceptionToMessage(e);
    } catch (e) {
      debugPrint('Error getting sign in methods: $e');
      throw 'Failed to get available sign-in methods';
    }
  }
  
  @override
  Future<void> linkEmailPassword(String email, String password) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw 'No user logged in';
      }
      
      // Create email credential
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      
      // Link credential to account
      await user.linkWithCredential(credential);
      
      // Update profile
      await _firestore.collection(_usersCollection).doc(user.uid).update({
        'email': email,
        'providers': FieldValue.arrayUnion(['password']),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Refresh cached user
      _cachedUser = _mapFirebaseUserToAuthUser(user);
      _lastUserCheck = DateTime.now();
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase error linking email/password: ${e.code} - ${e.message}');
      throw _mapFirebaseAuthExceptionToMessage(e);
    } catch (e) {
      debugPrint('Error linking email/password: $e');
      throw 'Failed to link email and password to your account';
    }
  }

  void _ensureFirebaseInitialized() {
    try {
      // First check if we already know Firebase is initialized via our global tracker
      if (FirebaseInitTracker.isInitialized) {
        return; // Firebase is already initialized via our proper initialization path
      }
      
      // Check if Firebase is already initialized
      if (Firebase.apps.isEmpty) {
        debugPrint('WARNING: Firebase not initialized before auth operation. Initializing now...');
        // We shouldn't reach this point normally, but as a safety measure, initialize Firebase
        Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        
        // Update tracker
        FirebaseInitTracker.isInitialized = true;
        FirebaseInitTracker.needsInitialization = false;
      } else {
        // Firebase is initialized but tracker wasn't updated
        FirebaseInitTracker.isInitialized = true;
        FirebaseInitTracker.needsInitialization = false;
      }
    } catch (e) {
      debugPrint('Error checking Firebase initialization status: $e');
      throw 'Firebase initialization error. Please restart the app and try again.';
    }
  }
}
