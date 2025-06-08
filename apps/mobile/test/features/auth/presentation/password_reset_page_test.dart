import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/core/navigation/routes.dart';
import 'package:hive_ui/features/auth/presentation/pages/password_reset_page.dart';
import 'package:mockito/mockito.dart';

// Mock GoRouter
class MockGoRouter extends Mock implements GoRouter {}

void main() {
  // Mock GoRouter setup for testing navigation
  final mockGoRouter = MockGoRouter();

  // Helper function to pump the widget within ProviderScope and MaterialApp
  Future<void> pumpPasswordResetPage(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: AppRoutes.passwordReset, // Start at the page we test
            routes: [
              GoRoute(
                path: AppRoutes.passwordReset,
                builder: (context, state) => const PasswordResetPage(),
              ),
              GoRoute(
                path: AppRoutes.passwordResetSent,
                builder: (context, state) => const Scaffold(body: Text('Password Reset Sent Mock')), // Mock destination
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('PasswordResetPage renders correctly', (WidgetTester tester) async {
    await pumpPasswordResetPage(tester);

    // Verify AppBar title
    expect(find.text('Reset Password'), findsOneWidget);
    // Verify introductory text
    expect(find.textContaining('Enter your account email'), findsOneWidget);
    // Verify email input field
    expect(find.byType(TextFormField), findsOneWidget);
    // Verify submit button
    expect(find.widgetWithText(ElevatedButton, 'Send Reset Link'), findsOneWidget);
  });

  testWidgets('PasswordResetPage shows error for invalid email', (WidgetTester tester) async {
    await pumpPasswordResetPage(tester);

    // Find the submit button and tap it without entering email
    final submitButton = find.widgetWithText(ElevatedButton, 'Send Reset Link');
    await tester.tap(submitButton);
    await tester.pump(); // Rebuild after validation

    // Verify validation error message
    expect(find.text('Please enter a valid email address'), findsOneWidget);
  });

  testWidgets('PasswordResetPage handles submission (simulated)', (WidgetTester tester) async {
    // Use a Mock GoRouter or a custom GoRouter setup for navigation testing
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: GoRouter(
            // Use the mock router for navigation verification if needed
            // initialLocation: ..., routes: ...
            initialLocation: AppRoutes.passwordReset,
            routes: [
              GoRoute(
                path: AppRoutes.passwordReset,
                builder: (context, state) => const PasswordResetPage(),
              ),
              GoRoute(
                path: AppRoutes.passwordResetSent,
                builder: (context, state) => const Scaffold(body: Text('Password Reset Sent Mock')), // Mock destination
              ),
            ],
          ),
        ),
      ),
    );

    // Enter valid email
    await tester.enterText(find.byType(TextFormField), 'test@example.com');
    await tester.pump();

    // Find the submit button and tap it
    final submitButton = find.widgetWithText(ElevatedButton, 'Send Reset Link');
    await tester.tap(submitButton);
    await tester.pump(); // Show loading indicator

    // Verify loading indicator is shown (adjust finder if needed)
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // TODO: Mock the authRepositoryProvider to simulate success/failure
    // For now, we simulate the delay and expect navigation

    await tester.pump(const Duration(seconds: 2)); // Wait for simulated delay

    // Verify navigation occurred (check if the mock destination page is displayed)
    expect(find.text('Password Reset Sent Mock'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing); // Loading indicator gone
  });

  // TODO: Add test for error scenario (mocking provider to throw)
} 