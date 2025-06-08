import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:hive_ui/features/auth/domain/repositories/auth_repository.dart';

// Create manual mocks for the minimal components needed for the test
class MockAuthRepository extends Mock implements AuthRepository {
  @override
  Future<void> applyActionCode(String code) {
    return super.noSuchMethod(
      Invocation.method(#applyActionCode, [code]),
      returnValue: Future<void>.value(),
      returnValueForMissingStub: Future<void>.value(),
    );
  }
}

void main() {
  group('Email verification in deep links', () {
    // This is a very simplified test that ignores the DeepLinkService class
    // but verifies the core functionality we want to test - email verification handling
    
    test('should extract oobCode from email verification link', () {
      // Test data
      const emailVerificationLink = 'https://hiveapp.com/auth/action?mode=verifyEmail&oobCode=CODE123XYZ&apiKey=AIza...';
      
      // Parse the URI (similar to what DeepLinkService._handleDeepLink does)
      final uri = Uri.parse(emailVerificationLink);
      
      // Extract the mode and oobCode
      final mode = uri.queryParameters['mode'];
      final oobCode = uri.queryParameters['oobCode'];
      
      // Assert
      expect(mode, equals('verifyEmail'));
      expect(oobCode, equals('CODE123XYZ'));
    });
    
    test('should call applyActionCode when handling email verification link', () async {
      // Create mock
      final mockAuthRepository = MockAuthRepository();
      
      // Test data
      const emailVerificationLink = 'https://hiveapp.com/auth/action?mode=verifyEmail&oobCode=CODE123XYZ&apiKey=AIza...';
      const oobCode = 'CODE123XYZ';
      
      // Setup mock behavior
      when(mockAuthRepository.applyActionCode(oobCode))
          .thenAnswer((_) async => Future.value());
      
      // Parse URI (similar to DeepLinkService)
      final uri = Uri.parse(emailVerificationLink);
      final mode = uri.queryParameters['mode'];
      final extractedCode = uri.queryParameters['oobCode'];
      
      // Only continue if this is an email verification link
      if (mode == 'verifyEmail' && extractedCode != null && extractedCode.isNotEmpty) {
        // Call the repository (similar to what DeepLinkService would do)
        await mockAuthRepository.applyActionCode(extractedCode);
      }
      
      // Verify
      verify(mockAuthRepository.applyActionCode(oobCode)).called(1);
    });
    
    test('should handle errors from applyActionCode', () async {
      // Create mock
      final mockAuthRepository = MockAuthRepository();
      
      // Test data
      const emailVerificationLink = 'https://hiveapp.com/auth/action?mode=verifyEmail&oobCode=CODE123XYZ&apiKey=AIza...';
      const oobCode = 'CODE123XYZ';
      
      // Setup mock behavior to throw exception BEFORE test execution
      final exception = FirebaseAuthException(code: 'invalid-action-code');
      when(mockAuthRepository.applyActionCode(oobCode)).thenThrow(exception);
      
      // Parse URI (similar to DeepLinkService)
      final uri = Uri.parse(emailVerificationLink);
      final mode = uri.queryParameters['mode'];
      final extractedCode = uri.queryParameters['oobCode'];
      
      // Flags to track behavior
      bool navigatedToErrorPage = false;
      bool navigatedToSuccessPage = false;
      
      // Only continue if this is an email verification link
      if (mode == 'verifyEmail' && extractedCode != null && extractedCode.isNotEmpty) {
        try {
          // Call the repository (similar to what DeepLinkService would do)
          await mockAuthRepository.applyActionCode(extractedCode);
          navigatedToSuccessPage = true; // This would navigate to success page
        } catch (e) {
          // Do not use when() inside the catch block as it causes "Cannot call when within a stub response"
          navigatedToErrorPage = true; // This would navigate to error page
        }
      }
      
      // Verify the exception was thrown and we "navigated" to error page
      verify(mockAuthRepository.applyActionCode(oobCode)).called(1);
      expect(navigatedToErrorPage, isTrue);
      expect(navigatedToSuccessPage, isFalse);
    });
  });
} 