// Batch club initialization CLI script with branch organization
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_ui/firebase_options.dart';
import 'package:hive_ui/services/club_service.dart';
import 'package:hive_ui/services/rss_service.dart';
import 'package:hive_ui/services/user_preferences_service.dart';
import 'dart:io';

void main() async {
  // Initialize Flutter bindings for headless operation
  WidgetsFlutterBinding.ensureInitialized();

  print('\n======== CLUB BATCH INITIALIZATION UTILITY ========');
  print(
      'This utility will fetch all events from RSS, generate clubs, and store them in Firestore,');
  print(
      'organizing them into proper branch subcollections (campus living, greek life, etc.).');
  print(
      'This initial setup significantly reduces Firestore reads during normal app operation.\n');

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
    await ClubService.initialize();
    print('✓ Services initialized');

    // Fetch events from RSS
    print('\nFetching events from RSS feed...');
    final events = await RssService.fetchEvents(forceRefresh: true);
    print('✓ Fetched ${events.length} events from RSS feed');

    // Generate clubs from events
    print('\nGenerating clubs from events...');
    final clubs = await ClubService.generateClubsFromEvents(events);
    print('✓ Generated ${clubs.length} clubs from events');

    // Store clubs in Firestore with branch organization
    print('\nStoring clubs in Firestore with branch organization...');
    final success = await ClubService.syncAllClubsToFirestore();

    if (success) {
      print('\n✅ SUCCESS: All clubs have been stored in Firestore');
      print('Clubs are now organized into these branches:');
      print('  - campus_living');
      print('  - fraternity_sorority_life');
      print('  - student_organizations');
      print('  - university_departments');
      print('\nThe app will now use Firestore as the primary source for clubs');
      print(
          'This will significantly reduce Firestore reads during normal operation');

      // Verify by loading from Firestore
      print('\nVerifying by loading clubs from Firestore...');
      final loadedClubs = await ClubService.loadClubsFromFirestore();
      print('✓ Successfully loaded ${loadedClubs.length} clubs from Firestore');
    } else {
      print('\n❌ ERROR: Failed to store clubs in Firestore');
      print('Please check your connection and Firebase configuration');
    }
  } catch (e, stackTrace) {
    print('\n❌ ERROR: ${e.toString()}');
    print('Stack trace: $stackTrace');
  }

  print('\nExiting...');
  exit(0);
}
