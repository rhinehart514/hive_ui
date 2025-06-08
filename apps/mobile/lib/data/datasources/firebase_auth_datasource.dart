import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:hive_ui/core/result/result.dart';
import 'package:hive_ui/domain/failures/auth_failure.dart';

/// Abstract interface for authentication data sources.
abstract class AuthDataSource {
  /// Requests a magic link to be sent to the provided email.
  Future<Result<String, Failure>> requestMagicLink(String email);

  /// Verifies the magic link token and signs the user in.
  Future<Result<String, Failure>> verifyMagicLink(String token);

  /// Signs out the current user.
  Future<Result<void, Failure>> signOut();
}

/// Firebase implementation of [AuthDataSource].
class FirebaseAuthDataSource implements AuthDataSource {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final String _actionCodeSettings;
  final List<String> _allowedDomains;

  /// The regex pattern for validating email addresses.
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Creates a new instance with the given dependencies.
  ///
  /// [firebaseAuth] - The Firebase Auth instance to use.
  /// [actionCodeSettings] - The Firebase dynamic link settings for magic links.
  /// [allowedDomains] - List of domains that are allowed to sign in (e.g., ["buffalo.edu"]).
  FirebaseAuthDataSource(
    this._firebaseAuth,
    this._actionCodeSettings,
    this._allowedDomains,
  );

  @override
  Future<Result<String, Failure>> requestMagicLink(String email) async {
    try {
      // Validate email format
      if (!_isValidEmail(email)) {
        return const Result.left(
          InvalidEmailFailure('Please enter a valid email address.'),
        );
      }

      // Verify email domain is allowed
      if (!_isAllowedDomain(email)) {
        return const Result.left(
          InvalidEmailFailure(
            'Only emails from approved institutions are allowed.',
          ),
        );
      }

      // Send the email link
      await _firebaseAuth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: firebase_auth.ActionCodeSettings(
          url: _actionCodeSettings,
          handleCodeInApp: true,
          androidPackageName: 'com.hive.app',
          androidInstallApp: true,
          androidMinimumVersion: '21',
          iOSBundleId: 'com.hive.app',
        ),
      );

      return Result.right(email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Result.left(_mapFirebaseException(e));
    } catch (e) {
      return Result.left(UnknownFailure('Failed to send magic link: ${e.toString()}'));
    }
  }

  @override
  Future<Result<String, Failure>> verifyMagicLink(String token) async {
    try {
      // Check if link is valid
      final isValidLink = _firebaseAuth.isSignInWithEmailLink(token);
      if (!isValidLink) {
        return const Result.left(
          ExpiredLinkFailure('The link is invalid or has expired.'),
        );
      }

      // Get email from local storage (in production, this would be persisted)
      // For simplicity, we assume it's part of the token for this example
      final email = _extractEmailFromToken(token);
      if (email == null) {
        return const Result.left(
          InvalidEmailFailure('Email not found in the link.'),
        );
      }

      // Sign in with the email link
      final userCredential = await _firebaseAuth.signInWithEmailLink(
        email: email,
        emailLink: token,
      );

      if (userCredential.user == null) {
        return const Result.left(
          ServerFailure('Failed to authenticate with the provided link.'),
        );
      }

      return Result.right(userCredential.user!.uid);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Result.left(_mapFirebaseException(e));
    } catch (e) {
      return Result.left(
        UnknownFailure('Failed to verify magic link: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void, Failure>> signOut() async {
    try {
      await _firebaseAuth.signOut();
      return const Result.right(null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Result.left(_mapFirebaseException(e));
    } catch (e) {
      return Result.left(UnknownFailure('Failed to sign out: ${e.toString()}'));
    }
  }

  /// Validates if the email format is correct.
  bool _isValidEmail(String email) {
    return email.isNotEmpty && _emailRegex.hasMatch(email);
  }

  /// Checks if the email domain is in the allowed list.
  bool _isAllowedDomain(String email) {
    final domain = email.split('@').last.toLowerCase();
    return _allowedDomains.contains(domain);
  }

  /// Extracts the email from the token for verification.
  /// 
  /// Note: In a real implementation, the email would be stored locally
  /// when requesting the magic link, and retrieved here.
  String? _extractEmailFromToken(String token) {
    // This is a placeholder implementation
    // In production, email would be retrieved from secure storage
    final emailParam = Uri.parse(token).queryParameters['email'];
    return emailParam;
  }

  /// Maps Firebase exceptions to domain-specific failures.
  Failure _mapFirebaseException(firebase_auth.FirebaseAuthException exception) {
    switch (exception.code) {
      case 'invalid-email':
        return const InvalidEmailFailure(
          'The email address is not valid.',
        );
      case 'user-disabled':
        return const AuthFailure(
          'This account has been disabled. Please contact support.',
        );
      case 'operation-not-allowed':
        return const ServerFailure(
          'This operation is not allowed.',
        );
      case 'expired-action-code':
      case 'invalid-action-code':
        return const ExpiredLinkFailure(
          'The magic link has expired or is invalid. Please request a new one.',
        );
      case 'network-request-failed':
        return const NetworkFailure(
          'A network error occurred. Please check your connection and try again.',
        );
      default:
        return ServerFailure(
          'An error occurred: ${exception.message ?? exception.code}',
        );
    }
  }
}

/// Abstract base class for all authentication failures.
class AuthFailure extends Failure {
  /// Creates a new authentication failure with the given message.
  const AuthFailure(String message) : super(message);
} 