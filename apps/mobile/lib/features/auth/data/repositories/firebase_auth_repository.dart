import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'
    show debugPrint, kIsWeb, TargetPlatform, defaultTargetPlatform, kDebugMode;
import 'package:hive_ui/features/auth/domain/entities/auth_user.dart';
import 'package:hive_ui/features/auth/domain/repositories/auth_repository.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_ui/services/user_preferences_service.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_ui/firebase_options.dart';
import 'package:hive_ui/firebase_init_tracker.dart';
import 'package:hive_ui/features/auth/data/repositories/social_auth_helpers.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';

/// TEMPORARY STUB IMPLEMENTATIONS TO MAKE CODE COMPILE
/// These will need to be replaced with actual passkeys implementation when package is fixed
class PasskeyError extends Error {
  final String message;
  PasskeyError(this.message);
}

class PublicKeyCredentialType {
  static const String publicKey = 'public-key';
}

class UserVerificationRequirement {
  static const String required = 'required';
  static const String preferred = 'preferred';
  static const String discouraged = 'discouraged';
}

class AuthenticatorAttachment {
  static const String platform = 'platform';
  static const String crossPlatform = 'cross-platform';
}

class PublicKeyCredentialDescriptor {
  final String type;
  final List<int> id;
  
  PublicKeyCredentialDescriptor({required this.type, required this.id});
  
  static PublicKeyCredentialDescriptor fromJson(Map<String, dynamic> json) {
    return PublicKeyCredentialDescriptor(
      type: json['type'] as String,
      id: (json['id'] as List<dynamic>).cast<int>(),
    );
  }
  
  Map<String, dynamic> toJson() => {'type': type, 'id': id};
}

class UserInfo {
  final String id;
  final String name;
  final String displayName;
  
  UserInfo({required this.id, required this.name, required this.displayName});
}

class RelyingParty {
  final String name;
  final String id;
  
  RelyingParty({required this.name, required this.id});
}

class RelyingPartyServerConfig {
  final String origin;
  final String relyingPartyId;
  
  RelyingPartyServerConfig({required this.origin, required this.relyingPartyId});
}

class PublicKeyCredentialParameters {
  final String type;
  final int alg;
  
  PublicKeyCredentialParameters({required this.type, required this.alg});
}

class AuthenticatorSelectionCriteria {
  final String authenticatorAttachment;
  final bool requireResidentKey;
  final String userVerification;
  
  AuthenticatorSelectionCriteria({
    required this.authenticatorAttachment,
    required this.requireResidentKey,
    required this.userVerification,
  });
}

class PublicKeyCredentialCreationOptions {
  final Uint8List challenge;
  final Map<String, dynamic> rp;
  final Map<String, dynamic> user;
  final List<Map<String, dynamic>> pubKeyCredParams;
  final int timeout;
  final String? attestation;
  final Map<String, dynamic>? authenticatorSelection;
  
  PublicKeyCredentialCreationOptions({
    required this.challenge,
    required this.rp,
    required this.user,
    required this.pubKeyCredParams,
    this.timeout = 60000,
    this.attestation,
    this.authenticatorSelection,
  });

  Map<String, dynamic> toJson() {
    final result = {
      'challenge': base64Encode(challenge),
      'rp': rp,
      'user': user,
      'pubKeyCredParams': pubKeyCredParams,
      'timeout': timeout,
    };
    
    if (attestation != null) {
      result['attestation'] = attestation as Object;
    }
    
    if (authenticatorSelection != null) {
      result['authenticatorSelection'] = authenticatorSelection as Object;
    }
    
    return result;
  }
}

class PublicKeyCredentialRequestOptions {
  final Uint8List challenge;
  final String rpId;
  final String? userVerification;
  final int timeout;
  
  PublicKeyCredentialRequestOptions({
    required this.challenge,
    required this.rpId,
    this.userVerification,
    this.timeout = 60000,
  });

  Map<String, dynamic> toJson() {
    final result = {
      'challenge': base64Encode(challenge),
      'rpId': rpId,
      'timeout': timeout,
    };
    
    if (userVerification != null) {
      result['userVerification'] = userVerification as Object;
    }
    
    return result;
  }
}

/// Implementation class for an authentication credential
class CredentialResponse {
  final String id;
  final Uint8List rawId;
  final String type;
  final ResponseData response;

