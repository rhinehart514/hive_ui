import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ui/data/datasources/secure_storage.dart';
import 'package:hive_ui/domain/failures/auth_failure.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'secure_storage_test.mocks.dart';

@GenerateMocks([FlutterSecureStorage])
void main() {
  late MockFlutterSecureStorage mockSecureStorage;
  late FlutterSecureStorageImpl secureStorageImpl;

  setUp(() {
    mockSecureStorage = MockFlutterSecureStorage();
    secureStorageImpl = FlutterSecureStorageImpl(mockSecureStorage);
  });

  group('FlutterSecureStorageImpl Tests', () {
    const testKey = 'test_key';
    const testValue = 'test_value';
    const testFailure = ServerFailure('Storage Error');
    final testException = Exception('Platform Error');

    group('saveString', () {
      test('should call write on FlutterSecureStorage and return success', () async {
        // Arrange
        when(mockSecureStorage.write(key: testKey, value: testValue))
            .thenAnswer((_) async => {}); // Simulate successful write
        // Act
        final result = await secureStorageImpl.saveString(testKey, testValue);
        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockSecureStorage.write(key: testKey, value: testValue)).called(1);
      });

      test('should return Failure when write throws an exception', () async {
        // Arrange
        when(mockSecureStorage.write(key: testKey, value: testValue))
            .thenThrow(testException);
        // Act
        final result = await secureStorageImpl.saveString(testKey, testValue);
        // Assert
        expect(result.isFailure, isTrue);
        expect(result.getFailure, isA<ServerFailure>());
        expect(result.getFailure.message, contains('Failed to save secure data'));
        verify(mockSecureStorage.write(key: testKey, value: testValue)).called(1);
      });
    });

    group('getString', () {
      test('should call read on FlutterSecureStorage and return value on success', () async {
        // Arrange
        when(mockSecureStorage.read(key: testKey))
            .thenAnswer((_) async => testValue);
        // Act
        final result = await secureStorageImpl.getString(testKey);
        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.getSuccess, equals(testValue));
        verify(mockSecureStorage.read(key: testKey)).called(1);
      });

      test('should call read on FlutterSecureStorage and return null if not found', () async {
        // Arrange
        when(mockSecureStorage.read(key: testKey))
            .thenAnswer((_) async => null);
        // Act
        final result = await secureStorageImpl.getString(testKey);
        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.getSuccess, isNull);
        verify(mockSecureStorage.read(key: testKey)).called(1);
      });

      test('should return Failure when read throws an exception', () async {
        // Arrange
        when(mockSecureStorage.read(key: testKey)).thenThrow(testException);
        // Act
        final result = await secureStorageImpl.getString(testKey);
        // Assert
        expect(result.isFailure, isTrue);
        expect(result.getFailure, isA<ServerFailure>());
        expect(result.getFailure.message, contains('Failed to read secure data'));
        verify(mockSecureStorage.read(key: testKey)).called(1);
      });
    });

    group('deleteKey', () {
      test('should call delete on FlutterSecureStorage and return success', () async {
        // Arrange
        when(mockSecureStorage.delete(key: testKey)).thenAnswer((_) async => {});
        // Act
        final result = await secureStorageImpl.deleteKey(testKey);
        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockSecureStorage.delete(key: testKey)).called(1);
      });

       test('should return Failure when delete throws an exception', () async {
         // Arrange
         when(mockSecureStorage.delete(key: testKey)).thenThrow(testException);
         // Act
         final result = await secureStorageImpl.deleteKey(testKey);
         // Assert
         expect(result.isFailure, isTrue);
         expect(result.getFailure, isA<ServerFailure>());
         expect(result.getFailure.message, contains('Failed to delete secure data'));
         verify(mockSecureStorage.delete(key: testKey)).called(1);
       });
    });

    group('clearAll', () {
      test('should call deleteAll on FlutterSecureStorage and return success', () async {
        // Arrange
        when(mockSecureStorage.deleteAll()).thenAnswer((_) async => {});
        // Act
        final result = await secureStorageImpl.clearAll();
        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockSecureStorage.deleteAll()).called(1);
      });

       test('should return Failure when deleteAll throws an exception', () async {
         // Arrange
         when(mockSecureStorage.deleteAll()).thenThrow(testException);
         // Act
         final result = await secureStorageImpl.clearAll();
         // Assert
         expect(result.isFailure, isTrue);
         expect(result.getFailure, isA<ServerFailure>());
         expect(result.getFailure.message, contains('Failed to clear secure storage'));
         verify(mockSecureStorage.deleteAll()).called(1);
       });
    });

    // --- Test Helper Methods --- 

    group('saveAuthTokens', () {
      const authToken = 'auth-123';
      const refreshToken = 'refresh-456';
      const userId = 'user-789';

      test('should write auth token, refresh token, and user ID', () async {
        // Arrange
        when(mockSecureStorage.write(key: FlutterSecureStorageImpl.kAuthToken, value: authToken))
            .thenAnswer((_) async => {});
        when(mockSecureStorage.write(key: FlutterSecureStorageImpl.kRefreshToken, value: refreshToken))
            .thenAnswer((_) async => {});
         when(mockSecureStorage.write(key: FlutterSecureStorageImpl.kUserId, value: userId))
             .thenAnswer((_) async => {});

        // Act
        final result = await secureStorageImpl.saveAuthTokens(
            authToken: authToken, refreshToken: refreshToken, userId: userId);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockSecureStorage.write(key: FlutterSecureStorageImpl.kAuthToken, value: authToken)).called(1);
        verify(mockSecureStorage.write(key: FlutterSecureStorageImpl.kRefreshToken, value: refreshToken)).called(1);
        verify(mockSecureStorage.write(key: FlutterSecureStorageImpl.kUserId, value: userId)).called(1);
      });

      test('should write only auth token and user ID if refresh token is null', () async {
        // Arrange
        when(mockSecureStorage.write(key: FlutterSecureStorageImpl.kAuthToken, value: authToken))
            .thenAnswer((_) async => {});
         when(mockSecureStorage.write(key: FlutterSecureStorageImpl.kUserId, value: userId))
             .thenAnswer((_) async => {});

        // Act
        final result = await secureStorageImpl.saveAuthTokens(
            authToken: authToken, refreshToken: null, userId: userId); // Null refresh token

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockSecureStorage.write(key: FlutterSecureStorageImpl.kAuthToken, value: authToken)).called(1);
        verifyNever(mockSecureStorage.write(key: FlutterSecureStorageImpl.kRefreshToken, value: anyNamed('value')));
        verify(mockSecureStorage.write(key: FlutterSecureStorageImpl.kUserId, value: userId)).called(1);
      });

       test('should return Failure if any write throws an exception', () async {
         // Arrange
         when(mockSecureStorage.write(key: FlutterSecureStorageImpl.kAuthToken, value: authToken))
             .thenAnswer((_) async => {}); // First write succeeds
         when(mockSecureStorage.write(key: FlutterSecureStorageImpl.kRefreshToken, value: refreshToken))
             .thenThrow(testException); // Second write fails
         when(mockSecureStorage.write(key: FlutterSecureStorageImpl.kUserId, value: userId))
             .thenAnswer((_) async => {}); // This won't be reached

         // Act
         final result = await secureStorageImpl.saveAuthTokens(
             authToken: authToken, refreshToken: refreshToken, userId: userId);

         // Assert
         expect(result.isFailure, isTrue);
         expect(result.getFailure, isA<ServerFailure>());
         expect(result.getFailure.message, contains('Failed to save auth tokens'));
         // Verify the first write was attempted, the second failed, third not attempted
         verify(mockSecureStorage.write(key: FlutterSecureStorageImpl.kAuthToken, value: authToken)).called(1);
         verify(mockSecureStorage.write(key: FlutterSecureStorageImpl.kRefreshToken, value: refreshToken)).called(1);
         verifyNever(mockSecureStorage.write(key: FlutterSecureStorageImpl.kUserId, value: userId));
       });
    });

    group('clearAuthData', () {
      test('should delete all known auth keys', () async {
        // Arrange
        when(mockSecureStorage.delete(key: anyNamed('key'))).thenAnswer((_) async {});

        // Act
        final result = await secureStorageImpl.clearAuthData();

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockSecureStorage.delete(key: FlutterSecureStorageImpl.kAuthToken)).called(1);
        verify(mockSecureStorage.delete(key: FlutterSecureStorageImpl.kRefreshToken)).called(1);
        verify(mockSecureStorage.delete(key: FlutterSecureStorageImpl.kUserId)).called(1);
        verify(mockSecureStorage.delete(key: FlutterSecureStorageImpl.kEmail)).called(1);
        verify(mockSecureStorage.delete(key: FlutterSecureStorageImpl.kMagicLinkToken)).called(1);
      });

       test('should return Failure if any delete throws an exception', () async {
         // Arrange
         when(mockSecureStorage.delete(key: FlutterSecureStorageImpl.kAuthToken)).thenAnswer((_) async {});
         when(mockSecureStorage.delete(key: FlutterSecureStorageImpl.kRefreshToken)).thenThrow(testException);
         when(mockSecureStorage.delete(key: FlutterSecureStorageImpl.kUserId)).thenAnswer((_) async {});
         when(mockSecureStorage.delete(key: FlutterSecureStorageImpl.kEmail)).thenAnswer((_) async {});
         when(mockSecureStorage.delete(key: FlutterSecureStorageImpl.kMagicLinkToken)).thenAnswer((_) async {});

         // Act
         final result = await secureStorageImpl.clearAuthData();

         // Assert
         expect(result.isFailure, isTrue);
         expect(result.getFailure, isA<ServerFailure>());
         expect(result.getFailure.message, contains('Failed to clear auth data'));
         // Verify all deletes were attempted up to the point of failure
         verify(mockSecureStorage.delete(key: FlutterSecureStorageImpl.kAuthToken)).called(1);
         verify(mockSecureStorage.delete(key: FlutterSecureStorageImpl.kRefreshToken)).called(1);
         verifyNever(mockSecureStorage.delete(key: FlutterSecureStorageImpl.kUserId)); // Might depend on exception handling strategy
       });
    });

    // Tests for save/get MagicLinkEmail and MagicLinkToken delegate to save/getString
    // We can add simple tests to ensure they use the correct keys

    group('saveMagicLinkEmail', () {
      test('should call saveString with the correct key', () async {
         when(mockSecureStorage.write(key: FlutterSecureStorageImpl.kEmail, value: 'test@email.com'))
             .thenAnswer((_) async => {});
         await secureStorageImpl.saveMagicLinkEmail('test@email.com');
         verify(mockSecureStorage.write(key: FlutterSecureStorageImpl.kEmail, value: 'test@email.com')).called(1);
      });
    });

     group('getMagicLinkEmail', () {
       test('should call getString with the correct key', () async {
          when(mockSecureStorage.read(key: FlutterSecureStorageImpl.kEmail))
              .thenAnswer((_) async => 'test@email.com');
          await secureStorageImpl.getMagicLinkEmail();
          verify(mockSecureStorage.read(key: FlutterSecureStorageImpl.kEmail)).called(1);
       });
     });

     group('saveMagicLinkToken', () {
       test('should call saveString with the correct key', () async {
          when(mockSecureStorage.write(key: FlutterSecureStorageImpl.kMagicLinkToken, value: 'token123'))
              .thenAnswer((_) async => {});
          await secureStorageImpl.saveMagicLinkToken('token123');
          verify(mockSecureStorage.write(key: FlutterSecureStorageImpl.kMagicLinkToken, value: 'token123')).called(1);
       });
     });

     group('getMagicLinkToken', () {
       test('should call getString with the correct key', () async {
          when(mockSecureStorage.read(key: FlutterSecureStorageImpl.kMagicLinkToken))
              .thenAnswer((_) async => 'token123');
          await secureStorageImpl.getMagicLinkToken();
          verify(mockSecureStorage.read(key: FlutterSecureStorageImpl.kMagicLinkToken)).called(1);
       });
     });

  });
} 