import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/auth/domain/repositories/auth_repository.dart';
import 'package:hive_ui/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:hive_ui/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:hive_ui/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:hive_ui/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:hive_ui/features/auth/domain/usecases/verify_email_usecase.dart';
import 'package:hive_ui/features/auth/domain/usecases/abandon_onboarding_usecase.dart';
import 'package:hive_ui/features/auth/domain/services/auth_analytics_service.dart';
import 'package:hive_ui/services/admin_service.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_ui/firebase_options.dart';
import 'package:hive_ui/firebase_init_tracker.dart';

/// Controller class for handling authentication operations using the domain use cases
class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;
  final SignInUseCase _signInUseCase;
  final SignUpUseCase _signUpUseCase;
  final SignOutUseCase _signOutUseCase;
  final ResetPasswordUseCase _resetPasswordUseCase;
  final SendEmailVerificationUseCase _sendEmailVerificationUseCase;
  final CheckEmailVerifiedUseCase _checkEmailVerifiedUseCase;
  final UpdateEmailVerificationStatusUseCase
      _updateEmailVerificationStatusUseCase;
  final AbandonOnboardingUseCase _abandonOnboardingUseCase;
  final AuthAnalyticsService _analyticsService;

  AuthController({
    required AuthRepository authRepository,
    required SignInUseCase signInUseCase,
    required SignUpUseCase signUpUseCase,
    required SignOutUseCase signOutUseCase,
    required ResetPasswordUseCase resetPasswordUseCase,
    required SendEmailVerificationUseCase sendEmailVerificationUseCase,
    required CheckEmailVerifiedUseCase checkEmailVerifiedUseCase,
    required UpdateEmailVerificationStatusUseCase
        updateEmailVerificationStatusUseCase,
    required AbandonOnboardingUseCase abandonOnboardingUseCase,
    required AuthAnalyticsService analyticsService,
  })  : _authRepository = authRepository,
        _signInUseCase = signInUseCase,
        _signUpUseCase = signUpUseCase,
        _signOutUseCase = signOutUseCase,
        _resetPasswordUseCase = resetPasswordUseCase,
        _sendEmailVerificationUseCase = sendEmailVerificationUseCase,
        _checkEmailVerifiedUseCase = checkEmailVerifiedUseCase,
        _updateEmailVerificationStatusUseCase =
            updateEmailVerificationStatusUseCase,
        _abandonOnboardingUseCase = abandonOnboardingUseCase,
        _analyticsService = analyticsService,
        super(const AsyncValue.data(null));

  /// Sign in with email and password
  Future<void> signInWithEmailPassword(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      // First ensure Firebase is initialized
      await _ensureFirebaseInitialized();
      
      // Then sign in
      await _authRepository.signInWithEmailPassword(email, password);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      debugPrint('Error in sign in process: $e');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Create a new account with email and password
  Future<void> createUserWithEmailPassword(
      String email, String password) async {
    state = const AsyncValue.loading();
    try {
      // First ensure Firebase is initialized
      await _ensureFirebaseInitialized();
      
      // Then create the user
      await _authRepository.createUserWithEmailPassword(email, password);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      debugPrint('Error in account creation process: $e');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Ensure Firebase is properly initialized before auth operations
  Future<void> _ensureFirebaseInitialized() async {
    try {
      // Check if Firebase is already properly initialized according to our tracker
      if (FirebaseInitTracker.isInitialized) {
        debugPrint('Firebase already initialized according to tracker');
        return;
      }
      
      // If not, check if it's initialized but tracker doesn't know
      if (Firebase.apps.isNotEmpty) {
        // Update tracker and continue
        FirebaseInitTracker.isInitialized = true;
        FirebaseInitTracker.needsInitialization = false;
        debugPrint('Firebase was initialized but tracker was not updated - fixed');
        return;
      }
      
      // If we get here, Firebase is truly not initialized
      if (defaultTargetPlatform != TargetPlatform.windows) {
        debugPrint('WARNING: Firebase not initialized in AuthController! Initializing now...');
        // Initialize Firebase and wait for completion
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
        
        // Verify initialization succeeded
        if (Firebase.apps.isEmpty) {
          throw 'Firebase initialization failed';
        }
        
        // Update tracker
        FirebaseInitTracker.isInitialized = true;
        FirebaseInitTracker.needsInitialization = false;
        debugPrint('Firebase initialized successfully from AuthController');
      }
    } catch (e) {
      debugPrint('Error initializing Firebase in AuthController: $e');
      throw 'Could not initialize Firebase. Please restart the app and try again.';
    }
  }

  /// Convert Firebase error codes to user-friendly messages
  String _getReadableErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'email-already-in-use':
        return 'This email is already registered. Please try signing in instead.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled. Please contact support.';
      case 'weak-password':
        return 'Please choose a stronger password. Use at least 6 characters with a mix of letters and numbers.';
      default:
        return 'An error occurred during sign up. Please try again.';
    }
  }

  /// Sign out
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      // Clear admin status cache before signing out
      AdminService.clearCachedStatus();

      await _signOutUseCase();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      // Track sign out error
      await _analyticsService.trackAuthError(
        method: 'sign_out',
        errorCode: 'sign_out_error',
        errorMessage: e.toString(),
      );

      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signInWithGoogle();

      // Track successful login with Google
      await _analyticsService.trackLogin(
        method: 'google',
        additionalParams: {
          'platform': defaultTargetPlatform.toString(),
        },
      );

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      // Track auth error
      final errorCode = e.toString().contains('firebase_auth')
          ? e.toString().split('/')[1].split(']')[0]
          : 'unknown_error';

      await _analyticsService.trackAuthError(
        method: 'google_sign_in',
        errorCode: errorCode,
        errorMessage: e.toString(),
      );

      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    state = const AsyncValue.loading();
    try {
      await _resetPasswordUseCase(ResetPasswordParams(email: email));

      // Track password reset request
      await _analyticsService.trackPasswordReset(email: email);

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      // Track password reset error
      await _analyticsService.trackAuthError(
        method: 'password_reset',
        errorCode: 'password_reset_error',
        errorMessage: e.toString(),
      );

      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Send email verification to current user
  Future<void> sendEmailVerification() async {
    state = const AsyncValue.loading();
    try {
      await _sendEmailVerificationUseCase();

      // Track email verification sent
      await _analyticsService.trackEmailVerificationSent();

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      // Track email verification error
      await _analyticsService.trackAuthError(
        method: 'send_email_verification',
        errorCode: 'email_verification_error',
        errorMessage: e.toString(),
      );

      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Check if current user's email is verified
  Future<bool> checkEmailVerified() async {
    try {
      final isVerified = await _checkEmailVerifiedUseCase();

      // If verified and wasn't before, track completion
      if (isVerified) {
        await _analyticsService.trackEmailVerificationCompleted();
      }

      return isVerified;
    } catch (e) {
      debugPrint('Error checking email verification: $e');
      return false;
    }
  }

  /// Update user profile when email is verified
  Future<void> updateEmailVerificationStatus() async {
    try {
      await _updateEmailVerificationStatusUseCase();
    } catch (e) {
      debugPrint('Error updating email verification status: $e');
    }
  }

  /// Handle abandoned onboarding by signing out and cleaning up user data
  Future<void> abandonOnboarding() async {
    state = const AsyncValue.loading();
    try {
      await _abandonOnboardingUseCase();

      // Track onboarding abandonment
      await _analyticsService.trackOnboardingAbandoned(
        lastStep:
            'unknown', // This should ideally be passed from the calling context
        lastStepNumber: 0,
        totalSteps: 4, // Total number of steps in onboarding
        timeSpentSeconds: null,
      );

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      debugPrint('Error during onboarding abandonment: $e');
      state = AsyncValue.error(e, stack);
    }
  }
}
