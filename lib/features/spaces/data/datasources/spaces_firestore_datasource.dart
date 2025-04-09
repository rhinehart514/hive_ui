import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_ui/features/spaces/data/datasources/spaces_data_source.dart';
import 'package:hive_ui/features/spaces/data/models/space_model.dart';
import 'package:hive_ui/features/spaces/data/models/space_metrics_model.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_member_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_ui/models/event.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:math';

/// Firebase Firestore data source for spaces
class SpacesFirestoreDataSource implements SpacesDataSource {
  /// Firestore collection reference for spaces
  final CollectionReference _spacesCollection =
      FirebaseFirestore.instance.collection('spaces');

  /// Firestore collection reference for users
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');

  /// Firestore collection reference for space metrics
  final CollectionReference _spaceMetricsCollection =
      FirebaseFirestore.instance.collection('space_metrics');

  /// Cache-related constants and variables
  static const String _spacesPrefsKey = 'spaces_cache';
  static const String _lastFetchTimestampKey = 'spaces_last_fetch';
  static const Duration _cacheValidDuration = Duration(hours: 6);
  static const int _pageSize = 20;
  static final Map<String, SpaceModel> _spaceCache = {};
  static DateTime? _lastFirestoreSync;

  /// Get all spaces from Firestore with optional caching
  @override
  Future<List<SpaceModel>> getAllSpaces({
    bool forceRefresh = false,
    bool includePrivate = false,
    bool includeJoined = true,
    String? userId,
  }) async {
    try {
      if (_spaceCache.isNotEmpty && !forceRefresh) {
        final cachedSpaces = _spaceCache.values.toList();
        
        // Apply filters to cached spaces
        return _filterSpaces(cachedSpaces, includePrivate, includeJoined);
      }

      _spaceCache.clear();
      final List<SpaceModel> allSpaces = [];
      
      // Get spaces from all collections including hive_exclusive
      final collections = [
        'spaces/student_organizations/spaces',
        'spaces/university/spaces',
        'spaces/campus_living/spaces',
        'spaces/greek_life/spaces',
        'spaces/other/spaces',
        'spaces/hive_exclusive/spaces', // Explicitly include Hive Exclusive collection
      ];

      debugPrint('🔄 Fetching spaces from all collections...');
      
      // Fetch spaces from each collection
      for (final collection in collections) {
        debugPrint('📚 Querying collection: $collection');
        final snapshot = await FirebaseFirestore.instance.collection(collection).get();
        debugPrint('📊 Found ${snapshot.docs.length} documents in $collection');
        
        // Log all documents in the hive_exclusive collection to debug
        if (collection == 'spaces/hive_exclusive/spaces') {
          for (final doc in snapshot.docs) {
            final data = doc.data();
            debugPrint('📎 Hive Exclusive Document ID: ${doc.id}');
            debugPrint('🔑 Document data: ${data.toString().substring(0, min(100, data.toString().length))}...');
          }
        }
        
        for (final doc in snapshot.docs) {
          final space = SpaceModel.fromFirestore(doc);
          _spaceCache[space.id] = space;
          allSpaces.add(space);
          
          // Log details for all spaces with hiveExclusive flag
          debugPrint('📂 Space: ${space.name}, collection: $collection, hiveExclusive: ${space.hiveExclusive}');
          
          // Log details for spaces in the hive_exclusive collection
          if (collection == 'spaces/hive_exclusive/spaces') {
            debugPrint('🌟 Found Hive Exclusive collection space: ${space.name} (ID: ${space.id})');
          }
        }
      }

      debugPrint('✅ Loaded ${allSpaces.length} total spaces');
      
      // Apply filters to fetched spaces
      return _filterSpaces(allSpaces, includePrivate, includeJoined);
    } catch (e) {
      debugPrint('❌ Error getting all spaces: $e');
      throw Exception('Failed to get all spaces: $e');
    }
  }

