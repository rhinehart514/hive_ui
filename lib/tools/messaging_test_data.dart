import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:hive_ui/utils/realtime_db_windows_fix.dart';

/// Tool for generating test data for the messaging feature
class MessagingTestData {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseDatabase _database = FirebaseDatabase.instance;
  static final Uuid _uuid = const Uuid();
  
  /// Initialize the testing tool
  static Future<void> initialize() async {
    // Initialize the Windows fix for Realtime Database
    RealtimeDbWindowsFix.initialize();
    
    // Ensure we're logged in
    if (_auth.currentUser == null) {
      debugPrint('❌ ERROR: User not logged in. Please log in first.');
      return;
    }
    
    debugPrint('✅ Initialized messaging test data tool.');
    debugPrint('Current user: ${_auth.currentUser!.uid}');
  }
  
  /// Generate sample chat data with mock users and messages
  static Future<void> generateSampleData() async {
    try {
      if (_auth.currentUser == null) {
        debugPrint('❌ ERROR: User not logged in. Please log in first.');
        return;
      }
      
      final currentUserId = _auth.currentUser!.uid;
      debugPrint('🔄 Generating sample chat data for user: $currentUserId');
      
      // Create mock users (or use existing users)
      final mockUsers = await _createOrGetMockUsers();
      
      // Create direct chats with each mock user
      await _createDirectChats(currentUserId, mockUsers);
      
      // Create a group chat
      await _createGroupChat(currentUserId, mockUsers);
      
      // Set online status for mock users
      await _setMockOnlineStatus(mockUsers);
      
      debugPrint('✅ Sample chat data generated successfully!');
      debugPrint('📱 Navigate to the Messages tab to see the test chats');
    } catch (e) {
      debugPrint('❌ ERROR: Failed to generate sample data: $e');
    }
  }
  
