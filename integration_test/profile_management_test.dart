import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Profile Management Flow Tests', () {
    // Test account credentials that will be set during test setup
    late Map<String, String> testAccount;
    
    testWidgets('User can view and edit profile information',
        (WidgetTester tester) async {
      // Initialize the app
      await initializeApp();
      await launchApp(tester);
      
      // Take initial screenshot
      await takeScreenshot('profile_test_start');
      
      // STEP 1: Create a test account and complete onboarding
      testAccount = await createTestAccount(tester);
      
      // Assuming we're already logged in after account creation
      // and have completed basic onboarding
      
      // STEP 2: Navigate to profile page
      await tester.tap(find.byIcon(Icons.person).last);
      await tester.pumpAndSettle();
      
      // Take screenshot of profile page
      await takeScreenshot('profile_page');
      
      // STEP 3: Verify profile elements are visible
      expect(find.text('Test User'), findsOneWidget); // From onboarding
      
      // STEP 4: Tap on edit profile button
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();
      
      // Take screenshot of edit profile page
      await takeScreenshot('edit_profile_page');
      
      // STEP 5: Edit profile information
      // Find and update the bio field
      final bioField = find.byKey(const Key('bio_field'));
      await tester.enterText(bioField, 'This is a test bio created by automated testing');
      
      // Find and tap interests to modify
      await tester.tap(find.text('Interests'));
      await tester.pumpAndSettle();
      
      // Select an additional interest
      final interestTags = find.byType(Chip);
      await tester.tap(interestTags.at(5)); // Select a different interest
      await tester.pumpAndSettle();
      
      // Go back to main edit screen
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      
      // STEP 6: Save profile changes
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      
      // STEP 7: Verify changes were applied
      expect(find.text('This is a test bio created by automated testing'), findsOneWidget);
      await takeScreenshot('updated_profile_page');
      
      // STEP 8: Change profile visibility settings
      // Tap on settings icon
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      
      // Navigate to privacy settings
      await tester.tap(find.text('Privacy & Security'));
      await tester.pumpAndSettle();
      
      // Change profile visibility
      await tester.tap(find.text('Profile Visibility'));
      await tester.pumpAndSettle();
      
      // Select "Friends Only" option
      await tester.tap(find.text('Friends Only'));
      await tester.pumpAndSettle();
      
      // Take screenshot of visibility settings
      await takeScreenshot('profile_visibility_settings');
      
      // Go back to main settings
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      
      // Go back to profile
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      
      // STEP 9: View profile analytics (if available)
      await tester.tap(find.text('Analytics'));
      await tester.pumpAndSettle();
      
      // Take screenshot of analytics page
      await takeScreenshot('profile_analytics_page');
      
      // Clean up test data
      await cleanupTestData(testAccount['email']!);
    });
  });
} 