  /// Helper method to filter spaces based on privacy and joined status
  Future<List<SpaceModel>> _filterSpaces(
    List<SpaceModel> spaces, 
    bool includePrivate, 
    bool includeJoined
  ) async {
    // Get current user
    final currentUser = FirebaseAuth.instance.currentUser;
    List<String> joinedSpaceIds = [];
    
    // Get joined space IDs if needed
    if (!includeJoined && currentUser != null) {
      final userDoc = await _usersCollection.doc(currentUser.uid).get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>?;
        
        if (userData != null && userData['followedSpaces'] is List) {
          joinedSpaceIds = List<String>.from(userData['followedSpaces']);
        }
      }
    }
    
    return spaces.where((space) {
      // Filter private spaces
      if (space.isPrivate && !includePrivate) {
        return false;
      }
      
      // Filter joined spaces if needed
      if (!includeJoined && joinedSpaceIds.contains(space.id)) {
        return false;
      }
      
      return true;
    }).toList();
  }

  /// Get a space by ID with optional space type
  @override
  Future<SpaceModel?> getSpaceById(String id, {String? spaceType}) async {
    // Check memory cache first
    if (_spaceCache.containsKey(id)) {
      debugPrint('Space found in memory cache: $id');
      return _spaceCache[id];
    }

    try {
      debugPrint('Searching for space $id${spaceType != null ? " in $spaceType" : ""}...');
      
      // If space type is provided, check that specific collection first
      if (spaceType != null) {
        final typeCollectionPath = 'spaces/$spaceType/spaces';
        debugPrint('Checking specific path: $typeCollectionPath');
        
        final docRef = FirebaseFirestore.instance.collection(typeCollectionPath).doc(id);
        final docSnapshot = await docRef.get();
        
        if (docSnapshot.exists) {
          debugPrint('Found space $id in $spaceType collection');
          final space = SpaceModel.fromFirestore(docSnapshot);
          
          // Update cache
          _spaceCache[id] = space;
          return space;
        }
      }
      
      // If not found in specific type or no type provided, try all collections
      final spaceTypes = [
        'student_organizations',
        'university_organizations',
        'campus_living',
        'fraternity_and_sorority',
        'other'
      ];
      
      // Try to find space in each type collection
      for (final type in spaceTypes) {
        // Skip if we already checked this type
        if (type == spaceType) continue;
        
        try {
          final typeCollectionPath = 'spaces/$type/spaces';
          debugPrint('Checking path: $typeCollectionPath');
          
          final docRef = FirebaseFirestore.instance.collection(typeCollectionPath).doc(id);
          final docSnapshot = await docRef.get();
          
          if (docSnapshot.exists) {
            debugPrint('Found space $id in $type collection');
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
      
      // Try direct path in spaces collection as fallback
      final directDocSnapshot = await _spacesCollection.doc(id).get();
      if (directDocSnapshot.exists) {
        debugPrint('Found space $id in root spaces collection');
        final space = SpaceModel.fromFirestore(directDocSnapshot);
        
        // Update cache
        _spaceCache[id] = space;
        return space;
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
  /// If userId is provided, gets spaces joined by that user instead
  @override
  Future<List<SpaceModel>> getJoinedSpaces({String? userId}) async {
    try {
      // Use provided userId or current user
      final uid = userId ?? FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        return [];
      }

      // Get the user document
      final userDoc = await _usersCollection.doc(uid).get();
      
      if (!userDoc.exists) {
        return [];
      }
      
      final userData = userDoc.data() as Map<String, dynamic>?;
      
      if (userData == null || userData['followedSpaces'] == null) {
        return [];
      }
      
      List<String> spaceIds = [];
      
      if (userData['followedSpaces'] is List) {
        spaceIds = List<String>.from(userData['followedSpaces']);
      }

      // Load all spaces
      final allSpaces = await getAllSpaces();

      // Filter to joined spaces
      return allSpaces.where((space) => spaceIds.contains(space.id)).toList();
    } catch (e) {
      debugPrint('Error fetching joined spaces: $e');
      return [];
    }
  }

  /// Get recommended spaces for the current user
  /// If userId is provided, gets recommendations for that user instead
  @override
  Future<List<SpaceModel>> getRecommendedSpaces({String? userId}) async {
    try {
      // Get all public spaces (no private spaces)
      final allSpaces = await getAllSpaces(includePrivate: false);

      // Get joined spaces
      final joinedSpaces = await getJoinedSpaces(userId: userId);
      final joinedSpaceIds = joinedSpaces.map((space) => space.id).toSet();

      // Filter out already joined spaces
      final notJoinedSpaces = allSpaces
          .where((space) => !joinedSpaceIds.contains(space.id))
          .toList();

      // Sort by popularity or recommendation algorithm
      notJoinedSpaces.sort((a, b) =>
          (b.metrics.memberCount + b.metrics.activeMembers) -
          (a.metrics.memberCount + a.metrics.activeMembers));

      // Return top recommendations
      return notJoinedSpaces.take(20).toList();
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
      // Get all spaces
      final allSpaces = await getAllSpaces();

      // Convert query to lowercase for case-insensitive search
      final lowerQuery = query.toLowerCase();

      // Filter spaces by query
      return allSpaces.where((space) {
        final name = space.name.toLowerCase();
        final description = space.description.toLowerCase();
        final tags = space.tags.join(' ').toLowerCase();

        return name.contains(lowerQuery) ||
            description.contains(lowerQuery) ||
            tags.contains(lowerQuery);
      }).toList();
    } catch (e) {
      debugPrint('Error searching spaces: $e');
      return [];
    }
  }

  /// Join a space
  @override
  Future<void> joinSpace(String spaceId, {String? userId}) async {
    try {
      // Use provided userId or current user
      final uid = userId ?? FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        throw Exception('User not authenticated');
      }

      // Update the user document to add space to followedSpaces
      await _usersCollection.doc(uid).update({
        'followedSpaces': FieldValue.arrayUnion([spaceId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update the member count in space metrics
      await _spaceMetricsCollection.doc(spaceId).set({
        'memberCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update cache if space exists in cache
      if (_spaceCache.containsKey(spaceId)) {
        final updatedSpace = _spaceCache[spaceId]!;
        _spaceCache[spaceId] = SpaceModel(
          id: updatedSpace.id,
          name: updatedSpace.name,
          description: updatedSpace.description,
          iconCodePoint: updatedSpace.iconCodePoint,
          metrics: updatedSpace.metrics,
          imageUrl: updatedSpace.imageUrl,
          bannerUrl: updatedSpace.bannerUrl,
          tags: updatedSpace.tags,
          customData: updatedSpace.customData,
          isJoined: true,
          isPrivate: updatedSpace.isPrivate,
          moderators: updatedSpace.moderators,
          admins: updatedSpace.admins,
          quickActions: updatedSpace.quickActions,
          relatedSpaceIds: updatedSpace.relatedSpaceIds,
          createdAt: updatedSpace.createdAt,
          updatedAt: DateTime.now(),
          spaceType: updatedSpace.spaceType,
          eventIds: updatedSpace.eventIds,
          hiveExclusive: updatedSpace.hiveExclusive,
        );
      }
    } catch (e) {
      debugPrint('Error joining space: $e');
      throw Exception('Failed to join space');
    }
  }

  /// Leave a space
  @override
  Future<void> leaveSpace(String spaceId, {String? userId}) async {
    try {
      // Use provided userId or current user
      final uid = userId ?? FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        throw Exception('User not authenticated');
      }

      // Update the user document to remove space from followedSpaces
      await _usersCollection.doc(uid).update({
        'followedSpaces': FieldValue.arrayRemove([spaceId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update the member count in space metrics
      await _spaceMetricsCollection.doc(spaceId).set({
        'memberCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update cache if space exists in cache
      if (_spaceCache.containsKey(spaceId)) {
        final updatedSpace = _spaceCache[spaceId]!;
        _spaceCache[spaceId] = SpaceModel(
          id: updatedSpace.id,
          name: updatedSpace.name,
          description: updatedSpace.description,
          iconCodePoint: updatedSpace.iconCodePoint,
          metrics: updatedSpace.metrics,
          imageUrl: updatedSpace.imageUrl,
          bannerUrl: updatedSpace.bannerUrl,
          tags: updatedSpace.tags,
          customData: updatedSpace.customData,
          isJoined: false,
          isPrivate: updatedSpace.isPrivate,
          moderators: updatedSpace.moderators,
          admins: updatedSpace.admins,
          quickActions: updatedSpace.quickActions,
          relatedSpaceIds: updatedSpace.relatedSpaceIds,
          createdAt: updatedSpace.createdAt,
          updatedAt: DateTime.now(),
          spaceType: updatedSpace.spaceType,
          eventIds: updatedSpace.eventIds,
          hiveExclusive: updatedSpace.hiveExclusive,
        );
      }
    } catch (e) {
      debugPrint('Error leaving space: $e');
      throw Exception('Failed to leave space');
    }
  }

  /// Check if the current user has joined a space
  @override
  Future<bool> hasJoinedSpace(String spaceId, {String? userId}) async {
    try {
      // Use provided userId or current user
      final uid = userId ?? FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        return false;
      }

      // Check if the space ID is in user's followedSpaces
      final userDoc = await _usersCollection.doc(uid).get();

      if (!userDoc.exists) {
        return false;
      }

      final userData = userDoc.data() as Map<String, dynamic>?;
      if (userData == null || userData['followedSpaces'] == null) {
        return false;
      }

      if (userData['followedSpaces'] is List) {
        final followedSpaces = List<String>.from(userData['followedSpaces']);
        return followedSpaces.contains(spaceId);
      }

      return false;
    } catch (e) {
      debugPrint('Error checking if user has joined space: $e');
      return false;
    }
  }

  /// Get spaces with upcoming events
  @override
  Future<List<SpaceModel>> getSpacesWithUpcomingEvents() async {
    try {
      // Get current timestamp
      final now = DateTime.now();

      // Query spaces with upcoming events
      final snapshot = await _spacesCollection
          .where('hasUpcomingEvents', isEqualTo: true)
          .limit(_pageSize)
          .get();

      final spaces =
          snapshot.docs.map((doc) => SpaceModel.fromFirestore(doc)).toList();

      // Update cache
      for (final space in spaces) {
        _spaceCache[space.id] = space;
      }

      return spaces;
    } catch (e) {
      debugPrint('Error fetching spaces with upcoming events: $e');
      return [];
    }
  }

  /// Get trending spaces
  @override
  Future<List<SpaceModel>> getTrendingSpaces() async {
    try {
      // Query trending spaces
      final snapshot = await _spacesCollection
          .where('metrics.isTrending', isEqualTo: true)
          .limit(_pageSize)
          .get();

      final spaces =
          snapshot.docs.map((doc) => SpaceModel.fromFirestore(doc)).toList();

      // Update cache
      for (final space in spaces) {
        _spaceCache[space.id] = space;
      }

      return spaces;
    } catch (e) {
      debugPrint('Error fetching trending spaces: $e');
      return [];
    }
  }

  /// Fetch spaces from Firestore
  Future<List<SpaceModel>> _fetchSpacesFromFirestore() async {
    try {
      final snapshot = await _spacesCollection.limit(_pageSize).get();
      final spaces =
          snapshot.docs.map((doc) => SpaceModel.fromFirestore(doc)).toList();

      _lastFirestoreSync = DateTime.now();

      return spaces;
    } catch (e) {
      debugPrint('Error fetching spaces from Firestore: $e');
      return [];
    }
  }

  /// Check if cache is stale
  Future<bool> _isCacheStale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastFetchTimestamp = prefs.getInt(_lastFetchTimestampKey);

      if (lastFetchTimestamp == null) return true;

      final lastFetchTime =
          DateTime.fromMillisecondsSinceEpoch(lastFetchTimestamp);
      final now = DateTime.now();

      // Check if cache is older than the valid duration
      return now.difference(lastFetchTime) > _cacheValidDuration;
    } catch (e) {
      debugPrint('Error checking cache staleness: $e');
      return true;
    }
  }

  /// Load spaces from persistent cache
  Future<List<SpaceModel>> _loadSpacesFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final spacesJson = prefs.getString(_spacesPrefsKey);

      if (spacesJson == null) {
        return [];
      }

      final List<dynamic> spacesList = jsonDecode(spacesJson);
      final spaces = <SpaceModel>[];

      for (final spaceData in spacesList) {
        try {
          final json = spaceData as Map<String, dynamic>;
          // Create a temporary model directly from the JSON
          if (json.containsKey('id')) {
            // Fetch the actual space from Firestore to ensure consistency
            final spaceDoc =
                await _spacesCollection.doc(json['id'] as String).get();
            if (spaceDoc.exists) {
              final space = SpaceModel.fromFirestore(spaceDoc);
              spaces.add(space);
            }
          }
        } catch (e) {
          debugPrint('Error parsing cached space: $e');
          // Skip invalid entries
        }
      }

      return spaces;
    } catch (e) {
      debugPrint('Error loading spaces from cache: $e');
      return [];
    }
  }

  /// Save spaces to persistent cache
  Future<void> _saveSpacesToCache(List<SpaceModel> spaces) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert spaces to JSON
      final spacesList = spaces.map((space) => space.toFirestore()).toList();

      // Save to SharedPreferences
      await prefs.setString(_spacesPrefsKey, jsonEncode(spacesList));

      // Update last fetch timestamp
      await prefs.setInt(
          _lastFetchTimestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error saving spaces to cache: $e');
    }
  }

  /// Invalidate the cache to force a refresh on next fetch
  Future<void> invalidateCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_spacesPrefsKey);
      await prefs.remove(_lastFetchTimestampKey);
      debugPrint('✅ Cache invalidated successfully');
    } catch (e) {
      debugPrint('❌ Error invalidating cache: $e');
    }
  }

  /// Check if a space name already exists
  @override
  Future<bool> isSpaceNameTaken(String name) async {
    try {
      final normalizedName = name.trim().toLowerCase();
      
      // Check all space types for the name
      final spaceTypes = ['student_organizations', 'university', 'campus_living', 'greek_life', 'other'];
      
      for (final spaceType in spaceTypes) {
        // Query the nested spaces collection for each space type
        final querySnapshot = await FirebaseFirestore.instance
            .collection('spaces')
            .doc(spaceType)
            .collection('spaces')
            .where('nameLowerCase', isEqualTo: normalizedName)
            .limit(1)
            .get();
        
        if (querySnapshot.docs.isNotEmpty) {
          return true; // Found a match in this space type
        }
      }
      
      // Also check the top-level spaces collection (legacy support)
      final legacyQuerySnapshot = await _spacesCollection
          .where('nameLowerCase', isEqualTo: normalizedName)
          .limit(1)
          .get();
      
      return legacyQuerySnapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking space name: $e');
      // In case of error, default to assuming it's not taken
      // so we don't block creation unnecessarily
      return false;
    }
  }

  /// Create a new space in Firestore
  /// 
  /// This method creates a new space with the specified parameters and
  /// automatically sets up the creator as an admin and moderator.
  /// It also creates the initial space metrics and joins the creator to the space.
  @override
  Future<SpaceModel> createSpace({
    required String name,
    required String description,
    required int iconCodePoint,
    required SpaceType spaceType,
    required List<String> tags,
    required bool isPrivate,
    required String creatorId,
    bool isHiveExclusive = true,
  }) async {
    try {
      // First check if space name already exists
      final nameExists = await isSpaceNameTaken(name);
      if (nameExists) {
        throw Exception('A space with this name already exists. Please choose a different name.');
      }
      
      final now = DateTime.now();
      
      // Create metrics model
      final metricsModel = SpaceMetricsModel.initial('');
      
      // Prepare space data
      final Map<String, dynamic> spaceData = {
        'name': name,
        'description': description,
        'icon': iconCodePoint,
        'tags': tags,
        'isPrivate': isPrivate,
        'moderators': [creatorId],
        'admins': [creatorId],
        'spaceType': spaceType.toString().split('.').last,
        'metrics': metricsModel.toJson(),
        'createdAt': now,
        'updatedAt': now,
        'eventIds': <String>[],
        'customData': <String, dynamic>{},
        'hiveExclusive': isHiveExclusive, // Explicitly set hiveExclusive flag
        'nameLowerCase': name.trim().toLowerCase(),
      };
      
      // Determine the correct collection based on HIVE exclusivity and space type
      String collectionPath;
      
      // Override the collection path for HIVE exclusive spaces
      // to ensure they're stored in the HIVE exclusive collection
      if (isHiveExclusive) {
        collectionPath = 'spaces/hive_exclusive/spaces';
        // Make sure we're setting the hiveExclusive flag correctly in the data
        debugPrint('🌟 Creating a Hive Exclusive space: $name');
      } else {
        // Only use type-based paths for non-HIVE exclusive spaces
        switch (spaceType) {
          case SpaceType.studentOrg:
            collectionPath = 'spaces/student_organizations/spaces';
            break;
          case SpaceType.universityOrg:
            collectionPath = 'spaces/university/spaces';
            break;
          case SpaceType.campusLiving:
            collectionPath = 'spaces/campus_living/spaces';
            break;
          case SpaceType.fraternityAndSorority:
            collectionPath = 'spaces/greek_life/spaces';
            break;
          case SpaceType.other:
          default:
            collectionPath = 'spaces/other/spaces';
            break;
        }
      }
      
      // Create the space document in the correct collection
      final DocumentReference docRef = await FirebaseFirestore.instance
          .collection(collectionPath)
          .add(spaceData);
      
      // Get the newly created space ID
      final String spaceId = docRef.id;
      
      // Log space creation
      debugPrint('✅ Created space with ID: $spaceId in collection: $collectionPath, hiveExclusive: $isHiveExclusive');
      
      // Update metrics with the correct space ID
      final updatedMetrics = metricsModel.copyWith(spaceId: spaceId);
      await _spaceMetricsCollection.doc(spaceId).set(updatedMetrics.toJson());
      
      // Add space to creator's followedSpaces
      final userDoc = await _usersCollection.doc(creatorId).get();
      
      if (userDoc.exists) {
        // Update existing user document
        await _usersCollection.doc(creatorId).update({
          'followedSpaces': FieldValue.arrayUnion([spaceId]),
          'updatedAt': now,
        });
      } else {
        // Create new user document if it doesn't exist
        await _usersCollection.doc(creatorId).set({
          'id': creatorId,
          'followedSpaces': [spaceId],
          'createdAt': now,
          'updatedAt': now,
        });
      }
      
      // Get the created space from Firestore to return
      final docSnapshot = await docRef.get();
      final createdSpaceModel = SpaceModel.fromFirestore(docSnapshot);
      
      // Update the cache with the new space
      _spaceCache[spaceId] = createdSpaceModel;
      
      return createdSpaceModel;
    } catch (e) {
      debugPrint('Error creating space: $e');
      throw Exception('Failed to create space: $e');
    }
  }

  /// Helper method to safely convert Firestore timestamp to DateTime
  DateTime? _safeTimestampToDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  /// Get events associated with a space
  @override
  Future<List<Event>> getSpaceEvents(String spaceId) async {
    try {
      debugPrint('🔍 Fetching events for space: $spaceId');
      
      // First, find which collection the space is in
      final spaceTypes = [
        'student_organizations',
        'university',
        'campus_living',
        'greek_life',
        'hive_exclusive',
        'other'
      ];

      List<Event> events = [];
      
      // Try to find and fetch events from each possible space type collection
      for (final spaceType in spaceTypes) {
        try {
          debugPrint('👉 Checking $spaceType collection for space $spaceId');
          
          final spacePath = FirebaseFirestore.instance
              .collection('spaces')
              .doc(spaceType)
              .collection('spaces')
              .doc(spaceId);
              
          // First verify if the space exists in this collection
          final spaceDoc = await spacePath.get();
          if (!spaceDoc.exists) {
            debugPrint('Space not found in $spaceType collection');
            continue;
          }
          
          debugPrint('✅ Found space in $spaceType collection, fetching events...');
          
          final eventsSnapshot = await spacePath
              .collection('events')
              .orderBy('startDate', descending: false)
              .get();

          debugPrint('📊 Found ${eventsSnapshot.docs.length} events in $spaceType collection');

          // Process each event document
          for (final eventDoc in eventsSnapshot.docs) {
            try {
              final data = eventDoc.data();
              final event = Event(
                id: eventDoc.id,
                title: data['title'] ?? '',
                description: data['description'] ?? '',
                startDate: _safeTimestampToDateTime(data['startDate']) ?? DateTime.now(),
                endDate: _safeTimestampToDateTime(data['endDate']) ?? DateTime.now(),
                location: data['location'] ?? '',
                organizerEmail: data['organizerEmail'] ?? '',
                organizerName: data['organizerName'] ?? '',
                category: data['category'] ?? '',
                status: data['status'] ?? '',
                link: data['link'] ?? '',
                imageUrl: data['imageUrl'] ?? '',
                source: _parseEventSource(data['source']),
                createdBy: data['createdBy'] ?? '',
                lastModified: _safeTimestampToDateTime(data['lastModified']) ?? DateTime.now(),
                visibility: data['visibility'] ?? 'public',
                attendees: List<String>.from(data['attendees'] ?? []),
                spaceId: spaceId,
              );
              events.add(event);
            } catch (e) {
              debugPrint('Error processing event document: $e');
              continue;
            }
          }

          // If we found events in this collection, no need to check others
          if (events.isNotEmpty) {
            debugPrint('✅ Successfully found and processed ${events.length} events');
            break;
          }
        } catch (e) {
          debugPrint('Error checking $spaceType collection: $e');
          continue;
        }
      }

      // Sort events by start date
      events.sort((a, b) => a.startDate.compareTo(b.startDate));
      return events;

    } catch (e) {
      debugPrint('Error fetching space events: $e');
      return [];
    }
  }

  /// Helper method to parse event source
  EventSource _parseEventSource(dynamic source) {
    if (source == null) return EventSource.external;
    final sourceStr = source.toString().toLowerCase();
    if (sourceStr == 'user') return EventSource.user;
    if (sourceStr == 'club') return EventSource.club;
    return EventSource.external;
  }

  /// Get the chat ID associated with a space
  /// Returns null if no chat exists for this space
  @override
  Future<String?> getSpaceChatId(String spaceId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .where('spaceId', isEqualTo: spaceId)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        debugPrint('No chat found for space $spaceId');
        return null;
      }
      
      debugPrint('Found chat ID for space $spaceId: ${querySnapshot.docs.first.id}');
      return querySnapshot.docs.first.id;
    } catch (e) {
      debugPrint('Error getting space chat ID: $e');
      return null;
    }
  }
  
  /// Get details for a specific space member
  /// Returns null if the member is not found
  @override
  Future<SpaceMemberEntity?> getSpaceMember(String spaceId, String memberId) async {
    try {
      // Check if the member document exists in the space's members collection
      final docSnapshot = await FirebaseFirestore.instance
          .collection('spaces/$spaceId/members')
          .doc(memberId)
          .get();
          
      if (!docSnapshot.exists) {
        debugPrint('Member $memberId not found in space $spaceId');
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
      
      debugPrint('Found member $memberId in space $spaceId with role: $role');
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
}
