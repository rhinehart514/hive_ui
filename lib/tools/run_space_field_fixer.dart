import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_ui/features/spaces/utils/space_helper.dart';
import 'package:hive_ui/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A standalone tool to ensure all spaces have the complete set of required fields
/// This is particularly important for auto-created spaces from event migrations
///
/// Run with: flutter run -t lib/tools/run_space_field_fixer.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const SpaceFieldFixerApp());
}

class SpaceFieldFixerApp extends StatefulWidget {
  const SpaceFieldFixerApp({Key? key}) : super(key: key);

  @override
  State<SpaceFieldFixerApp> createState() => _SpaceFieldFixerAppState();
}

class _SpaceFieldFixerAppState extends State<SpaceFieldFixerApp> {
  bool _isRunning = false;
  bool _isComplete = false;
  String _status = '';
  int _spacesFound = 0;
  int _spacesFixed = 0;
  int _spacesMoved = 0;
  int _currentTypeIndex = 0;

  final List<String> _typeCollections = [
    'student_organizations',
    'university_organizations',
    'campus_living',
    'fraternity_and_sorority',
    'other'
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Colors.amber,
          secondary: Colors.amberAccent,
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Space Field Structure Fixer'),
          backgroundColor: Colors.black87,
        ),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Card(
                  color: Colors.black87,
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'Space Field Fixer',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'This tool ensures all spaces have the complete set of required fields.',
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'It is particularly useful for fixing auto-created spaces that may be missing fields.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                if (_isRunning) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_status, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  if (_spacesFound > 0)
                    Text(
                      'Progress: $_spacesFixed / $_spacesFound spaces processed',
                      textAlign: TextAlign.center,
                    ),
                ] else ...[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                    ),
                    onPressed: _isComplete ? null : _runFieldFixer,
                    child: Text(
                      _isComplete
                          ? 'Process Complete'
                          : 'Run Space Field Fixer',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_isComplete)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Space field fix process completed!'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                              'Fixed $_spacesFixed out of $_spacesFound spaces'),
                          if (_spacesMoved > 0)
                            Text(
                                'Moved $_spacesMoved spaces to correct collections'),
                        ],
                      ),
                    )
                ],
                const SizedBox(height: 32),
                const Card(
                  color: Colors.black87,
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text('Fields Fixed:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('• Required boolean fields (isJoined, isPrivate)'),
                        Text('• Complete metrics object structure'),
                        Text(
                            '• Missing arrays (admins, moderators, relatedSpaceIds)'),
                        Text('• Missing maps (customData, quickActions)'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _runFieldFixer() async {
    setState(() {
      _isRunning = true;
      _status = 'Starting space field fix process...';
      _spacesFound = 0;
      _spacesFixed = 0;
      _spacesMoved = 0;
      _currentTypeIndex = 0;
    });

    try {
      final firestore = FirebaseFirestore.instance;

      // Process each space type collection
      for (final type in _typeCollections) {
        setState(() {
          _status = 'Processing spaces in $type...';
          _currentTypeIndex++;
        });

        debugPrint('\n=== FIXING SPACES IN $type ===\n');

        // Get spaces in this type
        final spacesSnapshot = await firestore
            .collection('spaces')
            .doc(type)
            .collection('spaces')
            .get();

        setState(() {
          _spacesFound += spacesSnapshot.docs.length;
        });

        debugPrint('Found ${spacesSnapshot.docs.length} spaces in $type');

        // Process in batches to avoid overloading Firestore
        List<List<DocumentSnapshot>> batches = [];
        List<DocumentSnapshot> currentBatch = [];

        for (final doc in spacesSnapshot.docs) {
          currentBatch.add(doc);

          if (currentBatch.length >= 20) {
            batches.add(List.from(currentBatch));
            currentBatch = [];
          }
        }

        if (currentBatch.isNotEmpty) {
          batches.add(currentBatch);
        }

        // Process each batch
        int batchNumber = 1;
        for (final batch in batches) {
          setState(() {
            _status =
                'Processing spaces in $type (batch $batchNumber/${batches.length})...';
          });

          // Process each space in the batch
          for (final doc in batch) {
            await _fixSpaceFields(doc, type);
          }

          batchNumber++;
        }
      }

      setState(() {
        _isComplete = true;
        _status = 'Process completed successfully!';
      });

      debugPrint('\n=== SPACE FIELD FIX COMPLETE ===');
      debugPrint('Fixed $_spacesFixed out of $_spacesFound spaces');
    } catch (error) {
      setState(() {
        _status = 'Error: $error';
      });
      debugPrint('Error running space field fixer: $error');
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  Future<void> _fixSpaceFields(DocumentSnapshot doc, String type) async {
    try {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null || data.isEmpty) return;

      final String spaceId = doc.id;
      bool needsUpdate = false;

      // Check for auto-created spaces or spaces missing critical fields
      bool isAutoCreated = data['autoCreatedFromMigration'] == true ||
          data['isAutoCreated'] == true ||
          data['source'] == 'lost_event_migration' ||
          (data['metrics'] == null);

      // Also check for spaces that have enough fields but might be missing some
      if (!isAutoCreated) {
        // Check for missing basic required fields
        if (!data.containsKey('isJoined') ||
            !data.containsKey('isPrivate') ||
            !data.containsKey('metrics') ||
            !data.containsKey('moderators') ||
            !data.containsKey('admins') ||
            !data.containsKey('customData')) {
          isAutoCreated = true;
        }
      }

      // Get existing values to preserve
      final name = data['name'] as String? ?? 'Space $spaceId';
      final description = data['description'] as String? ?? '';
      final eventIds = data['eventIds'] is List
          ? List<String>.from(data['eventIds'])
          : <String>[];

      // Determine tags
      List<String> tags = [];
      if (data['tags'] is List) {
        tags = List<String>.from(data['tags']);
      }
      if (!tags.contains('auto-created')) {
        tags.add('auto-created');
      }

      // Determine space type if not already set
      String spaceType =
          data['spaceType'] as String? ?? data['type'] as String? ?? type;

      // Normalize space type to match collection names
      String normalizedType = _normalizeSpaceType(spaceType);

      // Create complete space data
      final updatedData = SpaceHelper.createCompleteSpaceData(
        id: spaceId,
        name: name,
        description: description,
        spaceType: spaceType,
        eventIds: eventIds,
        tags: tags,
        isAutoCreated: isAutoCreated,
      );

      // Preserve created timestamps if they exist
      if (data['createdAt'] != null) {
        updatedData['createdAt'] = data['createdAt'];
      }

      // Ensure we don't lose any existing fields that might be important
      if (data['metrics'] is Map) {
        // Merge existing metrics with default metrics
        final existingMetrics =
            Map<String, dynamic>.from(data['metrics'] as Map);
        final updatedMetrics = updatedData['metrics'] as Map<String, dynamic>;

        // Keep existing values for metrics if they exist
        for (final key in existingMetrics.keys) {
          updatedMetrics[key] = existingMetrics[key];
        }

        updatedData['metrics'] = updatedMetrics;
      }

      // Keep any special fields the space might have
      if (data['organizer_name'] != null) {
        updatedData['organizer_name'] = data['organizer_name'];
      }

      if (data['source'] != null) {
        updatedData['source'] = data['source'];
      }

      if (data['icon'] != null) {
        updatedData['icon'] = data['icon'];
      }

      if (data['imageUrl'] != null) {
        updatedData['imageUrl'] = data['imageUrl'];
      }

      // Check if space needs to be moved to a different collection
      if (normalizedType != type) {
        // Space needs to be moved to the correct collection
        await _moveSpaceToCorrectCollection(
            doc, spaceId, normalizedType, updatedData);
        debugPrint(
            '✓ Moved space $spaceId from $type to $normalizedType collection');
      } else {
        // Just update the space in its current collection
        await doc.reference.update(updatedData);
        debugPrint('✓ Fixed fields for space: $spaceId (in $type collection)');
      }

      setState(() {
        _spacesFixed++;
      });
    } catch (e) {
      debugPrint('✗ Error fixing space ${doc.id}: $e');
    }
  }

  /// Move a space to the correct collection based on its spaceType
  Future<void> _moveSpaceToCorrectCollection(
      DocumentSnapshot doc,
      String spaceId,
      String targetCollection,
      Map<String, dynamic> spaceData) async {
    final firestore = FirebaseFirestore.instance;

    try {
      // Reference to the new location
      final newSpaceRef = firestore
          .collection('spaces')
          .doc(targetCollection)
          .collection('spaces')
          .doc(spaceId);

      // Create a batch for atomic operations
      final batch = firestore.batch();

      // Add space to new collection
      batch.set(newSpaceRef, spaceData);

      // Delete from old collection
      batch.delete(doc.reference);

      // Update any events referencing this space
      await _updateSpaceReferencesInEvents(
          spaceId, doc.reference.path, newSpaceRef.path);

      // Commit the batch operation
      await batch.commit();

      // Update counter
      setState(() {
        _spacesMoved++;
      });
    } catch (e) {
      debugPrint('Error moving space: $e');
      // If move fails, still update the original doc
      await doc.reference.update(spaceData);
    }
  }

  /// Update references to this space in all events
  Future<void> _updateSpaceReferencesInEvents(
      String spaceId, String oldPath, String newPath) async {
    final firestore = FirebaseFirestore.instance;

    try {
      // Find events referencing this space
      final eventsQuery = firestore
          .collection('events')
          .where('spaceId', isEqualTo: spaceId)
          .limit(100);

      bool hasMoreEvents = true;
      DocumentSnapshot? lastDoc;
      int updatedCount = 0;

      // Process events in batches
      while (hasMoreEvents) {
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

        // Create a batch for updates
        final batch = firestore.batch();

        for (final eventDoc in eventsSnapshot.docs) {
          final eventData = eventDoc.data() as Map<String, dynamic>;

          // Check if event references old path
          if (eventData['spaceRef'] == oldPath) {
            batch.update(eventDoc.reference, {'spaceRef': newPath});
            updatedCount++;
          }
        }

        await batch.commit();

        // If we got less than the limit, we've processed all events
        if (eventsSnapshot.docs.length < 100) {
          hasMoreEvents = false;
        }
      }

      if (updatedCount > 0) {
        debugPrint('✓ Updated $updatedCount events with new space reference');
      }
    } catch (e) {
      debugPrint('Error updating event references: $e');
    }
  }

  /// Normalize space type to match Firestore collection names
  String _normalizeSpaceType(String type) {
    // Convert from spaceType to collection name
    switch (type.toLowerCase()) {
      case 'studentorg':
      case 'student org':
      case 'student_org':
      case 'student organization':
      case 'student_organization':
        return 'student_organizations';

      case 'universityorg':
      case 'university org':
      case 'university_org':
      case 'university organization':
      case 'university_organization':
        return 'university_organizations';

      case 'campus_living':
      case 'campusliving':
      case 'campus living':
      case 'dorm':
      case 'residence':
      case 'housing':
        return 'campus_living';

      case 'fraternity':
      case 'sorority':
      case 'frat':
      case 'fraternity_and_sorority':
      case 'fraternity and sorority':
      case 'greek':
      case 'greek life':
        return 'fraternity_and_sorority';

      default:
        // If type exactly matches a collection name, return it
        if (_typeCollections.contains(type)) {
          return type;
        }
        // Otherwise default to 'other'
        return 'other';
    }
  }
}
