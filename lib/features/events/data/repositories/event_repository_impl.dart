import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive_ui/features/events/domain/repositories/event_repository.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/models/attendance_record.dart';
import 'package:hive_ui/services/firebase_monitor.dart';

/// Implementation of the EventRepository using Firestore as data source
class EventRepositoryImpl implements EventRepository {
  final FirebaseFirestore _firestore;

  /// Constructor
  EventRepositoryImpl({FirebaseFirestore? firestore}) 
    : _firestore = firestore ?? FirebaseFirestore.instance;
    
  @override
  Future<Map<String, dynamic>> fetchEvents({
    bool forceRefresh = false,
    int page = 1,
    int pageSize = 20,
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  }) async {
    try {
      debugPrint('🔍 REPOSITORY: Fetching events from Firestore (page: $page, pageSize: $pageSize)');
      
      // Build the query with applied filters
      Query query = _firestore.collection('events');
      debugPrint('🔍 REPOSITORY: Using collection path: ${_firestore.collection('events').path}');
      
      // We want to show recent but also upcoming events
      // For the feed, we'll show events from 7 days ago to include recent ones
      final now = DateTime.now();
      final effectiveStartDate = startDate ?? 
          now.subtract(const Duration(days: 7)); // Show events from last 7 days too
      
      debugPrint('🔍 REPOSITORY: Using effective start date: $effectiveStartDate');
      
      // First try to get events with startDate filter
      var snapshot = await _tryFetchWithStartDate(query, effectiveStartDate, endDate, category, pageSize, page);
      
      // If we got no results, try with endDate filter instead (to show ongoing events)
      if (snapshot.docs.isEmpty) {
        debugPrint('🔍 REPOSITORY: No events found with startDate filter, trying endDate filter...');
        query = _firestore.collection('events');
        
        // Get events that haven't ended yet
        query = query.where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now));
        
        if (category != null && category.isNotEmpty) {
          query = query.where('category', isEqualTo: category);
        }
        
        query = query.orderBy('endDate').limit(pageSize * page);
        FirebaseMonitor.recordRead();
        snapshot = await query.get();
        
        debugPrint('🔍 REPOSITORY: Retrieved ${snapshot.docs.length} events with endDate filter');
      }
      
      // If we still have no results, try without date filters
      if (snapshot.docs.isEmpty) {
        debugPrint('🔍 REPOSITORY: No events found with any date filters, trying without filters...');
        query = _firestore.collection('events');
        
        if (category != null && category.isNotEmpty) {
          query = query.where('category', isEqualTo: category);
        }
        
        query = query.orderBy('startDate', descending: true).limit(pageSize * page);
        FirebaseMonitor.recordRead();
        snapshot = await query.get();
        
        debugPrint('🔍 REPOSITORY: Retrieved ${snapshot.docs.length} events without date filters');
      }
      
      // If we still have no results after trying all filters, create test data
      if (snapshot.docs.isEmpty && forceRefresh) {
        debugPrint('🔍 REPOSITORY: No events found, generating test events...');
        await _createTestEvents();
        
        // Try querying again after creating test events
        query = _firestore.collection('events');
        query = query.orderBy('startDate', descending: true).limit(pageSize * page);
        FirebaseMonitor.recordRead();
        snapshot = await query.get();
        
        debugPrint('🔍 REPOSITORY: Retrieved ${snapshot.docs.length} test events');
      }
      
      // Convert to Event objects
      final List<Event> events = [];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id; // Ensure ID is set
          
          debugPrint('🔍 REPOSITORY: Processing event: ${doc.id}');
          
          // Process timestamps and convert to DateTime
          final processedData = _processTimestamps(data);
          final event = Event.fromJson(processedData);
          events.add(event);
          
