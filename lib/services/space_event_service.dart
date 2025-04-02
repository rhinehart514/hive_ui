import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/models/space.dart';
import 'package:hive_ui/models/space_metrics.dart';
import 'package:hive_ui/models/space_type.dart';
import 'package:hive_ui/services/space_service.dart';
import 'package:hive_ui/utils/space_categorizer.dart';

/// Service for handling the connection between spaces and events
class SpaceEventService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Extract spaces from a list of events and save them to Firestore
  static Future<List<Space>> extractSpacesFromEvents(List<Event> events) async {
    final Map<String, _SpaceData> spacesMap = {};

    // First pass: Extract basic space data from events
    for (final event in events) {
      // Skip if organizer name is empty
      if (event.organizerName.isEmpty) continue;

      // Create a unique ID for the space based on the organizer name
      final String spaceId = _generateSpaceId(event.organizerName);

      // If this space already exists in our map, update it
      if (spacesMap.containsKey(spaceId)) {
        final _SpaceData existingData = spacesMap[spaceId]!;
        existingData.eventIds.add(event.id);

        // Update last activity if this event is more recent
        if (event.startDate.isAfter(existingData.lastActivity)) {
          existingData.lastActivity = event.startDate;
        }

        // Merge tags
        for (final tag in event.tags) {
          if (!existingData.tags.contains(tag)) {
            existingData.tags.add(tag);
          }
        }
      } else {
        // Create new space data
        final spaceType = SpaceCategorizer.categorizeFromEvent(event);

        spacesMap[spaceId] = _SpaceData(
          id: spaceId,
          name: event.organizerName,
          description: 'Events organized by ${event.organizerName}',
          tags: [...event.tags],
          eventIds: [event.id],
          lastActivity: event.startDate,
          spaceType: spaceType,
        );
      }
    }

    // Check which spaces already exist in Firestore
    final firestore = FirebaseFirestore.instance;
    final spacesCollection = firestore.collection('spaces');

    // Get all space IDs to check
    final List<String> spaceIds = spacesMap.keys.toList();
    final Map<String, bool> existingSpaces = {};

    // Check in batches of 10 to avoid overloading Firestore
    const int batchSize = 10;
    for (int i = 0; i < spaceIds.length; i += batchSize) {
      final end =
          i + batchSize < spaceIds.length ? i + batchSize : spaceIds.length;
      final batchIds = spaceIds.sublist(i, end);

      // Check each space ID individually
      for (final spaceId in batchIds) {
        try {
          final docSnapshot = await spacesCollection.doc(spaceId).get();
          existingSpaces[spaceId] = docSnapshot.exists;
        } catch (e) {
          debugPrint('Error checking if space exists: $e');
          // Assume it doesn't exist if there's an error
          existingSpaces[spaceId] = false;
        }
      }
    }

    // Second pass: Create Space objects and save to Firestore only if they don't exist
    final List<Space> spaces = [];
    final List<Future<void>> saveTasks = [];

    for (final data in spacesMap.values) {
      // Create metrics
      final metrics = SpaceMetrics(
        spaceId: data.id,
        memberCount: 0, // We don't have this information yet
        activeMembers: 0,
        weeklyEvents: data.eventIds
            .length, // Simplification, assuming all events are in current week
        monthlyEngagements: 0,
        lastActivity: data.lastActivity,
        hasNewContent: _isRecent(data.lastActivity),
        isTrending: data.eventIds.length > 3, // Simple heuristic
        activeMembers24h: const [],
        activityScores: const {},
        category: SpaceCategory.suggested,
        size: data.eventIds.length > 5
            ? SpaceSize.large
            : (data.eventIds.length > 2 ? SpaceSize.medium : SpaceSize.small),
        engagementScore: data.eventIds.length * 10.0, // Simple scoring
      );

      // Create space
      final space = Space(
        id: data.id,
        name: data.name,
        description: data.description,
        icon: _getIconForSpaceType(data.spaceType),
        metrics: metrics,
        tags: data.tags,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        spaceType: data.spaceType,
        eventIds: data.eventIds,
      );

      spaces.add(space);

      // Only save to Firestore if the space doesn't already exist
      if (existingSpaces[data.id] == false) {
        debugPrint('Creating new space document: ${space.id}');
        saveTasks.add(SpaceService.saveSpace(space));
      } else {
        // Maybe just update event associations for existing spaces
        // This could be implemented later if needed
        debugPrint('Space already exists, skipping creation: ${space.id}');
      }
    }

    // Wait for all save operations to complete
    await Future.wait(saveTasks);

    debugPrint(
        'Extracted and saved ${saveTasks.length} spaces from ${events.length} events');
    return spaces;
  }

  /// Link an existing event to a space
  static Future<void> linkEventToSpace(
      String eventId, String? organizerName) async {
    if (organizerName == null || organizerName.isEmpty) return;

    final spaceId = _generateSpaceId(organizerName);

    try {
      // Check if space exists
      final spaceDoc = await _firestore.collection('spaces').doc(spaceId).get();

      if (spaceDoc.exists) {
        // Space exists, add event to it
        await SpaceService.addEventToSpace(spaceId, eventId);
      } else {
        // Space doesn't exist yet, we need event info to create it
        final eventDoc =
            await _firestore.collection('events').doc(eventId).get();

        if (eventDoc.exists) {
          final eventData = eventDoc.data() as Map<String, dynamic>;
          final event = Event.fromJson(eventData);

          // Create and save space
          await extractSpacesFromEvents([event]);
        }
      }
    } catch (e) {
      debugPrint('Error linking event to space: $e');
    }
  }

  /// Generate a space ID from organizer name
  static String _generateSpaceId(String organizerName) {
    // Normalize the name (lowercase, remove special chars)
    final normalized = organizerName
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');

    return 'space_$normalized';
  }

  /// Check if a date is recent (within last 7 days)
  static bool _isRecent(DateTime date) {
    final now = DateTime.now();
    return now.difference(date).inDays <= 7;
  }

  /// Get appropriate icon for space type
  static IconData _getIconForSpaceType(SpaceType type) {
    return type.icon;
  }

  /// Process all existing events in Firestore and extract spaces
  static Future<int> processAllExistingEvents() async {
    try {
      final eventsCollection = _firestore.collection('events');

      // Get all events
      final querySnapshot = await eventsCollection.get();
      debugPrint('Found ${querySnapshot.docs.length} events to process');

      if (querySnapshot.docs.isEmpty) {
        return 0;
      }

      // Convert documents to Event objects
      final events = querySnapshot.docs
          .map((doc) {
            try {
              return Event.fromJson(doc.data());
            } catch (e) {
              debugPrint('Error parsing event document ${doc.id}: $e');
              return null;
            }
          })
          .whereType<Event>()
          .toList();

      // Process in batches to avoid memory issues
      const int batchSize = 50;
      int processedSpaces = 0;

      for (int i = 0; i < events.length; i += batchSize) {
        final end =
            i + batchSize < events.length ? i + batchSize : events.length;
        final batch = events.sublist(i, end);

        final spaces = await extractSpacesFromEvents(batch);
        processedSpaces += spaces.length;

        debugPrint(
            'Processed batch ${i ~/ batchSize + 1}/${(events.length / batchSize).ceil()}, created $processedSpaces spaces so far');
      }

      return processedSpaces;
    } catch (e) {
      debugPrint('Error processing all events: $e');
      return 0;
    }
  }

  /// Find and fix unassigned events by placing them into appropriate spaces
  /// Returns a summary of what was fixed and any remaining issues
  static Future<Map<String, dynamic>> findAndFixUnassignedEvents() async {
    try {
      // Get the current state of event-space assignments
      final verificationResults =
          await SpaceService.verifyEventSpaceAssignments();

      // Check if there was an error in verification
      if (verificationResults.containsKey('error')) {
        return {
          'error': 'Error during verification: ${verificationResults['error']}',
          'fixedEvents': 0
        };
      }

      final List<Map<String, dynamic>> unassignedEvents =
          List<Map<String, dynamic>>.from(
              verificationResults['unassignedEvents'] as List);

      final List<Map<String, dynamic>> eventsWithMissingOrganizerName =
          List<Map<String, dynamic>>.from(
              verificationResults['eventsWithMissingOrganizerName'] as List);

      debugPrint('Found ${unassignedEvents.length} unassigned events');
      debugPrint(
          'Found ${eventsWithMissingOrganizerName.length} events with missing organizer name');

      // These will track our fix results
      final List<Map<String, dynamic>> successfullyFixed = [];
      final List<Map<String, dynamic>> failedToFix = [];

      // Get all events that are unassigned but have organizer names
      final List<Map<String, dynamic>> fixableEvents = unassignedEvents
          .where((event) =>
              event['organizerName'] != null &&
              event['organizerName'].toString().trim().isNotEmpty)
          .toList();

      // Process each fixable event
      for (final eventData in fixableEvents) {
        final String eventId = eventData['eventId'];
        final String organizerName = eventData['organizerName'];

        try {
          // Get the full event document
          final eventDoc =
              await _firestore.collection('events').doc(eventId).get();
          if (!eventDoc.exists) {
            failedToFix
                .add({...eventData, 'reason': 'Event document not found'});
            continue;
          }

          // Convert to Event model
          final event = Event.fromJson(
              {'id': eventId, ...eventDoc.data() as Map<String, dynamic>});

          // Generate the space ID from the organizer name
          final String spaceId = _generateSpaceId(organizerName);

          // Determine the space type for this event
          final SpaceType spaceType =
              SpaceCategorizer.categorizeFromEvent(event);

          // Convert the space type to the appropriate collection path
          final String typeCollection = _getTypeCollectionPath(spaceType);

          // Check if the space already exists in the hierarchical structure
          final spaceRef = _firestore
              .collection('spaces')
              .doc(typeCollection)
              .collection('spaces')
              .doc(spaceId);

          final spaceDoc = await spaceRef.get();

          if (spaceDoc.exists) {
            // Space exists in the correct location, add the event
            debugPrint(
                'Adding event $eventId to existing space $spaceId in spaces/$typeCollection/spaces/');

            // Update the space with the new event ID
            await spaceRef.update({
              'eventIds': FieldValue.arrayUnion([eventId]),
              'updatedAt': FieldValue.serverTimestamp(),
            });

            successfullyFixed.add({
              ...eventData,
              'action': 'Added to existing space',
              'spaceId': spaceId,
              'spaceType': spaceType.name,
              'collectionPath': 'spaces/$typeCollection/spaces'
            });
          } else {
            // Space doesn't exist, create it
            debugPrint(
                'Creating new space $spaceId in spaces/$typeCollection/spaces/');

            // First check if a space with this ID exists in the root collection
            // (in case it hasn't been migrated yet)
            final rootSpaceDoc =
                await _firestore.collection('spaces').doc(spaceId).get();

            if (rootSpaceDoc.exists) {
              // Copy the existing space data to the typed location
              final rootSpaceData = rootSpaceDoc.data() as Map<String, dynamic>;

              // Add the event ID if it's not already there
              final List<dynamic> existingEventIds =
                  rootSpaceData['eventIds'] as List<dynamic>? ?? [];
              if (!existingEventIds.contains(eventId)) {
                existingEventIds.add(eventId);
              }

              // Update the space data
              final updatedSpaceData = {
                ...rootSpaceData,
                'eventIds': existingEventIds,
                'updatedAt': FieldValue.serverTimestamp(),
                'spaceType':
                    spaceType.toFirestoreValue(), // Ensure correct type
              };

              // Save to the typed location
              await spaceRef.set(updatedSpaceData);

              successfullyFixed.add({
                ...eventData,
                'action': 'Migrated existing space and added event',
                'spaceId': spaceId,
                'spaceType': spaceType.name,
                'collectionPath': 'spaces/$typeCollection/spaces'
              });
            } else {
              // Create a completely new space
              final spaces = await extractSpacesFromEvents([event]);

              if (spaces.isNotEmpty) {
                // The space was created in the root collection, now move it to the typed location
                // Get the space data from the root collection
                final rootCreatedSpaceDoc =
                    await _firestore.collection('spaces').doc(spaceId).get();

                if (rootCreatedSpaceDoc.exists) {
                  // Copy to typed location
                  await spaceRef
                      .set(rootCreatedSpaceDoc.data() as Map<String, dynamic>);

                  // Optionally delete from root (uncomment if you want to do this)
                  // await _firestore.collection('spaces').doc(spaceId).delete();

                  successfullyFixed.add({
                    ...eventData,
                    'action': 'Created new space and added event',
                    'spaceId': spaceId,
                    'spaceType': spaceType.name,
                    'collectionPath': 'spaces/$typeCollection/spaces'
                  });
                } else {
                  failedToFix.add({
                    ...eventData,
                    'reason': 'Failed to create space in root collection'
                  });
                }
              } else {
                failedToFix
                    .add({...eventData, 'reason': 'Failed to create space'});
              }
            }
          }
        } catch (e) {
          debugPrint('Error fixing event $eventId: $e');
          failedToFix.add({...eventData, 'reason': 'Error: $e'});
        }
      }

      // Compile the final results
      final Map<String, dynamic> fixResults = {
        'totalUnassignedEvents': unassignedEvents.length,
        'eventsWithMissingOrganizerName': eventsWithMissingOrganizerName,
        'fixableEvents': fixableEvents.length,
        'successfullyFixed': successfullyFixed,
        'failedToFix': failedToFix,
        'summary': {
          'totalFixed': successfullyFixed.length,
          'totalFailed': failedToFix.length,
          'totalWithMissingOrganizerName':
              eventsWithMissingOrganizerName.length,
          'percentageFixed': unassignedEvents.isEmpty
              ? 100
              : (successfullyFixed.length / unassignedEvents.length * 100)
                  .round()
        }
      };

      // Print a summary
      debugPrint('==== EVENT FIXING SUMMARY ====');
      debugPrint('Total unassigned events: ${unassignedEvents.length}');
      debugPrint('Events fixed: ${successfullyFixed.length}');
      debugPrint('Events failed to fix: ${failedToFix.length}');
      debugPrint(
          'Events with missing organizer name: ${eventsWithMissingOrganizerName.length}');

      if (successfullyFixed.isNotEmpty) {
        debugPrint('\nSuccessfully fixed events by spaces:');
        // Group fixed events by space type
        final Map<String, int> countBySpaceType = {};
        for (final event in successfullyFixed) {
          final spaceType = event['spaceType'] ?? 'unknown';
          countBySpaceType[spaceType] = (countBySpaceType[spaceType] ?? 0) + 1;
        }

        countBySpaceType.forEach((type, count) {
          debugPrint('- $type: $count events');
        });
      }

      if (failedToFix.isNotEmpty) {
        debugPrint('\nFailed to fix events by reason:');
        // Group failed events by reason
        final Map<String, int> countByReason = {};
        for (final event in failedToFix) {
          final reason = event['reason'] ?? 'unknown';
          countByReason[reason] = (countByReason[reason] ?? 0) + 1;
        }

        countByReason.forEach((reason, count) {
          debugPrint('- $reason: $count events');
        });
      }

      return fixResults;
    } catch (e) {
      debugPrint('Error fixing unassigned events: $e');
      return {'error': e.toString(), 'fixedEvents': 0};
    }
  }

  /// Convert a SpaceType to the appropriate collection path in Firestore
  static String _getTypeCollectionPath(SpaceType spaceType) {
    switch (spaceType) {
      case SpaceType.studentOrg:
        return 'student_organizations';
      case SpaceType.universityOrg:
        return 'university_organizations';
      case SpaceType.campusLiving:
        return 'campus_living';
      case SpaceType.fraternityAndSorority:
        return 'fraternity_and_sorority';
      case SpaceType.hiveExclusive:
        return 'hive_exclusive';
      case SpaceType.other:
        return 'other';
    }
  }

  /// Synchronize event between global events collection and space events subcollection
  /// When an event is created or updated in either location, this ensures both are synchronized
  static Future<void> synchronizeEvent(Event event, {String? spaceId}) async {
    try {
      // If spaceId is not provided, try to determine it from organizer name
      final String targetSpaceId =
          spaceId ?? _generateSpaceId(event.organizerName);
      final Map<String, dynamic> eventData = event.toJson();

      // First, ensure the event exists in the global events collection
      final globalEventRef = _firestore.collection('events').doc(event.id);

      // Find the space document using the spaceId
      final spaceQuery = await _firestore
          .collectionGroup('spaces')
          .where('id', isEqualTo: targetSpaceId)
          .limit(1)
          .get();

      if (spaceQuery.docs.isEmpty) {
        debugPrint('Space not found for event synchronization: $targetSpaceId');
        // Just update the global event and return
        await globalEventRef.set(eventData, SetOptions(merge: true));
        return;
      }

      // Get the space reference
      final spaceRef = spaceQuery.docs.first.reference;

      // Create a batch to update both locations atomically
      final batch = _firestore.batch();

      // Update in global events collection
      batch.set(globalEventRef, eventData, SetOptions(merge: true));

      // Update in space's events subcollection
      final spaceEventRef = spaceRef.collection('events').doc(event.id);
      batch.set(spaceEventRef, eventData, SetOptions(merge: true));

      // Add eventId to the space's eventIds array if not already there
      batch.update(spaceRef, {
        'eventIds': FieldValue.arrayUnion([event.id]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Commit the batch
      await batch.commit();

      debugPrint('Event synchronized successfully: ${event.id}');
    } catch (e) {
      debugPrint('Error synchronizing event: $e');
    }
  }

  /// Create or update an event in both global events collection and space events subcollection
  static Future<String> createOrUpdateEvent(Event event) async {
    try {
      // If event has no ID yet, generate one
      final String eventId = event.id.isNotEmpty
          ? event.id
          : 'event_${DateTime.now().millisecondsSinceEpoch}_${event.title.hashCode}';

      // Ensure event has the ID set
      final updatedEvent =
          event.id.isEmpty ? event.copyWith(id: eventId) : event;

      // Synchronize the event
      await synchronizeEvent(updatedEvent);

      return eventId;
    } catch (e) {
      debugPrint('Error creating/updating event: $e');
      return '';
    }
  }

  /// Delete an event from both global collection and space subcollection
  static Future<bool> deleteEvent(String eventId) async {
    try {
      // First fetch the event to get its organizer/space information
      final eventDoc = await _firestore.collection('events').doc(eventId).get();

      if (!eventDoc.exists) {
        debugPrint('Event not found for deletion: $eventId');
        return false;
      }

      final eventData = eventDoc.data() as Map<String, dynamic>;
      final organizerName = eventData['organizerName'] as String? ?? '';
      final spaceId = _generateSpaceId(organizerName);

      // Find the space document
      final spaceQuery = await _firestore
          .collectionGroup('spaces')
          .where('id', isEqualTo: spaceId)
          .limit(1)
          .get();

      // Create a batch for atomic operations
      final batch = _firestore.batch();

      // Delete from global events collection
      batch.delete(_firestore.collection('events').doc(eventId));

      // If space exists, delete from its events subcollection and update the space document
      if (spaceQuery.docs.isNotEmpty) {
        final spaceRef = spaceQuery.docs.first.reference;

        // Delete from space's events subcollection
        batch.delete(spaceRef.collection('events').doc(eventId));

        // Remove eventId from space's eventIds array
        batch.update(spaceRef, {
          'eventIds': FieldValue.arrayRemove([eventId]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Commit the batch
      await batch.commit();

      debugPrint('Event deleted successfully: $eventId');
      return true;
    } catch (e) {
      debugPrint('Error deleting event: $e');
      return false;
    }
  }
}

/// Helper class for building space data
class _SpaceData {
  final String id;
  final String name;
  final String description;
  final List<String> tags;
  final List<String> eventIds;
  final SpaceType spaceType;
  DateTime lastActivity;

  _SpaceData({
    required this.id,
    required this.name,
    required this.description,
    required this.tags,
    required this.eventIds,
    required this.lastActivity,
    required this.spaceType,
  });
}
