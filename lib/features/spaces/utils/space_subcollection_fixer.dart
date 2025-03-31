import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive_ui/features/spaces/utils/space_helper.dart';

/// Utility class to handle subcollection structures like spaces/type/spaces/spaceId/events/eventId
class SpaceSubcollectionFixer {
  /// Fix spaces with subcollection events
  static Future<void> fixSpaceEventSubcollections() async {
    final firestore = FirebaseFirestore.instance;

    debugPrint('\n=== CHECKING FOR SPACE EVENT SUBCOLLECTIONS ===\n');

    // Get all space types
    final typeCollections = [
      'student_organizations',
      'university_organizations',
      'campus_living',
      'fraternity_and_sorority',
      'other'
    ];

    int totalSpacesProcessed = 0;
    int totalEventsFound = 0;
    int totalEventsFixed = 0;

    // Process each type collection
    for (final type in typeCollections) {
      debugPrint('--- Processing spaces in $type ---');

      try {
        // Get spaces in this type
        final spacesSnapshot = await firestore
            .collection('spaces')
            .doc(type)
            .collection('spaces')
            .get();

        debugPrint(
            'Found ${spacesSnapshot.docs.length} spaces in spaces/$type/spaces');
        totalSpacesProcessed += spacesSnapshot.docs.length;

        // Process each space
        for (final spaceDoc in spacesSnapshot.docs) {
          final spaceId = spaceDoc.id;
          final spaceData = spaceDoc.data();

          debugPrint('Checking space: $spaceId');

          // Get events subcollection for this space
          try {
            final eventsSnapshot =
                await spaceDoc.reference.collection('events').get();

            if (eventsSnapshot.docs.isNotEmpty) {
              debugPrint(
                  '  ✓ Found ${eventsSnapshot.docs.length} events in subcollection');
              totalEventsFound += eventsSnapshot.docs.length;

              // Update the space's eventIds field if needed
              final List<String> existingEventIds =
                  spaceData['eventIds'] is List
                      ? List<String>.from(spaceData['eventIds'])
                      : [];

              final Set<String> updatedEventIds =
                  Set<String>.from(existingEventIds);
              final List<String> newEventIds = [];

              // Process each event in the subcollection
              for (final eventDoc in eventsSnapshot.docs) {
                final eventId = eventDoc.id;
                final eventData = eventDoc.data();

                // Add to event IDs if not already present
                if (!updatedEventIds.contains(eventId)) {
                  updatedEventIds.add(eventId);
                  newEventIds.add(eventId);
                }

                // Ensure the event has proper references back to this space
                bool needsUpdate = false;

                if (!eventData.containsKey('spaceId') ||
                    eventData['spaceId'] != spaceId) {
                  eventData['spaceId'] = spaceId;
                  needsUpdate = true;
                }

                final spaceRef = 'spaces/$type/spaces/$spaceId';
                if (!eventData.containsKey('spaceRef') ||
                    eventData['spaceRef'] != spaceRef) {
                  eventData['spaceRef'] = spaceRef;
                  needsUpdate = true;
                }

                // Update the event if needed
                if (needsUpdate) {
                  try {
                    await eventDoc.reference
                        .update({'spaceId': spaceId, 'spaceRef': spaceRef});
                    totalEventsFixed++;
                  } catch (e) {
                    debugPrint('    ✗ Error updating event: $e');
                  }
                }

                // Also ensure this event exists in the main events collection
                await _ensureEventInMainCollection(
                    eventId, eventData, spaceId, spaceRef);
              }

              // Update the space with the new event IDs if we found new ones
              if (newEventIds.isNotEmpty) {
                debugPrint(
                    '  ✓ Adding ${newEventIds.length} new event IDs to space');
                try {
                  await spaceDoc.reference.update({
                    'eventIds': updatedEventIds.toList(),
                    'updatedAt': FieldValue.serverTimestamp()
                  });
                } catch (e) {
                  debugPrint('  ✗ Error updating space eventIds: $e');
                }
              }
            } else {
              debugPrint('  - No events found in subcollection');
            }
          } catch (e) {
            debugPrint('  ✗ Error accessing events subcollection: $e');
          }
        }
      } catch (e) {
        debugPrint('✗ Error processing spaces in $type: $e');
      }
    }

    debugPrint('\n=== SUMMARY ===');
    debugPrint('Total spaces processed: $totalSpacesProcessed');
    debugPrint('Total events found in subcollections: $totalEventsFound');
    debugPrint('Total events fixed: $totalEventsFixed');
    debugPrint('=== FINISHED CHECKING SPACE EVENT SUBCOLLECTIONS ===\n');
  }

