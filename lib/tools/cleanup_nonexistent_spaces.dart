import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_ui/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A utility script to clean up non-existent documents in space subcollections.
///
/// This script will:
/// 1. Check each type subcollection for documents that show in the listing but don't actually exist
/// 2. Remove references to these non-existent documents
///
/// Run with: flutter run -d windows lib/tools/cleanup_nonexistent_spaces.dart

// Constants
const String _logPrefix = '[CLEANUP]';
const int _maxBatchSize = 400;
const Duration _startupDelay = Duration(seconds: 3);
const Duration _exitDelay = Duration(seconds: 3);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _printHeader();

  print('Starting in 3 seconds...');
  await Future.delayed(_startupDelay);

  try {
    print('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully.');

    print('');
    print('Starting cleanup of non-existent documents...');
    print('');

    await cleanupNonexistentDocuments();

    print('');
    print('Operation completed successfully.');
    print('');
    print('Exiting in 3 seconds...');
    await Future.delayed(_exitDelay);
    exit(0);
  } catch (e, stackTrace) {
    _printError('Failed to complete operation', e, stackTrace);
    await Future.delayed(_exitDelay);
    exit(1);
  }
}

/// Print the script header
void _printHeader() {
  print('==================================================');
  print('  HIVE UI - Clean Up Non-existent Space Documents');
  print('==================================================');
  print('');
  print('This utility will remove references to non-existent documents');
  print('in the spaces subcollections.');
  print('');
}

/// Print a formatted error message with stack trace
void _printError(String message, Object error, StackTrace stackTrace) {
  print('');
  print('ERROR: $message:');
  print(error);
  print('');
  print('Stack trace:');
  print(stackTrace);
  print('');
  print('Exiting in 3 seconds...');
}

/// Get the list of space type paths
List<String> _getTypePaths() {
  return [
    'student_organizations',
    'university_organizations',
    'campus_living',
    'fraternity_and_sorority',
    'other',
  ];
}

/// Cleanup non-existent documents in type subcollections
Future<void> cleanupNonexistentDocuments() async {
  final firestore = FirebaseFirestore.instance;

  // Type paths
  final List<String> typePaths = _getTypePaths();

  int totalNonexistent = 0;
  int totalRemoved = 0;

  // Check each type collection
  for (final typePath in typePaths) {
    final stats = await _cleanupTypeCollection(firestore, typePath);
    totalNonexistent += stats.nonexistentCount;
    totalRemoved += stats.removedCount;
  }

  // Check for documents directly under spaces collection that might need cleanup
  final rootCleanupStats =
      await _cleanupRootSpacesCollection(firestore, typePaths);
  totalRemoved += rootCleanupStats.removedCount;

  // Final summary
  _printSummary(totalNonexistent, totalRemoved);
}

/// Print a summary of results
void _printSummary(int totalNonexistent, int totalRemoved) {
  print('');
  print('Cleanup summary:');
  print('- Total non-existent documents found: $totalNonexistent');
  print('- Total documents removed: $totalRemoved');
}

/// Represents the results of a cleanup operation
class CleanupStats {
  final int nonexistentCount;
  final int removedCount;

  CleanupStats({this.nonexistentCount = 0, this.removedCount = 0});
}

/// Cleanup documents in a specific type collection
Future<CleanupStats> _cleanupTypeCollection(
    FirebaseFirestore firestore, String typePath) async {
  print('Checking spaces/$typePath/spaces collection...');

  int nonexistentCount = 0;
  int removedCount = 0;

  try {
    // Get all documents in the type subcollection
    final QuerySnapshot spaceQuery = await firestore
        .collection('spaces')
        .doc(typePath)
        .collection('spaces')
        .get();

    print(
        'Found ${spaceQuery.docs.length} documents in spaces/$typePath/spaces');

    // Check for non-existent documents
    final batchResult = await _processBatchDeletion(firestore, spaceQuery.docs,
        (doc) async {
      // Get a fresh snapshot to check if it exists
      final snapshot = await doc.reference.get();

      // If the document doesn't exist or doesn't have expected fields
      return !snapshot.exists ||
          (snapshot.data() is Map && (snapshot.data() as Map).isEmpty);
    },
        (doc) =>
            'Non-existent document: ${doc.id} in spaces/$typePath/spaces');

    nonexistentCount = batchResult.nonexistentCount;
    removedCount = batchResult.removedCount;

    print(
        'Found $nonexistentCount non-existent documents in spaces/$typePath/spaces');
  } catch (e) {
    print('Error checking spaces/$typePath/spaces: $e');
  }

  return CleanupStats(
      nonexistentCount: nonexistentCount, removedCount: removedCount);
}

/// Cleanup documents in the root spaces collection
Future<CleanupStats> _cleanupRootSpacesCollection(
    FirebaseFirestore firestore, List<String> validRootDocs) async {
  print('Checking for remaining documents in root spaces collection...');

  int removedCount = 0;

  try {
    final spacesQuery = await firestore.collection('spaces').get();

    // Check for documents to delete
    final batchResult =
        await _processBatchDeletion(firestore, spacesQuery.docs, (doc) async {
      // If not a type document or doesn't start with space_
      return !validRootDocs.contains(doc.id) && doc.id.startsWith('space_');
    }, (doc) => 'Remaining space document: ${doc.id} - will be removed');

    removedCount = batchResult.removedCount;

    print(
        'Removed $removedCount remaining space documents from root collection');
  } catch (e) {
    print('Error checking root spaces collection: $e');
  }

  return CleanupStats(removedCount: removedCount);
}

/// Process a batch of documents for deletion
/// Takes a list of documents, a check function to determine if a document should be deleted,
/// and a message function to display info about the document being deleted
Future<CleanupStats> _processBatchDeletion(
    FirebaseFirestore firestore,
    List<QueryDocumentSnapshot> docs,
    Future<bool> Function(QueryDocumentSnapshot) shouldDeleteCheck,
    String Function(QueryDocumentSnapshot) deleteMessage) async {
  int nonexistentCount = 0;
  int removedCount = 0;
  var batch = firestore.batch();
  int batchCount = 0;

  for (final doc in docs) {
    try {
      final shouldDelete = await shouldDeleteCheck(doc);

      if (shouldDelete) {
        print(deleteMessage(doc));

        // Add to deletion batch
        batch.delete(doc.reference);
        nonexistentCount++;
        batchCount++;

        // Commit batch every max batch size
        if (batchCount >= _maxBatchSize) {
          print('Committing batch of $batchCount deletes...');
          await batch.commit();
          removedCount += batchCount;
          batch = firestore.batch();
          batchCount = 0;
        }
      }
    } catch (e) {
      print('Error checking document ${doc.id}: $e');
    }
  }

  // Commit any remaining operations
  if (batchCount > 0) {
    print('Committing final batch of $batchCount deletes...');
    await batch.commit();
    removedCount += batchCount;
  }

  return CleanupStats(
      nonexistentCount: nonexistentCount, removedCount: removedCount);
}
