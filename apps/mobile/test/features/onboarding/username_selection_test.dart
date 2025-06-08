import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ui/features/onboarding/data/services/username_verification_service.dart';
import 'package:hive_ui/features/onboarding/state/onboarding_state.dart';

void main() {
  group('UsernameVerificationService', () {
    test('validateUsernameFormat should return error for empty username', () {
      // Arrange & Act
      final verificationService = UsernameVerificationService();
      final result = verificationService.validateUsernameFormat('');
      
      // Assert
      expect(result, isNotNull);
      expect(result, equals('Username is required'));
    });

    test('validateUsernameFormat should return error for username too short', () {
      // Arrange & Act
      final verificationService = UsernameVerificationService();
      final result = verificationService.validateUsernameFormat('ab');
      
      // Assert
      expect(result, isNotNull);
      expect(result, equals('Username must be at least 3 characters'));
    });

    test('validateUsernameFormat should return error for username too long', () {
      // Arrange & Act
      final verificationService = UsernameVerificationService();
      final result = verificationService.validateUsernameFormat('abcdefghijklmnopqrstuvwxyz');
      
      // Assert
      expect(result, isNotNull);
      expect(result, equals('Username cannot exceed 20 characters'));
    });

    test('validateUsernameFormat should return error for invalid characters', () {
      // Arrange & Act
      final verificationService = UsernameVerificationService();
      final result = verificationService.validateUsernameFormat('user-name');
      
      // Assert
      expect(result, isNotNull);
      expect(result, equals('Username can only contain letters, numbers, and underscores'));
    });

    test('validateUsernameFormat should return error for username not starting with letter', () {
      // Arrange & Act
      final verificationService = UsernameVerificationService();
      final result = verificationService.validateUsernameFormat('1username');
      
      // Assert
      expect(result, isNotNull);
      expect(result, equals('Username must start with a letter'));
    });

    test('validateUsernameFormat should return null for valid username', () {
      // Arrange & Act
      final verificationService = UsernameVerificationService();
      final result = verificationService.validateUsernameFormat('username123');
      
      // Assert
      expect(result, isNull);
    });

    test('checkUsernameAvailability should return true for available username', () async {
      // Arrange
      final verificationService = UsernameVerificationService();
      
      // Act
      final result = await verificationService.checkUsernameAvailability('available_username');
      
      // Assert
      expect(result, isTrue);
    });

    test('checkUsernameAvailability should return false for taken username', () async {
      // Arrange
      final verificationService = UsernameVerificationService();
      
      // Act
      final result = await verificationService.checkUsernameAvailability('admin');
      
      // Assert
      expect(result, isFalse);
    });
  });

  group('OnboardingState', () {
    test('Username page validation should pass with valid username', () {
      // Arrange
      const state = OnboardingState(
        username: 'valid_username',
        currentPageIndex: 1, // Username page is index 1
      );
      
      // Act
      final isValid = state.isCurrentPageValid();
      
      // Assert
      expect(isValid, isTrue);
    });

    test('Username page validation should fail with empty username', () {
      // Arrange
      const state = OnboardingState(
        username: '',
        currentPageIndex: 1, // Username page is index 1
      );
      
      // Act
      final isValid = state.isCurrentPageValid();
      
      // Assert
      expect(isValid, isFalse);
    });
  });
} 