import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/error/app_error_handler.dart';
import 'package:hive_ui/core/error/failures/app_failure.dart';
import 'package:hive_ui/core/error/services/crashlytics_service.dart';
import 'package:hive_ui/features/shared/domain/failures/failure.dart';

/// Examples of using the unified error handling approach
class ErrorHandlingExamples {
  /// Example 1: Basic error handling in a function
  static void basicErrorHandling(WidgetRef ref) {
    try {
      // Some code that might throw an exception
      throw Exception('Something went wrong');
    } catch (error, stackTrace) {
      // Handle the error using the unified error handler
      ref.read(appErrorHandlerProvider).handleError(
        error,
        stackTrace: stackTrace,
        fallbackMessage: 'Failed to perform operation',
      );
    }
  }
  
  /// Example 2: Error handling in an async function with UI feedback
  static Future<void> asyncErrorHandling(BuildContext context, WidgetRef ref) async {
    try {
      // Some async code that might throw an exception
      await Future.delayed(const Duration(seconds: 1));
      throw Exception('Network error');
    } catch (error, stackTrace) {
      // Handle the error with UI feedback
      ref.read(appErrorHandlerProvider).handleError(
        error,
        context: context,
        stackTrace: stackTrace,
        fallbackMessage: 'Failed to load data',
        showDialog: true, // Show a dialog instead of a snackbar
      );
    }
  }
  
  /// Example 3: Using domain-specific failures
  static void domainSpecificFailure(WidgetRef ref) {
    try {
      // Some code that might fail
      final result = _fetchData();
      
      // Check the result using the Either type
      result.fold(
        (failure) {
          // Handle the failure using the unified error handler
          ref.read(appErrorHandlerProvider).handleFailure(failure);
        },
        (data) {
          // Success case - use the data
          debugPrint('Data fetched successfully: $data');
        },
      );
    } catch (error, stackTrace) {
      // Fallback error handling for unexpected errors
      ref.read(appErrorHandlerProvider).handleAsyncError(
        error,
        stackTrace,
        fallbackMessage: 'An unexpected error occurred while fetching data',
      );
    }
  }
  
  /// Example 4: Creating a custom domain-specific failure
  static void createCustomFailure(WidgetRef ref) {
    // Create a custom domain failure
    final failure = CustomDomainFailure(
      userMessage: 'Could not complete the requested operation.',
      technicalMessage: 'API returned status code 429 (Too Many Requests)',
      retryAfter: 60,
    );
    
    // Handle the failure
    ref.read(appErrorHandlerProvider).handleFailure(failure);
  }
  
  /// Example 5: Direct usage in a StateNotifier
  static final exampleNotifierProvider = StateNotifierProvider<ExampleNotifier, AsyncValue<String>>((ref) {
    return ExampleNotifier(ref);
  });
  
  /// Example 6: Using Crashlytics for specialized error tracking
  static void trackSpecializedError(WidgetRef ref) {
    try {
      // Some code that might throw an exception
      throw Exception('Critical system error');
    } catch (error, stackTrace) {
      // Log the error to Crashlytics directly
      ref.read(crashlyticsServiceProvider).recordError(
        error,
        stackTrace,
        reason: 'Critical system component failure',
        information: ['Component: Authentication', 'Operation: Token Refresh'],
        fatal: true,
      );
      
      // Also handle through the standard error handler
      ref.read(appErrorHandlerProvider).handleError(
        error,
        stackTrace: stackTrace,
        fallbackMessage: 'A system error occurred. Please try again later.',
      );
    }
  }
  
  /// Mock function that returns Either type for example
  static Either<AppFailure, String> _fetchData() {
    // Simulate a failure for the example
    if (DateTime.now().second % 2 == 0) {
      return Either.left(
        NetworkFailure(
          userMessage: 'Could not connect to the server. Please check your internet connection.',
          technicalMessage: 'Network request failed with status code 500',
        ),
      );
    }
    
    // Simulate success
    return Either.right('Sample data');
  }
}

/// Example custom domain-specific failure
class CustomDomainFailure extends AppFailure {
  /// Time in seconds to retry after
  final int retryAfter;
  
  /// Constructor
  CustomDomainFailure({
    required String userMessage,
    required String technicalMessage,
    required this.retryAfter,
    dynamic exception,
  }) : super(
         code: 'rate_limit_exceeded',
         userMessage: userMessage,
         technicalMessage: technicalMessage,
         exception: exception,
         isCritical: false,
       );
}

/// Example StateNotifier that incorporates error handling
class ExampleNotifier extends StateNotifier<AsyncValue<String>> {
  final Ref _ref;
  
  ExampleNotifier(this._ref) : super(const AsyncValue.loading());
  
  /// Load data with proper error handling
  Future<void> loadData() async {
    // Set loading state
    state = const AsyncValue.loading();
    
    try {
      // Simulate async operation
      await Future.delayed(const Duration(seconds: 1));
      
      // Simulate API call using Either for error handling
      final result = _fetchData();
      
      // Process the result
      state = result.fold(
        (failure) {
          // Handle the failure
          _ref.read(appErrorHandlerProvider).handleFailure(failure);
          
          // Return the error state
          return AsyncValue.error(failure, StackTrace.current);
        },
        (data) {
          // Return the success state
          return AsyncValue.data(data);
        },
      );
    } catch (error, stackTrace) {
      // Handle unexpected errors
      _ref.read(appErrorHandlerProvider).handleAsyncError(
        error,
        stackTrace,
        fallbackMessage: 'Failed to load data',
      );
      
      // Update state with the error
      state = AsyncValue.error(error, stackTrace);
    }
  }
  
  /// Mock function that returns Either type
  Either<AppFailure, String> _fetchData() {
    // Simulate a failure for the example
    if (DateTime.now().second % 3 == 0) {
      return Either.left(
        NetworkFailure(
          userMessage: 'Unable to load data. Please try again.',
          technicalMessage: 'API request timed out after 30 seconds',
        ),
      );
    }
    
    // Simulate success
    return Either.right('Example data loaded successfully');
  }
} 