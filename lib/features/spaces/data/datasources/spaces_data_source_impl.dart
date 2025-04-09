import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_ui/features/spaces/data/datasources/spaces_data_source.dart';
import 'package:hive_ui/features/spaces/data/models/space_model.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_member_entity.dart';
import 'package:hive_ui/models/event.dart';

/// Implementation of SpacesDataSource that uses Firebase Firestore
class SpacesDataSourceImpl implements SpacesDataSource {
  /// Firebase instances
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  
  /// Cache-related constants and variables
  static const String _spacesPrefsKey = 'spaces_cache';
  static const String _lastFetchTimestampKey = 'spaces_last_fetch';
  static const Duration _cacheValidDuration = Duration(hours: 6);
  static final Map<String, SpaceModel> _spaceCache = {};
  
  /// Constructor
  SpacesDataSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;
  
  /// Get all spaces from Firestore with optional caching
  @override
  Future<List<SpaceModel>> getAllSpaces({
    bool forceRefresh = false,
    bool includePrivate = false,
    bool includeJoined = true,
    String? userId,
  }) async {
    try {
      final List<SpaceModel> spaces = [];
      final List<String> spaceTypes = [
        'student_organizations',
        'university',
        'campus_living',
        'greek_life',
        'hive_exclusive',
        'other',
      ];
      
      // Fetch spaces from each collection
      for (final type in spaceTypes) {
        final collectionPath = 'spaces/$type/spaces';
        final querySnapshot = await _firestore
            .collection(collectionPath)
            .orderBy('createdAt', descending: true)
            .limit(100)
            .get();
            
        for (final doc in querySnapshot.docs) {
          final space = SpaceModel.fromFirestore(doc);
          spaces.add(space);
        }
      }
      
      // Filter spaces based on parameters
      List<String> joinedSpaceIds = [];
      if (!includeJoined && userId != null) {
        joinedSpaceIds = await _getJoinedSpaceIds(userId: userId);
      }
      
      return spaces.where((space) {
        // Filter private spaces
        if (space.isPrivate && !includePrivate) {
          return false;
        }
        
        // Filter joined spaces if needed and userId is available
        if (!includeJoined && userId != null && joinedSpaceIds.contains(space.id)) {
          return false;
        }
        
        return true;
      }).toList();
    } catch (e) {
      debugPrint('Error fetching spaces: $e');
      return [];
    }
  }
  
  /// Get a space by ID with optional space type
  @override
  Future<SpaceModel?> getSpaceById(String id, {String? spaceType}) async {
    try {
      // Check cache first
      if (_spaceCache.containsKey(id)) {
        return _spaceCache[id];
      }
      
      // If spaceType is provided, look directly in that collection
      if (spaceType != null) {
        final collectionPath = 'spaces/$spaceType/spaces';
        final docSnapshot = await _firestore
            .collection(collectionPath)
            .doc(id)
            .get();
            
        if (docSnapshot.exists) {
          final space = SpaceModel.fromFirestore(docSnapshot);
          // Update cache
          _spaceCache[id] = space;
          return space;
        }
      }
      
      // If not found or spaceType not provided, search in all collections
      final List<String> spaceTypes = [
        'student_organizations',
        'university',
        'campus_living',
        'greek_life',
        'hive_exclusive',
        'other',
      ];
      
      for (final type in spaceTypes) {
        // Skip if we already checked this type
        if (type == spaceType) continue;
        
        try {
          final collectionPath = 'spaces/$type/spaces';
          final docSnapshot = await _firestore
              .collection(collectionPath)
              .doc(id)
              .get();
              
          if (docSnapshot.exists) {
            final space = SpaceModel.fromFirestore(docSnapshot);
            // Update cache
            _spaceCache[id] = space;
            return space;
          }
        } catch (e) {
          debugPrint('Error checking space $id in $type: $e');
          // Continue to next type
        }
      }
      
      debugPrint('Space $id not found in any collection');
      return null;
    } catch (e) {
      debugPrint('Error getting space by ID: $e');
      return null;
    }
  }
  
  /// Get spaces by category
  @override
  Future<List<SpaceModel>> getSpacesByCategory(String category) async {
    try {
      // First load all spaces
      final allSpaces = await getAllSpaces();
      
      // Filter by category
      return allSpaces
          .where((space) => space.tags.contains(category.toLowerCase()))
          .toList();
    } catch (e) {
      debugPrint('Error fetching spaces by category: $e');
      return [];
    }
  }
  
