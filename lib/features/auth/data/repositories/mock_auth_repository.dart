import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/features/auth/domain/entities/auth_user.dart';
import 'package:hive_ui/features/auth/domain/repositories/auth_repository.dart';

/// Mock implementation of AuthRepository for development and testing
/// This will be replaced with a Firebase implementation later
class MockAuthRepository implements AuthRepository {
  /// Stream controller for authentication state changes
  final StreamController<AuthUser> _authStateController =
      StreamController<AuthUser>.broadcast();

  /// Current mock authenticated user
  AuthUser _currentUser = AuthUser.empty();

  /// Mock user database for testing
  final Map<String, _MockUserCredential> _users = {};

  /// Whether to simulate network delays
  final bool simulateNetworkDelay;

  /// Duration of simulated network delay
  final Duration networkDelay;

  /// Creates a MockAuthRepository
  MockAuthRepository({
    this.simulateNetworkDelay = true,
    this.networkDelay = const Duration(milliseconds: 1000),
  });

  @override
  AuthUser getCurrentUser() {
    return _currentUser;
  }

  @override
  Stream<AuthUser> get authStateChanges => _authStateController.stream;

  @override
  Future<AuthUser> signInWithEmailPassword(
      String email, String password) async {
    // Simulate network delay
    if (simulateNetworkDelay) {
      await Future.delayed(networkDelay);
    }

    final normalizedEmail = email.toLowerCase().trim();

    // Check if user exists
    if (!_users.containsKey(normalizedEmail)) {
      throw AuthException('User not found');
    }

    // Check password
    final userCredential = _users[normalizedEmail]!;
    if (userCredential.password != password) {
      throw AuthException('Invalid password');
    }

    // Update current user
    _currentUser = userCredential.user;
    _authStateController.add(_currentUser);

    return _currentUser;
  }

  @override
  Future<AuthUser> createUserWithEmailPassword(
      String email, String password) async {
    // Simulate network delay
    if (simulateNetworkDelay) {
      await Future.delayed(networkDelay);
    }

    final normalizedEmail = email.toLowerCase().trim();

    // Check if user already exists
    if (_users.containsKey(normalizedEmail)) {
      throw AuthException('Email already in use');
    }

    // Create new user
    final now = DateTime.now();
    final user = AuthUser(
      id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
      email: normalizedEmail,
      isEmailVerified: false,
      createdAt: now,
      lastSignInTime: now,
    );

    // Store user credentials
    _users[normalizedEmail] = _MockUserCredential(user, password);

    // Update current user
    _currentUser = user;
    _authStateController.add(_currentUser);

    return _currentUser;
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    // Simulate network delay
    if (simulateNetworkDelay) {
      await Future.delayed(networkDelay);
    }

    // Create mock Google user if not exists
    const googleEmail = 'google_user@gmail.com';
    if (!_users.containsKey(googleEmail)) {
      final now = DateTime.now();
      final user = AuthUser(
        id: 'google-${DateTime.now().millisecondsSinceEpoch}',
        email: googleEmail,
        displayName: 'Google User',
        photoUrl: 'https://ui-avatars.com/api/?name=Google+User',
        isEmailVerified: true,
        createdAt: now,
        lastSignInTime: now,
      );

      _users[googleEmail] = _MockUserCredential(user, 'google-password');
    }

    // Update current user
    _currentUser = _users[googleEmail]!.user;
    _authStateController.add(_currentUser);

    return _currentUser;
  }

  @override
  Future<void> signOut() async {
    // Simulate network delay
    if (simulateNetworkDelay) {
      await Future.delayed(networkDelay);
    }

    // Reset current user
    _currentUser = AuthUser.empty();
    _authStateController.add(_currentUser);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    // Simulate network delay
    if (simulateNetworkDelay) {
      await Future.delayed(networkDelay);
    }

    final normalizedEmail = email.toLowerCase().trim();

    // Just check if user exists
    if (!_users.containsKey(normalizedEmail)) {
      // Still return success to avoid leaking information
      debugPrint(
          'Password reset requested for non-existent user: $normalizedEmail');
      return;
    }

    debugPrint('Password reset email sent to: $normalizedEmail');
  }

  @override
  Future<bool> checkIfUserExists(String email) async {
    // Simulate network delay
    if (simulateNetworkDelay) {
      await Future.delayed(networkDelay);
    }

    final normalizedEmail = email.toLowerCase().trim();
    return _users.containsKey(normalizedEmail);
  }

  @override
  Future<void> sendEmailVerification() async {
    // Simulate network delay
    if (simulateNetworkDelay) {
      await Future.delayed(networkDelay);
    }

    if (_currentUser.isEmpty) {
      throw AuthException('No authenticated user found');
    }

    debugPrint('Mock verification email sent to: ${_currentUser.email}');
  }

  @override
  Future<bool> checkEmailVerified() async {
    // Simulate network delay
    if (simulateNetworkDelay) {
      await Future.delayed(networkDelay);
    }

    if (_currentUser.isEmpty) {
      return false;
    }

    // For mock implementation, if the email ends with '.edu', we'll say it's verified
    final isEduEmail = _currentUser.email.toLowerCase().endsWith('.edu');
    return _currentUser.isEmailVerified || isEduEmail;
  }

  @override
  Future<void> updateEmailVerificationStatus() async {
    // Simulate network delay
    if (simulateNetworkDelay) {
      await Future.delayed(networkDelay);
    }

    if (_currentUser.isEmpty) {
      return;
    }

    // Find the user in the _users map
    final userEntry = _users.entries.firstWhere(
      (entry) => entry.value.user.id == _currentUser.id,
      orElse: () => MapEntry('', _MockUserCredential(_currentUser, '')),
    );

    if (userEntry.key.isNotEmpty) {
      // Update the user to be verified if it has a .edu email
      final isEduEmail = userEntry.key.toLowerCase().endsWith('.edu');
      if (isEduEmail) {
        final updatedUser = userEntry.value.user.copyWith(
          isEmailVerified: true,
        );

        // Update the user in the map
        _users[userEntry.key] =
            _MockUserCredential(updatedUser, userEntry.value.password);

        // Update current user
        _currentUser = updatedUser;
        _authStateController.add(_currentUser);

        debugPrint('Updated verification status for: ${_currentUser.email}');
      }
    }
  }

  /// Dispose resources
  void dispose() {
    _authStateController.close();
  }
}

/// Helper class for storing mock user credentials
class _MockUserCredential {
  final AuthUser user;
  final String password;

  _MockUserCredential(this.user, this.password);
}

/// Authentication exception class
class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}
