import 'dart:io';

import 'package:hive_ui/features/messaging/domain/entities/chat.dart';
import 'package:hive_ui/features/messaging/domain/entities/chat_user.dart';
import 'package:hive_ui/features/messaging/domain/entities/message.dart';

/// Repository interface for managing messaging functionality
abstract class MessageRepository {
  // Chat management methods

  /// Gets a list of chat IDs that a user is participating in
  Future<List<String>> getChatsForUser(String userId);

  /// Gets details of a specific chat
  Future<Chat> getChatDetails(String chatId);

  /// Creates a direct chat between two users
  Future<String> createDirectChat(String userId1, String userId2);

  /// Creates a group chat with multiple participants
  Future<String> createGroupChat(String title, List<String> participantIds,
      {String? imageUrl});

  /// Creates a club chat for a specific club
  Future<String> createClubChat(String clubId, String clubName,
      {String? imageUrl});

  /// Creates an event chat for a specific event
  Future<String> createEventChat(String eventId, String eventName,
      {String? imageUrl});

  /// Adds a user to an existing chat
  Future<void> addUserToChat(String chatId, String userId);

  /// Removes a user from a chat
  Future<void> removeUserFromChat(String chatId, String userId);

  /// Updates a chat's metadata (title, image, etc.)
  Future<void> updateChatDetails(String chatId,
      {String? title, String? imageUrl});

  /// Deletes a chat and all associated messages
  Future<void> deleteChat(String chatId);

  // Real-time streams

  /// Stream of all chats for a specific user
  Stream<List<Chat>> getUserChatsStream(String userId);

  /// Stream of messages in a specific chat
  Stream<List<Message>> getChatMessagesStream(String chatId);

  /// Stream of users currently typing in a chat
  Stream<Map<String, DateTime>> getTypingStatusStream(String chatId);

  /// Stream of users' online status for a specific chat
  Stream<Map<String, bool>> getUserOnlineStatusStream(String chatId);

  // Message methods

  /// Gets a list of messages for a specific chat
  Future<List<Message>> getMessagesForChat(String chatId,
      {int limit = 30, String? lastMessageId});

  /// Gets the most recent messages for a chat (non-streaming)
  Future<List<Message>> getChatMessages(String chatId, {int limit = 30});

  /// Sends a text message to a chat
  Future<Message> sendTextMessage(
    String chatId,
    String senderId,
    String content, {
    String? replyToMessageId,
    String? threadParentId,
  });

  /// Sends an image message to a chat
  Future<Message> sendImageMessage(
    String chatId,
    String senderId,
    File imageFile, {
    String? caption,
    String? replyToMessageId,
    String? threadParentId,
  });

  /// Sends an event share message to a chat
  Future<Message> sendEventMessage(
    String chatId,
    String senderId,
    MessageEventData eventData, {
    String? replyToMessageId,
    String? threadParentId,
  });

  /// Marks a specific message as seen by a user
  Future<void> markMessageAsSeen(
      String chatId, String messageId, String userId);

  /// Marks all messages in a chat as read by a user
  Future<void> markChatAsRead(String chatId, String userId);

  /// Deletes a message
  Future<void> deleteMessage(String chatId, String messageId, String userId);

  // Typing indicators

  /// Updates a user's typing status in a chat
  Future<void> updateTypingStatus(String chatId, String userId, bool isTyping);

  // Message interactions

  /// Adds a reaction to a message
  Future<void> addReaction(
      String chatId, String messageId, String userId, String emoji);

  /// Removes a reaction from a message
  Future<void> removeReaction(
      String chatId, String messageId, String userId, String emoji);

  /// Adds a reaction to a message (newer method)
  Future<void> addMessageReaction(
      String chatId, String messageId, String userId, String emoji);
      
  /// Removes a reaction from a message (newer method)
  Future<void> removeMessageReaction(
      String chatId, String messageId, String userId, String emoji);

  /// Pins a message in a chat
  Future<void> pinMessage(String chatId, String messageId);

  /// Unpins a message in a chat
  Future<void> unpinMessage(String chatId, String messageId);

  // Thread methods

  /// Gets messages in a thread
  Future<List<Message>> getThreadMessages(String parentMessageId,
      {int limit = 30, String? lastMessageId});

  /// Gets a thread reply message
  Future<Message> getThreadReply(
    String parentMessageId,
    String senderId,
    String content,
  );

  /// Sends a text message as a reply in a thread
  Future<Message> sendTextMessageReply(
    String chatId,
    String senderId,
    String content,
    String threadParentId,
  );

  /// Gets the count of replies in a thread
  Future<int> getThreadReplyCount(String parentMessageId);

  // User methods

  /// Gets a list of users in a chat
  Future<List<ChatUser>> getChatParticipants(String chatId);

  /// Gets a specific user's profile
  Future<ChatUser> getUserProfile(String userId);

  /// Updates a user's online status
  Future<void> updateUserOnlineStatus(String userId, bool isOnline);

  /// Gets suggested contacts for the user based on their clubs and interactions
  Future<List<ChatUser>> getSuggestedContacts(String userId, {int limit = 10});

  // Search

  /// Searches for messages in a chat
  Future<List<Message>> searchMessages(String chatId, String query,
      {int limit = 20});

  /// Searches for users across the platform
  Future<List<ChatUser>> searchUsers(String query, {int limit = 20});

  /// Searches for chats (group, club, event) across the platform
  Future<List<Chat>> searchChats(String query, {int limit = 20});

  /// Gets a paginated list of messages for a chat
  Future<List<Message>> getMessagesPaginated(String chatId, DateTime? lastMessageTimestamp, int limit);

  /// Updates a message's delivery status
  Future<void> updateMessageDeliveryStatus(String messageId, String chatId, bool isDelivered, {bool isRead = false});

  /// Uploads an attachment file and returns the download URL
  Future<String> uploadAttachment(File file, String chatId, String senderId);

  /// Sends a message with an attachment to a chat
  Future<Message> sendMessageWithAttachment(
    String chatId,
    String senderId,
    String attachmentUrl,
    String fileName,
    MessageType messageType, {
    String? replyToMessageId,
    String? threadParentId,
  });
  
  /// Gets a specific message by ID
  Future<Message?> getMessageById(String chatId, String messageId);
  
  /// Gets thread messages as a stream for real-time updates
  Stream<List<Message>> getThreadMessagesStream(String chatId, String threadParentId);
  
  /// Gets unread message count as a stream for a chat
  Stream<int> getUnreadMessageCountStream(String chatId, String userId);
  
  /// Gets messages before a specific timestamp (for pagination)
  Future<List<Message>> getChatMessagesBefore(
    String chatId, 
    DateTime timestamp,
    {int limit = 20}
  );
  
  /// Creates a message search index
  Future<void> createMessageSearchIndex(String chatId);
  
  /// Updates the message search index with new messages
  Future<void> updateMessageSearchIndex(String chatId, List<Message> messages);
}
