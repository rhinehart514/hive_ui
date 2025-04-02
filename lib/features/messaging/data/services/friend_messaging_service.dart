import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ui/features/messaging/domain/entities/chat.dart';
import 'package:hive_ui/features/messaging/domain/entities/chat_user.dart';
import 'package:hive_ui/features/messaging/domain/repositories/message_repository.dart';

/// Service to handle friend-to-friend messaging functionality
class FriendMessagingService {
  final FirebaseFirestore _firestore;
  final MessageRepository _messageRepository;

  FriendMessagingService({
    required MessageRepository messageRepository,
    FirebaseFirestore? firestore,
  })  : _messageRepository = messageRepository,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Gets or creates a direct chat between the current user and a friend
  Future<Chat> getOrCreateDirectChat(String currentUserId, String friendId) async {
    // Check if these users are friends
    final areFriends = await _checkIfFriends(currentUserId, friendId);
    
    if (!areFriends) {
      throw Exception('Users are not friends');
    }
    
    // Get existing chat or create new one
    final chatId = await _messageRepository.createDirectChat(currentUserId, friendId);
    return await _messageRepository.getChatDetails(chatId);
  }

  /// Gets all friends for a user
  Future<List<ChatUser>> getUserFriends(String userId) async {
    final friendsCollection = _firestore.collection('users').doc(userId).collection('friends');
    final friendsSnapshot = await friendsCollection.get();
    
    final friends = <ChatUser>[];
    
    for (final doc in friendsSnapshot.docs) {
      final friendId = doc.id;
      final userDoc = await _firestore.collection('users').doc(friendId).get();
      
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        
        final lastActive = userData['lastLogin'] != null
            ? (userData['lastLogin'] as Timestamp).toDate()
            : DateTime.now();
        
        friends.add(ChatUser(
          id: friendId,
          name: userData['displayName'] ?? 'User',
          avatarUrl: userData['profileImageUrl'],
          isOnline: userData['isOnline'] ?? false,
          lastActive: lastActive,
          major: userData['major'],
          year: userData['year'],
          isVerified: userData['isVerified'] ?? false,
        ));
      }
    }
    
    return friends;
  }

  /// Gets all recent chats with friends
  Future<List<Chat>> getRecentFriendChats(String userId) async {
    // Get all chats where the user is a participant
    final chatsStream = _messageRepository.getUserChatsStream(userId);
    
    // Wait for the first emission from the stream
    final allChats = await chatsStream.first;
    
    // Filter to only direct chats
    final directChats = allChats.where((chat) => chat.isDirectMessage).toList();
    
    // Sort by last message time
    directChats.sort((a, b) {
      if (a.lastMessageAt == null) return 1;
      if (b.lastMessageAt == null) return -1;
      return b.lastMessageAt!.compareTo(a.lastMessageAt!);
    });
    
    return directChats;
  }

  /// Checks if two users are friends
  Future<bool> _checkIfFriends(String userId1, String userId2) async {
    // Check if user1 has user2 as friend
    final friendDoc = await _firestore
        .collection('users')
        .doc(userId1)
        .collection('friends')
        .doc(userId2)
        .get();
    
    return friendDoc.exists;
  }
  
  /// Gets chat suggestions based on user's friends
  Future<List<ChatUser>> getFriendChatSuggestions(String userId) async {
    // Get friends who you haven't chatted with recently
    final friends = await getUserFriends(userId);
    
    if (friends.isEmpty) {
      return [];
    }
    
    // Get recent chats
    final recentChats = await getRecentFriendChats(userId);
    
    // Get IDs of friends we've chatted with recently
    final recentChatFriendIds = <String>{};
    
    for (final chat in recentChats) {
      if (chat.isDirectMessage) {
        for (final participantId in chat.participantIds) {
          if (participantId != userId) {
            recentChatFriendIds.add(participantId);
          }
        }
      }
    }
    
    // Filter to friends we haven't chatted with recently
    final suggestions = friends
        .where((friend) => !recentChatFriendIds.contains(friend.id))
        .toList();
    
    // Sort by online status, then by name
    suggestions.sort((a, b) {
      if (a.isOnline && !b.isOnline) return -1;
      if (!a.isOnline && b.isOnline) return 1;
      return a.name.compareTo(b.name);
    });
    
    return suggestions;
  }
} 