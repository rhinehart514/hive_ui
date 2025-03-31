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
}
