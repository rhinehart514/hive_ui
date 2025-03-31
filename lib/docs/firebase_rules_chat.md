# Firebase Chat Security Rules for HIVE UI

This document outlines specialized Firebase security rules and best practices for implementing secure, real-time chat functionality in the HIVE UI application.

## 1. Chat Data Structure

### 1.1 Collection Design
- Use `/chats/{chatId}` as the main collection for all chat data
- Store messages in `/chats/{chatId}/messages/{messageId}` subcollection
- Store typing status in `/chats/{chatId}/typing/{userId}` subcollection
- Include participantIds array in chat documents for access control
- Example chat document:
  ```json
  {
    "id": "chat123",
    "title": "Club Leaders Discussion",
    "participantIds": ["user1", "user2", "user3"],
    "createdAt": "2023-03-15T10:30:00Z",
    "lastMessage": {
      "text": "When is our next meeting?",
      "senderId": "user1",
      "timestamp": "2023-03-16T14:22:00Z"
    },
    "metadata": {
      "isGroupChat": true,
      "groupOwner": "user1"
    }
  }
  ```

### 1.2 Message Structure
- Store each message in a subcollection with appropriate metadata
- Include read receipts and delivery status when necessary
- Support various message types (text, image, file, etc.)
- Example message document:
  ```json
  {
    "id": "msg456",
    "text": "When is our next meeting?",
    "senderId": "user1",
    "timestamp": "2023-03-16T14:22:00Z",
    "readBy": ["user1"],
    "attachments": [],
    "type": "text"
  }
  ```

## 2. Firestore Security Rules

### 2.1 Chat Access Control
- Restrict chat access to participants listed in participantIds
- Allow creation of new chats only by authenticated users
- Prevent modification of chat metadata by non-owners
- Example security rules for chats:
  ```
  match /chats/{chatId} {
    // Allow read if user is a participant
    allow read: if request.auth != null && 
      resource.data.participantIds.hasAny([request.auth.uid]);
      
    // Allow create with validation
    allow create: if request.auth != null && 
      request.resource.data.participantIds.hasAny([request.auth.uid]) &&
      request.resource.data.createdAt is timestamp;
      
    // Allow update with restrictions
    allow update: if request.auth != null && 
      resource.data.participantIds.hasAny([request.auth.uid]) &&
      (!request.resource.data.diff(resource.data).affectedKeys()
        .hasAny(['participantIds', 'createdAt']) || 
        resource.data.metadata.groupOwner == request.auth.uid);
  }
  ```

### 2.2 Message Security
- Only allow message creation by chat participants
- Only allow message senders to update or delete their own messages
- Allow admins to delete any message
- Enforce message size and rate limiting
- Example security rules for messages:
  ```
  match /chats/{chatId}/messages/{messageId} {
    // Allow read if user is a participant in the parent chat
    allow read: if request.auth != null && 
      get(/databases/$(database)/documents/chats/$(chatId)).data
        .participantIds.hasAny([request.auth.uid]);
    
    // Allow create with validation
    allow create: if request.auth != null && 
      get(/databases/$(database)/documents/chats/$(chatId)).data
        .participantIds.hasAny([request.auth.uid]) &&
      request.resource.data.senderId == request.auth.uid &&
      request.resource.data.timestamp is timestamp;
      
    // Allow update for own messages only
    allow update: if request.auth != null && 
      resource.data.senderId == request.auth.uid;
      
    // Allow delete for own messages or admin
    allow delete: if request.auth != null && 
      (resource.data.senderId == request.auth.uid || 
       request.auth.token.admin == true);
  }
  ```

### 2.3 Typing Indicators
- Only allow users to update their own typing status
- Automatically expire typing indicators after a short period
- Example security rules for typing indicators:
  ```
  match /chats/{chatId}/typing/{userId} {
    // Allow read if user is a participant
    allow read: if request.auth != null && 
      get(/databases/$(database)/documents/chats/$(chatId)).data
        .participantIds.hasAny([request.auth.uid]);
        
    // Allow write only to own typing status
    allow write: if request.auth != null && 
      userId == request.auth.uid &&
      get(/databases/$(database)/documents/chats/$(chatId)).data
        .participantIds.hasAny([request.auth.uid]);
  }
  ```

## 3. Real-time Chat Implementation

