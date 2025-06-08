import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ui/application/services/onboarding_service.dart';
import 'package:hive_ui/core/result/result.dart';
import 'package:hive_ui/domain/entities/user_profile.dart' as domain;
import 'package:hive_ui/domain/failures/auth_failure.dart';
import 'package:hive_ui/features/onboarding/presentation/state/onboarding_state_notifier.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'onboarding_state_notifier_test.mocks.dart';

@GenerateMocks([OnboardingService])
void main() {
  late OnboardingStateNotifier notifier;
  late MockOnboardingService mockOnboardingService;
  late ProviderContainer container;

  const testEmail = 'test@buffalo.edu';
  const testUid = 'test-uid';
  
  setUp(() {
    mockOnboardingService = MockOnboardingService();
    notifier = OnboardingStateNotifier(mockOnboardingService, testEmail);
    container = ProviderContainer(
      overrides: [],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('initial state should have name step and provided email', () {
    // Assert
    expect(notifier.state.currentStep, equals(OnboardingStep.name));
    expect(notifier.state.status, equals(OnboardingStatus.idle));
    expect(notifier.state.email, equals(testEmail));
    expect(notifier.state.firstName, isEmpty);
    expect(notifier.state.lastName, isEmpty);
    expect(notifier.state.interests, isEmpty);
  });

  group('setName', () {
    test('should update first and last name and move to residence step', () {
      // Act
      notifier.setName('John', 'Doe');

      // Assert
      expect(notifier.state.firstName, equals('John'));
      expect(notifier.state.lastName, equals('Doe'));
      expect(notifier.state.currentStep, equals(OnboardingStep.residence));
    });
  });

  group('setResidence', () {
    test('should update residence and move to major step', () {
      // Arrange - Set name first
      notifier.setName('John', 'Doe');

      // Act
      notifier.setResidence('Campus Housing');

      // Assert
      expect(notifier.state.residence, equals('Campus Housing'));
      expect(notifier.state.currentStep, equals(OnboardingStep.major));
    });
  });

  group('setMajor', () {
    test('should update major and move to interests step', () {
      // Arrange - Set previous steps
      notifier.setName('John', 'Doe');
      notifier.setResidence('Campus Housing');

      // Act
      notifier.setMajor('Computer Science');

      // Assert
      expect(notifier.state.major, equals('Computer Science'));
      expect(notifier.state.currentStep, equals(OnboardingStep.interests));
    });
  });

  group('setInterests', () {
    test('should update interests and move to role step', () {
      // Arrange - Set previous steps
      notifier.setName('John', 'Doe');
      notifier.setResidence('Campus Housing');
      notifier.setMajor('Computer Science');

      // Act
      notifier.setInterests(['Technology', 'Music']);

      // Assert
      expect(notifier.state.interests, equals(['Technology', 'Music']));
      expect(notifier.state.currentStep, equals(OnboardingStep.role));
    });
  });

  group('setRequestVerifiedPlus', () {
    test('should update requestVerifiedPlus flag', () {
      // Arrange - Set previous steps
      notifier.setName('John', 'Doe');
      notifier.setResidence('Campus Housing');
      notifier.setMajor('Computer Science');
      notifier.setInterests(['Technology', 'Music']);

      // Act
      notifier.setRequestVerifiedPlus(true);

      // Assert
      expect(notifier.state.requestVerifiedPlus, isTrue);
      expect(notifier.state.currentStep, equals(OnboardingStep.role)); // Step shouldn't change
    });
  });

  group('goBack', () {
    test('should navigate back to name step from residence step', () {
      // Arrange
      notifier.setName('John', 'Doe');
      expect(notifier.state.currentStep, equals(OnboardingStep.residence));

      // Act
      notifier.goBack();

      // Assert
      expect(notifier.state.currentStep, equals(OnboardingStep.name));
    });

    test('should navigate back to residence step from major step', () {
      // Arrange
      notifier.setName('John', 'Doe');
      notifier.setResidence('Campus Housing');
      expect(notifier.state.currentStep, equals(OnboardingStep.major));

      // Act
      notifier.goBack();

      // Assert
      expect(notifier.state.currentStep, equals(OnboardingStep.residence));
    });

    test('should navigate back to major step from interests step', () {
      // Arrange
      notifier.setName('John', 'Doe');
      notifier.setResidence('Campus Housing');
      notifier.setMajor('Computer Science');
      expect(notifier.state.currentStep, equals(OnboardingStep.interests));

      // Act
      notifier.goBack();

      // Assert
      expect(notifier.state.currentStep, equals(OnboardingStep.major));
    });

    test('should navigate back to interests step from role step', () {
      // Arrange
      notifier.setName('John', 'Doe');
      notifier.setResidence('Campus Housing');
      notifier.setMajor('Computer Science');
      notifier.setInterests(['Technology', 'Music']);
      expect(notifier.state.currentStep, equals(OnboardingStep.role));

      // Act
      notifier.goBack();

      // Assert
      expect(notifier.state.currentStep, equals(OnboardingStep.interests));
    });

    test('should not change state when trying to go back from name step', () {
      // Act
      notifier.goBack();

      // Assert
      expect(notifier.state.currentStep, equals(OnboardingStep.name));
    });
  });

  group('completeOnboarding', () {
    test('should complete onboarding successfully when service returns success', () async {
      // Arrange
      // Fill out all steps
      notifier.setName('John', 'Doe');
      notifier.setResidence('Campus Housing');
      notifier.setMajor('Computer Science');
      notifier.setInterests(['Technology', 'Music']);
      notifier.setRequestVerifiedPlus(true);

      const userProfile = domain.UserProfile(
        firstName: 'John',
        lastName: 'Doe',
        email: testEmail,
        username: 'john_doe_1234',
        residence: 'Campus Housing',
        major: 'Computer Science',
        interests: ['Technology', 'Music'],
        tier: domain.UserTier.base,
      );

      when(mockOnboardingService.completeOnboarding(
        uid: testUid,
        firstName: 'John',
        lastName: 'Doe',
        email: testEmail,
        residence: 'Campus Housing',
        major: 'Computer Science',
        interests: ['Technology', 'Music'],
        requestVerifiedPlus: true,
      )).thenAnswer((_) async => const Result.right(userProfile));

      // Act
      await notifier.completeOnboarding(testUid);

      // Assert
      expect(notifier.state.status, equals(OnboardingStatus.completed));
      expect(notifier.state.currentStep, equals(OnboardingStep.completed));
      expect(notifier.state.profile, equals(userProfile));
      
      verify(mockOnboardingService.completeOnboarding(
        uid: testUid,
        firstName: 'John',
        lastName: 'Doe',
        email: testEmail,
        residence: 'Campus Housing',
        major: 'Computer Science',
        interests: ['Technology', 'Music'],
        requestVerifiedPlus: true,
      )).called(1);
    });

    test('should update to error state when service returns failure', () async {
      // Arrange
      // Fill out all steps
      notifier.setName('John', 'Doe');
      notifier.setResidence('Campus Housing');
      notifier.setMajor('Computer Science');
      notifier.setInterests(['Technology', 'Music']);
      notifier.setRequestVerifiedPlus(true);

      const failure = ServerFailure('Failed to complete onboarding');

      when(mockOnboardingService.completeOnboarding(
        uid: testUid,
        firstName: 'John',
        lastName: 'Doe',
        email: testEmail,
        residence: 'Campus Housing',
        major: 'Computer Science',
        interests: ['Technology', 'Music'],
        requestVerifiedPlus: true,
      )).thenAnswer((_) async => const Result.left(failure));

      // Act
      await notifier.completeOnboarding(testUid);

      // Assert
      expect(notifier.state.status, equals(OnboardingStatus.error));
      expect(notifier.state.error, equals(failure));
      
      verify(mockOnboardingService.completeOnboarding(
        uid: testUid,
        firstName: 'John',
        lastName: 'Doe',
        email: testEmail,
        residence: 'Campus Housing',
        major: 'Computer Science',
        interests: ['Technology', 'Music'],
        requestVerifiedPlus: true,
      )).called(1);
    });
  });

  group('clearError', () {
    test('should clear error and set status back to idle', () async {
      // Arrange - Create an error state first
      // Fill out all steps
      notifier.setName('John', 'Doe');
      notifier.setResidence('Campus Housing');
      notifier.setMajor('Computer Science');
      notifier.setInterests(['Technology', 'Music']);
      notifier.setRequestVerifiedPlus(true);

      const failure = ServerFailure('Failed to complete onboarding');

      when(mockOnboardingService.completeOnboarding(
        uid: testUid,
        firstName: 'John',
        lastName: 'Doe',
        email: testEmail,
        residence: 'Campus Housing',
        major: 'Computer Science',
        interests: ['Technology', 'Music'],
        requestVerifiedPlus: true,
      )).thenAnswer((_) async => const Result.left(failure));

      await notifier.completeOnboarding(testUid);
      expect(notifier.state.status, equals(OnboardingStatus.error));
      expect(notifier.state.error, equals(failure));

      // Act
      notifier.clearError();

      // Assert
      expect(notifier.state.status, equals(OnboardingStatus.idle));
      expect(notifier.state.error, isNull);
    });
  });
} 