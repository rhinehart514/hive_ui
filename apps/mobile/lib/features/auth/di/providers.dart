import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/application/services/auth_service.dart';
import 'package:hive_ui/application/services/onboarding_service.dart';
import 'package:hive_ui/data/datasources/firebase_auth_datasource.dart';
import 'package:hive_ui/data/datasources/firestore_user_datasource.dart';
import 'package:hive_ui/data/repositories/analytics_repository_impl.dart';
import 'package:hive_ui/data/repositories/user_repository_impl.dart';
import 'package:hive_ui/domain/repositories/analytics_repository.dart';
import 'package:hive_ui/domain/repositories/user_repository.dart';
import 'package:hive_ui/domain/usecases/complete_onboarding_usecase.dart';
import 'package:hive_ui/domain/usecases/generate_username_usecase.dart';
import 'package:hive_ui/domain/usecases/track_analytics_event_usecase.dart';
import 'package:hive_ui/domain/usecases/username_collision_detection_usecase.dart';
import 'package:hive_ui/features/auth/presentation/state/auth_state_notifier.dart';
import 'package:hive_ui/features/onboarding/presentation/state/onboarding_state_notifier.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Configuration for the Firebase magic link.
final actionCodeSettingsProvider = Provider<String>((ref) {
  // In a real app, this would be in a config file or environment variable
  return 'https://hiveapp.page.link/auth';
});

/// List of allowed email domains for sign-up.
final allowedDomainsProvider = Provider<List<String>>((ref) {
  // In a real app, this would be in a config file or environment variable
  return ['buffalo.edu'];
});

/// Provider for Firebase Auth instance.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Provider for Firestore instance.
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Provider for Firebase Analytics instance.
final firebaseAnalyticsProvider = Provider<FirebaseAnalytics>((ref) {
  return FirebaseAnalytics.instance;
});

/// Provider for Firebase Crashlytics instance.
final firebaseCrashlyticsProvider = Provider<FirebaseCrashlytics>((ref) {
  return FirebaseCrashlytics.instance;
});

/// Provider for the Firestore collection name for users.
final usersCollectionProvider = Provider<String>((ref) {
  return 'users';
});

/// Provider for the Firestore collection name for verification requests.
final verificationRequestsCollectionProvider = Provider<String>((ref) {
  return 'verifiedRequests';
});

/// Provider for the auth data source.
final authDataSourceProvider = Provider<AuthDataSource>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  final actionCodeSettings = ref.watch(actionCodeSettingsProvider);
  final allowedDomains = ref.watch(allowedDomainsProvider);
  
  return FirebaseAuthDataSource(
    firebaseAuth,
    actionCodeSettings,
    allowedDomains,
  );
});

/// Provider for the user data source.
final userDataSourceProvider = Provider<UserDataSource>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final usersCollection = ref.watch(usersCollectionProvider);
  final verificationRequestsCollection = ref.watch(verificationRequestsCollectionProvider);
  
  return FirestoreUserDataSource(
    firestore,
    usersCollection,
    verificationRequestsCollection,
  );
});

/// Provider for the user repository.
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final userDataSource = ref.watch(userDataSourceProvider);
  return UserRepositoryImpl(userDataSource);
});

/// Provider for the analytics repository
final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  final analytics = ref.watch(firebaseAnalyticsProvider);
  final crashlytics = ref.watch(firebaseCrashlyticsProvider);
  return FirebaseAnalyticsRepository(analytics, crashlytics);
});

/// Provider for tracking analytics events use case
final trackAnalyticsEventUseCaseProvider = Provider<TrackAnalyticsEventUseCase>((ref) {
  final analyticsRepository = ref.watch(analyticsRepositoryProvider);
  return TrackAnalyticsEventUseCase(analyticsRepository);
});

/// Provider for username collision detection use case
final usernameCollisionDetectionUseCaseProvider = Provider<UsernameCollisionDetectionUseCase>((ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  final analyticsRepository = ref.watch(analyticsRepositoryProvider);
  return UsernameCollisionDetectionUseCase(userRepository, analyticsRepository);
});

/// Provider for the username generation use case.
final generateUsernameUseCaseProvider = Provider<GenerateUsernameUseCase>((ref) {
  final usernameCollisionDetectionUseCase = ref.watch(usernameCollisionDetectionUseCaseProvider);
  return GenerateUsernameUseCase(usernameCollisionDetectionUseCase);
});

/// Provider for the onboarding completion use case.
final completeOnboardingUseCaseProvider = Provider<CompleteOnboardingUseCase>((ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  final generateUsernameUseCase = ref.watch(generateUsernameUseCaseProvider);
  final trackAnalyticsEventUseCase = ref.watch(trackAnalyticsEventUseCaseProvider);
  return CompleteOnboardingUseCase(userRepository, generateUsernameUseCase, trackAnalyticsEventUseCase);
});

/// Provider for the auth service.
final authServiceProvider = Provider<AuthService>((ref) {
  final authDataSource = ref.watch(authDataSourceProvider);
  return AuthService(authDataSource);
});

/// Provider for the onboarding service.
final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  final userDataSource = ref.watch(userDataSourceProvider);
  final completeOnboardingUseCase = ref.watch(completeOnboardingUseCaseProvider);
  
  return OnboardingService(
    userDataSource,
    completeOnboardingUseCase,
  );
});

/// Provider for the auth state notifier.
final authStateNotifierProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthStateNotifier(authService);
});

/// Provider for the onboarding state notifier.
/// Note: This uses a family to pass the email.
final onboardingStateNotifierProvider = StateNotifierProvider.family<
    OnboardingStateNotifier, OnboardingState, String>((ref, email) {
  final onboardingService = ref.watch(onboardingServiceProvider);
  return OnboardingStateNotifier(onboardingService, email);
});

/// Provider to check if a user is authenticated.
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateNotifierProvider);
  return authState.status == AuthStatus.authenticated;
}); 