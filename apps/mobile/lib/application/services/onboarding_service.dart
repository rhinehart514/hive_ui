import 'package:hive_ui/core/result/result.dart';
import 'package:hive_ui/data/datasources/firestore_user_datasource.dart';
import 'package:hive_ui/domain/entities/user_profile.dart' as domain;
import 'package:hive_ui/domain/failures/auth_failure.dart';
import 'package:hive_ui/domain/usecases/complete_onboarding_usecase.dart';

/// Service for handling user onboarding operations.
class OnboardingService {
  final UserDataSource _userDataSource;
  final CompleteOnboardingUseCase _completeOnboardingUseCase;

  /// Creates a new instance with the given dependencies.
  OnboardingService(
    this._userDataSource,
    this._completeOnboardingUseCase,
  );

  /// Completes the onboarding process for a user.
  ///
  /// Takes all collected user information and creates a profile in the system.
  /// Returns a [Result] containing either the created [domain.UserProfile] or a [Failure].
  Future<Result<domain.UserProfile, Failure>> completeOnboarding({
    required String uid,
    required String firstName,
    required String lastName,
    required String email,
    required String residence,
    required String major,
    required List<String> interests,
    required bool requestVerifiedPlus,
    Duration onboardingDuration = const Duration(minutes: 5),
  }) async {
    try {
      // Use the domain use case to create and validate the profile
      final result = await _completeOnboardingUseCase.execute(
        uid: uid,
        firstName: firstName,
        lastName: lastName,
        email: email,
        residence: residence,
        major: major,
        interests: interests,
        requestVerifiedPlus: requestVerifiedPlus,
        onboardingDuration: onboardingDuration,
      );
      
      // Return the result directly since our new implementation already returns Result<UserProfile, Failure>
      return result;
    } catch (e) {
      return Result.left(
        ServerFailure('Failed to complete onboarding: ${e.toString()}'),
      );
    }
  }

  /// Retrieves a user's profile.
  ///
  /// Returns a [Result] containing either the [domain.UserProfile] or a [Failure].
  Future<Result<domain.UserProfile, Failure>> getUserProfile(String uid) async {
    return _userDataSource.getUserProfile(uid);
  }

  /// Updates a user's profile with the given fields.
  ///
  /// Returns a [Result] containing either the updated [domain.UserProfile] or a [Failure].
  Future<Result<domain.UserProfile, Failure>> updateUserProfile(
    String uid,
    Map<String, dynamic> updates,
  ) async {
    return _userDataSource.updateUserProfile(uid, updates);
  }

  /// Checks if a username is already taken.
  ///
  /// Returns a [Result] containing a boolean indicating whether the username is taken.
  Future<Result<bool, Failure>> isUsernameTaken(String username) async {
    return _userDataSource.isUsernameTaken(username);
  }

  /// Requests verification for a user's account.
  ///
  /// Returns a [Result] indicating success or failure.
  Future<Result<void, Failure>> requestVerification(String uid) async {
    return _userDataSource.requestVerification(uid);
  }
} 