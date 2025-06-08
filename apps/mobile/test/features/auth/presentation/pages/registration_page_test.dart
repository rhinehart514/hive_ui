import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/features/auth/presentation/pages/registration_page.dart';
import 'package:hive_ui/services/user_preferences_service.dart';
import 'package:hive_ui/core/widgets/hive_primary_button.dart';
import 'package:hive_ui/widgets/form_fields/hive_text_form_field.dart';
import 'package:mocktail/mocktail.dart';

// Mocks
class MockGoRouter extends Mock implements GoRouter {}
class MockUserPreferencesService extends Mock implements UserPreferencesService {}

// Helper to pump widget with providers
Future<void> pumpRegistrationPage(WidgetTester tester) async {
  // Mock UserPreferencesService static methods if needed
  // Assuming initialize() is handled elsewhere

  await tester.pumpWidget(
    ProviderScope(
      // Override providers if RegistrationPage directly interacts with them
      // e.g., authRepositoryProvider, authControllerProvider
      overrides: const [
        // Add overrides here
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/register', // Start at the registration page
          routes: [
            GoRoute(
              path: '/register',
              builder: (context, state) => const RegistrationPage(),
            ),
            // Add other routes needed for navigation tests
            GoRoute(path: '/login', builder: (context, state) => const Scaffold()),
            GoRoute(path: '/onboarding/username', builder: (context, state) => const Scaffold(body: Text('Onboarding'))),
            // Add routes for terms/privacy if testing those links
            // GoRoute(path: '/terms', builder: (context, state) => const Scaffold(body: Text('Terms'))),
            // GoRoute(path: '/privacy', builder: (context, state) => const Scaffold(body: Text('Privacy'))),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle(); // Allow initial build
}

void main() {
  setUpAll(() {
    // Mock static UserPreferencesService methods if needed globally
    registerFallbackValue(Uri.parse('/'));
    // Mock methods called during registration flow (e.g., setNeedsOnboarding)
    when(() => UserPreferencesService.setNeedsOnboarding(any())).thenAnswer((_) async => true);
  });

  testWidgets('RegistrationPage renders correctly', (WidgetTester tester) async {
    await pumpRegistrationPage(tester);

    // Verify key elements
    expect(find.byType(RegistrationPage), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios), findsOneWidget); // AppBar back button
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Start by entering your details below'), findsOneWidget);

    // Verify form fields
    // Using HiveTextFormField type might be too broad if other fields use it.
    // Consider adding Keys or finding by labelText.
    expect(find.widgetWithText(HiveTextFormField, 'School Email (.edu)'), findsOneWidget);
    expect(find.widgetWithText(HiveTextFormField, 'Password'), findsOneWidget);
    expect(find.widgetWithText(HiveTextFormField, 'Confirm Password'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(3)); // Check total TextFormField count

    // Verify buttons
    expect(find.byType(HivePrimaryButton), findsOneWidget);
    expect(find.widgetWithText(HivePrimaryButton, 'Create Account'), findsOneWidget);

    // Verify Terms/Privacy text
    expect(find.textContaining('Terms & Conditions'), findsOneWidget);
    expect(find.textContaining('Privacy Policy'), findsOneWidget);

    // Verify Login link
    expect(find.text('Already have an account?'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Log In'), findsOneWidget);
  });

  // Add more tests:
  // - Test form validation (.edu requirement, password length, matching passwords)
  // - Test successful registration (mock auth success, tap button, verify verification sheet appears)
  // - Test failed registration (email exists, other errors)
  // - Test tapping Terms/Privacy links (verify navigation or action)
  // - Test tapping Log In link (verify navigation to /login)
} 