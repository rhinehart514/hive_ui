import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/models/space.dart';
import 'package:hive_ui/models/space_metrics.dart';
import 'package:http/http.dart' as http;

/// PlatformIntegrationManager handles cross-feature integrations in the HIVE platform.
///
/// This class centralizes the integration points described in the platform overview document,
/// ensuring consistency and reliability when data changes in one feature affect other features.
class PlatformIntegrationManager {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final http.Client _httpClient;

  PlatformIntegrationManager({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    http.Client? httpClient,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _httpClient = httpClient ?? http.Client();

  http.Client get httpClient => _httpClient;

  /// Returns the current user ID or null if not authenticated
  String? get currentUserId => _auth.currentUser?.uid;

  /// Handles the complete RSVP journey, updating all connected systems.
  ///
  /// When a user RSVPs to an event, multiple systems need to be updated:
  /// 1. Event attendee list and count
  /// 2. User's saved events
  /// 3. Feed signals for social discovery
  /// 4. Space engagement metrics
  Future<bool> processEventRsvp({
    required String eventId,
    required bool attending,
    String? userId,
  }) async {
    try {
      final uid = userId ?? currentUserId;
      if (uid == null) {
        debugPrint('PlatformIntegrationManager: No authenticated user for RSVP');
        return false;
      }

      // Use a transaction to ensure data consistency across collections
      return await _firestore.runTransaction<bool>((transaction) async {
        // Get event document
        final eventDoc = await transaction.get(
          _firestore.collection('events').doc(eventId),
        );

        if (!eventDoc.exists) {
          debugPrint('PlatformIntegrationManager: Event $eventId not found');
          return false;
        }

        final eventData = eventDoc.data()!;
        final String spaceId = eventData['spaceId'] as String;
        final List<String> currentAttendees = 
            List<String>.from(eventData['attendees'] ?? []);

        // Update Event (1)
        if (attending && !currentAttendees.contains(uid)) {
          transaction.update(
            _firestore.collection('events').doc(eventId),
            {
              'attendees': FieldValue.arrayUnion([uid]),
              'attendeeCount': FieldValue.increment(1),
              'updatedAt': FieldValue.serverTimestamp(),
            },
          );
        } else if (!attending && currentAttendees.contains(uid)) {
          transaction.update(
            _firestore.collection('events').doc(eventId),
            {
              'attendees': FieldValue.arrayRemove([uid]),
              'attendeeCount': FieldValue.increment(-1),
              'updatedAt': FieldValue.serverTimestamp(),
            },
          );
        }

        // Update User's saved events (2)
        if (attending) {
          transaction.update(
            _firestore.collection('users').doc(uid),
            {
              'savedEvents': FieldValue.arrayUnion([eventId]),
              'updatedAt': FieldValue.serverTimestamp(),
            },
          );
        } else {
          transaction.update(
            _firestore.collection('users').doc(uid),
            {
              'savedEvents': FieldValue.arrayRemove([eventId]),
              'updatedAt': FieldValue.serverTimestamp(),
            },
          );
        }

        // Update Space engagement metrics (4)
        transaction.update(
          _firestore.collection('spaces').doc(spaceId),
          {
            'eventEngagementCount': FieldValue.increment(attending ? 1 : -1),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );

        return true;
      });
    } catch (e) {
      debugPrint('PlatformIntegrationManager: Error processing RSVP: $e');
      return false;
    }
  }

  /// Handles joining a Space, updating both the Space and user's profile.
  ///
  /// When a user joins a Space, multiple systems need to be updated:
  /// 1. Space's member list and count
  /// 2. User's joined Spaces list
  Future<bool> joinSpace({
    required String spaceId,
    String? userId,
  }) async {
    try {
      final uid = userId ?? currentUserId;
      if (uid == null) {
        debugPrint('PlatformIntegrationManager: No authenticated user for joining space');
        return false;
      }

      // Use a transaction to ensure data consistency
      return await _firestore.runTransaction<bool>((transaction) async {
        // Get space document
        final spaceDoc = await transaction.get(
          _firestore.collection('spaces').doc(spaceId),
        );

        if (!spaceDoc.exists) {
          debugPrint('PlatformIntegrationManager: Space $spaceId not found');
          return false;
        }

        // Update Space members
        transaction.update(
          _firestore.collection('spaces').doc(spaceId),
          {
            'members': FieldValue.arrayUnion([uid]),
            'memberCount': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );

        // Update User's joined spaces
        transaction.update(
          _firestore.collection('users').doc(uid),
          {
            'joinedSpaces': FieldValue.arrayUnion([spaceId]),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );

        return true;
      });
    } catch (e) {
      debugPrint('PlatformIntegrationManager: Error joining space: $e');
      return false;
    }
  }

  /// Creates an event in a Space, updating all relevant collections.
  ///
  /// When a new event is created:
  /// 1. Event is added to events collection
  /// 2. Space's event list is updated
  /// 3. Organizer's created events list is updated
  Future<String?> createSpaceEvent({
    required String spaceId,
    required String title,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    required String location,
    List<String> tags = const [],
    String? imageUrl,
  }) async {
    try {
      final uid = currentUserId;
      if (uid == null) {
        debugPrint('PlatformIntegrationManager: No authenticated user for creating event');
        return null;
      }

      // --- BEGIN ROLE VERIFICATION ---
      // Check if user has Verified+ status for this space
      final userSpaceRoleDoc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('spaceRoles')
          .doc(spaceId)
          .get();
      
      bool hasVerifiedPlusRole = false;
      
      if (userSpaceRoleDoc.exists) {
        final roleData = userSpaceRoleDoc.data();
        // Check for Verified+ role or admin/owner role
        hasVerifiedPlusRole = roleData != null && 
            (roleData['role'] == 'verified_plus' || 
             roleData['role'] == 'admin' || 
             roleData['role'] == 'owner');
      }
      
      // If not space-specific Verified+, check for global Verified+ status
      if (!hasVerifiedPlusRole) {
        final userDoc = await _firestore.collection('users').doc(uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          // Global verification status check
          hasVerifiedPlusRole = userData != null && 
              userData['verificationLevel'] == 'verified_plus';
        }
      }
      
      if (!hasVerifiedPlusRole) {
        debugPrint('PlatformIntegrationManager: User $uid does not have Verified+ role required to create events for space $spaceId');
        return null;
      }
      // --- END ROLE VERIFICATION ---
      
      // Define the time window for duplicate check (e.g., 5 minutes)
      const duplicateTimeWindow = Duration(minutes: 5);
      final startTimeWindowStart = startDate.subtract(duplicateTimeWindow);
      final startTimeWindowEnd = startDate.add(duplicateTimeWindow);

      // Query for potentially duplicate events
      final potentialDuplicates = await _firestore
          .collection('events')
          .where('spaceId', isEqualTo: spaceId)
          .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startTimeWindowStart))
          .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(startTimeWindowEnd))
          .limit(5) // Limit query results for performance
          .get();

      // Check if any potential duplicate has the same title (case-insensitive)
      if (potentialDuplicates.docs.isNotEmpty) {
        final normalizedNewTitle = title.trim().toLowerCase();
        final hasDuplicate = potentialDuplicates.docs.any((doc) {
           final docData = doc.data();
           final existingTitle = docData['title'] as String?;
           return existingTitle?.trim().toLowerCase() == normalizedNewTitle;
        });

        if (hasDuplicate) {
          debugPrint('PlatformIntegrationManager: Potential duplicate event creation detected for space $spaceId with title "$title" near start time $startDate. Aborting.');
          // Optionally throw a specific exception here instead of returning null
          // throw DuplicateEventException('Potential duplicate event detected.');
          return null;
        }
      }

      // Create the event document with a new ID
      final eventRef = _firestore.collection('events').doc();
      final eventId = eventRef.id;
      
      // Use a batch to update multiple collections
      final batch = _firestore.batch();
      
      // 1. Create the event
      batch.set(eventRef, {
        'id': eventId,
        'title': title,
        'description': description,
        'spaceId': spaceId,
        'organizerId': uid,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'location': location,
        'tags': tags,
        'imageUrl': imageUrl,
        'attendeeCount': 0,
        'attendees': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // 2. Update Space's event list
      batch.update(
        _firestore.collection('spaces').doc(spaceId),
        {
          'events': FieldValue.arrayUnion([eventId]),
          'eventCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
      
      // 3. Update organizer's created events
      batch.update(
        _firestore.collection('users').doc(uid),
        {
          'createdEvents': FieldValue.arrayUnion([eventId]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
      
      await batch.commit();
      return eventId;
    } catch (e) {
      debugPrint('PlatformIntegrationManager: Error creating event: $e');
      return null;
    }
  }

  /// Returns all spaces a user has joined.
  ///
  /// This integration point between Profiles and Spaces features allows
  /// getting a user's joined spaces for display on their profile.
  Future<List<Space>> getSpacesForUser(String userId) async {
    try {
      // Get the user document to find their joined spaces
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        return [];
      }
      
      final userData = userDoc.data()!;
      final List<String> joinedSpaceIds = List<String>.from(userData['joinedSpaces'] ?? []);
      
      if (joinedSpaceIds.isEmpty) {
        return [];
      }
      
      // Get the space documents
      final spaces = await _firestore
          .collection('spaces')
          .where(FieldPath.documentId, whereIn: joinedSpaceIds)
          .get();
      
      // Convert to Space objects
      return spaces.docs.map((doc) {
        final data = doc.data();
        final now = DateTime.now();
        
        // Parse icon
        IconData icon = Icons.group;
        if (data['iconCodePoint'] is int) {
          icon = IconData(
            data['iconCodePoint'] as int,
            fontFamily: 'MaterialIcons',
          );
        }

        // Create Space with all required parameters
        return Space(
          id: doc.id,
          name: data['name'] ?? '',
          description: data['description'] ?? '',
          icon: icon,
          imageUrl: data['imageUrl'],
          metrics: SpaceMetrics.initial(doc.id),
          createdAt: data['createdAt'] != null 
              ? (data['createdAt'] as Timestamp).toDate() 
              : now,
          updatedAt: data['updatedAt'] != null 
              ? (data['updatedAt'] as Timestamp).toDate() 
              : now,
        );
      }).toList();
    } catch (e) {
      debugPrint('PlatformIntegrationManager: Error getting spaces for user: $e');
      return [];
    }
  }

  /// Returns all events a user has RSVPed to.
  ///
  /// This integration point between Profiles and Events features gets
  /// a user's saved events for display on their profile.
  Future<List<Event>> getSavedEventsForUser(String userId) async {
    try {
      // Get the user document to find their saved events
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        return [];
      }
      
      final userData = userDoc.data()!;
      final savedEvents = userData['savedEvents'];
      
      // Early return if there are no saved events
      if (savedEvents == null || savedEvents is! List || savedEvents.isEmpty) {
        debugPrint('No saved events found for user $userId');
        return [];
      }

      // Handle both formats: arrays of IDs and arrays of event objects
      List<Event> results = [];
      List<String> eventIdsToFetch = [];
      
      // First, process any complete event objects in the array
      for (var item in savedEvents) {
        if (item is Map<String, dynamic>) {
          // This is a complete event object
          try {
            debugPrint('Processing saved event object with ID: ${item['id']}');
            results.add(Event.fromJson(item));
          } catch (e) {
            debugPrint('Error parsing event from savedEvents array: $e');
            // If we can't parse it as an event but it has an ID, add that ID to fetch later
            if (item['id'] != null) {
              eventIdsToFetch.add(item['id'].toString());
            }
          }
        } else if (item is String) {
          // This is just an event ID
          eventIdsToFetch.add(item);
        }
      }
      
      // If we have IDs to fetch, get those events
      if (eventIdsToFetch.isNotEmpty) {
        debugPrint('Fetching ${eventIdsToFetch.length} events by ID');
        
        // Firebase only allows 10 items in a whereIn query, so we may need to batch
        for (var i = 0; i < eventIdsToFetch.length; i += 10) {
          final end = (i + 10 < eventIdsToFetch.length) ? i + 10 : eventIdsToFetch.length;
          final batch = eventIdsToFetch.sublist(i, end);
          
          final querySnapshot = await _firestore
              .collection('events')
              .where(FieldPath.documentId, whereIn: batch)
              .get();
          
          for (var doc in querySnapshot.docs) {
            final data = doc.data();
            data['id'] = doc.id;
            try {
              results.add(Event.fromJson(data));
            } catch (e) {
              debugPrint('Error creating Event from Firestore: $e');
            }
          }
        }
      }
      
      debugPrint('Returning ${results.length} saved events for user $userId');
      return results;
    } catch (e) {
      debugPrint('PlatformIntegrationManager: Error getting saved events for user: $e');
      return [];
    }
  }

  /// Fetches upcoming events from spaces a user has joined.
  ///
  /// This method implements the Feed ↔ Spaces integration described in the platform overview:
  /// - Retrieves events from spaces the user follows
  /// - Applies relevance filtering based on user engagement with spaces
  /// - Provides a consistent content pipeline from spaces to feed
  Future<List<Event>> getEventsFromFollowedSpaces({
    required String userId,
    int limit = 20,
    DateTime? startDate,
  }) async {
    try {
      startDate ??= DateTime.now();
      
      // 1. Get the spaces the user has joined
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        return [];
      }
      
      final userData = userDoc.data()!;
      final List<String> followedSpaceIds = List<String>.from(userData['followedSpaces'] ?? []);
      
      if (followedSpaceIds.isEmpty) {
        return [];
      }
      
      // 2. Calculate user engagement metrics with each space
      Map<String, double> spaceEngagementScores = {};
      
      // This implements the "level of engagement with a Space affects how prominently its content appears"
      // concept mentioned in the platform overview
      for (final spaceId in followedSpaceIds) {
        double score = 1.0; // Base score for following
        
        // 2.1. Check user's event participation for this space
        try {
          final eventQuery = await _firestore
              .collection('events')
              .where('spaceId', isEqualTo: spaceId)
              .where('attendees', arrayContains: userId)
              .get();
          
          // Add 0.5 points for each event the user has RSVPed to from this space
          score += eventQuery.docs.length * 0.5;
          
          // 2.2. Check recent interactions (comments, etc.)
          final interactionQuery = await _firestore
              .collection('spaces')
              .doc(spaceId)
              .collection('userInteractions')
              .doc(userId)
              .get();
          
          if (interactionQuery.exists) {
            final interactionData = interactionQuery.data();
            // Add 0.2 points for each type of interaction
            if (interactionData != null) {
              score += (interactionData['viewCount'] ?? 0) * 0.05;
              score += (interactionData['commentCount'] ?? 0) * 0.2;
              score += (interactionData['likeCount'] ?? 0) * 0.1;
            }
          }
          
          // 2.3. Space membership duration
          final membershipDoc = await _firestore
              .collection('users')
              .doc(userId)
              .collection('spaces')
              .doc(spaceId)
              .get();
          
          if (membershipDoc.exists) {
            final memberData = membershipDoc.data();
            if (memberData != null && memberData['joinedAt'] != null) {
              final joinDate = (memberData['joinedAt'] as Timestamp).toDate();
              final daysSinceJoin = DateTime.now().difference(joinDate).inDays;
              // Longer membership gives up to 2 additional points
              score += (daysSinceJoin / 30).clamp(0.0, 2.0);
            }
          }
        } catch (e) {
          // If there's an error calculating engagement, use default score
          debugPrint('Error calculating engagement for space $spaceId: $e');
        }
        
        spaceEngagementScores[spaceId] = score;
      }
      
      // 3. Get events from these spaces with proper weighting
      const maxSpacesPerBatch = 10; // Firestore limit for "in" queries
      List<Event> allEvents = [];
      List<MapEntry<String?, Event>> allEntries = [];
      
      // Batch the space IDs if there are more than the Firestore limit
      for (int i = 0; i < followedSpaceIds.length; i += maxSpacesPerBatch) {
        final batchEnd = (i + maxSpacesPerBatch < followedSpaceIds.length) 
            ? i + maxSpacesPerBatch 
            : followedSpaceIds.length;
        
        final batchSpaceIds = followedSpaceIds.sublist(i, batchEnd);
        
        // Query for events from these spaces
        final eventsQuery = await _firestore
            .collection('events')
            .where('spaceId', whereIn: batchSpaceIds)
            .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
            .orderBy('startDate')
            .limit(limit * 2) // Get more than needed for proper weighting
            .get();
        
        // Parse events
        final batchEvents = eventsQuery.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          final spaceId = data['spaceId'] as String?;
          
          try {
            return MapEntry(
              spaceId,
              Event(
                id: doc.id,
                title: data['title'] ?? '',
                description: data['description'] ?? '',
                location: data['location'] ?? 'TBD',
                organizerEmail: data['organizerEmail'] ?? '',
                organizerName: data['organizerName'] ?? 'Unknown',
                category: data['category'] ?? 'Event',
                status: data['status'] ?? 'confirmed',
                link: data['link'] ?? '',
                startDate: data['startDate'] != null 
                    ? (data['startDate'] as Timestamp).toDate() 
                    : DateTime.now(),
                endDate: data['endDate'] != null 
                    ? (data['endDate'] as Timestamp).toDate() 
                    : DateTime.now().add(const Duration(hours: 2)),
                imageUrl: data['imageUrl'] ?? '',
                source: EventSource.external,
              )
            );
          } catch (e) {
            debugPrint('Error parsing event: $e');
            return null;
          }
        })
        .whereType<MapEntry<String?, Event>>() // Filter out nulls
        .toList();
        
        allEvents.addAll(batchEvents.map((entry) => entry.value));
        allEntries.addAll(batchEvents);
      }
      
      // 4. Apply the engagement-based weighting to sort events
      final sortedEvents = allEvents.toList();
      
      final eventMap = Map.fromEntries(
        allEntries.where((entry) => entry.key != null)
          .map((entry) => MapEntry(entry.value.id, entry.key))
      );
      
      sortedEvents.sort((a, b) {
        final spaceIdA = eventMap[a.id];
        final spaceIdB = eventMap[b.id];
        
        final scoreA = spaceIdA != null ? (spaceEngagementScores[spaceIdA] ?? 1.0) : 0.0;
        final scoreB = spaceIdB != null ? (spaceEngagementScores[spaceIdB] ?? 1.0) : 0.0;
        
        // First compare by engagement score
        final scoreCompare = scoreB.compareTo(scoreA);
        if (scoreCompare != 0) return scoreCompare;
        
        // If scores are equal, sort by date
        return a.startDate.compareTo(b.startDate);
      });
      
      // 5. Return the top events based on limit
      return sortedEvents.take(limit).toList();
    } catch (e) {
      debugPrint('PlatformIntegrationManager: Error getting events from followed spaces: $e');
      return [];
    }
  }
  
  /// Gets space engagement metrics for a user.
  ///
  /// This enables the "level of engagement with a Space affects how prominently its content appears"
  /// feature described in the platform overview.
  Future<Map<String, double>> getSpaceEngagementScores(String userId) async {
    try {
      // Get the spaces the user has joined
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        return {};
      }
      
      final userData = userDoc.data()!;
      final List<String> followedSpaceIds = List<String>.from(userData['followedSpaces'] ?? []);
      
      if (followedSpaceIds.isEmpty) {
        return {};
      }
      
      // Calculate engagement scores
      Map<String, double> spaceEngagementScores = {};
      
      for (final spaceId in followedSpaceIds) {
        double score = 1.0; // Base score for following
        
        // Check event participation
        try {
          final eventQuery = await _firestore
              .collection('events')
              .where('spaceId', isEqualTo: spaceId)
              .where('attendees', arrayContains: userId)
              .get();
          
          score += eventQuery.docs.length * 0.5;
          
          // Check recent interactions (comments, etc.)
          final interactionQuery = await _firestore
              .collection('spaces')
              .doc(spaceId)
              .collection('userInteractions')
              .doc(userId)
              .get();
          
          if (interactionQuery.exists) {
            final interactionData = interactionQuery.data();
            if (interactionData != null) {
              score += (interactionData['viewCount'] ?? 0) * 0.05;
              score += (interactionData['commentCount'] ?? 0) * 0.2;
              score += (interactionData['likeCount'] ?? 0) * 0.1;
            }
          }
          
          // Space membership duration
          final membershipDoc = await _firestore
              .collection('users')
              .doc(userId)
              .collection('spaces')
              .doc(spaceId)
              .get();
          
          if (membershipDoc.exists) {
            final memberData = membershipDoc.data();
            if (memberData != null && memberData['joinedAt'] != null) {
              final joinDate = (memberData['joinedAt'] as Timestamp).toDate();
              final daysSinceJoin = DateTime.now().difference(joinDate).inDays;
              score += (daysSinceJoin / 30).clamp(0.0, 2.0);
            }
          }
        } catch (e) {
          debugPrint('Error calculating engagement for space $spaceId: $e');
        }
        
        spaceEngagementScores[spaceId] = score;
      }
      
      return spaceEngagementScores;
    } catch (e) {
      debugPrint('PlatformIntegrationManager: Error getting space engagement scores: $e');
      return {};
    }
  }

  void dispose() {
    _httpClient.close();
  }
} 