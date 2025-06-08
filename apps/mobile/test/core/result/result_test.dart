import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ui/core/result/result.dart';
import 'package:hive_ui/domain/failures/auth_failure.dart';

void main() {
  group('Result', () {
    test('should create a success result with the right constructor', () {
      const result = Result<String, Failure>.right('success');
      
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.getSuccess, equals('success'));
    });
    
    test('should create a failure result with the left constructor', () {
      const failure = ServerFailure('error');
      const result = Result<String, Failure>.left(failure);
      
      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.getFailure, equals(failure));
    });
    
    test('should create a success result with the success constructor', () {
      const result = Result<String, Failure>.success('success');
      
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.getSuccess, equals('success'));
    });
    
    test('should create a failure result with the failure constructor', () {
      const failure = ServerFailure('error');
      const result = Result<String, Failure>.failure(failure);
      
      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.getFailure, equals(failure));
    });
    
    test('should throw when accessing success value from a failure result', () {
      const failure = ServerFailure('error');
      const result = Result<String, Failure>.failure(failure);
      
      expect(() => result.getSuccess, throwsStateError);
    });
    
    test('should throw when accessing failure value from a success result', () {
      const result = Result<String, Failure>.success('success');
      
      expect(() => result.getFailure, throwsStateError);
    });
    
    test('should map a success value correctly', () {
      const result = Result<String, Failure>.success('hello');
      
      final mapped = result.map((value) => '$value world');
      
      expect(mapped.isSuccess, isTrue);
      expect(mapped.getSuccess, equals('hello world'));
    });
    
    test('should not map a failure value', () {
      const failure = ServerFailure('error');
      const result = Result<String, Failure>.failure(failure);
      
      final mapped = result.map((value) => '$value world');
      
      expect(mapped.isFailure, isTrue);
      expect(mapped.getFailure, equals(failure));
    });
    
    test('should map a failure value correctly', () {
      const failure = ServerFailure('error');
      const result = Result<String, ServerFailure>.failure(failure);
      
      final mapped = result.mapFailure((error) => UnknownFailure(error.message));
      
      expect(mapped.isFailure, isTrue);
      expect(mapped.getFailure, isA<UnknownFailure>());
      expect(mapped.getFailure.message, equals('error'));
    });
    
    test('should not map a success failure', () {
      const result = Result<String, Failure>.success('hello');
      
      final mapped = result.mapFailure((error) => UnknownFailure(error.message));
      
      expect(mapped.isSuccess, isTrue);
      expect(mapped.getSuccess, equals('hello'));
    });
    
    test('should fold correctly for success', () {
      const result = Result<String, Failure>.success('hello');
      var successCalled = false;
      var failureCalled = false;
      
      result.fold(
        onSuccess: (value) => successCalled = true,
        onFailure: (error) => failureCalled = true,
      );
      
      expect(successCalled, isTrue);
      expect(failureCalled, isFalse);
    });
    
    test('should fold correctly for failure', () {
      const failure = ServerFailure('error');
      const result = Result<String, Failure>.failure(failure);
      var successCalled = false;
      var failureCalled = false;
      
      result.fold(
        onSuccess: (value) => successCalled = true,
        onFailure: (error) => failureCalled = true,
      );
      
      expect(successCalled, isFalse);
      expect(failureCalled, isTrue);
    });
    
    test('should get the value from a success result with getOrElse', () {
      const result = Result<String, Failure>.success('hello');
      
      final value = result.getOrElse((error) => 'default');
      
      expect(value, equals('hello'));
    });
    
    test('should get the default value for a failure result with getOrElse', () {
      const failure = ServerFailure('error');
      const result = Result<String, Failure>.failure(failure);
      
      final value = result.getOrElse((error) => 'default: ${error.message}');
      
      expect(value, equals('default: error'));
    });
    
    test('should flatMap a success result correctly', () {
      const result = Result<String, Failure>.success('hello');
      
      final mapped = result.flatMap(
        (value) => Result<int, Failure>.success(value.length),
      );
      
      expect(mapped.isSuccess, isTrue);
      expect(mapped.getSuccess, equals(5));
    });
    
    test('should not flatMap a failure result', () {
      const failure = ServerFailure('error');
      const result = Result<String, Failure>.failure(failure);
      
      final mapped = result.flatMap(
        (value) => Result<int, Failure>.success(value.length),
      );
      
      expect(mapped.isFailure, isTrue);
      expect(mapped.getFailure, equals(failure));
    });
    
    test('should implement toString correctly for success results', () {
      const result = Result<String, Failure>.success('hello');
      
      expect(result.toString(), equals('Success(hello)'));
    });
    
    test('should implement toString correctly for failure results', () {
      const failure = ServerFailure('error');
      const result = Result<String, Failure>.failure(failure);
      
      expect(result.toString(), contains('Failure'));
      expect(result.toString(), contains('error'));
    });
  });
} 