### 3.1 Message Listeners
- Use Firestore listeners for real-time updates
- Implement proper error handling for stream interruptions
- Clean up listeners when leaving chat screens
- Example real-time listener setup:
  ```dart
  StreamSubscription<QuerySnapshot>? _messagesSubscription;
  
  void setupMessageListener(String chatId) {
    // Order by timestamp to get messages in chronological order
    final messagesQuery = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp')
        .limit(50); // Paginate for performance
        
    _messagesSubscription = messagesQuery.snapshots().listen(
      (snapshot) {
        final messages = snapshot.docs
            .map((doc) => MessageModel.fromJson(doc.data()))
            .toList();
            
        // Update UI with new messages
        _chatController.updateMessages(messages);
      },
      onError: (error) {
        logError('Error listening to messages', error);
        // Handle error appropriately
      }
    );
  }
  
  void disposeMessageListener() {
    _messagesSubscription?.cancel();
    _messagesSubscription = null;
  }
  ```

### 3.2 Typing Indicators
- Use debounce for typing indicator updates
- Implement auto-expiry for typing indicators
- Clean up typing status when leaving chat
- Example typing indicator implementation:
  ```dart
  Timer? _typingTimer;
  bool _isTyping = false;
  
  void handleUserTyping(String chatId, String userId) {
    // Cancel existing timer if any
    _typingTimer?.cancel();
    
    // Update typing status in Firestore if not already typing
    if (!_isTyping) {
      _isTyping = true;
      _firestore
          .collection('chats')
          .doc(chatId)
          .collection('typing')
          .doc(userId)
          .set({'isTyping': true, 'timestamp': FieldValue.serverTimestamp()});
    }
    
    // Set timer to clear typing status after inactivity
    _typingTimer = Timer(const Duration(seconds: 5), () {
      _isTyping = false;
      _firestore
          .collection('chats')
          .doc(chatId)
          .collection('typing')
          .doc(userId)
          .delete();
    });
  }
  
  void cleanupTypingStatus(String chatId, String userId) {
    _typingTimer?.cancel();
    if (_isTyping) {
      _firestore
          .collection('chats')
          .doc(chatId)
          .collection('typing')
          .doc(userId)
          .delete();
      _isTyping = false;
    }
  }
  ```

## 4. Performance Optimization

### 4.1 Pagination and Query Limits
- Implement pagination for message history
- Use query limits to prevent excessive data transfer
- Cache message data locally for smooth scrolling
- Example message pagination:
  ```dart
  Future<List<MessageModel>> loadPreviousMessages(
    String chatId, 
    MessageModel? oldestLoadedMessage,
    {int limit = 20}
  ) async {
    try {
      var query = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(limit);
          
      // If we have an oldest message, get messages before it
      if (oldestLoadedMessage != null) {
        query = query.endBefore([oldestLoadedMessage.timestamp]);
      }
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs
          .map((doc) => MessageModel.fromJson(doc.data()))
          .toList()
          .reversed // Reverse to get chronological order
          .toList();
    } catch (e) {
      logError('Failed to load previous messages', e);
      rethrow;
    }
  }
  ```

### 4.2 Offline Support
- Enable Firestore offline persistence for chat data
- Display appropriate UI for message sending status
- Handle reconnection gracefully
- Example offline configuration:
  ```dart
  Future<void> configureFirestoreForOfflineSupport() async {
    await FirebaseFirestore.instance.settings = Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }
  ```

## 5. Message Content Security

### 5.1 Content Validation
- Validate message content before saving to Firestore
- Implement character limits for text messages
- Validate and sanitize message content to prevent injection attacks
- Example content validation:
  ```dart
  bool validateMessageContent(MessageModel message) {
    // Check for empty content
    if (message.type == 'text' && 
        (message.text == null || message.text!.trim().isEmpty)) {
      return false;
    }
    
    // Check text length limits
    if (message.type == 'text' && message.text!.length > 2000) {
      return false;
    }
    
    // Validate attachment types and sizes
    if (message.attachments.isNotEmpty) {
      for (final attachment in message.attachments) {
        if (!_isValidAttachment(attachment)) {
          return false;
        }
      }
    }
    
    return true;
  }
  
  bool _isValidAttachment(AttachmentModel attachment) {
    // Validate file type
    final allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 
                          'application/pdf', 'text/plain'];
    if (!allowedTypes.contains(attachment.mimeType)) {
      return false;
    }
    
    // Validate file size (10MB max)
    if (attachment.size > 10 * 1024 * 1024) {
      return false;
    }
    
    return true;
  }
  ```

### 5.2 Content Moderation
- Implement content filtering for inappropriate content
- Use Firebase Functions for automated content moderation
- Allow reporting of inappropriate messages
- Example content moderation function:
  ```javascript
  // Firebase Cloud Function for content moderation
  exports.moderateMessageContent = functions.firestore
    .document('chats/{chatId}/messages/{messageId}')
    .onCreate(async (snapshot, context) => {
      const message = snapshot.data();
      
      // Skip moderation for non-text messages
      if (message.type !== 'text' || !message.text) {
        return null;
      }
      
      // Check content against moderation API
      const moderationResult = await checkContent(message.text);
      
      if (moderationResult.isInappropriate) {
        // Option 1: Delete the message
        return snapshot.ref.delete();
        
        // Option 2: Flag the message
        return snapshot.ref.update({
          'flagged': true,
          'flagReason': moderationResult.reason
        });
      }
      
      return null;
    });
  ```

