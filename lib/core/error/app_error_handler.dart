import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/error/failures/app_failure.dart';
import 'package:hive_ui/core/error/ui/error_dialog.dart';
import 'package:hive_ui/core/error/ui/error_snackbar.dart';
import 'package:hive_ui/services/error_handling_service.dart';

/// Provides the app error handler
final appErrorHandlerProvider = Provider<AppErrorHandler>((ref) {
  return AppErrorHandler(ref);
});

/// Unified error handler for the application
/// 
/// This class provides a consistent approach to error handling throughout the app,
/// supporting both domain-specific failures and general exceptions.
/// It integrates with Firebase Crashlytics for production error reporting.
class AppErrorHandler {
  /// Provider reference
  final ProviderRef _ref;
  
  /// Legacy error handling service (will gradually migrate to this new handler)
  late final ErrorHandlingService _legacyService;
  
  /// Error controller for broadcasting errors throughout the app
  final StreamController<AppFailure> _errorStreamController = 
      StreamController<AppFailure>.broadcast();
  
  /// Creates a new app error handler
  AppErrorHandler(this._ref) {
    _legacyService = _ref.read(errorHandlingServiceProvider);
  }
  
  /// Stream of app errors that can be listened to by UI components
  Stream<AppFailure> get errorStream => _errorStreamController.stream;
  
  /// Handle any type of error or failure
  /// 
  /// This is the main entry point for error handling in the app.
  /// - If [error] is an [AppFailure], it will be handled directly
  /// - For other exceptions, it will be wrapped in an [UnexpectedFailure]
  /// 
  /// [context] is optional but enables UI feedback if provided
  /// [showDialog] determines whether to show a dialog or snackbar (when context is provided)
  /// [reportToCrashlytics] can be set to false for expected errors that shouldn't be reported
  void handleError(
    dynamic error, {
    BuildContext? context,
    StackTrace? stackTrace,
    String? fallbackMessage,
    bool showDialog = false,
    bool reportToCrashlytics = true,
  }) {
    // Create appropriate failure object
    final failure = _createFailure(error, stackTrace, fallbackMessage);
    
    // Log error
    _logError(failure, stackTrace);
    
    // Report to Crashlytics if appropriate
    if (reportToCrashlytics) {
      _reportToCrashlytics(failure, stackTrace);
    }
    
    // Add to stream for global error listeners
    _errorStreamController.add(failure);
    
    // Legacy service bridge (for compatibility during migration)
    _bridgeToLegacyService(failure);
    
    // Show UI feedback if context is provided
    if (context != null) {
      if (showDialog) {
        showErrorDialog(context, failure.userMessage);
      } else {
        showErrorSnackBar(context, failure.userMessage);
      }
    }
  }
  
  /// Handle a domain-specific failure
  /// 
  /// This is a convenience method when you already have an AppFailure object
  void handleFailure(
    AppFailure failure, {
    BuildContext? context,
    StackTrace? stackTrace,
    bool showDialog = false,
    bool reportToCrashlytics = true,
  }) {
    handleError(
      failure,
      context: context,
      stackTrace: stackTrace,
      showDialog: showDialog,
      reportToCrashlytics: reportToCrashlytics,
    );
  }
  
  /// Handle errors that occur during async operations
  /// 
  /// Designed to be used in a catch block
  void handleAsyncError(
    dynamic error,
    StackTrace stackTrace, {
    BuildContext? context,
    String? fallbackMessage,
    bool showDialog = false,
    bool reportToCrashlytics = true,
  }) {
    handleError(
      error,
      context: context,
      stackTrace: stackTrace,
      fallbackMessage: fallbackMessage,
      showDialog: showDialog,
      reportToCrashlytics: reportToCrashlytics,
    );
  }
  
  /// Create a domain failure from any error type
  AppFailure _createFailure(dynamic error, StackTrace? stackTrace, String? fallbackMessage) {
    // If it's already a domain failure, return it directly
    if (error is AppFailure) {
      return error;
    }
    
    // Create an unexpected failure for other error types
    String message;
    if (error is Exception || error is Error) {
      message = error.toString();
    } else if (error is String) {
      message = error;
    } else {
      message = fallbackMessage ?? 'An unexpected error occurred';
    }
    
    return UnexpectedFailure(
      technicalMessage: message,
      exception: error,
    );
  }
  
  /// Log error to console
  void _logError(AppFailure failure, StackTrace? stackTrace) {
    if (kDebugMode) {
      print('ERROR [${failure.code}]: ${failure.technicalMessage}');
      if (stackTrace != null) {
        print(stackTrace);
      }
    }
  }
  
