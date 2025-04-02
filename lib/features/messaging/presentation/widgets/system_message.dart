import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:hive_ui/features/messaging/domain/entities/message.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// Widget to display system messages with a distinctive styling
class SystemMessage extends StatelessWidget {
  final Message message;
  
  const SystemMessage({
    Key? key,
    required this.message,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: Colors.grey.withOpacity(0.3),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade900.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.gold.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.content,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  timeago.format(message.timestamp),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: Colors.grey.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Factory constructor to create different types of system messages
  factory SystemMessage.forType(Message message) {
    if (message.type != MessageType.system) {
      throw ArgumentError('Message must be of type system');
    }
    
    return SystemMessage(message: message);
  }
  
  /// Helper to create a user joined message
  static Message createUserJoinedMessage(String chatId, String userName) {
    return Message.system(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: chatId,
      content: '$userName joined the chat',
      timestamp: DateTime.now(),
    );
  }
  
  /// Helper to create a user left message
  static Message createUserLeftMessage(String chatId, String userName) {
    return Message.system(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: chatId,
      content: '$userName left the chat',
      timestamp: DateTime.now(),
    );
  }
  
  /// Helper to create a chat created message
  static Message createChatCreatedMessage(String chatId, String creatorName) {
    return Message.system(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: chatId,
      content: '$creatorName created this chat',
      timestamp: DateTime.now(),
    );
  }
  
  /// Helper to create a message deleted notification
  static Message createMessageDeletedMessage(String chatId) {
    return Message.system(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: chatId,
      content: 'A message was deleted',
      timestamp: DateTime.now(),
    );
  }
  
  /// Helper to create a space unlock message
  static Message createSpaceUnlockedMessage(String chatId) {
    return Message.system(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: chatId,
      content: 'Space chat has been unlocked! 🎉',
      timestamp: DateTime.now(),
    );
  }
} 
 
 