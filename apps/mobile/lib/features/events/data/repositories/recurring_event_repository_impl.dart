import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive_ui/features/events/domain/repositories/recurring_event_repository.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/models/recurring_event.dart';
import 'package:hive_ui/core/event_bus/app_event_bus.dart';
import 'package:hive_ui/core/event_bus/recurring_event_events.dart';

/// Implementation of the RecurringEventRepository
class RecurringEventRepositoryImpl implements RecurringEventRepository {
  final FirebaseFirestore _firestore;
  final AppEventBus _eventBus;

  /// Constructor
  RecurringEventRepositoryImpl({
    FirebaseFirestore? firestore,
    AppEventBus? eventBus,
  }) : 
    _firestore = firestore ?? FirebaseFirestore.instance,
    _eventBus = eventBus ?? AppEventBus();

  @override
  Future<RecurringEvent?> createRecurringEvent(RecurringEvent event) async {
    try {
      // Convert event to map
      final eventData = event.toJson();
      
      // Reference to the master recurring event document
      final masterEventRef = _firestore.collection('recurring_events').doc(event.id);
      final globalEventRef = _firestore.collection('events').doc(event.id);
      
      // Create a batch to update both collections atomically
      final batch = _firestore.batch();
      
      // Set the master event data
      batch.set(masterEventRef, eventData);
      
      // Also set in the global events collection with a flag indicating it's recurring
      batch.set(globalEventRef, {
        ...eventData,
        'isRecurring': true,
      });
      
      // If this is a space/club event, also save it to the space's events collection
      if (event.spaceId != null && event.spaceId!.isNotEmpty) {
        // Determine the space type from the event
        final spaceType = _determineSpaceType(event);
        
        // Reference to the space's events collection
        final spaceEventRef = _firestore
            .collection('spaces')
            .doc(spaceType)
            .collection('spaces')
            .doc(event.spaceId)
            .collection('events')
            .doc(event.id);
            
        // Add to batch
        batch.set(spaceEventRef, eventData);
        
        // Update the space document to include this event ID
        final spaceRef = _firestore
            .collection('spaces')
            .doc(spaceType)
            .collection('spaces')
            .doc(event.spaceId);
            
        batch.update(spaceRef, {
          'eventIds': FieldValue.arrayUnion([event.id]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      // Pre-generate a number of event instances
      final instances = event.generateNextInstances(count: 10);
      
      // Save each instance (but maintain their recurring pattern link)
      for (final instance in instances) {
        final instanceData = instance.toJson();
        
        // Create a document in the instances subcollection for each instance
        final instanceRef = masterEventRef.collection('instances').doc(instance.id);
        batch.set(instanceRef, instanceData);
      }
      
      // Commit the batch
      await batch.commit();
      
      // Emit an event to notify subscribers
      _eventBus.emit(RecurringEventCreatedEvent(eventId: event.id));
      
      // Return the created event
      return event;
    } catch (e, stackTrace) {
      debugPrint('Error creating recurring event: $e');
      // Log error using FirebaseMonitor
      debugPrint('Error details: $e\n$stackTrace');
      return null;
    }
  }

  @override
  Future<RecurringEvent?> getRecurringEventById(String eventId) async {
    try {
      // First check the recurring_events collection
      final docSnapshot = await _firestore.collection('recurring_events').doc(eventId).get();
      
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        data['id'] = docSnapshot.id;
        
        // Process timestamps and convert to DateTime
        final processedData = _processTimestamps(data);
        return RecurringEvent.fromJson(processedData);
      }
      
      // If not found in recurring_events, check if it's an instance
      final instancesQuery = await _firestore
          .collectionGroup('instances')
          .where('id', isEqualTo: eventId)
          .limit(1)
          .get();
          
      if (instancesQuery.docs.isNotEmpty) {
        final instanceData = instancesQuery.docs.first.data();
        instanceData['id'] = instancesQuery.docs.first.id;
        
        // Process timestamps and convert to DateTime
        final processedData = _processTimestamps(instanceData);
        return RecurringEvent.fromJson(processedData);
      }
      
      return null;
    } catch (e, stackTrace) {
      debugPrint('Error getting recurring event by ID: $e');
      debugPrint('Error details: $e\n$stackTrace');
      return null;
    }
  }

  @override
  Future<List<RecurringEvent>> getUpcomingRecurringEvents({int limit = 20}) async {
    try {
      // Get current time
      final now = DateTime.now();
      final nowTimestamp = Timestamp.fromDate(now);
      
      // Query recurring events where start date is after now
      final snapshot = await _firestore
          .collection('recurring_events')
          .where('startDate', isGreaterThanOrEqualTo: nowTimestamp)
          .orderBy('startDate')
          .limit(limit)
          .get();
          
      // Convert to RecurringEvent objects
      final List<RecurringEvent> events = [];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          
          // Process timestamps and convert to DateTime
          final processedData = _processTimestamps(data);
          
          // Check if this has a recurrence pattern
          if (processedData.containsKey('recurrencePattern')) {
            final event = RecurringEvent.fromJson(processedData);
            events.add(event);
          }
        } catch (e) {
          debugPrint('Error processing recurring event ${doc.id}: $e');
        }
      }
      
      return events;
    } catch (e, stackTrace) {
      debugPrint('Error getting upcoming recurring events: $e');
      debugPrint('Error details: $e\n$stackTrace');
      return [];
    }
  }

  @override
  Future<List<RecurringEvent>> getRecurringEventInstances(String parentEventId, {int limit = 10}) async {
    try {
      // Query the instances subcollection
      final snapshot = await _firestore
          .collection('recurring_events')
          .doc(parentEventId)
          .collection('instances')
          .where('parentEventId', isEqualTo: parentEventId)
          .orderBy('startDate')
          .limit(limit)
          .get();
          
      // Convert to RecurringEvent objects
      final List<RecurringEvent> instances = [];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          
          // Process timestamps and convert to DateTime
          final processedData = _processTimestamps(data);
          final instance = RecurringEvent.fromJson(processedData);
          instances.add(instance);
        } catch (e) {
          debugPrint('Error processing recurring event instance ${doc.id}: $e');
        }
      }
      
      return instances;
    } catch (e, stackTrace) {
      debugPrint('Error getting recurring event instances: $e');
      debugPrint('Error details: $e\n$stackTrace');
      return [];
    }
  }

  @override
  Future<bool> updateRecurringEvent(RecurringEvent event, {bool updateAllInstances = false}) async {
    try {
      // Convert event to map
      final eventData = event.toJson();
      
      // Reference to the master recurring event document
      final masterEventRef = _firestore.collection('recurring_events').doc(event.id);
      final globalEventRef = _firestore.collection('events').doc(event.id);
      
      // Create a batch to update both collections atomically
      final batch = _firestore.batch();
      
      // Update the master event data
      batch.update(masterEventRef, eventData);
      
      // Also update in the global events collection
      batch.update(globalEventRef, eventData);
      
      // If this is a space/club event, also update it in the space's events collection
      if (event.spaceId != null && event.spaceId!.isNotEmpty) {
        // Determine the space type from the event
        final spaceType = _determineSpaceType(event);
        
        // Reference to the space's events collection
        final spaceEventRef = _firestore
            .collection('spaces')
            .doc(spaceType)
            .collection('spaces')
            .doc(event.spaceId)
            .collection('events')
            .doc(event.id);
            
        // Add to batch
        batch.update(spaceEventRef, eventData);
      }
      
      // If updateAllInstances is true, update future instances
      if (updateAllInstances) {
        // Get all future instances
        final now = DateTime.now();
        final nowTimestamp = Timestamp.fromDate(now);
        
        final instancesSnapshot = await masterEventRef
            .collection('instances')
            .where('startDate', isGreaterThanOrEqualTo: nowTimestamp)
            .get();
            
        // Update each instance with the new data but preserve instance-specific fields
        for (final doc in instancesSnapshot.docs) {
          final instanceData = doc.data();
          final instanceId = doc.id;
          
          // Update fields from the master event but preserve instance-specific fields
          final updatedInstanceData = {
            ...eventData,
            'id': instanceId,
            'parentEventId': event.id,
            'isModifiedInstance': instanceData['isModifiedInstance'] ?? false,
            'originalDate': instanceData['originalDate'],
          };
          
          // Add to batch
          batch.update(doc.reference, updatedInstanceData);
        }
      }
      
      // Commit the batch
      await batch.commit();
      
      // Emit an event to notify subscribers
      _eventBus.emit(RecurringEventUpdatedEvent(
        eventId: event.id, 
        updates: eventData,
        updatedAllInstances: updateAllInstances,
      ));
      
      return true;
    } catch (e, stackTrace) {
      debugPrint('Error updating recurring event: $e');
      debugPrint('Error details: $e\n$stackTrace');
      return false;
    }
  }

  @override
  Future<bool> updateEventInstance(RecurringEvent instance) async {
    try {
      // Ensure this is an instance
      if (instance.parentEventId == null) {
        throw Exception('Cannot update instance: parentEventId is null');
      }
      
      // Convert instance to map
      final instanceData = instance.toJson();
      
      // Set modified flag
      instanceData['isModifiedInstance'] = true;
      
      // Reference to the instance document
      final instanceRef = _firestore
          .collection('recurring_events')
          .doc(instance.parentEventId)
          .collection('instances')
          .doc(instance.id);
          
      // Update the instance
      await instanceRef.update(instanceData);
      
      // Emit an event to notify subscribers
      _eventBus.emit(EventInstanceUpdatedEvent(
        instanceId: instance.id,
        parentEventId: instance.parentEventId!,
        updates: instanceData,
      ));
      
      return true;
    } catch (e, stackTrace) {
      debugPrint('Error updating event instance: $e');
      debugPrint('Error details: $e\n$stackTrace');
      return false;
    }
  }

  @override
  Future<bool> cancelEventInstance(String instanceId, String parentEventId) async {
    try {
      // Reference to the instance document
      final instanceRef = _firestore
          .collection('recurring_events')
          .doc(parentEventId)
          .collection('instances')
          .doc(instanceId);
          
      // Get the instance
      final instanceDoc = await instanceRef.get();
      if (!instanceDoc.exists) {
        return false;
      }
      
      // Update the status to cancelled
      await instanceRef.update({
        'status': 'cancelled',
        'isModifiedInstance': true,
        'lastModified': FieldValue.serverTimestamp(),
      });
      
      // Emit an event to notify subscribers
      _eventBus.emit(EventInstanceCancelledEvent(
        instanceId: instanceId,
        parentEventId: parentEventId,
      ));
      
      return true;
    } catch (e, stackTrace) {
      debugPrint('Error cancelling event instance: $e');
      debugPrint('Error details: $e\n$stackTrace');
      return false;
    }
  }

  @override
  Future<bool> cancelRecurringEvent(String eventId, {DateTime? afterDate}) async {
    try {
      // Reference to the master event document
      final masterEventRef = _firestore.collection('recurring_events').doc(eventId);
      final globalEventRef = _firestore.collection('events').doc(eventId);
      
      // Create a batch
      final batch = _firestore.batch();
      
      // Update the master event status to cancelled
      batch.update(masterEventRef, {
        'status': 'cancelled',
        'lastModified': FieldValue.serverTimestamp(),
      });
      
      // Also update the global event
      batch.update(globalEventRef, {
        'status': 'cancelled',
        'lastModified': FieldValue.serverTimestamp(),
      });
      
      // If afterDate is provided, only cancel instances after that date
      if (afterDate != null) {
        final afterTimestamp = Timestamp.fromDate(afterDate);
        
        // Get instances after the specified date
        final instancesSnapshot = await masterEventRef
            .collection('instances')
            .where('startDate', isGreaterThanOrEqualTo: afterTimestamp)
            .get();
            
        // Cancel each instance
        for (final doc in instancesSnapshot.docs) {
          batch.update(doc.reference, {
            'status': 'cancelled',
            'isModifiedInstance': true,
            'lastModified': FieldValue.serverTimestamp(),
          });
        }
      } else {
        // Otherwise, cancel all instances
        final instancesSnapshot = await masterEventRef.collection('instances').get();
        
        // Cancel each instance
        for (final doc in instancesSnapshot.docs) {
          batch.update(doc.reference, {
            'status': 'cancelled',
            'isModifiedInstance': true,
            'lastModified': FieldValue.serverTimestamp(),
          });
        }
      }
      
      // Commit the batch
      await batch.commit();
      
      // Emit an event to notify subscribers
      _eventBus.emit(RecurringEventCancelledEvent(
        eventId: eventId,
        afterDate: afterDate,
      ));
      
      return true;
    } catch (e, stackTrace) {
      debugPrint('Error cancelling recurring event: $e');
      debugPrint('Error details: $e\n$stackTrace');
      return false;
    }
  }

  @override
  Future<List<RecurringEvent>> generateNewInstances(String eventId, {int count = 5}) async {
    try {
      // Get the master event
      final masterEventRef = _firestore.collection('recurring_events').doc(eventId);
      final masterEventDoc = await masterEventRef.get();
      
      if (!masterEventDoc.exists) {
        return [];
      }
      
      // Convert to RecurringEvent
      final masterEventData = masterEventDoc.data() as Map<String, dynamic>;
      masterEventData['id'] = masterEventDoc.id;
      
      // Process timestamps and convert to DateTime
      final processedData = _processTimestamps(masterEventData);
      final masterEvent = RecurringEvent.fromJson(processedData);
      
      // Get the most recent instance
      final instancesSnapshot = await masterEventRef
          .collection('instances')
          .orderBy('startDate', descending: true)
          .limit(1)
          .get();
          
      // Determine the start date for generating new instances
      DateTime startFrom;
      if (instancesSnapshot.docs.isNotEmpty) {
        // Use the most recent instance as the starting point
        final mostRecentInstance = instancesSnapshot.docs.first.data();
        final processedInstance = _processTimestamps(mostRecentInstance);
        startFrom = (processedInstance['startDate'] as DateTime).add(const Duration(minutes: 1));
      } else {
        // Use the master event's start date
        startFrom = masterEvent.startDate;
      }
      
      // Generate new instances
      final newInstances = masterEvent.recurrencePattern
          .generateNextOccurrences(startFrom, masterEvent.startDate, count: count)
          .map((date) => masterEvent.createInstance(date))
          .toList();
          
      // Save the new instances
      final batch = _firestore.batch();
      for (final instance in newInstances) {
        final instanceRef = masterEventRef
            .collection('instances')
            .doc(instance.id);
            
        batch.set(instanceRef, instance.toJson());
      }
      
      // Commit the batch
      await batch.commit();
      
      // Emit an event
      _eventBus.emit(RecurringEventInstancesGeneratedEvent(
        eventId: eventId,
        count: newInstances.length,
      ));
      
      return newInstances;
    } catch (e, stackTrace) {
      debugPrint('Error generating new instances: $e');
      debugPrint('Error details: $e\n$stackTrace');
      return [];
    }
  }

  @override
  Future<bool> saveRsvpStatusForInstance(String instanceId, String parentEventId, String userId, bool isAttending) async {
    try {
      // Reference to the instance document
      final instanceRef = _firestore
          .collection('recurring_events')
          .doc(parentEventId)
          .collection('instances')
          .doc(instanceId);
          
      // Get the instance
      final instanceDoc = await instanceRef.get();
      if (!instanceDoc.exists) {
        return false;
      }
      
      // Update the attendees array
      if (isAttending) {
        // Add user to attendees
        await instanceRef.update({
          'attendees': FieldValue.arrayUnion([userId]),
          'lastModified': FieldValue.serverTimestamp(),
        });
      } else {
        // Remove user from attendees
        await instanceRef.update({
          'attendees': FieldValue.arrayRemove([userId]),
          'lastModified': FieldValue.serverTimestamp(),
        });
      }
      
      // Update user's RSVP status in their profile
      final userRef = _firestore.collection('users').doc(userId);
      
      if (isAttending) {
        await userRef.update({
          'rsvpedEvents': FieldValue.arrayUnion([instanceId]),
        });
      } else {
        await userRef.update({
          'rsvpedEvents': FieldValue.arrayRemove([instanceId]),
        });
      }
      
      // Emit an event to notify subscribers
      _eventBus.emit(RsvpStatusChangedEvent(
        eventId: instanceId,
        userId: userId,
        isAttending: isAttending,
      ));
      
      return true;
    } catch (e, stackTrace) {
      debugPrint('Error saving RSVP status for instance: $e');
      debugPrint('Error details: $e\n$stackTrace');
      return false;
    }
  }

  /// Helper method to determine space type from an event
  String _determineSpaceType(Event event) {
    if (event.source == EventSource.club) {
      // Try to determine from category
      final category = event.category.toLowerCase();
      
      if (category.contains('fraternity') || category.contains('sorority') || category.contains('greek')) {
        return 'fraternity_and_sorority';
      } else if (category.contains('university') || category.contains('college')) {
        return 'university_organizations';
      } else if (category.contains('housing') || category.contains('residence') || category.contains('dorm')) {
        return 'campus_living';
      } else {
        // Default to student organizations
        return 'student_organizations';
      }
    }
    
    // Default type
    return 'student_organizations';
  }

  /// Process Firestore data to handle Timestamps
  Map<String, dynamic> _processTimestamps(Map<String, dynamic> data) {
    final result = Map<String, dynamic>.from(data);

    // Convert Timestamps to DateTime for serialization
    result.forEach((key, value) {
      if (value is Timestamp) {
        result[key] = value.toDate();
      } else if (value is Map) {
        result[key] = _processTimestamps(Map<String, dynamic>.from(value));
      }
    });

    return result;
  }
} 