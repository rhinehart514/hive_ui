import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ui/domain/failures/auth_failure.dart';

void main() {
  group('Auth Failures', () {
    test('Failure base class should store message', () {
      const message = 'Test failure message';
      const failure = ServerFailure(message);
      
      expect(failure.message, equals(message));
      expect(failure.toString(), equals(message));
    });
    
    test('AuthFailure should inherit from Failure', () {
      const authFailure = AuthFailure('Auth failure');
      
      expect(authFailure, isA<Failure>());
      expect(authFailure.message, equals('Auth failure'));
    });
    
    test('InvalidEmailFailure should inherit from AuthFailure', () {
      const message = 'Invalid email provided';
      const failure = InvalidEmailFailure(message);
      
      expect(failure, isA<AuthFailure>());
      expect(failure, isA<Failure>());
      expect(failure.message, equals(message));
    });
    
    test('ExpiredLinkFailure should inherit from AuthFailure', () {
      const message = 'Your link has expired';
      const failure = ExpiredLinkFailure(message);
      
      expect(failure, isA<AuthFailure>());
      expect(failure, isA<Failure>());
      expect(failure.message, equals(message));
    });
    
    test('ServerFailure should inherit from Failure', () {
      const message = 'Server error occurred';
      const failure = ServerFailure(message);
      
      expect(failure, isA<Failure>());
      expect(failure.message, equals(message));
    });
    
    test('NetworkFailure should inherit from Failure', () {
      const message = 'Network connection lost';
      const failure = NetworkFailure(message);
      
      expect(failure, isA<Failure>());
      expect(failure.message, equals(message));
    });
    
    test('UnknownFailure should inherit from Failure', () {
      const message = 'Something went wrong';
      const failure = UnknownFailure(message);
      
      expect(failure, isA<Failure>());
      expect(failure.message, equals(message));
    });
  });
} 