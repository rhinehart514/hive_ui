import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_ui/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A command-line tool to check the distribution of spaces across type collections
///
/// This tool will:
/// 1. Count the number of spaces in each type collection
/// 2. Analyze space types and distribution
/// 3. Report on any inconsistencies or spaces in wrong collections
///
/// This tool is designed to be run directly with Flutter:
/// flutter run -d <device> lib/tools/check_spaces_distribution.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('==================================================');
  print('  HIVE UI - Check Spaces Distribution Tool');
  print('==================================================');
  print('');
  print('This tool will analyze the distribution of spaces across collections.');
  print('');

  try {
    print('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully.');
    
    print('');
    print('Starting spaces distribution analysis...');
    print('');

    // Record start time for performance measurement
    final startTime = DateTime.now();

    // Define all space type collections
    final spaceTypes = [
      'student_organizations',
      'university_organizations',
      'campus_living',
      'fraternity_and_sorority',
      'other'
    ];

    // Stats for reporting
    final Map<String, dynamic> stats = {
      'total_spaces': 0,
      'spaces_by_type': <String, int>{},
      'spaces_in_root': 0,
      'inconsistent_spaces': 0,
      'spaces_with_events': 0,
      'total_events': 0,
    };

    // Check the root collection first (legacy)
    await checkRootSpaces(stats);

    // Check all type collections
    for (final spaceType in spaceTypes) {
      await checkSpacesInCollection(spaceType, stats);
    }

    // Calculate elapsed time
    final elapsedTime = DateTime.now().difference(startTime);
    
    print('');
    print('Space distribution analysis completed in ${elapsedTime.inSeconds} seconds.');
    print('');
    print('RESULTS:');
    print('----------------------------------------');
    print('Total spaces found: ${stats['total_spaces']}');
    print('');
    print('Distribution by type:');
    for (final type in spaceTypes) {
      final count = stats['spaces_by_type']?[type] ?? 0;
      final percentage = stats['total_spaces'] == 0 
          ? 0 
          : (count / (stats['total_spaces'] as int) * 100).toStringAsFixed(1);
      print('  - $type: $count spaces ($percentage%)');
    }
    print('');
    print('Spaces in root collection (legacy): ${stats['spaces_in_root']}');
    print('Spaces with incorrectly set type: ${stats['inconsistent_spaces']}');
    print('Spaces with events: ${stats['spaces_with_events']}');
    print('Total events across all spaces: ${stats['total_events']}');
    print('----------------------------------------');
    
    // Provide recommendations
    print('');
    print('RECOMMENDATIONS:');
    if ((stats['spaces_in_root'] as int) > 0) {
      print('• There are ${stats['spaces_in_root']} spaces in the root collection.');
      print('  Run the reorganize_spaces_by_type tool to move them to the right collections.');
    }
    if ((stats['inconsistent_spaces'] as int) > 0) {
      print('• Found ${stats['inconsistent_spaces']} spaces with type inconsistencies.');
      print('  Run the reorganize_spaces_by_type tool to correct their placement.');
    }
    if ((stats['total_spaces'] as int) > 0) {
      final spacesByType = stats['spaces_by_type'] as Map<String, int>;
      print('• Space type distribution summary:');
      print('  - ${spacesByType['student_organizations'] ?? 0} student organizations');
      print('  - ${spacesByType['university_organizations'] ?? 0} university organizations');
      print('  - ${spacesByType['campus_living'] ?? 0} campus living spaces');
      print('  - ${spacesByType['fraternity_and_sorority'] ?? 0} fraternities/sororities');
      print('  - ${spacesByType['other'] ?? 0} other spaces');
    }
    
    print('');
    print('Press any key to exit...');

    // Wait for user input before exiting
    stdin.readByteSync();
    exit(0);
  } catch (e, stackTrace) {
    print('');
    print('ERROR: Failed to complete analysis:');
    print(e);
    print('');
    print('Stack trace:');
    print(stackTrace);
    print('');
    print('Press any key to exit...');

    // Wait for user input before exiting
    stdin.readByteSync();
    exit(1);
  }
}

