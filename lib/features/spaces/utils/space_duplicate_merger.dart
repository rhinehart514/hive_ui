import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive_ui/features/spaces/utils/space_helper.dart';

/// Utility class to find and merge duplicate spaces across different space types
class SpaceDuplicateMerger {
  /// Identify and merge duplicate spaces across different space types
  static Future<void> mergeDuplicateSpaces() async {
    final firestore = FirebaseFirestore.instance;

    debugPrint('\n=== CHECKING FOR DUPLICATE SPACES ACROSS TYPES ===\n');

    // Get all space types
    final typeCollections = [
      'student_organizations',
      'university_organizations',
      'campus_living',
      'fraternity_and_sorority',
      'other'
    ];

    // Map to store spaces by ID for quick lookup
    final Map<String, Map<String, dynamic>> spacesById = {};
    // Map to store space references by ID
    final Map<String, List<DocumentReference>> spaceRefsById = {};
    // Map to store space paths by ID
    final Map<String, List<String>> spacePathsById = {};

    // Step 1: Fetch all spaces from each type collection
    for (final type in typeCollections) {
      debugPrint('--- Scanning spaces in $type ---');

      try {
        final spacesCollection =
            firestore.collection('spaces').doc(type).collection('spaces');
        final spacesSnapshot = await spacesCollection.get();

        debugPrint(
            'Found ${spacesSnapshot.docs.length} spaces in spaces/$type/spaces');

        // Process each space
        for (final doc in spacesSnapshot.docs) {
          final id = doc.id;
          final data = doc.data();

          // Update space refs map - ensure lists exist before adding
          if (!spaceRefsById.containsKey(id)) {
            spaceRefsById[id] = <DocumentReference>[];
            spacePathsById[id] = <String>[];
          }

          // Now we're sure the lists exist
          spaceRefsById[id]?.add(doc.reference);
          spacePathsById[id]?.add('spaces/$type/spaces/$id');

          // If this is the first time seeing this space, just store it
          if (!spacesById.containsKey(id)) {
            spacesById[id] = data;
            // Add type path with null safety
            if (spacesById[id] != null) {
              spacesById[id]!['_typePath'] = type;
            }
            continue;
          }

          // We've found a duplicate space!
          debugPrint(
              '❗ DUPLICATE FOUND: Space ID $id exists in multiple collections:');
          debugPrint(
              '  - Existing: spaces/${spacesById[id]?['_typePath']}/spaces/$id');
          debugPrint('  - Duplicate: spaces/$type/spaces/$id');
        }
      } catch (e) {
        debugPrint('✗ Error scanning collection: $e');
      }
    }

    // Step 2: Find spaces with duplicates
    final duplicateIds = spaceRefsById.keys
        .where((id) => (spaceRefsById[id]?.length ?? 0) > 1)
        .toList();

    debugPrint('\n--- Found ${duplicateIds.length} spaces with duplicates ---');

    // Step 3: Merge duplicates
    for (final id in duplicateIds) {
      final refs = spaceRefsById[id];
      final paths = spacePathsById[id];

      if (refs != null && paths != null && refs.length > 1) {
        await _mergeDuplicateSpace(id, refs, paths);
      }
    }

    debugPrint('\n=== FINISHED CHECKING FOR DUPLICATE SPACES ===\n');
  }

