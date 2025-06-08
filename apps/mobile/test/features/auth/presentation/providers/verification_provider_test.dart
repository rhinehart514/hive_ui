import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ui/application/services/verification_service.dart';
import 'package:hive_ui/core/result/result.dart';
import 'package:hive_ui/domain/failures/auth_failure.dart';
import 'package:hive_ui/features/auth/presentation/providers/verification_provider.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'verification_provider_test.mocks.dart';

@GenerateMocks([VerificationService])
void main() {
  late VerificationNotifier notifier;
  late MockVerificationService mockVerificationService;
  late ProviderContainer container;
  
  const testUserId = 'test-uid';
  
  setUp(() {
    mockVerificationService = MockVerificationService();
    notifier = VerificationNotifier(
      verificationService: mockVerificationService,
      userId: testUserId,
    );
    container = ProviderContainer(
      overrides: [],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('initial state should be VerificationInitial', () {
    // Create a new notifier to test initial state
    final freshNotifier = VerificationNotifier(
      verificationService: mockVerificationService,
      userId: testUserId,
    );
    
    // Assert
    expect(freshNotifier.state, isA<VerificationInitial>());
  });

  group('_initVerificationStatus', () {
    test('should change state to VerificationNotRequested when status is notRequested', () async {
      // Arrange
      when(mockVerificationService.getVerificationStatus(testUserId))
          .thenAnswer((_) async => const Result.right(VerificationStatus.notRequested));
      
      // Act - initialization happens in constructor
      final notifier = VerificationNotifier(
        verificationService: mockVerificationService,
        userId: testUserId,
      );
      
      // Allow async operations to complete
      await Future.delayed(Duration.zero);
      
      // Assert
      expect(notifier.state, isA<VerificationNotRequested>());
      verify(mockVerificationService.getVerificationStatus(testUserId)).called(1);
    });
    
    test('should change state to VerificationPending when status is pending', () async {
      // Arrange
      when(mockVerificationService.getVerificationStatus(testUserId))
          .thenAnswer((_) async => const Result.right(VerificationStatus.pending));
      
      // Act - initialization happens in constructor
      final notifier = VerificationNotifier(
        verificationService: mockVerificationService,
        userId: testUserId,
      );
      
      // Allow async operations to complete
      await Future.delayed(Duration.zero);
      
      // Assert
      expect(notifier.state, isA<VerificationPending>());
      verify(mockVerificationService.getVerificationStatus(testUserId)).called(1);
    });
    
    test('should change state to VerificationApproved when status is approved', () async {
      // Arrange
      when(mockVerificationService.getVerificationStatus(testUserId))
          .thenAnswer((_) async => const Result.right(VerificationStatus.approved));
      
      // Act - initialization happens in constructor
      final notifier = VerificationNotifier(
        verificationService: mockVerificationService,
        userId: testUserId,
      );
      
      // Allow async operations to complete
      await Future.delayed(Duration.zero);
      
      // Assert
      expect(notifier.state, isA<VerificationApproved>());
      verify(mockVerificationService.getVerificationStatus(testUserId)).called(1);
    });
    
    test('should change state to VerificationRejected when status is rejected', () async {
      // Arrange
      when(mockVerificationService.getVerificationStatus(testUserId))
          .thenAnswer((_) async => const Result.right(VerificationStatus.rejected));
      
      // Act - initialization happens in constructor
      final notifier = VerificationNotifier(
        verificationService: mockVerificationService,
        userId: testUserId,
      );
      
      // Allow async operations to complete
      await Future.delayed(Duration.zero);
      
      // Assert
      expect(notifier.state, isA<VerificationRejected>());
      verify(mockVerificationService.getVerificationStatus(testUserId)).called(1);
    });
    
    test('should change state to VerificationError when getVerificationStatus fails', () async {
      // Arrange
      const failure = ServerFailure('Failed to get verification status');
      when(mockVerificationService.getVerificationStatus(testUserId))
          .thenAnswer((_) async => const Result.left(failure));
      
      // Act - initialization happens in constructor
      final notifier = VerificationNotifier(
        verificationService: mockVerificationService,
        userId: testUserId,
      );
      
      // Allow async operations to complete
      await Future.delayed(Duration.zero);
      
      // Assert
      expect(notifier.state, isA<VerificationError>());
      expect((notifier.state as VerificationError).failure, equals(failure));
      verify(mockVerificationService.getVerificationStatus(testUserId)).called(1);
    });
    
    test('should set state to VerificationNotRequested when userId is empty', () async {
      // Act - initialization happens in constructor with empty userId
      final notifier = VerificationNotifier(
        verificationService: mockVerificationService,
        userId: '',
      );
      
      // Allow async operations to complete
      await Future.delayed(Duration.zero);
      
      // Assert
      expect(notifier.state, isA<VerificationNotRequested>());
      verifyNever(mockVerificationService.getVerificationStatus(any));
    });
  });

  group('requestVerification', () {
    test('should update state to VerificationRequestInProgress then VerificationPending when successful', () async {
      // Arrange
      when(mockVerificationService.requestVerification(testUserId))
          .thenAnswer((_) async => const Result.right(null));
      
      // Act
      notifier.requestVerification();
      
      // Assert - should immediately be in progress
      expect(notifier.state, isA<VerificationRequestInProgress>());
      
      // Allow async operations to complete
      await Future.delayed(Duration.zero);
      
      // Assert - should be pending after completion
      expect(notifier.state, isA<VerificationPending>());
      verify(mockVerificationService.requestVerification(testUserId)).called(1);
    });
    
    test('should update state to VerificationError when requestVerification fails', () async {
      // Arrange
      const failure = ServerFailure('Failed to request verification');
      when(mockVerificationService.requestVerification(testUserId))
          .thenAnswer((_) async => const Result.left(failure));
      
      // Act
      notifier.requestVerification();
      
      // Allow async operations to complete
      await Future.delayed(Duration.zero);
      
      // Assert
      expect(notifier.state, isA<VerificationError>());
      expect((notifier.state as VerificationError).failure, equals(failure));
      verify(mockVerificationService.requestVerification(testUserId)).called(1);
    });
    
    test('should set state to VerificationError when userId is empty', () async {
      // Arrange - Create notifier with empty userId
      final notifier = VerificationNotifier(
        verificationService: mockVerificationService,
        userId: '',
      );
      
      // Act
      notifier.requestVerification();
      
      // Assert
      expect(notifier.state, isA<VerificationError>());
      expect((notifier.state as VerificationError).failure.message, contains('empty'));
      verifyNever(mockVerificationService.requestVerification(any));
    });
  });

  group('cancelVerificationRequest', () {
    test('should update state to VerificationNotRequested when cancelVerificationRequest succeeds', () async {
      // Arrange - Set the initial state to VerificationPending
      when(mockVerificationService.getVerificationStatus(testUserId))
          .thenAnswer((_) async => const Result.right(VerificationStatus.pending));
      
      final notifier = VerificationNotifier(
        verificationService: mockVerificationService,
        userId: testUserId,
      );
      
      // Allow initialization to complete
      await Future.delayed(Duration.zero);
      expect(notifier.state, isA<VerificationPending>());
      
      // Setup for the cancel request
      when(mockVerificationService.cancelVerificationRequest(testUserId))
          .thenAnswer((_) async => const Result.right(null));
      
      // Act
      notifier.cancelVerificationRequest();
      
      // Allow async operations to complete
      await Future.delayed(Duration.zero);
      
      // Assert
      expect(notifier.state, isA<VerificationNotRequested>());
      verify(mockVerificationService.cancelVerificationRequest(testUserId)).called(1);
    });
    
    test('should update state to VerificationError when cancelVerificationRequest fails', () async {
      // Arrange - Set the initial state to VerificationPending
      when(mockVerificationService.getVerificationStatus(testUserId))
          .thenAnswer((_) async => const Result.right(VerificationStatus.pending));
      
      final notifier = VerificationNotifier(
        verificationService: mockVerificationService,
        userId: testUserId,
      );
      
      // Allow initialization to complete
      await Future.delayed(Duration.zero);
      expect(notifier.state, isA<VerificationPending>());
      
      // Setup for the cancel request
      const failure = ServerFailure('Failed to cancel verification');
      when(mockVerificationService.cancelVerificationRequest(testUserId))
          .thenAnswer((_) async => const Result.left(failure));
      
      // Act
      notifier.cancelVerificationRequest();
      
      // Allow async operations to complete
      await Future.delayed(Duration.zero);
      
      // Assert
      expect(notifier.state, isA<VerificationError>());
      expect((notifier.state as VerificationError).failure, equals(failure));
      verify(mockVerificationService.cancelVerificationRequest(testUserId)).called(1);
    });
    
    test('should set state to VerificationError when userId is empty', () async {
      // Arrange - Create notifier with empty userId and set initial state
      final notifier = VerificationNotifier(
        verificationService: mockVerificationService,
        userId: '',
      );
      
      // Act
      notifier.cancelVerificationRequest();
      
      // Assert
      expect(notifier.state, isA<VerificationError>());
      expect((notifier.state as VerificationError).failure.message, contains('empty'));
      verifyNever(mockVerificationService.cancelVerificationRequest(any));
    });
    
    test('should set state to VerificationError when not in VerificationPending state', () async {
      // Arrange - Set the initial state to VerificationNotRequested
      when(mockVerificationService.getVerificationStatus(testUserId))
          .thenAnswer((_) async => const Result.right(VerificationStatus.notRequested));
      
      final notifier = VerificationNotifier(
        verificationService: mockVerificationService,
        userId: testUserId,
      );
      
      // Allow initialization to complete
      await Future.delayed(Duration.zero);
      expect(notifier.state, isA<VerificationNotRequested>());
      
      // Act
      notifier.cancelVerificationRequest();
      
      // Allow async operations to complete
      await Future.delayed(Duration.zero);
      
      // Assert
      expect(notifier.state, isA<VerificationError>());
      expect((notifier.state as VerificationError).failure.message, contains('No pending verification'));
      verifyNever(mockVerificationService.cancelVerificationRequest(any));
    });
  });

  group('refreshVerificationStatus', () {
    test('should update state to match current verification status', () async {
      // Arrange - Set up the initial status check
      when(mockVerificationService.getVerificationStatus(testUserId))
          .thenAnswer((_) async => const Result.right(VerificationStatus.notRequested));
      
      final notifier = VerificationNotifier(
        verificationService: mockVerificationService,
        userId: testUserId,
      );
      
      // Allow initialization to complete
      await Future.delayed(Duration.zero);
      expect(notifier.state, isA<VerificationNotRequested>());
      
      // Change the mock response for the refresh
      when(mockVerificationService.getVerificationStatus(testUserId))
          .thenAnswer((_) async => const Result.right(VerificationStatus.approved));
      
      // Act
      await notifier.refreshVerificationStatus();
      
      // Assert
      expect(notifier.state, isA<VerificationApproved>());
      verify(mockVerificationService.getVerificationStatus(testUserId)).called(2); // Once for init, once for refresh
    });
  });

  group('isVerifiedPlus', () {
    test('should return true when user is verified plus', () async {
      // Arrange
      when(mockVerificationService.isVerifiedPlus(testUserId))
          .thenAnswer((_) async => const Result.right(true));
      
      // Act
      final result = await notifier.isVerifiedPlus();
      
      // Assert
      expect(result, isTrue);
      verify(mockVerificationService.isVerifiedPlus(testUserId)).called(1);
    });
    
    test('should return false when user is not verified plus', () async {
      // Arrange
      when(mockVerificationService.isVerifiedPlus(testUserId))
          .thenAnswer((_) async => const Result.right(false));
      
      // Act
      final result = await notifier.isVerifiedPlus();
      
      // Assert
      expect(result, isFalse);
      verify(mockVerificationService.isVerifiedPlus(testUserId)).called(1);
    });
    
    test('should return false when service returns failure', () async {
      // Arrange
      const failure = ServerFailure('Failed to check verification status');
      when(mockVerificationService.isVerifiedPlus(testUserId))
          .thenAnswer((_) async => const Result.left(failure));
      
      // Act
      final result = await notifier.isVerifiedPlus();
      
      // Assert
      expect(result, isFalse);
      verify(mockVerificationService.isVerifiedPlus(testUserId)).called(1);
    });
    
    test('should return false when userId is empty', () async {
      // Arrange - Create notifier with empty userId
      final notifier = VerificationNotifier(
        verificationService: mockVerificationService,
        userId: '',
      );
      
      // Act
      final result = await notifier.isVerifiedPlus();
      
      // Assert
      expect(result, isFalse);
      verifyNever(mockVerificationService.isVerifiedPlus(any));
    });
  });
} 