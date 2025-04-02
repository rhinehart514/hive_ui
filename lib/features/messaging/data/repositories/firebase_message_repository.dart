import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as path;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:hive_ui/features/messaging/domain/entities/chat.dart';
import 'package:hive_ui/features/messaging/domain/entities/chat_user.dart';
import 'package:hive_ui/features/messaging/domain/entities/message.dart';
import 'package:hive_ui/features/messaging/domain/repositories/message_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/utils/firebase_threading_fix.dart';

/// Implementation note: This repository is currently incomplete.
/// Several methods need to be implemented to fully satisfy the MessageRepository interface.
class FirebaseMessageRepository implements MessageRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;
  final Uuid _uuid;

  FirebaseMessageRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required FirebaseStorage storage,
    required Uuid uuid,
  })  : _firestore = firestore,
        _auth = auth,
        _storage = storage,
        _uuid = uuid;

  // Collection references
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _chatsCollection => _firestore.collection('chats');
  CollectionReference _messagesCollection(String chatId) =>
      _firestore.collection('chats/$chatId/messages');
  CollectionReference get _spacesCollection => _firestore.collection('spaces');

  @override
  Future<List<String>> getChatsForUser(String userId) async {
    try {
      // Get all chats where user is a participant
      final chatsQuery = await _chatsCollection
          .where('participantIds', arrayContains: userId)
          .get();

      return chatsQuery.docs.map((doc) => doc.id).toList();
    } catch (e) {
      throw Exception('Failed to get chats: $e');
    }
  }

  @override
  Future<Chat> getChatDetails(String chatId) async {
    try {
      final docSnapshot = await _chatsCollection.doc(chatId).get();

      if (!docSnapshot.exists) {
        throw Exception('Chat not found');
      }

      final data = docSnapshot.data() as Map<String, dynamic>;

      return Chat(
        id: docSnapshot.id,
        title: data['title'] as String,
        imageUrl: data['imageUrl'] as String?,
        type: ChatType.values[data['type'] as int],
        participantIds: List<String>.from(data['participantIds'] ?? []),
        createdAt: (data['createdAt'] is Timestamp)
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.parse(data['createdAt'] as String),
        lastMessageAt: data['lastMessageAt'] != null
            ? (data['lastMessageAt'] is Timestamp)
                ? (data['lastMessageAt'] as Timestamp).toDate()
                : DateTime.parse(data['lastMessageAt'] as String)
            : null,
        lastMessageText: data['lastMessageText'] as String?,
        lastMessageSenderId: data['lastMessageSenderId'] as String?,
        unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
        pinnedMessageIds: data['pinnedMessageIds'] != null
            ? List<String>.from(data['pinnedMessageIds'])
            : null,
        clubId: data['clubId'] as String?,
      );
    } catch (e) {
      throw Exception('Failed to get chat details: $e');
    }
  }

  @override
  Future<String> createDirectChat(String userId1, String userId2) async {
    try {
      // Check if a direct chat already exists between these users
      final existingChatQuery = await _chatsCollection
          .where('type', isEqualTo: ChatType.direct.index)
          .where('participantIds', arrayContains: userId1)
          .get();

      for (final doc in existingChatQuery.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final participantIds = List<String>.from(data['participantIds'] ?? []);
        if (participantIds.contains(userId2) && participantIds.length == 2) {
          // Chat already exists, return chat ID
          return doc.id;
        }
      }

      // Create new chat
      final chatRef = _chatsCollection.doc();
      final timestamp = DateTime.now().toIso8601String();

      // Get user profiles for chat title and image
      final user1Doc = await _usersCollection.doc(userId1).get();
      final user2Doc = await _usersCollection.doc(userId2).get();

      if (!user1Doc.exists || !user2Doc.exists) {
        throw Exception('One or both users not found');
      }

      final user2Data = user2Doc.data() as Map<String, dynamic>;

      // Set chat data
      await chatRef.set({
        'title': user2Data['displayName'] ??
            'User', // For user1, the chat name is user2's name
        'imageUrl': user2Data['photoURL'],
        'type': ChatType.direct.index,
        'participantIds': [userId1, userId2],
        'createdAt': timestamp,
        'lastMessageAt': null,
        'lastMessageText': null,
        'lastMessageSenderId': null,
        'unreadCount': {
          userId1: 0,
          userId2: 0,
        },
      });

      return chatRef.id;
    } catch (e) {
      throw Exception('Failed to create direct chat: $e');
    }
  }

  @override
  Future<String> createGroupChat(String title, List<String> participantIds,
      {String? imageUrl}) async {
    try {
      // Create new group chat
      final chatRef = _chatsCollection.doc();
      final timestamp = DateTime.now().toIso8601String();

      // Prepare unread count map
      final unreadCount = <String, int>{};
      for (final userId in participantIds) {
        unreadCount[userId] = 0;
      }

      // Set chat data
      await chatRef.set({
        'title': title,
        'imageUrl': imageUrl, // Use the provided image URL
        'type': ChatType.group.index,
        'participantIds': participantIds,
        'createdAt': timestamp,
        'lastMessageAt': null,
        'lastMessageText': null,
        'lastMessageSenderId': null,
        'unreadCount': unreadCount,
      });

      // Create a system message indicating group creation
      final messageRef = _messagesCollection(chatRef.id).doc();

      await messageRef.set({
        'id': messageRef.id,
        'chatId': chatRef.id,
        'senderId': 'system',
        'senderName': 'System',
        'content': 'Group chat created',
        'timestamp': timestamp,
        'type': MessageType.system.index,
        'isRead': true,
        'seenBy': participantIds,
      });

      return chatRef.id;
    } catch (e) {
      throw Exception('Failed to create group chat: $e');
    }
  }

  @override
  Future<String> createClubChat(String clubId, String clubName,
      {String? imageUrl}) async {
    try {
      // Create new club chat
      final chatRef = _chatsCollection.doc();
      final timestamp = DateTime.now().toIso8601String();

      // Get club members
      final clubDoc = await _spacesCollection.doc(clubId).get();
      if (!clubDoc.exists) {
        throw Exception('Club not found');
      }

      final clubData = clubDoc.data() as Map<String, dynamic>;
      final memberIds = List<String>.from(clubData['memberIds'] ?? []);

      if (memberIds.isEmpty) {
        throw Exception('Club has no members');
      }

      // Prepare unread count map
      final unreadCount = <String, int>{};
      for (final userId in memberIds) {
        unreadCount[userId] = 0;
      }

      // Set chat data
      await chatRef.set({
        'title': clubName,
        'imageUrl': imageUrl,
        'type': ChatType.club.index,
        'participantIds': memberIds,
        'createdAt': timestamp,
        'lastMessageAt': null,
        'lastMessageText': null,
        'lastMessageSenderId': null,
        'unreadCount': unreadCount,
        'clubId': clubId,
      });

      // Create a system message indicating club chat creation
      final messageRef = _messagesCollection(chatRef.id).doc();

      await messageRef.set({
        'id': messageRef.id,
        'chatId': chatRef.id,
        'senderId': 'system',
        'senderName': 'System',
        'content': 'Club chat created',
        'timestamp': timestamp,
        'type': MessageType.system.index,
        'isRead': true,
        'seenBy': memberIds,
      });

      return chatRef.id;
    } catch (e) {
      throw Exception('Failed to create club chat: $e');
    }
  }

  @override
  Future<List<Message>> getMessagesForChat(String chatId,
      {int limit = 30, String? lastMessageId}) async {
    try {
      Query query = _messagesCollection(chatId)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (lastMessageId != null) {
        final lastDoc =
            await _messagesCollection(chatId).doc(lastMessageId).get();
        if (lastDoc.exists) {
          query = query.startAfterDocument(lastDoc);
        }
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        List<MessageReaction>? reactions;
        if (data['reactions'] != null) {
          reactions = (data['reactions'] as List).map((e) {
            return MessageReaction(
              userId: e['userId'],
              emoji: e['emoji'],
              timestamp: (e['timestamp'] is Timestamp)
                  ? (e['timestamp'] as Timestamp).toDate()
                  : DateTime.parse(e['timestamp'] as String),
            );
          }).toList();
        }

        // Handle message type
        MessageType messageType = MessageType.text;
        if (data['type'] != null) {
          if (data['type'] is int &&
              data['type'] >= 0 &&
              data['type'] < MessageType.values.length) {
            messageType = MessageType.values[data['type'] as int];
          } else if (data['type'] is String) {
            final typeStr = data['type'] as String;
            switch (typeStr.toLowerCase()) {
              case 'text':
                messageType = MessageType.text;
                break;
              case 'image':
                messageType = MessageType.image;
                break;
              case 'file':
                messageType = MessageType.file;
                break;
              case 'video':
                messageType = MessageType.video;
                break;
              case 'audio':
                messageType = MessageType.audio;
                break;
              case 'event':
                messageType = MessageType.event;
                break;
              case 'system':
                messageType = MessageType.system;
                break;
              default:
                messageType = MessageType.text;
            }
          }
        }

        // Handle eventData safely
        Map<String, dynamic>? eventDataMap = data['eventData'] as Map<String, dynamic>?;
        MessageEventData? eventData = eventDataMap != null
            ? MessageEventData.fromMap(eventDataMap)
            : null;

        return Message(
          id: doc.id,
          chatId: data['chatId'],
          senderId: data['senderId'],
          senderName: data['senderName'],
          senderAvatar: data['senderAvatar'],
          content: data['content'],
          timestamp: (data['timestamp'] is Timestamp)
              ? (data['timestamp'] as Timestamp).toDate()
              : DateTime.parse(data['timestamp'] as String),
          isRead: data['isRead'] ?? false,
          reactions: reactions,
          type: messageType,
          attachmentUrl: data['attachmentUrl'],
          attachmentType: data['attachmentType'],
          seenBy: data['seenBy'] != null
              ? List<String>.from(data['seenBy'])
              : const [],
          replyToMessageId: data['replyToMessageId'],
          isPinned: data['isPinned'] ?? false,
          eventData: eventData,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to get messages: $e');
    }
  }

  @override
  Future<List<Message>> getChatMessages(String chatId, {int limit = 30}) async {
    try {
      final messagesRef = _messagesCollection(chatId)
          .orderBy('timestamp', descending: true)
          .limit(limit);
      
      final messagesSnapshot = await messagesRef.get();
      
      return messagesSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Add the id to the map since it's required
        data['id'] = doc.id;
        return Message.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('Error getting chat messages: $e');
      return [];
    }
  }

  Future<Message> sendMessage(
    String chatId,
    String senderId,
    String content, {
    String? replyToMessageId,
    String? threadParentId,
  }) async {
    try {
      // Get sender info for the message
      final userDoc = await _usersCollection.doc(senderId).get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final userData = userDoc.data() as Map<String, dynamic>;

      // Check if chat exists
      final chatDoc = await _chatsCollection.doc(chatId).get();

      if (!chatDoc.exists) {
        throw Exception('Chat not found');
      }

      // Create the message
      final messageId = _uuid.v4();
      final timestamp = DateTime.now();

      // Basic message data
      final messageData = {
        'id': messageId,
        'chatId': chatId,
        'senderId': senderId,
        'senderName': userData['name'] ?? 'Unknown User',
        'senderAvatar': userData['avatar'],
        'content': content,
        'timestamp': timestamp,
        'isRead': false,
        'type': MessageType.text.index,
        'replyToMessageId': replyToMessageId,
        'threadParentId': threadParentId,
        'seenBy': [senderId],
      };

      // Save the message
      await _messagesCollection(chatId).doc(messageId).set(messageData);

      // Update chat with last message info
      await _chatsCollection.doc(chatId).update({
        'lastMessageText': content,
        'lastMessageAt': timestamp,
        'lastMessageSenderId': senderId,
      });

      // If this is a reply to a thread, increment the reply count on the parent message
      if (threadParentId != null) {
        await _messagesCollection(chatId).doc(threadParentId).update({
          'replyCount': FieldValue.increment(1),
        });
      }

      // If this is a new message in the chat, increment unread counts for all users except sender
      final chatData = chatDoc.data() as Map<String, dynamic>;
      final participantIds =
          List<String>.from(chatData['participantIds'] ?? []);

      final unreadCounts =
          Map<String, dynamic>.from(chatData['unreadCount'] ?? {});

      for (final userId in participantIds) {
        if (userId != senderId) {
          unreadCounts[userId] = (unreadCounts[userId] as int? ?? 0) + 1;
        }
      }

      await _chatsCollection.doc(chatId).update({
        'unreadCount': unreadCounts,
      });

      // Return the created message
      return Message(
        id: messageId,
        chatId: chatId,
        senderId: senderId,
        senderName: userData['name'] ?? 'Unknown User',
        senderAvatar: userData['avatar'],
        content: content,
        timestamp: timestamp,
        isRead: false,
        type: MessageType.text,
        replyToMessageId: replyToMessageId,
        threadParentId: threadParentId,
        seenBy: [senderId],
      );
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  @override
  Future<void> markMessageAsRead(String messageId, String userId) async {
    try {
      // Get the message to get its chat ID
      final messageDoc = await _messagesCollection(messageId.split('/')[0])
          .doc(messageId).get();
      if (!messageDoc.exists) {
        throw Exception('Message not found');
      }

      final messageData = messageDoc.data() as Map<String, dynamic>;
      final chatId = messageData['chatId'];

      // Add user to seenBy array if not already there
      await _messagesCollection(chatId).doc(messageId).update({
        'isRead': true,
        'seenBy': FieldValue.arrayUnion([userId]),
        'deliveryStatus': 'read',
      });

      // Reset unread count for this user in the chat
      await _chatsCollection.doc(chatId).update({
        'unreadCount.$userId': 0,
      });
    } catch (e) {
      throw Exception('Failed to mark message as read: $e');
    }
  }

  @override
  Future<void> deleteMessage(
      String chatId, String messageId, String userId) async {
    try {
      final messageRef = _messagesCollection(chatId).doc(messageId);
      final messageDoc = await messageRef.get();

      if (!messageDoc.exists) {
        throw Exception('Message not found');
      }

      final messageData = messageDoc.data() as Map<String, dynamic>;
      final senderId = messageData['senderId'] as String;

      // Only the sender can delete their own messages
      if (senderId != userId && userId != 'admin') {
        throw Exception('Not authorized to delete this message');
      }

      // Soft delete by updating the message
      await messageRef.update({
        'isDeleted': true,
        'content': 'This message was deleted',
        'attachmentUrl': null, // Remove attachment if any
      });
    } catch (e) {
      debugPrint('Error deleting message: $e');
      throw Exception('Failed to delete message: $e');
    }
  }

  @override
  Future<void> addMessageReaction(String chatId, String messageId, String userId, String emoji) async {
    try {
      final messageRef = _messagesCollection(chatId).doc(messageId);
      final messageDoc = await messageRef.get();

      if (!messageDoc.exists) {
        throw Exception('Message not found');
      }

      // Add reaction to the reactions map
      await messageRef.update({
        'reactions.$userId': emoji,
      });
    } catch (e) {
      throw Exception('Failed to add reaction: $e');
    }
  }

  @override
  Future<void> removeMessageReaction(String chatId, String messageId, String userId, String emoji) async {
    try {
      final messageRef = _messagesCollection(chatId).doc(messageId);
      final messageDoc = await messageRef.get();

      if (!messageDoc.exists) {
        throw Exception('Message not found');
      }

      // Remove reaction from the reactions map
      await messageRef.update({
        'reactions.$userId': FieldValue.delete(),
      });
    } catch (e) {
      throw Exception('Failed to remove reaction: $e');
    }
  }

  // Legacy methods that delegate to the new implementations
  @override
  Future<void> addReaction(String chatId, String messageId, String userId, String emoji) async {
    return addMessageReaction(chatId, messageId, userId, emoji);
  }

  @override
  Future<void> removeReaction(String chatId, String messageId, String userId, String emoji) async {
    return removeMessageReaction(chatId, messageId, userId, emoji);
  }

  @override
  Future<void> pinMessage(String messageId, String chatId) async {
    try {
      // Update message
      await _messagesCollection(chatId).doc(messageId).update({
        'isPinned': true,
      });

      // Add to pinned messages in chat
      await _chatsCollection.doc(chatId).update({
        'pinnedMessageIds': FieldValue.arrayUnion([messageId]),
      });
    } catch (e) {
      throw Exception('Failed to pin message: $e');
    }
  }

  @override
  Future<void> unpinMessage(String messageId, String chatId) async {
    try {
      // Update message
      await _messagesCollection(chatId).doc(messageId).update({
        'isPinned': false,
      });

      // Remove from pinned messages in chat
      await _chatsCollection.doc(chatId).update({
        'pinnedMessageIds': FieldValue.arrayRemove([messageId]),
      });
    } catch (e) {
      throw Exception('Failed to unpin message: $e');
    }
  }

  @override
  Future<List<Message>> getThreadMessages(String parentMessageId,
      {int limit = 30, String? lastMessageId}) async {
    return FirebaseThreadingFix.ensurePlatformThread(() async {
      try {
        final chatId = parentMessageId.split('/')[0];

        // Prepare the query - don't execute it yet
        Query query = _messagesCollection(chatId)
            .where('replyToMessageId', isEqualTo: parentMessageId)
            .orderBy('timestamp')
            .limit(limit);

        // For pagination, get the last doc reference first
        if (lastMessageId != null) {
          // Get document snapshot on the main thread
          final lastDoc =
              await _messagesCollection(chatId).doc(lastMessageId).get();

          if (lastDoc.exists) {
            query = query.startAfterDocument(lastDoc);
          }
        }

        // Execute the query on the main thread
        final querySnapshot = await query.get();

        // Process results
        return querySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;

          List<MessageReaction>? reactions;
          if (data['reactions'] != null) {
            reactions = (data['reactions'] as List).map((e) {
              return MessageReaction(
                userId: e['userId'],
                emoji: e['emoji'],
                timestamp: (e['timestamp'] as Timestamp).toDate(),
              );
            }).toList();
          }

          // Fixed: Using safe non-nullable type
          MessageType messageType = MessageType.text; // Default value
          if (data['type'] != null) {
            final typeValue = data['type'] as int;
            if (typeValue >= 0 && typeValue < MessageType.values.length) {
              messageType = MessageType.values[typeValue];
            }
          }

          return Message(
            id: doc.id,
            chatId: data['chatId'],
            senderId: data['senderId'],
            senderName: data['senderName'],
            senderAvatar: data['senderAvatar'],
            content: data['content'],
            timestamp: (data['timestamp'] as Timestamp).toDate(),
            isRead: data['isRead'] ?? false,
            reactions: reactions,
            type: messageType,
            attachmentUrl: data['attachmentUrl'],
            attachmentType: data['attachmentType'],
            seenBy: data['seenBy'] != null
                ? List<String>.from(data['seenBy'])
                : const [],
            replyToMessageId: data['replyToMessageId'],
            isPinned: data['isPinned'] ?? false,
          );
        }).toList();
      } catch (e) {
        throw Exception('Failed to get thread messages: $e');
      }
    });
  }

  @override
  Future<Message> getThreadReply(
    String parentMessageId,
    String senderId,
    String content,
  ) async {
    return FirebaseThreadingFix.ensurePlatformThread(() async {
      try {
        // Try to parse the chat ID from the parent message ID if possible
        String? chatId;

        // If parentMessageId contains a chatId/messageId pattern, extract it directly
        if (parentMessageId.contains('/')) {
          chatId = parentMessageId.split('/')[0];
        } else {
          // Otherwise, query for the parent message to find its chatId
          final parentMessageDoc = await _firestore
              .collectionGroup('messages')
              .where('id', isEqualTo: parentMessageId)
              .get();

          if (parentMessageDoc.docs.isEmpty) {
            throw Exception('Parent message not found');
          }

          final parentMessageData =
              parentMessageDoc.docs.first.data();
          chatId = parentMessageData['chatId'] as String;
        }

        // Now send as a regular message but with threadParentId
        return sendMessage(
          chatId,
          senderId,
          content,
          threadParentId: parentMessageId,
        );
      } catch (e) {
        throw Exception('Failed to send thread reply: $e');
      }
    });
  }

  @override
  Future<List<Message>> searchMessages(String chatId, String query,
      {int limit = 20}) async {
    try {
      // Perform case-insensitive search on message content
      final messagesSnapshot = await _messagesCollection(chatId)
          .where('content', isGreaterThanOrEqualTo: query)
          .where('content', isLessThanOrEqualTo: '$query\uf8ff')
          .orderBy('content')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return messagesSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final messageType = MessageType.values.firstWhere(
          (type) => type.toString().split('.').last == (data['type'] as String),
          orElse: () => MessageType.text,
        );

        // Convert event data if present
        Map<String, dynamic>? eventDataMap =
            data['eventData'] as Map<String, dynamic>?;
        MessageEventData? eventData = eventDataMap != null
            ? MessageEventData.fromMap(eventDataMap)
            : null;

        return Message(
          id: doc.id,
          chatId: data['chatId'] as String,
          senderId: data['senderId'] as String,
          senderName: data['senderName'] as String,
          senderAvatar: data['senderAvatar'] as String?,
          content: data['content'] as String,
          timestamp: data['timestamp'] is Timestamp
              ? (data['timestamp'] as Timestamp).toDate()
              : DateTime.parse(data['timestamp'] as String),
          isRead: data['isRead'] as bool? ?? false,
          type: messageType,
          attachmentUrl: data['attachmentUrl'] as String?,
          attachmentType: data['attachmentType'] as String?,
          replyToMessageId: data['replyToMessageId'] as String?,
          isPinned: data['isPinned'] as bool? ?? false,
          reactions: data['reactions'] != null
              ? List<MessageReaction>.from(
                  (data['reactions'] as List).map(
                    (x) => MessageReaction.fromMap(x as Map<String, dynamic>),
                  ),
                )
              : null,
          seenBy: data['seenBy'] != null
              ? List<String>.from(data['seenBy'] as List)
              : null,
          metadata: data['metadata'] as Map<String, dynamic>?,
          eventData: eventData,
          threadParentId: data['threadParentId'] as String?,
          replyCount: data['replyCount'] as int?,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to search messages: $e');
    }
  }

  // New methods for handling space message boards and friends-only messaging

  Future<void> createSpaceMessageBoard(String spaceId, String title) async {
    try {
      // Get all users in the space
      final spaceDoc = await _spacesCollection.doc(spaceId).get();

      if (!spaceDoc.exists) {
        throw Exception('Space not found');
      }

      final spaceData = spaceDoc.data() as Map<String, dynamic>;
      final List<String> memberIds =
          List<String>.from(spaceData['memberIds'] ?? []);

      // Create unread counts map for all members
      final Map<String, int> unreadCounts = {};
      for (final userId in memberIds) {
        unreadCounts[userId] = 0;
      }

      final chatId = _uuid.v4();

      await _chatsCollection.doc(chatId).set({
        'title': title,
        'type': ChatType.group.index,
        'participantIds': memberIds,
        'createdAt': FieldValue.serverTimestamp(),
        'unreadCount': unreadCounts,
        'spaceId': spaceId,
      });
    } catch (e) {
      throw Exception('Failed to create space message board: $e');
    }
  }

  Future<List<String>> getFriendIds(String userId) async {
    try {
      final userDoc = await _usersCollection.doc(userId).get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      return List<String>.from(userData['friendIds'] ?? []);
    } catch (e) {
      throw Exception('Failed to get friends: $e');
    }
  }

  Future<bool> canMessageUser(String senderId, String recipientId) async {
    try {
      final senderFriends = await getFriendIds(senderId);
      return senderFriends.contains(recipientId);
    } catch (e) {
      throw Exception('Failed to check messaging permission: $e');
    }
  }

  // Media handling methods

  Future<String> uploadMediaAttachment(
      File file, String chatId, String senderId) async {
    try {
      final fileName =
          '${chatId}_${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final storageRef = _storage.ref().child('chat_media/$chatId/$fileName');

      final uploadTask = storageRef.putFile(file);
      final snapshot = await uploadTask;

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload media: $e');
    }
  }

  // Add new method to get a stream of messages for real-time updates
  Stream<List<Message>> getMessagesStream(String chatId, {int limit = 30}) {
    try {
      return _messagesCollection(chatId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  // Add the id to the map since it's required
                  data['id'] = doc.id;
                  return Message.fromMap(data);
                })
                .toList();
          })
          .switchToUiThread();
    } catch (e) {
      throw Exception('Failed to get messages stream: $e');
    }
  }

  // Add a stream for chat updates
  Stream<Map<String, dynamic>> getChatDetailsStream(String chatId) {
    try {
      // Get a reference to the chat document
      final chatRef = _chatsCollection.doc(chatId);

      // Map the document snapshot to the chat details
      return chatRef.snapshots().map((snapshot) {
        if (!snapshot.exists) {
          return <String, dynamic>{};
        }
        return snapshot.data() as Map<String, dynamic>;
      }).switchToUiThread();
    } catch (e) {
      debugPrint('Failed to get chat details stream: $e');
      return Stream.value(<String, dynamic>{});
    }
  }

  // Add a stream for all user chats
  Stream<List<String>> getChatsStreamForUser(String userId) {
    try {
      return _usersCollection
          .doc(userId)
          .collection('user-chats')
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) => doc.id).toList();
          })
          .switchToUiThread();
    } catch (e) {
      throw Exception('Failed to get chats stream: $e');
    }
  }

  // Add method to update typing status
  @override
  Future<void> updateTypingStatus(
      String chatId, String userId, bool isTyping) async {
    try {
      final typingRef = _firestore.collection('typing').doc(chatId);
      final typingDoc = await typingRef.get();

      if (typingDoc.exists) {
        final typingData = typingDoc.data() as Map<String, dynamic>;
        final typingUsers =
            Map<String, dynamic>.from(typingData['users'] ?? {});

        if (isTyping) {
          typingUsers[userId] = DateTime.now().toIso8601String();
        } else {
          typingUsers.remove(userId);
        }

        await typingRef.update({'users': typingUsers});
      } else if (isTyping) {
        // Create the typing document if it doesn't exist and user is typing
        await typingRef.set({
          'users': {userId: DateTime.now().toIso8601String()},
        });
      }
    } catch (e) {
      throw Exception('Failed to update typing status: $e');
    }
  }

  // Mark a message as delivered
  Future<void> markMessageAsDelivered(String messageId) async {
    try {
      await _messagesCollection(messageId.split('/')[0]).doc(messageId).update({
        'deliveryStatus': 'delivered',
      });
    } catch (e) {
      throw Exception('Failed to mark message as delivered: $e');
    }
  }

  // Mark all messages in a chat as read for a user
  Future<void> markAllMessagesAsRead(String chatId, String userId) async {
    try {
      // Get all unread messages for this user in this chat
      final querySnapshot = await _messagesCollection(chatId)
          .where('seenBy', arrayContains: userId)
          .get();

      // Create a batch to update all messages at once
      final batch = _firestore.batch();

      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'seenBy': FieldValue.arrayUnion([userId]),
          'deliveryStatus': 'read',
        });
      }

      // Execute the batch
      await batch.commit();

      // Reset unread count for this user in the chat
      await _chatsCollection.doc(chatId).update({
        'unreadCount.$userId': 0,
      });
    } catch (e) {
      throw Exception('Failed to mark all messages as read: $e');
    }
  }

  @override
  Future<void> markChatAsRead(String chatId, String userId) async {
    try {
      final chatDoc = await _chatsCollection.doc(chatId).get();
      if (!chatDoc.exists) {
        throw Exception('Chat not found');
      }

      final chatData = chatDoc.data() as Map<String, dynamic>;
      final unreadCount =
          Map<String, dynamic>.from(chatData['unreadCount'] ?? {});

      // Set the unread count to 0 for this user
      unreadCount[userId] = 0;

      await _chatsCollection.doc(chatId).update({'unreadCount': unreadCount});
    } catch (e) {
      throw Exception('Failed to mark chat as read: $e');
    }
  }

  @override
  Stream<List<Chat>> getUserChatsStream(String userId) {
    try {
      // Get a reference to the user-chats subcollection
      final userChatsRef = _usersCollection
          .doc(userId)
          .collection('user-chats')
          .orderBy('lastMessageTime', descending: true);

      // Map the query snapshot to a list of Chat objects
      return userChatsRef.snapshots().asyncMap((snapshot) async {
        final List<Chat> chats = [];

        for (final doc in snapshot.docs) {
          final chatId = doc.id;
          try {
            final chatDoc = await _chatsCollection.doc(chatId).get();
            if (chatDoc.exists) {
              final chatData = chatDoc.data() as Map<String, dynamic>;
              chats.add(Chat.fromMap(chatData));
            }
          } catch (e) {
            debugPrint('Error fetching chat $chatId: $e');
          }
        }

        return chats;
      }).switchToUiThread();
    } catch (e) {
      // Handle the error
      debugPrint('Error getting user chats stream: $e');
      return Stream.value([]);
    }
  }

  @override
  Stream<List<Message>> getChatMessagesStream(String chatId) {
    try {
      return _messagesCollection(chatId)
          .orderBy('timestamp', descending: true)
          .limit(20) // Limit to 20 messages per fetch
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return Message.fromMap(data);
              })
              .toList());
    } catch (e) {
      throw Exception('Failed to get chat messages: $e');
    }
  }

  @override
  Stream<Map<String, DateTime>> getTypingStatusStream(String chatId) {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint(
            'User not authenticated, cannot access typing status stream');
        return Stream.value({});
      }

      // First check if the user is a participant in this chat
      return _chatsCollection.doc(chatId).get().asStream().handleError((error) {
        debugPrint('Error accessing chat for typing status: $error');
        return null;
      }).asyncMap((chatDoc) async {
        if (!chatDoc.exists) {
          debugPrint('Chat does not exist: $chatId');
          return <String, DateTime>{};
        }

        final chatData = chatDoc.data() as Map<String, dynamic>;
        final List<String> participantIds =
            List<String>.from(chatData['participantIds'] ?? []);

        if (!participantIds.contains(currentUser.uid)) {
          debugPrint('Current user is not a participant in chat: $chatId');
          return <String, DateTime>{};
        }

        // Now we've confirmed the user is a participant, get typing status
        final stream = _firestore
            .collection('typing')
            .doc(chatId)
            .snapshots()
            .handleError((error) {
          debugPrint('Error in typing status stream: $error');
          return null;
        }).map((snapshot) {
          if (!snapshot.exists) {
            return <String, DateTime>{};
          }

          final data = snapshot.data() as Map<String, dynamic>;
          final Map<String, DateTime> typingUsers = {};

          data.forEach((userId, timestamp) {
            if (userId != currentUser.uid) {
              // Convert Firestore timestamp to DateTime
              if (timestamp is Timestamp) {
                final dateTime = timestamp.toDate();
                // Only consider users typing in the last 10 seconds
                if (DateTime.now().difference(dateTime).inSeconds < 10) {
                  typingUsers[userId] = dateTime;
                }
              }
            }
          });

          return typingUsers;
        });
        
        return await stream.first;
      }).switchToUiThread();
    } catch (e) {
      debugPrint('Error in typing status stream: $e');
      return Stream.value({});
    }
  }

  @override
  Future<void> markMessageAsSeen(
      String chatId, String messageId, String userId) async {
    try {
      final messageDoc = await _messagesCollection(chatId).doc(messageId).get();
      if (!messageDoc.exists) {
        throw Exception('Message not found');
      }

      final messageData = messageDoc.data() as Map<String, dynamic>;
      final seenBy = List<String>.from(messageData['seenBy'] ?? []);

      if (!seenBy.contains(userId)) {
        seenBy.add(userId);
        await _messagesCollection(chatId).doc(messageId).update({
          'seenBy': seenBy,
          'isRead': true,
        });
      }
    } catch (e) {
      throw Exception('Failed to mark message as seen: $e');
    }
  }

  @override
  Future<String> createEventChat(String eventId, String eventName,
      {String? imageUrl}) async {
    try {
      // Create new event chat
      final chatRef = _chatsCollection.doc();
      final timestamp = DateTime.now().toIso8601String();

      // Get event attendees
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) {
        throw Exception('Event not found');
      }

      final eventData = eventDoc.data() as Map<String, dynamic>;
      final attendeeIds = List<String>.from(eventData['attendeeIds'] ?? []);

      if (attendeeIds.isEmpty) {
        throw Exception('Event has no attendees');
      }

      // Prepare unread count map
      final unreadCount = <String, int>{};
      for (final userId in attendeeIds) {
        unreadCount[userId] = 0;
      }

      // Set chat data
      await chatRef.set({
        'title': eventName,
        'imageUrl': imageUrl,
        'type': ChatType.event.index,
        'participantIds': attendeeIds,
        'createdAt': timestamp,
        'lastMessageAt': null,
        'lastMessageText': null,
        'lastMessageSenderId': null,
        'unreadCount': unreadCount,
        'eventId': eventId,
      });

      // Create a system message indicating event chat creation
      final messageRef = _messagesCollection(chatRef.id).doc();

      await messageRef.set({
        'id': messageRef.id,
        'chatId': chatRef.id,
        'senderId': 'system',
        'senderName': 'System',
        'content': 'Event chat created',
        'timestamp': timestamp,
        'type': MessageType.system.index,
        'isRead': true,
        'seenBy': attendeeIds,
      });

      return chatRef.id;
    } catch (e) {
      throw Exception('Failed to create event chat: $e');
    }
  }

  @override
  Future<void> addUserToChat(String chatId, String userId) async {
    try {
      final chatDoc = await _chatsCollection.doc(chatId).get();
      if (!chatDoc.exists) {
        throw Exception('Chat not found');
      }

      final chatData = chatDoc.data() as Map<String, dynamic>;
      final participantIds =
          List<String>.from(chatData['participantIds'] ?? []);

      // Check if user is already in the chat
      if (participantIds.contains(userId)) {
        return; // User already in chat, no need to add
      }

      // Add user to participants
      participantIds.add(userId);

      // Update unread counts
      final unreadCount = Map<String, int>.from(chatData['unreadCount'] ?? {});
      unreadCount[userId] = 0;

      // Update chat document
      await _chatsCollection.doc(chatId).update({
        'participantIds': participantIds,
        'unreadCount': unreadCount,
      });

      // Add system message about the new user
      final userDoc = await _usersCollection.doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      final userName = userData?['displayName'] ?? 'A new user';

      final messageRef = _messagesCollection(chatId).doc();
      await messageRef.set({
        'id': messageRef.id,
        'chatId': chatId,
        'senderId': 'system',
        'senderName': 'System',
        'content': '$userName joined the chat',
        'timestamp': DateTime.now().toIso8601String(),
        'type': MessageType.system.index,
        'isRead': true,
        'seenBy': participantIds,
      });
    } catch (e) {
      throw Exception('Failed to add user to chat: $e');
    }
  }

  @override
  Future<void> deleteChat(String chatId) async {
    try {
      final chatDoc = await _chatsCollection.doc(chatId).get();
      if (!chatDoc.exists) {
        throw Exception('Chat not found');
      }

      // Get all messages
      final messagesSnapshot = await _messagesCollection(chatId).get();

      // Delete all messages
      final batch = _firestore.batch();
      for (final doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete the chat document
      batch.delete(_chatsCollection.doc(chatId));

      // Commit the batch
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete chat: $e');
    }
  }

  @override
  Future<List<ChatUser>> getChatParticipants(String chatId) async {
    try {
      final chatDoc = await _chatsCollection.doc(chatId).get();
      if (!chatDoc.exists) {
        throw Exception('Chat not found');
      }

      final chatData = chatDoc.data() as Map<String, dynamic>;
      final participantIds =
          List<String>.from(chatData['participantIds'] ?? []);

      if (participantIds.isEmpty) {
        return [];
      }

      // Get user data in batches to avoid large queries
      final participants = <ChatUser>[];
      const batchSize = 10;

      for (int i = 0; i < participantIds.length; i += batchSize) {
        final end = (i + batchSize < participantIds.length)
            ? i + batchSize
            : participantIds.length;
        final batchIds = participantIds.sublist(i, end);

        final usersQuery = await _usersCollection
            .where(FieldPath.documentId, whereIn: batchIds)
            .get();

        for (final userDoc in usersQuery.docs) {
          final userData = userDoc.data() as Map<String, dynamic>;
          participants.add(ChatUser(
            id: userDoc.id,
            name: userData['displayName'] ?? 'Unknown User',
            avatarUrl: userData['photoURL'] as String?,
            isOnline: userData['isOnline'] as bool? ?? false,
            lastActive: userData['lastActive'] != null
                ? (userData['lastActive'] is Timestamp)
                    ? (userData['lastActive'] as Timestamp).toDate()
                    : DateTime.parse(userData['lastActive'] as String)
                : DateTime.now(), // Add default value instead of null
            role: userData['role'] as String? ?? 'user',
            major: userData['major'] as String?,
            year: userData['year'] as String?,
            clubIds: userData['clubIds'] != null
                ? List<String>.from(userData['clubIds'] as List)
                : null,
            isVerified: userData['isVerified'] as bool? ?? false,
          ));
        }
      }

      return participants;
    } catch (e) {
      throw Exception('Failed to get chat participants: $e');
    }
  }

  // Helper to convert eventData with either fromMap or fromJson
  MessageEventData? _parseEventData(Map<String, dynamic>? data) {
    if (data == null) return null;
    try {
      return MessageEventData.fromMap(data);
    } catch (e) {
      debugPrint('Error parsing event data: $e');
      return null;
    }
  }

  MessageType _safeMessageType(MessageType? type) {
    return type ?? MessageType.text;
  }

  // Stubbed methods that need to be implemented in the future

  @override
  Future<List<ChatUser>> getSuggestedContacts(String userId,
      {int limit = 10}) async {
    // TODO: Implement getSuggestedContacts
    return [];
  }

  @override
  Future<int> getThreadReplyCount(String parentMessageId) async {
    // TODO: Implement getThreadReplyCount
    return 0;
  }

  @override
  Stream<Map<String, bool>> getUserOnlineStatusStream(String chatId) {
    try {
      // Get the online status for participants in this chat
      return _chatsCollection
          .doc(chatId)
          .snapshots()
          .handleError((error) {
            debugPrint('Error in user online status stream: $error');
            return null;
          })
          .asyncMap((chatDoc) async {
            if (!chatDoc.exists) {
              return <String, bool>{};
            }

            final chatData = chatDoc.data() as Map<String, dynamic>;
            final List<String> participantIds =
                List<String>.from(chatData['participantIds'] ?? []);

            // Get online status for each participant
            final Map<String, bool> onlineStatus = {};
            for (final userId in participantIds) {
              try {
                final userDoc = await _usersCollection.doc(userId).get();
                if (userDoc.exists) {
                  final userData = userDoc.data() as Map<String, dynamic>;
                  // Check online status and last seen
                  final bool isOnline = userData['isOnline'] ?? false;
                  onlineStatus[userId] = isOnline;
                }
              } catch (e) {
                debugPrint('Error getting user status for $userId: $e');
              }
            }

            return onlineStatus;
          })
          .switchToUiThread();
    } catch (e) {
      debugPrint('Failed to get user online status stream: $e');
      return Stream.value({});
    }
  }

  @override
  Future<ChatUser> getUserProfile(String userId) async {
    try {
      final userDoc = await _usersCollection.doc(userId).get();
      
      if (!userDoc.exists) {
        throw Exception('User not found');
      }
      
      final userData = userDoc.data() as Map<String, dynamic>;
      
      // Convert timestamps or handle null last active
      DateTime lastActive;
      if (userData['lastActive'] != null) {
        if (userData['lastActive'] is Timestamp) {
          lastActive = (userData['lastActive'] as Timestamp).toDate();
        } else {
          lastActive = DateTime.parse(userData['lastActive'] as String);
        }
      } else {
        lastActive = DateTime.now(); // Default value if null
      }
      
      return ChatUser(
        id: userId,
        name: userData['displayName'] ?? 'Unknown User',
        email: userData['email'] ?? '',
        photoUrl: userData['photoURL'],
        avatarUrl: userData['photoURL'],
        bio: userData['bio'] ?? '',
        isOnline: false,
        lastActive: lastActive, // Now using the non-nullable variable
        role: userData['role'],
        major: userData['major'],
        year: userData['year'],
        clubIds: userData['clubIds'] != null 
          ? List<String>.from(userData['clubIds'])
          : null,
        isVerified: userData['isVerified'] ?? false,
      );
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  @override
  Future<void> updateUserOnlineStatus(String userId, bool isOnline) async {
    // TODO: Implement updateUserOnlineStatus
  }

  @override
  Future<List<ChatUser>> searchUsers(String query, {int limit = 20}) async {
    // TODO: Implement searchUsers
    return [];
  }

  @override
  Future<List<Chat>> searchChats(String query, {int limit = 20}) async {
    // TODO: Implement searchChats
    return [];
  }

  @override
  Future<void> removeUserFromChat(String chatId, String userId) async {
    // TODO: Implement removeUserFromChat
  }

  @override
  Future<void> updateChatDetails(String chatId,
      {String? title, String? imageUrl}) async {
    try {
      final updates = <String, dynamic>{};
      
      if (title != null) {
        updates['title'] = title;
      }
      
      if (imageUrl != null) {
        updates['imageUrl'] = imageUrl;
      }
      
      if (updates.isNotEmpty) {
        await _chatsCollection.doc(chatId).update(updates);
      }
    } catch (e) {
      throw Exception('Failed to update chat details: $e');
    }
  }

  @override
  Future<Message> sendEventMessage(
    String chatId,
    String senderId,
    MessageEventData eventData, {
    String? replyToMessageId,
    String? threadParentId,
  }) async {
    // TODO: Implement sendEventMessage
    return Message(
      id: 'temp',
      chatId: chatId,
      senderId: senderId,
      senderName: 'User',
      content: 'Event message',
      timestamp: DateTime.now(),
      isRead: false,
      type: MessageType.event,
      eventData: eventData,
    );
  }

  @override
  Future<Message> sendImageMessage(
    String chatId,
    String senderId,
    File imageFile, {
    String? caption,
    String? replyToMessageId,
    String? threadParentId,
  }) async {
    try {
      // Upload image to storage
      final fileExtension = path.extension(imageFile.path);
      final fileName = '${_uuid.v4()}$fileExtension';
      final storageRef = _storage.ref().child('chats/$chatId/images/$fileName');
      
      // Upload the file
      final uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg', // Or derive from file extension
        ),
      );
      
      // Wait for upload to complete
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Get sender information
      final userDoc = await _usersCollection.doc(senderId).get();
      final userData = userDoc.data() as Map<String, dynamic>;
      
      // Create message
      final messageRef = _messagesCollection(chatId).doc();
      final timestamp = DateTime.now().toIso8601String();
      
      final message = Message(
        id: messageRef.id,
      chatId: chatId,
      senderId: senderId,
        senderName: userData['displayName'] ?? 'Unknown',
        senderAvatar: userData['photoURL'],
        content: caption ?? 'Photo',
      timestamp: DateTime.now(),
      isRead: false,
      type: MessageType.image,
        attachmentUrl: downloadUrl,
        attachmentType: 'image',
        replyToMessageId: replyToMessageId,
        threadParentId: threadParentId,
        seenBy: [senderId],
      );
      
      // Save to Firestore
      await messageRef.set(message.toMap());
      
      // Update chat's last message
      await _chatsCollection.doc(chatId).update({
        'lastMessageAt': timestamp,
        'lastMessageText': caption ?? 'Photo',
        'lastMessageSenderId': senderId,
      });
      
      return message;
    } catch (e) {
      throw Exception('Failed to send image message: $e');
    }
  }

  @override
  Future<Message> sendMessageWithAttachment(
    String chatId,
    String senderId,
    String attachmentUrl,
    String fileName,
    MessageType messageType, {
    String? replyToMessageId,
    String? threadParentId,
  }) async {
    try {
      // Get sender information
      final userDoc = await _usersCollection.doc(senderId).get();
      final userData = userDoc.data() as Map<String, dynamic>;
      
      // Create message
      final messageRef = _messagesCollection(chatId).doc();
      final timestamp = DateTime.now().toIso8601String();
      
      String messageContent;
      String attachmentType;
      
      switch (messageType) {
        case MessageType.image:
          messageContent = 'Photo';
          attachmentType = 'image';
          break;
        case MessageType.video:
          messageContent = 'Video';
          attachmentType = 'video';
          break;
        case MessageType.audio:
          messageContent = 'Audio';
          attachmentType = 'audio';
          break;
        case MessageType.file:
          messageContent = fileName;
          attachmentType = 'file';
          break;
        default:
          messageContent = fileName;
          attachmentType = 'file';
      }
      
      final message = Message(
        id: messageRef.id,
        chatId: chatId,
        senderId: senderId,
        senderName: userData['displayName'] ?? 'Unknown',
        senderAvatar: userData['photoURL'],
        content: messageContent,
        timestamp: DateTime.now(),
        isRead: false,
        type: messageType,
        attachmentUrl: attachmentUrl,
        attachmentType: attachmentType,
        replyToMessageId: replyToMessageId,
        threadParentId: threadParentId,
        seenBy: [senderId],
      );
      
      // Save to Firestore
      await messageRef.set(message.toMap());
      
      // Update chat's last message
      await _chatsCollection.doc(chatId).update({
        'lastMessageAt': timestamp,
        'lastMessageText': messageContent,
        'lastMessageSenderId': senderId,
      });
      
      return message;
    } catch (e) {
      throw Exception('Failed to send message with attachment: $e');
    }
  }

  @override
  Future<List<Message>> getMessagesPaginated(String chatId, DateTime? lastMessageTimestamp, int limit) async {
    try {
      Query query = _messagesCollection(chatId)
          .orderBy('timestamp', descending: true);
      
      // If we have a timestamp for pagination
      if (lastMessageTimestamp != null) {
        query = query.startAfter([Timestamp.fromDate(lastMessageTimestamp)]);
      }
      
      // Apply the limit (defaulting to 20 if not specified)
      query = query.limit(limit > 0 ? limit : 20);
      
      final snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Message.fromMap(data);
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to get paginated messages: $e');
    }
  }

  @override
  Future<void> updateMessageDeliveryStatus(String messageId, String chatId, bool isDelivered, {bool isRead = false}) async {
    try {
      final messageDoc = _messagesCollection(chatId).doc(messageId);
      
      final Map<String, dynamic> updateData = {
        'isDelivered': isDelivered,
      };
      
      if (isRead) {
        updateData['isRead'] = true;
        
        // Get current user ID
        final currentUserId = _auth.currentUser?.uid;
        if (currentUserId != null) {
          // Add user to seenBy array if not already present
          updateData['seenBy'] = FieldValue.arrayUnion([currentUserId]);
          
          // Update unread count for current user
          await _chatsCollection.doc(chatId).update({
            'unreadCount.$currentUserId': 0
          });
        }
      }
      
      await messageDoc.update(updateData);
    } catch (e) {
      throw Exception('Failed to update message delivery status: $e');
    }
  }

  @override
  Future<String> uploadAttachment(File file, String chatId, String senderId) async {
    try {
      final fileExtension = path.extension(file.path);
      final fileName = '${_uuid.v4()}$fileExtension';
      final storageRef = _storage.ref().child('chats/$chatId/$fileName');
      
      // Upload the file
      final uploadTask = storageRef.putFile(
        file,
        SettableMetadata(
          contentType: _getContentType(fileExtension),
        ),
      );
      
      // Wait for upload to complete
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload attachment: $e');
    }
  }
  
  // Helper to determine content type from file extension
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.mp4':
        return 'video/mp4';
      case '.mp3':
        return 'audio/mpeg';
      case '.pdf':
        return 'application/pdf';
      case '.doc':
      case '.docx':
        return 'application/msword';
      default:
        return 'application/octet-stream';
    }
  }

  @override
  Future<Message> sendTextMessage(
    String chatId,
    String senderId,
    String content, {
    String? replyToMessageId,
    String? threadParentId,
  }) async {
    try {
      // Get sender information
      final userDoc = await _usersCollection.doc(senderId).get();
      final userData = userDoc.data() as Map<String, dynamic>;
      
      // Create message
      final messageRef = _messagesCollection(chatId).doc();
      final timestamp = DateTime.now().toIso8601String();
      
      final message = Message(
        id: messageRef.id,
      chatId: chatId,
      senderId: senderId,
        senderName: userData['displayName'] ?? 'Unknown',
        senderAvatar: userData['photoURL'],
      content: content,
      timestamp: DateTime.now(),
      isRead: false,
      type: MessageType.text,
        replyToMessageId: replyToMessageId,
        threadParentId: threadParentId,
        seenBy: [senderId],
      );
      
      // Save to Firestore
      await messageRef.set(message.toMap());
      
      // Update the unread count for all participants except the sender
      final chatDoc = await _chatsCollection.doc(chatId).get();
      final chatData = chatDoc.data() as Map<String, dynamic>;
      final participantIds = List<String>.from(chatData['participantIds'] ?? []);
      
      final updateData = <String, dynamic>{
        'lastMessageAt': timestamp,
        'lastMessageText': content,
        'lastMessageSenderId': senderId,
      };
      
      // Increment unread count for each participant except sender
      for (final participantId in participantIds) {
        if (participantId != senderId) {
          updateData['unreadCount.$participantId'] = FieldValue.increment(1);
        }
      }
      
      // Update chat document
      await _chatsCollection.doc(chatId).update(updateData);
      
      return message;
    } catch (e) {
      throw Exception('Failed to send text message: $e');
    }
  }

  @override
  Future<Message?> getMessageById(String chatId, String messageId) async {
    try {
      final docSnapshot = await _messagesCollection(chatId).doc(messageId).get();
      
      if (!docSnapshot.exists) {
        return null;
      }
      
      final data = docSnapshot.data() as Map<String, dynamic>;
      data['id'] = docSnapshot.id; // Add ID to the map
      
      return Message.fromMap(data);
    } catch (e) {
      throw Exception('Failed to get message by ID: $e');
    }
  }

  @override
  Stream<List<Message>> getThreadMessagesStream(String chatId, String threadParentId) {
    try {
      return _messagesCollection(chatId)
          .where('threadParentId', isEqualTo: threadParentId)
          .orderBy('timestamp')
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id; // Add ID to the map
              return Message.fromMap(data);
            }).toList();
          });
    } catch (e) {
      throw Exception('Failed to get thread messages stream: $e');
    }
  }

  @override
  Stream<int> getUnreadMessageCountStream(String chatId, String userId) {
    try {
      return _chatsCollection
          .doc(chatId)
          .snapshots()
          .map((snapshot) {
            if (!snapshot.exists) {
              return 0;
            }
            
            final data = snapshot.data() as Map<String, dynamic>;
            final unreadCounts = data['unreadCount'] as Map<String, dynamic>?;
            
            if (unreadCounts == null || !unreadCounts.containsKey(userId)) {
              return 0;
            }
            
            return unreadCounts[userId] as int;
          });
    } catch (e) {
      throw Exception('Failed to get unread message count stream: $e');
    }
  }

  @override
  Future<List<Message>> getChatMessagesBefore(
      String chatId, DateTime timestamp, {int limit = 20}) async {
    try {
      final querySnapshot = await _messagesCollection(chatId)
          .where('timestamp', isLessThan: timestamp)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Add ID to the map
        return Message.fromMap(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get chat messages before timestamp: $e');
    }
  }

  @override
  Future<void> createMessageSearchIndex(String chatId) async {
    try {
      // For Firebase, we can use Cloud Firestore's built-in search capabilities
      // through queries. However, for more complex search, Algolia or ElasticSearch
      // would be preferred. This implementation is a placeholder.
      
      // Create a separate collection for search indices
      await _firestore.collection('messageSearchIndices').doc(chatId).set({
        'chatId': chatId,
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });
      
      // Get recent messages to index
      final messages = await getChatMessages(chatId, limit: 100);
      
      // Update the search index with these messages
      await updateMessageSearchIndex(chatId, messages);
    } catch (e) {
      throw Exception('Failed to create message search index: $e');
    }
  }

  @override
  Future<void> updateMessageSearchIndex(String chatId, List<Message> messages) async {
    try {
      final batch = _firestore.batch();
      final indexCollection = _firestore.collection('messageSearchIndices')
          .doc(chatId)
          .collection('indexedMessages');
      
      // Update index metadata
      batch.update(
        _firestore.collection('messageSearchIndices').doc(chatId),
        {'lastUpdatedAt': FieldValue.serverTimestamp()},
      );
      
      // Index each message
      for (final message in messages) {
        // Skip certain message types that don't need indexing
        if (message.type == MessageType.system || 
            message.content.isEmpty) {
          continue;
        }
        
        // Create search tokens from the message content
        final searchTokens = _generateSearchTokens(message.content);
        
        // Create a searchable representation of the message
        final searchData = {
          'messageId': message.id,
          'content': message.content,
          'senderId': message.senderId,
          'senderName': message.senderName,
          'timestamp': message.timestamp.toIso8601String(),
          'type': message.type.toString().split('.').last,
          'searchTokens': searchTokens,
        };
        
        // Add to batch
        batch.set(indexCollection.doc(message.id), searchData);
      }
      
      // Commit the batch
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to update message search index: $e');
    }
  }
  
  // Helper method to generate search tokens for message content
  List<String> _generateSearchTokens(String content) {
    // Normalize content: lowercase and remove special characters
    final normalizedContent = content.toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .trim();
    
    // Split into words
    final words = normalizedContent.split(RegExp(r'\s+'));
    
    // Create tokens (including n-grams for partial matching)
    final Set<String> tokens = {};
    
    // Add full words
    tokens.addAll(words.where((word) => word.isNotEmpty));
    
    // Add n-grams for words longer than 4 characters
    for (final word in words) {
      if (word.length > 4) {
        // Add trigrams
        for (int i = 0; i <= word.length - 3; i++) {
          tokens.add(word.substring(i, i + 3));
        }
      }
    }
    
    return tokens.toList();
  }

  @override
  Future<Message> sendTextMessageReply(
    String chatId,
    String senderId,
    String content,
    String threadParentId,
  ) async {
    try {
      // First check if the parent message exists
      final parentMessage = await getMessageById(chatId, threadParentId);
      if (parentMessage == null) {
        throw Exception('Parent message not found');
      }
      
      // Fetch user profile to get sender name
      final userProfile = await getUserProfile(senderId);
      final senderName = userProfile.displayName;
      
      // Create reply message with current timestamp
      final now = DateTime.now();
      final message = Message.text(
        id: '', // Will be filled after document creation
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        content: content,
        timestamp: now,
        threadParentId: threadParentId,
      );
      
      // Save the message to Firestore
      final docRef = await _messagesCollection(chatId).add(message.toMap());
      
      // Update the message with the ID
      final messageWithId = message.copyWith(id: docRef.id);
      
      // Update thread count on parent message
      await _messagesCollection(chatId).doc(threadParentId).update({
        'threadRepliesCount': FieldValue.increment(1),
      });
      
      return messageWithId;
    } catch (e) {
      throw Exception('Failed to send text message reply: $e');
    }
  }
}
