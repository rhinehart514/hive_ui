import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/messaging/domain/entities/chat.dart';
import 'package:hive_ui/features/messaging/domain/entities/chat_user.dart';
import 'package:hive_ui/features/messaging/domain/entities/message.dart';
import 'package:hive_ui/features/messaging/domain/repositories/message_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:hive_ui/features/messaging/data/repositories/firebase_message_repository.dart';
import 'package:hive_ui/features/messaging/application/usecases/message_use_case.dart';
import 'package:hive_ui/features/messaging/application/providers/messaging_providers.dart';

/// State for messaging
class MessagingState {
  // Chat list state
  final List<String> chatIds;
  final bool isLoadingChats;
  final String? chatLoadError;

  // Current chat state
  final String? currentChatId;
  final List<Message> messages;
  final bool isLoadingMessages;
  final String? messageLoadError;

  // Current chat info
  final List<ChatUser> participants;
  final bool isLoadingParticipants;

  // Typing indicators
  final Map<String, DateTime> typingUsers;

  // Message sending state
  final bool isSendingMessage;
  final String? messageSendError;

  // Media upload state
  final bool isUploadingMedia;
  final double uploadProgress;

  // Search state
  final String searchQuery;
  final List<ChatUser> searchResults;
  final bool isSearching;

  const MessagingState({
    this.chatIds = const [],
    this.isLoadingChats = false,
    this.chatLoadError,
    this.currentChatId,
    this.messages = const [],
    this.isLoadingMessages = false,
    this.messageLoadError,
    this.participants = const [],
    this.isLoadingParticipants = false,
    this.typingUsers = const {},
    this.isSendingMessage = false,
    this.messageSendError,
    this.isUploadingMedia = false,
    this.uploadProgress = 0.0,
    this.searchQuery = '',
    this.searchResults = const [],
    this.isSearching = false,
  });

  MessagingState copyWith({
    List<String>? chatIds,
    bool? isLoadingChats,
    String? chatLoadError,
    Object? currentChatId = const _Unset(),
    List<Message>? messages,
    bool? isLoadingMessages,
    Object? messageLoadError = const _Unset(),
    List<ChatUser>? participants,
    bool? isLoadingParticipants,
    Map<String, DateTime>? typingUsers,
    bool? isSendingMessage,
    Object? messageSendError = const _Unset(),
    bool? isUploadingMedia,
    double? uploadProgress,
    String? searchQuery,
    List<ChatUser>? searchResults,
    bool? isSearching,
  }) {
    return MessagingState(
      chatIds: chatIds ?? this.chatIds,
      isLoadingChats: isLoadingChats ?? this.isLoadingChats,
      chatLoadError: chatLoadError ?? this.chatLoadError,
      currentChatId: currentChatId is _Unset
          ? this.currentChatId
          : (currentChatId as String?),
      messages: messages ?? this.messages,
      isLoadingMessages: isLoadingMessages ?? this.isLoadingMessages,
      messageLoadError: messageLoadError is _Unset
          ? this.messageLoadError
          : (messageLoadError as String?),
      participants: participants ?? this.participants,
      isLoadingParticipants:
          isLoadingParticipants ?? this.isLoadingParticipants,
      typingUsers: typingUsers ?? this.typingUsers,
      isSendingMessage: isSendingMessage ?? this.isSendingMessage,
      messageSendError: messageSendError is _Unset
          ? this.messageSendError
          : (messageSendError as String?),
      isUploadingMedia: isUploadingMedia ?? this.isUploadingMedia,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      searchQuery: searchQuery ?? this.searchQuery,
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
    );
  }
}

class _Unset {
  const _Unset();
}

/// Controller to coordinate all messaging functionality
class MessagingController {
  final MessageUseCase _messageUseCase;
  final FirebaseAuth _auth;

  MessagingController({
    required MessageUseCase messageUseCase,
    FirebaseAuth? auth,
  })  : _messageUseCase = messageUseCase,
        _auth = auth ?? FirebaseAuth.instance;

