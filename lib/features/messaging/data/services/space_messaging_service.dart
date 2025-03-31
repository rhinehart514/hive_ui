import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ui/features/messaging/domain/entities/chat.dart';
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
  /// Returns null if the space doesn't have enough members
  Future<Chat?> getOrCreateSpaceChat(String spaceId) async {
    // First check if the space has enough members
    final spaceDoc = await _firestore.collection('spaces').doc(spaceId).get();
    
    if (!spaceDoc.exists) {
      throw Exception('Space not found');
    }
    
    final spaceData = spaceDoc.data()!;
    final List<String> members = List<String>.from(spaceData['memberIds'] ?? []);
    
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
      return Chat.fromMap(chatQuerySnapshot.docs.first.data());
    }
    
    // Create a new chat for this space
    final spaceName = spaceData['name'] as String;
    final spaceImage = spaceData['imageUrl'] as String?;
    
    final chatId = await _messageRepository.createGroupChat(
      "Space: $spaceName",
      members,
      imageUrl: spaceImage,
    );
    
    // Update the chat with space ID
    await _firestore.collection('chats').doc(chatId).update({
      'spaceId': spaceId,
    });
    
    // Create welcome message
    await _messageRepository.sendTextMessage(
      chatId,
      'system',
      'Welcome to the $spaceName space chat! This is a place for all members to connect.',
    );
    
    // Get the updated chat
    return await _messageRepository.getChatDetails(chatId);
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
    final spaceDoc = await _firestore.collection('spaces').doc(spaceId).get();
    
    if (!spaceDoc.exists) {
      throw Exception('Space not found');
    }
    
    final spaceData = spaceDoc.data()!;
    final List<String> members = List<String>.from(spaceData['memberIds'] ?? []);
    
    // Check if a chat exists for this space
    final chatQuerySnapshot = await _firestore.collection('chats')
        .where('spaceId', isEqualTo: spaceId)
        .limit(1)
        .get();
    
    if (chatQuerySnapshot.docs.isEmpty) {
      // No chat exists yet, nothing to sync
      return;
    }
    
    final chatDoc = chatQuerySnapshot.docs.first;
    final chatId = chatDoc.id;
    final chatData = chatDoc.data();
    
    final List<String> currentParticipants = List<String>.from(chatData['participantIds'] ?? []);
    
    // Add new members to chat
    final membersToAdd = members.where((id) => !currentParticipants.contains(id)).toList();
    for (final userId in membersToAdd) {
      await _messageRepository.addUserToChat(chatId, userId);
    }
    
    // Remove members who left the space
    final membersToRemove = currentParticipants.where((id) => !members.contains(id)).toList();
    for (final userId in membersToRemove) {
      await _messageRepository.removeUserFromChat(chatId, userId);
    }
  }
} 