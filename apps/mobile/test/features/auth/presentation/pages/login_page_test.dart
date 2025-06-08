import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/features/auth/presentation/components/auth/login_form.dart';
import 'package:hive_ui/features/auth/presentation/pages/login_page.dart';
import 'package:hive_ui/services/user_preferences_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hive_ui/core/widgets/hive_primary_button.dart';
import 'package:hive_ui/features/auth/presentation/components/auth/social_auth_button.dart';

// Mocks
class MockGoRouter extends Mock implements GoRouter {}
class MockUserPreferencesService extends Mock implements UserPreferencesService {}

// Helper to pump widget with providers and mock router
Future<void> pumpLoginPage(WidgetTester tester) async {
  // Mock UserPreferencesService initialization if needed (it's static)
  // Assuming UserPreferencesService.initialize() is called elsewhere or handled safely.
  // We might need to mock static methods if they are called directly during build.
  // For now, assume it's initialized or methods handle null _preferences.

  // Mock static methods needed during build/interaction (if any)
  // For example, if getSocialAuthRedirectPath is static and called:
  // when(() => UserPreferencesService.getSocialAuthRedirectPath()).thenReturn('');
  // when(() => UserPreferencesService.hasCompletedOnboarding()).thenReturn(true); // Example

  await tester.pumpWidget(
    ProviderScope(
      // Override providers if LoginPage directly interacts with them
      // e.g., authRepositoryProvider, authControllerProvider
      overrides: const [
        // Add overrides for providers used by LoginPage or its children if needed
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/login',
          routes: [
            GoRoute(
              path: '/login',
              builder: (context, state) => const LoginPage(),
            ),
            // Add other routes needed for navigation tests (e.g., '/', '/register')
            GoRoute(path: '/', builder: (context, state) => const Scaffold()),
            GoRoute(path: '/register', builder: (context, state) => const Scaffold()),
             GoRoute(path: '/home', builder: (context, state) => const Scaffold(body: Text('Home'))),
            GoRoute(path: '/onboarding/username', builder: (context, state) => const Scaffold(body: Text('Onboarding'))),
          ],
        ),
        // No need to override routerDelegate/parser/provider when using routerConfig
      ),
    ),
  );
  // Pump and settle to allow initial frame rendering and animations
  await tester.pumpAndSettle();
}


void main() {
  // MockGoRouter instance is not needed if we let GoRouter handle navigation
  // late MockGoRouter mockGoRouter;

  setUpAll(() {
     // Mock static methods ONLY ONCE if they don't change per test
     // These are needed because LoginPage calls them in _handleAuthResult
     // and potentially during build.
    registerFallbackValue(Uri.parse('/')); // Fallback for Uri arguments if mocking navigation
    when(() => UserPreferencesService.getSocialAuthRedirectPath()).thenReturn('');
    when(() => UserPreferencesService.hasCompletedOnboarding()).thenReturn(true);
    // Mock clearSocialAuthRedirectPath to return a Future<bool>
    when(() => UserPreferencesService.clearSocialAuthRedirectPath()).thenAnswer((_) async => true);
  });

  setUp(() {
    // No mockGoRouter setup needed anymore
  });

  testWidgets('LoginPage renders correctly', (WidgetTester tester) async {
    await pumpLoginPage(tester);

    // Verify key elements are present
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(LoginForm), findsOneWidget); // Check if LoginForm is present
    // Check for AppBar by finding the back button icon if AppBarBuilder adds one
    expect(find.byIcon(Icons.arrow_back_ios), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign in to continue your journey'), findsOneWidget);

    // Check for form fields within LoginForm (more specific)
    // Find by type first, then potentially add keys to HiveTextFormField for robustness
    expect(find.byType(TextFormField), findsNWidgets(2)); // Expect Email and Password fields

    // Check for buttons
    expect(find.widgetWithText(TextButton, 'Forgot Password?'), findsOneWidget);
    // Find HivePrimaryButton by type
    expect(find.byType(HivePrimaryButton), findsOneWidget);

    // Check for "OR" divider section (could be more specific)
    expect(find.text('OR'), findsOneWidget);
    expect(find.byType(Divider), findsNWidgets(2));

    // Check for Social Auth Button
    expect(find.byType(SocialAuthButton), findsOneWidget);

    // Check for Sign Up link
    expect(find.text("Don't have an account?"), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Sign Up'), findsOneWidget);
  });

  // Add more tests:
  // - Test form validation (find fields, enter text, tap button, check for errors)
  // - Test successful login navigation (mock auth success, tap button, verify navigation)
  // - Test failed login (mock auth failure, tap button, verify error message/toast)
  // - Test 'Forgot Password?' button tap (verify bottom sheet appears)
  // - Test 'Sign Up' button tap (verify navigation to /register)
}

// Helper mock class if needed for GoRouter setup
// class MockRouteInformationParser extends Mock implements RouteInformationParser<Object> {} 