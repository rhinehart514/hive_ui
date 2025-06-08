import 'package:hive_ui/core/result/result.dart';
import 'package:hive_ui/data/datasources/firebase_auth_datasource.dart';
import 'package:hive_ui/domain/entities/auth_challenge.dart';
import 'package:hive_ui/domain/failures/auth_failure.dart';

/// Service for handling authentication-related operations.
class AuthService {
  final AuthDataSource _authDataSource;

  /// Creates a new instance with the given dependencies.
  AuthService(this._authDataSource);

  /// Requests a magic link to be sent to the provided email.
  ///
  /// Returns a [Result] containing either the email or a [Failure].
  Future<Result<String, Failure>> requestMagicLink(String email) async {
    // Normalize email by trimming and converting to lowercase
    final normalizedEmail = email.trim().toLowerCase();
    
    return _authDataSource.requestMagicLink(normalizedEmail);
  }

  /// Verifies a magic link token and signs the user in.
  ///
  /// Returns a [Result] containing either the user ID or a [Failure].
  Future<Result<String, Failure>> verifyMagicLink(String token) async {
    return _authDataSource.verifyMagicLink(token);
  }

  /// Signs out the current user.
  ///
  /// Returns a [Result] indicating success or failure.
  Future<Result<void, Failure>> signOut() async {
    return _authDataSource.signOut();
  }

  /// Creates an [AuthChallenge] for the given email.
  ///
  /// This generates a new challenge with pending status and proper expiry time.
  AuthChallenge createAuthChallenge(String email) {
    return AuthChallenge.create(email);
  }
} 