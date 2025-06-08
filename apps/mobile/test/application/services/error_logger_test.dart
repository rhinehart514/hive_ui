import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ui/application/services/error_logger.dart';
import 'package:hive_ui/core/result/result.dart';
import 'package:hive_ui/domain/failures/auth_failure.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'error_logger_test.mocks.dart';

@GenerateMocks([FirebaseCrashlytics])
void main() {
  late MockFirebaseCrashlytics mockCrashlytics;
  late FirebaseCrashlyticsLogger errorLogger;

  setUp(() {
    mockCrashlytics = MockFirebaseCrashlytics();
    errorLogger = FirebaseCrashlyticsLogger(mockCrashlytics);

    // Default stubbing for methods that don't return values
    when(mockCrashlytics.log(any)).thenAnswer((_) async {}); // Use thenAnswer like others
    when(mockCrashlytics.setCustomKey(any, any)).thenAnswer((_) async {});
    when(mockCrashlytics.setUserIdentifier(any)).thenAnswer((_) async {});
    when(mockCrashlytics.recordError(any, any, reason: anyNamed('reason'), fatal: anyNamed('fatal'), information: anyNamed('information')))
        .thenAnswer((_) async {});

  });

  group('FirebaseCrashlyticsLogger Tests', () {
    const testMessage = 'Test log message';
    final testContext = {'key1': 'value1', 'key2': 123};
    final testError = Exception('Test Exception');
    final testStackTrace = StackTrace.current;
    const testFailure = ServerFailure('Test Server Failure');

    group('log', () {
      test('should log message to Crashlytics for non-info levels', () {
        errorLogger.log(testMessage, level: LogLevel.warning);
        verify(mockCrashlytics.log('[LogLevel.warning] $testMessage')).called(1);
        verifyNever(mockCrashlytics.recordError(any, any)); // Warning shouldn't record error
      });

       test('should NOT log message to Crashlytics for info level', () {
         errorLogger.log(testMessage, level: LogLevel.info);
         verifyNever(mockCrashlytics.log(any));
         verifyNever(mockCrashlytics.recordError(any, any));
       });

       test('should record non-fatal error for error level', () {
          errorLogger.log(testMessage, level: LogLevel.error, stackTrace: testStackTrace);
          verify(mockCrashlytics.log('[LogLevel.error] $testMessage')).called(1);
          verify(mockCrashlytics.recordError(
             testMessage, 
             testStackTrace, 
             reason: 'App log: LogLevel.error',
             fatal: false,
             information: anyNamed('information') // Ensure optional params are handled
          )).called(1);
       });

       test('should record fatal error for critical level', () {
          errorLogger.log(testMessage, level: LogLevel.critical, stackTrace: testStackTrace);
          verify(mockCrashlytics.log('[LogLevel.critical] $testMessage')).called(1);
           verify(mockCrashlytics.recordError(
             testMessage, 
             testStackTrace, 
             reason: 'App log: LogLevel.critical',
             fatal: true,
             information: anyNamed('information')
          )).called(1);
       });

       test('should set custom keys from context', () {
          errorLogger.log(testMessage, level: LogLevel.warning, context: testContext);
          verify(mockCrashlytics.setCustomKey('key1', 'value1')).called(1);
          verify(mockCrashlytics.setCustomKey('key2', '123')).called(1); // Ensure value is stringified
       });
    });

    group('reportError', () {
      test('should call recordError on Crashlytics with error and stacktrace', () {
        errorLogger.reportError(testError, testStackTrace, reason: 'Test Reason');
        verify(mockCrashlytics.recordError(
          testError,
          testStackTrace,
          reason: 'Test Reason',
          fatal: false,
          information: anyNamed('information')
        )).called(1);
      });
      
       test('should set custom keys from context before reporting error', () {
          errorLogger.reportError(testError, testStackTrace, context: testContext);
          // Verify keys set *before* recordError - use invocation order verification
          verifyInOrder([
            mockCrashlytics.setCustomKey('key1', 'value1'),
            mockCrashlytics.setCustomKey('key2', '123'),
            mockCrashlytics.recordError(testError, testStackTrace, reason: anyNamed('reason'), fatal: anyNamed('fatal'), information: anyNamed('information')),
          ]);
       });
    });

    group('reportFailure', () {
      test('should call recordError on Crashlytics with failure and stacktrace', () {
        errorLogger.reportFailure(testFailure, stackTrace: testStackTrace);
         verify(mockCrashlytics.recordError(
           testFailure, // Passes the Failure object itself
           testStackTrace, 
           reason: 'Domain failure: ServerFailure',
           fatal: false,
           information: anyNamed('information')
         )).called(1);
      });

      test('should set failure_type and context keys before reporting failure', () {
        errorLogger.reportFailure(testFailure, context: testContext);
        verifyInOrder([
          mockCrashlytics.setCustomKey('failure_type', 'ServerFailure'),
          mockCrashlytics.setCustomKey('key1', 'value1'),
          mockCrashlytics.setCustomKey('key2', '123'),
          mockCrashlytics.recordError(testFailure, any, reason: anyNamed('reason'), fatal: anyNamed('fatal'), information: anyNamed('information')),
        ]);
      });
    });
    
    group('reportResultFailure', () {
      test('should call reportFailure when result is Failure', () {
        const failureResult = Result<String, Failure>.left(testFailure);
        // Use spy or manual check as reportFailure is on the same object
        // We'll verify the underlying crashlytics calls were made as expected by reportFailure
        errorLogger.reportResultFailure(failureResult);
        
        verify(mockCrashlytics.setCustomKey('failure_type', 'ServerFailure')).called(1);
        verify(mockCrashlytics.recordError(testFailure, any, reason: 'Domain failure: ServerFailure', fatal: false, information: anyNamed('information'))).called(1);
      });

      test('should NOT call reportFailure when result is Success', () {
        const successResult = Result<String, Failure>.right('Success Data');
        errorLogger.reportResultFailure(successResult);
        
        verifyNever(mockCrashlytics.setCustomKey('failure_type', any));
        verifyNever(mockCrashlytics.recordError(any, any));
      });
    });

    group('setUserId', () {
      test('should call setUserIdentifier on Crashlytics', () {
        const userId = 'user-123';
        errorLogger.setUserId(userId);
        verify(mockCrashlytics.setUserIdentifier(userId)).called(1);
      });
    });

     group('setCustomKey', () {
       test('should call setCustomKey on Crashlytics with stringified value', () {
         errorLogger.setCustomKey('testBool', true);
         verify(mockCrashlytics.setCustomKey('testBool', 'true')).called(1);
         
         errorLogger.setCustomKey('testInt', 42);
         verify(mockCrashlytics.setCustomKey('testInt', '42')).called(1);
       });
     });

  });
} 