## 6. Media Message Handling

### 6.1 Media Storage
- Store media files in Firebase Storage with secure access controls
- Organize files in folders by chat and message IDs
- Set appropriate security rules for media access
- Example storage structure:
  ```
  /chat_media/{chatId}/{messageId}/{fileName}
  ```

### 6.2 Media Upload Implementation
- Show upload progress for media messages
- Compress images before upload when appropriate
- Handle upload errors gracefully
- Example media upload implementation:
  ```dart
  Future<String> uploadChatMedia(
    String chatId, 
    String messageId, 
    File mediaFile,
    String fileName
  ) async {
    try {
      // Compress image if it's an image file
      File fileToUpload = mediaFile;
      if (_isImageFile(fileName)) {
        fileToUpload = await _compressImage(mediaFile);
      }
      
      // Create storage reference
      final storageRef = _storage.ref()
          .child('chat_media')
          .child(chatId)
          .child(messageId)
          .child(fileName);
      
      // Start upload with progress tracking
      final uploadTask = storageRef.putFile(
        fileToUpload,
        SettableMetadata(contentType: _getContentType(fileName))
      );
      
      // Listen for progress updates
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        _updateUploadProgress(messageId, progress);
      });
      
      // Get download URL when complete
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      logError('Failed to upload chat media', e);
      rethrow;
    }
  }
  ```

## 7. Chat Privacy and Security

### 7.1 End-to-End Encryption
- Consider implementing client-side encryption for sensitive chats
- Store encryption keys securely
- Document encryption approach for transparency
- Example encryption implementation approach:
  ```dart
  // Generate a unique encryption key for a chat
  Future<String> generateChatEncryptionKey() async {
    // Generate a random encryption key
    final key = await _cryptoService.generateRandomKey();
    return base64Encode(key);
  }
  
  // Encrypt message content
  Future<String> encryptMessageContent(String content, String encryptionKey) async {
    final keyBytes = base64Decode(encryptionKey);
    return await _cryptoService.encrypt(content, keyBytes);
  }
  
  // Decrypt message content
  Future<String> decryptMessageContent(String encryptedContent, String encryptionKey) async {
    final keyBytes = base64Decode(encryptionKey);
    return await _cryptoService.decrypt(encryptedContent, keyBytes);
  }
  ```

### 7.2 Message Deletion and Retention
- Implement proper message deletion functionality
- Consider message retention policies
- Allow users to delete their own messages
- Example message deletion implementation:
  ```dart
  Future<void> deleteMessage(String chatId, String messageId, String userId) async {
    try {
      final messageRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId);
      
      // Get the message to check permissions
      final messageDoc = await messageRef.get();
      if (!messageDoc.exists) {
        throw 'Message not found';
      }
      
      final messageData = messageDoc.data()!;
      
      // Check if user can delete this message
      if (messageData['senderId'] != userId && !_isUserAdmin(userId)) {
        throw 'Permission denied';
      }
      
      // Delete associated media if any
      if (messageData['attachments'] != null && 
          (messageData['attachments'] as List).isNotEmpty) {
        await _deleteMessageMedia(chatId, messageId);
      }
      
      // Delete the message document
      await messageRef.delete();
      
      // Update last message in chat if needed
      await _updateChatLastMessageAfterDeletion(chatId, messageId);
    } catch (e) {
      logError('Failed to delete message', e);
      rethrow;
    }
  }
  ```

## 8. Testing Chat Functionality

### 8.1 Chat Unit Testing
- Test message sending, receiving, and validation
- Mock Firestore for testing chat repositories
- Test error handling and edge cases
- Example chat repository test:
  ```dart
  void main() {
    group('ChatRepository', () {
      late MockFirebaseFirestore mockFirestore;
      late ChatRepository chatRepository;
      
      setUp(() {
        mockFirestore = MockFirebaseFirestore();
        chatRepository = FirestoreChatRepository(mockFirestore);
      });
      
      test('sendMessage should add message to Firestore', () async {
        // Arrange
        final chatId = 'test-chat-id';
        final message = MessageModel(
          id: 'test-message-id',
          text: 'Hello, world!',
          senderId: 'user1',
          timestamp: DateTime.now(),
          type: 'text',
        );
        
        // Setup mock response
        when(mockFirestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .add(any))
          .thenAnswer((_) async => MockDocumentReference());
          
        // Act
        await chatRepository.sendMessage(chatId, message);
        
        // Assert
        verify(mockFirestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .add(any)).called(1);
      });
    });
  }
  ```

