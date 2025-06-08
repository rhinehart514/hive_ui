
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/core/result/result.dart';
import 'package:hive_ui/domain/failures/auth_failure.dart';

/// Defines the severity level of a log message.
enum LogLevel {
  /// Informational messages that don't indicate problems.
  info,
  
  /// Warnings about potential problems that don't cause errors.
  warning,
  
  /// Errors that might be recoverable.
  error,
  
  /// Severe errors that might cause application crashes.
  critical,
}

/// Service for logging errors and diagnostic information.
abstract class ErrorLogger {
  /// Logs a message with context information.
  void log(
    String message, {
    LogLevel level = LogLevel.info,
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
  });

  /// Logs and reports an error to the error tracking service.
  void reportError(
    dynamic error,
    StackTrace stackTrace, {
    String? reason,
    Map<String, dynamic>? context,
  });

  /// Logs an application failure with context.
  void reportFailure(
    Failure failure, {
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
  });
  
  /// Logs a Result object's failure if present.
  void reportResultFailure<S, F extends Failure>(
    Result<S, F> result, {
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
  });

  /// Sets a user identifier for error tracking.
  void setUserId(String userId);
  
  /// Sets custom keys for error tracking.
  void setCustomKey(String key, dynamic value);
}

/// Implementation of [ErrorLogger] using Firebase Crashlytics.
class FirebaseCrashlyticsLogger implements ErrorLogger {
  final FirebaseCrashlytics _crashlytics;
  
  /// Creates a new instance with the given Crashlytics instance.
  FirebaseCrashlyticsLogger(this._crashlytics);

  @override
  void log(
    String message, {
    LogLevel level = LogLevel.info,
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
  }) {
    // Log to console in debug mode
    if (kDebugMode) {
      print('[$level] $message ${context != null ? '- Context: $context' : ''}');
      if (stackTrace != null) {
        print(stackTrace);
      }
    }
    
    // Skip reporting info level logs to Crashlytics
    if (level == LogLevel.info) {
      return;
    }
    
    // Log to Crashlytics
    _crashlytics.log('[$level] $message');
    
    // Add context as custom keys
    if (context != null) {
      for (final entry in context.entries) {
        _crashlytics.setCustomKey(entry.key, entry.value.toString());
      }
    }
    
    // For error and critical, record a non-fatal exception
    if (level == LogLevel.error || level == LogLevel.critical) {
      _crashlytics.recordError(
        message,
        stackTrace ?? StackTrace.current,
        reason: 'App log: $level',
        fatal: level == LogLevel.critical,
      );
    }
  }

  @override
  void reportError(
    dynamic error,
    StackTrace stackTrace, {
    String? reason,
    Map<String, dynamic>? context,
  }) {
    // Log to console in debug mode
    if (kDebugMode) {
      print('ERROR: ${reason ?? 'Uncaught error'} - $error');
      print('Context: $context');
      print(stackTrace);
    }
    
    // Add context as custom keys
    if (context != null) {
      for (final entry in context.entries) {
        _crashlytics.setCustomKey(entry.key, entry.value.toString());
      }
    }
    
    // Report to Crashlytics
    _crashlytics.recordError(
      error,
      stackTrace,
      reason: reason,
      fatal: false,
    );
  }

  @override
  void reportFailure(
    Failure failure, {
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
  }) {
    final failureType = failure.runtimeType.toString();
    
    // Log to console in debug mode
    if (kDebugMode) {
      print('FAILURE: $failureType - ${failure.message}');
      print('Context: $context');
      if (stackTrace != null) {
        print(stackTrace);
      }
    }
    
    // Add failure type as custom key
    _crashlytics.setCustomKey('failure_type', failureType);
    
    // Add context as custom keys
    if (context != null) {
      for (final entry in context.entries) {
        _crashlytics.setCustomKey(entry.key, entry.value.toString());
      }
    }
    
    // Report to Crashlytics
    _crashlytics.recordError(
      failure,
      stackTrace ?? StackTrace.current,
      reason: 'Domain failure: $failureType',
      fatal: false,
    );
  }
  
  @override
  void reportResultFailure<S, F extends Failure>(
    Result<S, F> result, {
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
  }) {
    if (result.isFailure) {
      reportFailure(
        result.getFailure,
        context: context,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  void setUserId(String userId) {
    _crashlytics.setUserIdentifier(userId);
  }
  
  @override
  void setCustomKey(String key, dynamic value) {
    _crashlytics.setCustomKey(key, value.toString());
  }
} 