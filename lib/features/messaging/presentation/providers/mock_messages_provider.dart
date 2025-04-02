import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class Message {
  final String id;
  final String content;
  final DateTime timestamp;
  final String senderId;
  final bool isMe;
  final MessageStatus status;

  Message({
    String? id,
    required this.content,
    required this.senderId,
    required this.isMe,
    DateTime? timestamp,
    this.status = MessageStatus.sent,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();
}

enum MessageStatus { sent, delivered, read }

class Conversation {
  final String id;
  final String name;
  final String avatarUrl;
  final List<Message> messages;
  final DateTime lastMessageTime;
  final bool isOnline;

  Conversation({
    String? id,
    required this.name,
    required this.avatarUrl,
    required this.messages,
    required this.isOnline,
  })  : id = id ?? const Uuid().v4(),
        lastMessageTime = messages.isNotEmpty
            ? messages.last.timestamp
            : DateTime.now();
}

final mockConversationsProvider = StateProvider<List<Conversation>>((ref) {
  return [
    Conversation(
      name: "Sarah Parker",
      avatarUrl: "https://i.pravatar.cc/150?img=1",
      isOnline: true,
      messages: [
        Message(
          content: "Hey! How's your day going? 😊",
          senderId: "2",
          isMe: false,
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        Message(
          content: "Pretty good! Just finished that project we talked about.",
          senderId: "1",
          isMe: true,
          timestamp: DateTime.now().subtract(const Duration(minutes: 55)),
        ),
        Message(
          content: "That's awesome! Would love to see it sometime",
          senderId: "2",
          isMe: false,
          timestamp: DateTime.now().subtract(const Duration(minutes: 50)),
        ),
      ],
    ),
    Conversation(
      name: "Alex Thompson",
      avatarUrl: "https://i.pravatar.cc/150?img=2",
      isOnline: false,
      messages: [
        Message(
          content: "Are we still on for coffee tomorrow?",
          senderId: "3",
          isMe: false,
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        Message(
          content: "Yes! Looking forward to it. 10 AM at the usual spot?",
          senderId: "1",
          isMe: true,
          timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 55)),
        ),
      ],
    ),
    Conversation(
      name: "Team Hive",
      avatarUrl: "https://i.pravatar.cc/150?img=3",
      isOnline: true,
      messages: [
        Message(
          content: "New feature deployment successful! 🚀",
          senderId: "4",
          isMe: false,
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
        Message(
          content: "Great work everyone!",
          senderId: "1",
          isMe: true,
          timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
        ),
      ],
    ),
  ];
}); 