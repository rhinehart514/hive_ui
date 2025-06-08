import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/auth/domain/repositories/auth_repository.dart';
import 'package:hive_ui/features/auth/presentation/pages/oauth_callback_page.dart';
import 'package:hive_ui/features/auth/providers/auth_providers.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Create manual mocks for testing
class MockAuthRepository extends Mock implements AuthRepository {}

@GenerateMocks([])
void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();

    // Set up shared preferences for tests
    SharedPreferences.setMockInitialValues({
      'oauth_state': 'test_state',
      'oauth_state_timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
      ],
      child: const MaterialApp(
        home: OAuthCallbackPage(provider: 'google-edu'),
      ),
    );
  }

  group('OAuthCallbackPage', () {
    testWidgets('shows loading state initially', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      
      expect(find.text('Processing your google edu sign-in...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error message when code is missing', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle(const Duration(seconds: 1));
      
      expect(find.text('Authentication failed: Missing authorization code'), findsOneWidget);
      expect(find.text('Return to Sign In'), findsOneWidget);
    });

    testWidgets('has a button to return to sign-in', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle(const Duration(seconds: 1));
      
      // Just verify the button exists and can be tapped (without verifying navigation)
      expect(find.text('Return to Sign In'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
      
      await tester.tap(find.text('Return to Sign In'));
      await tester.pumpAndSettle();
      
      // Navigation cannot be tested directly with this approach, but the button can be tapped
    });

    // TODO: Implement more test cases when mock setup is complete
    // 1. Successful auth flow with valid code
    // 2. Error handling for invalid code
    // 3. Timeout behavior
    // 4. Error states from Firebase Auth
  });
} 