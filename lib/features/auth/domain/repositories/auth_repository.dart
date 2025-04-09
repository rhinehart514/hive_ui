import 'package:hive_ui/features/auth/domain/entities/auth_user.dart';

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
}
