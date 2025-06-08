import 'package:flutter/foundation.dart';

/// Defines the different types of messages that can be sent
enum MessageType { text, image, video, audio, file, event, system }

/// Represents a message in a chat
class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final MessageType type;
  final String? attachmentUrl;
  final String? attachmentType;
  final String? replyToMessageId;
  final bool isPinned;
  final List<MessageReaction>? reactions;
  final List<String>? seenBy;
  final Map<String, dynamic>? metadata;
  final MessageEventData? eventData;
  final String? threadParentId; // For message threads/replies
  final int? replyCount; // Count of replies in a thread

  const Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    required this.isRead,
    required this.type,
    this.senderAvatar,
    this.attachmentUrl,
    this.attachmentType,
    this.replyToMessageId,
    this.isPinned = false,
    this.reactions,
    this.seenBy,
    this.metadata,
    this.eventData,
    this.threadParentId,
    this.replyCount,
  });

  /// Creates a copy of this Message with the given fields replaced with new values
  Message copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? content,
    DateTime? timestamp,
    bool? isRead,
    MessageType? type,
    String? attachmentUrl,
    String? attachmentType,
    String? replyToMessageId,
    bool? isPinned,
    List<MessageReaction>? reactions,
    List<String>? seenBy,
    Map<String, dynamic>? metadata,
    MessageEventData? eventData,
    String? threadParentId,
    int? replyCount,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentType: attachmentType ?? this.attachmentType,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      isPinned: isPinned ?? this.isPinned,
      reactions: reactions ?? this.reactions,
      seenBy: seenBy ?? this.seenBy,
      metadata: metadata ?? this.metadata,
      eventData: eventData ?? this.eventData,
      threadParentId: threadParentId ?? this.threadParentId,
      replyCount: replyCount ?? this.replyCount,
    );
  }

  /// Checks if this message has a media attachment
  bool get hasAttachment => attachmentUrl != null && attachmentUrl!.isNotEmpty;

  /// Checks if this message is part of a thread
  bool get isThreadMessage => threadParentId != null;

  /// Checks if this message has replies
  bool get hasReplies => replyCount != null && replyCount! > 0;

  /// Creates a text message
  factory Message.text({
    required String id,
    required String chatId,
    required String senderId,
    required String senderName,
    required String content,
    required DateTime timestamp,
    String? senderAvatar,
    String? replyToMessageId,
    String? threadParentId,
  }) {
    return Message(
      id: id,
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      content: content,
      timestamp: timestamp,
      isRead: false,
      type: MessageType.text,
      replyToMessageId: replyToMessageId,
      seenBy: [senderId],
      threadParentId: threadParentId,
    );
  }

  /// Creates an image message
  factory Message.image({
    required String id,
    required String chatId,
    required String senderId,
    required String senderName,
    required String imageUrl,
    required DateTime timestamp,
    String? caption,
    String? senderAvatar,
    String? replyToMessageId,
    String? threadParentId,
  }) {
    return Message(
      id: id,
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      content: caption ?? 'Image',
      timestamp: timestamp,
      isRead: false,
      type: MessageType.image,
      attachmentUrl: imageUrl,
      attachmentType: 'image',
      replyToMessageId: replyToMessageId,
      seenBy: [senderId],
      threadParentId: threadParentId,
    );
  }

  /// Creates a system message (e.g., "User joined the chat")
  factory Message.system({
    required String id,
    required String chatId,
    required String content,
    required DateTime timestamp,
  }) {
    return Message(
      id: id,
      chatId: chatId,
      senderId: 'system',
      senderName: 'System',
      content: content,
      timestamp: timestamp,
      isRead: true,
      type: MessageType.system,
      seenBy: ['system'],
    );
  }

  /// Converts a Message to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'type': type.toString().split('.').last,
      'attachmentUrl': attachmentUrl,
      'attachmentType': attachmentType,
      'replyToMessageId': replyToMessageId,
      'isPinned': isPinned,
      'reactions': reactions?.map((e) => e.toMap()).toList(),
      'seenBy': seenBy,
      'metadata': metadata,
      'eventData': eventData?.toMap(),
      'threadParentId': threadParentId,
      'replyCount': replyCount,
    };
  }

  /// Creates a Message from a Firestore document
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as String,
      chatId: map['chatId'] as String,
      senderId: map['senderId'] as String,
      senderName: map['senderName'] as String,
      senderAvatar: map['senderAvatar'] as String?,
      content: map['content'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      isRead: map['isRead'] as bool,
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == (map['type'] as String),
        orElse: () => MessageType.text,
      ),
      attachmentUrl: map['attachmentUrl'] as String?,
      attachmentType: map['attachmentType'] as String?,
      replyToMessageId: map['replyToMessageId'] as String?,
      isPinned: map['isPinned'] as bool? ?? false,
      reactions: map['reactions'] != null
          ? List<MessageReaction>.from(
              (map['reactions'] as List).map(
                (x) => MessageReaction.fromMap(x as Map<String, dynamic>),
              ),
            )
          : null,
      seenBy: map['seenBy'] != null
          ? List<String>.from(map['seenBy'] as List)
          : null,
      metadata: map['metadata'] as Map<String, dynamic>?,
      eventData: map['eventData'] != null
          ? MessageEventData.fromMap(map['eventData'] as Map<String, dynamic>)
          : null,
      threadParentId: map['threadParentId'] as String?,
      replyCount: map['replyCount'] as int?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Message &&
        other.id == id &&
        other.chatId == chatId &&
        other.senderId == senderId &&
        other.senderName == senderName &&
        other.senderAvatar == senderAvatar &&
        other.content == content &&
        other.timestamp == timestamp &&
        other.isRead == isRead &&
        other.type == type &&
        other.attachmentUrl == attachmentUrl &&
        other.attachmentType == attachmentType &&
        other.replyToMessageId == replyToMessageId &&
        other.isPinned == isPinned &&
        listEquals(other.reactions, reactions) &&
        listEquals(other.seenBy, seenBy) &&
        mapEquals(other.metadata, metadata) &&
        other.eventData == eventData &&
        other.threadParentId == threadParentId &&
        other.replyCount == replyCount;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        chatId.hashCode ^
        senderId.hashCode ^
        senderName.hashCode ^
        senderAvatar.hashCode ^
        content.hashCode ^
        timestamp.hashCode ^
        isRead.hashCode ^
        type.hashCode ^
        attachmentUrl.hashCode ^
        attachmentType.hashCode ^
        replyToMessageId.hashCode ^
        isPinned.hashCode ^
        reactions.hashCode ^
        seenBy.hashCode ^
        metadata.hashCode ^
        eventData.hashCode ^
        threadParentId.hashCode ^
        replyCount.hashCode;
  }
}

