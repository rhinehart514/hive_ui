import 'dart:io';

import 'package:hive_ui/features/messaging/data/services/friend_messaging_service.dart';
import 'package:hive_ui/features/messaging/data/services/realtime_messaging_service.dart';
import 'package:hive_ui/features/messaging/data/services/space_messaging_service.dart';
import 'package:hive_ui/features/messaging/domain/entities/chat.dart';
import 'package:hive_ui/features/messaging/domain/entities/chat_user.dart';
import 'package:hive_ui/features/messaging/domain/entities/message.dart';
import 'package:hive_ui/features/messaging/domain/repositories/message_repository.dart';

/// Use case class for messaging functionality
class MessageUseCase {
  final MessageRepository _messageRepository;
  final FriendMessagingService _friendMessagingService;
  final SpaceMessagingService _spaceMessagingService;
  final RealtimeMessagingService _realtimeMessagingService;

  MessageUseCase({
    required MessageRepository messageRepository,
    required FriendMessagingService friendMessagingService,
    required SpaceMessagingService spaceMessagingService,
    required RealtimeMessagingService realtimeMessagingService,
  })  : _messageRepository = messageRepository,
        _friendMessagingService = friendMessagingService,
        _spaceMessagingService = spaceMessagingService,
        _realtimeMessagingService = realtimeMessagingService;

  // Friend messaging

  /// Gets or creates a direct chat with a friend
  Future<Chat> startFriendChat(String currentUserId, String friendId) async {
    return await _friendMessagingService.getOrCreateDirectChat(currentUserId, friendId);
  }

  /// Gets all friends who the user can message
  Future<List<ChatUser>> getMessagingFriends(String userId) async {
    return await _friendMessagingService.getUserFriends(userId);
  }

  /// Gets suggested friends to message (ones not recently messaged)
  Future<List<ChatUser>> getFriendChatSuggestions(String userId) async {
    return await _friendMessagingService.getFriendChatSuggestions(userId);
  }

  // Space messaging

  /// Tries to get a space chat, returning null if the space doesn't have enough members
  Future<Chat?> getSpaceChat(String spaceId) async {
    return await _spaceMessagingService.getOrCreateSpaceChat(spaceId);
  }

  /// Checks if a space has enough members to have chat enabled
  Future<bool> isSpaceChatUnlocked(String spaceId) async {
    return await _spaceMessagingService.isSpaceChatUnlocked(spaceId);
  }

  /// Gets number of members needed to unlock chat
  Future<int> getMembersNeededForChat(String spaceId) async {
    return await _spaceMessagingService.getMembersNeededToUnlockChat(spaceId);
  }

  // General chat functionality

  /// Gets all chats for a user
  Stream<List<Chat>> getUserChats(String userId) {
    return _messageRepository.getUserChatsStream(userId);
  }

  /// Gets messages for a specific chat
  Stream<List<Message>> getChatMessages(String chatId) {
    return _messageRepository.getChatMessagesStream(chatId);
  }

  // Real-time features

  /// Gets typing status stream for a chat (using Realtime Database)
  Stream<Map<String, DateTime>> getTypingIndicators(String chatId) {
    return _realtimeMessagingService.getTypingIndicatorsStream(chatId);
  }

  /// Updates user typing status (using Realtime Database)
  Future<void> updateTypingStatus(String chatId, String userId, bool isTyping) async {
    await _realtimeMessagingService.updateTypingStatus(chatId, userId, isTyping);
  }

  /// Updates a user's online status (using Realtime Database)
  Future<void> updateUserOnlineStatus(String userId, bool isOnline) async {
    await _realtimeMessagingService.updateOnlineStatus(userId, isOnline);
  }

  /// Gets online status for multiple users (using Realtime Database)
  Stream<Map<String, bool>> getUsersOnlineStatus(List<String> userIds) {
    return _realtimeMessagingService.getOnlineStatusStream(userIds);
  }

  /// Updates message delivery status (using Realtime Database)
  Future<void> updateMessageDeliveryStatus(
    String messageId,
    String receiverId,
    MessageDeliveryStatus status,
  ) async {
    await _realtimeMessagingService.updateMessageDeliveryStatus(
      messageId,
      receiverId,
      status,
    );
  }

  /// Gets delivery status for a message (using Realtime Database)
  Stream<Map<String, MessageDeliveryStatus>> getMessageDeliveryStatus(String messageId) {
    return _realtimeMessagingService.getMessageDeliveryStatusStream(messageId);
  }

  /// Gets a user's last active timestamp (using Realtime Database)
  Future<DateTime?> getUserLastActive(String userId) async {
    return await _realtimeMessagingService.getUserLastActive(userId);
  }

  // After sending a message, update its delivery status
  Future<Message> _updateMessageAfterSend(Message message, List<String> recipientIds) async {
    // Mark as sent for all recipients
    for (final recipientId in recipientIds) {
      if (recipientId != message.senderId) {
        await updateMessageDeliveryStatus(
          message.id,
          recipientId,
          MessageDeliveryStatus.sent,
        );
      }
    }
    return message;
  }

  /// Sends a text message with delivery tracking
  Future<Message> sendTextMessage(String chatId, String senderId, String content) async {
    // Send the message via repository
    final message = await _messageRepository.sendTextMessage(chatId, senderId, content);
    
    // Get chat details to find recipients
    final chat = await _messageRepository.getChatDetails(chatId);
    
    // Update delivery status for all recipients
    return await _updateMessageAfterSend(message, chat.participantIds);
  }

  /// Sends an image message with delivery tracking
  Future<Message> sendImageMessage(String chatId, String senderId, File imageFile, {String? caption}) async {
    // Send the message via repository
    final message = await _messageRepository.sendImageMessage(chatId, senderId, imageFile, caption: caption);
    
    // Get chat details to find recipients
    final chat = await _messageRepository.getChatDetails(chatId);
    
    // Update delivery status for all recipients
    return await _updateMessageAfterSend(message, chat.participantIds);
  }

  /// Marks a message as read for the current user
  Future<void> markMessageAsRead(String messageId, String userId) async {
    await updateMessageDeliveryStatus(
      messageId,
      userId,
      MessageDeliveryStatus.read,
    );
  }

  /// Marks all messages in a chat as read
  Future<void> markChatAsRead(String chatId, String userId) async {
    // First use repository method to update Firestore
    await _messageRepository.markChatAsRead(chatId, userId);
    
    // Then get recent messages and mark them as read in Realtime Database
    final messages = await _messageRepository.getChatMessages(chatId, limit: 50);
    
    for (final message in messages) {
      if (message.senderId != userId) {
        await markMessageAsRead(message.id, userId);
      }
    }
  }

  /// Gets users in a chat
  Future<List<ChatUser>> getChatParticipants(String chatId) async {
    return await _messageRepository.getChatParticipants(chatId);
  }

  /// Gets a user's profile
  Future<ChatUser> getUserProfile(String userId) async {
    return await _messageRepository.getUserProfile(userId);
  }

  /// Deletes a message
  Future<void> deleteMessage(String chatId, String messageId, String userId) async {
    await _messageRepository.deleteMessage(chatId, messageId, userId);
  }

  /// Searches messages in a chat
  Future<List<Message>> searchChatMessages(String chatId, String query) async {
    return await _messageRepository.searchMessages(chatId, query);
  }

  /// Searches for users by name or username
  Future<List<ChatUser>> searchUsers(String query) async {
    return await _messageRepository.searchUsers(query);
  }
} 