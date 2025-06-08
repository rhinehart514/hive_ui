import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/messaging/domain/entities/message.dart';
import 'package:hive_ui/features/messaging/application/providers/messaging_providers.dart';
import 'package:hive_ui/features/spaces/presentation/providers/spaces_repository_provider.dart';
import 'package:hive_ui/features/spaces/presentation/providers/spaces_async_providers.dart' as async_providers;
import 'package:firebase_auth/firebase_auth.dart';

/// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  return FirebaseAuth.instance.currentUser;
});

/// Provider to get or create a chat for a space
final spaceChatProvider = FutureProvider.family<String?, String>((ref, spaceId) async {
  final spacesRepository = ref.watch(spacesRepositoryProvider);
  
  // Try to get existing chat ID
  final chatId = await spacesRepository.getSpaceChatId(spaceId);
  
  // If chat exists, return it
  if (chatId != null) {
    return chatId;
  }
  
  // Otherwise, create a new chat for this space
  try {
    // Get space details
    final space = await spacesRepository.getSpaceById(spaceId);
    if (space == null) {
      return null;
    }
    
    // Create chat
    return spacesRepository.createSpaceChat(spaceId, space.name, imageUrl: space.imageUrl);
  } catch (e) {
    // Log error
    print('Error creating space chat: $e');
    return null;
  }
});

/// Provider to get pinned messages in a chat
final pinnedMessagesProvider = FutureProvider.family<List<Message>, String>((ref, chatId) async {
  final messageRepository = ref.watch(messageRepositoryProvider);
  
  try {
    // Get chat details to get pinnedMessageIds
    final chat = await messageRepository.getChatDetails(chatId);
    
    // If no pinned messages, return empty list
    if (chat.pinnedMessageIds == null || chat.pinnedMessageIds!.isEmpty) {
      return [];
    }
    
    // Fetch each pinned message
    final messages = <Message>[];
    for (final messageId in chat.pinnedMessageIds!) {
      final message = await messageRepository.getMessageById(chatId, messageId);
      if (message != null) {
        messages.add(message);
      }
    }
    
    return messages;
  } catch (e) {
    print('Error getting pinned messages: $e');
    return [];
  }
});

/// Provider to check if current user can pin messages in a space
final canPinMessagesProvider = Provider.family<bool, String>((ref, spaceId) {
  final currentUser = ref.watch(currentUserProvider);
  
  if (currentUser == null) {
    return false;
  }
  
  // Get space details from the repository directly
  final spaceAsync = ref.watch(async_providers.spaceByIdProvider(spaceId));
  
  return spaceAsync.maybeWhen(
    data: (space) {
      if (space == null) return false;
      
      // User can pin if they're an admin or moderator
      return space.admins.contains(currentUser.uid) || 
             space.moderators.contains(currentUser.uid);
    },
    orElse: () => false,
  );
}); 