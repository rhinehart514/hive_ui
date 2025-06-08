import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// A utility class for consistent error logging across the app
/// Handles both debug logging and reporting to Firebase Crashlytics in production
class ErrorLogger {
  /// Log an error with optional context information
  /// 
  /// [message] A descriptive message about the error
  /// [error] The error or exception object
  /// [stackTrace] The stack trace associated with the error
  /// [context] Additional contextual information about the error
  static void logError(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    // Always log to console
    debugPrint('ERROR: $message');
    if (error != null) {
      debugPrint('  Details: $error');
    }
    if (stackTrace != null) {
      debugPrint('  Stack trace: $stackTrace');
    }
    if (context != null) {
      debugPrint('  Context: $context');
    }

    try {
      // In production, also log to Firebase Crashlytics
      if (!kDebugMode) {
        // Record non-fatal exception to Crashlytics
        FirebaseCrashlytics.instance.recordError(
          error ?? message,
          stackTrace,
          reason: message,
          information: context?.entries.map((e) => '${e.key}: ${e.value}').toList() ?? [],
          printDetails: false, // Already printed above
        );
      }
    } catch (e) {
      // Don't let crash reporting itself crash the app
      debugPrint('Error reporting to Crashlytics: $e');
    }
  }

  /// Record a non-fatal exception to Crashlytics
  /// Use this for important exceptions that shouldn't crash the app
  /// but are still worth tracking
  static void recordNonFatalException(
    dynamic exception,
    StackTrace stackTrace, {
    String? reason,
    Iterable<String>? information,
  }) {
    try {
      if (!kDebugMode) {
        FirebaseCrashlytics.instance.recordError(
          exception,
          stackTrace,
          reason: reason,
          information: information?.toList() ?? <String>[],
          printDetails: true,
        );
      } else {
        debugPrint('NON-FATAL EXCEPTION: ${reason ?? 'Unspecified reason'}');
        debugPrint('  Details: $exception');
        debugPrint('  Stack trace: $stackTrace');
        if (information != null) {
          debugPrint('  Additional info: $information');
        }
      }
    } catch (e) {
      debugPrint('Error recording non-fatal exception: $e');
    }
  }

  /// Set user identifier in Crashlytics for better error tracking
  static void setUserIdentifier(String userId) {
    try {
      if (!kDebugMode) {
        FirebaseCrashlytics.instance.setUserIdentifier(userId);
      }
    } catch (e) {
      debugPrint('Error setting user identifier: $e');
    }
  }

  /// Add a custom key/value pair to Crashlytics logs
  static void setCustomKey(String key, dynamic value) {
    try {
      if (!kDebugMode) {
        FirebaseCrashlytics.instance.setCustomKey(key, value.toString());
      }
    } catch (e) {
      debugPrint('Error setting custom key: $e');
    }
  }
} 