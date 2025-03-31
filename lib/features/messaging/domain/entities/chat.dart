import 'package:flutter/foundation.dart';

enum ChatType { direct, group, club, event }

/// Represents a chat conversation in the system
class Chat {
  final String id;
  final String title;
  final String? imageUrl;
  final ChatType type;
  final List<String> participantIds;
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final String? lastMessageText;
  final String? lastMessageSenderId;
  final Map<String, int> unreadCount;
  final List<String>? pinnedMessageIds;
  final String? clubId; // For club chats
  final String? eventId; // For event chats

  const Chat({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.type,
    required this.participantIds,
    required this.createdAt,
    this.lastMessageAt,
    this.lastMessageText,
    this.lastMessageSenderId,
    required this.unreadCount,
    this.pinnedMessageIds,
    this.clubId,
    this.eventId,
  });

  /// Creates a copy of this Chat with the given fields replaced with new values
  Chat copyWith({
    String? id,
    String? title,
    String? imageUrl,
    ChatType? type,
    List<String>? participantIds,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    String? lastMessageText,
    String? lastMessageSenderId,
    Map<String, int>? unreadCount,
    List<String>? pinnedMessageIds,
    String? clubId,
    String? eventId,
  }) {
    return Chat(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      participantIds: participantIds ?? this.participantIds,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCount: unreadCount ?? this.unreadCount,
      pinnedMessageIds: pinnedMessageIds ?? this.pinnedMessageIds,
      clubId: clubId ?? this.clubId,
      eventId: eventId ?? this.eventId,
    );
  }

  /// Returns the unread count for a specific user
  int getUnreadCountForUser(String userId) {
    return unreadCount[userId] ?? 0;
  }

  /// Checks if the chat is a direct message between two users
  bool get isDirectMessage => type == ChatType.direct;

  /// Checks if the chat is a club chat
  bool get isClubChat => type == ChatType.club;

  /// Checks if the chat is a group chat
  bool get isGroupChat => type == ChatType.group;

  /// Checks if the chat is an event chat
  bool get isEventChat => type == ChatType.event;

  /// Gets a preview text for the chat list
  String getPreviewText() {
    if (lastMessageText != null && lastMessageText!.isNotEmpty) {
      return lastMessageText!.length > 50
          ? '${lastMessageText!.substring(0, 47)}...'
          : lastMessageText!;
    }
    return 'No messages yet';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Chat &&
        other.id == id &&
        other.title == title &&
        other.imageUrl == imageUrl &&
        other.type == type &&
        listEquals(other.participantIds, participantIds) &&
        other.createdAt == createdAt &&
        other.lastMessageAt == lastMessageAt &&
        other.lastMessageText == lastMessageText &&
        other.lastMessageSenderId == lastMessageSenderId &&
        mapEquals(other.unreadCount, unreadCount) &&
        listEquals(other.pinnedMessageIds, pinnedMessageIds) &&
        other.clubId == clubId &&
        other.eventId == eventId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        imageUrl.hashCode ^
        type.hashCode ^
        participantIds.hashCode ^
        createdAt.hashCode ^
        lastMessageAt.hashCode ^
        lastMessageText.hashCode ^
        lastMessageSenderId.hashCode ^
        unreadCount.hashCode ^
        pinnedMessageIds.hashCode ^
        clubId.hashCode ^
        eventId.hashCode;
  }

  /// Converts a Chat to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'type': type.toString().split('.').last,
      'participantIds': participantIds,
      'createdAt': createdAt.toIso8601String(),
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'lastMessageText': lastMessageText,
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCount': unreadCount,
      'pinnedMessageIds': pinnedMessageIds,
      'clubId': clubId,
      'eventId': eventId,
    };
  }

  /// Creates a Chat from a Firestore document
  factory Chat.fromMap(Map<String, dynamic> map) {
    return Chat(
      id: map['id'] as String,
      title: map['title'] as String,
      imageUrl: map['imageUrl'] as String?,
      type: ChatType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => ChatType.direct,
      ),
      participantIds: List<String>.from(map['participantIds'] as List),
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastMessageAt: map['lastMessageAt'] != null
          ? DateTime.parse(map['lastMessageAt'] as String)
          : null,
      lastMessageText: map['lastMessageText'] as String?,
      lastMessageSenderId: map['lastMessageSenderId'] as String?,
      unreadCount: Map<String, int>.from(map['unreadCount'] as Map),
      pinnedMessageIds: map['pinnedMessageIds'] != null
          ? List<String>.from(map['pinnedMessageIds'] as List)
          : null,
      clubId: map['clubId'] as String?,
      eventId: map['eventId'] as String?,
    );
  }
}