  /// Merge duplicate spaces into a single space
  /// Priority: The space with the most complete data, or if auto-created from migration, merge into preexisting
  static Future<void> _mergeDuplicateSpace(
      String spaceId, List<DocumentReference> refs, List<String> paths) async {
    if (refs.length <= 1) return;

    debugPrint('\n--- Merging duplicate space: $spaceId ---');
    debugPrint('Paths: ${paths.join(', ')}');

    try {
      final batch = FirebaseFirestore.instance.batch();

      // Step 1: Get all space documents
      final List<DocumentSnapshot> docs = [];
      for (final ref in refs) {
        final doc = await ref.get();
        docs.add(doc);
      }

      // Step 2: Determine which space to keep (primary space)
      final primaryDoc = _determinePrimarySpace(docs);
      final primaryData = primaryDoc.data() as Map<String, dynamic>;

      debugPrint('Selected primary space: ${primaryDoc.reference.path}');

      // Step 3: Merge data from other spaces into the primary space
      final mergedData = await _mergeSpaceData(primaryDoc, docs);

      // Step 4: Update the primary space with merged data
      batch.update(primaryDoc.reference, mergedData);

      // Step 5: Update event references to point to the primary space
      await _updateEventReferences(batch, primaryDoc.reference, docs);

      // Step 6: Delete the other spaces
      for (final doc in docs) {
        if (doc.reference.path != primaryDoc.reference.path) {
          debugPrint('Deleting duplicate: ${doc.reference.path}');
          batch.delete(doc.reference);
        }
      }

      // Commit the batch
      await batch.commit();
      debugPrint('✅ Successfully merged duplicate space: $spaceId');
    } catch (e) {
      debugPrint('✗ Error merging duplicate space: $e');
    }
  }

  /// Update event references to point to the primary space
  static Future<void> _updateEventReferences(
      WriteBatch batch,
      DocumentReference primarySpaceRef,
      List<DocumentSnapshot> spaceDocs) async {
    final firestore = FirebaseFirestore.instance;

    // Extract all event IDs from all spaces
    final Set<String> allEventIds = {};
    final String primarySpacePath = primarySpaceRef.path;
    final String primarySpaceId = primarySpaceRef.id;

    debugPrint('--- Updating event references to point to primary space ---');

    for (final doc in spaceDocs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) continue;

      final List<String> eventIds = [];
      if (data['eventIds'] != null) {
        try {
          eventIds.addAll((data['eventIds'] as List).map((e) => e.toString()));
          allEventIds.addAll(eventIds);
        } catch (e) {
          debugPrint('Error extracting event IDs: $e');
        }
      }

      // Only process events if this is a duplicate space (not the primary)
      if (doc.reference.path != primarySpacePath && eventIds.isNotEmpty) {
        debugPrint(
            'Found ${eventIds.length} events in duplicate space: ${doc.reference.path}');
      }
    }

    if (allEventIds.isEmpty) {
      debugPrint('No events to update');
      return;
    }

    debugPrint('Found ${allEventIds.length} total events across all spaces');

    // Fetch all events and update their space references
    int updatedCount = 0;
    final eventsCollection = firestore.collection('events');

    // Process in chunks to avoid hitting Firestore limits
    final chunks = _chunkList(allEventIds.toList(), 30);
    for (final chunk in chunks) {
      try {
        final eventDocs = await eventsCollection
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (final eventDoc in eventDocs.docs) {
          final eventData = eventDoc.data();

          // Check if event has a spaceId or spaceRef field
          bool needsUpdate = false;

          if (eventData.containsKey('spaceId') &&
              eventData['spaceId'] != primarySpaceId) {
            eventData['spaceId'] = primarySpaceId;
            needsUpdate = true;
          }

          if (eventData.containsKey('spaceRef')) {
            final currentRef = eventData['spaceRef'];
            if (currentRef is String && currentRef != primarySpacePath) {
              eventData['spaceRef'] = primarySpacePath;
              needsUpdate = true;
            }
          }

          // Add to specific spaces array if it exists
          if (eventData.containsKey('spaces')) {
            final spaces = eventData['spaces'] as List?;
            if (spaces != null) {
              final spacesList = spaces.map((e) => e.toString()).toList();
              if (!spacesList.contains(primarySpaceId)) {
                spacesList.add(primarySpaceId);
                eventData['spaces'] = spacesList;
                needsUpdate = true;
              }
            }
          }

          if (needsUpdate) {
            batch.update(eventDoc.reference, eventData);
            updatedCount++;
          }
        }
      } catch (e) {
        debugPrint('Error processing event chunk: $e');
      }
    }