  /// Report error to Crashlytics
  void _reportToCrashlytics(AppFailure failure, StackTrace? stackTrace) {
    // Skip reporting in debug mode
    if (kDebugMode) return;
    
    // Don't report failures that are marked as not reportable
    if (!failure.isCritical) return;
    
    try {
      // Report error with all available context
      FirebaseCrashlytics.instance.recordError(
        failure,
        stackTrace,
        reason: failure.code,
        information: [
          failure.technicalMessage,
          if (failure.exception != null) 'Original exception: ${failure.exception}',
        ],
        fatal: failure.isCritical,
      );
      
      // Set custom keys for better filtering in Crashlytics
      FirebaseCrashlytics.instance.setCustomKey('error_code', failure.code);
      FirebaseCrashlytics.instance.setCustomKey('error_type', failure.runtimeType.toString());
    } catch (e) {
      // If Crashlytics itself fails, just log it (especially for Windows)
      if (kDebugMode) {
        print('Failed to report to Crashlytics: $e');
      }
    }
  }
  
  /// Bridge to legacy error handling service
  /// This helps maintain compatibility during migration
  void _bridgeToLegacyService(AppFailure failure) {
    try {
      ErrorType legacyType = ErrorType.general;
      
      // Map domain failure types to legacy error types
      if (failure is NetworkFailure) {
        legacyType = ErrorType.network;
      } else if (failure is AuthenticationFailure) {
        legacyType = ErrorType.authentication;
      } else if (failure is ValidationFailure) {
        legacyType = ErrorType.dataFormat;
      } else if (failure is PermissionFailure) {
        legacyType = ErrorType.permission;
      } else if (failure is UserInputFailure) {
        legacyType = ErrorType.userInput;
      }
      
      // Report to legacy service
      _legacyService.reportUserError(
        failure.userMessage,
        type: legacyType,
      );
    } catch (e) {
      // Ignore errors from legacy bridge
      if (kDebugMode) {
        print('Error in legacy error handling bridge: $e');
      }
    }
  }
  
  /// Release resources
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
        // Handle the error but still rethrow to propagate to AsyncValue.error
        ref.read(appErrorHandlerProvider).handleAsyncError(
          error,
          stackTrace,
          fallbackMessage: 'Failed to load $providerName data',
        );
        rethrow;
      }
    });
  }
}

/// Basic failure types for application-wide use
/// These can be used directly or as a base for feature-specific failures

/// Failure for unexpected errors
class UnexpectedFailure extends AppFailure {
  /// Constructor
  UnexpectedFailure({
    required String technicalMessage,
    dynamic exception,
  }) : super(
         code: 'unexpected_error',
         userMessage: 'Something went wrong. Please try again later.',
         technicalMessage: technicalMessage,
         exception: exception,
         isCritical: true,
       );
}

/// Failure for network-related errors
class NetworkFailure extends AppFailure {
  /// Constructor
  NetworkFailure({
    String? userMessage,
    String? technicalMessage,
    dynamic exception,
  }) : super(
         code: 'network_error',
         userMessage: userMessage ?? 'Network connection issue. Please check your connection and try again.',
         technicalMessage: technicalMessage ?? 'Network connection failure',
         exception: exception,
         isCritical: false,
       );
}

/// Failure for authentication-related errors
class AuthenticationFailure extends AppFailure {
  /// Constructor
  AuthenticationFailure({
    String? userMessage,
    String? technicalMessage,
    dynamic exception,
  }) : super(
         code: 'authentication_error',
         userMessage: userMessage ?? 'Please sign in to continue.',
         technicalMessage: technicalMessage ?? 'Authentication required or failed',
         exception: exception,
         isCritical: false,
       );
}

/// Failure for permission-related errors
class PermissionFailure extends AppFailure {
  /// Constructor
  PermissionFailure({
    String? userMessage,
    String? technicalMessage,
    dynamic exception,
  }) : super(
         code: 'permission_error',
         userMessage: userMessage ?? 'You don\'t have permission to perform this action.',
         technicalMessage: technicalMessage ?? 'Permission denied',
         exception: exception,
         isCritical: false,
       );
}

/// Failure for validation errors
class ValidationFailure extends AppFailure {
  /// Constructor
  ValidationFailure({
    String? userMessage,
    String? technicalMessage,
    dynamic exception,
  }) : super(
         code: 'validation_error',
         userMessage: userMessage ?? 'Please check the information you provided.',
         technicalMessage: technicalMessage ?? 'Data validation failed',
         exception: exception,
         isCritical: false,
       );
}

/// Failure for user input errors
class UserInputFailure extends AppFailure {
  /// Constructor
  UserInputFailure({
    required String userMessage,
    String? technicalMessage,
    dynamic exception,
  }) : super(
         code: 'user_input_error',
         userMessage: userMessage,
         technicalMessage: technicalMessage ?? 'User input error: $userMessage',
         exception: exception,
         isCritical: false,
       );
}

/// Failure for offline access errors
class OfflineFailure extends AppFailure {
  /// Constructor
  OfflineFailure({
    String? userMessage,
    String? technicalMessage,
    String? operation,
    dynamic exception,
  }) : super(
         code: 'offline_access_error',
         userMessage: userMessage ?? 'This feature is not available offline. Please connect to the internet and try again.',
         technicalMessage: technicalMessage ?? 'Offline access failed${operation != null ? ' for operation: $operation' : ''}',
         exception: exception,
         isCritical: false,
       );
} 