import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show debugPrint, kIsWeb, TargetPlatform, defaultTargetPlatform;
import 'package:hive_ui/features/auth/domain/entities/auth_user.dart';
import 'package:hive_ui/features/auth/domain/repositories/auth_repository.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ui/services/user_preferences_service.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/services/optimized_club_adapter.dart';

/// Firebase implementation of the AuthRepository
class FirebaseAuthRepository implements AuthRepository {
  // Firebase instances - using late for better initialization control
  late final FirebaseAuth _firebaseAuth;
  late final GoogleSignIn? _googleSignIn;
  late final FirebaseFirestore _firestore;

  // Cache for reducing unnecessary database reads/writes
  AuthUser? _cachedUser;
  DateTime? _lastUserCheck;

  // Constants for optimizing Firebase operations
  static const Duration _userCacheDuration = Duration(minutes: 5);
  static const String _usersCollection = 'users';

  /// Creates a new FirebaseAuthRepository with optional dependencies for testing
  FirebaseAuthRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    FirebaseFirestore? firestore,
  }) {
    // Initialize Firebase Auth
    _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

    // Initialize Google Sign In only on supported platforms
    _googleSignIn = googleSignIn ??
        (kIsWeb ||
                defaultTargetPlatform == TargetPlatform.android ||
                defaultTargetPlatform == TargetPlatform.iOS
            ? GoogleSignIn()
            : null);

    // Initialize Firestore
    _firestore = firestore ?? FirebaseFirestore.instance;

    // Set up auth state listener to invalidate cache
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
        throw 'Google Sign-In is not supported on this platform';
      }

      // Start Google sign-in flow
      final googleUser = await _googleSignIn!.signIn();
      if (googleUser == null) {
        throw 'Google sign-in was cancelled';
      }

      // Get auth details from request
      final googleAuth = await googleUser.authentication;
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
            'clubRole': ''
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
            throw e;
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
        clubCount: 0,
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
      default:
        return e.message ?? 'Authentication failed';
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthExceptionToMessage(e);
    } catch (e) {
      throw 'Failed to send password reset email. Please try again.';
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
}
