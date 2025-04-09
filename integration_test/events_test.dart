import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Event Creation and RSVP Flow Tests', () {
    // Test account credentials that will be set during test setup
    late Map<String, String> testAccount;
    
    testWidgets('User can create, edit, RSVP to, and share events',
        (WidgetTester tester) async {
      // Initialize the app
      await initializeApp();
      await launchApp(tester);
      
      // STEP 1: Create a test account and complete onboarding
      testAccount = await createTestAccount(tester);
      
      // Assuming we're on the main app screen after onboarding
      
      // STEP 2: Navigate to events tab
      await tester.tap(find.byIcon(Icons.event_outlined));
      await tester.pumpAndSettle();
      
      // Take screenshot of events page
      await takeScreenshot('events_page');
      
      // STEP 3: Tap on create event button
      final createEventButton = find.byIcon(Icons.add);
      await tester.tap(createEventButton);
      await tester.pumpAndSettle();
      
      // Take screenshot of create event page
      await takeScreenshot('create_event_page');
      
      // STEP 4: Fill event details
      // Enter event title
      final titleField = find.byKey(const Key('event_title_field'));
      await tester.enterText(titleField, 'Test Integration Event');
      
      // Enter event description
      final descriptionField = find.byKey(const Key('event_description_field'));
      await tester.enterText(descriptionField, 'This is a test event created by automated testing.');
      
      // Set event location
      final locationField = find.byKey(const Key('event_location_field'));
      await tester.enterText(locationField, 'Test Location, Room 123');
      
      // Select event date
      final dateField = find.byKey(const Key('event_date_field'));
      await tester.tap(dateField);
      await tester.pumpAndSettle();
      
      // Select a date from the date picker (today + 1 day)
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      
      // Select event time
      final timeField = find.byKey(const Key('event_time_field'));
      await tester.tap(timeField);
      await tester.pumpAndSettle();
      
      // Select a time from the time picker
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      
      // Set event capacity
      final capacityField = find.byKey(const Key('event_capacity_field'));
      await tester.enterText(capacityField, '50');
      
      // STEP 5: Create the event
      final createButton = find.text('Create Event');
      await tester.tap(createButton);
      await tester.pumpAndSettle();
      
      // Take screenshot of events list after creation
      await takeScreenshot('events_list_after_creation');
      
      // STEP 6: Find and view the created event
      // Find our test event by title
      await scrollUntilVisible(tester, 'Test Integration Event');
      await tester.tap(find.text('Test Integration Event'));
      await tester.pumpAndSettle();
      
      // Take screenshot of event details
      await takeScreenshot('event_details_page');
      
      // STEP 7: Edit the event
      final editButton = find.byIcon(Icons.edit);
      await tester.tap(editButton);
      await tester.pumpAndSettle();
      
      // Update event description
      await tester.enterText(find.byKey(const Key('event_description_field')), 
        'This is an updated test event description.');
      
      // Save changes
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();
      
      // Verify changes were applied
      expect(find.text('This is an updated test event description.'), findsOneWidget);
      await takeScreenshot('updated_event_details');
      
      // STEP 8: RSVP to the event
      final rsvpButton = find.text('RSVP');
      await tester.tap(rsvpButton);
      await tester.pumpAndSettle();
      
      // Verify RSVP success
      expect(find.text('Going'), findsOneWidget);
      await takeScreenshot('event_rsvp_confirmed');
      
      // STEP 9: View attendees
      final attendeesTab = find.text('Attendees');
      await tester.tap(attendeesTab);
      await tester.pumpAndSettle();
      
      // Take screenshot of attendees list
      await takeScreenshot('event_attendees_list');
      
      // STEP 10: Share the event
      // Go back to details
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      
      // Find and tap share button
      final shareButton = find.byIcon(Icons.share);
      await tester.tap(shareButton);
      await tester.pumpAndSettle();
      
      // Take screenshot of share dialog
      await takeScreenshot('event_share_dialog');
      
      // Close share dialog by tapping outside (if needed)
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      
      // STEP 11: Cancel RSVP
      // Find and tap the RSVP status button (now showing 'Going')
      final goingButton = find.text('Going');
      await tester.tap(goingButton);
      await tester.pumpAndSettle();
      
      // Select 'Not Going' option
      final notGoingOption = find.text('Not Going');
      await tester.tap(notGoingOption);
      await tester.pumpAndSettle();
      
      // Verify RSVP status changed
      expect(find.text('RSVP'), findsOneWidget);
      await takeScreenshot('event_rsvp_cancelled');
      
      // STEP 12: Delete the event
      // Find and tap the menu button
      final menuButton = find.byIcon(Icons.more_vert);
      await tester.tap(menuButton);
      await tester.pumpAndSettle();
      
      // Tap "Delete Event" option
      final deleteOption = find.text('Delete Event');
      await tester.tap(deleteOption);
      await tester.pumpAndSettle();
      
      // Confirm deletion
      final confirmButton = find.text('Delete');
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();
      
      // Verify we're back on the events list
      expect(find.text('Upcoming Events'), findsOneWidget);
      await takeScreenshot('events_list_after_deletion');
      
      // Clean up test data
      await cleanupTestData(testAccount['email']!);
    });
  });
} 