    debugPrint('✓ Updated $updatedCount events to reference the primary space');
  }

  /// Helper to chunk a list into smaller sublists
  static List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    final List<List<T>> chunks = [];
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(list.sublist(i, math.min(i + chunkSize, list.length)));
    }
    return chunks;
  }

  /// Determine which space document should be the primary one
  /// Priority criteria:
  /// 1. If one is from auto-migration, use the pre-existing one
  /// 2. The one with the most fields
  /// 3. The one with the most recent updatedAt
  /// 4. First in the list
  static DocumentSnapshot _determinePrimarySpace(List<DocumentSnapshot> docs) {
    if (docs.isEmpty) {
      throw Exception('No documents provided for primary space determination');
    }

    if (docs.length == 1) {
      return docs.first;
    }

    // Check for auto-migration flag
    final nonAutoCreatedDocs = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      return data != null && !(data['autoCreatedFromMigration'] == true);
    }).toList();

    if (nonAutoCreatedDocs.isNotEmpty) {
      // Use the non-auto-created space as primary
      if (nonAutoCreatedDocs.length == 1) {
        return nonAutoCreatedDocs.first;
      }

      // If multiple non-auto-created, proceed with other criteria
      docs = nonAutoCreatedDocs;
    }

    // Sort by number of fields (descending)
    docs.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>? ?? {};
      final bData = b.data() as Map<String, dynamic>? ?? {};
      return bData.length.compareTo(aData.length);
    });

    // If field counts are the same, compare updatedAt (most recent first)
    if (docs.length >= 2) {
      final firstData = docs.first.data() as Map<String, dynamic>? ?? {};
      final secondData = docs[1].data() as Map<String, dynamic>? ?? {};

      if (firstData.length == secondData.length) {
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>? ?? {};
          final bData = b.data() as Map<String, dynamic>? ?? {};

          final aUpdated = aData['updatedAt'] is Timestamp
              ? (aData['updatedAt'] as Timestamp).toDate()
              : DateTime(2000);

          final bUpdated = bData['updatedAt'] is Timestamp
              ? (bData['updatedAt'] as Timestamp).toDate()
              : DateTime(2000);

          return bUpdated.compareTo(aUpdated);
        });
      }
    }

    return docs.first;
  }

  /// Merge data from all spaces into a single map, with primary space as the base
  static Future<Map<String, dynamic>> _mergeSpaceData(
      DocumentSnapshot primaryDoc, List<DocumentSnapshot> allDocs) async {
    final primaryData = primaryDoc.data() as Map<String, dynamic>;
    final result = Map<String, dynamic>.from(primaryData);

    // Ensure the required fields exist in the result
    _ensureRequiredFields(result);

    // Get reference to the primary space's metrics
    final primaryMetrics = result['metrics'] as Map<String, dynamic>? ?? {};

    // Track merged event IDs
    final Set<String> mergedEventIds =
        Set<String>.from(result['eventIds'] ?? []);

    // Merge data from other docs
    for (final doc in allDocs) {
      if (doc.reference.path == primaryDoc.reference.path) continue;

      final data = doc.data() as Map<String, dynamic>? ?? {};

      // Merge tags (unique)
      if (data['tags'] != null) {
        final existingTags = Set<String>.from(result['tags'] ?? []);
        final newTags = Set<String>.from(data['tags'] as List? ?? []);
        result['tags'] = [...existingTags.union(newTags)];
      }

      // Merge event IDs (unique) - with more detailed logging
      if (data['eventIds'] != null) {
        try {
          final newEventIds = Set<String>.from(data['eventIds'] as List? ?? []);
          final beforeCount = mergedEventIds.length;
          mergedEventIds.addAll(newEventIds);

          if (mergedEventIds.length > beforeCount) {
            debugPrint(
                '  - Merged ${mergedEventIds.length - beforeCount} new event IDs from ${doc.reference.path}');
          }
        } catch (e) {
          debugPrint('Error merging eventIds: $e');
        }
      }

      // Merge embedded events if they exist
      if (data['events'] != null) {
        final existingEvents = result['events'] as List? ?? [];
        final newEvents = data['events'] as List? ?? [];

        // Create a map of existing events by ID for easy lookup
        final Map<String, dynamic> eventMap = {};
        for (final event in existingEvents) {
          if (event is Map<String, dynamic> && event['id'] != null) {
            eventMap[event['id']] = event;
          }
        }

        // Add or merge new events
        for (final event in newEvents) {
          if (event is Map<String, dynamic> && event['id'] != null) {
            final String eventId = event['id'];
            if (!eventMap.containsKey(eventId)) {
              eventMap[eventId] = event;
            } else {
              // Merge event data (could add more sophisticated merging here)
              eventMap[eventId] = {...eventMap[eventId]!, ...event};
            }
          }
        }

        // Convert back to list
        result['events'] = eventMap.values.toList();
        debugPrint(
            '  - Merged embedded events, total count: ${result['events'].length}');
      }

      // Merge metrics
      if (data['metrics'] != null) {
        final metricData = data['metrics'] as Map<String, dynamic>? ?? {};

        // Use max values for numeric fields
        primaryMetrics['memberCount'] = math.max<int>(
            primaryMetrics['memberCount'] as int? ?? 0,
            metricData['memberCount'] as int? ?? 0);

        primaryMetrics['activeMembers'] = math.max<int>(
            primaryMetrics['activeMembers'] as int? ?? 0,
            metricData['activeMembers'] as int? ?? 0);

        primaryMetrics['weeklyEvents'] = math.max<int>(
            primaryMetrics['weeklyEvents'] as int? ?? 0,
            metricData['weeklyEvents'] as int? ?? 0);

        primaryMetrics['monthlyEngagements'] = math.max<int>(
            primaryMetrics['monthlyEngagements'] as int? ?? 0,
            metricData['monthlyEngagements'] as int? ?? 0);

        primaryMetrics['engagementScore'] = math.max<double>(
            primaryMetrics['engagementScore'] as double? ?? 0.0,
            metricData['engagementScore'] as double? ?? 0.0);

        // Use boolean OR for flag fields
        primaryMetrics['hasNewContent'] =
            (primaryMetrics['hasNewContent'] as bool? ?? false) ||
                (metricData['hasNewContent'] as bool? ?? false);

        primaryMetrics['isTrending'] =
            (primaryMetrics['isTrending'] as bool? ?? false) ||
                (metricData['isTrending'] as bool? ?? false);

        primaryMetrics['isTimeSensitive'] =
            (primaryMetrics['isTimeSensitive'] as bool? ?? false) ||
                (metricData['isTimeSensitive'] as bool? ?? false);

        // Use most recent lastActivity
        if (metricData['lastActivity'] != null &&
            primaryMetrics['lastActivity'] != null) {
          final primaryLastActivity =
              primaryMetrics['lastActivity'] is Timestamp
                  ? (primaryMetrics['lastActivity'] as Timestamp).toDate()
                  : DateTime(2000);

          final otherLastActivity = metricData['lastActivity'] is Timestamp
              ? (metricData['lastActivity'] as Timestamp).toDate()
              : DateTime(2000);

          if (otherLastActivity.isAfter(primaryLastActivity)) {
            primaryMetrics['lastActivity'] = metricData['lastActivity'];
          }
        } else if (metricData['lastActivity'] != null) {
          primaryMetrics['lastActivity'] = metricData['lastActivity'];
        }

        // Merge connected friends
        if (metricData['connectedFriends'] != null) {
          final existingFriends =
              Set<String>.from(primaryMetrics['connectedFriends'] ?? []);
          final newFriends =
              Set<String>.from(metricData['connectedFriends'] as List? ?? []);
          primaryMetrics['connectedFriends'] = [
            ...existingFriends.union(newFriends)
          ];
        }
      }

      // Update the metrics in the result
      result['metrics'] = primaryMetrics;

      // Merge moderators and admins
      if (data['moderators'] != null) {
        final existingMods = Set<String>.from(result['moderators'] ?? []);
        final newMods = Set<String>.from(data['moderators'] as List? ?? []);
        result['moderators'] = [...existingMods.union(newMods)];
      }

      if (data['admins'] != null) {
        final existingAdmins = Set<String>.from(result['admins'] ?? []);
        final newAdmins = Set<String>.from(data['admins'] as List? ?? []);
        result['admins'] = [...existingAdmins.union(newAdmins)];
      }

      // Use the most recent updatedAt
      if (data['updatedAt'] != null && result['updatedAt'] != null) {
        final primaryUpdatedAt = result['updatedAt'] is Timestamp
            ? (result['updatedAt'] as Timestamp).toDate()
            : DateTime(2000);

        final otherUpdatedAt = data['updatedAt'] is Timestamp
            ? (data['updatedAt'] as Timestamp).toDate()
            : DateTime(2000);

        if (otherUpdatedAt.isAfter(primaryUpdatedAt)) {
          result['updatedAt'] = data['updatedAt'];
        }
      }

      // Use the earliest createdAt
      if (data['createdAt'] != null && result['createdAt'] != null) {
        final primaryCreatedAt = result['createdAt'] is Timestamp
            ? (result['createdAt'] as Timestamp).toDate()
            : DateTime(2000);

        final otherCreatedAt = data['createdAt'] is Timestamp
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime(2000);

        if (otherCreatedAt.isBefore(primaryCreatedAt)) {
          result['createdAt'] = data['createdAt'];
        }
      }
    }

    // Update eventIds in the result with all merged event IDs
    result['eventIds'] = mergedEventIds.toList();

    // Set the updatedAt field to now
    result['updatedAt'] = FieldValue.serverTimestamp();

    // Remove the auto-created flag if it exists
    result.remove('autoCreatedFromMigration');

    return result;
  }

  /// Ensure all required fields exist in the space data
  static void _ensureRequiredFields(Map<String, dynamic> data) {
    // Basic fields
    data['id'] ??= data['id'] ?? '';
    data['name'] ??= data['name'] ?? 'Unnamed Space';
    data['description'] ??= data['description'] ?? '';
    data['spaceType'] ??= data['spaceType'] ?? 'other';
    data['createdAt'] ??= FieldValue.serverTimestamp();
    data['updatedAt'] ??= FieldValue.serverTimestamp();

    // Lists
    data['tags'] ??= [];
    data['eventIds'] ??= [];
    data['moderators'] ??= [];
    data['admins'] ??= [];
    data['relatedSpaceIds'] ??= [];

    // Maps
    data['customData'] ??= {};
    data['quickActions'] ??= {};

    // Booleans
    data['isJoined'] ??= false;
    data['isPrivate'] ??= false;

    // Metrics
    if (data['metrics'] == null) {
      data['metrics'] = {
        'memberCount': 0,
        'activeMembers': 0,
        'weeklyEvents': 0,
        'monthlyEngagements': 0,
        'engagementScore': 0.0,
        'hasNewContent': false,
        'isTrending': false,
        'isTimeSensitive': false,
        'category': 'suggested',
        'size': 'medium',
        'connectedFriends': [],
        'spaceId': data['id'],
      };
    }
  }

  /// Delete spaces with no fields across all space types
  static Future<void> deleteEmptySpaces() async {
    final firestore = FirebaseFirestore.instance;

    debugPrint('\n=== CHECKING FOR EMPTY SPACES TO DELETE ===\n');

    // Get all space types
    final typeCollections = [
      'student_organizations',
      'university_organizations',
      'campus_living',
      'fraternity_and_sorority',
      'other'
    ];

    int totalEmptySpaces = 0;
    // Track empty spaces for later use with events
    final Map<String, DocumentReference> emptySpaceRefs = {};

    // Check each type collection for empty spaces
    for (final type in typeCollections) {
      debugPrint('--- Scanning for empty spaces in $type ---');

      try {
        final spacesCollection =
            firestore.collection('spaces').doc(type).collection('spaces');
        final spacesSnapshot = await spacesCollection.get();

        debugPrint(
            'Found ${spacesSnapshot.docs.length} total spaces in spaces/$type/spaces');

        // Create a batch for deletions
        WriteBatch batch = firestore.batch();
        int batchCount = 0;
        int emptySpacesCount = 0;

        // Process each space
        for (final doc in spacesSnapshot.docs) {
          final data = doc.data();

          // Check if the space is empty (has no fields or only has ID)
          bool isEmpty =
              data.isEmpty || (data.length == 1 && data.containsKey('id'));

          // More comprehensive check for "practically empty" spaces that just have placeholder data
          if (!isEmpty && data.length <= 3) {
            // Check if it only has basic placeholder fields
            final hasOnlyBasicFields = data.keys.every((key) =>
                ['id', 'name', 'createdAt', 'updatedAt'].contains(key));

            if (hasOnlyBasicFields) {
              isEmpty = true;
            }
          }

          if (isEmpty) {
            emptySpacesCount++;
            totalEmptySpaces++;

            // Store reference to empty space for event processing
            emptySpaceRefs[doc.id] = doc.reference;

            debugPrint('  - Found empty space: ${doc.id}');

            // We'll handle deletion later after checking for events
          }
        }

        debugPrint(
            '✓ Found $emptySpacesCount potentially empty spaces in spaces/$type/spaces');
      } catch (e) {
        debugPrint('✗ Error processing empty spaces in $type: $e');
      }
    }

    // Handle events for empty spaces before deletion
    if (emptySpaceRefs.isNotEmpty) {
      await _handleEventsForEmptySpaces(emptySpaceRefs);
    }

    // Now safely delete the empty spaces
    if (emptySpaceRefs.isNotEmpty) {
      debugPrint('Deleting ${emptySpaceRefs.length} confirmed empty spaces...');

      // Create batches for deletion (max 500 operations per batch)
      List<List<DocumentReference>> batches = [];
      List<DocumentReference> currentBatch = [];

      for (final ref in emptySpaceRefs.values) {
        currentBatch.add(ref);

        if (currentBatch.length >= 400) {
          batches.add(List.from(currentBatch));
          currentBatch = [];
        }
      }

      if (currentBatch.isNotEmpty) {
        batches.add(currentBatch);
      }

      // Process each batch
      int batchNumber = 1;
      for (final batchRefs in batches) {
        try {
          final batch = firestore.batch();
          for (final ref in batchRefs) {
            batch.delete(ref);
          }

          await batch.commit();
          debugPrint(
              '✓ Deleted batch $batchNumber of ${batches.length} (${batchRefs.length} spaces)');
        } catch (e) {
          debugPrint('✗ Error deleting batch $batchNumber: $e');
        }

        batchNumber++;
      }
    }

    debugPrint(
        '\n=== FINISHED CHECKING ${emptySpaceRefs.length} EMPTY SPACES ===\n');
  }

  /// Handle events for empty spaces - either move them or create proper spaces
  static Future<void> _handleEventsForEmptySpaces(
      Map<String, DocumentReference> emptySpaceRefs) async {
    final firestore = FirebaseFirestore.instance;

    debugPrint('\n=== CHECKING FOR EVENTS IN EMPTY SPACES ===\n');

    // Create map to store events per space ID
    final Map<String, List<DocumentSnapshot>> eventsBySpaceId = {};
    int totalEventsFound = 0;

    // Query for events that reference these empty spaces (in batches to avoid overloading Firestore)
    final chunks = _chunkList(emptySpaceRefs.keys.toList(), 10);
    for (final chunk in chunks) {
      try {
        final eventsQuery = firestore
            .collection('events')
            .where('spaceId', whereIn: chunk)
            .limit(1000);

        final eventsSnapshot = await eventsQuery.get();

        if (eventsSnapshot.docs.isNotEmpty) {
          debugPrint(
              'Found ${eventsSnapshot.docs.length} events for ${chunk.length} empty spaces');
          totalEventsFound += eventsSnapshot.docs.length;

          // Group events by space ID
          for (final eventDoc in eventsSnapshot.docs) {
            final data = eventDoc.data();
            final spaceId = data['spaceId'] as String?;

            if (spaceId != null && emptySpaceRefs.containsKey(spaceId)) {
              if (!eventsBySpaceId.containsKey(spaceId)) {
                eventsBySpaceId[spaceId] = [];
              }
              eventsBySpaceId[spaceId]!.add(eventDoc);
            }
          }
        }
      } catch (e) {
        debugPrint('Error fetching events for chunk: $e');
      }
    }

    debugPrint('Total events found in empty spaces: $totalEventsFound');

    // Process each space that has events
    for (final spaceId in eventsBySpaceId.keys) {
      final events = eventsBySpaceId[spaceId]!;

      if (events.isEmpty) continue;

      debugPrint(
          'Processing ${events.length} events for empty space: $spaceId');

      // Option 1: Create a proper space instead of deleting it
      await _createProperSpaceForEvents(
          spaceId, emptySpaceRefs[spaceId]!, events);

      // Remove from deletion list since we've upgraded it
      emptySpaceRefs.remove(spaceId);
    }

    debugPrint('\n=== FINISHED PROCESSING EVENTS FOR EMPTY SPACES ===\n');
  }

  /// Create a proper space document using event information
  static Future<void> _createProperSpaceForEvents(String spaceId,
      DocumentReference spaceRef, List<DocumentSnapshot> events) async {
    try {
      debugPrint(
          'Creating proper space for $spaceId with ${events.length} events');

      // Determine the best name for the space from events
      String spaceName = 'Space $spaceId';
      String spaceDescription = '';

      // Extract most common name from events
      final nameFrequency = <String, int>{};
      for (final eventDoc in events) {
        final data = eventDoc.data() as Map<String, dynamic>?;
        if (data != null) {
          // Try to get a name from the event
          final eventName = data['title'] as String? ?? data['name'] as String?;
          if (eventName != null && eventName.isNotEmpty) {
            // Extract potential org/space name from event title
            // Common patterns: "CSC Club Meeting", "Football Team Practice", etc.
            final parts = eventName.split(' ');
            if (parts.length > 2) {
              // Take first part or two as potential org name
              final potentialName =
                  parts.take(math.min(2, parts.length - 1)).join(' ');
              nameFrequency[potentialName] =
                  (nameFrequency[potentialName] ?? 0) + 1;
            } else {
              nameFrequency[eventName] = (nameFrequency[eventName] ?? 0) + 1;
            }
          }

          // Try to get a description from the event
          final eventDescription = data['description'] as String?;
          if (eventDescription != null &&
              eventDescription.isNotEmpty &&
              (spaceDescription.isEmpty ||
                  eventDescription.length > spaceDescription.length)) {
            spaceDescription = eventDescription;
          }
        }
      }

      // Use the most common name if available
      if (nameFrequency.isNotEmpty) {
        final sortedNames = nameFrequency.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        // Use the most frequent name if it appears in multiple events
        if (sortedNames.first.value > 1) {
          spaceName = '${sortedNames.first.key} Space';
        }
      }

      // Clean up description if needed
      if (spaceDescription.length > 200) {
        spaceDescription = '${spaceDescription.substring(0, 197)}...';
      }

      // Create event IDs list from events
      final eventIds = events.map((e) => e.id).toList();

      // Use SpaceHelper to create complete space data
      final spaceData = SpaceHelper.createCompleteSpaceData(
        id: spaceId,
        name: spaceName,
        description: spaceDescription.isNotEmpty
            ? spaceDescription
            : 'Space containing ${events.length} events',
        eventIds: eventIds,
        tags: ['auto-created', 'events-space'],
      );

      // Update the space doc
      await spaceRef.set(spaceData);
      debugPrint(
          '✓ Successfully created proper space: $spaceName (ID: $spaceId)');
    } catch (e) {
      debugPrint('Error creating proper space: $e');
    }
  }

  /// Fix orphaned events that reference spaces that don't exist - optimized version
  static Future<void> fixOrphanedEvents() async {
    final firestore = FirebaseFirestore.instance;

    debugPrint('\n=== CHECKING FOR ORPHANED EVENTS TO FIX ===\n');

    try {
      // First, collect all existing space IDs to avoid individual queries
      final Set<String> existingSpaceIds = {};

      // Get space IDs from all type collections
      for (final type in [
        'student_organizations',
        'university_organizations',
        'campus_living',
        'fraternity_and_sorority',
        'other'
      ]) {
        try {
          debugPrint('Fetching space IDs from $type...');
          final spacesSnapshot = await firestore
              .collection('spaces')
              .doc(type)
              .collection('spaces')
              .get();

          // Add all space IDs to the set
          for (final doc in spacesSnapshot.docs) {
            existingSpaceIds.add(doc.id);
          }

          debugPrint(
              '- Added ${spacesSnapshot.docs.length} space IDs from $type');
        } catch (e) {
          debugPrint('Error fetching spaces from $type: $e');
        }
      }

      debugPrint(
          'Found ${existingSpaceIds.length} total existing spaces across all types');

      // Now process events in batches
      final eventsCollection = firestore.collection('events');
      final eventsQuery = eventsCollection.limit(500);

      int totalFixed = 0;
      bool hasMoreEvents = true;
      DocumentSnapshot? lastDoc;

      while (hasMoreEvents) {
        // Get batch of events
        QuerySnapshot eventsSnapshot;
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
        debugPrint('Processing batch of ${eventsSnapshot.docs.length} events');

        // Create batch for updates
        WriteBatch batch = firestore.batch();
        int batchCount = 0;
        int fixedCount = 0;

        // Check each event
        for (final eventDoc in eventsSnapshot.docs) {
          final eventData = eventDoc.data() as Map<String, dynamic>;
          bool needsUpdate = false;

          // Check if event has a spaceId that doesn't exist in our cached space IDs
          if (eventData.containsKey('spaceId')) {
            final spaceId = eventData['spaceId'];
            if (spaceId != null && spaceId is String && spaceId.isNotEmpty) {
              if (!existingSpaceIds.contains(spaceId)) {
                debugPrint(
                    '  - Event ${eventDoc.id} references non-existent space: $spaceId');

                // Create a space in 'other' collection for this event
                final newSpaceRef = firestore
                    .collection('spaces')
                    .doc('other')
                    .collection('spaces')
                    .doc(spaceId);

                // Update the event to use the new space reference
                eventData['spaceRef'] = newSpaceRef.path;

                // Create the space document with basic info from the event
                try {
                  final title = eventData['title'] as String? ??
                      eventData['name'] as String? ??
                      'Event Space';
                  final description = eventData['description'] as String? ??
                      'Auto-created space for event ${eventDoc.id}';

                  // Create minimally valid space
                  await newSpaceRef.set({
                    'id': spaceId,
                    'name': '$title Space',
                    'description': description,
                    'eventIds': [eventDoc.id],
                    'spaceType': 'other',
                    'createdAt': FieldValue.serverTimestamp(),
                    'updatedAt': FieldValue.serverTimestamp(),
                    'tags': ['auto-created', 'event-space'],
                    'isAutoCreated': true,
                  });

                  // Add the newly created space ID to our tracking set
                  existingSpaceIds.add(spaceId);

                  needsUpdate = true;
                } catch (e) {
                  debugPrint('Error creating space for event: $e');
                }
              }
            }
          }

          if (needsUpdate) {
            batch.update(eventDoc.reference, eventData);
            batchCount++;
            fixedCount++;
            totalFixed++;

            // If batch gets too large, commit and create a new one
            if (batchCount >= 400) {
              await batch.commit();
              batch = firestore.batch();
              batchCount = 0;
              debugPrint('  - Committed batch of event fixes');
            }
          }
        }

        // Commit any remaining updates
        if (batchCount > 0) {
          await batch.commit();
          debugPrint('  - Committed final batch of event fixes');
        }

        debugPrint('✓ Fixed $fixedCount events in this batch');

        // Check if we've processed all events
        if (eventsSnapshot.docs.length < 500) {
          hasMoreEvents = false;
        }
      }

      debugPrint('\n=== FINISHED FIXING $totalFixed ORPHANED EVENTS ===\n');
    } catch (e) {
      debugPrint('✗ Error fixing orphaned events: $e');
    }
  }

  /// Runs complete space cleanup process
  static Future<void> runFullSpaceCleanup() async {
    try {
      // Fix empty spaces and duplicates
      await deleteEmptySpaces();
      await mergeDuplicateSpaces();

      // Fix orphaned events
      await fixOrphanedEvents();

      debugPrint('\n=== SPACE CLEANUP COMPLETE ===\n');
    } catch (e) {
      debugPrint('ERROR IN SPACE CLEANUP: $e');
    }
  }

  static runFullMergeProcess() {}
}
