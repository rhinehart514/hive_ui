import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ui/application/services/config_service.dart';
import 'package:hive_ui/core/result/result.dart';
import 'package:hive_ui/data/datasources/remote_config_source.dart';
import 'package:hive_ui/domain/failures/auth_failure.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'config_service_test.mocks.dart';

@GenerateMocks([ConfigDataSource])
void main() {
  late MockConfigDataSource mockConfigDataSource;
  late ConfigService configService;

  setUp(() {
    mockConfigDataSource = MockConfigDataSource();
    configService = ConfigService(mockConfigDataSource);
  });

  group('ConfigService', () {
    test('getAllowedDomains should return domains from data source', () async {
      // Arrange
      final expectedDomains = ['buffalo.edu', 'example.edu'];
      when(mockConfigDataSource.getAllowedDomains())
          .thenAnswer((_) async => Result.right(expectedDomains));

      // Act
      final result = await configService.getAllowedDomains();

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.getSuccess, equals(expectedDomains));
      verify(mockConfigDataSource.getAllowedDomains()).called(1);
    });

    test('getAllowedDomains should return default domains on error', () async {
      // Arrange
      when(mockConfigDataSource.getAllowedDomains())
          .thenAnswer((_) async => const Result.left(ServerFailure('Error')));

      // Act
      final result = await configService.getAllowedDomains();

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.getSuccess, contains('buffalo.edu'));
      verify(mockConfigDataSource.getAllowedDomains()).called(1);
    });

    test('isEmailDomainAllowed should return true for allowed domain', () async {
      // Arrange
      when(mockConfigDataSource.getAllowedDomains())
          .thenAnswer((_) async => const Result.right(['buffalo.edu']));

      // Act
      final result = await configService.isEmailDomainAllowed('user@buffalo.edu');

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.getSuccess, isTrue);
    });

    test('isEmailDomainAllowed should return false for disallowed domain', () async {
      // Arrange
      when(mockConfigDataSource.getAllowedDomains())
          .thenAnswer((_) async => const Result.right(['buffalo.edu']));

      // Act
      final result = await configService.isEmailDomainAllowed('user@example.com');

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.getSuccess, isFalse);
    });

    test('isEmailDomainAllowed should return failure for invalid email', () async {
      // Act
      final result = await configService.isEmailDomainAllowed('invalid-email');

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.getFailure, isA<InvalidEmailFailure>());
    });

    test('getInterestsList should return interests from data source', () async {
      // Arrange
      final expectedInterests = ['Art', 'Music', 'Sports'];
      when(mockConfigDataSource.getInterestsList())
          .thenAnswer((_) async => Result.right(expectedInterests));

      // Act
      final result = await configService.getInterestsList();

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.getSuccess, equals(expectedInterests));
      verify(mockConfigDataSource.getInterestsList()).called(1);
    });

    test('getInterestsList should return default interests on error', () async {
      // Arrange
      when(mockConfigDataSource.getInterestsList())
          .thenAnswer((_) async => const Result.left(ServerFailure('Error')));

      // Act
      final result = await configService.getInterestsList();

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.getSuccess.length, greaterThan(0));
      verify(mockConfigDataSource.getInterestsList()).called(1);
    });

    test('isFeatureEnabled should return feature flag from data source', () async {
      // Arrange
      when(mockConfigDataSource.isFeatureEnabled('test_feature'))
          .thenAnswer((_) async => const Result.right(true));

      // Act
      final result = await configService.isFeatureEnabled('test_feature');

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.getSuccess, isTrue);
      verify(mockConfigDataSource.isFeatureEnabled('test_feature')).called(1);
    });

    test('isValidEmailFormat should return true for valid email', () {
      // Act
      final result = configService.isValidEmailFormat('user@example.com');

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.getSuccess, isTrue);
    });

    test('isValidEmailFormat should return failure for invalid email', () {
      // Act
      final result = configService.isValidEmailFormat('invalid-email');

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.getFailure, isA<InvalidEmailFailure>());
    });

    test('isValidEmailFormat should return failure for empty email', () {
      // Act
      final result = configService.isValidEmailFormat('');

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.getFailure, isA<InvalidEmailFailure>());
      expect(result.getFailure.message, contains('cannot be empty'));
    });
  });
} 