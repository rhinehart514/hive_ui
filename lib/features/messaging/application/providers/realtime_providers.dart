import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/messaging/data/services/realtime_messaging_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Provider for the RealtimeMessagingService
final realtimeMessagingServiceProvider = Provider<RealtimeMessagingService>((ref) {
  return RealtimeMessagingService(
    database: FirebaseDatabase.instance,
  );
});

/// Provider for typing indicators in a specific chat
final typingIndicatorsProvider = StreamProvider.family<Map<String, DateTime>, String>((ref, chatId) {
  final service = ref.watch(realtimeMessagingServiceProvider);
  return service.getTypingIndicatorsStream(chatId);
});

/// Provider for online status of multiple users
final onlineStatusProvider = StreamProvider.family<Map<String, bool>, List<String>>((ref, userIds) {
  final service = ref.watch(realtimeMessagingServiceProvider);
  return service.getOnlineStatusStream(userIds);
});

/// Provider for a single user's online status
final userOnlineStatusProvider = FutureProvider.family<bool, String>((ref, userId) async {
  final service = ref.watch(realtimeMessagingServiceProvider);
  return await service.getUserOnlineStatus(userId);
});

/// Provider for a user's last active timestamp
final userLastActiveProvider = FutureProvider.family<DateTime?, String>((ref, userId) async {
  final service = ref.watch(realtimeMessagingServiceProvider);
  return await service.getUserLastActive(userId);
});

/// Provider for message delivery status
final messageDeliveryStatusProvider = StreamProvider.family<Map<String, MessageDeliveryStatus>, String>((ref, messageId) {
  final service = ref.watch(realtimeMessagingServiceProvider);
  return service.getMessageDeliveryStatusStream(messageId);
});

/// Action provider to update typing status
final updateTypingStatusProvider = Provider.family<Future<void> Function(bool), String>((ref, chatId) {
  final service = ref.watch(realtimeMessagingServiceProvider);
  final userId = FirebaseAuth.instance.currentUser?.uid;
  
  return (bool isTyping) async {
    if (userId == null) return;
    await service.updateTypingStatus(chatId, userId, isTyping);
  };
});

/// Action provider to update online status
final updateOnlineStatusProvider = Provider<Future<void> Function(bool)>((ref) {
  final service = ref.watch(realtimeMessagingServiceProvider);
  final userId = FirebaseAuth.instance.currentUser?.uid;
  
  return (bool isOnline) async {
    if (userId == null) return;
    await service.updateOnlineStatus(userId, isOnline);
  };
});

/// Action provider to update message delivery status
final updateMessageDeliveryStatusProvider = Provider.family<
    Future<void> Function(MessageDeliveryStatus), 
    ({String messageId, String receiverId})>((ref, params) {
  final service = ref.watch(realtimeMessagingServiceProvider);
  
  return (MessageDeliveryStatus status) async {
    await service.updateMessageDeliveryStatus(
      params.messageId,
      params.receiverId,
      status,
    );
  };
}); 