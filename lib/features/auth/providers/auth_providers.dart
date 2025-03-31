import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:hive_ui/features/auth/domain/entities/auth_user.dart';
import 'package:hive_ui/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:hive_ui/services/user_preferences_service.dart';
import 'package:hive_ui/services/admin_service.dart';

/// Provider for the auth repository
/// Now uses Firebase implementation
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  // Use real Firebase implementation (now that Windows is supported)
  return FirebaseAuthRepository();
});

/// Provider for the current auth state
/// Emits the current user whenever auth state changes
final authStateProvider = StreamProvider<AuthUser>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});

/// Provider that exposes whether a user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user.isNotEmpty,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Provider that returns the current user synchronously
final currentUserProvider = Provider<AuthUser>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.getCurrentUser();
});

/// Provider for handling auth operations with proper loading and error states
/// This is a StateNotifier that manages the authentication process state
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthController(authRepository);
});

/// Provider for tracking whether onboarding is in progress
final onboardingInProgressProvider = StateProvider<bool>((ref) => false);

/// Controller class for handling authentication operations
class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;

  AuthController(this._authRepository) : super(const AsyncValue.data(null));

  /// Sign in with email and password
  Future<void> signInWithEmailPassword(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signInWithEmailPassword(email, password);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Create a new account with email and password
  Future<void> createUserWithEmailPassword(
      String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.createUserWithEmailPassword(email, password);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signInWithGoogle();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      // Clear admin status cache before signing out
      AdminService.clearCachedStatus();

      await _authRepository.signOut();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.sendPasswordResetEmail(email);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Send email verification to current user
  Future<void> sendEmailVerification() async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.sendEmailVerification();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Check if current user's email is verified
  Future<bool> checkEmailVerified() async {
    try {
      return await _authRepository.checkEmailVerified();
    } catch (e) {
      debugPrint('Error checking email verification: $e');
      return false;
    }
  }

  /// Update user profile when email is verified
  Future<void> updateEmailVerificationStatus() async {
    try {
      await _authRepository.updateEmailVerificationStatus();
    } catch (e) {
      debugPrint('Error updating email verification status: $e');
    }
  }

  /// Handle abandoned onboarding by signing out and cleaning up user data
  Future<void> abandonOnboarding() async {
    state = const AsyncValue.loading();
    try {
      // Make sure to clear shared preferences first
      await UserPreferencesService.clearUserData();

      // Then sign out from Firebase
      await _authRepository.signOut();

      debugPrint(
          'User abandoned onboarding - auth state and user data cleared');
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      debugPrint('Error during onboarding abandonment: $e');
      state = AsyncValue.error(e, stack);
      // Don't rethrow - we want to fail silently if possible when abandoning
    }
  }
}
