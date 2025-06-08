import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ui/application/services/onboarding_service.dart';
import 'package:hive_ui/core/result/result.dart';
import 'package:hive_ui/data/datasources/firestore_user_datasource.dart' as data_sources;
import 'package:hive_ui/domain/entities/user_profile.dart' as domain;
import 'package:hive_ui/domain/failures/auth_failure.dart';
import 'package:hive_ui/domain/usecases/complete_onboarding_usecase.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'onboarding_service_test.mocks.dart';

@GenerateMocks([data_sources.UserDataSource, CompleteOnboardingUseCase])
void main() {
  late MockUserDataSource mockUserDataSource;
  late MockCompleteOnboardingUseCase mockCompleteOnboardingUseCase;
  late OnboardingService onboardingService;

  setUp(() {
    mockUserDataSource = MockUserDataSource();
    mockCompleteOnboardingUseCase = MockCompleteOnboardingUseCase();
    onboardingService = OnboardingService(
      mockUserDataSource,
      mockCompleteOnboardingUseCase,
    );
  });

  group('OnboardingService', () {
    const testDomainProfile = domain.UserProfile(
      firstName: 'John',
      lastName: 'Doe',
      email: 'john.doe@example.com',
      username: 'john_doe_1234',
      residence: 'Campus Housing',
      major: 'Computer Science',
      interests: ['Technology', 'Music'],
      tier: domain.UserTier.base,
    );

    const testUid = 'test-uid';

    test('completeOnboarding should return user profile on success', () async {
      // Arrange
      when(mockCompleteOnboardingUseCase.execute(
        uid: anyNamed('uid'),
        firstName: anyNamed('firstName'),
        lastName: anyNamed('lastName'),
        email: anyNamed('email'),
        residence: anyNamed('residence'),
        major: anyNamed('major'),
        interests: anyNamed('interests'),
        requestVerifiedPlus: anyNamed('requestVerifiedPlus'),
        onboardingDuration: anyNamed('onboardingDuration'),
      )).thenAnswer((_) async => const Result.right(testDomainProfile));

      // Act
      final result = await onboardingService.completeOnboarding(
        uid: testUid,
        firstName: 'John',
        lastName: 'Doe',
        email: 'john.doe@example.com',
        residence: 'Campus Housing',
        major: 'Computer Science',
        interests: const ['Technology', 'Music'],
        requestVerifiedPlus: false,
        onboardingDuration: const Duration(minutes: 5),
      );

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.getSuccess, equals(testDomainProfile));
    });

    test('completeOnboarding should return failure when use case fails', () async {
      // Arrange
      const failure = AuthFailure('First name cannot be empty');
      when(mockCompleteOnboardingUseCase.execute(
        uid: anyNamed('uid'),
        firstName: anyNamed('firstName'),
        lastName: anyNamed('lastName'),
        email: anyNamed('email'),
        residence: anyNamed('residence'),
        major: anyNamed('major'),
        interests: anyNamed('interests'),
        requestVerifiedPlus: anyNamed('requestVerifiedPlus'),
        onboardingDuration: anyNamed('onboardingDuration'),
      )).thenAnswer((_) async => const Result.left(failure));

      // Act
      final result = await onboardingService.completeOnboarding(
        uid: testUid,
        firstName: '',
        lastName: 'Doe',
        email: 'john.doe@example.com',
        residence: 'Campus Housing',
        major: 'Computer Science',
        interests: const ['Technology', 'Music'],
        requestVerifiedPlus: false,
        onboardingDuration: const Duration(minutes: 5),
      );

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.getFailure, equals(failure));
    });

    test('getUserProfile should delegate to UserDataSource', () async {
      // Arrange
      const domainProfile = domain.UserProfile(
        firstName: 'John', 
        lastName: 'Doe', 
        email: 'j@d.com', 
        username: 'jd', 
        residence: 'r', 
        major: 'm', 
        interests: [], 
        tier: domain.UserTier.base
      );
      when(mockUserDataSource.getUserProfile(testUid))
          .thenAnswer((_) async => const Result.right(domainProfile));

      // Act
      final result = await onboardingService.getUserProfile(testUid);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.getSuccess, equals(domainProfile));
      verify(mockUserDataSource.getUserProfile(testUid)).called(1);
    });

    test('updateUserProfile should delegate to UserDataSource', () async {
      // Arrange
      const updates = {'firstName': 'Jane'};
      const domainProfile = domain.UserProfile(
        firstName: 'Jane', 
        lastName: 'Doe', 
        email: 'j@d.com', 
        username: 'jd', 
        residence: 'r', 
        major: 'm', 
        interests: [], 
        tier: domain.UserTier.base
      );
      
      when(mockUserDataSource.updateUserProfile(testUid, updates))
          .thenAnswer((_) async => const Result.right(domainProfile));

      // Act
      final result = await onboardingService.updateUserProfile(testUid, updates);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.getSuccess, equals(domainProfile));
      verify(mockUserDataSource.updateUserProfile(testUid, updates)).called(1);
    });

    test('isUsernameTaken should delegate to UserDataSource', () async {
      // Arrange
      const username = 'john_doe_1234';
      when(mockUserDataSource.isUsernameTaken(username))
          .thenAnswer((_) async => const Result.right(true));

      // Act
      final result = await onboardingService.isUsernameTaken(username);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.getSuccess, isTrue);
      verify(mockUserDataSource.isUsernameTaken(username)).called(1);
    });

    test('requestVerification should delegate to UserDataSource', () async {
      // Arrange
      when(mockUserDataSource.requestVerification(testUid))
          .thenAnswer((_) async => const Result.right(null));

      // Act
      final result = await onboardingService.requestVerification(testUid);

      // Assert
      expect(result.isSuccess, isTrue);
      verify(mockUserDataSource.requestVerification(testUid)).called(1);
    });
  });
} 