import 'package:get_it/get_it.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/messaging/controllers/messaging_controller.dart';
import 'package:hive_ui/features/messaging/data/repositories/firebase_message_repository.dart';
import 'package:hive_ui/features/messaging/domain/repositories/message_repository.dart';
import 'package:hive_ui/features/messaging/domain/entities/chat.dart';
import 'package:hive_ui/features/messaging/domain/entities/message.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:hive_ui/providers/user_providers.dart';
import 'package:hive_ui/features/messaging/domain/entities/chat_user.dart';
import 'package:hive_ui/features/messaging/application/usecases/message_use_case.dart';
import 'package:hive_ui/features/messaging/data/services/friend_messaging_service.dart';
import 'package:hive_ui/features/messaging/data/services/space_messaging_service.dart';
import 'package:hive_ui/features/messaging/data/services/realtime_messaging_service.dart';
import 'package:hive_ui/features/messaging/presentation/screens/chat_detail_screen.dart';
import 'package:hive_ui/features/messaging/presentation/screens/chat_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:hive_ui/features/messaging/application/providers/messaging_providers.dart';

/// Re-export providers from messaging_providers for easy access
export 'application/providers/messaging_providers.dart';

/// GetIt service locator
final GetIt serviceLocator = GetIt.instance;

/// Provides the message repository
final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return FirebaseMessageRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
    storage: FirebaseStorage.instance,
    uuid: const Uuid(),
  );
});

/// Provides the messaging controller
final messagingControllerProvider = Provider<MessagingController>((ref) {
  final messageUseCase = ref.read(messageUseCaseProvider);
  return MessagingController(messageUseCase: messageUseCase);
});

/// Streams all chats for the current user
final userChatsStreamProvider = StreamProvider<List<Chat>>((ref) {
  final userData = ref.read(userProvider);
  final userId = userData?.id ?? FirebaseAuth.instance.currentUser?.uid;

  if (userId == null) {
    return Stream.value([]);
  }

  final repository = ref.watch(messageRepositoryProvider);
  return repository.getUserChatsStream(userId);
});

/// Streams messages for a specific chat
final chatMessagesStreamProvider =
    StreamProvider.family<List<Message>, String>((ref, chatId) {
  final repository = ref.watch(messageRepositoryProvider);
  return repository.getChatMessagesStream(chatId);
});

/// Streams typing indicators for a specific chat
final typingUsersStreamProvider =
    StreamProvider.family<Map<String, DateTime>, String>((ref, chatId) {
  final repository = ref.watch(messageRepositoryProvider);
  return repository.getTypingStatusStream(chatId);
});

/// Gets chat details for a specific chat
final chatDetailsProvider =
    FutureProvider.family<Chat, String>((ref, chatId) async {
  final repository = ref.watch(messageRepositoryProvider);
  return await repository.getChatDetails(chatId);
});

/// Gets participants for a specific chat
final chatParticipantsProvider =
    FutureProvider.family<List<ChatUser>, String>((ref, chatId) async {
  final repository = ref.watch(messageRepositoryProvider);
  return await repository.getChatParticipants(chatId);
});

/// Creates a direct chat between two users
final createDirectChatProvider =
    FutureProvider.family<String, String>((ref, targetUserId) async {
  final userData = ref.read(userProvider);
  final currentUserId = userData?.id ?? FirebaseAuth.instance.currentUser?.uid;

  if (currentUserId == null) {
    throw Exception('User not authenticated');
  }

  final repository = ref.watch(messageRepositoryProvider);
  return await repository.createDirectChat(currentUserId, targetUserId);
});

/// Creates a group chat
final createGroupChatProvider = FutureProvider.family<
    String,
    ({
      String title,
      List<String> participantIds,
      String? imageUrl
    })>((ref, params) async {
  final repository = ref.watch(messageRepositoryProvider);
  return await repository.createGroupChat(params.title, params.participantIds,
      imageUrl: params.imageUrl);
});

/// Registers messaging dependencies with GetIt
void registerMessagingDependencies(GetIt locator) {
  // Repositories
  locator.registerLazySingleton<MessageRepository>(
    () => FirebaseMessageRepository(
      firestore: locator<FirebaseFirestore>(),
      storage: locator<FirebaseStorage>(),
      auth: locator<FirebaseAuth>(),
      uuid: locator<Uuid>(),
    ),
  );
  
  // Services
  locator.registerLazySingleton<FriendMessagingService>(
    () => FriendMessagingService(
      messageRepository: locator<MessageRepository>(),
      firestore: locator<FirebaseFirestore>(),
    ),
  );
  
  locator.registerLazySingleton<SpaceMessagingService>(
    () => SpaceMessagingService(
      messageRepository: locator<MessageRepository>(),
      firestore: locator<FirebaseFirestore>(),
    ),
  );
  
  locator.registerLazySingleton<RealtimeMessagingService>(
    () => RealtimeMessagingService(),
  );
  
  // Use cases
  locator.registerLazySingleton<MessageUseCase>(
    () => MessageUseCase(
      messageRepository: locator<MessageRepository>(),
      friendMessagingService: locator<FriendMessagingService>(),
      spaceMessagingService: locator<SpaceMessagingService>(),
      realtimeMessagingService: locator<RealtimeMessagingService>(),
    ),
  );
}

/// Registers all messaging related routes
Map<String, Widget Function(BuildContext)> getMessagingRoutes() {
  return {
    '/messages': (context) => const ChatListScreen(),
    '/chat_detail': (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final chatId = args?['chatId'] as String? ?? '';
      return ChatDetailScreen(chatId: chatId);
    },
  };
}

/// Initializes messaging services
void initializeMessaging() {
  try {
    // Register dependencies if they are not already
    if (!serviceLocator.isRegistered<MessageRepository>()) {
      registerMessagingDependencies(serviceLocator);
    }
  } catch (e) {
    // Using a comment instead of print for logging
    // TODO: Replace with proper logging implementation
    // Error initializing messaging services: $e
  }
}
