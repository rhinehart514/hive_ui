import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_ui/firebase_options.dart';
import 'package:hive_ui/main.dart' as app;

/// Initializes the app for testing
Future<void> initializeApp() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with the test project
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Wait for any initialization to complete
  await Future.delayed(const Duration(seconds: 1));
}

/// Launches the app and returns once it's stable
Future<void> launchApp(WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle();
}

/// Creates a unique test email for test isolation
String generateTestEmail() {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  return 'test_$timestamp@example.com';
}

/// Takes a screenshot during the test
/// Note: Screenshots are collected by the integration_test package's
/// screenshot capability and are available after the test is complete
Future<void> takeScreenshot(String name) async {
  // This uses the integration_test package to capture screenshots
  await IntegrationTestWidgetsFlutterBinding.instance.takeScreenshot(name);
  print('Screenshot taken: $name');
}

/// Finds text on the screen and scrolls until it's found, or times out
Future<void> scrollUntilVisible(
  WidgetTester tester,
  String text, {
  Finder? scrollable,
  bool scrollDown = true,
  int maxScrolls = 20,
}) async {
  final finder = find.text(text);
  scrollable ??= find.byType(Scrollable).first;
  
  for (var i = 0; i < maxScrolls; i++) {
    if (finder.evaluate().isNotEmpty) {
      // Found the text, no need to scroll further
      return;
    }
    
    await tester.drag(
      scrollable,
      scrollDown ? const Offset(0, -300) : const Offset(0, 300),
    );
    await tester.pumpAndSettle();
  }
  
  throw Exception('Could not find "$text" after $maxScrolls scrolls');
}

/// Signs in with email and password
Future<void> signInWithEmailAndPassword(
  WidgetTester tester,
  String email,
  String password,
) async {
  // Assumes we're on the login screen
  await tester.enterText(find.byType(TextField).at(0), email);
  await tester.enterText(find.byType(TextField).at(1), password);
  
  // Find and tap the login button
  await tester.tap(find.text('Log In'));
  await tester.pumpAndSettle();
}

/// Creates a test account for integration testing
Future<Map<String, String>> createTestAccount(WidgetTester tester) async {
  final email = generateTestEmail();
  const password = 'Test@123456';
  
  // Tap on "Create Account" button
  await tester.tap(find.text('Create Account'));
  await tester.pumpAndSettle();
  
  // Fill out registration form
  await tester.enterText(find.byType(TextField).at(0), email);
  await tester.enterText(find.byType(TextField).at(1), password);
  await tester.enterText(find.byType(TextField).at(2), password);
  
  // Submit registration
  await tester.tap(find.text('Sign Up'));
  await tester.pumpAndSettle(const Duration(seconds: 3));
  
  return {
    'email': email,
    'password': password,
  };
}

/// Cleans up test data after a test is complete
Future<void> cleanupTestData(String email) async {
  // Implement this to delete test accounts and any created data
  // This would typically involve Firebase Admin SDK calls or similar
  print('Cleaning up test data for: $email');
} 