import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/messaging/application/providers/messaging_providers.dart';
import 'package:hive_ui/features/messaging/utils/online_status_manager.dart';
import 'package:hive_ui/features/messaging/data/services/realtime_messaging_service.dart';
import 'package:go_router/go_router.dart';

/// A provider to initialize messaging services
/// Reference this in your app's initialization code to set up messaging features
final messagingInitializerProvider = Provider<void>((ref) {
  // Initialize online status tracking
  ref.watch(onlineStatusManagerProvider);
  
  // Setup auth state listener
  final authStateListener = FirebaseAuth.instance.authStateChanges().listen((User? user) {
    if (user != null) {
      // User logged in - set online status
      final updateOnlineStatus = ref.read(updateOnlineStatusProvider);
      updateOnlineStatus(true);
    }
  });
  
  // Clean up listener on dispose
  ref.onDispose(() {
    authStateListener.cancel();
    debugPrint('MessagingInitializer: Cleaned up auth state listener');
  });
  
  debugPrint('MessagingInitializer: Messaging services initialized');
});

/// Helper to navigate to the chat screen from anywhere in the app
void navigateToMessaging(BuildContext context) {
  context.push('/messaging');
}

/// Helper to navigate directly to a specific chat
void navigateToChat(BuildContext context, String chatId, {
  String? chatName,
  String? chatAvatar,
  bool isGroupChat = false,
}) {
  context.push('/chat/$chatId', extra: {
    'chatName': chatName ?? '',
    'chatAvatar': chatAvatar,
    'isGroupChat': isGroupChat,
  });
} 