### 8.2 Chat Integration Testing
- Test real-time chat functionality with Firebase Emulator
- Validate chat security rules with security rule tests
- Test chat UI with widget tests
- Example security rule test:
  ```javascript
  // Firebase security rules test
  const assert = require('assert');
  const firebase = require('@firebase/rules-unit-testing');

  describe('Chat security rules', () => {
    let app;
    
    beforeEach(async () => {
      app = firebase.initializeTestApp({
        projectId: 'hive-test',
        auth: { uid: 'user1' }
      });
    });
    
    it('allows users to read chats they are participants in', async () => {
      const db = app.firestore();
      
      // Setup test data
      await firebase.loadFirestoreRules({
        projectId: 'hive-test',
        rules: fs.readFileSync('firestore.rules', 'utf8')
      });
      
      await firebase.clearFirestoreData({ projectId: 'hive-test' });
      
      const admin = firebase.initializeAdminApp({
        projectId: 'hive-test'
      });
      
      // Create test chat with user1 as participant
      await admin.firestore().collection('chats').doc('chat1').set({
        participantIds: ['user1', 'user2'],
        title: 'Test Chat'
      });
      
      // Test read access
      const chatRef = db.collection('chats').doc('chat1');
      await firebase.assertSucceeds(chatRef.get());
    });
    
    it('prevents users from reading chats they are not participants in', async () => {
      const db = app.firestore();
      
      // Setup test data (similar to above)
      // ...
      
      // Create test chat without user1 as participant
      await admin.firestore().collection('chats').doc('chat2').set({
        participantIds: ['user2', 'user3'],
        title: 'Private Chat'
      });
      
      // Test read access is denied
      const chatRef = db.collection('chats').doc('chat2');
      await firebase.assertFails(chatRef.get());
    });
  });
  ```

## 9. Deployment Checklist

### 9.1 Security Rule Deployment
- Deploy and test security rules before enabling chat in production
- Use rule testing to validate all access scenarios
- Monitor rule performance in production
- Example deployment command:
  ```bash
  firebase deploy --only firestore:rules
  ```

### 9.2 Performance Monitoring
- Set up Firebase Performance Monitoring for chat queries
- Monitor message delivery latency
- Track client-side performance metrics
- Example performance instrumentation:
  ```dart
  Future<void> sendMessageWithPerformanceTracking(
    String chatId, 
    MessageModel message
  ) async {
    // Create a trace for message sending performance
    final trace = FirebasePerformance.instance.newTrace('send_message');
    await trace.start();
    
    try {
      // Add custom attributes for analysis
      trace.putAttribute('chat_id', chatId);
      trace.putAttribute('message_type', message.type);
      
      // Start a metric for serialization time
      trace.startMetric('serialization_time');
      final messageData = message.toJson();
      trace.stopMetric('serialization_time');
      
      // Start a metric for database write time
      trace.startMetric('database_write_time');
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(messageData);
      trace.stopMetric('database_write_time');
      
      trace.incrementMetric('successful_sends', 1);
    } catch (e) {
      trace.incrementMetric('failed_sends', 1);
      rethrow;
    } finally {
      await trace.stop();
    }
  }
  ```

## 10. Additional Security Considerations

### 10.1 Rate Limiting
- Implement rate limiting for message sending
- Use Firebase Functions to enforce limits
- Add client-side throttling for better UX
- Example rate limiting function:
  ```javascript
  // Firebase Function for rate limiting
  exports.enforceMessageRateLimit = functions.firestore
    .document('chats/{chatId}/messages/{messageId}')
    .onCreate(async (snapshot, context) => {
      const { senderId } = snapshot.data();
      const timestamp = snapshot.data().timestamp.toDate();
      
      // Check recent messages from this user
      const recentMessages = await admin.firestore()
        .collectionGroup('messages')
        .where('senderId', '==', senderId)
        .where('timestamp', '>', new Date(timestamp.getTime() - 60000)) // Last minute
        .get();
        
      // If more than 30 messages in the last minute, delete this message
      if (recentMessages.size > 30) {
        console.log(`Rate limit exceeded for user ${senderId}`);
        return snapshot.ref.delete();
      }
      
      return null;
    });
  ```

### 10.2 Abuse Detection
- Implement reporting functionality for abusive messages
- Create admin functions to review and act on reports
- Use Firebase Functions to handle chat moderation
- Example reporting implementation:
  ```dart
  Future<void> reportMessage(
    String chatId, 
    String messageId, 
    String reporterId,
    String reason
  ) async {
    try {
      await _firestore.collection('reports').add({
        'chatId': chatId,
        'messageId': messageId,
        'reporterId': reporterId,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (e) {
      logError('Failed to report message', e);
      rethrow;
    }
  }
  ``` 