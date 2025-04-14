import 'dart:io';

import 'package:hive_ui/features/spaces/data/datasources/spaces_data_source.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/domain/repositories/spaces_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_member_entity.dart';
import 'package:hive_ui/core/services/firebase/firebase_services.dart';
import 'package:hive_ui/features/events/domain/entities/event.dart' as event_entity;
import 'package:hive_ui/features/events/data/mappers/event_mapper.dart';
import 'package:hive_ui/models/event.dart' as event_model;

/// Implementation of the SpacesRepository interface
class SpacesRepositoryImpl implements SpacesRepository {
  final SpacesDataSource _dataSource;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// Constructor
  SpacesRepositoryImpl(
    this._dataSource, {
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<SpaceEntity>> getAllSpaces({
    bool forceRefresh = false,
    bool includePrivate = false,
    bool includeJoined = true,
  }) async {
    // Get the current user ID to correctly filter based on join status
    final uid = _auth.currentUser?.uid;
    
    final spaces = await _dataSource.getAllSpaces(
      forceRefresh: forceRefresh,
      includePrivate: includePrivate,
      includeJoined: includeJoined,
      userId: uid, // Pass userId to data source
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
      
      await _dataSource.leaveSpace(spaceId, userId: uid);
      return true;
    } catch (e) {
      debugPrint('Error leaving space: $e');
      return false;
    }
  }

  @override
  Future<bool> hasJoinedSpace(String spaceId, {String? userId}) async {
    try {
      // Use current user ID if not provided
      final uid = userId ?? _auth.currentUser?.uid;
      if (uid == null) {
        debugPrint('No user ID provided and no current user');
        return false;
      }
      
      return await _dataSource.hasJoinedSpace(spaceId, userId: uid);
    } catch (e) {
      debugPrint('Error checking if joined space: $e');
      return false;
    }
  }

  @override
  Future<List<SpaceEntity>> getSpacesWithUpcomingEvents() async {
    try {
      final spaces = await _dataSource.getSpacesWithUpcomingEvents();
      return spaces.map((model) => model.toEntity()).toList();
    } catch (e) {
      debugPrint('Error getting spaces with upcoming events: $e');
      return [];
    }
  }

  @override
  Future<List<SpaceEntity>> getTrendingSpaces() async {
    try {
      final spaces = await _dataSource.getTrendingSpaces();
      return spaces.map((model) => model.toEntity()).toList();
    } catch (e) {
      debugPrint('Error getting trending spaces: $e');
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
      // Convert entity to model
      final model = await _dataSource.getSpaceById(space.id);
      if (model == null) {
        throw Exception('Space not found');
      }
      
      // Update the space in Firestore
      final collectionPath = _getSpaceCollectionPath(space.spaceType);
      final docRef = _firestore.collection(collectionPath).doc(space.id);
      
      // Create a map of updates (we need to convert specific properties manually)
      final updates = <String, dynamic>{
        'name': space.name,
        'description': space.description,
        'icon': space.iconCodePoint,
        'tags': space.tags,
        'isPrivate': space.isPrivate,
        'moderators': space.moderators,
        'admins': space.admins,
        'quickActions': space.quickActions,
        'relatedSpaceIds': space.relatedSpaceIds,
        'updatedAt': FieldValue.serverTimestamp(),
        'lifecycleState': _lifecycleStateToString(space.lifecycleState),
        'claimStatus': _claimStatusToString(space.claimStatus),
        'claimId': space.claimId,
        'lastActivityAt': space.lastActivityAt != null ? 
            Timestamp.fromDate(space.lastActivityAt!) : null,
      };
      
      // Update the document
      await docRef.update(updates);
      
      // Refresh and return the updated space
      final updatedModel = await _dataSource.getSpaceById(space.id);
      if (updatedModel == null) {
        throw Exception('Failed to get updated space');
      }
      
      return updatedModel.toEntity();
    } catch (e) {
      debugPrint('Error updating space: $e');
      rethrow;
    }
  }
  
  @override
  Future<String> uploadBannerImage(String spaceId, File bannerImage) async {
    // TODO: Implement banner image upload logic
    throw UnimplementedError('uploadBannerImage not implemented');
  }
  
  @override
  Future<String> uploadProfileImage(String spaceId, File profileImage) async {
    // TODO: Implement profile image upload logic
    throw UnimplementedError('uploadProfileImage not implemented');
  }

  @override
  Future<bool> isSpaceNameTaken(String name) async {
    try {
      return await _dataSource.isSpaceNameTaken(name);
    } catch (e) {
      debugPrint('Error checking if space name is taken: $e');
      // Default to true (name is taken) in case of error to be safe
      return true;
    }
  }

  @override
  Future<List<event_entity.Event>> getSpaceEvents(String spaceId, {int limit = 10}) async {
    try {
      final events = await _dataSource.getSpaceEvents(spaceId, limit: limit);
      // Convert model events to domain entities
      return events.map(EventMapper.toEntity).toList();
    } catch (e) {
      debugPrint('Error getting events for space $spaceId: $e');
      return [];
    }
  }
  
  @override
  Future<bool> addModerator(String spaceId, String userId) async {
    try {
      // Get the space
      final space = await getSpaceById(spaceId);
      if (space == null) {
        return false;
      }
      
      // Check if user is already a moderator
      if (space.moderators.contains(userId)) {
        return true;
      }
      
      // Add user to moderators list
      final updatedSpace = space.copyWith(
        moderators: [...space.moderators, userId],
      );
      
      // Update the space
      await updateSpace(updatedSpace);
      
      return true;
    } catch (e) {
      debugPrint('Error adding moderator: $e');
      return false;
    }
  }
  
  @override
  Future<bool> removeModerator(String spaceId, String userId) async {
    try {
      // Get the space
      final space = await getSpaceById(spaceId);
      if (space == null) {
        return false;
      }
      
      // Remove user from moderators list
      final updatedSpace = space.copyWith(
        moderators: space.moderators.where((id) => id != userId).toList(),
      );
      
      // Update the space
      await updateSpace(updatedSpace);
      
      return true;
    } catch (e) {
      debugPrint('Error removing moderator: $e');
      return false;
    }
  }
  
  @override
  Future<bool> addAdmin(String spaceId, String userId) async {
    try {
      // Get the space
      final space = await getSpaceById(spaceId);
      if (space == null) {
        return false;
      }
      
      // Check if user is already an admin
      if (space.admins.contains(userId)) {
        return true;
      }
      
      // Check if admin limit is reached (max 4 admins)
      if (space.admins.length >= 4) {
        throw SpaceAdminLimitException('Maximum number of admins (4) reached');
      }
      
      // Add user to admins list
      final updatedSpace = space.copyWith(
        admins: [...space.admins, userId],
      );
      
      // Update the space
      await updateSpace(updatedSpace);
      
      return true;
    } catch (e) {
      debugPrint('Error adding admin: $e');
      if (e is SpaceAdminLimitException) {
        rethrow;
      }
      return false;
    }
  }
  
  @override
  Future<bool> removeAdmin(String spaceId, String userId) async {
    try {
      // Get the space
      final space = await getSpaceById(spaceId);
      if (space == null) {
        return false;
      }
      
      // Remove user from admins list
      final updatedSpace = space.copyWith(
        admins: space.admins.where((id) => id != userId).toList(),
      );
      
      // Update the space
      await updateSpace(updatedSpace);
      
      return true;
    } catch (e) {
      debugPrint('Error removing admin: $e');
      return false;
    }
  }
  
  @override
  Future<List<String>> getSpaceMembers(String spaceId) async {
    try {
      final snapshot = await _firestore
          .collection('spaces')
          .doc(spaceId)
          .collection('members')
          .get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('Error getting space members: $e');
      return [];
    }
  }
  
  @override
  Future<SpaceMemberEntity?> getSpaceMember(String spaceId, String memberId) async {
    try {
      final memberDocRef = _firestore
          .collection('spaces')
          .doc(spaceId)
          .collection('members')
          .doc(memberId);
          
      final snapshot = await memberDocRef.get();
      
      if (snapshot.exists) {
        return SpaceMemberEntity.fromSnapshot(snapshot);
      } else {
        // Member document doesn't exist
        return null;
      }
    } catch (e) {
      debugPrint('Error getting space member $memberId from space $spaceId: $e');
      // Depending on requirements, might rethrow or return null
      return null;
    }
  }
  
  @override
  Future<bool> updateLifecycleState(
    String spaceId,
    SpaceLifecycleState lifecycleState, {
    DateTime? lastActivityAt,
  }) async {
    try {
      // Get the space
      final space = await getSpaceById(spaceId);
      if (space == null) {
        return false;
      }
      
      // Update the space
      final updatedSpace = space.copyWith(
        lifecycleState: lifecycleState,
        lastActivityAt: lastActivityAt ?? DateTime.now(),
      );
      
      // Save the updated space
      await updateSpace(updatedSpace);
      
      return true;
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
      // Get the space
      final space = await getSpaceById(spaceId);
      if (space == null) {
        return false;
      }
      
      // Update the space
      final updatedSpace = space.copyWith(
        claimStatus: claimStatus,
        claimId: claimId,
      );
      
      // Save the updated space
      await updateSpace(updatedSpace);
      
      return true;
    } catch (e) {
      debugPrint('Error updating claim status: $e');
      return false;
    }
  }
  
  @override
  Future<bool> inviteUsers(String spaceId, List<String> userIds) async {
    // TODO: Implement invite users logic
    return false;
  }
  
  @override
  Future<bool> removeInvites(String spaceId, List<String> userIds) async {
    // TODO: Implement remove invites logic
    return false;
  }
  
  Future<Map<String, int>> getSpaceEngagementMetrics(String spaceId) async {
    // TODO: Implement space engagement metrics logic
    return {};
  }
  
  Future<bool> sendMessageToChat(String spaceId, String message, {String? userId}) async {
    // TODO: Implement send message to chat logic
    return false;
  }
  
  @override
  Future<String?> getSpaceChatId(String spaceId) async {
    try {
      return await _dataSource.getSpaceChatId(spaceId);
    } catch (e) {
      debugPrint('Error getting space chat ID: $e');
      return null;
    }
  }
  
  @override
  Future<String?> createSpaceChat(String spaceId, String spaceName, {String? imageUrl}) async {
    try {
      // Create a new chat document for the space
      final chatRef = _firestore.collection('chats').doc();
      final timestamp = DateTime.now().toIso8601String();
      
      // Get space members to add as participants
      final space = await getSpaceById(spaceId);
      if (space == null) {
        debugPrint('Space not found when creating chat');
        return null;
      }
      
      // Combine all user types who should be in the chat
      final List<String> memberIds = [
        ...space.admins,
        ...space.moderators,
      ];
      
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
      final messageRef = _firestore.collection('chats/${chatRef.id}/messages').doc();
      
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
  Future<SpaceMetrics> getSpaceMetrics(String spaceId) async {
    try {
      // Try to get metrics from the space document
      final space = await getSpaceById(spaceId);
      if (space == null) {
        return const SpaceMetrics(
          memberCount: 0,
          eventCount: 0,
          activeMembers: 0,
        );
      }
      
      // Get member count
      final members = await getSpaceMembers(spaceId);
      
      // Get events count
      final events = await getSpaceEvents(spaceId);
      
      // For active members, we'll just use a percentage of total members for now
      // In a real implementation, this would be based on recent activity
      final activeMembers = (members.length * 0.7).round();
      
      return SpaceMetrics(
        memberCount: members.length,
        eventCount: events.length,
        activeMembers: activeMembers,
      );
    } catch (e) {
      debugPrint('Error getting space metrics: $e');
      return const SpaceMetrics(
        memberCount: 0,
        eventCount: 0,
        activeMembers: 0,
      );
    }
  }

  @override
  Future<bool> updateSpaceVerification(String spaceId, bool isVerified) async {
    try {
      // Get the space
      final space = await getSpaceById(spaceId);
      if (space == null) {
        return false;
      }
      
      // Update the space in Firestore
      final collectionPath = _getSpaceCollectionPath(space.spaceType);
      final docRef = _firestore.collection(collectionPath).doc(space.id);
      
      // Update the verification status
      await docRef.update({
        'isVerified': isVerified,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      debugPrint('Error updating space verification: $e');
      return false;
    }
  }
  
  /// Get the collection path for a space type
  String _getSpaceCollectionPath(SpaceType spaceType) {
    switch (spaceType) {
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
  
  /// Convert lifecycle state to string for Firestore
  String _lifecycleStateToString(SpaceLifecycleState state) {
    switch (state) {
      case SpaceLifecycleState.created:
        return 'created';
      case SpaceLifecycleState.active:
        return 'active';
      case SpaceLifecycleState.dormant:
        return 'dormant';
      case SpaceLifecycleState.archived:
        return 'archived';
    }
  }
  
  /// Convert claim status to string for Firestore
  String _claimStatusToString(SpaceClaimStatus status) {
    switch (status) {
      case SpaceClaimStatus.unclaimed:
        return 'unclaimed';
      case SpaceClaimStatus.pending:
        return 'pending';
      case SpaceClaimStatus.claimed:
        return 'claimed';
      case SpaceClaimStatus.notRequired:
        return 'notRequired';
    }
  }

  @override
  Future<bool> updateSpaceActivity(String spaceId) async {
    try {
      // Update the space's lastActivityAt field
      final space = await getSpaceById(spaceId);
      if (space == null) {
        return false;
      }
      
      // Update the space with current timestamp
      final updatedSpace = space.copyWith(
        lastActivityAt: DateTime.now(),
      );
      
      // Save the updated space
      await updateSpace(updatedSpace);
      
      return true;
    } catch (e) {
      debugPrint('Error updating space activity: $e');
      return false;
    }
  }

  @override
  Future<void> requestToJoinSpace(String spaceId, String userId) async {
    try {
      // Get the space to check if it's private
      final space = await getSpaceById(spaceId);
      if (space == null) {
        throw Exception('Space not found');
      }
      
      if (!space.isPrivate) {
        throw Exception('Space is not private. Use joinSpace directly.');
      }
      
      // Check if user is already a member
      final isMember = await hasJoinedSpace(spaceId, userId: userId);
      if (isMember) {
        throw Exception('User is already a member of this space');
      }
      
      // Create a join request document
      final requestRef = _firestore
          .collection('spaces')
          .doc(spaceId)
          .collection('joinRequests')
          .doc(userId);
      
      // Check if request already exists
      final requestDoc = await requestRef.get();
      if (requestDoc.exists) {
        throw Exception('Join request already pending');
      }
      
      // Add the request
      await requestRef.set({
        'userId': userId,
        'requestedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('User $userId requested to join space $spaceId');
    } catch (e) {
      debugPrint('Error requesting to join space: $e');
      rethrow;
    }
  }

  @override
  Future<List<String>> getJoinRequests(String spaceId) async {
    try {
      final requestsSnapshot = await _firestore
          .collection('spaces')
          .doc(spaceId)
          .collection('joinRequests')
          .get();
      
      return requestsSnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('Error getting join requests: $e');
      return [];
    }
  }

  @override
  Future<bool> approveJoinRequest(String spaceId, String userIdToApprove) async {
    try {
      // Check if the request exists
      final requestRef = _firestore
          .collection('spaces')
          .doc(spaceId)
          .collection('joinRequests')
          .doc(userIdToApprove);
      
      final requestDoc = await requestRef.get();
      if (!requestDoc.exists) {
        debugPrint('No join request found for user $userIdToApprove');
        return false;
      }
      
      // Add the user to the space
      final joinSuccess = await joinSpace(spaceId, userId: userIdToApprove);
      if (!joinSuccess) {
        debugPrint('Failed to add user $userIdToApprove to space $spaceId');
        return false;
      }
      
      // Delete the request
      await requestRef.delete();
      
      return true;
    } catch (e) {
      debugPrint('Error approving join request: $e');
      return false;
    }
  }

  @override
  Future<bool> denyJoinRequest(String spaceId, String userIdToDeny) async {
    try {
      // Check if the request exists
      final requestRef = _firestore
          .collection('spaces')
          .doc(spaceId)
          .collection('joinRequests')
          .doc(userIdToDeny);
      
      final requestDoc = await requestRef.get();
      if (!requestDoc.exists) {
        debugPrint('No join request found for user $userIdToDeny');
        return true; // No action needed
      }
      
      // Delete the request
      await requestRef.delete();
      
      return true;
    } catch (e) {
      debugPrint('Error denying join request: $e');
      return false;
    }
  }

  @override
  Future<bool> initiateSpaceArchive(String spaceId, String initiatorId) async {
    try {
      // Get the space to check if it's Hive Exclusive
      final space = await getSpaceById(spaceId);
      if (space == null) {
        throw Exception('Space not found');
      }
      
      // Check if initiator is admin/creator
      if (!space.admins.contains(initiatorId)) {
        throw Exception('User is not authorized to initiate archive');
      }
      
      // Check if space is Hive Exclusive
      if (!space.hiveExclusive) {
        throw Exception('Cannot archive non-Hive Exclusive spaces');
      }
      
      // Create transaction to update the space
      await _firestore.runTransaction((transaction) async {
        final spaceRef = _firestore
            .collection(_getSpaceCollectionPath(space.spaceType))
            .doc(spaceId);
        
        final spaceDoc = await transaction.get(spaceRef);
        if (!spaceDoc.exists) {
          throw Exception('Space not found');
        }
        
        final spaceData = spaceDoc.data() as Map<String, dynamic>;
        final currentArchiveState = spaceData['archiveState'] as String? ?? 'none';
        
        if (currentArchiveState != 'none') {
          throw Exception('Space is already being archived or has been archived/rejected');
        }
        
        // Initiate voting
        transaction.update(spaceRef, {
          'archiveState': 'voting',
          'archiveVotes': {initiatorId: true}, // Initiator automatically votes yes
        });
      });
      
      return true;
    } catch (e) {
      debugPrint('Error initiating space archive: $e');
      if (e.toString().contains('not authorized') || 
          e.toString().contains('non-Hive Exclusive') ||
          e.toString().contains('already being archived')) {
        rethrow;
      }
      return false;
    }
  }

  @override
  Future<String> voteForSpaceArchive(String spaceId, String voterId, bool approve) async {
    try {
      // Get the space
      final space = await getSpaceById(spaceId);
      if (space == null) {
        throw Exception('Space not found');
      }
      
      // Check if voter is admin
      if (!space.admins.contains(voterId)) {
        throw Exception('User is not authorized to vote');
      }
      
      String finalState = 'voting'; // Default unless majority reached
      
      // Use transaction to handle voting atomically
      await _firestore.runTransaction((transaction) async {
        final spaceRef = _firestore
            .collection(_getSpaceCollectionPath(space.spaceType))
            .doc(spaceId);
        
        final spaceDoc = await transaction.get(spaceRef);
        if (!spaceDoc.exists) {
          throw Exception('Space not found');
        }
        
        final spaceData = spaceDoc.data() as Map<String, dynamic>;
        
        // Check current archive state
        final currentArchiveState = spaceData['archiveState'] as String? ?? 'none';
        if (currentArchiveState != 'voting') {
          throw Exception('Archive voting is not currently active for this space');
        }
        
        // Record vote
        final currentVotes = Map<String, bool>.from(spaceData['archiveVotes'] ?? {});
        currentVotes[voterId] = approve;
        
        // Calculate results
        final totalAdmins = space.admins.length;
        int approveVotes = 0;
        int denyVotes = 0;
        
        currentVotes.forEach((userId, vote) {
          if (space.admins.contains(userId)) {
            if (vote) {
              approveVotes++;
            } else {
              denyVotes++;
            }
          }
        });
        
        // Prepare updates
        Map<String, dynamic> updates = {'archiveVotes': currentVotes};
        
        // Check for majority
        if (approveVotes > totalAdmins / 2) {
          finalState = 'archived';
          updates['archiveState'] = finalState;
          updates['lifecycleState'] = 'archived';
        } else if (denyVotes >= totalAdmins / 2) {
          finalState = 'rejected';
          updates['archiveState'] = finalState;
        }
        
        transaction.update(spaceRef, updates);
      });
      
      return finalState;
    } catch (e) {
      debugPrint('Error voting for space archive: $e');
      if (e.toString().contains('not authorized') || 
          e.toString().contains('not currently active')) {
        rethrow;
      }
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getSpaceArchiveStatus(String spaceId) async {
    try {
      final space = await getSpaceById(spaceId);
      if (space == null) {
        throw Exception('Space not found');
      }
      
      // Get the space document to access archive data
      final spaceDoc = await _firestore
          .collection(_getSpaceCollectionPath(space.spaceType))
          .doc(spaceId)
          .get();
      
      if (!spaceDoc.exists) {
        throw Exception('Space not found');
      }
      
      final spaceData = spaceDoc.data() as Map<String, dynamic>;
      
      return {
        'archiveState': spaceData['archiveState'] as String? ?? 'none',
        'archiveVotes': Map<String, bool>.from(spaceData['archiveVotes'] ?? {}),
      };
    } catch (e) {
      debugPrint('Error getting space archive status: $e');
      return {
        'archiveState': 'error',
        'archiveVotes': {},
      };
    }
  }

  @override
  Future<List<SpaceEntity>> getFeaturedSpaces({int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection('spaces')
          .where('isFeatured', isEqualTo: true)
          .limit(limit)
          .get();
      
      // Convert to space entities
      final spaces = await Future.wait(querySnapshot.docs.map((doc) async {
        final docId = doc.id;
        final spaceModel = await _dataSource.getSpaceById(docId);
        if (spaceModel == null) return null;
        return spaceModel.toEntity();
      }).toList());
      
      // Remove nulls
      return spaces.whereType<SpaceEntity>().toList();
    } catch (e) {
      debugPrint('Error getting featured spaces: $e');
      return [];
    }
  }

  @override
  Future<List<SpaceEntity>> getNewestSpaces({int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection('spaces')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      // Convert to space entities
      final spaces = await Future.wait(querySnapshot.docs.map((doc) async {
        final docId = doc.id;
        final spaceModel = await _dataSource.getSpaceById(docId);
        if (spaceModel == null) return null;
        return spaceModel.toEntity();
      }).toList());
      
      // Remove nulls
      return spaces.whereType<SpaceEntity>().toList();
    } catch (e) {
      debugPrint('Error getting newest spaces: $e');
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
      // Create a claim document in the "leadership_claims" collection
      final claimId = '${spaceId}_${userId}_${DateTime.now().millisecondsSinceEpoch}';
      
      await _firestore.collection('leadership_claims').doc(claimId).set({
        'spaceId': spaceId,
        'userId': userId,
        'userName': userName,
        'email': email,
        'reason': reason,
        'credentials': credentials,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Update the space's claim status
      await _firestore.collection('spaces').doc(spaceId).update({
        'claimStatus': 'pending',
        'claimId': claimId,
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
      // Update the member's role in the members subcollection
      await _firestore
          .collection('spaces')
          .doc(spaceId)
          .collection('members')
          .doc(userId)
          .update({'role': role});
      
      // If the role is admin, add the user to the admins array in the space document
      if (role == 'admin') {
        await _firestore.collection('spaces').doc(spaceId).update({
          'admins': FieldValue.arrayUnion([userId]),
        });
      } 
      // If the role is being downgraded from admin, remove from admins array
      else {
        // Get the current member doc to check if they were an admin
        final memberDoc = await _firestore
            .collection('spaces')
            .doc(spaceId)
            .collection('members')
            .doc(userId)
            .get();
        
        if (memberDoc.exists && memberDoc.data()?['role'] == 'admin') {
          await _firestore.collection('spaces').doc(spaceId).update({
            'admins': FieldValue.arrayRemove([userId]),
          });
        }
      }
      
      return true;
    } catch (e) {
      debugPrint('Error updating space member role: $e');
      return false;
    }
  }

  @override
  Future<List<SpaceMemberEntity>> getSpaceMembersWithDetails(String spaceId) async {
    try {
      final querySnapshot = await _firestore
          .collection('spaces')
          .doc(spaceId)
          .collection('members')
          .get();

      return querySnapshot.docs.map((doc) => SpaceMemberEntity.fromSnapshot(doc)).toList();
    } catch (e) {
      debugPrint('Error getting space members with details: $e');
      return [];
    }
  }
}
