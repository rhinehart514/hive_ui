import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:hive_ui/features/auth/domain/entities/auth_user.dart';
import 'package:hive_ui/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint, TargetPlatform, defaultTargetPlatform;
import 'package:hive_ui/services/user_preferences_service.dart';
import 'package:hive_ui/services/admin_service.dart';
import 'package:hive_ui/core/providers/auth_provider.dart';
import 'package:hive_ui/features/auth/providers/new_onboarding_providers.dart' hide firebaseAuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_ui/firebase_options.dart';
import 'package:hive_ui/firebase_init_tracker.dart';
import 'package:hive_ui/main.dart' show firebaseInitializationProvider, appInitializationProvider;
import 'package:hive_ui/features/auth/providers/platform_auth_provider.dart';

// Add this at the top of the file with other imports
export 'user_preferences_provider.dart';

/// Provider for the auth repository
/// Uses a safe initialization approach that waits for Firebase to be ready
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  // Listen to app initialization (this creates a dependency)
  final appInitialized = ref.watch(appInitializationProvider);
  
  // Return a placeholder repository during initialization
  return appInitialized.when(
    data: (_) {
      // Check if we're on Windows first
      if (defaultTargetPlatform == TargetPlatform.windows) {
        debugPrint('Windows platform detected, using Windows auth repository');
        return ref.watch(platformAuthRepositoryProvider);
      }
      
      // For other platforms, proceed with Firebase initialization check
      if (Firebase.apps.isEmpty && !FirebaseInitTracker.isInitialized) {
        debugPrint('WARNING: Firebase not ready but auth repository requested. Using placeholder.');
        return _PlaceholderAuthRepository();
      }
      
      // Firebase is ready, return the real repository
      FirebaseInitTracker.isInitialized = true;
      FirebaseInitTracker.needsInitialization = false;
      
      final firebaseAuthInstance = ref.watch(firebaseAuthProvider);
      final firestoreInstance = ref.watch(firestoreProvider);
      
      return FirebaseAuthRepository(
        firebaseAuth: firebaseAuthInstance,
        firestore: firestoreInstance,
      );
    },
    loading: () {
      debugPrint('App still initializing but auth repository requested. Using placeholder.');
      return _PlaceholderAuthRepository();
    },
    error: (error, _) {
      debugPrint('App initialization error but auth repository requested: $error');
      return _PlaceholderAuthRepository();
    },
  );
});

/// Placeholder implementation that handles pre-initialization access safely
class _PlaceholderAuthRepository implements AuthRepository {
  @override
  Stream<AuthUser> get authStateChanges => Stream.value(AuthUser.empty());

  @override
  Future<bool> checkEmailVerified() async => false;

  @override
  Future<AuthUser> createUserWithEmailPassword(String email, String password) async {
    throw 'Firebase not yet initialized. Wait for app to finish initializing.';
  }

  @override
  AuthUser getCurrentUser() => AuthUser.empty();

  @override
  Future<List<String>> getAvailableSignInMethods(String email) async => [];

  @override
  Future<void> linkEmailPassword(String email, String password) async {
    throw 'Firebase not yet initialized. Wait for app to finish initializing.';
  }

  @override
  Future<void> sendEmailVerification() async {
    throw 'Firebase not yet initialized. Wait for app to finish initializing.';
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    throw 'Firebase not yet initialized. Wait for app to finish initializing.';
  }

  @override
  Future<AuthUser> signInWithApple() async {
    throw 'Firebase not yet initialized. Wait for app to finish initializing.';
  }

  @override
  Future<AuthUser> signInWithEmailPassword(String email, String password) async {
    throw 'Firebase not yet initialized. Wait for app to finish initializing.';
  }

  @override
  Future<AuthUser> signInWithFacebook() async {
    throw 'Firebase not yet initialized. Wait for app to finish initializing.';
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    throw 'Firebase not yet initialized. Wait for app to finish initializing.';
  }

  @override
  Future<void> signOut() async {
    // No-op, we're not signed in
  }

  @override
  Future<void> updateEmailVerificationStatus() async {
    // No-op
  }

  @override
  Future<bool> checkIfUserExists(String email) async => false;
}

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

/// Provider for available sign-in methods for a given email
final availableSignInMethodsProvider = 
    FutureProvider.family<List<String>, String>((ref, email) async {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.getAvailableSignInMethods(email);
});

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
  
  /// Sign in with Apple
  Future<void> signInWithApple() async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signInWithApple();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
  
  /// Sign in with Facebook
  Future<void> signInWithFacebook() async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signInWithFacebook();
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
  
  /// Get available sign-in methods for a given email
  Future<List<String>> getAvailableSignInMethods(String email) async {
    try {
      return await _authRepository.getAvailableSignInMethods(email);
    } catch (e) {
      debugPrint('Error getting sign-in methods: $e');
      return [];
    }
  }
  
  /// Link email/password to an existing account
  Future<void> linkEmailPassword(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.linkEmailPassword(email, password);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
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
