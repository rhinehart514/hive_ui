import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/core/navigation/routes.dart';
import 'package:hive_ui/features/auth/presentation/pages/magic_link_sent_page.dart';
import 'package:mockito/mockito.dart';

// Mock GoRouter
class MockGoRouter extends Mock implements GoRouter {}

void main() {
  // Mock GoRouter setup for testing navigation
  final mockGoRouter = MockGoRouter();

  // Helper function to pump the widget
  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: AppRoutes.magicLinkSent,
            routes: [
              GoRoute(
                path: AppRoutes.magicLinkSent,
                builder: (context, state) => const MagicLinkSentPage(),
              ),
              GoRoute(
                path: AppRoutes.signIn,
                builder: (context, state) => const Scaffold(body: Text('Sign In Mock')), // Mock destination
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('MagicLinkSentPage renders correctly', (WidgetTester tester) async {
    await pumpPage(tester);

    // Verify AppBar title
    expect(find.text('Verification Link Sent'), findsOneWidget);
    // Verify icon
    expect(find.byIcon(Icons.outgoing_mail), findsOneWidget);
    // Verify descriptive text
    expect(find.textContaining('We\'ve sent a verification link'), findsOneWidget);
    // Verify button
    expect(find.widgetWithText(OutlinedButton, 'Back to Sign In'), findsOneWidget);
  });

  testWidgets('MagicLinkSentPage button navigates to sign in', (WidgetTester tester) async {
     await pumpPage(tester);

    // Find the button and tap it
    final button = find.widgetWithText(OutlinedButton, 'Back to Sign In');
    await tester.tap(button);
    await tester.pumpAndSettle(); // Allow navigation to complete

    // Verify navigation occurred
    expect(find.text('Sign In Mock'), findsOneWidget);
  });
} 