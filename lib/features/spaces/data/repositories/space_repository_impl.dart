import 'dart:io';
import 'dart:developer';

import 'package:hive_ui/features/spaces/data/datasources/spaces_data_source.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/domain/repositories/spaces_repository.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_member_entity.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/models/event.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ui/features/spaces/data/models/space_model.dart';
import 'package:hive_ui/features/events/domain/entities/event.dart' as entity;
import 'package:hive_ui/features/events/data/mappers/event_mapper.dart';

/// Implementation of the SpacesRepository interface that wraps legacy SpaceRepository
/// This implementation is used to implement the new SpacesRepository interface while
/// maintaining compatibility with existing code.
class SpaceRepositoryImpl implements SpacesRepository {
  final SpacesDataSource _dataSource;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// Constructor
  SpaceRepositoryImpl(this._dataSource, {FirebaseAuth? auth}) 
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = FirebaseFirestore.instance;

  @override
  Future<List<SpaceEntity>> getAllSpaces({
    bool forceRefresh = false,
    bool includePrivate = false,
    bool includeJoined = true,
  }) async {
    final spaces = await _dataSource.getAllSpaces(
      forceRefresh: forceRefresh,
      includePrivate: includePrivate,
      includeJoined: includeJoined,
    );
    return spaces.map((model) => model.toEntity()).toList();
  }

  @override
  Future<SpaceEntity?> getSpaceById(String id, {String? spaceType}) async {
    try {
      final space = await _dataSource.getSpaceById(id, spaceType: spaceType);
      return space?.toEntity();
    } catch (e) {
      debugPrint('Error getting space by ID: $e');
      return null;
    }
  }

  @override
  Future<List<SpaceEntity>> getSpacesByCategory(String category) async {
    final spaces = await _dataSource.getSpacesByCategory(category);
    return spaces.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<SpaceEntity>> getJoinedSpaces({String? userId}) async {
    // Use current user ID if not provided
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) {
      debugPrint('No user ID provided and no current user');
      return [];
    }
    
    try {
      final spaces = await _dataSource.getJoinedSpaces(userId: uid);
      return spaces.map((model) => model.toEntity()).toList();
    } catch (e) {
      debugPrint('Error getting joined spaces: $e');
      return [];
    }
  }

  @override
  Future<List<SpaceEntity>> getInvitedSpaces({String? userId}) async {
    // Use current user ID if not provided
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) {
      debugPrint('No user ID provided and no current user');
      return [];
    }
    
