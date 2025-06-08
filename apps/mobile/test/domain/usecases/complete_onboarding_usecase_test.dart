import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ui/core/result/result.dart';
import 'package:hive_ui/domain/entities/user_profile.dart';
import 'package:hive_ui/domain/failures/auth_failure.dart';
import 'package:hive_ui/domain/repositories/user_repository.dart';
import 'package:hive_ui/domain/usecases/complete_onboarding_usecase.dart';
import 'package:hive_ui/domain/usecases/generate_username_usecase.dart';
import 'package:hive_ui/domain/usecases/track_analytics_event_usecase.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'complete_onboarding_usecase_test.mocks.dart';

@GenerateMocks([
  UserRepository, 
  GenerateUsernameUseCase, 
  TrackAnalyticsEventUseCase
])
void main() {
  late CompleteOnboardingUseCase useCase;
  late MockUserRepository mockUserRepository;
  late MockGenerateUsernameUseCase mockGenerateUsernameUseCase;
  late MockTrackAnalyticsEventUseCase mockTrackAnalyticsEventUseCase;
  
  setUp(() {
    mockUserRepository = MockUserRepository();
    mockGenerateUsernameUseCase = MockGenerateUsernameUseCase();
    mockTrackAnalyticsEventUseCase = MockTrackAnalyticsEventUseCase();
    useCase = CompleteOnboardingUseCase(
      mockUserRepository, 
      mockGenerateUsernameUseCase, 
      mockTrackAnalyticsEventUseCase
    );
  });
  
  const testUid = 'test-user-123';
  const testEmail = 'test@buffalo.edu';
  const testFirstName = 'John';
  const testLastName = 'Doe';
  const testResidence = 'Campus Housing';
  const testMajor = 'Computer Science';
  const testInterests = ['Technology', 'Music'];
  const testUsername = 'john_doe_1234';
  const testDuration = Duration(minutes: 5);
  
  const testUserProfile = UserProfile(
    firstName: testFirstName,
    lastName: testLastName,
    email: testEmail,
    username: testUsername,
    residence: testResidence,
    major: testMajor,
    interests: testInterests,
    tier: UserTier.base,
  );
  
  test('should create user profile with generated username when all inputs are valid', () async {
    // Arrange
    when(mockGenerateUsernameUseCase.execute(testFirstName, testLastName))
        .thenAnswer((_) async => const Result.right(testUsername));
    when(mockUserRepository.createUserProfile(any, testUid))
        .thenAnswer((_) async => const Result.right(testUserProfile));
    
    // Act
    final result = await useCase.execute(
      uid: testUid,
      email: testEmail,
      firstName: testFirstName,
      lastName: testLastName,
      residence: testResidence,
      major: testMajor,
      interests: testInterests,
      requestVerifiedPlus: false,
      onboardingDuration: testDuration,
    );
    
    // Assert
    expect(result.isSuccess, isTrue);
    expect(result.getSuccess, equals(testUserProfile));
    verify(mockGenerateUsernameUseCase.execute(testFirstName, testLastName)).called(1);
    verify(mockUserRepository.createUserProfile(any, testUid)).called(1);
  });
  
  test('should request verification if requestVerifiedPlus is true', () async {
    // Arrange
    when(mockGenerateUsernameUseCase.execute(testFirstName, testLastName))
        .thenAnswer((_) async => const Result.right(testUsername));
    when(mockUserRepository.createUserProfile(any, testUid))
        .thenAnswer((_) async => const Result.right(testUserProfile));
    when(mockUserRepository.requestVerification(testUid))
        .thenAnswer((_) async => const Result.right(null));
    
    // Act
    final result = await useCase.execute(
      uid: testUid,
      email: testEmail,
      firstName: testFirstName,
      lastName: testLastName,
      residence: testResidence,
      major: testMajor,
      interests: testInterests,
      requestVerifiedPlus: true,
      onboardingDuration: testDuration,
    );
    
    // Assert
    expect(result.isSuccess, isTrue);
    verify(mockUserRepository.requestVerification(testUid)).called(1);
  });
  
  test('should return failure when first name is empty', () async {
    // Act
    final result = await useCase.execute(
      uid: testUid,
      email: testEmail,
      firstName: '',
      lastName: testLastName,
      residence: testResidence,
      major: testMajor,
      interests: testInterests,
      requestVerifiedPlus: false,
      onboardingDuration: testDuration,
    );
    
    // Assert
    expect(result.isFailure, isTrue);
    expect(result.getFailure, isA<AuthFailure>());
    expect(result.getFailure.message, contains('name'));
    verifyNever(mockGenerateUsernameUseCase.execute(any, any));
    verifyNever(mockUserRepository.createUserProfile(any, any));
  });
  
  test('should return failure when interests list is empty', () async {
    // Act
    final result = await useCase.execute(
      uid: testUid,
      email: testEmail,
      firstName: testFirstName,
      lastName: testLastName,
      residence: testResidence,
      major: testMajor,
      interests: const [],
      requestVerifiedPlus: false,
      onboardingDuration: testDuration,
    );
    
    // Assert
    expect(result.isFailure, isTrue);
    expect(result.getFailure, isA<AuthFailure>());
    expect(result.getFailure.message, contains('interest'));
  });
  
  test('should return failure when interests list is too large', () async {
    // Act
    final result = await useCase.execute(
      uid: testUid,
      email: testEmail,
      firstName: testFirstName,
      lastName: testLastName,
      residence: testResidence,
      major: testMajor,
      interests: List.generate(11, (i) => 'Interest $i'),
      requestVerifiedPlus: false,
      onboardingDuration: testDuration,
    );
    
    // Assert
    expect(result.isFailure, isTrue);
    expect(result.getFailure, isA<AuthFailure>());
    expect(result.getFailure.message, contains('interest'));
  });
  
  test('should return failure when username generation fails', () async {
    // Arrange
    when(mockGenerateUsernameUseCase.execute(testFirstName, testLastName))
        .thenAnswer((_) async => const Result.left(ServerFailure('Failed to generate username')));
    
    // Act
    final result = await useCase.execute(
      uid: testUid,
      email: testEmail,
      firstName: testFirstName,
      lastName: testLastName,
      residence: testResidence,
      major: testMajor,
      interests: testInterests,
      requestVerifiedPlus: false,
      onboardingDuration: testDuration,
    );
    
    // Assert
    expect(result.isFailure, isTrue);
    expect(result.getFailure, isA<ServerFailure>());
  });
  
  test('should return failure when profile creation fails', () async {
    // Arrange
    when(mockGenerateUsernameUseCase.execute(testFirstName, testLastName))
        .thenAnswer((_) async => const Result.right(testUsername));
    when(mockUserRepository.createUserProfile(any, testUid))
        .thenAnswer((_) async => const Result.left(ServerFailure('Failed to create profile')));
    
    // Act
    final result = await useCase.execute(
      uid: testUid,
      email: testEmail,
      firstName: testFirstName,
      lastName: testLastName,
      residence: testResidence,
      major: testMajor,
      interests: testInterests,
      requestVerifiedPlus: false,
      onboardingDuration: testDuration,
    );
    
    // Assert
    expect(result.isFailure, isTrue);
    expect(result.getFailure, isA<ServerFailure>());
  });
} 