  /// Ensure the event exists in the main collection and sync it properly with the space
  static Future<void> _ensureEventInMainCollection(String eventId,
      Map<String, dynamic> eventData, String spaceId, String spaceRef) async {
    final firestore = FirebaseFirestore.instance;
    final mainEventRef = firestore.collection('events').doc(eventId);

    try {
      final mainEventDoc = await mainEventRef.get();

      if (mainEventDoc.exists) {
        // Event exists, check if it has proper references
        final mainEventData = mainEventDoc.data();

        if (mainEventData != null) {
          bool needsUpdate = false;
          final Map<String, dynamic> updates = {};

          if (mainEventData['spaceId'] != spaceId) {
            updates['spaceId'] = spaceId;
            needsUpdate = true;
          }

          if (mainEventData['spaceRef'] != spaceRef) {
            updates['spaceRef'] = spaceRef;
            needsUpdate = true;
          }

          // Ensure spaces array has this space
          if (mainEventData.containsKey('spaces')) {
            final spaces = mainEventData['spaces'] as List?;
            if (spaces != null) {
              final spacesList = spaces.map((e) => e.toString()).toList();
              if (!spacesList.contains(spaceId)) {
                spacesList.add(spaceId);
                updates['spaces'] = spacesList;
                needsUpdate = true;
              }
            } else {
              updates['spaces'] = [spaceId];
              needsUpdate = true;
            }
          } else {
            updates['spaces'] = [spaceId];
            needsUpdate = true;
          }

          // Update if needed
          if (needsUpdate) {
            await mainEventRef.update(updates);
          }
        }
      } else {
        // Event doesn't exist in main collection, create it
        final dataToSave = Map<String, dynamic>.from(eventData);

        // Ensure proper space references
        dataToSave['spaceId'] = spaceId;
        dataToSave['spaceRef'] = spaceRef;
        dataToSave['spaces'] = [spaceId];

        // Ensure ID field
        dataToSave['id'] = eventId;

        // Save to main events collection
        await mainEventRef.set(dataToSave);
      }
    } catch (e) {
      debugPrint('Error ensuring event in main collection: $e');
    }
  }

  /// Also check for events in the main collection that should be in subcollections
  static Future<void> syncEventsToSubcollections() async {
    final firestore = FirebaseFirestore.instance;

    debugPrint('\n=== SYNCING EVENTS TO SPACE SUBCOLLECTIONS ===\n');

    int totalEventsSynced = 0;
    final mainEventsProcessed = <String>{};

    // Process events in batches
    final eventsQuery = firestore.collection('events').limit(500);
    bool hasMoreEvents = true;
    DocumentSnapshot? lastDoc;

    while (hasMoreEvents) {
      // Get batch of events
      QuerySnapshot eventsSnapshot;
      try {
        if (lastDoc != null) {
          eventsSnapshot = await eventsQuery.startAfterDocument(lastDoc).get();
        } else {
          eventsSnapshot = await eventsQuery.get();
        }

        if (eventsSnapshot.docs.isEmpty) {
          hasMoreEvents = false;
          break;
        }

        lastDoc = eventsSnapshot.docs.last;

        debugPrint(
            'Processing batch of ${eventsSnapshot.docs.length} events from main collection');
        int batchSynced = 0;

        // Process each event
        for (final eventDoc in eventsSnapshot.docs) {
          final eventId = eventDoc.id;
          final eventData = eventDoc.data() as Map<String, dynamic>;

          mainEventsProcessed.add(eventId);

          // Check if event has a spaceId and spaceRef
          if (eventData.containsKey('spaceId') &&
              eventData['spaceId'] is String &&
              eventData.containsKey('spaceRef') &&
              eventData['spaceRef'] is String) {
            final spaceId = eventData['spaceId'] as String;
            final spaceRef = eventData['spaceRef'] as String;

            // Parse the space reference to get the path components
            try {
              final pathParts = spaceRef.split('/');
              if (pathParts.length >= 4) {
                final type = pathParts[1];
                final subSpaceId = pathParts[3];

                if (subSpaceId == spaceId) {
                  // Valid path format, ensure event exists in subcollection
                  final subcollectionRef = firestore
                      .collection('spaces')
                      .doc(type)
                      .collection('spaces')
                      .doc(spaceId)
                      .collection('events')
                      .doc(eventId);

                  try {
                    final subcollectionDoc = await subcollectionRef.get();

                    if (!subcollectionDoc.exists) {
                      // Create in subcollection
                      await subcollectionRef.set(eventData);
                      batchSynced++;
                      totalEventsSynced++;
                    }
                  } catch (e) {
                    debugPrint('Error creating event in subcollection: $e');
                  }
                }
              }
            } catch (e) {
              debugPrint('Error parsing space reference: $e');
            }
          }
        }

        debugPrint(
            'Synced $batchSynced events to space subcollections in this batch');

        // Check if we've processed all events
        if (eventsSnapshot.docs.length < 500) {
          hasMoreEvents = false;
        }
      } catch (e) {
        debugPrint('Error processing events batch: $e');
        // Safety mechanism to avoid infinite loop
        hasMoreEvents = false;
      }
    }

    debugPrint(
        '\n=== FINISHED SYNCING $totalEventsSynced EVENTS TO SUBCOLLECTIONS ===\n');
  }

  /// Create space for events if needed when event to subcollection sync finds missing space
  static Future<void> _createSpaceIfNeeded(
      String spaceId, String type, DocumentReference spaceRef) async {
    try {
      // Check if space exists
      final spaceDoc = await spaceRef.get();
      if (!spaceDoc.exists) {
        debugPrint('Creating missing space for events: $spaceId in $type');

        // Create a basic space with minimum required fields
        final spaceData = SpaceHelper.createCompleteSpaceData(
          id: spaceId,
          name: 'Auto-created Space',
          description:
              'This space was automatically created to organize events',
          spaceType: type,
          tags: ['auto-created', 'from-events'],
        );

        await spaceRef.set(spaceData);
        debugPrint('✓ Created missing space: $spaceId in $type');
      }
    } catch (e) {
      debugPrint('Error creating space: $e');
    }
  }

  /// Run the full fix process for space event subcollections
  static Future<void> runFullFixProcess() async {
    try {
      // Fix existing subcollections
      await fixSpaceEventSubcollections();

      // Sync events from main collection to subcollections
      await syncEventsToSubcollections();

      debugPrint('\n=== SPACE SUBCOLLECTION FIX PROCESS COMPLETE ===\n');
    } catch (e) {
      debugPrint('ERROR IN SUBCOLLECTION FIX PROCESS: $e');
    }
  }
}
