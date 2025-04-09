import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Space Discovery and Joining Flow Tests', () {
    // Test account credentials that will be set during test setup
    late Map<String, String> testAccount;
    
    testWidgets('User can discover, view, join and leave spaces',
        (WidgetTester tester) async {
      // Initialize the app
      await initializeApp();
      await launchApp(tester);
      
      // STEP 1: Create a test account and complete onboarding
      testAccount = await createTestAccount(tester);
      
      // Assuming we're on the main app screen after onboarding
      
      // STEP 2: Navigate to spaces tab
      await tester.tap(find.byIcon(Icons.people_alt_outlined));
      await tester.pumpAndSettle();
      
      // Take screenshot of spaces page
      await takeScreenshot('spaces_discovery_page');
      
      // STEP 3: Search for a space
      // Find and tap on the search field
      final searchIcon = find.byIcon(Icons.search);
      await tester.tap(searchIcon);
      await tester.pumpAndSettle();
      
      // Enter a search term
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'Club');
      await tester.pumpAndSettle();
      
      // Take screenshot of search results
      await takeScreenshot('space_search_results');
      
      // STEP 4: Select a space from search results
      // Find the first space card and tap it
      final firstSpaceCard = find.byType(Card).first;
      await tester.tap(firstSpaceCard);
      await tester.pumpAndSettle();
      
      // Take screenshot of space details
      await takeScreenshot('space_details_page');
      
      // STEP 5: Join the space
      final joinButton = find.text('Join');
      if (joinButton.evaluate().isNotEmpty) {
        await tester.tap(joinButton);
        await tester.pumpAndSettle();
        
        // Verify we've joined (button should change)
        expect(find.text('Joined'), findsOneWidget);
      } else {
        // If we're already a member, we should see "Joined"
        expect(find.text('Joined'), findsOneWidget);
      }
      
      // Take screenshot of joined state
      await takeScreenshot('space_joined_state');
      
      // STEP 6: View space message board
      final messageTab = find.text('Messages');
      await tester.tap(messageTab);
      await tester.pumpAndSettle();
      
      // Take screenshot of message board
      await takeScreenshot('space_message_board');
      
      // STEP 7: View space members
      final membersTab = find.text('Members');
      await tester.tap(membersTab);
      await tester.pumpAndSettle();
      
      // Take screenshot of members list
      await takeScreenshot('space_members_list');
      
      // STEP 8: Return to main tab and leave the space
      // Go back to space details
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      
      // Find and tap the menu button
      final menuButton = find.byIcon(Icons.more_vert);
      await tester.tap(menuButton);
      await tester.pumpAndSettle();
      
      // Tap "Leave Space" option
      final leaveOption = find.text('Leave Space');
      await tester.tap(leaveOption);
      await tester.pumpAndSettle();
      
      // Confirm leaving
      final confirmButton = find.text('Leave');
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();
      
      // Verify we're back on the spaces discovery page
      expect(find.byIcon(Icons.search), findsOneWidget);
      await takeScreenshot('space_discovery_after_leaving');
      
      // STEP 9: Browse spaces by category
      // Find category filter dropdown or button
      final categoryFilter = find.text('All Categories');
      await tester.tap(categoryFilter);
      await tester.pumpAndSettle();
      
      // Select a specific category
      final academicCategory = find.text('Academic');
      await tester.tap(academicCategory);
      await tester.pumpAndSettle();
      
      // Take screenshot of filtered spaces
      await takeScreenshot('spaces_filtered_by_category');
      
      // Clean up test data
      await cleanupTestData(testAccount['email']!);
    });
  });
} 