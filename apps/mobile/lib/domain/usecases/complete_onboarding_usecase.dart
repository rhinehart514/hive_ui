import 'package:hive_ui/core/result/result.dart';
import 'package:hive_ui/domain/entities/user_profile.dart';
import 'package:hive_ui/domain/failures/auth_failure.dart';
import 'package:hive_ui/domain/repositories/user_repository.dart';
import 'package:hive_ui/domain/usecases/generate_username_usecase.dart';
import 'package:hive_ui/domain/usecases/track_analytics_event_usecase.dart';

/// Use case for completing the onboarding process and creating a user profile
class CompleteOnboardingUseCase {
  final UserRepository _userRepository;
  final GenerateUsernameUseCase _generateUsernameUseCase;
  final TrackAnalyticsEventUseCase _trackAnalyticsEventUseCase;
  
  /// Creates a new instance with the given repositories and use cases
  CompleteOnboardingUseCase(
    this._userRepository, 
    this._generateUsernameUseCase,
    this._trackAnalyticsEventUseCase,
  );
  
  /// Executes the use case to complete onboarding and create a user profile
  /// 
  /// Takes all required onboarding fields and creates a user profile.
  /// Returns a Result with the created UserProfile or a Failure if creation fails.
  Future<Result<UserProfile, Failure>> execute({
    required String uid,
    required String email,
    required String firstName,
    required String lastName,
    required String residence,
    required String major,
    required List<String> interests,
    required bool requestVerifiedPlus,
    required Duration onboardingDuration,
  }) async {
    // Validate inputs
    final validationResult = _validateInputs(
      firstName: firstName,
      lastName: lastName,
      residence: residence,
      major: major,
      interests: interests,
    );
    
    if (validationResult.isFailure) {
      // Track validation failure
      _trackAnalyticsEventUseCase.trackOnboardingAbandoned(
        lastCompletedStep: 'validation',
        lastStepNumber: 5,
        timeSpent: onboardingDuration,
        userId: uid,
        abandonReason: validationResult.getFailure.message,
      );
      
      return Result.left(validationResult.getFailure);
    }
    
    // Generate username
    final usernameResult = await _generateUsernameUseCase.execute(firstName, lastName);
    
    if (usernameResult.isFailure) {
      // Track username generation failure
      _trackAnalyticsEventUseCase.trackOnboardingAbandoned(
        lastCompletedStep: 'username_generation',
        lastStepNumber: 5,
        timeSpent: onboardingDuration,
        userId: uid,
        abandonReason: usernameResult.getFailure.message,
      );
      
      return Result.left(usernameResult.getFailure);
    }
    
    final username = usernameResult.getSuccess;
    
    try {
      // Create the user profile
      final userProfile = UserProfile(
        firstName: firstName,
        lastName: lastName,
        email: email,
        username: username,
        residence: residence,
        major: major,
        interests: interests,
        tier: UserTier.base,
      );
      
      // Save the profile
      final saveResult = await _userRepository.createUserProfile(userProfile, uid);
      
      if (saveResult.isFailure) {
        // Track profile creation failure
        _trackAnalyticsEventUseCase.trackOnboardingAbandoned(
          lastCompletedStep: 'profile_creation',
          lastStepNumber: 5,
          timeSpent: onboardingDuration,
          userId: uid,
          abandonReason: saveResult.getFailure.message,
        );
        
        return Result.left(saveResult.getFailure);
      }
      
      // Request verified+ status if needed
      if (requestVerifiedPlus) {
        final verificationResult = await _userRepository.requestVerification(uid);
        
        if (verificationResult.isFailure) {
          // Log the error but continue with profile creation
          // The user can request verification later
          // We don't fail the onboarding process for this
        }
      }
      
      // Track successful onboarding completion
      _trackAnalyticsEventUseCase.trackOnboardingCompleted(
        totalTime: onboardingDuration,
        requestedVerification: requestVerifiedPlus,
        userId: uid,
        interestsCount: interests.length,
      );
      
      return Result.right(saveResult.getSuccess);
    } catch (e) {
      // Track exception during onboarding
      _trackAnalyticsEventUseCase.trackOnboardingAbandoned(
        lastCompletedStep: 'exception',
        lastStepNumber: 5,
        timeSpent: onboardingDuration,
        userId: uid,
        abandonReason: e.toString(),
      );
      
      return Result.left(ServerFailure('Failed to complete onboarding: ${e.toString()}'));
    }
  }
  
  /// Validates the onboarding inputs
  Result<void, Failure> _validateInputs({
    required String firstName,
    required String lastName,
    required String residence,
    required String major,
    required List<String> interests,
  }) {
    // Check for empty fields
    if (firstName.isEmpty) {
      return const Result.left(AuthFailure('First name is required'));
    }
    
    if (lastName.isEmpty) {
      return const Result.left(AuthFailure('Last name is required'));
    }
    
    if (residence.isEmpty) {
      return const Result.left(AuthFailure('Residence is required'));
    }
    
    if (major.isEmpty) {
      return const Result.left(AuthFailure('Major is required'));
    }
    
    // Validate interests
    if (interests.isEmpty) {
      return const Result.left(AuthFailure('At least one interest is required'));
    }
    
    if (interests.length > 10) {
      return const Result.left(AuthFailure('Maximum of 10 interests allowed'));
    }
    
    return const Result.right(null);
  }
} 