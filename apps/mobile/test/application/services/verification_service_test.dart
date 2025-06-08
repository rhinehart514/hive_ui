import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ui/application/services/verification_service.dart';
import 'package:hive_ui/core/result/result.dart';
import 'package:hive_ui/data/datasources/firestore_user_datasource.dart';
import 'package:hive_ui/domain/entities/user_profile.dart';
import 'package:hive_ui/domain/failures/auth_failure.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'verification_service_test.mocks.dart';

@GenerateMocks([UserDataSource])
void main() {
  late MockUserDataSource mockUserDataSource;
  late VerificationService verificationService;

  setUp(() {
    mockUserDataSource = MockUserDataSource();
    verificationService = VerificationService(mockUserDataSource);
  });

  group('VerificationService', () {
    const testUid = 'test-uid';
    const baseUserProfile = UserProfile(
      firstName: 'John',
      lastName: 'Doe',
      email: 'john@example.com',
      username: 'johndoe',
      residence: 'Campus Housing',
      major: 'Computer Science',
      interests: ['Technology'],
      tier: UserTier.base,
    );
    
    const pendingUserProfile = UserProfile(
      firstName: 'John',
      lastName: 'Doe',
      email: 'john@example.com',
      username: 'johndoe',
      residence: 'Campus Housing',
      major: 'Computer Science',
      interests: ['Technology'],
      tier: UserTier.pending,
    );
    
    const verifiedUserProfile = UserProfile(
      firstName: 'John',
      lastName: 'Doe',
      email: 'john@example.com',
      username: 'johndoe',
      residence: 'Campus Housing',
      major: 'Computer Science',
      interests: ['Technology'],
      tier: UserTier.verified_plus,
    );

    test('requestVerification should call the data source method', () async {
      // Arrange
      when(mockUserDataSource.requestVerification(testUid))
          .thenAnswer((_) async => const Result<void, Failure>.right(null));

      // Act
      final result = await verificationService.requestVerification(testUid);

      // Assert
      expect(result.isSuccess, isTrue);
      verify(mockUserDataSource.requestVerification(testUid)).called(1);
    });

    test('getVerificationStatus should return notRequested for base users', () async {
      // Arrange
      when(mockUserDataSource.getUserProfile(testUid))
          .thenAnswer((_) async => const Result<UserProfile, Failure>.right(baseUserProfile));

      // Act
      final result = await verificationService.getVerificationStatus(testUid);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.getSuccess, equals(VerificationStatus.notRequested));
    });

    test('getVerificationStatus should return pending for pending users', () async {
      // Arrange
      when(mockUserDataSource.getUserProfile(testUid))
          .thenAnswer((_) async => const Result<UserProfile, Failure>.right(pendingUserProfile));

      // Act
      final result = await verificationService.getVerificationStatus(testUid);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.getSuccess, equals(VerificationStatus.pending));
    });

    test('getVerificationStatus should return approved for verified_plus users', () async {
      // Arrange
      when(mockUserDataSource.getUserProfile(testUid))
          .thenAnswer((_) async => const Result<UserProfile, Failure>.right(verifiedUserProfile));

      // Act
      final result = await verificationService.getVerificationStatus(testUid);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.getSuccess, equals(VerificationStatus.approved));
    });

    test('cancelVerificationRequest should update profile for pending users', () async {
      // Arrange
      when(mockUserDataSource.getUserProfile(testUid))
          .thenAnswer((_) async => const Result<UserProfile, Failure>.right(pendingUserProfile));
      
      when(mockUserDataSource.updateUserProfile(testUid, {'tier': 'base'}))
          .thenAnswer((_) async => const Result<UserProfile, Failure>.right(baseUserProfile));

      // Act
      final result = await verificationService.cancelVerificationRequest(testUid);

      // Assert
      expect(result.isSuccess, isTrue);
      verify(mockUserDataSource.updateUserProfile(testUid, {'tier': 'base'})).called(1);
    });

    test('cancelVerificationRequest should fail for non-pending users', () async {
      // Arrange
      when(mockUserDataSource.getUserProfile(testUid))
          .thenAnswer((_) async => const Result<UserProfile, Failure>.right(baseUserProfile));

      // Act
      final result = await verificationService.cancelVerificationRequest(testUid);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.getFailure, isA<InvalidInputFailure>());
      verifyNever(mockUserDataSource.updateUserProfile(any, any));
    });

    test('isVerifiedPlus should return true for verified_plus users', () async {
      // Arrange
      when(mockUserDataSource.getUserProfile(testUid))
          .thenAnswer((_) async => const Result<UserProfile, Failure>.right(verifiedUserProfile));

      // Act
      final result = await verificationService.isVerifiedPlus(testUid);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.getSuccess, isTrue);
    });

    test('isVerifiedPlus should return false for non-verified_plus users', () async {
      // Arrange
      when(mockUserDataSource.getUserProfile(testUid))
          .thenAnswer((_) async => const Result<UserProfile, Failure>.right(baseUserProfile));

      // Act
      final result = await verificationService.isVerifiedPlus(testUid);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.getSuccess, isFalse);
    });

    test('upgradeToVerifiedPlus should update user tier', () async {
      // Arrange
      when(mockUserDataSource.getUserProfile(testUid))
          .thenAnswer((_) async => const Result<UserProfile, Failure>.right(pendingUserProfile));
      
      when(mockUserDataSource.saveUserProfile(any, testUid))
          .thenAnswer((_) async => const Result<UserProfile, Failure>.right(verifiedUserProfile));

      // Act
      final result = await verificationService.upgradeToVerifiedPlus(testUid);

      // Assert
      expect(result.isSuccess, isTrue);
      verify(mockUserDataSource.saveUserProfile(any, testUid)).called(1);
    });
  });
} 