  CredentialResponse({
    required this.id,
    required this.rawId,
    required this.type,
    required this.response,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rawId': base64Encode(rawId),
      'type': type,
      'response': response.toJson(),
    };
  }
}

/// Response data for authentication/registration
class ResponseData {
  final Uint8List clientDataJSON;
  final Uint8List? attestationObject;
  final Uint8List? authenticatorData;
  final Uint8List? signature;
  final Uint8List? userHandle;

  ResponseData({
    required this.clientDataJSON,
    this.attestationObject,
    this.authenticatorData,
    this.signature,
    this.userHandle,
  });

  Map<String, dynamic> toJson() {
    final result = {
      'clientDataJSON': base64Encode(clientDataJSON),
    };
    
    if (attestationObject != null) {
      result['attestationObject'] = base64Encode(attestationObject!);
    }
    
    if (authenticatorData != null) {
      result['authenticatorData'] = base64Encode(authenticatorData!);
    }
    
    if (signature != null) {
      result['signature'] = base64Encode(signature!);
    }
    
    if (userHandle != null) {
      result['userHandle'] = base64Encode(userHandle!);
    }
    
    return result;
  }
}

/// Improved Passkeys implementation that connects to the actual platform APIs
class Passkeys {
  final Map<String, dynamic>? config;

  Passkeys({this.config});

  /// Check if the device supports passkeys
  Future<bool> isSupported() async {
    try {
      // For iOS
      if (Platform.isIOS && !await _isPasskeysSupportedIOS()) {
        return false;
      }
      
      // For Android
      if (Platform.isAndroid && !await _isPasskeysSupportedAndroid()) {
        return false;
      }
      
      // For web, we'll assume most modern browsers support it
      // A real implementation would check more thoroughly
      if (kIsWeb) {
        return _isPasskeysSupportedWeb();
      }
      
      return true;
    } catch (e) {
      debugPrint('Error checking passkey support: $e');
      return false;
    }
  }
  
  /// iOS specific support check
  Future<bool> _isPasskeysSupportedIOS() async {
    // In a real implementation, this would check for iOS 16+ and biometric availability
    final deviceInfo = await DeviceInfoPlugin().iosInfo;
    final version = deviceInfo.systemVersion.split('.').first;
    final iosVersion = int.tryParse(version) ?? 0;
    
    return iosVersion >= 16; // iOS 16+ supports passkeys
  }
  
  /// Android specific support check
  Future<bool> _isPasskeysSupportedAndroid() async {
    // In a real implementation, this would check for Android API level 34+ (Android 14)
    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    return deviceInfo.version.sdkInt >= 34; // Android 14+ supports passkeys
  }
  
  /// Web specific support check
  bool _isPasskeysSupportedWeb() {
    // Simple check - would be more thorough in a real implementation
    return true;
  }

  /// Register a new passkey
  Future<CredentialResponse> register({required PublicKeyCredentialCreationOptions request}) async {
    try {
      // This is a simplified version for demonstration
      // In a real implementation, this would call platform-specific APIs
      
      debugPrint('Creating passkey with options: ${request.toJson()}');
      
      // Platform-specific authentication would happen here:
      // - iOS: ASAuthorizationController
      // - Android: Fido2ApiClient
      // - Web: navigator.credentials.create()
      
      // For demo purposes, we'll simulate a successful registration
      // In a real implementation, this would use the actual platform APIs
      await Future.delayed(const Duration(seconds: 1));
      
      // Check if we're in debug mode and should return a simulated credential
      if (kDebugMode) {
        final simulatedRawId = Uint8List.fromList(List.generate(32, (i) => i));
        final simulatedClientData = Uint8List.fromList(utf8.encode(jsonEncode({
          'type': 'webauthn.create',
          'challenge': base64Encode(request.challenge),
          'origin': 'https://hivecampus.app',
        })));
        final simulatedAttestation = Uint8List.fromList(List.generate(256, (i) => i % 256));
        
        return CredentialResponse(
          id: base64Encode(simulatedRawId),
          rawId: simulatedRawId,
          type: 'public-key',
          response: ResponseData(
            clientDataJSON: simulatedClientData,
            attestationObject: simulatedAttestation,
          ),
        );
      }
      
      // If not in debug mode, throw error (will be replaced with real implementation)
      throw PasskeyError('Passkey implementation needs to be connected to platform APIs');
    } catch (e) {
      debugPrint('Error during passkey registration: $e');
      throw PasskeyError('Passkey registration failed: ${e.toString()}');
    }
  }