  /// Get all spaces joined by the current user
  @override
  Future<List<SpaceModel>> getJoinedSpaces({String? userId}) async {
    try {
      final uid = userId ?? _auth.currentUser?.uid;
      if (uid == null) {
        return [];
      }
      
      // Get the list of space IDs the user has joined
      final joinedSpaceIds = await _getJoinedSpaceIds(userId: uid);
      
      // Fetch each space by ID
      final List<SpaceModel> joinedSpaces = [];
      for (final spaceId in joinedSpaceIds) {
        final space = await getSpaceById(spaceId);
        if (space != null) {
          joinedSpaces.add(space);
        }
      }
      
      return joinedSpaces;
    } catch (e) {
      debugPrint('Error fetching joined spaces: $e');
      return [];
    }
  }
  
  /// Get recommended spaces for a user
  @override
  Future<List<SpaceModel>> getRecommendedSpaces({String? userId}) async {
    try {
      // Get all spaces
      final allSpaces = await getAllSpaces();
      
      // If user ID is provided, we can do more personalized recommendations
      if (userId != null || _auth.currentUser != null) {
        final uid = userId ?? _auth.currentUser?.uid;
        
        // Get the user's joined spaces
        final joinedSpaceIds = await _getJoinedSpaceIds(userId: uid);
        
        // Filter out spaces the user has already joined
        final nonJoinedSpaces = allSpaces
            .where((space) => !joinedSpaceIds.contains(space.id))
            .toList();
            
        // TODO: Add more sophisticated recommendation logic here
        // For now, just return some random spaces
        if (nonJoinedSpaces.length > 10) {
          // Shuffle and take the first 10
          nonJoinedSpaces.shuffle();
          return nonJoinedSpaces.take(10).toList();
        }
        
        return nonJoinedSpaces;
      }
      
      // If no user ID, just return some random spaces
      if (allSpaces.length > 10) {
        // Shuffle and take the first 10
        allSpaces.shuffle();
        return allSpaces.take(10).toList();
      }
      
      return allSpaces;
    } catch (e) {
      debugPrint('Error fetching recommended spaces: $e');
      return [];
    }
  }
  
  /// Search spaces by query text
  @override
  Future<List<SpaceModel>> searchSpaces(String query) async {
    if (query.isEmpty) {
      return [];
    }
    
    try {
      // We don't have a full-text search in Firestore, so we'll fetch all
      // spaces and filter client-side
      final allSpaces = await getAllSpaces();
      
      // Convert query to lowercase for case-insensitive matching
      final lowercaseQuery = query.toLowerCase();
      
      return allSpaces.where((space) {
        // Check name, description, and tags
        return space.name.toLowerCase().contains(lowercaseQuery) ||
            space.description.toLowerCase().contains(lowercaseQuery) ||
            space.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
      }).toList();
    } catch (e) {
      debugPrint('Error searching spaces: $e');
      return [];
    }
  }
  
  /// Join a space
  @override
  Future<void> joinSpace(String spaceId, {String? userId}) async {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('No user ID provided and no current user');
    }
    
