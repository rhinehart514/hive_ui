import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/error/app_error_handler.dart';
import 'package:hive_ui/core/error/failures/app_failure.dart';
import 'package:hive_ui/core/error/services/crashlytics_service.dart';

/// Provider for Crashlytics initialization
final crashlyticsInitializerProvider = Provider<CrashlyticsInitializer>((ref) {
  return CrashlyticsInitializer(ref);
});

/// Class to handle initialization of Crashlytics and error reporting
class CrashlyticsInitializer {
  final Ref _ref;
  
  /// Whether initialization has been completed
  bool _initialized = false;
  
  /// Constructor
  CrashlyticsInitializer(this._ref);
  
  /// Initialize Crashlytics and set up global error handlers
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Initialize Crashlytics
      await _ref.read(crashlyticsServiceProvider).initialize();
      
      // Set up Flutter error handling
      FlutterError.onError = _handleFlutterError;
      
      // Set up error handling for async errors
      PlatformDispatcher.instance.onError = _handlePlatformDispatcherError;
      
      _initialized = true;
      debugPrint('Crashlytics initialization completed');
    } catch (e) {
      debugPrint('Failed to initialize Crashlytics: $e');
    }
  }
  
  /// Set user identifier for better error tracking
  Future<void> setUserIdentifier(String userId) async {
    try {
      await _ref.read(crashlyticsServiceProvider).setUserIdentifier(userId);
    } catch (e) {
      debugPrint('Failed to set user identifier for Crashlytics: $e');
    }
  }
  
  /// Handle Flutter framework errors
  void _handleFlutterError(FlutterErrorDetails details) {
    try {
      if (kReleaseMode) {
        // In release mode, report to Crashlytics
        _ref.read(crashlyticsServiceProvider).recordFlutterFatalError(details);
      } else {
        // In debug mode, print to console
        FlutterError.dumpErrorToConsole(details);
      }
      
      // Convert to AppFailure and report through the error handler
      final failure = UnexpectedFailure(
        technicalMessage: details.exception.toString(),
        exception: details.exception,
      );
      
      _ref.read(appErrorHandlerProvider).handleFailure(
        failure,
        stackTrace: details.stack,
        reportToCrashlytics: false, // Already reported above
      );
    } catch (e) {
      // If our error handling fails, fall back to Flutter's default
      FlutterError.dumpErrorToConsole(details);
      debugPrint('Error in Crashlytics error handler: $e');
    }
  }
  
  /// Handle platform dispatcher errors (Zone errors)
  bool _handlePlatformDispatcherError(Object error, StackTrace stack) {
    try {
      // Report via error handler
      _ref.read(appErrorHandlerProvider).handleAsyncError(
        error,
        stack,
        fallbackMessage: 'An unexpected error occurred',
        reportToCrashlytics: true,
      );
      
      // Return true to indicate that the error was handled
      return true;
    } catch (e) {
      debugPrint('Error in Platform error handler: $e');
      return false;
    }
  }
} 