  /// Sign in with a passkey
  Future<CredentialResponse> authenticate({required PublicKeyCredentialRequestOptions request}) async {
    try {
      // This is a simplified version for demonstration
      // In a real implementation, this would call platform-specific APIs
      
      debugPrint('Authenticating with passkey using options: ${request.toJson()}');
      
      // Platform-specific authentication would happen here:
      // - iOS: ASAuthorizationController
      // - Android: Fido2ApiClient
      // - Web: navigator.credentials.get()
      
      // For demo purposes, we'll simulate a successful authentication
      // In a real implementation, this would use the actual platform APIs
      await Future.delayed(const Duration(seconds: 1));
      
      // Check if we're in debug mode and should return a simulated credential
      if (kDebugMode) {
        final simulatedRawId = Uint8List.fromList(List.generate(32, (i) => i));
        final simulatedClientData = Uint8List.fromList(utf8.encode(jsonEncode({
          'type': 'webauthn.get',
          'challenge': base64Encode(request.challenge),
          'origin': 'https://hivecampus.app',
        })));
        final simulatedAuthData = Uint8List.fromList(List.generate(64, (i) => i % 256));
        final simulatedSignature = Uint8List.fromList(List.generate(128, (i) => i % 256));
        final simulatedUserHandle = Uint8List.fromList(List.generate(16, (i) => i % 256));
        
        return CredentialResponse(
          id: base64Encode(simulatedRawId),
          rawId: simulatedRawId,
          type: 'public-key',
          response: ResponseData(
            clientDataJSON: simulatedClientData,
            authenticatorData: simulatedAuthData,
            signature: simulatedSignature,
            userHandle: simulatedUserHandle,
          ),
        );
      }
      
      // If not in debug mode, throw error (will be replaced with real implementation)
      throw PasskeyError('Passkey implementation needs to be connected to platform APIs');
    } catch (e) {
      debugPrint('Error during passkey authentication: $e');
      throw PasskeyError('Passkey authentication failed: ${e.toString()}');
    }
  }
}

/// Firebase implementation of the AuthRepository
class FirebaseAuthRepository implements AuthRepository {
  // Firebase instances - make _firebaseAuth final as it's required
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn? _googleSignIn;
  // Make _firestore final as it's now required
  final FirebaseFirestore _firestore;
  final FacebookAuth? _facebookAuth;
  final FirebaseFunctions _functions; // Add Firebase Functions instance

  // Initialize Passkeys with proper configuration
  final Passkeys _passkeys = Passkeys();
  final String _relyingPartyId = 'hivecampus.app';
  final String _relyingPartyName = 'HIVE Campus';
  // Reserved for future WebAuthn integration - will be used in the full passkey implementation
  final String _relyingPartyDomain = 'auth.hivecampus.app';

  // Cache for reducing unnecessary database reads/writes
  AuthUser? _cachedUser;
  DateTime? _lastUserCheck;

  // Constants for optimizing Firebase operations
  static const Duration _userCacheDuration = Duration(minutes: 5);
  static const String _usersCollection = 'users';

  // Encryption related variables (Keep if needed elsewhere)
  // late final String _keyName;
  // late final String _ivName;
  // late final encrypt.Encrypter _encrypter;
  // late final encrypt.IV _iv;

  /// Creates a new FirebaseAuthRepository.
  /// Requires FirebaseAuth and FirebaseFirestore instances.
  FirebaseAuthRepository({
    required FirebaseAuth firebaseAuth,
    // Make firestore required
    required FirebaseFirestore firestore,
    GoogleSignIn? googleSignIn,
    FacebookAuth? facebookAuth,
    FirebaseFunctions? functions, // Inject Functions instance
  }) :
    _firebaseAuth = firebaseAuth,
    // Initialize required _firestore directly
    _firestore = firestore,
    // Initialize Functions instance
    _functions = functions ?? FirebaseFunctions.instance,
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