  /// Create or get mock users to chat with
  static Future<List<Map<String, dynamic>>> _createOrGetMockUsers() async {
    debugPrint('👤 Creating mock users...');
    
    final mockUsers = <Map<String, dynamic>>[
      {
        'id': 'mock_user_1',
        'name': 'Alex Smith',
        'avatar': 'https://randomuser.me/api/portraits/men/1.jpg',
        'isOnline': true,
      },
      {
        'id': 'mock_user_2',
        'name': 'Jessica Wong',
        'avatar': 'https://randomuser.me/api/portraits/women/2.jpg',
        'isOnline': false,
      },
      {
        'id': 'mock_user_3',
        'name': 'Taylor Johnson',
        'avatar': 'https://randomuser.me/api/portraits/men/3.jpg',
        'isOnline': true,
      },
      {
        'id': 'mock_user_4',
        'name': 'Olivia Chen',
        'avatar': 'https://randomuser.me/api/portraits/women/4.jpg',
        'isOnline': false,
      },
    ];
    
    // Check if users already exist in Firestore
    for (final user in mockUsers) {
      final userDoc = await _firestore.collection('users').doc(user['id']).get();
      
      if (!userDoc.exists) {
        // Create user in Firestore
        await _firestore.collection('users').doc(user['id']).set({
          'displayName': user['name'],
          'profileImageUrl': user['avatar'],
          'isOnline': user['isOnline'],
          'lastLogin': FieldValue.serverTimestamp(),
          'major': 'Computer Science',
          'year': 'Senior',
          'isVerified': true,
          'bio': 'This is a mock user for testing the messaging feature.',
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        debugPrint('👤 Created mock user: ${user['name']}');
      } else {
        debugPrint('👤 Mock user already exists: ${user['name']}');
      }
    }
    
    return mockUsers;
  }
  
  /// Create direct chats between the current user and mock users
  static Future<void> _createDirectChats(String currentUserId, List<Map<String, dynamic>> mockUsers) async {
    debugPrint('💬 Creating direct chats...');
    
    for (final mockUser in mockUsers) {
      final mockUserId = mockUser['id'];
      final chatId = _getChatId(currentUserId, mockUserId);
      
      // Check if chat already exists
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      
      if (!chatDoc.exists) {
        // Create chat document
        await _firestore.collection('chats').doc(chatId).set({
          'title': mockUser['name'],
          'imageUrl': mockUser['avatar'],
          'type': 0, // 0 = direct, 1 = group
          'participantIds': [currentUserId, mockUserId],
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessageAt': FieldValue.serverTimestamp(),
          'lastMessageText': 'This is a sample conversation. Hello!',
          'lastMessageSenderId': mockUserId,
          'unreadCount': {currentUserId: 1},
        });
        
        // Create sample messages
        await _createSampleMessages(chatId, currentUserId, mockUserId);
        
        // Add chat reference to user documents
        await _firestore.collection('users').doc(currentUserId).collection('user-chats').doc(chatId).set({
          'lastAccess': FieldValue.serverTimestamp(),
        });
        
        await _firestore.collection('users').doc(mockUserId).collection('user-chats').doc(chatId).set({
          'lastAccess': FieldValue.serverTimestamp(),
        });
        
        debugPrint('💬 Created direct chat with: ${mockUser['name']}');
      } else {
        debugPrint('💬 Direct chat already exists with: ${mockUser['name']}');
      }
    }
  }
  
  /// Create a group chat with the current user and mock users
  static Future<void> _createGroupChat(String currentUserId, List<Map<String, dynamic>> mockUsers) async {
    debugPrint('👥 Creating group chat...');
    
    final chatId = 'group_chat_${_uuid.v4()}';
    
    // Check if group chat already exists (using a basic check)
    final query = await _firestore.collection('chats').where('type', isEqualTo: 1).where('participantIds', arrayContains: currentUserId).limit(1).get();
    
    if (query.docs.isEmpty) {
      // Create participant list
      final participantIds = <String>[currentUserId];
      final participantNames = <String>[];
      
      for (final user in mockUsers) {
        participantIds.add(user['id']);
        participantNames.add(user['name']);
      }
      
      // Create chat document
      await _firestore.collection('chats').doc(chatId).set({
        'title': 'HIVE Test Group',
        'imageUrl': null,
        'type': 1, // 0 = direct, 1 = group
        'participantIds': participantIds,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageText': 'Welcome to the group chat!',
        'lastMessageSenderId': currentUserId,
        'unreadCount': {},
      });
      
      // Add unread counts for all participants
      final unreadCounts = <String, dynamic>{};
      for (final id in participantIds) {
        if (id != currentUserId) {
          unreadCounts[id] = 1;
        } else {
          unreadCounts[id] = 0;
        }
      }
      
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount': unreadCounts,
      });
      
      // Create sample group messages
      await _createSampleGroupMessages(chatId, currentUserId, mockUsers);
      
      // Add chat reference to all user documents
      for (final userId in participantIds) {
        await _firestore.collection('users').doc(userId).collection('user-chats').doc(chatId).set({
          'lastAccess': FieldValue.serverTimestamp(),
        });
      }
      
      debugPrint('👥 Created group chat with ${mockUsers.length + 1} participants');
    } else {
      debugPrint('👥 Group chat already exists');
    }
  }
  
