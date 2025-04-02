import 'dart:io';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/messaging/application/usecases/message_use_case.dart';
import 'package:hive_ui/features/messaging/data/repositories/firebase_message_repository.dart';
import 'package:hive_ui/features/messaging/data/services/friend_messaging_service.dart';
import 'package:hive_ui/features/messaging/data/services/space_messaging_service.dart';
import 'package:hive_ui/features/messaging/data/services/realtime_messaging_service.dart';
import 'package:hive_ui/features/messaging/domain/entities/chat.dart';
import 'package:hive_ui/features/messaging/domain/entities/chat_user.dart';
import 'package:hive_ui/features/messaging/domain/entities/message.dart';
import 'package:hive_ui/features/messaging/domain/repositories/message_repository.dart';
import 'package:uuid/uuid.dart';
import 'package:logging/logging.dart';

// Logger provider for centralized logging
final loggerProvider = Provider<Logger>((ref) {
  return Logger('MessagingModule');
});

// Repository provider
final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return FirebaseMessageRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
    storage: FirebaseStorage.instance,
    uuid: const Uuid(),
  );
});

// Service providers
final friendMessagingServiceProvider = Provider<FriendMessagingService>((ref) {
  final repository = ref.watch(messageRepositoryProvider);
  return FriendMessagingService(messageRepository: repository);
});

final spaceMessagingServiceProvider = Provider<SpaceMessagingService>((ref) {
  final repository = ref.watch(messageRepositoryProvider);
  return SpaceMessagingService(messageRepository: repository);
});

final realtimeMessagingServiceProvider = Provider<RealtimeMessagingService>((ref) {
  return RealtimeMessagingService();
});

// Use case provider
final messageUseCaseProvider = Provider<MessageUseCase>((ref) {
  final repository = ref.watch(messageRepositoryProvider);
  final friendService = ref.watch(friendMessagingServiceProvider);
  final spaceService = ref.watch(spaceMessagingServiceProvider);
  final realtimeService = ref.watch(realtimeMessagingServiceProvider);
  
  return MessageUseCase(
    messageRepository: repository,
    friendMessagingService: friendService,
    spaceMessagingService: spaceService,
    realtimeMessagingService: realtimeService,
  );
});

// Current user ID provider
final currentUserIdProvider = Provider<String?>((ref) {
  return FirebaseAuth.instance.currentUser?.uid;
});

// User chats stream provider
final userChatsStreamProvider = StreamProvider.family<List<Chat>, String>((ref, userId) {
  final useCase = ref.watch(messageUseCaseProvider);
  return useCase.getUserChats(userId);
});

// Chat messages stream provider
final chatMessagesStreamProvider = StreamProvider.family<List<Message>, String>((ref, chatId) {
  final useCase = ref.watch(messageUseCaseProvider);
  return useCase.getChatMessages(chatId);
});

// Chat typing indicators stream provider
final typingIndicatorsProvider = StreamProvider.family<Map<String, DateTime>, String>((ref, chatId) {
  final useCase = ref.watch(messageUseCaseProvider);
  return useCase.getTypingIndicators(chatId);
});

// Chat participants provider
final chatParticipantsProvider = FutureProvider.family<List<ChatUser>, String>((ref, chatId) async {
  final useCase = ref.watch(messageUseCaseProvider);
  return await useCase.getChatParticipants(chatId);
});

// Space chat availability provider
final spaceChatAvailabilityProvider = FutureProvider.family<bool, String>((ref, spaceId) async {
  final useCase = ref.watch(messageUseCaseProvider);
  return await useCase.isSpaceChatUnlocked(spaceId);
});

// Space chat members needed provider
final spaceChatMembersNeededProvider = FutureProvider.family<int, String>((ref, spaceId) async {
  final useCase = ref.watch(messageUseCaseProvider);
  return await useCase.getMembersNeededForChat(spaceId);
});

// Friend chat suggestions provider
final friendChatSuggestionsProvider = FutureProvider.family<List<ChatUser>, String>((ref, userId) async {
  final useCase = ref.watch(messageUseCaseProvider);
  return await useCase.getFriendChatSuggestions(userId);
});

// Messaging friends provider
final messagingFriendsProvider = FutureProvider.family<List<ChatUser>, String>((ref, userId) async {
  final useCase = ref.watch(messageUseCaseProvider);
  return await useCase.getMessagingFriends(userId);
});

// Send text message provider
final sendTextMessageProvider = FutureProvider.family<Message, ({String chatId, String content})>((ref, params) async {
  final useCase = ref.watch(messageUseCaseProvider);
  final userId = ref.watch(currentUserIdProvider);
  
  if (userId == null) {
    throw Exception('User not authenticated');
  }
  
  return await useCase.sendTextMessage(params.chatId, userId, params.content);
});

// Send image message provider
final sendImageMessageProvider = FutureProvider.family<Message, ({String chatId, File imageFile, String? caption})>((ref, params) async {
  final useCase = ref.watch(messageUseCaseProvider);
  final userId = ref.watch(currentUserIdProvider);
  
  if (userId == null) {
    throw Exception('User not authenticated');
  }
  
  return await useCase.sendImageMessage(params.chatId, userId, params.imageFile, caption: params.caption);
});

// Mark chat as read provider
final markChatAsReadProvider = FutureProvider.family<void, String>((ref, chatId) async {
  final useCase = ref.watch(messageUseCaseProvider);
  final userId = ref.watch(currentUserIdProvider);
  
  if (userId == null) {
    throw Exception('User not authenticated');
  }
  
  return await useCase.markChatAsRead(chatId, userId);
});

