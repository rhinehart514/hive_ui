import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/messaging/controllers/messaging_controller.dart';

/// Manages typing indicators with debouncing to reduce database writes
class TypingIndicatorManager {
  final String chatId;
  final MessagingController _messagingController;
  Timer? _debounceTimer;
  bool _isTyping = false;
  
  /// Duration for which typing indicator remains active
  static const Duration typingDuration = Duration(seconds: 5);
  
  /// Debounce time between typing indicator updates
  static const Duration debounceTime = Duration(milliseconds: 500);

  TypingIndicatorManager({
    required this.chatId,
    required MessagingController messagingController,
  }) : _messagingController = messagingController;

  /// Call this method when the user is typing
  void userIsTyping() {
    if (!_isTyping) {
      // If not currently marked as typing, update status immediately
      _setTypingStatus(true);
    } else {
      // If already typing, debounce the typing indicator updates
      _debounceTyping();
    }
  }

  /// Call this method when the user has stopped typing
  void userStoppedTyping() {
    // Cancel any pending debounce timer
    _debounceTimer?.cancel();
    
    // If currently typing, update status
    if (_isTyping) {
      _setTypingStatus(false);
    }
  }

  /// Private method to debounce the typing updates
  void _debounceTyping() {
    // Cancel any existing timer
    _debounceTimer?.cancel();
    
    // Set a new timer
    _debounceTimer = Timer(debounceTime, () {
      // After debounce time, extend the typing duration
      _debounceTimer = Timer(typingDuration, () {
        // Only update if still marked as typing
        if (_isTyping) {
          _setTypingStatus(false);
        }
      });
    });
  }

  /// Private method to update typing status in the database
  Future<void> _setTypingStatus(bool isTyping) async {
    // Update local state
    _isTyping = isTyping;
    
    try {
      // Update in the database
      await _messagingController.updateTypingStatus(chatId, isTyping);
    } catch (e) {
      // Silently handle errors - typing indicators are not critical
      print('Error updating typing status: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    // Cancel any pending timer
    _debounceTimer?.cancel();
    
    // Ensure typing status is set to false when disposed
    if (_isTyping) {
      // Use a fire-and-forget approach for cleanup
      _messagingController.updateTypingStatus(chatId, false).catchError((e) {
        // Ignore errors during disposal
        print('Error clearing typing status during disposal: $e');
      });
    }
  }
}

/// Provider for managing typing indicators
final typingIndicatorManagerProvider = Provider.family<TypingIndicatorManager, String>((ref, chatId) {
  final messagingController = ref.watch(messagingControllerProvider);
  
  // Create a new manager
  final manager = TypingIndicatorManager(
    chatId: chatId,
    messagingController: messagingController,
  );
  
  // Ensure the manager is disposed when no longer needed
  ref.onDispose(() {
    manager.dispose();
  });
  
  return manager;
}); 
 
 