  /// Create sample messages for a direct chat
  static Future<void> _createSampleMessages(String chatId, String currentUserId, String otherUserId) async {
    final messages = [
      {
        'senderId': otherUserId,
        'content': 'Hey there! How are you doing?',
        'timestamp': DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      },
      {
        'senderId': currentUserId,
        'content': 'I\'m doing great! Just checking out this new messaging feature.',
        'timestamp': DateTime.now().subtract(const Duration(days: 1, hours: 1, minutes: 45)),
      },
      {
        'senderId': otherUserId,
        'content': 'It looks pretty nice! I like the design.',
        'timestamp': DateTime.now().subtract(const Duration(days: 1, hours: 1, minutes: 30)),
      },
      {
        'senderId': currentUserId,
        'content': 'Thanks! It was built with Flutter and Firebase.',
        'timestamp': DateTime.now().subtract(const Duration(days: 1, hours: 1)),
      },
      {
        'senderId': otherUserId,
        'content': 'Do you have plans for the weekend?',
        'timestamp': DateTime.now().subtract(const Duration(hours: 5)),
      },
      {
        'senderId': currentUserId,
        'content': 'Nothing special yet. Maybe catching up on some reading. You?',
        'timestamp': DateTime.now().subtract(const Duration(hours: 4, minutes: 30)),
      },
      {
        'senderId': otherUserId,
        'content': 'Thinking of checking out that new cafe on campus. Heard they have great coffee!',
        'timestamp': DateTime.now().subtract(const Duration(hours: 4)),
      },
      {
        'senderId': otherUserId,
        'content': 'Would you like to join?',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 30)),
      },
    ];
    
    for (final message in messages) {
      final messageId = _uuid.v4();
      
      await _firestore.collection('chats').doc(chatId).collection('messages').doc(messageId).set({
        'id': messageId,
        'chatId': chatId,
        'senderId': message['senderId'],
        'senderName': message['senderId'] == currentUserId ? 'You' : await _getUserName(message['senderId'] as String),
        'senderAvatar': message['senderId'] == currentUserId ? null : await _getUserAvatar(message['senderId'] as String),
        'content': message['content'],
        'timestamp': message['timestamp'],
        'isRead': message['senderId'] != otherUserId, // Messages from other user are unread
        'type': 0, // 0 = text
        'attachmentUrl': null,
        'attachmentType': null,
        'replyToMessageId': null,
        'isPinned': false,
      });
    }
    
    debugPrint('📝 Created ${messages.length} sample messages for chat: $chatId');
  }
  
  /// Create sample messages for a group chat
  static Future<void> _createSampleGroupMessages(String chatId, String currentUserId, List<Map<String, dynamic>> mockUsers) async {
    final messages = [
      {
        'senderId': currentUserId,
        'content': 'Welcome everyone to our group chat!',
        'timestamp': DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      },
      {
        'senderId': mockUsers[0]['id'],
        'content': 'Hey! Thanks for adding me.',
        'timestamp': DateTime.now().subtract(const Duration(days: 1, hours: 2, minutes: 50)),
      },
      {
        'senderId': mockUsers[1]['id'],
        'content': 'This is cool! Hi everyone 👋',
        'timestamp': DateTime.now().subtract(const Duration(days: 1, hours: 2, minutes: 40)),
      },
      {
        'senderId': mockUsers[2]['id'],
        'content': 'Looking forward to chatting with you all!',
        'timestamp': DateTime.now().subtract(const Duration(days: 1, hours: 2, minutes: 30)),
      },
      {
        'senderId': currentUserId,
        'content': 'I thought this would be a good place for us to share campus events.',
        'timestamp': DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      },
      {
        'senderId': mockUsers[0]['id'],
        'content': 'Great idea! I heard there\'s a concert this weekend.',
        'timestamp': DateTime.now().subtract(const Duration(hours: 6)),
      },
      {
        'senderId': mockUsers[3]['id'],
        'content': 'Count me in! Where is it happening?',
        'timestamp': DateTime.now().subtract(const Duration(hours: 5)),
      },
      {
        'senderId': mockUsers[0]['id'],
        'content': 'At the student center, starting at 7pm on Saturday.',
        'timestamp': DateTime.now().subtract(const Duration(hours: 4)),
      },
      {
        'senderId': currentUserId,
        'content': 'Sounds fun! Should we meet up before?',
        'timestamp': DateTime.now().subtract(const Duration(hours: 1)),
      },
    ];
    
    for (final message in messages) {
      final messageId = _uuid.v4();
      final senderId = message['senderId'] as String;
      
      await _firestore.collection('chats').doc(chatId).collection('messages').doc(messageId).set({
        'id': messageId,
        'chatId': chatId,
        'senderId': senderId,
        'senderName': senderId == currentUserId ? 'You' : await _getUserName(senderId),
        'senderAvatar': senderId == currentUserId ? null : await _getUserAvatar(senderId),
        'content': message['content'],
        'timestamp': message['timestamp'],
        'isRead': senderId == currentUserId, // Only my messages are read
        'type': 0, // 0 = text
        'attachmentUrl': null,
        'attachmentType': null,
        'replyToMessageId': null,
        'isPinned': false,
      });
    }
    
    debugPrint('📝 Created ${messages.length} sample messages for group chat: $chatId');
  }
  
  /// Set mock online status for test users
  static Future<void> _setMockOnlineStatus(List<Map<String, dynamic>> mockUsers) async {
    debugPrint('🟢 Setting mock online status...');
    
    for (final user in mockUsers) {
      final userId = user['id'];
      final isOnline = user['isOnline'] as bool;
      
      // Set online status in Realtime Database
      await _database.ref('online/$userId').set({
        'online': isOnline,
        'lastActive': ServerValue.timestamp,
      });
      
      // Show typing indicator for one user
      if (mockUsers.indexOf(user) == 0) {
        // Get first chat with current user
        final currentUserId = _auth.currentUser!.uid;
        final chatId = _getChatId(currentUserId, userId);
        
        await _database.ref('typing/$chatId/$userId').set(ServerValue.timestamp);
        
        debugPrint('⌨️ Set typing indicator for: ${user['name']}');
      }
    }
    
    debugPrint('🟢 Mock online status set for ${mockUsers.length} users');
  }
  
  /// Get the name of a user from their ID
  static Future<String> _getUserName(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (userDoc.exists && userDoc.data() != null) {
        return userDoc.data()!['displayName'] as String? ?? 'Unknown User';
      }
      
      return 'Unknown User';
    } catch (e) {
      return 'Unknown User';
    }
  }
  
  /// Get the avatar URL of a user from their ID
  static Future<String?> _getUserAvatar(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (userDoc.exists && userDoc.data() != null) {
        return userDoc.data()!['profileImageUrl'] as String?;
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
  
  /// Generate a deterministic chat ID for two user IDs
  static String _getChatId(String userId1, String userId2) {
    // Sort user IDs to ensure consistency
    final sortedIds = [userId1, userId2]..sort();
    return 'chat_${sortedIds.join('_')}';
  }
  
  /// Clear all test data (use with caution)
  static Future<void> clearTestData() async {
    debugPrint('⚠️ WARNING: This will delete all test messaging data.');
    debugPrint('⚠️ This action cannot be undone.');
    debugPrint('❓ To proceed, call MessagingTestData.confirmClearTestData()');
  }
  
  /// Confirm clearing all test data
  static Future<void> confirmClearTestData() async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        debugPrint('❌ ERROR: User not logged in. Please log in first.');
        return;
      }
      
      debugPrint('🗑️ Clearing test data...');
      
      // Get mock user IDs
      final mockUserIds = ['mock_user_1', 'mock_user_2', 'mock_user_3', 'mock_user_4'];
      
      // Delete direct chats
      for (final mockUserId in mockUserIds) {
        final chatId = _getChatId(currentUserId, mockUserId);
        
        // Delete messages in the chat
        final messagesQuery = await _firestore.collection('chats').doc(chatId).collection('messages').get();
        for (final doc in messagesQuery.docs) {
          await doc.reference.delete();
        }
        
        // Delete chat document
        await _firestore.collection('chats').doc(chatId).delete();
        
        // Remove chat references from user documents
        await _firestore.collection('users').doc(currentUserId).collection('user-chats').doc(chatId).delete();
        await _firestore.collection('users').doc(mockUserId).collection('user-chats').doc(chatId).delete();
      }
      
      // Find and delete group chats
      final groupChatsQuery = await _firestore.collection('chats')
          .where('type', isEqualTo: 1)
          .where('participantIds', arrayContains: currentUserId)
          .get();
      
      for (final chatDoc in groupChatsQuery.docs) {
        final chatId = chatDoc.id;
        
        // Delete messages in the group chat
        final messagesQuery = await _firestore.collection('chats').doc(chatId).collection('messages').get();
        for (final doc in messagesQuery.docs) {
          await doc.reference.delete();
        }
        
        // Get participant IDs to remove references
        final participantIds = List<String>.from(chatDoc.data()['participantIds'] ?? []);
        
        // Delete chat document
        await chatDoc.reference.delete();
        
        // Remove chat references from all participant documents
        for (final userId in participantIds) {
          await _firestore.collection('users').doc(userId).collection('user-chats').doc(chatId).delete();
        }
      }
      
      // Delete mock users
      for (final userId in mockUserIds) {
        await _firestore.collection('users').doc(userId).delete();
        
        // Clear online status and typing indicators
        await _database.ref('online/$userId').remove();
        
        // Clear typing indicators in any chat
        final typingRef = _database.ref('typing');
        final snapshot = await typingRef.get();
        if (snapshot.exists && snapshot.value is Map) {
          final data = Map<String, dynamic>.from(snapshot.value as Map);
          for (final chatId in data.keys) {
            if (data[chatId] is Map && (data[chatId] as Map).containsKey(userId)) {
              await _database.ref('typing/$chatId/$userId').remove();
            }
          }
        }
      }
      
      debugPrint('✅ Test data cleared successfully!');
    } catch (e) {
      debugPrint('❌ ERROR: Failed to clear test data: $e');
    }
  }
  
  /// Generate advanced sample chat data with configurable options
  static Future<void> generateAdvancedSampleData({
    int userCount = 5,
    int messagesPerConversation = 20,
    bool includeMedia = false,
    bool includeGroupChats = false,
  }) async {
    try {
      if (_auth.currentUser == null) {
        debugPrint('❌ ERROR: User not logged in. Please log in first.');
        return;
      }
      
      final currentUserId = _auth.currentUser!.uid;
      debugPrint('🔄 Generating advanced sample chat data for user: $currentUserId');
      debugPrint('👤 User count: $userCount');
      debugPrint('💬 Messages per conversation: $messagesPerConversation');
      debugPrint('🖼️ Include media: $includeMedia');
      debugPrint('👥 Include group chats: $includeGroupChats');
      
      // Create mock users (or use existing users)
      final mockUsers = await _createAdvancedMockUsers(userCount);
      
      // Create direct chats with each mock user
      await _createAdvancedDirectChats(currentUserId, mockUsers, messagesPerConversation, includeMedia);
      
      // Create group chats if enabled
      if (includeGroupChats) {
        await _createAdvancedGroupChats(currentUserId, mockUsers, messagesPerConversation, includeMedia);
      }
      
      // Set online status for mock users
      await _setMockOnlineStatus(mockUsers);
      
      debugPrint('✅ Advanced sample chat data generated successfully!');
      debugPrint('📱 Navigate to the Messages tab to see the test chats');
    } catch (e) {
      debugPrint('❌ ERROR: Failed to generate advanced sample data: $e');
      rethrow;
    }
  }
  
  /// Create configurable mock users
  static Future<List<Map<String, dynamic>>> _createAdvancedMockUsers(int userCount) async {
    debugPrint('👤 Creating $userCount mock users...');
    
    final mockUsers = <Map<String, dynamic>>[];
    
    // Generate unique IDs for mock users
    for (int i = 1; i <= userCount; i++) {
      final userId = 'mock_user_adv_$i';
      final gender = i % 2 == 0 ? 'women' : 'men';
      final avatarId = i % 70 + 1; // Using randomuser.me API which has ~70 avatars per gender
      
      mockUsers.add({
        'id': userId,
        'name': _getRandomName(i),
        'avatar': 'https://randomuser.me/api/portraits/$gender/$avatarId.jpg',
        'isOnline': i % 3 == 0, // Every third user is online
      });
    }
    
    // Create users in Firestore
    for (final user in mockUsers) {
      final userDoc = await _firestore.collection('users').doc(user['id']).get();
      
      if (!userDoc.exists) {
        // Create user in Firestore
        await _firestore.collection('users').doc(user['id']).set({
          'displayName': user['name'],
          'profileImageUrl': user['avatar'],
          'isOnline': user['isOnline'],
          'lastLogin': FieldValue.serverTimestamp(),
          'major': _getRandomMajor(),
          'year': _getRandomYear(),
          'isVerified': true,
          'bio': 'This is an advanced mock user for testing the messaging feature.',
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        debugPrint('👤 Created mock user: ${user['name']}');
      } else {
        debugPrint('👤 Mock user already exists: ${user['name']}');
      }
    }
    
    return mockUsers;
  }
  
  /// Create advanced direct chats with configurable message count and media
  static Future<void> _createAdvancedDirectChats(
    String currentUserId,
    List<Map<String, dynamic>> mockUsers,
    int messagesPerConversation,
    bool includeMedia,
  ) async {
    debugPrint('💬 Creating direct chats with $messagesPerConversation messages each...');
    
    for (final mockUser in mockUsers) {
      final mockUserId = mockUser['id'];
      final chatId = _getChatId(currentUserId, mockUserId);
      
      // Check if chat already exists
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      
      if (!chatDoc.exists) {
        // Create chat document
        await _firestore.collection('chats').doc(chatId).set({
          'title': mockUser['name'],
          'imageUrl': mockUser['avatar'],
          'type': 0, // 0 = direct, 1 = group
          'participantIds': [currentUserId, mockUserId],
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessageAt': FieldValue.serverTimestamp(),
          'lastMessageText': 'This is an advanced test conversation.',
          'lastMessageSenderId': mockUserId,
          'unreadCount': {currentUserId: 1},
        });
        
        // Create configurable sample messages
        await _createAdvancedMessages(
          chatId,
          currentUserId,
          mockUserId,
          messagesPerConversation,
          includeMedia,
        );
        
        // Add chat reference to user documents
        await _firestore.collection('users').doc(currentUserId).collection('user-chats').doc(chatId).set({
          'lastAccess': FieldValue.serverTimestamp(),
        });
        
        await _firestore.collection('users').doc(mockUserId).collection('user-chats').doc(chatId).set({
          'lastAccess': FieldValue.serverTimestamp(),
        });
        
        debugPrint('💬 Created direct chat with: ${mockUser['name']}');
      } else {
        debugPrint('💬 Direct chat already exists with: ${mockUser['name']}');
      }
    }
  }
  
  /// Create advanced group chats with configurable options
  static Future<void> _createAdvancedGroupChats(
    String currentUserId,
    List<Map<String, dynamic>> allUsers,
    int messagesPerConversation,
    bool includeMedia,
  ) async {
    debugPrint('👥 Creating advanced group chats...');
    
    // Create 1-3 group chats depending on user count
    final groupCount = allUsers.length >= 10 ? 3 : (allUsers.length >= 5 ? 2 : 1);
    
    for (int i = 0; i < groupCount; i++) {
      final chatId = 'adv_group_chat_${i}_${_uuid.v4()}';
      final groupName = _getRandomGroupName(i);
      
      // Select a subset of users for this group
      final userSubset = _selectRandomUsers(allUsers, i == 0 ? allUsers.length : allUsers.length ~/ 2);
      
      // Create participant list
      final participantIds = <String>[currentUserId];
      final participantNames = <String>[];
      
      for (final user in userSubset) {
        participantIds.add(user['id']);
        participantNames.add(user['name']);
      }
      
      // Create chat document
      await _firestore.collection('chats').doc(chatId).set({
        'title': groupName,
        'imageUrl': null,
        'type': 1, // 0 = direct, 1 = group
        'participantIds': participantIds,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageText': 'Welcome to the $groupName!',
        'lastMessageSenderId': currentUserId,
        'unreadCount': {},
      });
      
      // Add unread counts for all participants
      final unreadCounts = <String, dynamic>{};
      for (final id in participantIds) {
        if (id != currentUserId) {
          unreadCounts[id] = 1;
        } else {
          unreadCounts[id] = 0;
        }
      }
      
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount': unreadCounts,
      });
      
      // Create sample group messages
      await _createAdvancedGroupMessages(
        chatId,
        currentUserId,
        userSubset,
        messagesPerConversation,
        includeMedia,
      );
      
      // Add chat reference to all user documents
      for (final userId in participantIds) {
        await _firestore.collection('users').doc(userId).collection('user-chats').doc(chatId).set({
          'lastAccess': FieldValue.serverTimestamp(),
        });
      }
      
      debugPrint('👥 Created group chat "$groupName" with ${participantIds.length} participants');
    }
  }
  
  /// Create configurable messages for a direct chat
  static Future<void> _createAdvancedMessages(
    String chatId,
    String currentUserId,
    String otherUserId,
    int messageCount,
    bool includeMedia,
  ) async {
    final messages = <Map<String, dynamic>>[];
    final now = DateTime.now();
    
    // Generate random messages
    for (int i = 0; i < messageCount; i++) {
      final isFromCurrentUser = i % 2 == 0;
      final senderId = isFromCurrentUser ? currentUserId : otherUserId;
      final minutesAgo = messageCount - i;
      
      // Determine if this should be a media message
      final isMediaMessage = includeMedia && i % 7 == 0;
      
      if (isMediaMessage) {
        // Create a media message
        messages.add({
          'senderId': senderId,
          'content': _getRandomMediaCaption(),
          'timestamp': now.subtract(Duration(minutes: minutesAgo * 5)),
          'isMedia': true,
          'mediaType': i % 2 == 0 ? 'image' : 'video',
          'mediaUrl': _getRandomMediaUrl(i % 2 == 0),
        });
      } else {
        // Create a text message
        messages.add({
          'senderId': senderId,
          'content': _getRandomMessage(i),
          'timestamp': now.subtract(Duration(minutes: minutesAgo * 5)),
          'isMedia': false,
        });
      }
    }
    
    // Add messages to the chat
    for (final message in messages) {
      final messageId = _uuid.v4();
      final senderId = message['senderId'] as String;
      
      final messageData = {
        'id': messageId,
        'chatId': chatId,
        'senderId': senderId,
        'senderName': senderId == currentUserId ? 'You' : await _getUserName(senderId),
        'senderAvatar': senderId == currentUserId ? null : await _getUserAvatar(senderId),
        'content': message['content'],
        'timestamp': message['timestamp'],
        'isRead': senderId != otherUserId, // Messages from other user are unread
        'type': message['isMedia'] ? (message['mediaType'] == 'image' ? 1 : 2) : 0, // 0 = text, 1 = image, 2 = video
        'attachmentUrl': message['isMedia'] ? message['mediaUrl'] : null,
        'attachmentType': message['isMedia'] ? message['mediaType'] : null,
        'replyToMessageId': null,
        'isPinned': false,
      };
      
      await _firestore.collection('chats').doc(chatId).collection('messages').doc(messageId).set(messageData);
    }
    
    debugPrint('📝 Created $messageCount advanced messages for chat: $chatId');
  }
  
  /// Create configurable messages for a group chat
  static Future<void> _createAdvancedGroupMessages(
    String chatId,
    String currentUserId,
    List<Map<String, dynamic>> groupMembers,
    int messageCount,
    bool includeMedia,
  ) async {
    final messages = <Map<String, dynamic>>[];
    final now = DateTime.now();
    final allUserIds = [currentUserId, ...groupMembers.map((u) => u['id'] as String)];
    
    // Generate random messages
    for (int i = 0; i < messageCount; i++) {
      // Rotate through users for messages
      final senderIndex = i % allUserIds.length;
      final senderId = allUserIds[senderIndex];
      final minutesAgo = messageCount - i;
      
      // Determine if this should be a media message
      final isMediaMessage = includeMedia && i % 8 == 0;
      
      if (isMediaMessage) {
        // Create a media message
        messages.add({
          'senderId': senderId,
          'content': _getRandomMediaCaption(),
          'timestamp': now.subtract(Duration(minutes: minutesAgo * 7)),
          'isMedia': true,
          'mediaType': i % 2 == 0 ? 'image' : 'video',
          'mediaUrl': _getRandomMediaUrl(i % 2 == 0),
        });
      } else {
        // Create a text message
        messages.add({
          'senderId': senderId,
          'content': _getRandomGroupMessage(i),
          'timestamp': now.subtract(Duration(minutes: minutesAgo * 7)),
          'isMedia': false,
        });
      }
    }
    
    // Add messages to the chat
    for (final message in messages) {
      final messageId = _uuid.v4();
      final senderId = message['senderId'] as String;
      
      final messageData = {
        'id': messageId,
        'chatId': chatId,
        'senderId': senderId,
        'senderName': senderId == currentUserId ? 'You' : await _getUserName(senderId),
        'senderAvatar': senderId == currentUserId ? null : await _getUserAvatar(senderId),
        'content': message['content'],
        'timestamp': message['timestamp'],
        'isRead': senderId == currentUserId, // Only my messages are read
        'type': message['isMedia'] ? (message['mediaType'] == 'image' ? 1 : 2) : 0, // 0 = text, 1 = image, 2 = video
        'attachmentUrl': message['isMedia'] ? message['mediaUrl'] : null,
        'attachmentType': message['isMedia'] ? message['mediaType'] : null,
        'replyToMessageId': null,
        'isPinned': false,
      };
      
      await _firestore.collection('chats').doc(chatId).collection('messages').doc(messageId).set(messageData);
    }
    
    debugPrint('📝 Created $messageCount advanced messages for group chat: $chatId');
  }
  
  /// Select a random subset of users
  static List<Map<String, dynamic>> _selectRandomUsers(List<Map<String, dynamic>> allUsers, int count) {
    if (count >= allUsers.length) return List.from(allUsers);
    allUsers.shuffle();
    return allUsers.take(count).toList();
  }
  
  /// Get a random name for a mock user
  static String _getRandomName(int index) {
    final firstNames = [
      'Alex', 'Jordan', 'Taylor', 'Morgan', 'Casey', 'Riley', 'Jamie', 'Quinn',
      'Skyler', 'Avery', 'Blake', 'Charlie', 'Dakota', 'Emerson', 'Finley', 'Harley'
    ];
    
    final lastNames = [
      'Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis',
      'Rodriguez', 'Martinez', 'Hernandez', 'Lopez', 'Gonzalez', 'Wilson', 'Anderson', 'Thomas'
    ];
    
    final firstIndex = (index * 3) % firstNames.length;
    final lastIndex = (index * 7) % lastNames.length;
    
    return '${firstNames[firstIndex]} ${lastNames[lastIndex]}';
  }
  
  /// Get a random major for a mock user
  static String _getRandomMajor() {
    final majors = [
      'Computer Science', 'Business Administration', 'Engineering', 'Psychology',
      'Biology', 'English', 'Communications', 'Political Science', 'Economics',
      'Art History', 'Mathematics', 'Physics', 'Chemistry', 'Music', 'Sociology'
    ];
    
    return majors[DateTime.now().microsecond % majors.length];
  }
  
  /// Get a random year for a mock user
  static String _getRandomYear() {
    final years = ['Freshman', 'Sophomore', 'Junior', 'Senior', 'Graduate'];
    return years[DateTime.now().microsecond % years.length];
  }
  
  /// Get a random group name
  static String _getRandomGroupName(int index) {
    final groupNames = [
      'HIVE Campus Group',
      'Study Buddies',
      'Weekend Plans',
      'Project Team',
      'Campus Events',
      'Coffee Club',
      'Fitness Group',
      'Movie Night Crew',
      'Hackathon Team',
      'Campus Foodies'
    ];
    
    return groupNames[index % groupNames.length];
  }
  
  /// Get a random message for conversation
  static String _getRandomMessage(int index) {
    final messages = [
      'Hey there! How are you doing?',
      'What are you up to today?',
      'Did you finish that assignment yet?',
      'I\'m thinking of going to the campus cafe later. Want to join?',
      'Have you seen the latest campus event posting?',
      'The library is so crowded today!',
      'Do you know when the next club meeting is?',
      'I just got tickets for the concert this weekend!',
      'Can you share your notes from yesterday\'s lecture?',
      'What did you think about the professor\'s announcement?',
      'I\'m going to be a few minutes late for our study session.',
      'Did you see that email from the department?',
      'The weather is perfect for a campus picnic today!',
      'Have you registered for next semester\'s classes yet?',
      'I found this great coffee shop just off campus.',
      'Can we reschedule our meeting for tomorrow?',
      'I could really use some help with this problem set.',
      'Are you going to the game this weekend?',
      'This class is definitely more challenging than I expected.',
      'Happy Friday! Any plans for the weekend?'
    ];
    
    return messages[index % messages.length];
  }
  
  /// Get a random message for group conversation
  static String _getRandomGroupMessage(int index) {
    final messages = [
      'Hey everyone! How\'s it going?',
      'When are we meeting up next?',
      'Who\'s going to the campus event tonight?',
      'I created a shared document for our project. Check your email for the invite.',
      'Can someone explain what the professor meant about the midterm format?',
      'Does anyone have an extra textbook I could borrow?',
      'I\'ll be in the library if anyone wants to join for a study session.',
      'Just a reminder, our presentation is due next week!',
      'Pizza in the student center right now if anyone\'s interested!',
      'Did everyone submit their part of the assignment?',
      'Who wants to grab dinner after class?',
      'I found some great research papers for our project. I\'ll share them later.',
      'Is anyone else having trouble with the online portal?',
      'Great meeting everyone today! I think we made good progress.',
      'Let\'s aim to finish the outline by Friday, does that work for everyone?',
      'There\'s a guest speaker coming next week that\'s relevant to our topic.',
      'Thanks for all your help with the project!',
      'I created a poll for our next meeting time, please vote!',
      'Here\'s the link to the resources we discussed today.',
      'Has anyone started on the final project yet?'
    ];
    
    return messages[index % messages.length];
  }
  
  /// Get a random caption for media messages
  static String _getRandomMediaCaption() {
    final captions = [
      'Check this out!',
      'What do you think?',
      'Just took this!',
      'Look what I found',
      'This is amazing',
      '',
      'Can\'t believe my eyes',
      'Thought you might like this',
      'From today',
      'Interesting, right?'
    ];
    
    return captions[DateTime.now().microsecond % captions.length];
  }
  
  /// Get a random media URL based on type
  static String _getRandomMediaUrl(bool isImage) {
    if (isImage) {
      // Use random unsplash images
      final categories = ['campus', 'study', 'coffee', 'library', 'nature', 'technology'];
      final category = categories[DateTime.now().microsecond % categories.length];
      final dimensions = '800x600';
      final randomId = DateTime.now().millisecondsSinceEpoch % 1000;
      
      return 'https://source.unsplash.com/random/$dimensions/?$category&sig=$randomId';
    } else {
      // Return placeholder video URL
      return 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4';
    }
  }
  
  /// Clear all test data without confirmation for Advanced screen
  static Future<void> clearAllTestData() async {
    // Call the existing method directly
    return confirmClearTestData();
  }
} 