import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Registration and Onboarding Flow Tests', () {
    testWidgets('User can create account and complete basic profile setup',
        (WidgetTester tester) async {
      // Initialize the app
      await initializeApp();
      await launchApp(tester);
      
      // Take initial screenshot
      await takeScreenshot('onboarding_start');
      
      // Generate a unique test email
      final testEmail = generateTestEmail();
      const testPassword = 'Test@123456';
      
      // STEP 1: Find the Create Account button and tap it
      await tester.pumpAndSettle();
      expect(find.text('Create Account'), findsOneWidget);
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();
      
      // Take screenshot of registration page
      await takeScreenshot('registration_page');
      
      // STEP 2: Fill out registration form
      await tester.enterText(find.byType(TextField).at(0), testEmail);
      await tester.enterText(find.byType(TextField).at(1), testPassword);
      await tester.enterText(find.byType(TextField).at(2), testPassword);
      
      // STEP 3: Submit registration
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // STEP 4: Verify we're on the onboarding profile page
      // This may need adjusting based on your actual UI
      expect(find.text('Create Your Profile'), findsOneWidget);
      await takeScreenshot('onboarding_profile_page');
      
      // STEP 5: Fill in basic profile information
      // Find and fill the name field
      final nameField = find.byKey(const Key('name_field'));
      await tester.enterText(nameField, 'Test User');
      
      // Find and select university
      final universityField = find.byKey(const Key('university_field'));
      await tester.tap(universityField);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sample University').first);
      await tester.pumpAndSettle();
      
      // Find and select graduation year
      final gradYearField = find.byKey(const Key('graduation_year_field'));
      await tester.tap(gradYearField);
      await tester.pumpAndSettle();
      await tester.tap(find.text('2025').first);
      await tester.pumpAndSettle();
      
      // Find and select major
      final majorField = find.byKey(const Key('major_field'));
      await tester.tap(majorField);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Computer Science').first);
      await tester.pumpAndSettle();
      
      // STEP 6: Tap the Continue button
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      
      // Take screenshot of interests selection page
      await takeScreenshot('interests_selection_page');
      
      // STEP 7: Select some interests
      // Find and select at least 3 interests
      final interestTags = find.byType(Chip);
      
      // Select first 3 interests
      for (int i = 0; i < 3; i++) {
        await tester.tap(interestTags.at(i));
        await tester.pumpAndSettle();
      }
      
      // STEP 8: Tap Continue to complete onboarding
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      // STEP 9: Verify we're on the main app screen (Home/Feed)
      // This will depend on where your app navigates after onboarding
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      await takeScreenshot('main_app_screen');
      
      // Clean up test data
      await cleanupTestData(testEmail);
    });
  });
} 