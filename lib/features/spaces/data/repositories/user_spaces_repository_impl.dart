import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_metrics_entity.dart';
import 'package:hive_ui/features/spaces/domain/repositories/user_spaces_repository.dart';
import 'package:hive_ui/features/spaces/data/datasources/spaces_firestore_datasource.dart';
import 'package:hive_ui/services/space_service.dart';
import 'package:hive_ui/features/spaces/utils/model_converters.dart';

/// Implementation of the UserSpacesRepository interface
class UserSpacesRepositoryImpl implements UserSpacesRepository {
  final FirebaseFirestore _firestore;
  final SpacesFirestoreDataSource _spacesDataSource;

  /// Constructor
  UserSpacesRepositoryImpl({
    FirebaseFirestore? firestore,
    SpacesFirestoreDataSource? spacesDataSource,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _spacesDataSource = spacesDataSource ?? SpacesFirestoreDataSource();

  @override
  Future<List<SpaceEntity>> getUserSpaces(String userId) async {
    try {
      // Get user document from Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        debugPrint('User document not found: $userId');
        return [];
      }

      // Extract space IDs from the followedSpaces field
      final data = userDoc.data();
      final List<String> spaceIds = [];
      
      if (data != null && data['followedSpaces'] != null) {
        if (data['followedSpaces'] is List) {
          spaceIds.addAll(List<String>.from(data['followedSpaces']));
          debugPrint('Found ${spaceIds.length} spaces in followedSpaces: $spaceIds');
        }
      } else {
        debugPrint('No followedSpaces found in user document');
      }
      
      // Also check joinedClubs for backward compatibility
      if (spaceIds.isEmpty && data != null && data['joinedClubs'] != null) {
        if (data['joinedClubs'] is List) {
          final joinedClubs = List<String>.from(data['joinedClubs']);
          spaceIds.addAll(joinedClubs);
          debugPrint('Found ${joinedClubs.length} spaces in joinedClubs for backward compatibility: $joinedClubs');
          
          // If we found clubs in joinedClubs but not in followedSpaces, 
          // let's update followedSpaces for future consistency
          if (joinedClubs.isNotEmpty) {
            try {
              await _firestore.collection('users').doc(userId).update({
                'followedSpaces': FieldValue.arrayUnion(joinedClubs),
                'updatedAt': FieldValue.serverTimestamp(),
              });
              debugPrint('Updated followedSpaces with joinedClubs for consistency');
            } catch (e) {
              debugPrint('Error updating followedSpaces with joinedClubs: $e');
            }
          }
        }
      }

      // Also check users/{userId}/spaces subcollection for backward compatibility
      final userSpacesQuery = await _firestore
          .collection('users')
          .doc(userId)
          .collection('spaces')
          .where('isActive', isEqualTo: true)
          .get();

      // Add space IDs from the subcollection
      final List<String> legacySpaceIds = [];
      for (final doc in userSpacesQuery.docs) {
        if (!spaceIds.contains(doc.id)) {
          spaceIds.add(doc.id);
          legacySpaceIds.add(doc.id);
        }
      }
      
      if (legacySpaceIds.isNotEmpty) {
        debugPrint('Found ${legacySpaceIds.length} spaces in legacy collection: $legacySpaceIds');
      }

      if (spaceIds.isEmpty) {
        debugPrint('No spaces found for user $userId');
        return [];
      }

      // Get space details for each ID
      List<SpaceEntity> spaces = [];
      List<String> failedSpaceIds = [];
      
      debugPrint('Fetching details for ${spaceIds.length} spaces');
      
      for (final spaceId in spaceIds) {
        try {
          final space = await _spacesDataSource.getSpaceById(spaceId);
          if (space != null) {
            // Mark the space as joined since it's in the user's spaces
            spaces.add(space.toEntity().copyWith(isJoined: true));
            debugPrint('Successfully fetched space: ${space.id} (${space.name})');
          } else {
            failedSpaceIds.add(spaceId);
            debugPrint('Space not found: $spaceId');
          }
        } catch (e) {
          failedSpaceIds.add(spaceId);
          debugPrint('Error fetching space $spaceId: $e');
        }
      }
      
      if (failedSpaceIds.isNotEmpty) {
        debugPrint('Failed to fetch ${failedSpaceIds.length} spaces: $failedSpaceIds');
        
        // Try to fetch using SpaceService as fallback
        try {
          debugPrint('Attempting to fetch failed spaces using SpaceService');
          final fallbackSpaces = await SpaceService.getUserSpaces(failedSpaceIds);
          
          if (fallbackSpaces.isNotEmpty) {
            debugPrint('Retrieved ${fallbackSpaces.length} spaces using fallback method');
            
            // Convert legacy Space objects to SpaceEntity
            for (final legacySpace in fallbackSpaces) {
              try {
                final spaceEntity = SpaceModelConverters.convertLegacySpaceToEntity(legacySpace);
                spaces.add(spaceEntity.copyWith(isJoined: true));
                debugPrint('Successfully converted legacy space: ${legacySpace.id}');
              } catch (e) {
                debugPrint('Error converting legacy space ${legacySpace.id}: $e');
              }
            }
          }
        } catch (e) {
          debugPrint('Error using fallback method: $e');
        }
      }

      debugPrint('Returning ${spaces.length} spaces for user $userId');
      return spaces;
    } catch (e) {
      debugPrint('Error getting user spaces: $e');
      throw Exception('Failed to get user spaces: $e');
    }
  }

  @override
  Future<void> joinSpace(String userId, String spaceId) async {
    try {
      // Get current timestamp
      final now = FieldValue.serverTimestamp();

      // Update the user document to add the space ID to followedSpaces
      await _firestore
          .collection('users')
          .doc(userId)
          .update({
        'followedSpaces': FieldValue.arrayUnion([spaceId]),
        'updatedAt': now,
      });

      // For backward compatibility, maintain user/{userId}/spaces/{spaceId}
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('spaces')
          .doc(spaceId)
          .set({
        'joinedAt': now,
        'updatedAt': now,
        'isActive': true,
      }, SetOptions(merge: true));

      // Also update the space to add the user and increment member count
      await SpaceService.updateJoinStatus(
        spaceId: spaceId, 
        isJoined: true, 
        userId: userId,
      );
      
    } catch (e) {
      debugPrint('Error joining space: $e');
      throw Exception('Failed to join space: $e');
    }
  }

  @override
  Future<void> leaveSpace(String userId, String spaceId) async {
    try {
      // Update the user document to remove the space ID from followedSpaces
      await _firestore
          .collection('users')
          .doc(userId)
          .update({
        'followedSpaces': FieldValue.arrayRemove([spaceId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // For backward compatibility, update the spaces subcollection
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('spaces')
          .doc(spaceId)
          .set({
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': false,
        'leftAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Also update the space to remove the user and decrement member count
      await SpaceService.updateJoinStatus(
        spaceId: spaceId, 
        isJoined: false, 
        userId: userId,
      );
      
    } catch (e) {
      debugPrint('Error leaving space: $e');
      throw Exception('Failed to leave space: $e');
    }
  }

  @override
  Future<bool> hasJoinedSpace(String userId, String spaceId) async {
    try {
      // Check if the spaceId is in the user's followedSpaces
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return false;
      }

      final data = userDoc.data();
      if (data != null && data['followedSpaces'] != null) {
        if (data['followedSpaces'] is List) {
          final followedSpaces = List<String>.from(data['followedSpaces']);
          if (followedSpaces.contains(spaceId)) {
            return true;
          }
        }
      }

      // If not found in followedSpaces, check the spaces subcollection for backward compatibility
      final spaceDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('spaces')
          .doc(spaceId)
          .get();

      return spaceDoc.exists && (spaceDoc.data()?['isActive'] == true);
    } catch (e) {
      debugPrint('Error checking if user joined space: $e');
      return false;
    }
  }

  @override
  Future<List<String>> getSpaceMembers(String spaceId) async {
    try {
      // Query users collection for all users who have this spaceId in their followedSpaces
      final query = await _firestore
          .collection('users')
          .where('followedSpaces', arrayContains: spaceId)
          .get();

      final userIds = query.docs.map((doc) => doc.id).toList();

      // If no users found, check the old user_spaces collection as fallback
      if (userIds.isEmpty) {
        final legacyQuery = await _firestore
            .collection('user_spaces')
            .where('spaceId', isEqualTo: spaceId)
            .where('isJoined', isEqualTo: true)
            .get();

        return legacyQuery.docs
            .map((doc) => doc.data()['userId'] as String)
            .toList();
      }

      return userIds;
    } catch (e) {
      debugPrint('Error getting space members: $e');
      return [];
    }
  }

  @override
  Future<List<SpaceEntity>> getRecommendedSpaces(String userId) async {
    try {
      // Get user's joined spaces first
      final userSpaces = await getUserSpaces(userId);
      final joinedSpaceIds = userSpaces.map((s) => s.id).toSet();

      // Get trending/popular spaces as a base for recommendations
      final trendingSpaces = await _spacesDataSource.getTrendingSpaces();
      
      // Filter out spaces the user has already joined
      final recommendedSpaces = trendingSpaces
          .where((space) => !joinedSpaceIds.contains(space.id))
          .map((space) => space.toEntity())
          .toList();

      return recommendedSpaces;
    } catch (e) {
      debugPrint('Error getting recommended spaces: $e');
      return [];
    }
  }
} 