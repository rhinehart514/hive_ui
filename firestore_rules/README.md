# HIVE UI Firebase Security Rules

This directory contains comprehensive Firebase security rules for the HIVE UI platform, covering both Firestore Database and Firebase Storage.

## Directory Contents

- **firestore.rules**: Main Firestore security rules file for all collections and documents
- **storage.rules**: Firebase Storage security rules to protect file uploads and downloads
- **chat_security_rules.md**: Detailed documentation on the chat-specific security model
- **deployment_guide.md**: Guide for deploying, testing, and maintaining these security rules

## Security Model Overview

The HIVE UI security model follows these core principles:

1. **User Authentication**: Most operations require authentication
2. **Role-Based Access**: Different permissions for admins, moderators, club leaders, etc.
3. **Resource Ownership**: Users can only edit their own content
4. **Data Validation**: Ensures data consistency and prevents malicious inputs
5. **Contextual Access**: Club members access club data, chat participants access chat data

## Key Features

- Comprehensive helper functions for common security checks
- Detailed rules for users, clubs, events, chats, spaces, and system data
- Special handling for chat messages and attachments
- Storage rules for profile pictures, club images, event media, etc.
- Prevention of unauthorized data access across all collections

## Using These Rules

1. Copy the rules files to your Firebase project
2. Deploy using the Firebase CLI
3. Test with the Firebase Emulator Suite
4. Refer to `deployment_guide.md` for step-by-step instructions

## Security Rules Testing

It's critical to test these rules thoroughly before deployment:

```javascript
// Example test for chat security
const chatId = "chat123";
const messageId = "msg456";

// Setup test data
await admin.firestore().collection("chats").doc(chatId).set({
  participantIds: ["user1", "user2"],
  type: "direct",
  createdAt: admin.firestore.FieldValue.serverTimestamp()
});

// Test participant access (should succeed)
await firebase.assertSucceeds(
  firebase.firestore()
    .collection("chats")
    .doc(chatId)
    .get()
);

// Test non-participant access (should fail)
await firebase.assertFails(
  firebase.firestore()
    .collection("chats")
    .doc(chatId)
    .get()
);
```

## Customization

These rules are designed to work with the HIVE UI data model, but you may need to customize:

- Adjust helper functions to match your data structure
- Modify collection paths if you've changed the data organization
- Add or remove rules for custom collections
- Adjust validation logic to match your business rules

## Important Considerations

- Rules cascade from top to bottom, with the first matching rule taking precedence
- Firebase has a 256KB limit on rules file size
- Cross-collection `get()` operations can impact performance
- Rule changes can take up to a minute to propagate

## Maintenance

Regularly update these rules when:
- Adding new collections
- Changing data structures
- Implementing new features
- Modifying access patterns

## Further Documentation

- See `chat_security_rules.md` for details on chat security implementation
- See `deployment_guide.md` for deployment instructions
- Refer to [Firebase Security Rules Documentation](https://firebase.google.com/docs/rules) for general guidance 