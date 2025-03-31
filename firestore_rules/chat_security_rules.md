# HIVE UI Chat Security Rules Guide

This document provides an in-depth explanation of the Firestore security rules implemented for the chat and messaging system in the HIVE UI application. These rules enforce proper access control, data validation, and secure real-time communication.

## Core Chat Data Structure

### Chat Collection
- Main collection: `/chats/{chatId}`
- Message subcollection: `/chats/{chatId}/messages/{messageId}`
- Typing status subcollection: `/chats/{chatId}/typing/{userId}`

### Chat Document Structure
```json
{
  "id": "chat123",
  "title": "Club Discussion",
  "type": "group", // direct, group, club, event
  "participantIds": ["user1", "user2", "user3"],
  "createdAt": "2023-03-15T10:30:00Z",
  "lastMessageAt": "2023-03-16T14:22:00Z",
  "lastMessageText": "When is our next meeting?",
  "lastMessageSenderId": "user1",
  "unreadCount": {
    "user1": 0,
    "user2": 1,
    "user3": 1
  },
  "pinnedMessageIds": ["msg123", "msg456"],
  "clubId": "club123", // for club chats
  "eventId": "event123" // for event chats
}
```

### Message Document Structure
```json
{
  "id": "msg456",
  "text": "When is our next meeting?",
  "senderId": "user1",
  "timestamp": "2023-03-16T14:22:00Z",
  "readBy": ["user1"],
  "attachments": [],
  "type": "text" // text, image, file, etc.
}
```

## Security Rules Overview

### Access Control Principle

The core principle of the chat security model is that **only participants should have access to their chats and messages**. This is enforced through participant lists stored in each chat document.

### Helper Functions

```javascript
// Check if user is a participant in a chat
function isChatParticipant(chatId) {
  return request.auth != null && 
    get(/databases/$(database)/documents/chats/$(chatId)).data.participantIds.hasAny([request.auth.uid]);
}
```

## Detailed Rules Explanation

### 1. Chat Collection Access

```javascript
match /chats/{chatId} {
  // Only chat participants can read chat data
  allow read: if isChatParticipant(chatId);
  
  // Any authenticated user can create a chat if they include themselves as participant
  allow create: if isAuthenticated() && 
    request.resource.data.createdAt is timestamp &&
    request.resource.data.participantIds.hasAny([request.auth.uid]);
  
  // Update rules based on chat type
  allow update: if isChatParticipant(chatId) && (
    // Direct chats: either participant can update last message info
    (request.resource.data.type == "direct" && 
      fieldsUnchanged(["lastMessageText", "lastMessageAt", "lastMessageSenderId", "unreadCount"])) ||
    
    // Group chats: only change allowed by regular members is updating unread counts
    (request.resource.data.type == "group" && 
      (fieldsUnchanged(["unreadCount"]) || isAdmin() || isModerator()))
  );
  
  // Only admin can delete chats
  allow delete: if isAdmin();
}
```

#### Rule Justification:
- **Read restriction**: Protects private conversations by ensuring only participants can access chats
- **Create validation**: Prevents creating chats on behalf of other users
- **Update restrictions**: 
  - For direct chats, allows either participant to update last message info and unread counts
  - For group chats, restricts regular members to only updating their read status
  - Prevents tampering with critical fields like participant lists
- **Delete restriction**: Only admins can permanently remove chat threads for data protection

### 2. Messages Subcollection Access

```javascript
match /chats/{chatId}/messages/{messageId} {
  // Chat participants can read messages
  allow read: if isChatParticipant(chatId);
  
  // Chat participants can send messages
  allow create: if isChatParticipant(chatId) && 
    request.resource.data.senderId == request.auth.uid &&
    request.resource.data.timestamp is timestamp;
  
  // Users can only edit their own messages
  allow update: if request.auth.uid == resource.data.senderId &&
    request.resource.data.timestamp == resource.data.timestamp; // Can't change original timestamp
  
  // Users can delete their own messages, admins/moderators can delete any message
  allow delete: if request.auth.uid == resource.data.senderId || isAdmin() || isModerator();
}
```

#### Rule Justification:
- **Read restriction**: Only chat participants can read messages in the chat
- **Create validation**: 
  - Ensures the sender ID in the message matches the authenticated user
  - Requires a valid timestamp for message ordering
  - Prevents sending messages in chats where the user is not a participant
- **Update restriction**: 
  - Only message author can edit their messages
  - Prevents changing the original timestamp to maintain accurate conversation history
- **Delete permissions**: 
  - Message authors can delete their own messages
  - Admins and moderators can remove inappropriate content

### 3. Typing Indicators

```javascript
match /chats/{chatId}/typing/{userId} {
  allow read: if isChatParticipant(chatId);
  allow write: if isUser(userId) && isChatParticipant(chatId);
}
```

#### Rule Justification:
- **Read access**: All chat participants can see who is typing
- **Write restriction**: Users can only update their own typing status
- **Participant check**: Ensures typing indicators are only visible to chat participants

### 4. Club Chat Special Rules

```javascript
match /chats/{chatId}/club_chats/{clubChatId} {
  allow read: if isClubMember(chatId.split('_')[1]);
  allow write: if isClubAdmin(chatId.split('_')[1]);
}
```

#### Rule Justification:
- **Read access**: Available to all club members
- **Write restriction**: Limited to club administrators
- **Club ID extraction**: Uses the club ID embedded in the chat ID (format: `club_[clubId]`)

## Security Considerations

### 1. Rate Limiting
The rules do not directly implement rate limiting, which should be handled by Cloud Functions or server-side logic to prevent message flooding.

### 2. Content Validation
Message content validation should be implemented through:
- Client-side validation
- Server-side Firebase Functions for content moderation
- For sensitive applications, consider adding maximum message size checks in the rules

### 3. Attachment Security
For file attachments:
- Store file metadata in Firestore
- Upload files to Firebase Storage with proper security rules
- Reference the storage path in the message document

### 4. Time Synchronization
Always use server timestamps (`FieldValue.serverTimestamp()`) when creating messages to ensure accurate ordering and prevent timestamp manipulation.

## Implementation Tips

### 1. Client-Side Security
Even with secure rules, implement client-side validation to:
- Improve user experience with immediate feedback
- Reduce unnecessary write attempts
- Handle formatting and content checks before submission

### 2. Optimizing Reads
- Implement pagination for message history
- Use query limits to prevent excessive data transfer
- Consider using snapshot listeners with proper cleanup

### 3. Offline Capability
Configure Firestore persistence for offline message viewing:
```dart
await FirebaseFirestore.instance.settings = Settings(
  persistenceEnabled: true,
  cacheSizeBytes: 10485760,  // 10 MB
);
```

### 4. Message Lifecycle
Implement proper message state tracking:
- Sending state for in-progress messages
- Error state for failed messages
- Delivered/read indicators
- Cleanup for deleted messages

## Testing Your Rules

Test these security rules against various scenarios:
1. User trying to access a chat they're not part of
2. User sending a message with incorrect sender ID
3. User attempting to edit another user's message
4. User trying to add/remove participants without permission
5. Moderator/admin content moderation
6. Club members access to club chats

Use the Firebase Emulator Suite to test rules before deployment. 