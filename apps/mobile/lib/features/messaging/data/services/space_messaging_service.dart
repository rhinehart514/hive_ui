import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ui/features/messaging/domain/entities/chat.dart';
import 'package:hive_ui/features/messaging/domain/entities/message.dart';
import 'package:hive_ui/features/messaging/domain/repositories/message_repository.dart';

/// Service to handle space-specific messaging functionality
class SpaceMessagingService {
  final FirebaseFirestore _firestore;
  final MessageRepository _messageRepository;
  
  // Minimum number of members required to unlock space chat
  static const int MINIMUM_MEMBERS_FOR_CHAT = 10;

  SpaceMessagingService({
    required MessageRepository messageRepository,
    FirebaseFirestore? firestore,
  })  : _messageRepository = messageRepository,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Creates or retrieves the chat for a space
  Future<Chat?> getOrCreateSpaceChat(String spaceId) async {
    // First check if the space has enough members
    final spaceDoc = await _firestore.collection('spaces').doc(spaceId).get();
    
    if (!spaceDoc.exists) {
      throw Exception('Space not found');
    }
    
    final spaceData = spaceDoc.data()!;
    final List<String> members = List<String>.from(spaceData['memberIds'] ?? []);
    final String spaceName = spaceData['name'] as String;
    final String? spaceImageUrl = spaceData['imageUrl'] as String?;
    
    // Check if the space has enough members to enable chat
    final bool hasEnoughMembers = members.length >= MINIMUM_MEMBERS_FOR_CHAT;
    
    if (!hasEnoughMembers) {
      return null; // Chat is locked
    }
    
    // Check if a chat already exists for this space
    final chatQuerySnapshot = await _firestore.collection('chats')
        .where('spaceId', isEqualTo: spaceId)
        .limit(1)
        .get();
    
    if (chatQuerySnapshot.docs.isNotEmpty) {
      // Chat exists, return it
      final chatData = chatQuerySnapshot.docs.first.data();
      final chatId = chatQuerySnapshot.docs.first.id;
      
      // Make sure all current members are in the chat
      final participantIds = List<String>.from(chatData['participantIds'] ?? []);
      final membersToAdd = members.where((id) => !participantIds.contains(id)).toList();
      
      if (membersToAdd.isNotEmpty) {
        // Add new members to the chat
        await _syncSpaceMembersWithChat(spaceId, chatId);
        
        // Send system message about new members
        if (membersToAdd.length == 1) {
          await _messageRepository.sendTextMessage(
            chatId,
            'system',
            '1 new member joined the space chat',
          );
        } else {
          await _messageRepository.sendTextMessage(
            chatId,
            'system',
            '${membersToAdd.length} new members joined the space chat',
          );
        }
      }
      
      return Chat.fromMap(chatData);
    }
    
    // Create a new chat for this space
    final chatId = await _messageRepository.createGroupChat(
      "Space: $spaceName",
      members,
      imageUrl: spaceImageUrl,
    );
    
    // Update the chat with space ID
    await _firestore.collection('chats').doc(chatId).update({
      'spaceId': spaceId,
      'type': ChatType.club.index,
    });
    
    // Create welcome message
    await _messageRepository.sendTextMessage(
      chatId,
      'system',
      'Welcome to the $spaceName space chat! This is a place for all members to connect.',
    );
    
    // Get the updated chat
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    return Chat.fromMap(chatDoc.data()!);
  }

  /// Checks if a space has enough members to unlock chat
  Future<bool> isSpaceChatUnlocked(String spaceId) async {
    final spaceDoc = await _firestore.collection('spaces').doc(spaceId).get();
    
    if (!spaceDoc.exists) {
      return false;
    }
    
    final spaceData = spaceDoc.data()!;
    final List<String> members = List<String>.from(spaceData['memberIds'] ?? []);
    
    return members.length >= MINIMUM_MEMBERS_FOR_CHAT;
  }

  /// Get the number of members needed to unlock chat for a space
  Future<int> getMembersNeededToUnlockChat(String spaceId) async {
    final spaceDoc = await _firestore.collection('spaces').doc(spaceId).get();
    
    if (!spaceDoc.exists) {
      return MINIMUM_MEMBERS_FOR_CHAT;
    }
    
    final spaceData = spaceDoc.data()!;
    final List<String> members = List<String>.from(spaceData['memberIds'] ?? []);
    
    final int currentMembers = members.length;
    
    if (currentMembers >= MINIMUM_MEMBERS_FOR_CHAT) {
      return 0; // Already unlocked
    }
    
    return MINIMUM_MEMBERS_FOR_CHAT - currentMembers;
  }

