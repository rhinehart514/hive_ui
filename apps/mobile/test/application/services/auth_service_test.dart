import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ui/core/result/result.dart';
import 'package:hive_ui/data/datasources/firebase_auth_datasource.dart';
import 'package:hive_ui/application/services/auth_service.dart';
import 'package:hive_ui/domain/entities/auth_challenge.dart';
import 'package:hive_ui/domain/failures/auth_failure.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Import generated mocks
import 'auth_service_test.mocks.dart';

// Annotate the class to be mocked
@GenerateMocks([AuthDataSource])
void main() {
  late MockAuthDataSource mockAuthDataSource;
  late AuthService authService;

  setUp(() {
    mockAuthDataSource = MockAuthDataSource();
    authService = AuthService(mockAuthDataSource);
  });

  group('AuthService Tests', () {
    const testEmail = 'test@example.com';
    const testEmailWithWhitespace = '  test@example.com  ';
    const normalizedEmail = 'test@example.com'; // Lowercase and trimmed
    const testToken = 'magic-token-123';
    const testUserId = 'user-id-456';
    const testFailure = ServerFailure('DataSource Error');

    group('requestMagicLink', () {
      test('should call requestMagicLink on data source with normalized email and return result', () async {
        // Arrange
        when(mockAuthDataSource.requestMagicLink(normalizedEmail))
            .thenAnswer((_) async => const Result.right(normalizedEmail)); // Return email on success
        
        // Act
        final result = await authService.requestMagicLink(testEmailWithWhitespace);
        
        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.getSuccess, equals(normalizedEmail));
        verify(mockAuthDataSource.requestMagicLink(normalizedEmail)).called(1);
      });

      test('should return Failure when data source requestMagicLink fails', () async {
        // Arrange
        when(mockAuthDataSource.requestMagicLink(normalizedEmail))
            .thenAnswer((_) async => const Result.left(testFailure));
        
        // Act
        final result = await authService.requestMagicLink(testEmailWithWhitespace);
        
        // Assert
        expect(result.isFailure, isTrue);
        expect(result.getFailure, equals(testFailure));
        verify(mockAuthDataSource.requestMagicLink(normalizedEmail)).called(1);
      });
    });

    group('verifyMagicLink', () {
      test('should call verifyMagicLink on data source and return user ID on success', () async {
        // Arrange
        when(mockAuthDataSource.verifyMagicLink(testToken))
            .thenAnswer((_) async => const Result.right(testUserId));
        
        // Act
        final result = await authService.verifyMagicLink(testToken);
        
        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.getSuccess, equals(testUserId));
        verify(mockAuthDataSource.verifyMagicLink(testToken)).called(1);
      });

      test('should return Failure when data source verifyMagicLink fails', () async {
        // Arrange
        when(mockAuthDataSource.verifyMagicLink(testToken))
            .thenAnswer((_) async => const Result.left(testFailure));
        
        // Act
        final result = await authService.verifyMagicLink(testToken);
        
        // Assert
        expect(result.isFailure, isTrue);
        expect(result.getFailure, equals(testFailure));
        verify(mockAuthDataSource.verifyMagicLink(testToken)).called(1);
      });
    });

    group('signOut', () {
      test('should call signOut on data source and return success', () async {
        // Arrange
        when(mockAuthDataSource.signOut())
            .thenAnswer((_) async => const Result.right(null));
        
        // Act
        final result = await authService.signOut();
        
        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockAuthDataSource.signOut()).called(1);
      });

       test('should return Failure when data source signOut fails', () async {
         // Arrange
         when(mockAuthDataSource.signOut())
             .thenAnswer((_) async => const Result.left(testFailure));
         
         // Act
         final result = await authService.signOut();
         
         // Assert
         expect(result.isFailure, isTrue);
         expect(result.getFailure, equals(testFailure));
         verify(mockAuthDataSource.signOut()).called(1);
       });
    });

    group('createAuthChallenge', () {
       test('should create an AuthChallenge with the given email and pending status', () {
         // Act
         final challenge = authService.createAuthChallenge(testEmail);
         
         // Assert
         expect(challenge, isA<AuthChallenge>());
         expect(challenge.email, equals(testEmail));
         expect(challenge.status, equals(AuthChallengeStatus.pending));
         expect(challenge.isExpired(), isFalse); // Should not be expired immediately
         // Check expiry is roughly 15 mins in the future
         expect(challenge.expiresAt.isAfter(DateTime.now().add(const Duration(minutes: 14))), isTrue);
         expect(challenge.expiresAt.isBefore(DateTime.now().add(const Duration(minutes: 16))), isTrue);
       });
    });

  });
} 