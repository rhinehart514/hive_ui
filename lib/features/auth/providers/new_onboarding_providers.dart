import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ui/features/auth/data/datasources/onboarding_local_datasource.dart';
import 'package:hive_ui/features/auth/data/datasources/onboarding_remote_datasource.dart';
import 'package:hive_ui/features/auth/data/repositories/onboarding_repository_impl.dart';
import 'package:hive_ui/features/auth/domain/repositories/onboarding_repository.dart';
import 'package:hive_ui/features/auth/domain/usecases/complete_onboarding_usecase.dart';
import 'package:hive_ui/features/auth/domain/usecases/get_onboarding_profile_usecase.dart';
import 'package:hive_ui/features/auth/domain/usecases/update_onboarding_progress_usecase.dart';
import 'package:hive_ui/features/auth/presentation/controllers/onboarding_controller_new.dart';

/// Provider for FirebaseAuth instance
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Provider for FirebaseFirestore instance
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Provider for OnboardingLocalDataSource
final onboardingLocalDataSourceProvider =
    Provider<OnboardingLocalDataSource>((ref) {
  return SharedPreferencesOnboardingDataSource();
});

/// Provider for OnboardingRemoteDataSource
final onboardingRemoteDataSourceProvider =
    Provider<OnboardingRemoteDataSource>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);
  return FirebaseOnboardingDataSource(
    auth: auth,
    firestore: firestore,
  );
});

/// Provider for OnboardingRepository
final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  final localDataSource = ref.watch(onboardingLocalDataSourceProvider);
  final remoteDataSource = ref.watch(onboardingRemoteDataSourceProvider);
  return OnboardingRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
  );
});

/// Provider for GetOnboardingProfileUseCase
final getOnboardingProfileUseCaseProvider =
    Provider<GetOnboardingProfileUseCase>((ref) {
  final repository = ref.watch(onboardingRepositoryProvider);
  return GetOnboardingProfileUseCase(repository: repository);
});

/// Provider for UpdateOnboardingProgressUseCase
final updateOnboardingProgressUseCaseProvider =
    Provider<UpdateOnboardingProgressUseCase>((ref) {
  final repository = ref.watch(onboardingRepositoryProvider);
  final auth = ref.watch(firebaseAuthProvider);
  return UpdateOnboardingProgressUseCase(
    repository: repository,
    auth: auth,
  );
});

/// Provider for CompleteOnboardingUseCase
final completeOnboardingUseCaseProvider =
    Provider<CompleteOnboardingUseCase>((ref) {
  final repository = ref.watch(onboardingRepositoryProvider);
  final auth = ref.watch(firebaseAuthProvider);
  return CompleteOnboardingUseCase(
    repository: repository,
    auth: auth,
  );
});

/// Provider for OnboardingController
final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, OnboardingState>((ref) {
  final getProfileUseCase = ref.watch(getOnboardingProfileUseCaseProvider);
  final updateProgressUseCase =
      ref.watch(updateOnboardingProgressUseCaseProvider);
  final completeOnboardingUseCase =
      ref.watch(completeOnboardingUseCaseProvider);

  return OnboardingController(
    getOnboardingProfileUseCase: getProfileUseCase,
    updateOnboardingProgressUseCase: updateProgressUseCase,
    completeOnboardingUseCase: completeOnboardingUseCase,
  );
});