  /// Gets the current user ID or throws an error
  String _getCurrentUserId() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return userId;
  }

  /// Gets all chats for the current user
  Stream<List<Chat>> getCurrentUserChats() {
    final userId = _getCurrentUserId();
    return _messageUseCase.getUserChats(userId);
  }

  /// Starts a chat with a friend
  Future<Chat> startFriendChat(String friendId) async {
    final userId = _getCurrentUserId();
    return await _messageUseCase.startFriendChat(userId, friendId);
  }
  
  /// Checks if a space chat is available
  Future<bool> isSpaceChatAvailable(String spaceId) async {
    return await _messageUseCase.isSpaceChatUnlocked(spaceId);
  }
  
  /// Gets the number of members needed to unlock a space chat
  Future<int> getMembersNeededForSpaceChat(String spaceId) async {
    return await _messageUseCase.getMembersNeededForChat(spaceId);
  }
  
  /// Gets or creates a space chat if available
  Future<Chat?> getSpaceChat(String spaceId) async {
    return await _messageUseCase.getSpaceChat(spaceId);
  }

  /// Sends a text message
  Future<void> sendTextMessage(String chatId, String content) async {
    final userId = _getCurrentUserId();
    await _messageUseCase.sendTextMessage(chatId, userId, content);
  }

  /// Sends a text message as a reply in a thread
  Future<void> sendTextMessageReply(String chatId, String content, String threadParentId) async {
    final userId = _getCurrentUserId();
    await _messageUseCase.sendTextMessageReply(chatId, userId, content, threadParentId);
  }

  /// Sends an image message
  Future<void> sendImageMessage(String chatId, File imageFile, {String? caption}) async {
    final userId = _getCurrentUserId();
    await _messageUseCase.sendImageMessage(chatId, userId, imageFile, caption: caption);
  }

  /// Sends a file message
  Future<void> sendFileMessage(String chatId, File file, String fileName) async {
    final userId = _getCurrentUserId();
    await _messageUseCase.sendFileMessage(chatId, userId, file, fileName);
  }

  /// Sets the current chat for the user
  void setCurrentChat(String chatId) {
    // Simply a utility method to track the current chat ID
    // No backend operation needed for this simple tracking
  }

  /// Marks a chat as read
  Future<void> markChatAsRead(String chatId) async {
    final userId = _getCurrentUserId();
    await _messageUseCase.markChatAsRead(chatId, userId);
  }

  /// Updates typing status
  Future<void> updateTypingStatus(String chatId, bool isTyping) async {
    final userId = _getCurrentUserId();
    await _messageUseCase.updateTypingStatus(chatId, userId, isTyping);
  }

  /// Adds a reaction to a message
  Future<void> addReaction(String chatId, String messageId, String emoji) async {
    final userId = _getCurrentUserId();
    await _messageUseCase.addMessageReaction(chatId, messageId, userId, emoji);
  }
  
  /// Removes a reaction from a message
  Future<void> removeReaction(String chatId, String messageId, String emoji) async {
    final userId = _getCurrentUserId();
    await _messageUseCase.removeMessageReaction(chatId, messageId, userId, emoji);
  }

  /// Updates user's online status
  Future<void> updateOnlineStatus(bool isOnline) async {
    final userId = _getCurrentUserId();
    await _messageUseCase.updateUserOnlineStatus(userId, isOnline);
  }

  /// Deletes a message
  Future<void> deleteMessage(String chatId, String messageId) async {
    final userId = _getCurrentUserId();
    await _messageUseCase.deleteMessage(chatId, messageId, userId);
  }
  
  /// Searches for users matching the query
  Future<List<ChatUser>> searchUsers(String query) async {
    if (query.trim().length < 2) {
      return [];
    }
    
    try {
      // Since we don't have direct access to the repository,
      // we'll use the message repository's search function
      return await _messageUseCase.searchUsers(query);
    } catch (e) {
      // Handle error
      return [];
    }
  }
  
  /// Creates a direct chat with another user
  Future<String> createDirectChat(String otherUserId) async {
    final userId = _getCurrentUserId();
    final chat = await _messageUseCase.startFriendChat(userId, otherUserId);
    return chat.id;
  }
  
  /// Creates a group chat
  Future<String> createGroupChat(String title, List<String> participantIds, {String? imageUrl}) async {
    // Implementation depends on your use case layer
    // This is a placeholder
    throw UnimplementedError('Group chat creation not implemented yet');
  }

  /// Sends an announcement to a space chat
  Future<Message?> sendSpaceAnnouncement(String spaceId, String content) async {
    final userId = _getCurrentUserId();
    return await _messageUseCase.sendSpaceAnnouncement(spaceId, userId, content);
  }
  
  /// Gets all spaces with active chats for the current user
  Future<List<String>> getSpacesWithChats() async {
    final userId = _getCurrentUserId();
    return await _messageUseCase.getSpacesWithChatsForUser(userId);
  }
  
  /// Synchronizes space members with chat participants
  Future<void> syncSpaceChat(String spaceId) async {
    await _messageUseCase.syncSpaceMembersWithChat(spaceId);
  }
}

// Provider for message repository
final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  // Import the correct repository implementation
  return FirebaseMessageRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
    storage: FirebaseStorage.instance,
    uuid: const Uuid(),
  );
});

// Provider for the messaging controller
final messagingControllerProvider = Provider<MessagingController>((ref) {
  final messageUseCase = ref.watch(messageUseCaseProvider);
  return MessagingController(messageUseCase: messageUseCase);
});

// Chat messages stream provider
final chatMessagesStreamProvider =
    StreamProvider.family<List<Message>, String>((ref, chatId) {
  final repository = ref.watch(messageRepositoryProvider);
  return repository.getChatMessagesStream(chatId);
});

// Chats stream provider
final userChatsStreamProvider = StreamProvider<List<Chat>>((ref) {
  final repository = ref.watch(messageRepositoryProvider);
  final userId = ref.read(authStateProvider)?.id ?? 'current-user-id';
  return repository.getUserChatsStream(userId);
});

// Auth state provider placeholder - replace with actual auth provider
final authStateProvider = Provider<dynamic>((ref) => null);

// Provider for user's chats
final userChatsProvider =
    FutureProvider.family<List<String>, String>((ref, userId) async {
  final repository = ref.watch(messageRepositoryProvider);
  return repository.getChatsForUser(userId);
});

// Provider for chat details
final chatDetailsProvider =
    FutureProvider.family<Chat, String>((ref, chatId) async {
  final repository = ref.watch(messageRepositoryProvider);
  return repository.getChatDetails(chatId);
});
