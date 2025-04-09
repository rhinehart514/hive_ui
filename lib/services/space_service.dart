import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/space.dart';
import '../models/club.dart';
import '../models/space_type.dart';
import '../models/space_metrics.dart';
import '../models/organization.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Result class for paginated queries
class PaginatedResult<T> {
  /// The list of items retrieved
  final List<T> items;

  /// Whether there are more items to load
  final bool hasMore;

  /// The last document snapshot for pagination
  final DocumentSnapshot? lastDocument;

  /// Default constructor
  PaginatedResult({
    required this.items,
    this.hasMore = false,
    this.lastDocument,
  });
}

/// Service for interacting with spaces in the app
class SpaceService {
  /// The collection reference for Spaces
  static final CollectionReference _spacesCollection =
      FirebaseFirestore.instance.collection('spaces');

  /// Cache-related constants
  static const String _spacesPrefsKey = 'spaces_cache';
  static const String _lastFetchTimestampKey = 'spaces_last_fetch';
  static const Duration _cacheValidDuration = Duration(hours: 6);
  static const int _pageSize = 20;

  /// In-memory cache
  static final Map<String, Space> _spaceCache = {};
  static bool _isInitialized = false;
  static DateTime? _lastFirestoreSync;

  /// Initialize the service and load cache
  static Future<void> initialize() async {
    if (_isInitialized) return;

    await initSettings();
    await loadSpacesFromCache();
    _isInitialized = true;
  }

  /// Get a space by ID with immediate return from cache
  static Space? getSpaceById(String id) {
    return _spaceCache[id];
  }

  /// Get a club by ID - compatibility method for Club model
  static Club? getClubById(String id) {
    final space = _spaceCache[id];
    if (space == null) return null;

    return Club.fromSpace(space.toJson());
  }

  /// Get a space by name with immediate return from cache
  static Space? getSpaceByName(String name) {
    final spaceId = _generateSpaceIdFromName(name);
    return _spaceCache[spaceId];
  }

  /// Get a club by organizer name - compatibility method for Club model
  static Club? getClubByOrganizerName(String organizerName) {
    final space = getSpaceByName(organizerName);
    if (space == null) return null;

    return Club.fromSpace(space.toJson());
  }

  /// Get all spaces immediately from cache
  static List<Space> getAllSpaces() {
    return _spaceCache.values.toList();
  }

  /// Get all clubs - compatibility method
  static List<Club> getAllClubs() {
    return _spaceCache.values
        .map((space) => Club.fromSpace(space.toJson()))
        .toList();
  }

  /// Get all spaces with a specific category immediately from cache
  static List<Space> getSpacesByCategory(String category) {
    final spaceType = _getCategorySpaceType(category);

    return _spaceCache.values
        .where((space) =>
            space.spaceType == spaceType || (space.tags.contains(category)))
        .toList();
  }

  /// Get all clubs with a specific category - compatibility method
  static List<Club> getClubsByCategory(String category) {
    return getSpacesByCategory(category)
        .map((space) => Club.fromSpace(space.toJson()))
        .toList();
  }

  /// Add a single space to the memory cache and optionally save to persistent cache
  static Future<void> addSpaceToCache(Space space,
      {bool saveToDisk = false}) async {
    // Add to memory cache
    _spaceCache[space.id] = space;

    // Optionally save to persistent cache
    if (saveToDisk) {
      await _saveSpacesToCache([..._spaceCache.values.toList()]);
    }

    debugPrint('Added space to cache: ${space.name} (${space.id})');
  }

  /// Check if cache needs refreshing and load spaces from network if needed
  /// Returns immediately with cached data and updates later if needed
  static Future<List<Space>> getRefreshedSpaces(
      {bool forceRefresh = false}) async {
    // First return whatever we have in cache
    final List<Space> currentSpaces = _spaceCache.values.toList();

    // Check if cache is stale or forced refresh
    if (forceRefresh || await _isCacheStale()) {
      _refreshSpacesAsync();
    }

    return currentSpaces;
  }

  /// Load spaces from cache on app startup
  static Future<void> loadSpacesFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final spacesJson = prefs.getString(_spacesPrefsKey);