/// Represents a reaction to a message (e.g., emoji reactions)
class MessageReaction {
  final String userId;
  final String emoji;
  final DateTime timestamp;

  const MessageReaction({
    required this.userId,
    required this.emoji,
    required this.timestamp,
  });

  MessageReaction copyWith({
    String? userId,
    String? emoji,
    DateTime? timestamp,
  }) {
    return MessageReaction(
      userId: userId ?? this.userId,
      emoji: emoji ?? this.emoji,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'emoji': emoji,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory MessageReaction.fromMap(Map<String, dynamic> map) {
    return MessageReaction(
      userId: map['userId'] as String,
      emoji: map['emoji'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MessageReaction &&
        other.userId == userId &&
        other.emoji == emoji &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode => userId.hashCode ^ emoji.hashCode ^ timestamp.hashCode;
}

/// Represents event data that can be attached to a message
class MessageEventData {
  final String eventId;
  final String eventTitle;
  final DateTime eventDateTime;
  final String eventLocation;
  final String? eventImageUrl;
  final int? attendeeCount;
  final bool? isRsvped;

  const MessageEventData({
    required this.eventId,
    required this.eventTitle,
    required this.eventDateTime,
    required this.eventLocation,
    this.eventImageUrl,
    this.attendeeCount,
    this.isRsvped,
  });

  MessageEventData copyWith({
    String? eventId,
    String? eventTitle,
    DateTime? eventDateTime,
    String? eventLocation,
    String? eventImageUrl,
    int? attendeeCount,
    bool? isRsvped,
  }) {
    return MessageEventData(
      eventId: eventId ?? this.eventId,
      eventTitle: eventTitle ?? this.eventTitle,
      eventDateTime: eventDateTime ?? this.eventDateTime,
      eventLocation: eventLocation ?? this.eventLocation,
      eventImageUrl: eventImageUrl ?? this.eventImageUrl,
      attendeeCount: attendeeCount ?? this.attendeeCount,
      isRsvped: isRsvped ?? this.isRsvped,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'eventTitle': eventTitle,
      'eventDateTime': eventDateTime.toIso8601String(),
      'eventLocation': eventLocation,
      'eventImageUrl': eventImageUrl,
      'attendeeCount': attendeeCount,
      'isRsvped': isRsvped,
    };
  }

  factory MessageEventData.fromMap(Map<String, dynamic> map) {
    return MessageEventData(
      eventId: map['eventId'] as String,
      eventTitle: map['eventTitle'] as String,
      eventDateTime: DateTime.parse(map['eventDateTime'] as String),
      eventLocation: map['eventLocation'] as String,
      eventImageUrl: map['eventImageUrl'] as String?,
      attendeeCount: map['attendeeCount'] as int?,
      isRsvped: map['isRsvped'] as bool?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MessageEventData &&
        other.eventId == eventId &&
        other.eventTitle == eventTitle &&
        other.eventDateTime == eventDateTime &&
        other.eventLocation == eventLocation &&
        other.eventImageUrl == eventImageUrl &&
        other.attendeeCount == attendeeCount &&
        other.isRsvped == isRsvped;
  }

  @override
  int get hashCode {
    return eventId.hashCode ^
        eventTitle.hashCode ^
        eventDateTime.hashCode ^
        eventLocation.hashCode ^
        eventImageUrl.hashCode ^
        attendeeCount.hashCode ^
        isRsvped.hashCode;
  }
}
