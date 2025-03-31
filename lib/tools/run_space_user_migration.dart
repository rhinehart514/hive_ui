import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'dart:async';

/// Tool to migrate existing user-space relationships to the new format
/// This script will:
/// 1. Find all existing relationships in the user_spaces collection
/// 2. Create corresponding documents in users/{userId}/spaces/{spaceId}
/// Run this script once to migrate data to the new structure
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  await migrateUserSpaces();
}

Future<void> migrateUserSpaces() async {
  final firestore = FirebaseFirestore.instance;
  
  debugPrint('Starting user-space relationship migration...');
  int processed = 0;
  int created = 0;
  int errors = 0;
  
  try {
    // Get all active user-space relationships from the existing collection
    final userSpacesQuery = await firestore
        .collection('user_spaces')
        .where('isJoined', isEqualTo: true)
        .get();
        
    final totalToProcess = userSpacesQuery.docs.length;
    debugPrint('Found $totalToProcess user-space relationships to migrate');
    
    if (totalToProcess == 0) {
      debugPrint('No relationships to migrate. Exiting.');
      return;
    }
    
    // Process each relationship
    for (final doc in userSpacesQuery.docs) {
      try {
        processed++;
        final data = doc.data();
        
        // Extract user ID and space ID
        final userId = data['userId'] as String?;
        final spaceId = data['spaceId'] as String?;
        
        if (userId == null || spaceId == null) {
          debugPrint('⚠️ Skipping invalid relationship: ${doc.id}');
          errors++;
          continue;
        }
        
        // Create the new document in users/{userId}/spaces/{spaceId}
        final userSpaceRef = firestore
            .collection('users')
            .doc(userId)
            .collection('spaces')
            .doc(spaceId);
            
        // Check if it already exists
        final existingDoc = await userSpaceRef.get();
        if (existingDoc.exists) {
          debugPrint('✓ Relationship already exists for user $userId, space $spaceId');
          continue;
        }
        
        // Create the relationship in the new structure
        await userSpaceRef.set({
          'joinedAt': data['joinedAt'] ?? FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'isActive': true,
        });
        
        created++;
        
        // Log progress
        if (processed % 10 == 0 || processed == totalToProcess) {
          debugPrint('Progress: $processed/$totalToProcess (${(processed / totalToProcess * 100).toStringAsFixed(1)}%)');
        }
      } catch (e) {
        debugPrint('❌ Error processing relationship ${doc.id}: $e');
        errors++;
      }
    }
    
    debugPrint('\nMigration completed:');
    debugPrint('- Total processed: $processed');
    debugPrint('- New relationships created: $created');
    debugPrint('- Errors: $errors');
    
  } catch (e) {
    debugPrint('❌ Error during migration: $e');
  }
} 