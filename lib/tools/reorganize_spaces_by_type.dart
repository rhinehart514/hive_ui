import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_ui/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ui/models/space_type.dart';

/// A command-line tool to reorganize spaces by their type
///
/// This tool will:
/// 1. Scan all spaces and check if they're in the correct type collection
/// 2. Move spaces to the correct type collection if needed
/// 3. Ensure all events are properly connected with their spaces
///
/// This tool is designed to be run directly with Flutter:
/// flutter run -d <device> lib/tools/reorganize_spaces_by_type.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('==================================================');
  print('  HIVE UI - Reorganize Spaces by Type Tool');
  print('==================================================');
  print('');
  print('This tool will reorganize spaces into their correct type collections.');
  print('It will also ensure all events are properly linked with their spaces.');
  print('');
  print('WARNING: This operation can be resource-intensive.');
  print('');
  print('Press Y and Enter to continue, or any other key to cancel.');
  
  // Use a custom confirmation approach to avoid issues with stdin
  // Wait 1 second to ensure the message is displayed
  await Future.delayed(Duration(seconds: 1));
  
  // Read a single character from stdin
  int? key;
  try {
    stdin.echoMode = false;
    stdin.lineMode = false;
    key = stdin.readByteSync();
    stdin.lineMode = true;
    stdin.echoMode = true;
  } catch (e) {
    print('Error reading input: $e');
    // Default to No if there's an error
    exit(0);
  }
  
  // Check if the key is 'y' or 'Y'
  if (key != 121 && key != 89) {
    print('Operation cancelled.');
    exit(0);
  }
  
  print('Continuing with reorganization...');

  try {
    print('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully.');
    
    print('');
    print('Starting space reorganization...');
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
    final stats = {
      'total_spaces_checked': 0,
      'spaces_moved': 0,
      'events_updated': 0,
      'errors': 0,
    };

    // Check if all type collections exist, create if needed
    await ensureTypeCollectionsExist(spaceTypes);

    // Reorganize all spaces
    for (final spaceType in spaceTypes) {
      await reorganizeSpacesInCollection(spaceType, spaceTypes, stats);
    }

    // Also check spaces in the root collection (legacy)
    await reorganizeRootSpaces(spaceTypes, stats);

    // Check for orphaned events and link them to spaces
    final linkedEventsCount = await linkOrphanedEventsToSpaces();
    stats['events_updated'] = (stats['events_updated'] ?? 0) + linkedEventsCount;

    // Calculate elapsed time
    final elapsedTime = DateTime.now().difference(startTime);
    
    print('');
    print('Space reorganization completed in ${elapsedTime.inSeconds} seconds.');
    print('');
    print('RESULTS:');
    print('----------------------------------------');
    print('Total spaces checked: ${stats['total_spaces_checked']}');
    print('Spaces moved to correct type collection: ${stats['spaces_moved']}');
    print('Events updated: ${stats['events_updated']}');
    print('Errors: ${stats['errors']}');
    print('----------------------------------------');
    
    print('');
    print('Press any key to exit...');

    // Wait for user input before exiting
    await stdin.first;
    exit(0);
  } catch (e, stackTrace) {
    print('');
    print('ERROR: Failed to complete reorganization:');
    print(e);
    print('');
    print('Stack trace:');
    print(stackTrace);
    print('');
    print('Press any key to exit...');

    // Wait for user input before exiting
    await stdin.first;
    exit(1);
  }
}

