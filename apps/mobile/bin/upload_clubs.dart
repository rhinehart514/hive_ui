// A standalone Dart script to upload clubs to Firestore
// This avoids Flutter dependencies to prevent compatibility issues

import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_ui/firebase_options.dart';
import 'package:hive_ui/services/admin_tools.dart';
import 'package:logging/logging.dart';

void main() async {
  // Setup logging
  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  final log = Logger('ClubUploader');

  log.info('Starting clubs sync process...');

  // Initialize Firebase with defaults for Dart script
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  log.info('Firebase initialized successfully');

  try {
    log.info('Generating clubs from events...');
    await AdminTools.generateClubsFromExistingEvents();
    log.info('✅ Clubs generated from events successfully');

    log.info('Syncing clubs to Firestore...');
    await AdminTools.syncClubsToFirestore();
    log.info('✅ Clubs synced to Firestore successfully');

    log.info('Categorizing clubs into branches...');
    await AdminTools.categorizeClubsInFirestore();
    log.info('✅ Clubs categorized into branches successfully');

    log.info('All operations completed successfully!');
  } catch (e, s) {
    log.severe('❌ Error during club sync process', e, s);
  } finally {
    log.info('Club sync process finished');
    exit(0); // Force exit to prevent hanging
  }
} 