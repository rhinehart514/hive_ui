import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/navigation/async_navigation_service.dart';

/// Example class demonstrating how to use the AsyncNavigationService
/// to navigate safely across async gaps without BuildContext
class AsyncNavigationExamples {
  /// Example 1: Basic Navigation in a Future
  /// This example shows how to navigate after an async operation completes
  static void navigateAfterAsyncOperation(WidgetRef ref) async {
    // Get the navigation service from Riverpod
    final navigation = ref.read(asyncNavigationServiceProvider);
    
    try {
      // Perform an async operation
      await Future.delayed(const Duration(seconds: 2));
      
      // Safe navigation after async gap - no BuildContext needed
      navigation.goToHome();
    } catch (e) {
      // Handle errors
      debugPrint('Error during async operation: $e');
    }
  }
  
  /// Example 2: Navigation in a Stream Subscription
  /// This demonstrates navigation in response to a stream event
  static void navigateFromStreamEvents(WidgetRef ref, Stream<String> eventStream) {
    // Get the navigation service from Riverpod
    final navigation = ref.read(asyncNavigationServiceProvider);
    
    // Subscribe to a stream
    final subscription = eventStream.listen((event) {
      // Process the event
      debugPrint('Received event: $event');
      
      // Navigate based on the event - safe across async gap
      if (event == 'NEW_MESSAGE') {
        navigation.goToMessaging();
      } else if (event.startsWith('EVENT_')) {
        final eventId = event.substring(6); // Remove EVENT_ prefix
        navigation.goToEventDetails(eventId);
      }
    });
    
    // Don't forget to cancel the subscription when no longer needed
    // subscription.cancel();
  }
  
  /// Example 3: Navigation after Firebase Operation
  /// Shows safe navigation after a Firebase operation completes
  static void navigateAfterFirebaseOperation(WidgetRef ref) async {
    // Get the navigation service from Riverpod
    final navigation = ref.read(asyncNavigationServiceProvider);
    
    try {
      // Simulate a Firebase operation
      await Future.delayed(const Duration(seconds: 1));
      final bool success = true; // This would be the result of your Firebase operation
      
      // Navigate based on the operation result
      if (success) {
        // Safe navigation without BuildContext
        navigation.goToProfile();
      }
    } catch (e) {
      debugPrint('Firebase operation failed: $e');
      // Handle the error case with navigation if needed
    }
  }
  
  /// Example 4: Navigation in StateNotifier
  /// Shows how to use AsyncNavigationService in a StateNotifier
  static StateNotifierProvider<ExampleStateNotifier, bool> exampleNotifierProvider = 
      StateNotifierProvider<ExampleStateNotifier, bool>((ref) {
    return ExampleStateNotifier(ref);
  });
}

/// Example StateNotifier that uses AsyncNavigationService for navigation
class ExampleStateNotifier extends StateNotifier<bool> {
  final Ref _ref;
  
  ExampleStateNotifier(this._ref) : super(false);
  
  /// Process login and navigate on success
  Future<void> processLogin(String username, String password) async {
    try {
      // Set loading state
      state = true;
      
      // Perform login logic (mocked)
      await Future.delayed(const Duration(seconds: 2));
      final success = username.isNotEmpty && password.isNotEmpty;
      
      if (success) {
        // Get navigation service
        final navigation = _ref.read(asyncNavigationServiceProvider);
        
        // Navigate without BuildContext - safe across async gap
        navigation.goToHome();
      }
      
      // Update state
      state = false;
    } catch (e) {
      // Handle error
      state = false;
      debugPrint('Login error: $e');
    }
  }
  
  /// Log out and navigate to login screen
  Future<void> logout() async {
    try {
      // Set loading state
      state = true;
      
      // Perform logout logic
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Navigate to login page - safe across async gap
      final navigation = _ref.read(asyncNavigationServiceProvider);
      navigation.go('/login');
      
      // Update state
      state = false;
    } catch (e) {
      // Handle error
      state = false;
      debugPrint('Logout error: $e');
    }
  }
}

/// Example widget showing how to use AsyncNavigationService in a widget
class AsyncNavigationExampleWidget extends ConsumerWidget {
  const AsyncNavigationExampleWidget({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the AsyncNavigationService via extension method
    // This is for immediate use in event handlers
    final asyncNavigation = context.asyncNavigation;
    
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            // Direct navigation from UI event - no problem with context
            asyncNavigation.goToHome();
          },
          child: const Text('Navigate Home (Direct)'),
        ),
        ElevatedButton(
          onPressed: () {
            // Example of navigating after an async operation
            AsyncNavigationExamples.navigateAfterAsyncOperation(ref);
          },
          child: const Text('Navigate After Async Operation'),
        ),
        ElevatedButton(
          onPressed: () {
            // Example of using the AsyncNavigationService in a StateNotifier
            final notifier = ref.read(AsyncNavigationExamples.exampleNotifierProvider.notifier);
            notifier.processLogin('user', 'pass');
          },
          child: const Text('Process Login & Navigate'),
        ),
      ],
    );
  }
} 