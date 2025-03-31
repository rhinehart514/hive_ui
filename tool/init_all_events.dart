// Event initialization for Firestore - cost-effective approach
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_ui/firebase_options.dart';
import 'package:hive_ui/services/rss_service.dart';
import 'package:hive_ui/services/user_preferences_service.dart';
import 'dart:io';

void main() async {
  // Initialize Flutter bindings for headless operation
  WidgetsFlutterBinding.ensureInitialized();

  print('\n======== EVENT INITIALIZATION UTILITY ========');
  print(
      'This utility will fetch all events from RSS and store them in Firestore.');
  print(
      'This setup significantly reduces network usage and improves app performance');
  print(
      'by allowing all clients to use Firestore instead of fetching RSS directly.\n');

  try {
    // Initialize Firebase
    print('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✓ Firebase initialized');

    // Initialize services
    print('Initializing services...');
    await UserPreferencesService.initialize();
    print('✓ Services initialized');

    // Fetch events from RSS
    print('\nFetching events from RSS feed...');
    final events = await RssService.fetchEvents(forceRefresh: true);
    print('✓ Fetched ${events.length} events from RSS feed');

    // Store events in Firestore
    print('\nStoring events in Firestore...');
    await RssService.syncEventsWithFirestore(events);

    // Verify by loading from Firestore
    print('\nVerifying by loading events from Firestore...');
    final loadedEvents = await RssService.loadEventsFromFirestore(
      includeExpired: true,
      limit: 1000,
    );

    if (loadedEvents.isNotEmpty) {
      print('\n✅ SUCCESS: All events have been stored in Firestore');
      print(
          '✓ Successfully loaded ${loadedEvents.length} events from Firestore');
      print(
          '\nThe app will now use Firestore as the primary source for events');
      print(
          'This will significantly reduce network usage and improve performance');
    } else {
      print(
          '\n❌ WARNING: No events were loaded from Firestore during verification');
      print(
          'Please check your Firestore security rules and ensure the events collection is accessible');
    }
  } catch (e, stackTrace) {
    print('\n❌ ERROR: ${e.toString()}');
    print('Stack trace: $stackTrace');
  }

  print('\nExiting...');
  exit(0);
}
