import 'dart:io';

import 'package:hive_ui/features/spaces/data/datasources/spaces_data_source.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/domain/repositories/spaces_repository.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_member_entity.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/models/event.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ui/features/spaces/data/models/space_model.dart';

/// Implementation of the SpacesRepository interface that wraps legacy SpaceRepository
/// This implementation is used to implement the new SpacesRepository interface while
/// maintaining compatibility with existing code.
class SpaceRepositoryImpl implements SpacesRepository {
  final SpacesDataSource _dataSource;
  final FirebaseAuth _auth;

  /// Constructor
  SpaceRepositoryImpl(this._dataSource, {FirebaseAuth? auth}) 
      : _auth = auth ?? FirebaseAuth.instance;

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
      // Use current user ID if not provided
      final uid = userId ?? _auth.currentUser?.uid;
      if (uid == null) {
        debugPrint('No user ID provided and no current user');
        return false;
      }
      
      return _dataSource.hasJoinedSpace(spaceId, userId: uid);
    } catch (e) {
      debugPrint('Error checking if space is joined: $e');
      return false;
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
  Future<List<Event>> getSpaceEvents(String spaceId) async {
    try {
      final events = await _dataSource.getSpaceEvents(spaceId);
      return events;
    } catch (e) {
      debugPrint('Error getting space events: $e');
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
  Future<void> requestToJoinSpace(String spaceId, String userId) async {
    final spaceRef = FirebaseFirestore.instance.collection('spaces').doc(spaceId);
    final memberRef = spaceRef.collection('members').doc(userId);
    final requestRef = spaceRef.collection('joinRequests').doc(userId);

    try {
      final spaceDoc = await spaceRef.get();
      if (!spaceDoc.exists) throw Exception('Space not found');
      final spaceData = spaceDoc.data()!;
      if (!(spaceData['isPrivate'] as bool? ?? false)) {
        throw Exception('Space is not private. Use joinSpace directly.');
      }

      final memberDoc = await memberRef.get();
      if (memberDoc.exists) throw Exception('User is already a member');

      final requestDoc = await requestRef.get();
      if (requestDoc.exists) throw Exception('Join request already pending');

      // Add request (document ID is the user ID)
      await requestRef.set({
        'userId': userId,
        'requestedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('User $userId requested to join space $spaceId');
    } catch (e) {
      debugPrint('Error requesting to join space $spaceId: $e');
      rethrow; // Rethrow to be handled by the caller
    }
  }

  @override
  Future<List<String>> getJoinRequests(String spaceId) async {
    try {
      final requestsSnapshot = await FirebaseFirestore.instance
          .collection('spaces')
          .doc(spaceId)
          .collection('joinRequests')
          .get();
      return requestsSnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('Error fetching join requests for space $spaceId: $e');
      return [];
    }
  }

  @override
  Future<bool> approveJoinRequest(String spaceId, String userIdToApprove) async {
    final spaceRef = FirebaseFirestore.instance.collection('spaces').doc(spaceId);
    final requestRef = spaceRef.collection('joinRequests').doc(userIdToApprove);
    // Assume _dataSource.joinSpace handles adding to members collection and memberIds array

    try {
      // Verify request exists
      final requestDoc = await requestRef.get();
      if (!requestDoc.exists) {
         debugPrint('No pending join request found for user $userIdToApprove in space $spaceId');
         return false;
      }

      // Use the existing joinSpace logic (now part of dataSource)
      // This assumes joinSpace correctly adds the member and updates the array.
      // If joinSpace doesn't handle adding to the members subcollection AND the memberIds array,
      // that logic needs to be implemented here or within joinSpace.
      await _dataSource.joinSpace(spaceId, userId: userIdToApprove);
      
      // Remove the request now that they've joined
      await requestRef.delete();
      debugPrint('Approved join request for user $userIdToApprove in space $spaceId');
      return true;
    } catch (e) {
      debugPrint('Error approving join request for $userIdToApprove in $spaceId: $e');
      return false;
    }
  }

  @override
  Future<bool> denyJoinRequest(String spaceId, String userIdToDeny) async {
    final requestRef = FirebaseFirestore.instance
        .collection('spaces')
        .doc(spaceId)
        .collection('joinRequests')
        .doc(userIdToDeny);

    try {
      // Verify request exists before deleting
      final requestDoc = await requestRef.get();
      if (!requestDoc.exists) {
         debugPrint('No pending join request found for user $userIdToDeny in space $spaceId to deny');
         return true; // Or false if we want to indicate no action was taken
      }

      await requestRef.delete();
      debugPrint('Denied join request for user $userIdToDeny in space $spaceId');
      return true;
    } catch (e) {
      debugPrint('Error denying join request for $userIdToDeny in $spaceId: $e');
      return false;
    }
  }

  @override
  Future<bool> updateSpaceActivity(String spaceId) async {
    try {
      final spaceRef = FirebaseFirestore.instance.collection('spaces').doc(spaceId);
      await spaceRef.update({
        'lastActivityAt': FieldValue.serverTimestamp(), // Use server time
      });
      debugPrint('Updated lastActivityAt for space $spaceId');
      return true;
    } catch (e) {
      debugPrint('Error updating lastActivityAt for space $spaceId: $e');
      return false;
    }
  }

  @override
  Future<bool> initiateSpaceArchive(String spaceId, String initiatorId) async {
    final spaceRef = FirebaseFirestore.instance.collection('spaces').doc(spaceId);

    try {
      return await FirebaseFirestore.instance.runTransaction((transaction) async {
        final spaceDoc = await transaction.get(spaceRef);
        if (!spaceDoc.exists) throw Exception('Space not found.');
        final spaceData = spaceDoc.data()!;

        // Verify initiator is admin/creator
        final admins = List<String>.from(spaceData['admins'] ?? []);
        final creatorId = spaceData['creatorId'] as String?;
        if (initiatorId != creatorId && !admins.contains(initiatorId)) {
          throw Exception('User is not authorized to initiate archive.');
        }

        // Check if Hive Exclusive
        if (!(spaceData['isHiveExclusive'] as bool? ?? false)) {
          throw Exception('Cannot archive non-Hive Exclusive spaces.');
        }

        // Check current archive state
        final currentArchiveState = spaceData['archiveState'] as String? ?? 'none';
        if (currentArchiveState != 'none') {
          throw Exception('Space is already being archived or has been archived/rejected.');
        }

        // Initiate voting
        transaction.update(spaceRef, {
          'archiveState': 'voting',
          'archiveVotes': { initiatorId: true }, // Initiator automatically votes yes
        });
        debugPrint('Initiated archive voting for space $spaceId by $initiatorId');
        return true;
      });
    } catch (e) {
      debugPrint('Error initiating archive for space $spaceId: $e');
      // Rethrow specific exceptions for clearer feedback
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
    final spaceRef = FirebaseFirestore.instance.collection('spaces').doc(spaceId);

    try {
      return await FirebaseFirestore.instance.runTransaction((transaction) async {
        final spaceDoc = await transaction.get(spaceRef);
        if (!spaceDoc.exists) throw Exception('Space not found.');
        final spaceData = spaceDoc.data()!;

        // Verify voter is admin/creator
        final admins = List<String>.from(spaceData['admins'] ?? []);
        final creatorId = spaceData['creatorId'] as String?;
        final currentAdmins = Set<String>.from(admins);
        if (creatorId != null) currentAdmins.add(creatorId);
        if (!currentAdmins.contains(voterId)) {
          throw Exception('User is not authorized to vote.');
        }

        // Check current archive state
        final currentArchiveState = spaceData['archiveState'] as String? ?? 'none';
        if (currentArchiveState != 'voting') {
          throw Exception('Archive voting is not currently active for this space.');
        }

        // Record vote
        final currentVotes = Map<String, bool>.from(spaceData['archiveVotes'] ?? {});
        currentVotes[voterId] = approve;

        // Calculate results
        int totalEligibleVoters = currentAdmins.length;
        int approveVotes = 0;
        int denyVotes = 0;

        currentVotes.forEach((id, vote) {
          // Only count votes from current admins/creator
          if (currentAdmins.contains(id)) {
            if (vote) {
              approveVotes++;
            } else {
              denyVotes++;
            }
          }
        });

        String finalState = 'voting'; // Default unless majority reached
        Map<String, dynamic> updates = {'archiveVotes': currentVotes};

        // Check for majority
        if (approveVotes > totalEligibleVoters / 2) {
          finalState = 'archived';
          updates['archiveState'] = finalState;
          updates['lifecycleState'] = 'archived'; // Update lifecycle state as well
          debugPrint('Archive approved for space $spaceId');
        } else if (denyVotes >= totalEligibleVoters / 2) { // Note: >= for rejection majority
          finalState = 'rejected';
          updates['archiveState'] = finalState;
          // Reset votes? Or keep them? Keep for now for audit.
          debugPrint('Archive rejected for space $spaceId');
        }
        
        transaction.update(spaceRef, updates);
        return finalState;
      });
    } catch (e) {
      debugPrint('Error voting for archive on space $spaceId: $e');
       if (e.toString().contains('not authorized') || 
           e.toString().contains('not currently active')) {
         rethrow;
       }
      // Indicate error - perhaps return current state or throw?
      // Returning current state might be confusing. Let's rethrow generally.
      rethrow; 
    }
  }

  @override
  Future<Map<String, dynamic>> getSpaceArchiveStatus(String spaceId) async {
    try {
      final spaceDoc = await FirebaseFirestore.instance.collection('spaces').doc(spaceId).get();
      if (!spaceDoc.exists) throw Exception('Space not found.');
      final spaceData = spaceDoc.data()!;

      return {
        'archiveState': spaceData['archiveState'] as String? ?? 'none',
        'archiveVotes': Map<String, bool>.from(spaceData['archiveVotes'] ?? {}),
      };
    } catch (e) {
      debugPrint('Error getting archive status for space $spaceId: $e');
      return {
        'archiveState': 'error',
        'archiveVotes': {},
      }; // Return error state
    }
  }

  @override
  Future<List<SpaceEntity>> getFeaturedSpaces({int limit = 20}) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('spaces')
          .where('isFeatured', isEqualTo: true)
          // Optional: Add sorting, e.g., by activity or name
          // .orderBy('lastActivityAt', descending: true)
          .limit(limit)
          .get();

      // Convert snapshots to SpaceEntity objects
      // This requires a way to map Firestore data back to SpaceEntity.
      // Assuming SpaceModel.fromFirestore exists and can be mapped to SpaceEntity.
      // Or, implement a direct mapping here if needed.
      final spaces = querySnapshot.docs.map((doc) {
          // WARNING: Direct mapping assumes SpaceModel structure aligns with entity needs
          // and we have a reliable way to get SpaceType if needed for SpaceModel.fromFirestore.
          // A dedicated mapping function or using the DataSource might be safer.
          final model = SpaceModel.fromFirestore(doc); // Simplified assumption
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

      // Map snapshots to entities (same mapping considerations as getFeaturedSpaces)
      final spaces = querySnapshot.docs.map((doc) {
          final model = SpaceModel.fromFirestore(doc); // Simplified assumption
          return model.toEntity();
      }).toList();
      
      return spaces;
    } catch (e) {
      debugPrint('Error fetching newest spaces: $e');
      return [];
    }
  }

  // Convert SpaceLifecycleState enum to string
  String _lifecycleStateToString(SpaceLifecycleState state) {
    return state.toString().split('.').last;
  }
  
  // Convert string to SpaceLifecycleState enum
  SpaceLifecycleState _stringToLifecycleState(String stateStr) {
    return SpaceLifecycleState.values.firstWhere(
      (e) => e.toString().split('.').last == stateStr,
      orElse: () => SpaceLifecycleState.active,
    );
  }
  
  // Convert SpaceClaimStatus enum to string
  String _claimStatusToString(SpaceClaimStatus status) {
    return status.toString().split('.').last;
  }
  
  // Convert string to SpaceClaimStatus enum
  SpaceClaimStatus _stringToClaimStatus(String statusStr) {
    return SpaceClaimStatus.values.firstWhere(
      (e) => e.toString().split('.').last == statusStr,
      orElse: () => SpaceClaimStatus.unclaimed,
    );
  }
  
  // Get the appropriate collection path based on space type
  String _getSpaceCollectionPath(SpaceType type) {
    // Default to 'spaces' collection
    return 'spaces';
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
} 