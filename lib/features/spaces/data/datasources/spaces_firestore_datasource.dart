import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_ui/features/spaces/data/models/space_model.dart';
import 'package:hive_ui/features/spaces/data/models/space_metrics_model.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:math';

/// Firebase Firestore data source for spaces
class SpacesFirestoreDataSource {
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
  Future<List<SpaceModel>> getAllSpaces({bool forceRefresh = false}) async {
    try {
      if (_spaceCache.isNotEmpty && !forceRefresh) {
        return _spaceCache.values.toList();
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
      return allSpaces;
    } catch (e) {
      debugPrint('❌ Error getting all spaces: $e');
      throw Exception('Failed to get all spaces: $e');
    }
  }

  /// Get a space by ID
  Future<SpaceModel?> getSpaceById(String id) async {
    // Check memory cache first
    if (_spaceCache.containsKey(id)) {
      debugPrint('Space found in memory cache: $id');
      return _spaceCache[id];
    }

    try {
      debugPrint('Searching for space $id in multiple locations...');
      
      // Define all possible space type collections
      final spaceTypes = [
        'student_organizations',
        'university_organizations',
        'campus_living',
        'fraternity_and_sorority',
        'other'
      ];
      
      // Try to find space in each type collection
      for (final type in spaceTypes) {
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
      
      // Try direct path in spaces collection
      final directDocSnapshot = await _spacesCollection.doc(id).get();
      if (directDocSnapshot.exists) {
        debugPrint('Found space $id in root spaces collection');
        final space = SpaceModel.fromFirestore(directDocSnapshot);
        
        // Update cache
        _spaceCache[id] = space;
        return space;
      }
      
      // Try using collectionGroup to find the space across all subcollections
      try {
        debugPrint('Trying collectionGroup query for space $id');
        final collectionGroupQuery = await FirebaseFirestore.instance
            .collectionGroup('spaces')
            .where('id', isEqualTo: id)
            .limit(1)
            .get();
            
        if (collectionGroupQuery.docs.isNotEmpty) {
          debugPrint('Found space $id using collectionGroup query: ${collectionGroupQuery.docs.first.reference.path}');
          final space = SpaceModel.fromFirestore(collectionGroupQuery.docs.first);
          
          // Update cache
          _spaceCache[id] = space;
          return space;
        }
      } catch (e) {
        debugPrint('Error in collectionGroup query for space $id: $e');
      }

      debugPrint('Space $id not found in any collection');
      return null;
    } catch (e) {
      debugPrint('Error fetching space by ID: $e');
      return null;
    }
  }

  /// Get spaces by category
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
  Future<List<SpaceModel>> getJoinedSpaces() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return [];
      }

      // Get the user document
      final userDoc = await _usersCollection.doc(currentUser.uid).get();
      
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
  Future<List<SpaceModel>> getRecommendedSpaces() async {
    try {
      // Get all spaces
      final allSpaces = await getAllSpaces();

      // Get joined spaces
      final joinedSpaces = await getJoinedSpaces();
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
  Future<void> joinSpace(String spaceId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Update the user document to add space to followedSpaces
      await _usersCollection.doc(currentUser.uid).update({
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
        );
      }
    } catch (e) {
      debugPrint('Error joining space: $e');
      throw Exception('Failed to join space');
    }
  }

  /// Leave a space
  Future<void> leaveSpace(String spaceId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Update the user document to remove space from followedSpaces
      await _usersCollection.doc(currentUser.uid).update({
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
        );
      }
    } catch (e) {
      debugPrint('Error leaving space: $e');
      throw Exception('Failed to leave space');
    }
  }

  /// Check if the current user has joined a space
  Future<bool> hasJoinedSpace(String spaceId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return false;
      }

      // Check if the space ID is in user's followedSpaces
      final userDoc = await _usersCollection.doc(currentUser.uid).get();

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

  /// Check if a space name already exists
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
}