    try {
      // Fallback implementation since data source doesn't have this method
      // In a real implementation, you would query invitations for the user
      debugPrint('getInvitedSpaces not implemented in data source. Using fallback.');
      return [];
    } catch (e) {
      debugPrint('Error getting invited spaces: $e');
      return [];
    }
  }

  @override
  Future<List<SpaceEntity>> getRecommendedSpaces({String? userId}) async {
    // Use current user ID if not provided
    final uid = userId ?? _auth.currentUser?.uid;
    
    try {
      final spaces = await _dataSource.getRecommendedSpaces(userId: uid);
      return spaces.map((model) => model.toEntity()).toList();
    } catch (e) {
      debugPrint('Error getting recommended spaces: $e');
      return [];
    }
  }

  @override
  Future<List<SpaceEntity>> searchSpaces(String query) async {
    final spaces = await _dataSource.searchSpaces(query);
    return spaces.map((model) => model.toEntity()).toList();
  }

  @override
  Future<bool> joinSpace(String spaceId, {String? userId}) async {
    try {
      // Use current user ID if not provided
      final uid = userId ?? _auth.currentUser?.uid;
      if (uid == null) {
        debugPrint('No user ID provided and no current user');
        return false;
      }
      
      await _dataSource.joinSpace(spaceId, userId: uid);
      return true;
    } catch (e) {
      debugPrint('Error joining space: $e');
      // Handle SpaceJoinException if needed
      return false;
    }
  }

  @override
  Future<bool> leaveSpace(String spaceId, {String? userId}) async {
    try {
      // Use current user ID if not provided
      final uid = userId ?? _auth.currentUser?.uid;
      if (uid == null) {
        debugPrint('No user ID provided and no current user');
        return false;
      }

      // --- Creator Leave Prevention --- 
      // Get space details to check creator and admins
      final spaceDoc = await FirebaseFirestore.instance.collection('spaces').doc(spaceId).get();
      if (!spaceDoc.exists) {
        debugPrint('Space $spaceId not found');
        return false;
      }
      final spaceData = spaceDoc.data()!;
      final creatorId = spaceData['creatorId'] as String?;
      final admins = List<String>.from(spaceData['admins'] ?? []);

      // Check if the leaving user is the creator and the only admin
      if (creatorId == uid && admins.length == 1 && admins.contains(uid)) {
        debugPrint('Creator cannot leave as they are the sole admin. Transfer ownership or add another admin first.');
        // Optionally throw a specific exception here
        throw Exception('Creator cannot leave as the sole admin.');
      }
      // --- End Creator Leave Prevention ---
      
      await _dataSource.leaveSpace(spaceId, userId: uid);
      return true;
    } catch (e) {
      debugPrint('Error leaving space: $e');
      // Re-throw the specific exception if caught
      if (e.toString().contains('Creator cannot leave')) rethrow;
      return false;
    }
  }

  @override
  Future<bool> hasJoinedSpace(String spaceId, {String? userId}) async {
    try {
      final uid = userId ?? _auth.currentUser?.uid;
      if (uid == null) return false;
      
      // Check if user is in the members collection
      final memberDoc = await _firestore
          .collection('spaces')
          .doc(spaceId)
          .collection('members')
          .doc(uid)
          .get();
      
      return memberDoc.exists;
    } catch (e) {
      debugPrint('Error checking if user has joined space: $e');
      rethrow;
    }
  }

  @override
  Future<List<SpaceEntity>> getSpacesWithUpcomingEvents() async {
    final spaces = await _dataSource.getSpacesWithUpcomingEvents();
    return spaces.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<SpaceEntity>> getTrendingSpaces({int limit = 20}) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('spaces')
          // V1 Trending: Order by most recent activity
          .orderBy('lastActivityAt', descending: true)
          .limit(limit)
          .get();

      // Map snapshots to entities (same mapping considerations as getFeaturedSpaces)
      final spaces = querySnapshot.docs.map((doc) {
          final model = SpaceModel.fromFirestore(doc); // Simplified assumption
          return model.toEntity();
      }).toList();
      
      return spaces;
    } catch (e) {
      debugPrint('Error fetching trending spaces (V1 - by activity): $e');
      return [];
    }
  }

  @override
  Future<SpaceEntity> createSpace({
    required String name,
    required String description,
    required int iconCodePoint,
    required SpaceType spaceType,
    required List<String> tags,
    required bool isPrivate,
    required String creatorId,
    required bool isHiveExclusive,
    File? coverImage,
    DateTime? lastActivityAt,
  }) async {
    try {
      final model = await _dataSource.createSpace(
        name: name,
        description: description,
        iconCodePoint: iconCodePoint,
        spaceType: spaceType,
        tags: tags,
        isPrivate: isPrivate,
        creatorId: creatorId,
        isHiveExclusive: isHiveExclusive,
      );
      
      // Set appropriate claim status based on space type
      SpaceClaimStatus claimStatus = isHiveExclusive || spaceType == SpaceType.hiveExclusive ?
          SpaceClaimStatus.notRequired : SpaceClaimStatus.unclaimed;
          
      // Create entity with added fields
      final entity = model.toEntity().copyWith(
        claimStatus: claimStatus,
        lifecycleState: SpaceLifecycleState.created,
        lastActivityAt: lastActivityAt ?? DateTime.now(),
      );
      
      // Update the space with the modified entity
      await updateSpace(entity);
      
      return entity;
    } catch (e) {
      debugPrint('Error creating space: $e');
      rethrow;
    }
  }

  @override
  Future<SpaceEntity> updateSpace(SpaceEntity space) async {
    try {
      // Fallback implementation since data source doesn't have this method
      debugPrint('updateSpace not implemented in data source. Using fallback.');
      
      // In a real implementation, you would update the space entity in Firestore
      
      // Return the same space since not implemented
      return space;
    } catch (e) {
      debugPrint('Error updating space: $e');
      rethrow;
    }
  }

  @override
  Future<bool> isSpaceNameTaken(String name) {
    return _dataSource.isSpaceNameTaken(name);
  }

  @override
  Future<List<entity.Event>> getSpaceEvents(String spaceId, {int limit = 10}) async {
    try {
      final events = await _dataSource.getSpaceEvents(spaceId, limit: limit);
      // Convert to domain entities
      return events.map(EventMapper.toEntity).toList();
    } catch (e, s) {
      debugPrint('Error getting events for space $spaceId: $e');
      return [];
    }
  }

  @override
  Future<bool> inviteUsers(String spaceId, List<String> userIds) async {
    try {
      // Fallback implementation since data source doesn't have this method
      debugPrint('inviteUsers not implemented in data source. Using fallback.');
      
      // In a real implementation, you would add the users to the invited list
      
      return false; // Return false since not implemented
    } catch (e) {
      debugPrint('Error inviting users: $e');
      return false;
    }
  }

  @override
  Future<bool> removeInvites(String spaceId, List<String> userIds) async {
    // Implementation depends on how invites are stored. Assuming a subcollection or array.
    try {
      // Example: Using an 'invites' array field in the space document
      final spaceRef = FirebaseFirestore.instance.collection('spaces').doc(spaceId);
      await spaceRef.update({
        'invites': FieldValue.arrayRemove(userIds),
      });
      return true;
    } catch (e) {
      debugPrint('Error removing invites: $e');
      return false;
    }
  }

  @override
  Future<bool> addAdmin(String spaceId, String userId) async {
    try {
      // Fallback implementation since data source doesn't have this method
      debugPrint('addAdmin not implemented in data source. Using fallback.');
      
      // In a real implementation, you would add the user to the admins list
      
      return false; // Return false since not implemented
    } catch (e) {
      debugPrint('Error adding admin: $e');
      return false;
    }
  }

  @override
  Future<bool> removeAdmin(String spaceId, String userId) async {
    try {
      // Fallback implementation since data source doesn't have this method
      debugPrint('removeAdmin not implemented in data source. Using fallback.');
      
      // In a real implementation, you would remove the user from the admins list
      
      return false; // Return false since not implemented
    } catch (e) {
      debugPrint('Error removing admin: $e');
      return false;
    }
  }

  @override
  Future<List<String>> getSpaceMembers(String spaceId) async {
    try {
      // Implement directly using Firestore since the data source doesn't have this method
      final membersSnapshot = await FirebaseFirestore.instance
          .collection('spaces')
          .doc(spaceId)
          .collection('members')
          .get();
      
      // Extract user IDs from the member documents
      return membersSnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('Error getting space members: $e');
      return [];
    }
  }

  @override
  Future<SpaceMemberEntity?> getSpaceMember(String spaceId, String memberId) async {
    try {
      // Get reference to the member document in Firestore
      final memberDoc = await FirebaseFirestore.instance
          .collection('spaces')
          .doc(spaceId)
          .collection('members')
          .doc(memberId)
          .get();
      
      // If the document exists, return a SpaceMemberEntity
      if (memberDoc.exists) {
        return SpaceMemberEntity.fromSnapshot(memberDoc);
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting space member: $e');
      return null;
    }
  }

  @override
  Future<SpaceMetrics> getSpaceMetrics(String spaceId) async {
    // TODO: Implement space engagement metrics logic using Firestore or DataSource
    debugPrint('getSpaceMetrics not fully implemented. Using fallback.');
    // Placeholder implementation
    try {
      final memberSnap = await FirebaseFirestore.instance
          .collection('spaces').doc(spaceId).collection('members').count().get();
      final eventSnap = await FirebaseFirestore.instance
          .collection('events').where('parentId', isEqualTo: spaceId).count().get();
      // activeMembers calculation would require more complex query or dedicated tracking
      return SpaceMetrics(
        memberCount: memberSnap.count ?? 0,
        eventCount: eventSnap.count ?? 0,
        activeMembers: 0, // Placeholder
      );
    } catch (e) {
       debugPrint('Error getting basic space metrics: $e');
       return const SpaceMetrics(
          memberCount: 0,
          eventCount: 0,
          activeMembers: 0,
       );
    }
  }

  @override
  Future<bool> updateSpaceVerification(String spaceId, bool isVerified) async {
    // TODO: Implement space verification update logic (likely Firestore update)
    // Requires admin role check before calling typically.
    debugPrint('updateSpaceVerification not implemented. Using fallback.');
    try {
       await FirebaseFirestore.instance.collection('spaces').doc(spaceId).update({
           'isVerified': isVerified, // Assuming a boolean field 'isVerified' exists
       });
       return true;
    } catch (e) {
        debugPrint('Error updating space verification: $e');
        return false;
    }
  }

  @override
  Future<String?> createSpaceChat(String spaceId, String spaceName, {String? imageUrl}) async {
    try {
      // Use FirebaseFirestore directly since this is a cross-repository operation
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      
      // Create a new chat document for the space
      final chatRef = firestore.collection('chats').doc();
      final timestamp = DateTime.now().toIso8601String();
      
      // Get space members to add as participants
      final space = await getSpaceById(spaceId);
      if (space == null) {
        debugPrint('Space not found when creating chat');
        return null;
      }
      
      // Combine all user types who should be in the chat
      final List<String> memberIds = [];
      
      // Add admins and moderators (creator is included in admins)
      if (space.admins.isNotEmpty) {
        memberIds.addAll(space.admins);
      }
      
      if (space.moderators.isNotEmpty) {
        memberIds.addAll(space.moderators);
      }
      
      // Get any other members if available
      final spaceMembers = await getSpaceMembers(spaceId);
      if (spaceMembers.isNotEmpty) {
        memberIds.addAll(spaceMembers);
      }
      
      // Remove duplicates
      final participants = memberIds.toSet().toList();
      
      // Prepare unread count map
      final unreadCount = <String, int>{};
      for (final userId in participants) {
        unreadCount[userId] = 0;
      }
      
      // Set chat data
      await chatRef.set({
        'title': spaceName,
        'imageUrl': imageUrl,
        'type': 3, // 3 = space chat type
        'participantIds': participants,
        'createdAt': timestamp,
        'lastMessageAt': null,
        'lastMessageText': null,
        'lastMessageSenderId': null,
        'unreadCount': unreadCount,
        'spaceId': spaceId, // Link back to the space
      });
      
      // Create a system message indicating space chat creation
      final messageRef = firestore.collection('chats/${chatRef.id}/messages').doc();
      
      await messageRef.set({
        'id': messageRef.id,
        'chatId': chatRef.id,
        'senderId': 'system',
        'senderName': 'System',
        'content': 'Space discussion board created',
        'timestamp': timestamp,
        'type': 'system',
        'isRead': true,
        'seenBy': participants,
      });
      
      return chatRef.id;
    } catch (e) {
      debugPrint('Error creating space chat: $e');
      return null;
    }
  }
  
  @override
  Future<String?> getSpaceChatId(String spaceId) async {
    try {
      // Use FirebaseFirestore directly since this is a cross-repository operation
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      
      final querySnapshot = await firestore
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

  @override
  Future<bool> addModerator(String spaceId, String userId) async {
    try {
      // Fallback implementation
      debugPrint('addModerator not implemented in data source. Using fallback.');
      
      // In a real implementation, you would add the user to the moderators list
      
      return false; // Return false since not implemented
    } catch (e) {
      debugPrint('Error adding moderator: $e');
      return false;
    }
  }

  @override
  Future<bool> removeModerator(String spaceId, String userId) async {
    try {
      // Fallback implementation
      debugPrint('removeModerator not implemented in data source. Using fallback.');
      
      // In a real implementation, you would remove the user from the moderators list
      
      return false; // Return false since not implemented
    } catch (e) {
      debugPrint('Error removing moderator: $e');
      return false;
    }
  }

  @override
  Future<bool> updateLifecycleState(
    String spaceId,
    SpaceLifecycleState lifecycleState, {
    DateTime? lastActivityAt,
  }) async {
    try {
      // Fallback implementation
      debugPrint('updateLifecycleState not implemented in data source. Using fallback.');
      
      // In a real implementation, you would update the lifecycle state
      
      return false; // Return false since not implemented
    } catch (e) {
      debugPrint('Error updating lifecycle state: $e');
      return false;
    }
  }

  @override
  Future<bool> updateClaimStatus(
    String spaceId,
    SpaceClaimStatus claimStatus, {
    String? claimId,
  }) async {
    try {
      // Fallback implementation
      debugPrint('updateClaimStatus not implemented in data source. Using fallback.');
      
      // In a real implementation, you would update the claim status
      
      return false; // Return false since not implemented
    } catch (e) {
      debugPrint('Error updating claim status: $e');
      return false;
    }
  }

  @override
  Future<String> uploadBannerImage(String spaceId, File bannerImage) async {
    try {
      // Fallback implementation
      debugPrint('uploadBannerImage not implemented in data source. Using fallback.');
      
      // In a real implementation, you would upload the banner image to storage
      // and update the space document with the image URL
      
      return ''; // Return empty string since not implemented
    } catch (e) {
      debugPrint('Error uploading banner image: $e');
      return '';
    }
  }

  @override
  Future<String> uploadProfileImage(String spaceId, File profileImage) async {
    try {
      // Fallback implementation
      debugPrint('uploadProfileImage not implemented in data source. Using fallback.');
      
      // In a real implementation, you would upload the profile image to storage
      // and update the space document with the image URL
      
      return ''; // Return empty string since not implemented
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      return '';
    }
  }

  @override
  Future<SpaceClaimStatus> getClaimStatus(String spaceId) async {
    try {
      final spaceDoc = await _firestore.collection('spaces').doc(spaceId).get();
      final data = spaceDoc.data();
      
      if (data == null) {
        throw Exception('Space not found');
      }
      
      final claimStatus = data['claimStatus'] as String? ?? 'unclaimed';
      
      switch (claimStatus) {
        case 'claimed':
          return SpaceClaimStatus.claimed;
        case 'pending':
          return SpaceClaimStatus.pending;
        case 'unclaimed':
        default:
          return SpaceClaimStatus.unclaimed;
      }
    } catch (e) {
      debugPrint('Error getting claim status: $e');
      return SpaceClaimStatus.unclaimed;
    }
  }

  @override
  Future<List<SpaceMemberEntity>> getSpaceMembersWithDetails(String spaceId) async {
    try {
      // Get all member IDs
      final memberIds = await getSpaceMembers(spaceId);
      
      // Get space details to check roles
      final space = await getSpaceById(spaceId);
      if (space == null) {
        return [];
      }
      
      // Create member entities with role information
      final List<SpaceMemberEntity> members = [];
      
      for (final memberId in memberIds) {
        // Get the member details from the database
        final memberDoc = await _dataSource.getSpaceMember(spaceId, memberId);
        
        if (memberDoc != null) {
          // Use the member document directly if available
          members.add(memberDoc);
        } else {
          // Create a basic member entity if no detailed document exists
          String role = 'member';
          if (space.admins.contains(memberId)) {
            role = 'admin';
          } else if (space.moderators.contains(memberId)) {
            role = 'moderator';
          }
          
          members.add(SpaceMemberEntity(
            id: memberId,
            userId: memberId,
            role: role,
            joinedAt: DateTime.now(),
          ));
        }
      }
      
      return members;
    } catch (e) {
      debugPrint('Error getting space members with details: $e');
      return [];
    }
  }

  @override
  Future<bool> submitLeadershipClaim({
    required String spaceId,
    required String userId,
    required String userName,
    required String email,
    required String reason,
    required String credentials,
  }) async {
    try {
      // Get the space to verify it exists and check its current claim status
      final space = await getSpaceById(spaceId);
      if (space == null) {
        debugPrint('Space not found when submitting leadership claim');
        return false;
      }
      
      // Create claim document in Firestore
      final claimRef = FirebaseFirestore.instance.collection('spaces/$spaceId/claims').doc();
      
      await claimRef.set({
        'claimantId': userId,
        'claimantName': userName,
        'claimantEmail': email,
        'reasonText': reason,
        'credentials': credentials,
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update space with claim information
      await FirebaseFirestore.instance.collection('spaces').doc(spaceId).update({
        'claimStatus': 'pending',
        'claimId': claimRef.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      debugPrint('Error submitting leadership claim: $e');
      return false;
    }
  }

  @override
  Future<bool> updateSpaceMemberRole(String spaceId, String userId, String role) async {
    try {
      // Validate role
      if (!['admin', 'moderator', 'member'].contains(role.toLowerCase())) {
        debugPrint('Invalid role: $role. Must be admin, moderator, or member.');
        return false;
      }
      
      // Get space
      final space = await getSpaceById(spaceId);
      if (space == null) {
        debugPrint('Space not found when updating member role');
        return false;
      }
      
      // Check if user is a member
      final isMember = await hasJoinedSpace(spaceId, userId: userId);
      if (!isMember) {
        debugPrint('User is not a member of the space');
        return false;
      }
      
      // Update role in members collection
      await FirebaseFirestore.instance
          .collection('spaces/$spaceId/members')
          .doc(userId)
          .update({
        'role': role.toLowerCase(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update admin/moderator lists
      final spaceRef = FirebaseFirestore.instance.collection('spaces').doc(spaceId);
      
      // Start a batch operation to ensure atomicity
      final batch = FirebaseFirestore.instance.batch();
      
      // Remove from all role lists first
      if (space.admins.contains(userId)) {
        batch.update(spaceRef, {
          'admins': FieldValue.arrayRemove([userId]),
        });
      }
      if (space.moderators.contains(userId)) {
        batch.update(spaceRef, {
          'moderators': FieldValue.arrayRemove([userId]),
        });
      }
      
      // Add to the appropriate role list
      if (role.toLowerCase() == 'admin') {
        batch.update(spaceRef, {
          'admins': FieldValue.arrayUnion([userId]),
        });
      } else if (role.toLowerCase() == 'moderator') {
        batch.update(spaceRef, {
          'moderators': FieldValue.arrayUnion([userId]),
        });
      }
      
      // Commit the batch
      await batch.commit();
      
      return true;
    } catch (e) {
      debugPrint('Error updating space member role: $e');
      return false;
    }
  }

  @override
  Future<bool> approveJoinRequest(String spaceId, String userId) async {
    try {
      // First check if there is a pending request for this user
      final requestDocRef = _firestore
          .collection('spaces')
          .doc(spaceId)
          .collection('joinRequests')
          .doc(userId);
          
      final requestDoc = await requestDocRef.get();
      if (!requestDoc.exists) {
        debugPrint('No join request found for user $userId in space $spaceId');
        return false;
      }
      
      // Start a batch operation to ensure atomicity
      final batch = _firestore.batch();
      
      // Delete the join request
      batch.delete(requestDocRef);
      
      // Add the user to the space members
      final memberDocRef = _firestore
          .collection('spaces')
          .doc(spaceId)
          .collection('members')
          .doc(userId);
          
      batch.set(memberDocRef, {
        'userId': userId,
        'role': 'member',
        'joinedAt': FieldValue.serverTimestamp(),
      });
      
      // Update the space document with the new member count
      final spaceRef = _firestore.collection('spaces').doc(spaceId);
      batch.update(spaceRef, {
        'memberCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Commit the batch
      await batch.commit();
      
      return true;
    } catch (e) {
      debugPrint('Error approving join request: $e');
      return false;
    }
  }

  @override
  Future<bool> claimLeadership(String spaceId, String userId, {String? verificationInfo}) async {
    try {
      // Verify space exists
      final space = await getSpaceById(spaceId);
      if (space == null) {
        debugPrint('Space not found when claiming leadership');
        return false;
      }
      
      // Check if the space is already claimed
      if (space.claimStatus == SpaceClaimStatus.claimed) {
        debugPrint('Space is already claimed');
        return false;
      }
      
      // Check if user is already a member
      final isMember = await hasJoinedSpace(spaceId, userId: userId);
      if (!isMember) {
        // Join the space first if not already a member
        await joinSpace(spaceId, userId: userId);
      }
      
      // Update space with claim information
      await _firestore.collection('spaces').doc(spaceId).update({
        'claimStatus': 'claimed',
        'creatorId': userId, // Update creator to the claiming user
        'admins': FieldValue.arrayUnion([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Add claim record to the claims subcollection
      await _firestore.collection('spaces/$spaceId/claims').add({
        'claimantId': userId,
        'verificationInfo': verificationInfo,
        'status': 'approved',
        'claimedAt': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      debugPrint('Error claiming leadership: $e');
      return false;
    }
  }

  @override
  Future<bool> denyJoinRequest(String spaceId, String userId) async {
    try {
      // Check if there is a pending request for this user
      final requestDocRef = _firestore
          .collection('spaces')
          .doc(spaceId)
          .collection('joinRequests')
          .doc(userId);
          
      final requestDoc = await requestDocRef.get();
      if (!requestDoc.exists) {
        debugPrint('No join request found for user $userId in space $spaceId');
        return false;
      }
      
      // Simply delete the join request
      await requestDocRef.delete();
      
      return true;
    } catch (e) {
      debugPrint('Error denying join request: $e');
      return false;
    }
  }

  @override
  Future<List<SpaceEntity>> getFeaturedSpaces({int limit = 20}) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('spaces')
          .where('isFeatured', isEqualTo: true)
          .orderBy('lastActivityAt', descending: true)
          .limit(limit)
          .get();

      // Map snapshots to entities
      final spaces = querySnapshot.docs.map((doc) {
          final model = SpaceModel.fromFirestore(doc);
          return model.toEntity();
      }).toList();
      
      return spaces;
    } catch (e) {
      debugPrint('Error fetching featured spaces: $e');
      return [];
    }
  }

  @override
  Future<List<SpaceEntity>> getNewestSpaces({int limit = 20}) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('spaces')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      // Map snapshots to entities
      final spaces = querySnapshot.docs.map((doc) {
          final model = SpaceModel.fromFirestore(doc);
          return model.toEntity();
      }).toList();
      
      return spaces;
    } catch (e) {
      debugPrint('Error fetching newest spaces: $e');
      return [];
    }
  }

  @override
  Future<void> requestToJoinSpace(String spaceId, String userId) async {
    try {
      // Check if space exists
      final spaceDoc = await _firestore.collection('spaces').doc(spaceId).get();
      if (!spaceDoc.exists) {
        throw Exception('Space not found');
      }
      
      // Check if the user is already a member
      final isMember = await hasJoinedSpace(spaceId, userId: userId);
      if (isMember) {
        throw Exception('User is already a member of this space');
      }
      
      // Check if there is already a pending request
      final requestDoc = await _firestore
          .collection('spaces')
          .doc(spaceId)
          .collection('joinRequests')
          .doc(userId)
          .get();
          
      if (requestDoc.exists) {
        throw Exception('Join request already exists');
      }
      
      // Create the join request
      await _firestore
          .collection('spaces')
          .doc(spaceId)
          .collection('joinRequests')
          .doc(userId)
          .set({
        'userId': userId,
        'requestedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (e) {
      debugPrint('Error requesting to join space: $e');
      rethrow;
    }
  }

  @override
  Future<List<String>> getJoinRequests(String spaceId) async {
    try {
      final querySnapshot = await _firestore
          .collection('spaces')
          .doc(spaceId)
          .collection('joinRequests')
          .where('status', isEqualTo: 'pending')
          .get();
          
      return querySnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('Error getting join requests: $e');
      return [];
    }
  }

  @override
  Future<bool> initiateSpaceArchive(String spaceId, String initiatorId) async {
    try {
      // Check if the space exists
      final spaceDoc = await _firestore.collection('spaces').doc(spaceId).get();
      if (!spaceDoc.exists) {
        return false;
      }
      
      // Check if the initiator is an admin
      final spaceData = spaceDoc.data()!;
      final admins = List<String>.from(spaceData['admins'] ?? []);
      if (!admins.contains(initiatorId)) {
        debugPrint('Only admins can initiate space archive');
        return false;
      }
      
      // Create archive record
      await _firestore.collection('spaces').doc(spaceId).update({
        'archiveStatus': 'pending',
        'archiveInitiator': initiatorId,
        'archiveInitiatedAt': FieldValue.serverTimestamp(),
        'archiveVotes': {initiatorId: true}, // Initiator automatically votes yes
      });
      
      return true;
    } catch (e) {
      debugPrint('Error initiating space archive: $e');
      return false;
    }
  }

  @override
  Future<bool> voteOnSpaceArchive(String spaceId, String userId, bool approve) async {
    try {
      // Check if the space exists and has a pending archive
      final spaceDoc = await _firestore.collection('spaces').doc(spaceId).get();
      if (!spaceDoc.exists) {
        return false;
      }
      
      final spaceData = spaceDoc.data()!;
      if (spaceData['archiveStatus'] != 'pending') {
        debugPrint('No pending archive to vote on');
        return false;
      }
      
      // Update the vote
      await _firestore.collection('spaces').doc(spaceId).update({
        'archiveVotes.$userId': approve,
      });
      
      return true;
    } catch (e) {
      debugPrint('Error voting on space archive: $e');
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> getSpaceArchiveStatus(String spaceId) async {
    try {
      final spaceDoc = await _firestore.collection('spaces').doc(spaceId).get();
      if (!spaceDoc.exists) {
        return {'status': 'not_initiated'};
      }
      
      final spaceData = spaceDoc.data()!;
      final status = spaceData['archiveStatus'] as String? ?? 'not_initiated';
      final votes = Map<String, bool>.from(spaceData['archiveVotes'] ?? {});
      
      return {
        'status': status,
        'votes': votes,
        'initiator': spaceData['archiveInitiator'],
        'initiatedAt': spaceData['archiveInitiatedAt'],
      };
    } catch (e) {
      debugPrint('Error getting space archive status: $e');
      return {'status': 'error', 'error': e.toString()};
    }
  }

  @override
  Future<bool> isSpaceAdmin(String spaceId, String userId) async {
    try {
      final spaceDoc = await _firestore.collection('spaces').doc(spaceId).get();
      if (!spaceDoc.exists) {
        return false;
      }
      
      final spaceData = spaceDoc.data()!;
      final admins = List<String>.from(spaceData['admins'] ?? []);
      
      return admins.contains(userId);
    } catch (e) {
      debugPrint('Error checking if user is space admin: $e');
      return false;
    }
  }

  @override
  Future<bool> updateVisibility(String spaceId, bool isPrivate) async {
    try {
      await _firestore.collection('spaces').doc(spaceId).update({
        'isPrivate': isPrivate,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      debugPrint('Error updating space visibility: $e');
      return false;
    }
  }

  @override
  Future<bool> updateSpaceActivity(String spaceId) async {
    try {
      await _firestore.collection('spaces').doc(spaceId).update({
        'lastActivityAt': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      debugPrint('Error updating space activity: $e');
      return false;
    }
  }
} 