/// Ensure all type collections exist in Firestore
Future<void> ensureTypeCollectionsExist(List<String> spaceTypes) async {
  try {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();
    
    print('Checking and creating type collections if needed...');
    
    for (final type in spaceTypes) {
      final typeDocRef = firestore.collection('spaces').doc(type);
      final typeDoc = await typeDocRef.get();
      
      if (!typeDoc.exists) {
        print('Creating type collection: $type');
        
        batch.set(typeDocRef, {
          'name': type
              .replaceAll('_', ' ')
              .split(' ')
              .map((word) =>
                  word.substring(0, 1).toUpperCase() + word.substring(1))
              .join(' '),
          'description': 'Collection for ${type.replaceAll('_', ' ')} spaces',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'isTypeCollection': true,
          'type': type,
        });
      } else {
        // Ensure type document has correct structure
        final data = typeDoc.data() ?? {};
        if (!data.containsKey('isTypeCollection') || !data['isTypeCollection']) {
          print('Updating type collection document: $type');
          
          batch.update(typeDocRef, {
            'isTypeCollection': true,
            'type': type,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    }
    
    // Commit the batch
    await batch.commit();
    print('Type collections checked and created if needed.');
  } catch (e) {
    print('Error ensuring type collections exist: $e');
  }
}

/// Reorganize spaces within a specific collection
Future<void> reorganizeSpacesInCollection(
    String currentType, List<String> allTypes, Map<String, int> stats) async {
  try {
    final firestore = FirebaseFirestore.instance;
    
    print('Checking spaces in $currentType collection...');
    
    // Query for spaces in this type collection
    final spacesQuery = firestore
        .collection('spaces')
        .doc(currentType)
        .collection('spaces');
    
    final spacesSnapshot = await spacesQuery.get();
    
    print('Found ${spacesSnapshot.docs.length} spaces in $currentType collection');
    stats['total_spaces_checked'] = (stats['total_spaces_checked'] ?? 0) + spacesSnapshot.docs.length;
    
    // Check each space
    for (final spaceDoc in spacesSnapshot.docs) {
      try {
        final spaceId = spaceDoc.id;
        final spaceData = spaceDoc.data();
        
        // Skip non-space documents and type collections
        if (spaceData['isTypeCollection'] == true) {
          continue;
        }
        
        // Determine the correct type for this space
        final spaceTypeStr = spaceData['spaceType'] as String? ?? 'other';
        final correctType = getCorrectTypeCollection(spaceTypeStr);
        
        // If space is already in the correct type collection, skip
        if (correctType == currentType) {
          continue;
        }
        
        print('Space $spaceId should be in $correctType but is in $currentType');
        
        // Move the space to the correct type collection
        await moveSpaceToCorrectType(
          spaceDoc.reference,
          spaceData,
          correctType,
          firestore,
          stats
        );
      } catch (e) {
        print('Error processing space ${spaceDoc.id}: $e');
        stats['errors'] = (stats['errors'] ?? 0) + 1;
      }
    }
  } catch (e) {
    print('Error reorganizing $currentType collection: $e');
    stats['errors'] = (stats['errors'] ?? 0) + 1;
  }
}

/// Reorganize spaces in the root collection
Future<void> reorganizeRootSpaces(List<String> allTypes, Map<String, int> stats) async {
  try {
    final firestore = FirebaseFirestore.instance;
    
    print('Checking spaces in root collection...');
    
    // Query for spaces in the root collection
    final rootSpacesQuery = firestore.collection('spaces');
    final rootSpacesSnapshot = await rootSpacesQuery.get();
    
    // Filter out the type documents
    final rootSpaces = rootSpacesSnapshot.docs.where((doc) => 
      !allTypes.contains(doc.id) && doc.id != 'spaces' && !doc.id.startsWith('type_')
    ).toList();
    
    print('Found ${rootSpaces.length} spaces in root collection');
    stats['total_spaces_checked'] = (stats['total_spaces_checked'] ?? 0) + rootSpaces.length;
    
    // Check each space
    for (final spaceDoc in rootSpaces) {
      try {
        final spaceId = spaceDoc.id;
        final spaceData = spaceDoc.data();
        
        // Skip non-space documents
        if (spaceData.isEmpty) {
          continue;
        }
        
        // Determine the correct type for this space
        final spaceTypeStr = spaceData['spaceType'] as String? ?? 'other';
        final correctType = getCorrectTypeCollection(spaceTypeStr);
        
        print('Root space $spaceId should be in $correctType collection');
        
        // Move the space to the correct type collection
        await moveSpaceToCorrectType(
          spaceDoc.reference,
          spaceData,
          correctType,
          firestore,
          stats
        );
      } catch (e) {
        print('Error processing root space ${spaceDoc.id}: $e');
        stats['errors'] = (stats['errors'] ?? 0) + 1;
      }
    }
  } catch (e) {
    print('Error reorganizing root spaces: $e');
    stats['errors'] = (stats['errors'] ?? 0) + 1;
  }
}

/// Move a space to its correct type collection
Future<void> moveSpaceToCorrectType(
    DocumentReference sourceRef,
    Map<String, dynamic> spaceData,
    String targetType,
    FirebaseFirestore firestore,
    Map<String, int> stats) async {
  try {
    final spaceId = sourceRef.id;
    
    // Reference to the target location
    final targetRef = firestore
        .collection('spaces')
        .doc(targetType)
        .collection('spaces')
        .doc(spaceId);
    
    // Check if the space already exists in the target collection
    final targetDoc = await targetRef.get();
    if (targetDoc.exists) {
      print('Space $spaceId already exists in target collection $targetType, merging...');
      
      // Update with the most recent data
      await targetRef.update({
        ...spaceData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Delete the source document
      await sourceRef.delete();
      stats['spaces_moved'] = (stats['spaces_moved'] ?? 0) + 1;
      return;
    }
    
    // Get the space's events
    final eventsRef = sourceRef.collection('events');
    final eventsSnapshot = await eventsRef.get();
    print('Space $spaceId has ${eventsSnapshot.docs.length} events to move');
    
    // Create a batch for space document
    final spaceBatch = firestore.batch();
    
    // Set the space document at the target location
    spaceBatch.set(targetRef, {
      ...spaceData,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    // Delete the source document
    spaceBatch.delete(sourceRef);
    
    // Commit the space batch
    await spaceBatch.commit();
    
    // Move events in batches of 500 (Firestore batch limit)
    int eventsMoved = 0;
    for (int i = 0; i < eventsSnapshot.docs.length; i += 500) {
      final batchDocs = eventsSnapshot.docs.skip(i).take(500).toList();
      final eventsBatch = firestore.batch();
      
      for (final eventDoc in batchDocs) {
        final eventId = eventDoc.id;
        final eventData = eventDoc.data();
        
        // Create the event in the target space
        final targetEventRef = targetRef.collection('events').doc(eventId);
        eventsBatch.set(targetEventRef, eventData);
        
        // Delete the event from the source space
        eventsBatch.delete(eventDoc.reference);
        
        eventsMoved++;
      }
      
      // Commit the events batch
      await eventsBatch.commit();
      print('Moved batch of ${batchDocs.length} events (total: $eventsMoved)');
    }
    
    stats['spaces_moved'] = (stats['spaces_moved'] ?? 0) + 1;
    stats['events_updated'] = (stats['events_updated'] ?? 0) + eventsMoved;
    
    print('Successfully moved space $spaceId to $targetType collection with $eventsMoved events');
  } catch (e) {
    print('Error moving space to correct type: $e');
    stats['errors'] = (stats['errors'] ?? 0) + 1;
  }
}

/// Find and link orphaned events to appropriate spaces
Future<int> linkOrphanedEventsToSpaces() async {
  try {
    final firestore = FirebaseFirestore.instance;
    int linkedCount = 0;
    
    print('Checking for orphaned events in main collection...');
    
    // Query for events in the main collection
    final eventsQuery = firestore.collection('events').limit(500);
    bool hasMoreEvents = true;
    
    while (hasMoreEvents) {
      final eventsSnapshot = await eventsQuery.get();
      final batchSize = eventsSnapshot.docs.length;
      
      if (batchSize == 0) {
        hasMoreEvents = false;
        continue;
      }
      
      print('Processing batch of $batchSize events...');
      
      // Process each event
      for (final eventDoc in eventsSnapshot.docs) {
        try {
          final eventId = eventDoc.id;
          final eventData = eventDoc.data();
          
          // Skip events without organizer name
          if (!eventData.containsKey('organizerName') || 
              eventData['organizerName'] == null || 
              (eventData['organizerName'] as String).isEmpty) {
            continue;
          }
          
          final organizerName = eventData['organizerName'] as String;
          final spaceId = generateSpaceId(organizerName);
          
          // Determine the space type from the event
          final spaceTypeStr = eventData['spaceType'] as String? ?? 
                               eventData['category'] as String? ?? 'other';
          final spaceType = getCorrectTypeCollection(spaceTypeStr);
          
          // Find the space in the correct collection
          final spaceRef = firestore
              .collection('spaces')
              .doc(spaceType)
              .collection('spaces')
              .doc(spaceId);
          
          final spaceDoc = await spaceRef.get();
          
          if (spaceDoc.exists) {
            // Space exists, link the event
            final eventInSpaceRef = spaceRef.collection('events').doc(eventId);
            final eventInSpaceDoc = await eventInSpaceRef.get();
            
            if (!eventInSpaceDoc.exists) {
              // Event doesn't exist in space, create it
              await eventInSpaceRef.set(eventData);
              linkedCount++;
              
              // Update the space's eventIds array
              await spaceRef.update({
                'eventIds': FieldValue.arrayUnion([eventId]),
                'updatedAt': FieldValue.serverTimestamp(),
              });
              
              print('Linked event $eventId to space $spaceId');
            }
          } else {
            // Space doesn't exist, create it
            await createSpaceFromEvent(
              eventData, 
              spaceId, 
              spaceType, 
              firestore
            );
            
            // Create the event in the space
            final eventInSpaceRef = spaceRef.collection('events').doc(eventId);
            await eventInSpaceRef.set(eventData);
            linkedCount++;
            
            print('Created space $spaceId and linked event $eventId');
          }
        } catch (e) {
          print('Error processing event ${eventDoc.id}: $e');
        }
      }
      
      print('Linked $linkedCount events so far');
      
      // Use the last document as starting point for next query
      final lastDoc = eventsSnapshot.docs.last;
      eventsQuery.startAfterDocument(lastDoc);
      
      // If we got less than the limit, we've processed all events
      if (batchSize < 500) {
        hasMoreEvents = false;
      }
    }
    
    print('Linked $linkedCount events to spaces');
    return linkedCount;
  } catch (e) {
    print('Error linking orphaned events: $e');
    return 0;
  }
}

/// Create a new space from event data
Future<void> createSpaceFromEvent(
    Map<String, dynamic> eventData,
    String spaceId,
    String spaceType,
    FirebaseFirestore firestore) async {
  try {
    final organizerName = eventData['organizerName'] as String;
    
    // Reference to the new space
    final spaceRef = firestore
        .collection('spaces')
        .doc(spaceType)
        .collection('spaces')
        .doc(spaceId);
    
    // Create a complete space document
    await spaceRef.set({
      'id': spaceId,
      'name': organizerName,
      'description': 'Auto-created from event synchronization',
      'spaceType': eventData['spaceType'] as String? ?? 
                  mapCategoryToSpaceType(eventData['category'] as String? ?? 'other'),
      'iconCodePoint': 0xe570, // Default icon (group)
      'metrics': {
        'memberCount': 0,
        'activeMembers': 0,
        'weeklyEvents': 1,
        'monthlyEngagements': 0,
        'engagementScore': 0,
      },
      'tags': eventData['tags'] as List<dynamic>? ?? [],
      'isPrivate': false,
      'moderators': [],
      'admins': [],
      'eventIds': [eventData['id']],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'source': 'auto_created_from_event',
    });
    
    print('Created new space: $spaceId in $spaceType collection');
  } catch (e) {
    print('Error creating space from event: $e');
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

/// Map category to space type
String mapCategoryToSpaceType(String category) {
  switch (category.toLowerCase()) {
    case 'student organization':
    case 'student organizations':
    case 'student club':
    case 'student clubs':
    case 'club':
    case 'clubs':
      return 'studentOrg';
    
    case 'university':
    case 'university organization':
    case 'department':
    case 'academic':
    case 'faculty':
      return 'universityOrg';
    
    case 'housing':
    case 'dorm':
    case 'residence':
    case 'campus living':
    case 'residential':
      return 'campusLiving';
    
    case 'fraternity':
    case 'sorority':
    case 'greek life':
    case 'fraternity and sorority':
    case 'greek':
      return 'fraternityAndSorority';
    
    default:
      return 'other';
  }
}

/// Generate a space ID from organizer name
String generateSpaceId(String organizerName) {
  final normalized = organizerName
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w\s]'), '')
      .trim()
      .replaceAll(RegExp(r'\s+'), '_');

  return 'space_$normalized';
} 