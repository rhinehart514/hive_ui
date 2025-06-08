import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'analytics_service.dart';
import 'dart:async';

/// Types of application errors
enum ErrorType {
  /// Network-related errors
  network,

  /// Authentication-related errors
  authentication,

  /// Data parsing or validation errors
  dataFormat,

  /// User input errors
  userInput,

  /// Permission-related errors
  permission,

  /// General app errors
  general,
}

/// Data class for error information
class AppError {
  /// Type of error
  final ErrorType type;

  /// Error message
  final String message;

  /// Original exception
  final dynamic exception;

  /// Stack trace
  final StackTrace? stackTrace;

  /// Time when the error occurred
  final DateTime timestamp;

  /// Constructor
  AppError({
    required this.type,
    required this.message,
    this.exception,
    this.stackTrace,
  }) : timestamp = DateTime.now();

  @override
  String toString() =>
      'AppError(type: $type, message: $message, timestamp: $timestamp)';
}

/// Provider for the error handling service
final errorHandlingServiceProvider = Provider<ErrorHandlingService>((ref) {
  return ErrorHandlingService(ref);
});

/// Service for handling errors consistently across the app
class ErrorHandlingService {
  final Ref _ref;
  final AnalyticsService _analytics = AnalyticsService();

  /// Controller for app errors
  final StreamController<AppError> _errorStreamController =
      StreamController<AppError>.broadcast();

  /// Stream of app errors
  Stream<AppError> get errorStream => _errorStreamController.stream;

  /// Constructor
  ErrorHandlingService(this._ref);

  /// Handle a general error
  void handleError(dynamic error,
      {StackTrace? stackTrace, ErrorType type = ErrorType.general}) {
    final appError = _processError(error, stackTrace: stackTrace, type: type);
    _logError(appError);
    _errorStreamController.add(appError);
  }

  /// Handle a network error
  void handleNetworkError(dynamic error, {StackTrace? stackTrace}) {
    handleError(error, stackTrace: stackTrace, type: ErrorType.network);
  }

  /// Handle an authentication error
  void handleAuthError(dynamic error, {StackTrace? stackTrace}) {
    handleError(error, stackTrace: stackTrace, type: ErrorType.authentication);
  }

  /// Handle a data format error
  void handleDataFormatError(dynamic error, {StackTrace? stackTrace}) {
    handleError(error, stackTrace: stackTrace, type: ErrorType.dataFormat);
  }

  /// Report a user-facing error with a custom message
  void reportUserError(String message, {ErrorType type = ErrorType.general}) {
    final appError = AppError(
      type: type,
      message: message,
    );

    _logError(appError);
    _errorStreamController.add(appError);
  }

  /// Show a snackbar with an error message
  void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Process an error to create an AppError object
  AppError _processError(dynamic error,
      {StackTrace? stackTrace, ErrorType type = ErrorType.general}) {
    String message;

    if (error is Exception || error is Error) {
      message = error.toString();
    } else if (error is String) {
      message = error;
    } else {
      message = 'An unexpected error occurred';
    }

    return AppError(
      type: type,
      message: message,
      exception: error,
      stackTrace: stackTrace,
    );
  }

  /// Log an error to analytics and console
  void _logError(AppError error) {
    // Log to analytics
    _analytics.trackError(
      error.exception,
      error.stackTrace,
      method: error.type.toString(),
    );

    // Log to console in debug mode
    if (kDebugMode) {
      print('ERROR [${error.type}]: ${error.message}');
      if (error.stackTrace != null) {
        print(error.stackTrace);
      }
    }
  }

  /// Dispose resources
  void dispose() {
    _errorStreamController.close();
  }

  /// Create a wrapper for FutureProvider that includes error handling
  static AutoDisposeFutureProvider<T> createHandledFutureProvider<T>(
    String providerName,
    Future<T> Function(Ref) fetchData,
  ) {
    return AutoDisposeFutureProvider<T>((ref) async {
      try {
        return await fetchData(ref);
      } catch (error, stackTrace) {
        ref.read(errorHandlingServiceProvider).handleError(
              error,
              stackTrace: stackTrace,
            );
        rethrow;
      }
    });
  }
}

// Global app error observer - Moved from main.dart
class AppErrorObserver {
  static bool _isSetup = false;

  static void setup() {
    if (_isSetup) return;
    
    if (!kDebugMode) {
      debugPrint('Setting up global error handlers (Release Mode)');
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        // Call original handler if it exists (e.g., FlutterError.presentError)
        originalOnError?.call(details);
        
        // Log details to console
        debugPrint('Global FlutterError: ${details.exception}');
        // Optionally: Record to Crashlytics or other service if initialized
        // Example: if (CrashlyticsService.isInitialized) { ... }
      };

      final originalPlatformOnError = PlatformDispatcher.instance.onError;
      PlatformDispatcher.instance.onError = (error, stack) {
         debugPrint('Global Platform Error: $error');
         // Optionally: Record to Crashlytics or other service if initialized
         
         // Return true if handled, or call original handler if it exists
         return originalPlatformOnError?.call(error, stack) ?? true;
      };
    } else {
       debugPrint('Skipping global error handler setup (Debug Mode)');
    }
    
    _isSetup = true;
  }
}