    try {
      // Add to user_spaces collection (join relationship)
      await _firestore.collection('user_spaces').doc('${uid}_$spaceId').set({
        'userId': uid,
        'spaceId': spaceId,
        'joinedAt': FieldValue.serverTimestamp(),
      });
      
      // Update user's joined spaces list
      final userRef = _firestore.collection('users').doc(uid);
      await userRef.update({
        'followedSpaces': FieldValue.arrayUnion([spaceId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Get the space to update its metrics
      final space = await getSpaceById(spaceId);
      if (space != null) {
        // Update space metrics
        final metricsRef = _firestore.collection('space_metrics').doc(spaceId);
        await metricsRef.set({
          'memberCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error joining space: $e');
      rethrow;
    }
  }
  
  /// Leave a space
  @override
  Future<void> leaveSpace(String spaceId, {String? userId}) async {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('No user ID provided and no current user');
    }
    
    try {
      // Remove from user_spaces collection
      await _firestore.collection('user_spaces').doc('${uid}_$spaceId').delete();
      
      // Update user's joined spaces list
      final userRef = _firestore.collection('users').doc(uid);
      await userRef.update({
        'followedSpaces': FieldValue.arrayRemove([spaceId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Get the space to update its metrics
      final space = await getSpaceById(spaceId);
      if (space != null) {
        // Update space metrics
        final metricsRef = _firestore.collection('space_metrics').doc(spaceId);
        await metricsRef.set({
          'memberCount': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error leaving space: $e');
      rethrow;
    }
  }
  
  /// Check if a user has joined a space
  @override
  Future<bool> hasJoinedSpace(String spaceId, {String? userId}) async {
    try {
      final uid = userId ?? _auth.currentUser?.uid;
      if (uid == null) {
        return false;
      }
      
      // Check user_spaces collection
      final docSnapshot = await _firestore
          .collection('user_spaces')
          .doc('${uid}_$spaceId')
          .get();
          
      return docSnapshot.exists;
    } catch (e) {
      debugPrint('Error checking if space is joined: $e');
      return false;
    }
  }
  
  /// Get spaces with upcoming events
  @override
  Future<List<SpaceModel>> getSpacesWithUpcomingEvents() async {
    try {
      // Get current timestamp
      final now = DateTime.now();
      
      // Get events happening in the next week
      final eventsSnapshot = await _firestore
          .collection('events')
          .where('startTime', isGreaterThan: Timestamp.fromDate(now))
          .where('startTime', isLessThan: Timestamp.fromDate(now.add(const Duration(days: 7))))
          .orderBy('startTime')
          .get();
          
      // Extract unique space IDs from events
      final Set<String> spaceIds = {};
      for (final doc in eventsSnapshot.docs) {
        final data = doc.data();
        if (data['spaceId'] != null) {
          spaceIds.add(data['spaceId'] as String);
        }
      }
      
      // Get spaces by IDs
      final List<SpaceModel> spaces = [];
      for (final id in spaceIds) {
        final space = await getSpaceById(id);
        if (space != null) {
          spaces.add(space);
        }
      }
      
      return spaces;
    } catch (e) {
      debugPrint('Error getting spaces with upcoming events: $e');
      return [];
    }
  }
  
  /// Get trending spaces
  @override
  Future<List<SpaceModel>> getTrendingSpaces() async {
    try {
      // Get all metrics records sorted by activity
      final metricsSnapshot = await _firestore
          .collection('space_metrics')
          .orderBy('activityScore', descending: true)
          .limit(20)
          .get();
          
      // Extract space IDs from metrics
      final List<String> spaceIds = [];
      for (final doc in metricsSnapshot.docs) {
        spaceIds.add(doc.id);
      }
      
      // Get spaces by IDs
      final List<SpaceModel> spaces = [];
      for (final id in spaceIds) {
        final space = await getSpaceById(id);
        if (space != null) {
          spaces.add(space);
        }
      }
      
      return spaces;
    } catch (e) {
      debugPrint('Error getting trending spaces: $e');
      
      // Fallback to a simple algorithm if metrics are not available
      final spaces = await getAllSpaces();
      spaces.shuffle(); // Simple random selection for fallback
      return spaces.take(10).toList();
    }
  }
  
  /// Create a new space
  @override
  Future<SpaceModel> createSpace({
    required String name,
    required String description,
    required int iconCodePoint,
    required SpaceType spaceType,
    required List<String> tags,
    required bool isPrivate,
    required String creatorId,
    required bool isHiveExclusive,
  }) async {
    // First check if the name is already taken
    final nameExists = await isSpaceNameTaken(name);
    if (nameExists) {
      throw Exception('Space name is already taken');
    }
    
    try {
      // Create a new document with auto-generated ID
      final collectionPath = _getCollectionPathForSpaceType(spaceType);
      final docRef = _firestore.collection(collectionPath).doc();
      
      // Generate current timestamp
      final timestamp = FieldValue.serverTimestamp();
      
      // Prepare space data
      final data = {
        'id': docRef.id,
        'name': name,
        'description': description,
        'icon': iconCodePoint,
        'tags': tags,
        'isPrivate': isPrivate,
        'creatorId': creatorId,
        'admins': [creatorId], // Creator is automatically an admin
        'moderators': [],
        'createdAt': timestamp,
        'updatedAt': timestamp,
        'isHiveExclusive': isHiveExclusive,
        'quickActions': [],
        'relatedSpaceIds': [],
        'lifecycleState': 'created',
        'claimStatus': isHiveExclusive ? 'notRequired' : 'unclaimed',
      };
      
      // Save the document
      await docRef.set(data);
      
      // Create metrics document
      await _firestore.collection('space_metrics').doc(docRef.id).set({
        'memberCount': 1, // Creator is first member
        'eventCount': 0,
        'activityScore': 0,
        'createdAt': timestamp,
        'updatedAt': timestamp,
      });
      
      // Auto-join the creator to the space
      await joinSpace(docRef.id, userId: creatorId);
      
      // Get the created space
      final docSnapshot = await docRef.get();
      return SpaceModel.fromFirestore(docSnapshot);
    } catch (e) {
      debugPrint('Error creating space: $e');
      rethrow;
    }
  }
  
  /// Check if a space name is already taken
  @override
  Future<bool> isSpaceNameTaken(String name) async {
    try {
      final spaceTypes = [
        'student_organizations',
        'university',
        'campus_living',
        'greek_life',
        'hive_exclusive',
        'other',
      ];
      
      for (final type in spaceTypes) {
        final collectionPath = 'spaces/$type/spaces';
        final querySnapshot = await _firestore
            .collection(collectionPath)
            .where('name', isEqualTo: name)
            .limit(1)
            .get();
            
        if (querySnapshot.docs.isNotEmpty) {
          return true; // Name is taken
        }
      }
      
      return false; // Name is available
    } catch (e) {
      debugPrint('Error checking space name: $e');
      return true; // Assume taken in case of error
    }
  }
  
  /// Get events for a space
  @override
  Future<List<Event>> getSpaceEvents(String spaceId) async {
    try {
      final eventsSnapshot = await _firestore
          .collection('events')
          .where('spaceId', isEqualTo: spaceId)
          .orderBy('startDate')
          .get();
          
      return eventsSnapshot.docs.map((doc) {
        final data = doc.data();
        return Event(
          id: doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          location: data['location'] ?? '',
          startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(hours: 1)),
          organizerEmail: data['organizerEmail'] ?? '',
          organizerName: data['organizerName'] ?? '',
          category: data['category'] ?? 'Other',
          status: data['status'] ?? 'confirmed',
          link: data['link'] ?? '',
          imageUrl: data['imageUrl'] ?? '',
          source: EventSource.club,
          visibility: data['visibility'] ?? 'public',
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting space events: $e');
      return [];
    }
  }
  
  /// Get space chat ID
  @override
  Future<String?> getSpaceChatId(String spaceId) async {
    try {
      final querySnapshot = await _firestore
          .collection('chats')
          .where('spaceId', isEqualTo: spaceId)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        return null;
      }
      
      return querySnapshot.docs.first.id;
    } catch (e) {
      debugPrint('Error getting space chat ID: $e');
      return null;
    }
  }
  
  /// Get space member details
  @override
  Future<SpaceMemberEntity?> getSpaceMember(String spaceId, String memberId) async {
    try {
      // Check if the member document exists in the space's members collection
      final docSnapshot = await _firestore
          .collection('spaces/$spaceId/members')
          .doc(memberId)
          .get();
          
      if (!docSnapshot.exists) {
        return null;
      }
      
      // Convert to SpaceMemberEntity
      final data = docSnapshot.data() as Map<String, dynamic>;
      
      // Get the role from the document or default to 'member'
      final role = data['role'] as String? ?? 'member';
      
      // Get the display name from the document or default to null
      final displayName = data['displayName'] as String?;
      
      // Get the timestamp or default to now
      final joinedAtTimestamp = data['joinedAt'] as Timestamp? ?? Timestamp.now();
      
      return SpaceMemberEntity(
        id: docSnapshot.id,
        userId: memberId,
        role: role,
        displayName: displayName,
        joinedAt: joinedAtTimestamp.toDate(),
      );
    } catch (e) {
      debugPrint('Error getting space member: $e');
      return null;
    }
  }
  
  /// Get joined space IDs for a user
  Future<List<String>> _getJoinedSpaceIds({String? userId}) async {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) {
      return [];
    }
    
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists && userDoc.data()!.containsKey('joinedSpaces')) {
        return List<String>.from(userDoc.data()!['joinedSpaces'] as List? ?? []);
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Error getting joined space IDs: $e');
      return [];
    }
  }
  
  /// Get collection path for space type
  String _getCollectionPathForSpaceType(SpaceType type) {
    switch (type) {
      case SpaceType.studentOrg:
        return 'spaces/student_organizations/spaces';
      case SpaceType.universityOrg:
        return 'spaces/university/spaces';
      case SpaceType.campusLiving:
        return 'spaces/campus_living/spaces';
      case SpaceType.fraternityAndSorority:
        return 'spaces/greek_life/spaces';
      case SpaceType.hiveExclusive:
        return 'spaces/hive_exclusive/spaces';
      case SpaceType.other:
        return 'spaces/other/spaces';
    }
  }
} 