/// Check spaces in the root collection
Future<void> checkRootSpaces(Map<String, dynamic> stats) async {
  try {
    final firestore = FirebaseFirestore.instance;
    
    print('Checking spaces in root collection...');
    
    // Get all type collection IDs to filter them out
    final spaceTypes = [
      'student_organizations',
      'university_organizations',
      'campus_living',
      'fraternity_and_sorority',
      'other'
    ];
    
    // Query for spaces in the root collection
    final rootSpacesQuery = firestore.collection('spaces');
    final rootSpacesSnapshot = await rootSpacesQuery.get();
    
    // Filter out the type documents
    final rootSpaces = rootSpacesSnapshot.docs.where((doc) => 
      !spaceTypes.contains(doc.id) && doc.id != 'spaces' && !doc.id.startsWith('type_')
    ).toList();
    
    stats['spaces_in_root'] = rootSpaces.length;
    stats['total_spaces'] = (stats['total_spaces'] as int) + rootSpaces.length;
    
    // Check each space
    for (final spaceDoc in rootSpaces) {
      try {
        final spaceData = spaceDoc.data();
        
        // Skip empty documents
        if (spaceData.isEmpty) {
          continue;
        }
        
        // Check for spaceType field
        final spaceTypeStr = spaceData['spaceType'] as String? ?? 'other';
        final correctType = getCorrectTypeCollection(spaceTypeStr);
        
        // Count events
        final eventsRef = spaceDoc.reference.collection('events');
        final eventsCount = await eventsRef.count().get();
        final count = eventsCount.count ?? 0;
        
        // Update stats
        if (count > 0) {
          stats['spaces_with_events'] = (stats['spaces_with_events'] as int) + 1;
          stats['total_events'] = (stats['total_events'] as int) + count;
        }
        
        // Increment the count for the correct type
        stats['spaces_by_type'] ??= <String, int>{};
        final typeMap = stats['spaces_by_type'] as Map<String, int>;
        typeMap[correctType] = (typeMap[correctType] ?? 0) + 1;
        
      } catch (e) {
        print('Error analyzing root space ${spaceDoc.id}: $e');
      }
    }
    
    print('Found ${rootSpaces.length} spaces in root collection');
  } catch (e) {
    print('Error checking root spaces: $e');
  }
}

/// Check spaces in a specific type collection
Future<void> checkSpacesInCollection(String spaceType, Map<String, dynamic> stats) async {
  try {
    final firestore = FirebaseFirestore.instance;
    
    print('Checking spaces in $spaceType collection...');
    
    // Query for spaces in this type collection
    final spacesQuery = firestore
        .collection('spaces')
        .doc(spaceType)
        .collection('spaces');
    
    final spacesSnapshot = await spacesQuery.get();
    
    // Update stats
    stats['spaces_by_type'] ??= <String, int>{};
    final typeMap = stats['spaces_by_type'] as Map<String, int>;
    typeMap[spaceType] = (typeMap[spaceType] ?? 0) + spacesSnapshot.docs.length;
    stats['total_spaces'] = (stats['total_spaces'] as int) + spacesSnapshot.docs.length;
    
    // Check each space
    for (final spaceDoc in spacesSnapshot.docs) {
      try {
        final spaceData = spaceDoc.data();
        
        // Check for spaceType field
        if (spaceData.containsKey('spaceType')) {
          final declaredType = spaceData['spaceType'] as String? ?? 'other';
          final correctType = getCorrectTypeCollection(declaredType);
          
          // Check if space is in the wrong collection
          if (correctType != spaceType) {
            stats['inconsistent_spaces'] = (stats['inconsistent_spaces'] as int) + 1;
            print('Space ${spaceDoc.id} has type $declaredType but is in $spaceType collection');
          }
        }
        
        // Count events
        final eventsRef = spaceDoc.reference.collection('events');
        final eventsCount = await eventsRef.count().get();
        final count = eventsCount.count ?? 0;
        
        if (count > 0) {
          stats['spaces_with_events'] = (stats['spaces_with_events'] as int) + 1;
          stats['total_events'] = (stats['total_events'] as int) + count;
        }
      } catch (e) {
        print('Error analyzing space ${spaceDoc.id} in $spaceType: $e');
      }
    }
    
    print('Found ${spacesSnapshot.docs.length} spaces in $spaceType collection');
  } catch (e) {
    print('Error checking spaces in $spaceType: $e');
  }
}

/// Get the correct type collection for a space type string
String getCorrectTypeCollection(String spaceType) {
  if (spaceType == 'studentOrg') {
    return 'student_organizations';
  } else if (spaceType == 'universityOrg') {
    return 'university_organizations';
  } else if (spaceType == 'campusLiving') {
    return 'campus_living';
  } else if (spaceType == 'fraternityAndSorority') {
    return 'fraternity_and_sorority';
  } else if (spaceType == 'student organization' || spaceType == 'club' || spaceType == 'clubs') {
    return 'student_organizations';
  } else if (spaceType == 'university' || spaceType == 'department') {
    return 'university_organizations';
  } else if (spaceType == 'dorm' || spaceType == 'housing' || spaceType == 'residence') {
    return 'campus_living';
  } else if (spaceType == 'fraternity' || spaceType == 'sorority' || spaceType == 'greek') {
    return 'fraternity_and_sorority';
  } else {
    return 'other';
  }
} 