          debugPrint('🔍 REPOSITORY: Added event: ${event.title} (${event.id})');
        } catch (e) {
          debugPrint('❌ REPOSITORY: Error processing event ${doc.id}: $e');
        }
      }
      
      // Sort events by start date (upcoming events first)
      events.sort((a, b) => a.startDate.compareTo(b.startDate));
      
      // Calculate if there are more pages
      final bool hasMore = events.length >= pageSize * page;
      
      debugPrint('🔍 REPOSITORY: Returning ${events.length} events, hasMore: $hasMore');
      
      return {
        'events': events,
        'totalCount': events.length,
        'hasMore': hasMore,
        'page': page,
      };
    } catch (e) {
      debugPrint('❌ REPOSITORY: Error fetching events: $e');
      return {
        'events': <Event>[],
        'totalCount': 0,
        'hasMore': false,
        'page': page,
        'error': e.toString(),
      };
    }
  }
  
  /// Try to fetch events with startDate filter
  Future<QuerySnapshot> _tryFetchWithStartDate(
    Query baseQuery,
    DateTime startDate,
    DateTime? endDate,
    String? category,
    int pageSize,
    int page,
  ) async {
    // Convert DateTime to Timestamp for Firestore query
    final startTimestamp = Timestamp.fromDate(startDate);
    var query = baseQuery.where('startDate', isGreaterThanOrEqualTo: startTimestamp);
    debugPrint('🔍 REPOSITORY: Applied start date filter: $startDate');

    // Apply end date filter if provided
    if (endDate != null) {
      final endTimestamp = Timestamp.fromDate(endDate);
      query = query.where('endDate', isLessThanOrEqualTo: endTimestamp);
      debugPrint('🔍 REPOSITORY: Applied end date filter: $endDate');
    }
    
    // Apply category filter if provided
    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
      debugPrint('🔍 REPOSITORY: Applied category filter: $category');
    }
    
    // Apply ordering and pagination
    query = query.orderBy('startDate').limit(pageSize * page);
    
    debugPrint('🔍 REPOSITORY: Executing query with limit: ${pageSize * page}');
    
    // Monitor Firebase reads for optimization
    FirebaseMonitor.recordRead();
    
    // Execute the query
    return query.get();
  }
  
  /// Create test events for development purposes
  Future<void> _createTestEvents() async {
    debugPrint('🔍 REPOSITORY: Creating test events...');
    
    final now = DateTime.now();
    final batch = _firestore.batch();
    
    // Generate a mix of upcoming and recent past events
    final List<Map<String, dynamic>> testEvents = [
      // Upcoming events (sorted by date)
      {
        'title': 'CS Department Welcome Party',
        'description': 'Join us for the start of the semester with food, games, and networking with faculty and students.',
        'location': 'CS Building, Room 101',
        'startDate': now.add(const Duration(days: 2, hours: 3)),
        'endDate': now.add(const Duration(days: 2, hours: 6)),
        'organizerName': 'CS Department',
        'organizerEmail': 'cs@university.edu',
        'category': 'Social',
        'status': 'Confirmed',
        'tags': ['cs', 'welcome', 'party'],
        'imageUrl': 'https://firebasestorage.googleapis.com/v0/b/hive-flutter.appspot.com/o/placeholder%2Fcs_welcome.jpg?alt=media',
        'attendees': ['user1', 'user2'],
        'createdAt': now.subtract(const Duration(days: 10)),
      },
      {
        'title': 'Career Fair 2023',
        'description': 'Meet with top employers looking to hire students for internships and full-time positions.',
        'location': 'Student Union, Grand Ballroom',
        'startDate': now.add(const Duration(days: 5)),
        'endDate': now.add(const Duration(days: 5, hours: 4)),
        'organizerName': 'Career Services',
        'organizerEmail': 'careers@university.edu',
        'category': 'Career',
        'status': 'Confirmed',
        'tags': ['career', 'networking', 'jobs'],
        'imageUrl': 'https://firebasestorage.googleapis.com/v0/b/hive-flutter.appspot.com/o/placeholder%2Fcareer_fair.jpg?alt=media',
        'attendees': ['user3'],
        'createdAt': now.subtract(const Duration(days: 15)),
      },
      {
        'title': 'AI Workshop Series: Machine Learning Basics',
        'description': 'First in a series of workshops on AI. This session covers ML fundamentals.',
        'location': 'Engineering Building, Lab 204',
        'startDate': now.add(const Duration(days: 1, hours: 2)),
        'endDate': now.add(const Duration(days: 1, hours: 4)),
        'organizerName': 'AI Club',
        'organizerEmail': 'ai@university.edu',
        'category': 'Academic',
        'status': 'Confirmed',
        'tags': ['ai', 'workshop', 'machine learning'],
        'imageUrl': 'https://firebasestorage.googleapis.com/v0/b/hive-flutter.appspot.com/o/placeholder%2Fai_workshop.jpg?alt=media',
        'attendees': [],
        'createdAt': now.subtract(const Duration(days: 5)),
      },
      // Recent past events
      {
        'title': 'Hackathon 2023',
        'description': '24-hour coding competition with prizes for the best projects.',
        'location': 'Tech Center',
        'startDate': now.subtract(const Duration(days: 3)),
        'endDate': now.subtract(const Duration(days: 2)),
        'organizerName': 'Tech Club',
        'organizerEmail': 'tech@university.edu',
        'category': 'Competition',
        'status': 'Completed',
        'tags': ['hackathon', 'coding', 'competition'],
        'imageUrl': 'https://firebasestorage.googleapis.com/v0/b/hive-flutter.appspot.com/o/placeholder%2Fhackathon.jpg?alt=media',
        'attendees': ['user1', 'user4', 'user5'],
        'createdAt': now.subtract(const Duration(days: 30)),
      },
      {
        'title': 'Campus Concert: The Collegians',
        'description': 'Live music from our campus band featuring new songs.',
        'location': 'Outdoor Amphitheater',
        'startDate': now.subtract(const Duration(days: 1)),
        'endDate': now.subtract(const Duration(hours: 20)),
        'organizerName': 'Music Department',
        'organizerEmail': 'music@university.edu',
        'category': 'Entertainment',
        'status': 'Completed',
        'tags': ['music', 'concert', 'campus'],
        'imageUrl': 'https://firebasestorage.googleapis.com/v0/b/hive-flutter.appspot.com/o/placeholder%2Fcampus_concert.jpg?alt=media',
        'attendees': ['user2', 'user3'],
        'createdAt': now.subtract(const Duration(days: 7)),
      },
    ];
    
    // Add each event to the batch
    for (final eventData in testEvents) {
      final docRef = _firestore.collection('events').doc();
      
      // Convert DateTime fields to Timestamp for Firestore
      final firestoreData = Map<String, dynamic>.from(eventData);
      firestoreData['startDate'] = Timestamp.fromDate(eventData['startDate'] as DateTime);
      firestoreData['endDate'] = Timestamp.fromDate(eventData['endDate'] as DateTime);
      firestoreData['createdAt'] = Timestamp.fromDate(eventData['createdAt'] as DateTime);
      
      // Add to batch
      batch.set(docRef, firestoreData);
      debugPrint('🔍 REPOSITORY: Added test event to batch: ${eventData['title']}');
    }
    
    // Commit the batch
    await batch.commit();
    FirebaseMonitor.recordRead();
    debugPrint('🔍 REPOSITORY: Test events created successfully');
  }
  
  @override
  Future<Event?> getEventById(String eventId) async {
    try {
      // First try to get from the global events collection
      final docSnapshot = await _firestore.collection('events').doc(eventId).get();
      
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        data['id'] = docSnapshot.id;
        
        // Process timestamps and convert to DateTime
        final processedData = _processTimestamps(data);
        return Event.fromJson(processedData);
      }
      
      // If not found in global collection, the event might be in a space subcollection
      // This would require checking all space types and spaces, which is inefficient
      // For now, we'll return null and consider adding a more efficient lookup later
      return null;
    } catch (e) {
      debugPrint('Error getting event by ID: $e');
      return null;
    }
  }
  
  @override
  Future<List<Event>> getEventsForSpace(String spaceId, String spaceType) async {
    try {
      // Build path to space events
      final eventsRef = _firestore
          .collection('spaces')
          .doc(spaceType)
          .collection('spaces')
          .doc(spaceId)
          .collection('events');
      
      // Get events that haven't ended yet
      final now = DateTime.now();
      final nowTimestamp = Timestamp.fromDate(now);
      
      final snapshot = await eventsRef
          .where('endDate', isGreaterThanOrEqualTo: nowTimestamp)
          .orderBy('endDate')
          .get();
      
      // Convert to Event objects
      final List<Event> events = [];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          
          // Process timestamps and convert to DateTime
          final processedData = _processTimestamps(data);
          final event = Event.fromJson(processedData);
          events.add(event);
        } catch (e) {
          debugPrint('Error processing event ${doc.id}: $e');
        }
      }
      
      return events;
    } catch (e) {
      debugPrint('Error getting events for space: $e');
      return [];
    }
  }
  
  @override
  Future<bool> saveRsvpStatus(String eventId, String userId, bool isAttending) async {
    try {
      // Update the user's saved events collection
      final userEventRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('savedEvents')
          .doc(eventId);
      
      if (isAttending) {
        // Save the event
        await userEventRef.set({
          'eventId': eventId,
          'savedAt': FieldValue.serverTimestamp(),
        });
        
        // Also update the event's attendees list
        final eventRef = _firestore.collection('events').doc(eventId);
        await eventRef.update({
          'attendees': FieldValue.arrayUnion([userId]),
        });
      } else {
        // Remove the event
        await userEventRef.delete();
        
        // Also update the event's attendees list
        final eventRef = _firestore.collection('events').doc(eventId);
        await eventRef.update({
          'attendees': FieldValue.arrayRemove([userId]),
        });
      }
      
      return true;
    } catch (e) {
      debugPrint('Error saving RSVP status: $e');
      return false;
    }
  }
  
  @override
  Future<List<Event>> getTrendingEvents({int limit = 10}) async {
    try {
      // Get events with the most attendees
      final snapshot = await _firestore
          .collection('events')
          .orderBy('attendees', descending: true)
          .limit(limit)
          .get();
      
      // Convert to Event objects
      final List<Event> events = [];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          
          // Process timestamps and convert to DateTime
          final processedData = _processTimestamps(data);
          final event = Event.fromJson(processedData);
          events.add(event);
        } catch (e) {
          debugPrint('Error processing event ${doc.id}: $e');
        }
      }
      
      return events;
    } catch (e) {
      debugPrint('Error getting trending events: $e');
      return [];
    }
  }
  
  @override
  Future<List<Event>> getEventsForFollowedSpaces(List<String> spaceIds, {int limit = 20}) async {
    if (spaceIds.isEmpty) {
      return [];
    }
    
    try {
      // We need to query the global events collection filtered by spaceId
      // This requires that events have a spaceId field
      final snapshot = await _firestore
          .collection('events')
          .where('spaceId', whereIn: spaceIds.take(10).toList()) // Firestore limits to 10 values
          .orderBy('startDate')
          .limit(limit)
          .get();
      
      // Convert to Event objects
      final List<Event> events = [];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          
          // Process timestamps and convert to DateTime
          final processedData = _processTimestamps(data);
          final event = Event.fromJson(processedData);
          events.add(event);
        } catch (e) {
          debugPrint('Error processing event ${doc.id}: $e');
        }
      }
      
      return events;
    } catch (e) {
      debugPrint('Error getting events for followed spaces: $e');
      return [];
    }
  }
  
  @override
  Future<bool> boostEvent(String eventId, String userId) async {
    try {
      // Get the current event to ensure it exists
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) {
        debugPrint('❌ REPOSITORY: Boost failed - Event $eventId does not exist');
        return false;
      }

      // Check user permissions (implement role-based check here if needed)
      // For now, assuming userId is already verified to have Verified+ status
      
      // Update the event with boost information
      await _firestore.collection('events').doc(eventId).update({
        'isBoosted': true,
        'boostTimestamp': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastModifiedBy': userId,
      });
      
      // Add boost record for tracking/auditability
      await _firestore
          .collection('events')
          .doc(eventId)
          .collection('boosts')
          .add({
        'boosterId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ REPOSITORY: Event $eventId boosted successfully by $userId');
      return true;
    } catch (e) {
      debugPrint('❌ REPOSITORY: Error boosting event $eventId: $e');
      return false;
    }
  }

  @override
  Future<bool> setEventHoneyMode(String eventId, String userId) async {
    try {
      // Get the current event to ensure it exists and get spaceId
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) {
        debugPrint('❌ REPOSITORY: Honey Mode failed - Event $eventId does not exist');
        return false;
      }
      
      final eventData = eventDoc.data() as Map<String, dynamic>;
      final spaceId = eventData['spaceId'] as String?;
      
      if (spaceId == null) {
        debugPrint('❌ REPOSITORY: Honey Mode failed - Event $eventId has no spaceId');
        return false;
      }
      
      // Check if honey mode is available for this space
      final isAvailable = await isHoneyModeAvailable(spaceId);
      if (!isAvailable) {
        debugPrint('❌ REPOSITORY: Honey Mode failed - Space $spaceId has already used Honey Mode this month');
        return false;
      }
      
      // Update the event with honey mode information
      await _firestore.collection('events').doc(eventId).update({
        'isHoneyMode': true,
        'honeyModeTimestamp': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastModifiedBy': userId,
      });
      
      // Record honey mode usage for the space for the current month
      final now = DateTime.now();
      final yearMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      
      await _firestore
          .collection('spaces')
          .doc(spaceId)
          .collection('honeyModeUsage')
          .doc(yearMonth)
          .set({
        'used': true,
        'eventId': eventId,
        'timestamp': FieldValue.serverTimestamp(),
        'activatedBy': userId,
      });
      
      debugPrint('✅ REPOSITORY: Honey Mode activated for event $eventId by $userId');
      return true;
    } catch (e) {
      debugPrint('❌ REPOSITORY: Error setting Honey Mode for event $eventId: $e');
      return false;
    }
  }

  @override
  Future<bool> isHoneyModeAvailable(String spaceId) async {
    try {
      // Get the space document
      final spaceDoc = await _firestore.collection('spaces').doc(spaceId).get();
      FirebaseMonitor.recordRead();
      
      if (!spaceDoc.exists) {
        return false;
      }
      
      final spaceData = spaceDoc.data() as Map<String, dynamic>;
      
      // Check if the space has honey mode allocations available
      final int honeyModeUsed = spaceData['honeyModeUsed'] ?? 0;
      final int honeyModeAllocation = spaceData['honeyModeAllocation'] ?? 1; // Default 1 per month
      
      return honeyModeUsed < honeyModeAllocation;
    } catch (e) {
      debugPrint('❌ REPOSITORY: Error checking honey mode availability: $e');
      return false;
    }
  }
  
  @override
  Future<bool> recordAttendance(String eventId, AttendanceRecord attendanceRecord) async {
    try {
      debugPrint('🔍 REPOSITORY: Recording attendance for event $eventId by user ${attendanceRecord.userId}');
      
      // Get the current event document
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      FirebaseMonitor.recordRead();
      
      if (!eventDoc.exists) {
        debugPrint('❌ REPOSITORY: Event $eventId not found');
        return false;
      }
      
      final eventData = eventDoc.data() as Map<String, dynamic>;
      
      // Get the current attendance map or create a new one
      Map<String, dynamic> attendanceMap = eventData['attendance'] ?? {};
      
      // Add the new attendance record
      attendanceMap[attendanceRecord.userId] = attendanceRecord.toJson();
      
      // Update the event document with the new attendance map
      await _firestore.collection('events').doc(eventId).update({
        'attendance': attendanceMap,
      });
      FirebaseMonitor.recordRead();
      
      // Also record this attendance in a separate collection for analytics
      await _firestore.collection('event_attendance').add({
        'eventId': eventId,
        'userId': attendanceRecord.userId,
        'timestamp': FieldValue.serverTimestamp(),
        'verificationMethod': attendanceRecord.verificationMethod.toString().split('.').last,
        'verificationData': attendanceRecord.verificationData,
      });
      FirebaseMonitor.recordRead();
      
      debugPrint('✅ REPOSITORY: Successfully recorded attendance for event $eventId');
      return true;
    } catch (e) {
      debugPrint('❌ REPOSITORY: Error recording attendance: $e');
      return false;
    }
  }
  
  @override
  Future<bool> validateCheckInCode(String eventId, String code) async {
    try {
      debugPrint('🔍 REPOSITORY: Validating check-in code for event $eventId');
      
      // Get the event's check-in code from Firestore
      final codeDoc = await _firestore
          .collection('event_check_in_codes')
          .where('eventId', isEqualTo: eventId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      FirebaseMonitor.recordRead();
      
      if (codeDoc.docs.isEmpty) {
        debugPrint('❌ REPOSITORY: No active check-in code found for event $eventId');
        return false;
      }
      
      final codeData = codeDoc.docs.first.data();
      final storedCode = codeData['code'] as String?;
      
      // Check if the code has expired
      final createdAt = (codeData['createdAt'] as Timestamp).toDate();
      final expiresInMinutes = codeData['expiresInMinutes'] as int? ?? 15;
      
      final now = DateTime.now();
      final expirationTime = createdAt.add(Duration(minutes: expiresInMinutes));
      
      if (now.isAfter(expirationTime)) {
        debugPrint('❌ REPOSITORY: Check-in code for event $eventId has expired');
        return false;
      }
      
      // Compare with the provided code
      return storedCode == code;
    } catch (e) {
      debugPrint('❌ REPOSITORY: Error validating check-in code: $e');
      return false;
    }
  }
  
  @override
  Future<String> generateCheckInCode(String eventId, String generatedBy) async {
    try {
      debugPrint('🔍 REPOSITORY: Generating check-in code for event $eventId');
      
      // First, deactivate any existing codes for this event
      final existingCodes = await _firestore
          .collection('event_check_in_codes')
          .where('eventId', isEqualTo: eventId)
          .where('isActive', isEqualTo: true)
          .get();
      FirebaseMonitor.recordRead();
      
      final batch = _firestore.batch();
      for (final doc in existingCodes.docs) {
        batch.update(doc.reference, {'isActive': false});
      }
      await batch.commit();
      FirebaseMonitor.recordRead();
      
      // Generate a new code (6-digit number)
      final code = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
      
      // Store the new code
      await _firestore.collection('event_check_in_codes').add({
        'eventId': eventId,
        'code': code,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': generatedBy,
        'isActive': true,
        'expiresInMinutes': 15, // Code expires after 15 minutes
      });
      FirebaseMonitor.recordRead();
      
      debugPrint('✅ REPOSITORY: Successfully generated check-in code for event $eventId');
      return code;
    } catch (e) {
      debugPrint('❌ REPOSITORY: Error generating check-in code: $e');
      throw Exception('Failed to generate check-in code: $e');
    }
  }
  
  /// Helper method to process Firestore timestamps into DateTime
  Map<String, dynamic> _processTimestamps(Map<String, dynamic> data) {
    final result = Map<String, dynamic>.from(data);

    // Convert Timestamps to ISO strings for serialization
    result.forEach((key, value) {
      if (value is Timestamp) {
        result[key] = value.toDate().toIso8601String();
      } else if (value is Map) {
        result[key] = _processTimestamps(Map<String, dynamic>.from(value));
      }
    });

    return result;
  }
} 