// Space chat provider
final spaceChatProvider = FutureProvider.family<Chat?, String>((ref, spaceId) async {
  final useCase = ref.watch(messageUseCaseProvider);
  return await useCase.getSpaceChat(spaceId);
});

// Friend chat provider
final friendChatProvider = FutureProvider.family<Chat, String>((ref, friendId) async {
  final useCase = ref.watch(messageUseCaseProvider);
  final userId = ref.watch(currentUserIdProvider);
  
  if (userId == null) {
    throw Exception('User not authenticated');
  }
  
  return await useCase.startFriendChat(userId, friendId);
});

// Delete message provider
final deleteMessageProvider = FutureProvider.family<void, ({String chatId, String messageId})>((ref, params) async {
  final useCase = ref.watch(messageUseCaseProvider);
  final userId = ref.watch(currentUserIdProvider);
  
  if (userId == null) {
    throw Exception('User not authenticated');
  }
  
  return await useCase.deleteMessage(params.chatId, params.messageId, userId);
});

// Current chat ID provider - to track which chat the user is currently viewing
final currentChatIdProvider = StateProvider<String?>((ref) => null);

// Typing status provider - to handle typing status updates
final isTypingProvider = StateProvider<bool>((ref) => false);

// Message input provider - to handle text input
final messageInputProvider = StateProvider<String>((ref) => '');

// Search query provider - for message search
final chatSearchQueryProvider = StateProvider<String>((ref) => '');

// Search results provider
final userSearchResultsProvider = StateProvider<List<ChatUser>>((ref) => []);

// Is searching state provider
final isSearchingProvider = StateProvider<bool>((ref) => false);

// Message sending state provider - to track message sending status for each chat
final isSendingMessageProvider = StateProvider.family<bool, String>((ref, chatId) => false);

// Online status providers
final onlineStatusProvider = StreamProvider.family<Map<String, bool>, List<String>>((ref, userIds) {
  final useCase = ref.watch(messageUseCaseProvider);
  return useCase.getUsersOnlineStatus(userIds);
});

final userOnlineStatusProvider = FutureProvider.family<bool, String>((ref, userId) async {
  final service = ref.watch(realtimeMessagingServiceProvider);
  return await service.getUserOnlineStatus(userId);
});

final userLastActiveProvider = FutureProvider.family<DateTime?, String>((ref, userId) async {
  final service = ref.watch(realtimeMessagingServiceProvider);
  return await service.getUserLastActive(userId);
});

// Message delivery status provider
final messageDeliveryStatusProvider = StreamProvider.family<Map<String, MessageDeliveryStatus>, String>((ref, messageId) {
  final useCase = ref.watch(messageUseCaseProvider);
  return useCase.getMessageDeliveryStatus(messageId);
});

// Provider to get a specific message by ID
final messageFutureProvider = FutureProvider.family<Message?, ({String chatId, String messageId})>((ref, params) async {
  final repository = ref.watch(messageRepositoryProvider);
  try {
    return await repository.getMessageById(params.chatId, params.messageId);
  } catch (e) {
    ref.read(loggerProvider).warning('Error fetching message: $e');
    return null;
  }
});

// Provider for thread messages
final threadMessagesStreamProvider = StreamProvider.family<List<Message>, ({String chatId, String threadParentId})>((ref, params) {
  final repository = ref.watch(messageRepositoryProvider);
  return repository.getThreadMessagesStream(params.chatId, params.threadParentId);
});

// Provider to get unread message count for a chat
final unreadMessageCountProvider = StreamProvider.family<int, String>((ref, chatId) {
  final repository = ref.watch(messageRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  
  if (userId == null) return Stream.value(0);
  
  return repository.getUnreadMessageCountStream(chatId, userId);
});

// Provider to load more messages (used for pagination/refresh)
final loadMoreMessagesProvider = FutureProvider.family<void, String>((ref, chatId) async {
  final repository = ref.watch(messageRepositoryProvider);
  final currentMessages = await repository.getChatMessages(chatId, limit: 20);
  
  if (currentMessages.isEmpty) return;
  
  final oldestMessageTimestamp = currentMessages.last.timestamp;
  
  // Load messages older than the oldest message we have
  await repository.getChatMessagesBefore(
    chatId, 
    oldestMessageTimestamp,
    limit: 20,
  );
});

// Provider for searching messages in a chat
final searchMessagesProvider = FutureProvider.family<List<Message>, ({String chatId, String query})>((ref, params) async {
  if (params.query.trim().length < 3) return [];
  
  final repository = ref.watch(messageRepositoryProvider);
  // Search for messages with the given query
  return repository.searchMessages(params.chatId, params.query);
});

// Action provider to update typing status
final updateTypingStatusProvider = Provider.family<Future<void> Function(bool), String>((ref, chatId) {
  final useCase = ref.watch(messageUseCaseProvider);
  final userId = FirebaseAuth.instance.currentUser?.uid;
  
  return (bool isTyping) async {
    if (userId == null) return;
    await useCase.updateTypingStatus(chatId, userId, isTyping);
  };
});

// Action provider to update online status
final updateOnlineStatusProvider = Provider<Future<void> Function(bool)>((ref) {
  final useCase = ref.watch(messageUseCaseProvider);
  final userId = FirebaseAuth.instance.currentUser?.uid;
  
  return (bool isOnline) async {
    if (userId == null) return;
    await useCase.updateUserOnlineStatus(userId, isOnline);
  };
});