  /// Synchronize space members with chat participants
  Future<void> syncSpaceMembersWithChat(String spaceId) async {
    // Check if a chat exists for this space
    final chatQuerySnapshot = await _firestore.collection('chats')
        .where('spaceId', isEqualTo: spaceId)
        .limit(1)
        .get();
    
    if (chatQuerySnapshot.docs.isEmpty) {
      // No chat exists yet, nothing to sync
      return;
    }
    
    final chatId = chatQuerySnapshot.docs.first.id;
    await _syncSpaceMembersWithChat(spaceId, chatId);
  }
  
  /// Internal method to sync space members with chat
  Future<void> _syncSpaceMembersWithChat(String spaceId, String chatId) async {
    final spaceDoc = await _firestore.collection('spaces').doc(spaceId).get();
    
    if (!spaceDoc.exists) {
      throw Exception('Space not found');
    }
    
    final spaceData = spaceDoc.data()!;
    final List<String> members = List<String>.from(spaceData['memberIds'] ?? []);
    
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    
    if (!chatDoc.exists) {
      throw Exception('Chat not found');
    }
    
    final chatData = chatDoc.data()!;
    final List<String> currentParticipants = List<String>.from(chatData['participantIds'] ?? []);
    
    // Add new members to chat
    final membersToAdd = members.where((id) => !currentParticipants.contains(id)).toList();
    for (final userId in membersToAdd) {
      await _messageRepository.addUserToChat(chatId, userId);
    }
    
    // Remove members who left the space
    final membersToRemove = currentParticipants.where((id) => !members.contains(id) && id != 'system').toList();
    for (final userId in membersToRemove) {
      await _messageRepository.removeUserFromChat(chatId, userId);
    }
    
    // If members were added or removed, update the chat with a system message
    if (membersToAdd.isNotEmpty || membersToRemove.isNotEmpty) {
      // Create system messages about member changes
      if (membersToAdd.isNotEmpty) {
        String message;
        if (membersToAdd.length == 1) {
          message = '1 new member joined the space chat';
        } else {
          message = '${membersToAdd.length} new members joined the space chat';
        }
        
        await _messageRepository.sendTextMessage(
          chatId,
          'system',
          message,
        );
      }
      
      if (membersToRemove.isNotEmpty) {
        String message;
        if (membersToRemove.length == 1) {
          message = '1 member left the space chat';
        } else {
          message = '${membersToRemove.length} members left the space chat';
        }
        
        await _messageRepository.sendTextMessage(
          chatId,
          'system',
          message,
        );
      }
    }
  }
  
  /// Send an announcement to the space chat
  Future<Message?> sendSpaceAnnouncement(String spaceId, String senderId, String content) async {
    // Check if a chat exists for this space
    final chatQuerySnapshot = await _firestore.collection('chats')
        .where('spaceId', isEqualTo: spaceId)
        .limit(1)
        .get();
    
    if (chatQuerySnapshot.docs.isEmpty) {
      // Try to create a chat first
      final chat = await getOrCreateSpaceChat(spaceId);
      if (chat == null) {
        // Not enough members to create a chat
        return null;
      }
      
      // Now create an announcement in the new chat
      return await _messageRepository.sendTextMessage(
        chat.id,
        senderId,
        '📢 ANNOUNCEMENT: $content',
      );
    }
    
    // Send the announcement to the existing chat
    final chatId = chatQuerySnapshot.docs.first.id;
    return await _messageRepository.sendTextMessage(
      chatId,
      senderId,
      '📢 ANNOUNCEMENT: $content',
    );
  }
  
  /// Get all spaces that have chats for a user
  Future<List<String>> getSpacesWithChatsForUser(String userId) async {
    // Get all chats that the user is part of
    final userChats = await _messageRepository.getChatsForUser(userId);
    
    // Filter the chats to only get space chats
    final spaceChats = <String>[];
    
    for (final chatId in userChats) {
      try {
        final chatDetails = await _messageRepository.getChatDetails(chatId);
        if (chatDetails.isClubChat && chatDetails.clubId != null) {
          spaceChats.add(chatDetails.clubId!);
        }
      } catch (e) {
        // Skip chats that can't be loaded
        continue;
      }
    }
    
    return spaceChats;
  }
} 