      if (spacesJson != null) {
        final List<dynamic> spacesList = jsonDecode(spacesJson);

        for (final spaceData in spacesList) {
          final space = Space.fromJson(spaceData);
          _spaceCache[space.id] = space;
        }

        debugPrint('Loaded ${_spaceCache.length} spaces from cache');
      }
    } catch (e) {
      debugPrint('Error loading spaces from cache: $e');
    }
  }

  /// Save spaces to cache
  static Future<void> _saveSpacesToCache(List<Space> spaces) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final spacesList = spaces.map((space) => space.toJson()).toList();
      await prefs.setString(_spacesPrefsKey, jsonEncode(spacesList));

      // Update last fetch timestamp
      _updateLastFetchTimestamp();
    } catch (e) {
      debugPrint('Error saving spaces to cache: $e');
    }
  }

  /// Update timestamp of last fetch
  static Future<void> _updateLastFetchTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          _lastFetchTimestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error updating timestamp: $e');
    }
  }

  /// Check if our cached data is stale
  static Future<bool> _isCacheStale() async {
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

  /// Background refresh without blocking the UI
  static Future<void> _refreshSpacesAsync() async {
    try {
      // Load from Firestore
      final firestoreSpaces = await loadSpacesFromFirestore();

      if (firestoreSpaces.isNotEmpty) {
        debugPrint('Loaded ${firestoreSpaces.length} spaces from Firestore');
      }
    } catch (e, stackTrace) {
      debugPrint(
          'Failed to refresh spaces in background\nError: $e\nStack trace: $stackTrace');
      // Don't rethrow as this is a background operation
    }
  }

  /// Load spaces from Firestore with pagination and caching
  static Future<List<Space>> loadSpacesFromFirestore({
    int page = 0,
    bool forceRefresh = false,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      // Check if we should use cache
      if (!forceRefresh && _lastFirestoreSync != null) {
        final timeSinceLastSync =
            DateTime.now().difference(_lastFirestoreSync!);
        if (timeSinceLastSync < const Duration(minutes: 15)) {
          debugPrint(
              'Using in-memory cache for spaces (last synced ${timeSinceLastSync.inMinutes} minutes ago)');
          return _spaceCache.values.toList();
        }
      }

      debugPrint(
          'Loading spaces from Firestore using collectionGroup (page: $page, pageSize: $_pageSize)');

      // Use collectionGroup to query all "spaces" collections across all paths
      Query query = FirebaseFirestore.instance
          .collectionGroup('spaces')
          .orderBy('memberCount', descending: true)
          .limit(_pageSize);

      // Apply cursor-based pagination if a starting document is provided
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      // Execute query
      final querySnapshot = await query.get();

      debugPrint(
          'Loaded ${querySnapshot.docs.length} spaces from Firestore collectionGroup');

      // Convert to Space objects
      final List<Space> spaces = [];

      for (final doc in querySnapshot.docs) {
        try {
          spaces.add(_spaceFromFirestore(doc));

          // Add to cache for quick lookup
          _spaceCache[doc.id] = spaces.last;
        } catch (e, stackTrace) {
          debugPrint('Error processing space document: $e\n$stackTrace');
        }
      }

      // Update last sync timestamp
      _lastFirestoreSync = DateTime.now();

      // Save to cache if we got data
      if (spaces.isNotEmpty) {
        await _saveSpacesToCache(spaces);
      }

      // Update timestamp to avoid redundant refreshes
      _updateLastFetchTimestamp();

      return spaces;
    } catch (e, stackTrace) {
      debugPrint('Error loading spaces from Firestore: $e\n$stackTrace');
      return [];
    }
  }

  /// Join a space as a member
  static Future<bool> joinSpace(String spaceId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;

      if (currentUserId == null) {
        debugPrint('Cannot join space: user not authenticated');
        return false;
      }

      // First check if the user is already a member
      try {
        final memberDoc = await firestore
            .collectionGroup('members')
            .where('userId', isEqualTo: currentUserId)
            .where('spaceId', isEqualTo: spaceId)
            .limit(1)
            .get();

        if (memberDoc.docs.isNotEmpty) {
          debugPrint('User is already a member of this space');
          return true; // Already joined
        }
      } catch (e) {
        debugPrint('Error checking membership: $e');
        // Continue with join attempt even if check fails
      }

      // Find the space document using collectionGroup
      final spaceQuery = await firestore
          .collectionGroup('spaces')
          .where('id', isEqualTo: spaceId)
          .limit(1)
          .get();

      if (spaceQuery.docs.isEmpty) {
        debugPrint('Space not found with ID: $spaceId');
        return false;
      }

      final spaceRef = spaceQuery.docs.first.reference;

      // Add user to members subcollection
      final memberData = {
        'userId': currentUserId,
        'spaceId': spaceId,
        'joinedAt': FieldValue.serverTimestamp(),
        'status': 'active',
      };

      // Add member document to the correct subcollection
      await spaceRef.collection('members').doc(currentUserId).set(memberData);

      // Increment member count
      await spaceRef.update({
        'memberCount': FieldValue.increment(1),
      });

      debugPrint('Successfully joined space: $spaceId');
      return true;
    } catch (e) {
      debugPrint('Error joining space: $e');
      return false;
    }
  }

  /// Join a club as a member (compatibility method)
  static Future<bool> joinClub(String clubId) async {
    return joinSpace(clubId);
  }

  /// Generate a space ID from a name
  static String _generateSpaceIdFromName(String name) {
    // Normalize the name (lowercase, remove special chars)
    final normalized = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');

    return 'space_$normalized';
  }

  /// Get space type from category string
  static SpaceType _getCategorySpaceType(String category) {
    final lowerCategory = category.toLowerCase();

    if (lowerCategory.contains('fraternity') ||
        lowerCategory.contains('sorority')) {
      return SpaceType.fraternityAndSorority;
    } else if (lowerCategory.contains('student') &&
        lowerCategory.contains('org')) {
      return SpaceType.studentOrg;
    } else if (lowerCategory.contains('university') ||
        lowerCategory.contains('department')) {
      return SpaceType.universityOrg;
    } else if (lowerCategory.contains('campus') &&
        lowerCategory.contains('living')) {
      return SpaceType.campusLiving;
    } else {
      return SpaceType.other;
    }
  }

  /// Convert a Space to a Firestore-friendly JSON map
  static Map<String, dynamic> _spaceToJson(Space space) {
    return {
      'name': space.name,
      'description': space.description,
      'icon': space.icon.codePoint,
      'imageUrl': space.imageUrl,
      'bannerUrl': space.bannerUrl,
      'organizationId': space.organization?.id,
      'tags': space.tags,
      'customData': space.customData,
      'isJoined': space.isJoined,
      'isPrivate': space.isPrivate,
      'moderators': space.moderators,
      'admins': space.admins,
      'quickActions': space.quickActions,
      'relatedSpaceIds': space.relatedSpaceIds,
      'createdAt': space.createdAt,
      'updatedAt': space.updatedAt,
      'spaceType': space.spaceType.toString().split('.').last,
      'eventIds': space.eventIds,
      'metrics': {
        'spaceId': space.metrics.spaceId,
        'memberCount': space.metrics.memberCount,
        'activeMembers': space.metrics.activeMembers,
        'weeklyEvents': space.metrics.weeklyEvents,
        'monthlyEngagements': space.metrics.monthlyEngagements,
        'lastActivity': space.metrics.lastActivity,
        'hasNewContent': space.metrics.hasNewContent,
        'isTrending': space.metrics.isTrending,
        'activeMembers24h': space.metrics.activeMembers24h,
        'activityScores': space.metrics.activityScores,
        'category': space.metrics.category.toString().split('.').last,
        'size': space.metrics.size.toString().split('.').last,
        'engagementScore': space.metrics.engagementScore,
        'isTimeSensitive': space.metrics.isTimeSensitive,
        'expiryDate': space.metrics.expiryDate,
        'connectedFriends': space.metrics.connectedFriends,
        'firstActionPrompt': space.metrics.firstActionPrompt,
        'needsIntroduction': space.metrics.needsIntroduction,
      }
    };
  }

  /// Create a Space from a Firestore document
  static Space _spaceFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Parse metrics if available
    SpaceMetrics metrics = SpaceMetrics.empty();
    if (data['metrics'] != null && data['metrics'] is Map) {
      // Create a sanitized version of metrics data to avoid Timestamp errors
      final Map<String, dynamic> sanitizedMetrics = {};
      
      // Process the metrics map safely
      (data['metrics'] as Map<String, dynamic>).forEach((key, value) {
        // Handle Timestamp fields properly
        if (value is Timestamp) {
          sanitizedMetrics[key] = value.toDate();
        } else if (value is Map) {
          // Handle nested maps (like activityScores)
          final nestedMap = <String, dynamic>{};
          (value as Map<String, dynamic>).forEach((nestedKey, nestedValue) {
            nestedMap[nestedKey] = nestedValue;
          });
          sanitizedMetrics[key] = nestedMap;
        } else {
          // Copy other values as is
          sanitizedMetrics[key] = value;
        }
      });
      
      // Pass the sanitized metrics to the constructor
      metrics = SpaceMetrics.fromJson(sanitizedMetrics);
    }

    // Parse spaceType
    SpaceType spaceType = SpaceType.other;
    if (data['spaceType'] != null) {
      spaceType = _stringToSpaceType(data['spaceType'].toString());
    }

    // Parse and convert dates
    DateTime createdAt = DateTime.now();
    if (data['createdAt'] != null) {
      if (data['createdAt'] is Timestamp) {
        createdAt = (data['createdAt'] as Timestamp).toDate();
      }
    }

    DateTime updatedAt = DateTime.now();
    if (data['updatedAt'] != null) {
      if (data['updatedAt'] is Timestamp) {
        updatedAt = (data['updatedAt'] as Timestamp).toDate();
      }
    }

    // Default icon
    IconData icon = Icons.group;
    if (data['icon'] != null) {
      if (data['icon'] is int) {
        // Use predefined Material icons instead of creating new IconData
        final int codePoint = data['icon'] as int;
        switch (codePoint) {
          case 0xe318:
            icon = Icons.group;
            break;
          case 0xe1a5:
            icon = Icons.business;
            break;
          case 0xe332:
            icon = Icons.home;
            break;
          case 0xe30e:
            icon = Icons.forum;
            break;
          case 0xe0c9:
            icon = Icons.computer;
            break;
          case 0xe8f8:
            icon = Icons.school;
            break;
          case 0xe3ab:
            icon = Icons.people;
            break;
          case 0xe639:
            icon = Icons.sports;
            break;
          case 0xe430:
            icon = Icons.music_note;
            break;
          case 0xe40a:
            icon = Icons.palette;
            break;
          case 0xe465:
            icon = Icons.science;
            break;
          default:
            icon = Icons.group;
            break;
        }
      }
    }

    // Get space ID - either the document ID or the 'id' field if present
    String id = doc.id;
    if (data['id'] != null && data['id'] is String) {
      id = data['id'] as String;
    }

    // Return the constructed Space
    return Space(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      icon: icon,
      metrics: metrics,
      imageUrl: data['imageUrl'],
      bannerUrl: data['bannerUrl'],
      tags: data['tags'] != null ? List<String>.from(data['tags']) : [],
      customData: data['customData'] != null
          ? Map<String, dynamic>.from(data['customData'])
          : {},
      isJoined: data['isJoined'] ?? false,
      isPrivate: data['isPrivate'] ?? false,
      moderators: data['moderators'] != null
          ? List<String>.from(data['moderators'])
          : [],
      admins: data['admins'] != null ? List<String>.from(data['admins']) : [],
      quickActions: data['quickActions'] != null
          ? Map<String, String>.from(data['quickActions'])
          : {},
      relatedSpaceIds: data['relatedSpaceIds'] != null
          ? List<String>.from(data['relatedSpaceIds'])
          : [],
      createdAt: createdAt,
      updatedAt: updatedAt,
      spaceType: spaceType,
      eventIds:
          data['eventIds'] != null ? List<String>.from(data['eventIds']) : [],
    );
  }

  /// Convert a string to SpaceType enum
  static SpaceType _stringToSpaceType(String? value) {
    if (value == null) return SpaceType.other;

    switch (value.toLowerCase()) {
      case 'studentorg':
        return SpaceType.studentOrg;
      case 'universityorg':
        return SpaceType.universityOrg;
      case 'campusliving':
        return SpaceType.campusLiving;
      case 'fraternityandsorority':
        return SpaceType.fraternityAndSorority;
      default:
        return SpaceType.other;
    }
  }

  /// Initialize application-wide settings related to spaces
  static Future<void> initSettings() async {
    try {
      // Query for any existing settings document
      final settingsDoc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('spaces')
          .get();

      // If no settings document exists, create one with default values
      if (!settingsDoc.exists) {
        await FirebaseFirestore.instance
            .collection('settings')
            .doc('spaces')
            .set({
          'enableHierarchicalSpaces': true,
          'maxSpacesPerUser': 50,
          'lastUpdated': FieldValue.serverTimestamp(),
          'defaultSortBy': 'updatedAt',
          'defaultSortDescending': true,
        });
        debugPrint('Created default space settings');
      }
    } catch (error) {
      debugPrint('Error initializing space settings: $error');
      // Non-critical error, don't throw
    }
  }

  /// Creates a new space
  static Future<Space> createSpace({
    required String name,
    required String description,
    required SpaceType type,
    required Organization organization,
    required String createdBy,
  }) async {
    try {
      final now = DateTime.now();

      // Create a temporary ID that will be replaced with the Firestore ID
      final temporaryId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

      // Create a space object
      final Space space = Space(
        id: temporaryId,
        name: name,
        description: description,
        icon: type.icon,
        spaceType: type,
        organization: organization,
        metrics: SpaceMetrics.initial(organization.id),
        createdAt: now,
        updatedAt: now,
        moderators: [createdBy],
        admins: [createdBy],
      );

      // Add the space to Firestore
      final docRef = await _spacesCollection.add(_spaceToJson(space));

      // Create a new Space with the actual Firestore ID
      final newSpace = Space(
        id: docRef.id,
        name: name,
        description: description,
        icon: type.icon,
        spaceType: type,
        organization: organization,
        metrics: SpaceMetrics.initial(organization.id),
        createdAt: now,
        updatedAt: now,
        moderators: [createdBy],
        admins: [createdBy],
      );

      // Return the space with the generated ID
      return newSpace;
    } catch (error) {
      debugPrint('Error creating space: $error');
      throw Exception('Failed to create space: $error');
    }
  }

  /// Update a space's join status for a user
  static Future<Space> updateJoinStatus({
    required String spaceId,
    required bool isJoined,
    required String userId,
  }) async {
    try {
      // First try to get the space from the direct path
      final spaceRef = _spacesCollection.doc(spaceId);
      final spaceDoc = await spaceRef.get();
      
      // If space doesn't exist in main collection, search in all subcollections
      if (!spaceDoc.exists) {
        debugPrint('Space not found in main collection, searching in all paths');
        
        // Try to find in collection groups (all 'spaces' subcollections)
        final spaceQuery = await FirebaseFirestore.instance
            .collectionGroup('spaces')
            .where('id', isEqualTo: spaceId)
            .limit(1)
            .get();
            
        if (spaceQuery.docs.isEmpty) {
          // Also check older collection paths that might contain the space
          final legacyPaths = [
            'spaces/student_organizations/spaces',
            'spaces/greek_life/spaces',
            'spaces/university/spaces',
            'spaces/campus_living/spaces'
          ];
          
          DocumentSnapshot? foundDoc;
          for (final path in legacyPaths) {
            final query = await FirebaseFirestore.instance
                .collection(path)
                .where('id', isEqualTo: spaceId)
                .limit(1)
                .get();
                
            if (query.docs.isNotEmpty) {
              foundDoc = query.docs.first;
              break;
            }
          }
          
          if (foundDoc == null) {
            // If still not found, try matching by name converted to ID format
            // This addresses situations where spaces are clicked by name but joined by ID
            final allSpacesQuery = await FirebaseFirestore.instance
                .collectionGroup('spaces')
                .get();
                
            for (final doc in allSpacesQuery.docs) {
              final data = doc.data();
              if (data['name'] != null) {
                final generatedId = _generateSpaceIdFromName(data['name'].toString());
                if (generatedId == spaceId) {
                  foundDoc = doc;
                  break;
                }
              }
            }
            
            if (foundDoc == null) {
              throw Exception('Space does not exist in any collection');
            }
          }
          
          // Use the found document reference
          final currentSpace = _spaceFromFirestore(foundDoc);
          final docRef = foundDoc.reference;
          
          // Update member count and members
          await _updateSpaceMembership(docRef, currentSpace, isJoined, userId);
          
          // Get updated space
          final updatedDoc = await docRef.get();
          final updatedSpace = _spaceFromFirestore(updatedDoc);
          return updatedSpace.copyWith(isJoined: isJoined);
        } else {
          // Use the document from collection group
          final foundDoc = spaceQuery.docs.first;
          final currentSpace = _spaceFromFirestore(foundDoc);
          final docRef = foundDoc.reference;
          
          // Update member count and members
          await _updateSpaceMembership(docRef, currentSpace, isJoined, userId);
          
          // Get updated space
          final updatedDoc = await docRef.get();
          final updatedSpace = _spaceFromFirestore(updatedDoc);
          return updatedSpace.copyWith(isJoined: isJoined);
        }
      }
      
      // Handle the original path if space exists
      final currentSpace = _spaceFromFirestore(spaceDoc);
      await _updateSpaceMembership(spaceRef, currentSpace, isJoined, userId);
      
      // Get the updated space
      final updatedDoc = await spaceRef.get();
      final updatedSpace = _spaceFromFirestore(updatedDoc);

      // Return space with updated join status
      return updatedSpace.copyWith(isJoined: isJoined);
    } catch (error) {
      debugPrint('Error updating space join status: $error');
      throw Exception('Failed to update space join status: $error');
    }
  }
  
  /// Helper method to update space membership
  static Future<void> _updateSpaceMembership(
    DocumentReference docRef,
    Space currentSpace,
    bool isJoined,
    String userId
  ) async {
    // Update member count in metrics
    final currentMemberCount = currentSpace.metrics.memberCount;
    final newMemberCount = isJoined
        ? currentMemberCount + 1
        : (currentMemberCount > 0 ? currentMemberCount - 1 : 0);
    
    // Create update data
    final updateData = {
      'metrics.memberCount': newMemberCount,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    
    // Update members list if needed
    if (isJoined) {
      // Add to members if not already in list
      updateData['members'] = FieldValue.arrayUnion([userId]);
    } else {
      // Remove from members if in list
      updateData['members'] = FieldValue.arrayRemove([userId]);
    }
    
    // Update the space
    await docRef.update(updateData);
    
    // Get the user document to access followedSpaces
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    final userDoc = await userRef.get();
    final userData = userDoc.data();
    
    if (userData != null) {
      // Get current followedSpaces to calculate the new spaceCount
      List<String> followedSpaces = [];
      if (userData['followedSpaces'] is List) {
        followedSpaces = List<String>.from(userData['followedSpaces']);
      }
      
      // Update user document
      final updateUserData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (isJoined) {
        // Only add if not already in the list
        if (!followedSpaces.contains(currentSpace.id)) {
          followedSpaces.add(currentSpace.id);
          updateUserData['followedSpaces'] = FieldValue.arrayUnion([currentSpace.id]);
        }
      } else {
        // Only remove if it's in the list
        if (followedSpaces.contains(currentSpace.id)) {
          followedSpaces.remove(currentSpace.id);
          updateUserData['followedSpaces'] = FieldValue.arrayRemove([currentSpace.id]);
        }
      }
      
      // Always update spaceCount to match followedSpaces length
      updateUserData['spaceCount'] = followedSpaces.length;
      
      // Update the user document
      await userRef.update(updateUserData);
      
      debugPrint('Updated user document: followedSpaces count = ${followedSpaces.length}, spaceCount = ${followedSpaces.length}');
    } else {
      // Fallback to basic update if we couldn't get the user data
      if (isJoined) {
        await userRef.update({
          'followedSpaces': FieldValue.arrayUnion([currentSpace.id]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await userRef.update({
          'followedSpaces': FieldValue.arrayRemove([currentSpace.id]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  /// Get a space by ID
  static Future<Space?> getSpace(String id) async {
    // First check the cache
    if (_spaceCache.containsKey(id)) {
      return _spaceCache[id];
    }

    // Try to get the space from various paths in Firestore
    try {
      final spaceResult = await getFirestoreSpace(id);
      if (spaceResult != null) {
        // Add to cache for future quick access
        _spaceCache[id] = spaceResult;
        return spaceResult;
      }
    } catch (e) {
      debugPrint('Error getting space $id: $e');
    }

    return null;
  }

  /// Updates a space
  static Future<Space> updateSpace({
    required String spaceId,
    String? name,
    String? description,
    SpaceType? type,
  }) async {
    try {
      final spaceRef = _spacesCollection.doc(spaceId);
      final spaceDoc = await spaceRef.get();

      if (!spaceDoc.exists) {
        throw Exception('Space does not exist');
      }

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (type != null) {
        updateData['spaceType'] = type.toString().split('.').last;
      }

      await spaceRef.update(updateData);

      // Get the updated space
      final updatedDoc = await spaceRef.get();
      return _spaceFromFirestore(updatedDoc);
    } catch (error) {
      debugPrint('Error updating space: $error');
      throw Exception('Failed to update space: $error');
    }
  }

  /// Get spaces for an organization
  static Future<List<Space>> getSpacesForOrganization(String organizationId,
      {int limit = 10}) async {
    try {
      final query = _spacesCollection
          .where('organizationId', isEqualTo: organizationId)
          .limit(limit);

      final snapshot = await query.get();

      return snapshot.docs.map((doc) => _spaceFromFirestore(doc)).toList();
    } catch (error) {
      debugPrint('Error getting spaces for organization: $error');
      throw Exception('Failed to get spaces for organization: $error');
    }
  }

  /// Get all spaces (non-paginated)
  static Future<List<Space>> getSpaces() async {
    try {
      final snapshot = await _spacesCollection.limit(100).get();
      return snapshot.docs.map((doc) => _spaceFromFirestore(doc)).toList();
    } catch (error) {
      debugPrint('Error getting spaces: $error');
      throw Exception('Failed to get spaces: $error');
    }
  }

  /// Get spaces with pagination
  static Future<PaginatedResult<Space>> getSpacesPaginated({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String sortBy = 'updatedAt',
    bool sortDescending = true,
    bool includePrivate = true, // Default to showing all spaces
  }) async {
    try {
      Query query = _spacesCollection;

      // Apply privacy filter if needed
      if (!includePrivate) {
        // Only include spaces where isPrivate is false or not set
        query = query.where('isPrivate', isEqualTo: false);
      }

      // Apply sorting
      query = query.orderBy(sortBy, descending: sortDescending);

      // Apply pagination
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      // Apply limit
      query = query.limit(limit);

      // Execute query
      final snapshot = await query.get();

      // Parse results
      final spaces =
          snapshot.docs.map((doc) => _spaceFromFirestore(doc)).toList();

      // Return paginated result
      return PaginatedResult<Space>(
        items: spaces,
        hasMore: spaces.length >= limit,
        lastDocument: spaces.isNotEmpty ? snapshot.docs.last : null,
      );
    } catch (error) {
      debugPrint('Error getting paginated spaces: $error');
      throw Exception('Failed to get paginated spaces: $error');
    }
  }

  /// Get spaces from a specific type path
  static Future<List<Space>> getSpacesByTypePath({
    required String collectionPath,
    int limit = 20,
    bool useCache = false,
    bool includePrivate = true, // Default to showing all spaces
  }) async {
    try {
      final path = 'spaces/$collectionPath/spaces';
      Query query = FirebaseFirestore.instance.collection(path);
      
      // Apply privacy filter if needed
      if (!includePrivate) {
        // Only include spaces where isPrivate is false or not set
        query = query.where('isPrivate', isEqualTo: false);
      }
      
      // Apply limit
      query = query.limit(limit);

      // Execute query
      final snapshot = await query.get();

      // Parse results
      return snapshot.docs.map((doc) {
        // Just use _spaceFromFirestore which already handles ID properly
        return _spaceFromFirestore(doc);
      }).toList();
    } catch (error) {
      debugPrint('Error getting spaces by type path: $error');
      // Return empty list instead of throwing for this method
      return [];
    }
  }

  /// Get spaces for a specific user by their IDs
  static Future<List<Space>> getUserSpaces(List<String> spaceIds) async {
    if (spaceIds.isEmpty) return [];

    try {
      debugPrint('🔍 SpaceService.getUserSpaces - Fetching ${spaceIds.length} spaces');
      
      // First check memory cache for any spaces we already have
      final List<Space> cachedSpaces = [];
      final List<String> missingSpaceIds = [];
      
      // Deduplicate spaceIds to prevent redundant queries
      final uniqueSpaceIds = spaceIds.toSet().toList();
      
      for (final spaceId in uniqueSpaceIds) {
        final cachedSpace = _spaceCache[spaceId];
        if (cachedSpace != null) {
          cachedSpaces.add(cachedSpace);
        } else {
          missingSpaceIds.add(spaceId);
        }
      }
      
      debugPrint('🔍 SpaceService.getUserSpaces - Found ${cachedSpaces.length} spaces in cache, ${missingSpaceIds.length} missing');
      
      // If all spaces were in cache, return early
      if (missingSpaceIds.isEmpty) {
        return cachedSpaces;
      }
      
      // Try to get missing spaces from the getFirestoreSpace method first
      final List<Space> firestoreResults = [];
      final List<String> stillMissingIds = [];
      
      // Track spaces we've already attempted to find to prevent infinite loops
      final Set<String> attemptedIds = {};
      
      for (final spaceId in missingSpaceIds) {
        // Skip if we've already attempted this ID
        if (attemptedIds.contains(spaceId)) continue;
        
        attemptedIds.add(spaceId);
        
        // Use a timeout to prevent hanging on problematic queries
        try {
          final space = await getFirestoreSpace(spaceId).timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              debugPrint('⏱️ Timeout fetching space $spaceId');
              return null;
            },
          );
          
          if (space != null) {
            firestoreResults.add(space);
            _spaceCache[space.id] = space; // Update memory cache
          } else {
            stillMissingIds.add(spaceId);
          }
        } catch (e) {
          debugPrint('❌ Error fetching space $spaceId: $e');
          stillMissingIds.add(spaceId);
        }
      }
      
      // If we still have missing spaces, try batch lookup in chunks
      if (stillMissingIds.isNotEmpty) {
        debugPrint('🔍 SpaceService.getUserSpaces - Still missing ${stillMissingIds.length} spaces after getFirestoreSpace');
        
        // Firestore has a limit of 10 items in a whereIn query
        const chunkSize = 10;
        
        // Process in chunks of 10
        for (var i = 0; i < stillMissingIds.length; i += chunkSize) {
          final end = (i + chunkSize < stillMissingIds.length) 
              ? i + chunkSize 
              : stillMissingIds.length;
          final chunk = stillMissingIds.sublist(i, end);
          
          // Deduplicate chunk to prevent redundant queries
          final uniqueChunk = chunk.toSet().toList();
          
          try {
            // First try querying the main spaces collection
            final query = _spacesCollection.where(FieldPath.documentId, whereIn: uniqueChunk);
            final snapshot = await query.get().timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                debugPrint('⏱️ Timeout querying main collection for chunk');
                throw TimeoutException('Query timeout');
              },
            );
            
            if (snapshot.docs.isNotEmpty) {
              final spaces = snapshot.docs.map((doc) => _spaceFromFirestore(doc)).toList();
              
              // Add to results and cache each space
              for (final space in spaces) {
                attemptedIds.add(space.id); // Mark as attempted
                firestoreResults.add(space);
                _spaceCache[space.id] = space; // Update memory cache
              }
              
              debugPrint('🔍 SpaceService.getUserSpaces - Found ${spaces.length} spaces in main collection');
            } else {
              debugPrint('⚠️ SpaceService.getUserSpaces - No spaces found in main collection for chunk');
            }
          } catch (e) {
            debugPrint('❌ SpaceService.getUserSpaces - Error querying main collection: $e');
          }
          
          // If we still have missing spaces in this chunk, try direct path lookups
          final foundIds = firestoreResults.map((s) => s.id).toList();
          final stillMissingInChunk = uniqueChunk.where((id) => !foundIds.contains(id) && !attemptedIds.contains(id)).toList();
          
          if (stillMissingInChunk.isNotEmpty) {
            try {
              // Try checking in hive_exclusive collection first
              for (final missingId in stillMissingInChunk) {
                // Skip if we've already attempted this ID
                if (attemptedIds.contains(missingId)) continue;
                
                attemptedIds.add(missingId);
                
                try {
                  final hiveExclusiveRef = FirebaseFirestore.instance
                      .collection('spaces/hive_exclusive/spaces')
                      .doc(missingId);
                      
                  final doc = await hiveExclusiveRef.get().timeout(
                    const Duration(seconds: 3),
                    onTimeout: () {
                      debugPrint('⏱️ Timeout querying hive_exclusive for $missingId');
                      throw TimeoutException('Query timeout');
                    },
                  );
                  
                  if (doc.exists && doc.data() != null) {
                    debugPrint('✅ SpaceService.getUserSpaces - Found space $missingId in hive_exclusive collection');
                    // Manually create Space object to avoid index errors
                    final data = doc.data()!;
                    // Ensure ID is set correctly
                    data['id'] = missingId;
                    final space = Space.fromJson(data);
                    firestoreResults.add(space);
                    _spaceCache[space.id] = space; // Update memory cache
                  }
                } catch (e) {
                  debugPrint('❌ SpaceService.getUserSpaces - Error querying hive_exclusive for $missingId: $e');
                }
              }
              
              // For IDs still missing, try collectionGroup
              final afterHiveIds = firestoreResults.map((s) => s.id).toList();
              final stillMissingAfterHive = stillMissingInChunk.where((id) => 
                  !afterHiveIds.contains(id) && !attemptedIds.contains(id)).toList();
              
              if (stillMissingAfterHive.isNotEmpty) {
                debugPrint('🔍 SpaceService.getUserSpaces - Trying collectionGroup for ${stillMissingAfterHive.length} remaining spaces');
                
                // Use collectionGroup to find spaces across all subcollections
                final results = <Space>[];
                for (final missingId in stillMissingAfterHive) {
                  // Skip if we've already attempted this ID
                  if (attemptedIds.contains(missingId)) continue;
                  
                  attemptedIds.add(missingId);
                  
                  try {
                    final spaceQuery = await FirebaseFirestore.instance
                        .collectionGroup('spaces')
                        .where('id', isEqualTo: missingId)
                        .limit(1)
                        .get()
                        .timeout(
                          const Duration(seconds: 3),
                          onTimeout: () {
                            debugPrint('⏱️ Timeout in collectionGroup query for $missingId');
                            throw TimeoutException('Query timeout');
                          },
                        );
                        
                    if (spaceQuery.docs.isNotEmpty) {
                      try {
                        final space = _spaceFromFirestore(spaceQuery.docs.first);
                        results.add(space);
                        _spaceCache[space.id] = space; // Update memory cache
                      } catch (e) {
                        debugPrint('❌ SpaceService.getUserSpaces - Error parsing space from collectionGroup: $e');
                      }
                    }
                  } catch (e) {
                    debugPrint('❌ SpaceService.getUserSpaces - Error in collectionGroup query for $missingId: $e');
                  }
                }
                
                if (results.isNotEmpty) {
                  debugPrint('🔍 SpaceService.getUserSpaces - Found ${results.length} additional spaces with collectionGroup');
                  firestoreResults.addAll(results);
                }
              }
            } catch (e) {
              debugPrint('❌ SpaceService.getUserSpaces - Error with additional queries: $e');
            }
          }
        }
      }
      
      // Combine cached and Firestore results
      final allResults = [...cachedSpaces, ...firestoreResults];
      
      // Check if we got all the spaces or if some are still missing
      final retrievedIds = allResults.map((space) => space.id).toSet();
      final finalMissingIds = uniqueSpaceIds.where((id) => !retrievedIds.contains(id)).toList();
      
      if (finalMissingIds.isNotEmpty) {
        debugPrint('⚠️ SpaceService.getUserSpaces - Still missing ${finalMissingIds.length} spaces after all attempts');
        debugPrint('⚠️ SpaceService.getUserSpaces - Missing IDs: $finalMissingIds');
      } else {
        debugPrint('✅ SpaceService.getUserSpaces - Successfully retrieved all ${uniqueSpaceIds.length} spaces');
      }
      
      return allResults;
    } catch (error) {
      debugPrint('❌ SpaceService.getUserSpaces - Error getting user spaces: $error');
      // Return what we have in cache instead of throwing
      final cachedResults = spaceIds
          .map((id) => _spaceCache[id])
          .where((space) => space != null)
          .cast<Space>()
          .toList();
      
      if (cachedResults.isNotEmpty) {
        debugPrint('⚠️ SpaceService.getUserSpaces - Returning ${cachedResults.length} spaces from cache after error');
        return cachedResults;
      }
      
      throw Exception('Failed to get user spaces: $error');
    }
  }

  /// Get trending spaces based on metrics
  static Future<List<Space>> getTrendingSpaces({int limit = 20}) async {
    try {
      // Query spaces where isTrending is true in metrics
      final query = _spacesCollection
          .where('metrics.isTrending', isEqualTo: true)
          .orderBy('metrics.engagementScore', descending: true)
          .limit(limit);

      final snapshot = await query.get();

      return snapshot.docs.map((doc) => _spaceFromFirestore(doc)).toList();
    } catch (error) {
      debugPrint('Error getting trending spaces: $error');
      // Return empty list instead of throwing
      return [];
    }
  }

  /// Get spaces by space type
  static Future<List<Space>> getSpacesByType(SpaceType type,
      {int limit = 20}) async {
    try {
      final typeString = type.toString().split('.').last;
      final query = _spacesCollection
          .where('spaceType', isEqualTo: typeString)
          .limit(limit);

      final snapshot = await query.get();

      return snapshot.docs.map((doc) => _spaceFromFirestore(doc)).toList();
    } catch (error) {
      debugPrint('Error getting spaces by type: $error');
      // Return empty list instead of throwing
      return [];
    }
  }

  /// Get all spaces grouped by type
  static Future<Map<SpaceType, List<Space>>> getAllSpacesByType(
      {int limit = 100}) async {
    try {
      final result = <SpaceType, List<Space>>{};
      final allTypes = [
        SpaceType.studentOrg,
        SpaceType.universityOrg,
        SpaceType.campusLiving,
        SpaceType.fraternityAndSorority,
        SpaceType.other,
      ];

      // Initialize with empty lists
      for (final type in allTypes) {
        result[type] = [];
      }

      // Get all spaces at once
      final snapshot = await _spacesCollection.limit(limit).get();
      final spaces =
          snapshot.docs.map((doc) => _spaceFromFirestore(doc)).toList();

      // Categorize spaces by type
      for (final space in spaces) {
        final spaceType = space.spaceType;
        result[spaceType] = [...result[spaceType]!, space];
      }

      return result;
    } catch (error) {
      debugPrint('Error getting all spaces by type: $error');
      // Return empty result instead of throwing
      return {};
    }
  }

  /// Get spaces that have scheduled events
  static Future<List<Space>> getSpacesWithEvents({int limit = 20}) async {
    try {
      // Query spaces where eventIds is not empty
      final query =
          _spacesCollection.where('eventIds', isNotEqualTo: []).limit(limit);

      final snapshot = await query.get();

      return snapshot.docs.map((doc) => _spaceFromFirestore(doc)).toList();
    } catch (error) {
      debugPrint('Error getting spaces with events: $error');
      // Try a different approach if the first one fails
      try {
        // Get all spaces and filter for ones with events
        final snapshot = await _spacesCollection
            .limit(limit * 2)
            .get(); // Get more to account for filtering
        final spaces =
            snapshot.docs.map((doc) => _spaceFromFirestore(doc)).toList();

        // Filter for spaces with events
        final spacesWithEvents = spaces
            .where((space) =>
                space.eventIds.isNotEmpty || space.metrics.weeklyEvents > 0)
            .take(limit)
            .toList();

        return spacesWithEvents;
      } catch (fallbackError) {
        debugPrint('Fallback error getting spaces with events: $fallbackError');
        return [];
      }
    }
  }

  /// Get spaces that have specific events by eventIds
  static Future<List<Space>> getSpacesWithSpecificEvents(
      List<String> eventIds) async {
    if (eventIds.isEmpty) return [];

    try {
      // Firestore has a limit of 10 items in an arrayContainsAny query
      const chunkSize = 10;
      final List<Space> results = [];

      // Process in chunks of 10
      for (var i = 0; i < eventIds.length; i += chunkSize) {
        final end =
            (i + chunkSize < eventIds.length) ? i + chunkSize : eventIds.length;
        final chunk = eventIds.sublist(i, end);

        // Query spaces where eventIds array contains any of the eventIds in the chunk
        final query = _spacesCollection
            .where('eventIds', arrayContainsAny: chunk)
            .limit(50); // Increased limit to ensure we get all relevant spaces

        final snapshot = await query.get();
        final spaces =
            snapshot.docs.map((doc) => _spaceFromFirestore(doc)).toList();

        // Add to results, avoiding duplicates
        for (final space in spaces) {
          if (!results.any((s) => s.id == space.id)) {
            results.add(space);
          }
        }
      }

      return results;
    } catch (error) {
      debugPrint('Error getting spaces with specific events: $error');
      // Return empty list instead of throwing
      return [];
    }
  }

  /// Search spaces by name matching a query string
  static Future<List<Space>> searchSpacesByName(String query) async {
    if (query.isEmpty) {
      return [];
    }

    // First, search in the cache
    List<Space> results = [];
    
    // If we have cached spaces, search there first
    if (_spaceCache.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      results = _spaceCache.values
          .where((space) => 
              space.name.toLowerCase().contains(lowerQuery) ||
              space.description.toLowerCase().contains(lowerQuery) ||
              space.tags.any((tag) => tag.toLowerCase().contains(lowerQuery)))
          .toList();
    }

    // If we don't have results from cache or cache is empty, search Firestore
    if (results.isEmpty) {
      try {
        // Get spaces from Firestore
        debugPrint('Searching in Firestore for: $query');
        final snapshot = await _spacesCollection
            .orderBy('name')
            .get();

        // Filter for matches in name, description, or tags
        final lowerQuery = query.toLowerCase();
        final firestoreSpaces = snapshot.docs
            .map((doc) => _spaceFromFirestore(doc))
            .where((space) =>
                space.name.toLowerCase().contains(lowerQuery) ||
                space.description.toLowerCase().contains(lowerQuery) ||
                space.tags.any((tag) => tag.toLowerCase().contains(lowerQuery)))
            .toList();

        results.addAll(firestoreSpaces);
        
        // Add results to cache
        for (final space in firestoreSpaces) {
          _spaceCache[space.id] = space;
        }
      } catch (e) {
        debugPrint('Error searching spaces in Firestore: $e');
      }
    }

    return results;
  }
  
  /// Search spaces by partial ID match
  static Future<List<Space>> searchSpacesById(String idPattern) async {
    if (idPattern.isEmpty || idPattern.length < 3) {
      return [];
    }
    
    final lowerPattern = idPattern.toLowerCase();
    List<Space> results = [];
    
    // First, search in cache
    if (_spaceCache.isNotEmpty) {
      results = _spaceCache.values
          .where((space) => space.id.toLowerCase().contains(lowerPattern))
          .toList();
          
      if (results.isNotEmpty) {
        debugPrint('Found ${results.length} spaces with ID containing "$idPattern" in cache');
        return results;
      }
    }
    
    // If not found in cache, load all spaces and search
    try {
      // Load all spaces into cache if needed
      if (_spaceCache.isEmpty) {
        await loadSpacesFromFirestore();
      }
      
      // Try collection group query for efficiency
      final collectionGroupQuery = await FirebaseFirestore.instance
          .collectionGroup('spaces')
          .get();
          
      results = collectionGroupQuery.docs
          .map((doc) => _spaceFromFirestore(doc))
          .where((space) => space.id.toLowerCase().contains(lowerPattern))
          .toList();
      
      // Add to cache
      for (final space in results) {
        _spaceCache[space.id] = space;
      }
      
      debugPrint('Found ${results.length} spaces with ID containing "$idPattern" in Firestore');
      return results;
    } catch (e) {
      debugPrint('Error searching spaces by ID pattern: $e');
      return [];
    }
  }

  /// Stream a space for real-time updates
  static Stream<Space?> streamSpace(String spaceId) {
    return _spacesCollection.doc(spaceId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return _spaceFromFirestore(snapshot);
    });
  }

  /// Save a Space to Firestore
  static Future<DocumentReference> saveSpace(Space space) async {
    try {
      // Convert space to Firestore-friendly JSON
      final data = _spaceToJson(space);

      // Add the space to Firestore
      await _spacesCollection.doc(space.id).set(data);

      return _spacesCollection.doc(space.id);
    } catch (error) {
      debugPrint('Error saving space: $error');
      throw Exception('Failed to save space: $error');
    }
  }

  /// Add an event to a space
  static Future<void> addEventToSpace(String spaceId, String eventId) async {
    try {
      final spaceRef = _spacesCollection.doc(spaceId);

      // Update the space with the new event ID
      await spaceRef.update({
        'eventIds': FieldValue.arrayUnion([eventId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Also try updating metrics
      try {
        await spaceRef.update({
          'metrics.weeklyEvents': FieldValue.increment(1),
        });
      } catch (metricsError) {
        // Non-critical error, continue without updating metrics
        debugPrint(
            'Warning: Could not update event metrics for space: $metricsError');
      }
    } catch (error) {
      debugPrint('Error adding event to space: $error');
      throw Exception('Failed to add event to space: $error');
    }
  }

  /// Verify event-space assignments and find unassigned events
  static Future<Map<String, dynamic>> verifyEventSpaceAssignments() async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Get all events
      final eventsSnapshot = await firestore.collection('events').get();
      debugPrint('Found ${eventsSnapshot.docs.length} events to verify');

      // Get all spaces (from root collection)
      final spacesSnapshot = await firestore.collection('spaces').get();
      final rootSpaces = spacesSnapshot.docs;

      // Get spaces from hierarchical structure
      final List<QueryDocumentSnapshot> hierarchicalSpaces = [];

      // Define type collections to check
      final typeCollections = [
        'student_organizations',
        'university_organizations',
        'campus_living',
        'fraternity_and_sorority',
        'other'
      ];

      // Fetch spaces from each type collection
      for (final typeCollection in typeCollections) {
        try {
          final typeSpacesSnapshot = await firestore
              .collection('spaces')
              .doc(typeCollection)
              .collection('spaces')
              .get();

          hierarchicalSpaces.addAll(typeSpacesSnapshot.docs);
          debugPrint(
              'Found ${typeSpacesSnapshot.docs.length} spaces in $typeCollection');
        } catch (e) {
          debugPrint('Error fetching spaces from $typeCollection: $e');
          // Continue with other collections
        }
      }

      debugPrint(
          'Found ${rootSpaces.length} root spaces and ${hierarchicalSpaces.length} hierarchical spaces');

      // Map of eventId -> spaceId for events assigned to spaces
      final Map<String, String> eventSpaceAssignments = {};

      // Process root spaces
      for (final spaceDoc in rootSpaces) {
        final spaceData = spaceDoc.data();
        final List<dynamic> eventIds =
            spaceData['eventIds'] as List<dynamic>? ?? [];

        for (final eventId in eventIds) {
          eventSpaceAssignments[eventId.toString()] = spaceDoc.id;
        }
      }

      // Process hierarchical spaces
      for (final spaceDoc in hierarchicalSpaces) {
        final spaceData = spaceDoc.data() as Map<String, dynamic>?;
        if (spaceData == null) continue;

        final List<dynamic> eventIds =
            spaceData['eventIds'] as List<dynamic>? ?? [];

        for (final eventId in eventIds) {
          eventSpaceAssignments[eventId.toString()] = spaceDoc.id;
        }
      }

      // Find unassigned events (events not in any space)
      final List<Map<String, dynamic>> unassignedEvents = [];
      final List<Map<String, dynamic>> eventsWithMissingOrganizerName = [];

      for (final eventDoc in eventsSnapshot.docs) {
        final eventId = eventDoc.id;
        final Map<String, dynamic>? eventData =
            eventDoc.data() as Map<String, dynamic>?;

        if (eventData == null) continue;

        // Check if this event is assigned to a space
        if (!eventSpaceAssignments.containsKey(eventId)) {
          // This event is not associated with any space
          final organizerName = eventData['organizerName'] as String?;

          final Map<String, dynamic> eventInfo = {
            'eventId': eventId,
            'title': eventData['title'] ?? 'No Title',
            'organizerName': organizerName,
            'startDate': eventData['startDate'] != null
                ? (eventData['startDate'] as Timestamp).toDate().toString()
                : 'Unknown Date',
          };

          // Add to unassigned events list
          unassignedEvents.add(eventInfo);

          // If it's missing organizer name, add to that list too
          if (organizerName == null || organizerName.trim().isEmpty) {
            eventsWithMissingOrganizerName.add(eventInfo);
          }
        }
      }

      return {
        'totalEvents': eventsSnapshot.docs.length,
        'totalRootSpaces': rootSpaces.length,
        'totalHierarchicalSpaces': hierarchicalSpaces.length,
        'assignedEvents': eventSpaceAssignments.length,
        'unassignedEvents': unassignedEvents,
        'eventsWithMissingOrganizerName': eventsWithMissingOrganizerName,
        'percentAssigned': eventsSnapshot.docs.isEmpty
            ? 100
            : (eventSpaceAssignments.length / eventsSnapshot.docs.length * 100)
                .round()
      };
    } catch (e) {
      debugPrint('Error verifying event-space assignments: $e');
      return {'error': e.toString()};
    }
  }

  /// Get a space from Firestore by ID
  static Future<Space?> getFirestoreSpace(String id) async {
    final firestore = FirebaseFirestore.instance;
    
    // Define the collections where spaces can be stored
    final spacePaths = [
      'spaces', // Check root collection first
      'spaces/hive_exclusive/spaces', // Add HIVE exclusive path
      'spaces/student_organizations/spaces',
      'spaces/university/spaces',
      'spaces/campus_living/spaces',
      'spaces/greek_life/spaces',
      'spaces/other/spaces',
    ];

    // Keep track of already attempted paths to prevent redundant queries
    final attemptedPaths = <String>{};
    
    // Try each path
    for (final path in spacePaths) {
      // Skip if we've already tried this path
      if (attemptedPaths.contains(path)) {
        continue;
      }
      
      attemptedPaths.add(path);
      try {
        DocumentSnapshot doc;
        if (path == 'spaces') {
          // Direct path for root collection
          doc = await firestore.collection(path).doc(id).get();
        } else {
          // For nested collections, we need to get the document directly
          doc = await firestore.doc('$path/$id').get();
        }
        
        if (doc.exists) {
          debugPrint('Found space $id in $path');
          return _spaceFromFirestore(doc);
        }
      } catch (e) {
        // Continue to next path
        debugPrint('Error checking $path for space $id: $e');
      }
    }
    
    // If not found in direct paths, try collectionGroup query once
    try {
      // Skip collectionGroup query if we've already tried looking up this ID multiple times
      // to prevent excessive queries
      debugPrint('Trying collectionGroup query for space $id');
      final querySnapshot = await firestore
          .collectionGroup('spaces')
          .where('id', isEqualTo: id)
          .limit(1)
          .get();
          
      if (querySnapshot.docs.isNotEmpty) {
        final path = querySnapshot.docs.first.reference.path;
        debugPrint('Found space $id using collectionGroup: $path');
        
        // Add this path to attempted paths to prevent redundant queries
        attemptedPaths.add(path);
        
        return _spaceFromFirestore(querySnapshot.docs.first);
      }
    } catch (e) {
      debugPrint('Error in collectionGroup query for space $id: $e');
    }
    
    debugPrint('Space $id not found in any path');
    return null;
  }
}
