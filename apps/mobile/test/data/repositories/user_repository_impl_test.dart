import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ui/core/result/result.dart';
import 'package:hive_ui/data/datasources/firestore_user_datasource.dart';
import 'package:hive_ui/data/repositories/user_repository_impl.dart';
import 'package:hive_ui/domain/entities/user_profile.dart';
import 'package:hive_ui/domain/failures/auth_failure.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Import the generated mocks
import 'user_repository_impl_test.mocks.dart';

// Annotate the class to be mocked
@GenerateMocks([UserDataSource])
void main() {
  late MockUserDataSource mockUserDataSource;
  late UserRepositoryImpl userRepository;

  // Helper to create a test profile
  UserProfile createTestProfile({
    String username = 'testuser',
    String email = 'test@example.com',
    String firstName = 'Test',
    String lastName = 'User',
    String residence = 'Test Residence',
    String major = 'Test Major',
    List<String> interests = const ['interest1'],
    UserTier tier = UserTier.base,
  }) {
    return UserProfile(
      username: username,
      email: email,
      firstName: firstName,
      lastName: lastName,
      residence: residence,
      major: major,
      interests: interests,
      tier: tier,
    );
  }

  setUp(() {
    mockUserDataSource = MockUserDataSource();
    userRepository = UserRepositoryImpl(mockUserDataSource);
  });

  group('UserRepositoryImpl Tests', () {
    const testUid = 'test-uid';
    final testProfile = createTestProfile();
    final testUpdates = {'major': 'New Major'};
    const testFailure = ServerFailure('DataSource Error');

    group('getUserProfile', () {
      test('should return UserProfile on success from data source', () async {
        // Arrange
        when(mockUserDataSource.getUserProfile(testUid))
            .thenAnswer((_) async => Result.right(testProfile));
        // Act
        final result = await userRepository.getUserProfile(testUid);
        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.getSuccess, equals(testProfile));
        verify(mockUserDataSource.getUserProfile(testUid)).called(1);
      });

      test('should return Failure on failure from data source', () async {
        // Arrange
        when(mockUserDataSource.getUserProfile(testUid))
            .thenAnswer((_) async => const Result.left(testFailure));
        // Act
        final result = await userRepository.getUserProfile(testUid);
        // Assert
        expect(result.isFailure, isTrue);
        expect(result.getFailure, equals(testFailure));
        verify(mockUserDataSource.getUserProfile(testUid)).called(1);
      });
    });

    group('createUserProfile', () {
       test('should return UserProfile on success from data source saveUserProfile', () async {
         // Arrange
         when(mockUserDataSource.saveUserProfile(testProfile, testUid))
             .thenAnswer((_) async => Result.right(testProfile));
         // Act
         final result = await userRepository.createUserProfile(testProfile, testUid);
         // Assert
         expect(result.isSuccess, isTrue);
         expect(result.getSuccess, equals(testProfile));
         verify(mockUserDataSource.saveUserProfile(testProfile, testUid)).called(1);
       });

       test('should return Failure on failure from data source saveUserProfile', () async {
         // Arrange
         when(mockUserDataSource.saveUserProfile(testProfile, testUid))
             .thenAnswer((_) async => const Result.left(testFailure));
         // Act
         final result = await userRepository.createUserProfile(testProfile, testUid);
         // Assert
         expect(result.isFailure, isTrue);
         expect(result.getFailure, equals(testFailure));
         verify(mockUserDataSource.saveUserProfile(testProfile, testUid)).called(1);
       });
    });

    group('updateUserProfile', () {
      test('should return updated UserProfile on success from data source', () async {
        final updatedProfile = testProfile.copyWith(major: 'New Major');
        // Arrange
        when(mockUserDataSource.updateUserProfile(testUid, testUpdates))
            .thenAnswer((_) async => Result.right(updatedProfile));
        // Act
        final result = await userRepository.updateUserProfile(testUid, testUpdates);
        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.getSuccess, equals(updatedProfile));
        verify(mockUserDataSource.updateUserProfile(testUid, testUpdates)).called(1);
      });

      test('should return Failure on failure from data source', () async {
        // Arrange
        when(mockUserDataSource.updateUserProfile(testUid, testUpdates))
            .thenAnswer((_) async => const Result.left(testFailure));
        // Act
        final result = await userRepository.updateUserProfile(testUid, testUpdates);
        // Assert
        expect(result.isFailure, isTrue);
        expect(result.getFailure, equals(testFailure));
        verify(mockUserDataSource.updateUserProfile(testUid, testUpdates)).called(1);
      });
    });

    group('isUsernameTaken', () {
      test('should return bool on success from data source', () async {
        // Arrange
        when(mockUserDataSource.isUsernameTaken('testuser'))
            .thenAnswer((_) async => const Result.right(true));
        // Act
        final result = await userRepository.isUsernameTaken('testuser');
        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.getSuccess, isTrue);
        verify(mockUserDataSource.isUsernameTaken('testuser')).called(1);
      });

       test('should return Failure on failure from data source', () async {
         // Arrange
         when(mockUserDataSource.isUsernameTaken('testuser'))
             .thenAnswer((_) async => const Result.left(testFailure));
         // Act
         final result = await userRepository.isUsernameTaken('testuser');
         // Assert
         expect(result.isFailure, isTrue);
         expect(result.getFailure, equals(testFailure));
         verify(mockUserDataSource.isUsernameTaken('testuser')).called(1);
       });
    });

    group('getUserProfileByUsername', () {
      test('should return first UserProfile when data source returns non-empty list', () async {
        final profile1 = createTestProfile(username: 'targetuser');
        final profile2 = createTestProfile(username: 'targetuser'); // Same username, different instance
        // Arrange
        when(mockUserDataSource.getUsersByUsername('targetuser'))
            .thenAnswer((_) async => Result.right([profile1, profile2]));
        // Act
        final result = await userRepository.getUserProfileByUsername('targetuser');
        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.getSuccess, equals(profile1)); // Returns the first one
        verify(mockUserDataSource.getUsersByUsername('targetuser')).called(1);
      });

      test('should return AuthFailure when data source returns empty list', () async {
        // Arrange
        when(mockUserDataSource.getUsersByUsername('targetuser'))
            .thenAnswer((_) async => const Result.right([])); // Empty list
        // Act
        final result = await userRepository.getUserProfileByUsername('targetuser');
        // Assert
        expect(result.isFailure, isTrue);
        expect(result.getFailure, isA<AuthFailure>());
        expect(result.getFailure.message, contains('User with this username not found'));
        verify(mockUserDataSource.getUsersByUsername('targetuser')).called(1);
      });

      test('should return Failure when data source returns failure', () async {
        // Arrange
        when(mockUserDataSource.getUsersByUsername('targetuser'))
            .thenAnswer((_) async => const Result.left(testFailure));
        // Act
        final result = await userRepository.getUserProfileByUsername('targetuser');
        // Assert
        expect(result.isFailure, isTrue);
        expect(result.getFailure, equals(testFailure));
        verify(mockUserDataSource.getUsersByUsername('targetuser')).called(1);
      });

       test('should return ServerFailure on exception during processing', () async {
         // Arrange - Simulate exception after successful data source call
         when(mockUserDataSource.getUsersByUsername('targetuser'))
             .thenAnswer((_) async => Result.right([testProfile])); // Valid result initially
         // Make the processing fail (e.g., accessing .first on empty list - though covered above)
         // Let's simulate a different exception type during processing
         when(mockUserDataSource.getUsersByUsername('exceptionuser'))
             .thenThrow(Exception('Unexpected processing error'));

         // Act
         final result = await userRepository.getUserProfileByUsername('exceptionuser');

         // Assert
         expect(result.isFailure, isTrue);
         expect(result.getFailure, isA<ServerFailure>());
         expect(result.getFailure.message, contains('Unexpected processing error'));
         // Verify the underlying call was still attempted
         verify(mockUserDataSource.getUsersByUsername('exceptionuser')).called(1);
       });
    });

    group('requestVerification', () {
      test('should return void Result on success from data source', () async {
        // Arrange
        when(mockUserDataSource.requestVerification(testUid))
            .thenAnswer((_) async => const Result.right(null));
        // Act
        final result = await userRepository.requestVerification(testUid);
        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockUserDataSource.requestVerification(testUid)).called(1);
      });

      test('should return Failure on failure from data source', () async {
        // Arrange
        when(mockUserDataSource.requestVerification(testUid))
            .thenAnswer((_) async => const Result.left(testFailure));
        // Act
        final result = await userRepository.requestVerification(testUid);
        // Assert
        expect(result.isFailure, isTrue);
        expect(result.getFailure, equals(testFailure));
        verify(mockUserDataSource.requestVerification(testUid)).called(1);
      });
    });

    group('cancelVerificationRequest', () {
       test('should update tier to base and return success if user tier is pending', () async {
         final pendingProfile = createTestProfile(tier: UserTier.pending);
         final baseProfile = createTestProfile(tier: UserTier.base); // Expected after update
         // Arrange
         // 1. Mock getUserProfile to return pending user
         when(mockUserDataSource.getUserProfile(testUid))
             .thenAnswer((_) async => Result.right(pendingProfile));
         // 2. Mock updateUserProfile to return success with base tier
         when(mockUserDataSource.updateUserProfile(testUid, {'tier': 'base'}))
             .thenAnswer((_) async => Result.right(baseProfile));

         // Act
         final result = await userRepository.cancelVerificationRequest(testUid);

         // Assert
         expect(result.isSuccess, isTrue);
         verify(mockUserDataSource.getUserProfile(testUid)).called(1);
         verify(mockUserDataSource.updateUserProfile(testUid, {'tier': 'base'})).called(1);
       });

       test('should return AuthFailure if user tier is not pending', () async {
         final baseProfile = createTestProfile(tier: UserTier.base);
         // Arrange
         when(mockUserDataSource.getUserProfile(testUid))
             .thenAnswer((_) async => Result.right(baseProfile));

         // Act
         final result = await userRepository.cancelVerificationRequest(testUid);

         // Assert
         expect(result.isFailure, isTrue);
         expect(result.getFailure, isA<AuthFailure>());
         expect(result.getFailure.message, contains('No pending verification request'));
         verify(mockUserDataSource.getUserProfile(testUid)).called(1);
         verifyNever(mockUserDataSource.updateUserProfile(any, any)); // Update should not be called
       });

       test('should return Failure if getUserProfile fails', () async {
         // Arrange
         when(mockUserDataSource.getUserProfile(testUid))
             .thenAnswer((_) async => const Result.left(testFailure));

         // Act
         final result = await userRepository.cancelVerificationRequest(testUid);

         // Assert
         expect(result.isFailure, isTrue);
         expect(result.getFailure, equals(testFailure));
         verify(mockUserDataSource.getUserProfile(testUid)).called(1);
         verifyNever(mockUserDataSource.updateUserProfile(any, any));
       });

        test('should return Failure if updateUserProfile fails', () async {
          final pendingProfile = createTestProfile(tier: UserTier.pending);
          const updateFailure = ServerFailure('Update Failed');
          // Arrange
          when(mockUserDataSource.getUserProfile(testUid))
              .thenAnswer((_) async => Result.right(pendingProfile));
          when(mockUserDataSource.updateUserProfile(testUid, {'tier': 'base'}))
              .thenAnswer((_) async => const Result.left(updateFailure));

          // Act
          final result = await userRepository.cancelVerificationRequest(testUid);

          // Assert
          expect(result.isFailure, isTrue);
          expect(result.getFailure, equals(updateFailure));
          verify(mockUserDataSource.getUserProfile(testUid)).called(1);
          verify(mockUserDataSource.updateUserProfile(testUid, {'tier': 'base'})).called(1);
        });
    });

    group('getVerificationStatus', () {
       test('should return UserTier on success from getUserProfile', () async {
         // Arrange
         when(mockUserDataSource.getUserProfile(testUid))
             .thenAnswer((_) async => Result.right(testProfile)); // Assuming testProfile has tier=base
         // Act
         final result = await userRepository.getVerificationStatus(testUid);
         // Assert
         expect(result.isSuccess, isTrue);
         expect(result.getSuccess, equals(UserTier.base));
         verify(mockUserDataSource.getUserProfile(testUid)).called(1);
       });

      test('should return Failure on failure from getUserProfile', () async {
        // Arrange
        when(mockUserDataSource.getUserProfile(testUid))
            .thenAnswer((_) async => const Result.left(testFailure));
        // Act
        final result = await userRepository.getVerificationStatus(testUid);
        // Assert
        expect(result.isFailure, isTrue);
        expect(result.getFailure, equals(testFailure));
        verify(mockUserDataSource.getUserProfile(testUid)).called(1);
      });

      test('should return ServerFailure on exception during processing', () async {
        // Arrange - Simulate exception after successful data source call
        when(mockUserDataSource.getUserProfile(testUid))
            .thenThrow(Exception('Unexpected processing error'));

        // Act
        final result = await userRepository.getVerificationStatus(testUid);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.getFailure, isA<ServerFailure>());
        expect(result.getFailure.message, contains('Unexpected processing error'));
        verify(mockUserDataSource.getUserProfile(testUid)).called(1);
      });
    });

  });
} 