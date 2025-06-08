import 'package:hive_ui/features/auth/domain/entities/auth_user.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Interface defining authentication operations
/// This will be implemented by a Firebase implementation later
abstract class AuthRepository {
  /// Get the current authenticated user
  /// Returns an empty user if not authenticated
  AuthUser getCurrentUser();

  /// Stream of authentication state changes
  /// Emits the current user whenever auth state changes
  Stream<AuthUser> get authStateChanges;

  /// Sign in with email and password
  /// Returns the authenticated user on success
  Future<AuthUser> signInWithEmailPassword(String email, String password);

  /// Create a new account with email and password
  /// Returns the newly created user on success
  Future<AuthUser> createUserWithEmailPassword(String email, String password);

  /// Sign in with Google account
  /// Returns the authenticated user on success
  Future<AuthUser> signInWithGoogle();
  
  /// Sign in with Apple account
  /// Returns the authenticated user on success
  Future<AuthUser> signInWithApple();
  
  /// Sign in with Facebook account
  /// Returns the authenticated user on success
  Future<AuthUser> signInWithFacebook();

  /// Register a new account using passkey (biometric) authentication
  /// Returns the authenticated user on success
  Future<AuthUser> registerWithPasskey(String email);
  
  /// Sign in using passkey (biometric) authentication
  /// Returns the authenticated user on success
  Future<AuthUser> signInWithPasskey();
  
  /// Check if the device supports passkey authentication
  /// Returns true if passkeys are supported
  Future<bool> isPasskeySupported();

  /// Sign out the current user
  Future<void> signOut();

  /// Send a password reset email to the given address
  Future<void> sendPasswordResetEmail(String email);

  /// Check if a user exists with the given email
  Future<bool> checkIfUserExists(String email);

  /// Send verification email to the current user
  Future<void> sendEmailVerification();

  /// Check if the current user's email is verified
  Future<bool> checkEmailVerified();

  /// Update user profile when email is verified
  Future<void> updateEmailVerificationStatus();
  
  /// Get available sign-in methods for a given email
  /// Returns a list of provider IDs (e.g., 'password', 'google.com', 'apple.com')
  Future<List<String>> getAvailableSignInMethods(String email);
  
  /// Link email/password to an existing account
  /// Used when user has signed in with a social provider and wants to add password auth
  Future<void> linkEmailPassword(String email, String password);

  /// Verify email with a verification code (for code-based verification)
  /// Returns success status which can be used by the UI
  Future<bool> verifyEmailCode(String code);

  /// Applies out-of-band action codes (e.g., email verification, password reset).
  Future<void> applyActionCode(String code);

  /// Sends a sign-in link to the provided email
  /// 
  /// The link will be sent to the user's email and can be used to sign in without a password
  /// Returns true if the email was sent successfully
  Future<bool> sendSignInLinkToEmail(String email);
  
  /// Checks if the current URL is a sign-in link
  /// 
  /// Used to determine if the app was opened from a magic link email
  Future<bool> isSignInWithEmailLink(String link);
  
  /// Signs in the user using an email link
  /// 
  /// [email] is the email address that the link was sent to
  /// [link] is the URL that was opened
  /// Returns the user if sign-in was successful
  Future<User?> signInWithEmailLink(String email, String link);
}