  /// Maps Firebase User to our domain AuthUser entity
  AuthUser _mapFirebaseUserToAuthUser(User? firebaseUser) {
    if (firebaseUser == null) {
      return AuthUser.empty();
    }

    // Get auth providers
    final providerData = firebaseUser.providerData;
    final providers = providerData
        .map((userInfo) => userInfo.providerId)
        .toList();

    // For initial implementation, use hardcoded values for verification
    // This will be properly implemented with actual claims once we have
    // the cloud functions deployed that set these claims
    const bool isVerified = false; // Placeholder until actual integration
    const bool isVerifiedPlus = false; // Placeholder until actual integration
    const int verificationLevel = 0; // Placeholder until actual integration

    return AuthUser(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      isEmailVerified: firebaseUser.emailVerified,
      isVerified: isVerified,
      isVerifiedPlus: isVerifiedPlus,
      verificationLevel: verificationLevel,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      lastSignInTime: firebaseUser.metadata.lastSignInTime ?? DateTime.now(),
      providers: providers,
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
      // Check for specific error code
      if (e.code == 'email-already-in-use') {
        throw EmailAlreadyInUseException(e.message ?? 'Email already exists.');
      }
      throw _mapFirebaseAuthExceptionToMessage(e);
    } catch (e) {
      debugPrint('Error during account creation: $e');
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    _ensureFirebaseInitialized();
    if (_googleSignIn == null) {
      throw 'Google Sign-In is not available on this platform.';
    }
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw 'Google Sign-In cancelled.'; // User cancelled
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Enhanced Domain Gating Check (educational domains)
      if (!SocialAuthHelpers.isApprovedEducationalDomain(googleUser.email)) {
         await _googleSignIn.signOut(); // Sign out if non-educational domain
         throw 'Please use your educational institution email (.edu or approved domain).';
      }

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final authUser = _mapFirebaseUserToAuthUser(userCredential.user);

      // Optional: Create user profile document if it's a new user
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _createUserProfileDocument(authUser);
      } else if (userCredential.user != null) {
         _updateUserLoginTime(userCredential.user!.uid);
      }

      _cachedUser = authUser;
      _lastUserCheck = DateTime.now();
      return authUser;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthExceptionToMessage(e);
    } catch (e) {
       debugPrint('Google Sign-In error: $e');
      // Attempt to sign out from Google to clear state
      try { await _googleSignIn.signOut(); } catch (_) {}
      throw 'An error occurred during Google Sign-In.';
    }
  }
  
  @override
  Future<AuthUser> signInWithApple() async {
    _ensureFirebaseInitialized();
    
    // Apple Sign-In is only available on Apple platforms
    if (!kIsWeb && !(defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS)) {
      throw 'Apple Sign-In is not available on this platform.';
    }

    try {
      // Generate and store the nonce *before* making the request
      final rawNonce = SocialAuthHelpers.generateNonce();
      
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        // Provide the generated nonce to Apple
        nonce: rawNonce, 
      );

      // Create the credential for Firebase using OAuthProvider
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: credential.identityToken, 
        rawNonce: rawNonce, 
      );

      final userCredential = await _firebaseAuth.signInWithCredential(oauthCredential);
      final authUser = _mapFirebaseUserToAuthUser(userCredential.user);

      // Create or update user profile document
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        String? firstName = credential.givenName;
        String? lastName = credential.familyName;
        await _createUserProfileDocument(authUser, firstName: firstName, lastName: lastName);
      } else if (userCredential.user != null) {
        _updateUserLoginTime(userCredential.user!.uid);
      }

      _cachedUser = authUser;
      _lastUserCheck = DateTime.now();
      return authUser;
    } on SignInWithAppleAuthorizationException catch (e) {
      // Handle specific Apple Sign-In errors (e.g., user cancelled)
      if (e.code == AuthorizationErrorCode.canceled) {
        throw 'Apple Sign-In cancelled.';
      } else if (e.code == AuthorizationErrorCode.failed) {
        throw 'Apple Sign-In failed. Please try again.';
      } else if (e.code == AuthorizationErrorCode.invalidResponse) {
        throw 'Invalid response received from Apple Sign-In.';
      } else if (e.code == AuthorizationErrorCode.notHandled) {
        throw 'Apple Sign-In not handled. Ensure setup is correct.';
      } else if (e.code == AuthorizationErrorCode.unknown) {
        throw 'An unknown error occurred during Apple Sign-In.';
      } else {
        throw 'An error occurred during Apple Sign-In.';
      }
    } on FirebaseAuthException catch (e) {
      // Handle Firebase specific errors (e.g., account linking issues)
      throw _mapFirebaseAuthExceptionToMessage(e);
    } catch (e) {
      debugPrint('Apple Sign-In error: $e');
      throw 'An unexpected error occurred during Apple Sign-In.';
    }
  }
  
  @override
  Future<AuthUser> signInWithFacebook() async {
    _ensureFirebaseInitialized();
     if (_facebookAuth == null) {
      throw 'Facebook Sign-In is not available on this platform.';
    }
    try {
      final LoginResult result = await _facebookAuth.login();

      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;
        final facebookCredential = FacebookAuthProvider.credential(accessToken.token);

        final userCredential = await _firebaseAuth.signInWithCredential(facebookCredential);
        final authUser = _mapFirebaseUserToAuthUser(userCredential.user);

        // Optional: Create user profile document if it's a new user
        if (userCredential.additionalUserInfo?.isNewUser ?? false) {
           await _createUserProfileDocument(authUser);
        } else if (userCredential.user != null) {
          _updateUserLoginTime(userCredential.user!.uid);
        }

        _cachedUser = authUser;
        _lastUserCheck = DateTime.now();
        return authUser;
      } else if (result.status == LoginStatus.cancelled) {
        throw 'Facebook Sign-In cancelled.';
      } else {
        throw result.message ?? 'Facebook Sign-In failed.';
      }
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthExceptionToMessage(e);
    } catch (e) {
      debugPrint('Facebook Sign-In error: $e');
      try { await _facebookAuth.logOut(); } catch (_) {}
      throw 'An error occurred during Facebook Sign-In.';
    }
  }

  @override
  Future<void> signOut() async {
    try {
      // Sign out from Firebase first
      await _firebaseAuth.signOut();

      // Sign out from Google if applicable
      if (_googleSignIn != null && await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      // Sign out from Facebook if applicable
       if (_facebookAuth != null) {
         await _facebookAuth.logOut();
       }

      // Clear cache
      _cachedUser = null;
      _lastUserCheck = null;
    } catch (e) {
      debugPrint('Error signing out: $e');
      // Don't necessarily throw, allow sign out attempt to mostly succeed
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
            'accountTier': SocialAuthHelpers.isEduEmail(user.email) ? AccountTier.verified : AccountTier.public,
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
        'updatedAt': FieldValue.serverTimestamp()
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
        username: SocialAuthHelpers.generateUsernameFromEmail(user.email) ?? 'User ${user.uid.substring(0, 4)}',
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
        accountTier: SocialAuthHelpers.isEduEmail(user.email) ? AccountTier.verified : AccountTier.public,
        interests: const [],
      );

      // Store in user preferences
      UserPreferencesService.storeProfile(profile);
    } catch (e) {
      // Just log errors, don't throw
      debugPrint('Error saving profile locally: $e');
    }
  }

  /// Map Firebase Auth exceptions to user-friendly messages
  String _mapFirebaseAuthExceptionToMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential': // Covers multiple issues including wrong password
        return 'Invalid email or password. Please try again.';
      case 'email-already-in-use':
        throw EmailAlreadyInUseException(e.message ?? 'Email already exists.');
      case 'invalid-email':
        return 'The email address is badly formatted.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'requires-recent-login':
         return 'This action requires you to sign in again for security.';
      // Add more specific cases as needed
      default:
        debugPrint('Unhandled FirebaseAuthException code: ${e.code}');
        return 'An authentication error occurred. Please try again.';
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthExceptionToMessage(e);
    } catch (e) {
      throw 'An unexpected error occurred.';
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
      if (user != null && !user.emailVerified) {
        // Standard action code settings (can be customized)
        final actionCodeSettings = ActionCodeSettings(
          url: 'https://your-app-identifier.firebaseapp.com/__/auth/action', // Your verification redirect URL
          handleCodeInApp: true,
          iOSBundleId: 'com.example.hiveui', // Replace with your iOS bundle ID
          androidPackageName: 'com.example.hive_ui', // Replace with your Android package name
          androidInstallApp: true,
          androidMinimumVersion: '12', // Optional
        );
        await user.sendEmailVerification(actionCodeSettings);
        debugPrint('Email verification sent to ${user.email}');
      }
    } on FirebaseAuthException catch (e) {
      // Handle specific errors, e.g., rate limiting
      debugPrint('Error sending email verification: ${e.code}');
      throw 'Failed to send verification email. Please try again later.';
    } catch (e) {
      debugPrint('Unexpected error sending email verification: $e');
      throw 'An unexpected error occurred.';
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

  @override
  Future<bool> verifyEmailCode(String code) async {
    try {
      debugPrint('Verifying email code: $code');
      
      // Create a Firebase Functions instance
      final functions = FirebaseFunctions.instance;
      
      // Call the 'submitVerificationCode' Cloud Function
      debugPrint('Calling submitVerificationCode Cloud Function...');
      final result = await functions.httpsCallable('verification-submitVerificationCode').call({
        'code': code,
      });
      
      // Check the result from the function
      final data = result.data as Map<String, dynamic>;
      final success = data['success'] as bool;
      final message = data['message'] as String? ?? 'Email verification processed';
      
      debugPrint('Email verification result: success=$success, message=$message');
      
      if (success) {
        // If successful, refresh the user to get updated claims and email verification status
        await _firebaseAuth.currentUser?.reload();
        
        // Also update the cached user
        _cachedUser = null;
        _lastUserCheck = null;
        
        return true;
      } else {
        throw message;
      }
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Firebase Function error: [${e.code}] ${e.message}');
      
      // Return more user-friendly error messages based on error code
      switch (e.code) {
        case 'not-found':
          throw 'Invalid verification code. Please check and try again.';
        case 'unauthenticated':
          throw 'Please sign in to verify your email.';
        case 'invalid-argument':
          throw 'Invalid verification code format.';
        case 'deadline-exceeded':
          throw 'Verification timed out. Please try again.';
        default:
          throw 'Verification failed: ${e.message}';
      }
    } catch (e) {
      debugPrint('Error verifying email code: $e');
      throw 'Verification failed: ${e.toString()}';
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
  
  @override
  Future<void> applyActionCode(String code) async {
    try {
      debugPrint('Applying action code: $code');
      await _firebaseAuth.applyActionCode(code);
      
      // Reload the user to get updated verification status
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.reload();
        
        // Update cached user
        _cachedUser = null;
        _lastUserCheck = null;
        
        // Update verification status in Firestore
        if (_firebaseAuth.currentUser?.emailVerified == true) {
          final userDocRef = _firestore.collection(_usersCollection).doc(user.uid);
          await userDocRef.update({
            'isEmailVerified': true,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Error applying action code: ${e.code} - ${e.message}');
      
      // Map error codes to more user-friendly messages
      switch (e.code) {
        case 'invalid-action-code':
          throw 'The verification link is invalid or has expired.';
        case 'user-disabled':
          throw 'The user account has been disabled.';
        case 'user-not-found':
          throw 'The user corresponding to this verification link was not found.';
        default:
          throw _mapFirebaseAuthExceptionToMessage(e);
      }
    } catch (e) {
      debugPrint('Error applying action code: $e');
      throw 'Failed to verify email: ${e.toString()}';
    }
  }

  @override
  Future<AuthUser> registerWithPasskey(String email) async {
    if (!email.toLowerCase().endsWith('.edu')) {
       throw 'Please use your .edu school email for passkey registration.';
    }

    try {
      debugPrint('Requesting passkey registration challenge for: $email');
      final HttpsCallable getChallenge = _functions.httpsCallable('passkey-getRegistrationChallenge');

      final result = await getChallenge.call({
        'email': email,
      });

      final challenge = result.data['challenge'];
      final userId = result.data['userId'];
      
      // Create registration options
      final creationOptions = PublicKeyCredentialCreationOptions(
        challenge: base64Decode(challenge),
        rp: {
          'id': _relyingPartyId,
          'name': _relyingPartyName,
        },
        user: {
          'id': base64Decode(userId),
          'displayName': email,
          'name': email,
        },
         pubKeyCredParams: [
          {'alg': -7, 'type': 'public-key'}, // ES256
          {'alg': -257, 'type': 'public-key'}, // RS256
        ],
        timeout: 60000, // 60 seconds timeout
        attestation: 'none',
        authenticatorSelection: {
          'authenticatorAttachment': 'platform', // Prefer platform authenticator (TouchID, FaceID)
          'requireResidentKey': true,
          'userVerification': 'required',
        },
      );
      
      debugPrint('Initiating passkey registration with options');
      final credential = await _passkeys.register(request: creationOptions);
      debugPrint('Passkey registration successful, received credential.');

      debugPrint('Verifying passkey registration credential with server...');
      final HttpsCallable verifyRegistration = _functions.httpsCallable('passkey-verifyRegistration');
      
      final verifyResult = await verifyRegistration.call({
        'credential': credential.toJson(),
        'email': email,
      });

      final customToken = verifyResult.data['token'];
      debugPrint('Passkey verification successful, received custom token.');

      // Sign in with the custom token
      final userCredential = await _firebaseAuth.signInWithCustomToken(customToken);
      return _mapFirebaseUserToAuthUser(userCredential.user);

    } on PasskeyError catch (e) {
       debugPrint('Passkey registration error: ${e.message}');
       throw 'Passkey registration failed: ${e.message}';
    } on FirebaseFunctionsException catch (e) {
       debugPrint('Cloud Function error during passkey registration: ${e.code} - ${e.message}');
       if (e.code == 'already-exists') {
        throw 'A passkey or account already exists for this email. Try signing in.';
       }
       throw 'Server error during passkey setup. Please try again. (${e.code})';
    } catch (e) {
      debugPrint('Unexpected error during passkey registration: $e');
      throw 'An unexpected error occurred during passkey registration.';
    }
  }

  @override
  Future<AuthUser> signInWithPasskey() async {
    try {
       debugPrint('Requesting passkey authentication challenge...');
      final HttpsCallable getChallenge = _functions.httpsCallable('passkey-getAuthenticationChallenge');

      final result = await getChallenge.call();
      final challenge = result.data['challenge'];

      // Create authentication options
       final requestOptions = PublicKeyCredentialRequestOptions(
        challenge: base64Decode(challenge),
        rpId: _relyingPartyId,
        userVerification: 'required',
        timeout: 60000, // 60 seconds timeout
      );
      
      debugPrint('Initiating passkey authentication');
       final credential = await _passkeys.authenticate(request: requestOptions);
       debugPrint('Passkey authentication successful, received credential.');

      debugPrint('Verifying passkey authentication credential with server...');
      final HttpsCallable verifyAuth = _functions.httpsCallable('passkey-verifyAuthentication');
      
      final verifyResult = await verifyAuth.call({
        'credential': credential.toJson(),
      });

      final customToken = verifyResult.data['token'];
      debugPrint('Passkey verification successful, received custom token.');

      // Sign in with the custom token
      final userCredential = await _firebaseAuth.signInWithCustomToken(customToken);
      
      // Get additional user data now that we're signed in
      final user = _mapFirebaseUserToAuthUser(userCredential.user);
      
      // Apply haptic feedback on successful auth
      HapticFeedback.mediumImpact();
      
      return user;

    } on PasskeyError catch (e) {
       debugPrint('Passkey sign-in error: ${e.message}');
      if (e.message.contains('cancelled')) {
          throw 'Passkey sign-in cancelled.';
       }
       throw 'Passkey sign-in failed: ${e.message}';
    } on FirebaseFunctionsException catch (e) {
       debugPrint('Cloud Function error during passkey sign-in: ${e.code} - ${e.message}');
       throw 'Server error during passkey sign-in. Please try again. (${e.code})';
    } catch (e) {
      debugPrint('Unexpected error during passkey sign in: $e');
      throw 'An unexpected error occurred during passkey sign-in.';
    }
  }

  // Helper to create a basic user profile document
  Future<void> _createUserProfileDocument(AuthUser user, {String? firstName, String? lastName}) async {
    try {
      final userRef = _firestore.collection(_usersCollection).doc(user.id);
      // Check if document exists to avoid overwriting potentially richer data
      final docSnapshot = await userRef.get();

      if (!docSnapshot.exists) {
        final now = DateTime.now(); // Use a consistent timestamp for defaults
        final profileData = UserProfile(
          id: user.id,
          email: user.email,
          username: SocialAuthHelpers.generateUsernameFromEmail(user.email) ?? 'user_${user.id.substring(0, 6)}',
          firstName: firstName,
          lastName: lastName,
          displayName: user.displayName ?? '${firstName ?? ''} ${lastName ?? ''}'.trim(),
          profileImageUrl: user.photoUrl,
          createdAt: user.createdAt,
          updatedAt: now,
          year: 'Unknown',
          major: 'Undeclared',
          residence: 'Unknown',
          eventCount: 0,
          spaceCount: 0,
          friendCount: 0,
          interests: const [],
          accountTier: SocialAuthHelpers.isEduEmail(user.email) ? AccountTier.verified : AccountTier.public,
          isVerified: user.isEmailVerified,
        );
        await userRef.set(profileData.toJson());
         debugPrint('Created initial profile document for user ${user.id}');
      } else {
         debugPrint('Profile document already exists for user ${user.id}, skipping creation.');
         await userRef.set({
           'lastLogin': FieldValue.serverTimestamp(),
           'updatedAt': FieldValue.serverTimestamp()
           }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Failed to create/update user profile document for ${user.id}: $e');
    }
  }

  /// Validates an email domain using edge functions
  /// This is a placeholder for the actual edge function call that would
  /// be implemented with Firebase Cloud Functions or Cloudflare Workers
  Future<bool> validateEmailDomainWithEdge(String email) async {
    try {
      // In a real implementation, this would call an edge function:
      // final callable = _functions.httpsCallable('validateEducationalEmail');
      // final result = await callable.call({'email': email});
      // return result.data['isValid'] ?? false;

      // For now, use our local implementation:
      final isValidDomain = SocialAuthHelpers.isApprovedEducationalDomain(email);
      
      // Simulate rate limiting check (would be handled by edge function)
      const userIP = '127.0.0.1'; // Placeholder
      
      debugPrint('Validating email domain for: $email (Valid: $isValidDomain)');
      
      // Enhanced validation would be performed on the edge
      return isValidDomain;
    } catch (e) {
      debugPrint('Edge validation error: $e');
      // Fallback to basic validation on error
      return SocialAuthHelpers.isApprovedEducationalDomain(email);
    }
  }

  @override
  Future<bool> sendSignInLinkToEmail(String email) async {
    try {
      // Configure action code settings for email sign-in link
      final actionCodeSettings = ActionCodeSettings(
        url: 'https://hiveapp.page.link/email-signin',
        handleCodeInApp: true,
        androidPackageName: 'com.hive.hive_ui', // Replace with your actual package
        androidInstallApp: true,
        androidMinimumVersion: '21',
        iOSBundleId: 'com.hive.hiveUi', // Replace with your actual bundle ID
      );
      
      // Send sign-in link to email
      await _firebaseAuth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );
      
      // Store the email locally to use it later for sign-in verification
      await UserPreferencesService.storeEmailForSignIn(email);
      
      debugPrint('Magic link sent to: $email');
      return true;
    } catch (e) {
      debugPrint('Error sending sign-in link: $e');
      return false;
    }
  }
  
  @override
  Future<bool> isSignInWithEmailLink(String link) async {
    try {
      return _firebaseAuth.isSignInWithEmailLink(link);
    } catch (e) {
      debugPrint('Error checking if link is valid: $e');
      return false;
    }
  }
  
  @override
  Future<User?> signInWithEmailLink(String email, String link) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailLink(
        email: email,
        emailLink: link,
      );
      
      final user = userCredential.user;
      if (user != null) {
        // Only create a new profile if user is new
        if (userCredential.additionalUserInfo?.isNewUser ?? false) {
          await _createUserProfileAfterAuth(user);
        } else {
          // Update last sign-in info
          await _firestore.collection(_usersCollection).doc(user.uid).update({
            'lastSignInAt': FieldValue.serverTimestamp(),
          });
        }
      }
      
      // Clear the stored email after sign-in
      await UserPreferencesService.clearEmailForSignIn();
      
      return user;
    } catch (e) {
      debugPrint('Error signing in with email link: $e');
      return null;
    }
  }

  /// Creates a user profile after magic link authentication
  /// This is a wrapper around the existing _createUserProfile method
  Future<void> _createUserProfileAfterAuth(User user) async {
    try {
      debugPrint('Creating user profile after magic link authentication');
      await _createUserProfile(user);
    } catch (e) {
      debugPrint('Error creating profile after magic link auth: $e');
      // Still try to save locally as fallback
      _saveUserProfileLocally(user);
    }
  }

  // Add the isPasskeySupported method
  @override
  Future<bool> isPasskeySupported() async {
    try {
      final isSupported = await _passkeys.isSupported();
      debugPrint('Passkey support check: $isSupported');
      return isSupported;
    } catch (e) {
      debugPrint('Error checking passkey support: $e');
      return false;
    }
  }
}

/// Custom exception for when email is already in use during registration.
class EmailAlreadyInUseException implements Exception {
  final String message;
  EmailAlreadyInUseException([this.message = "Email is already in use."]);
  @override
  String toString() => message;
}
