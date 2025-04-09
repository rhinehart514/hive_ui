import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Content Creation and Sharing Flow Tests', () {
    // Test account credentials that will be set during test setup
    late Map<String, String> testAccount;
    
    testWidgets('User can create, edit, interact with, and delete content',
        (WidgetTester tester) async {
      // Initialize the app
      await initializeApp();
      await launchApp(tester);
      
      // STEP 1: Create a test account and complete onboarding
      testAccount = await createTestAccount(tester);
      
      // Assuming we're on the main app screen after onboarding
      
      // STEP 2: Navigate to feed/home tab
      await tester.tap(find.byIcon(Icons.home));
      await tester.pumpAndSettle();
      
      // Take screenshot of feed page
      await takeScreenshot('feed_page');
      
      // STEP 3: Tap on create post button
      final createPostButton = find.byIcon(Icons.add_circle_outline);
      await tester.tap(createPostButton);
      await tester.pumpAndSettle();
      
      // Take screenshot of create post page
      await takeScreenshot('create_post_page');
      
      // STEP 4: Create a simple text post
      // Enter post content
      final postContentField = find.byType(TextField).first;
      await tester.enterText(postContentField, 'This is a test post created by integration testing.');
      
      // STEP 5: Add a tag or topic
      final addTagButton = find.byIcon(Icons.tag);
      await tester.tap(addTagButton);
      await tester.pumpAndSettle();
      
      // Select a tag from the list
      final firstTag = find.byType(Chip).first;
      await tester.tap(firstTag);
      await tester.pumpAndSettle();
      
      // STEP 6: Post the content
      final postButton = find.text('Post');
      await tester.tap(postButton);
      await tester.pumpAndSettle();
      
      // Take screenshot of feed after posting
      await takeScreenshot('feed_after_posting');
      
      // STEP 7: Find and interact with the post
      // The post should be at the top of the feed, find by content
      await scrollUntilVisible(tester, 'This is a test post created by integration testing.');
      
      // Like the post
      final likeButton = find.byIcon(Icons.favorite_border);
      await tester.tap(likeButton);
      await tester.pumpAndSettle();
      
      // Verify like was successful (icon should change)
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      await takeScreenshot('post_liked');
      
      // STEP 8: Add a comment to the post
      // Find and tap comment button
      final commentButton = find.byIcon(Icons.chat_bubble_outline);
      await tester.tap(commentButton);
      await tester.pumpAndSettle();
      
      // Take screenshot of comments section
      await takeScreenshot('post_comments_page');
      
      // Enter comment text
      final commentField = find.byType(TextField).first;
      await tester.enterText(commentField, 'This is a test comment');
      
      // Submit comment
      final submitCommentButton = find.byIcon(Icons.send);
      await tester.tap(submitCommentButton);
      await tester.pumpAndSettle();
      
      // Verify comment appears
      expect(find.text('This is a test comment'), findsOneWidget);
      await takeScreenshot('post_with_comment');
      
      // Go back to the main feed
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      
      // STEP 9: Repost the content
      // Find and tap repost button
      final repostButton = find.byIcon(Icons.repeat);
      await tester.tap(repostButton);
      await tester.pumpAndSettle();
      
      // Add repost comment (if applicable)
      final repostCommentField = find.byType(TextField).first;
      if (repostCommentField.evaluate().isNotEmpty) {
        await tester.enterText(repostCommentField, 'Reposting this great content!');
      }
      
      // Confirm repost
      final confirmRepostButton = find.text('Repost');
      await tester.tap(confirmRepostButton);
      await tester.pumpAndSettle();
      
      // Take screenshot after reposting
      await takeScreenshot('feed_after_repost');
      
      // STEP 10: Edit the original post
      // Find and tap on the post options menu
      await scrollUntilVisible(tester, 'This is a test post created by integration testing.');
      final postOptionsButton = find.byIcon(Icons.more_vert).first;
      await tester.tap(postOptionsButton);
      await tester.pumpAndSettle();
      
      // Tap on edit option
      final editOption = find.text('Edit');
      await tester.tap(editOption);
      await tester.pumpAndSettle();
      
      // Update the post content
      final editPostField = find.byType(TextField).first;
      await tester.enterText(editPostField, 'This is an updated test post.');
      
      // Save changes
      final saveButton = find.text('Save');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();
      
      // Verify changes were applied
      expect(find.text('This is an updated test post.'), findsOneWidget);
      await takeScreenshot('post_after_edit');
      
      // STEP 11: Delete the post
      // Find and tap on the post options menu again
      final updatedPostOptionsButton = find.byIcon(Icons.more_vert).first;
      await tester.tap(updatedPostOptionsButton);
      await tester.pumpAndSettle();
      
      // Tap on delete option
      final deleteOption = find.text('Delete');
      await tester.tap(deleteOption);
      await tester.pumpAndSettle();
      
      // Confirm deletion
      final confirmDeleteButton = find.text('Delete');
      await tester.tap(confirmDeleteButton);
      await tester.pumpAndSettle();
      
      // Take screenshot of feed after deletion
      await takeScreenshot('feed_after_deletion');
      
      // Clean up test data
      await cleanupTestData(testAccount['email']!);
    });
  });
} 