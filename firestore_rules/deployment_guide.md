# HIVE UI Firebase Security Rules: Deployment Guide

This guide outlines the process for deploying, testing, and maintaining the Firebase security rules for the HIVE UI platform.

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Deployment Process](#deployment-process)
4. [Testing Rules](#testing-rules)
5. [Rule Structure & Organization](#rule-structure--organization)
6. [Maintenance & Updates](#maintenance--updates)
7. [Common Issues & Troubleshooting](#common-issues--troubleshooting)

## Overview

The HIVE UI platform uses a comprehensive set of security rules to protect data in Firestore and files in Firebase Storage. These rules enforce proper access control based on user roles, membership status, and ownership of resources.

Key security principles:
- Authenticated access for most operations
- Role-based permissions (admin, moderator, club admin)
- Data isolation (users can only access their own data where appropriate)
- Resource ownership validation
- Content validation (file sizes, types, etc.)

## Prerequisites

Before deploying these rules, ensure you have:

1. **Firebase CLI** installed and configured:
   ```bash
   npm install -g firebase-tools
   firebase login
   ```

2. **Firebase project** already created and configured

3. **Firebase Emulator Suite** for local testing:
   ```bash
   firebase init emulators
   ```

4. **Understanding of HIVE data structures** to ensure rules will work with your data

## Deployment Process

### Step 1: Initialize Firebase in your project (if not already done)

```bash
firebase init firestore
firebase init storage
```

### Step 2: Copy Security Rules

1. Copy the contents of `firestore.rules` to the `firestore.rules` file in your project root
2. Copy the contents of `storage.rules` to the `storage.rules` file in your project root

### Step 3: Deploy Rules to Firebase

To deploy Firestore security rules:
```bash
firebase deploy --only firestore:rules
```

To deploy Storage security rules:
```bash
firebase deploy --only storage:rules
```

To deploy both simultaneously:
```bash
firebase deploy --only firestore:rules,storage:rules
```

### Step 4: Verify Deployment

1. Open the Firebase Console: [https://console.firebase.google.com/](https://console.firebase.google.com/)
2. Navigate to your project
3. Go to Firestore Database > Rules tab to verify Firestore rules
4. Go to Storage > Rules tab to verify Storage rules

## Testing Rules

### Local Testing with Firebase Emulator

1. Start the Firebase Emulator Suite:
   ```bash
   firebase emulators:start
   ```

2. Use the Firestore Rules Playground in the Emulator UI (typically at http://localhost:4000)

3. Write and execute test cases:

   ```javascript
   // Example: Test if a non-participant can read a chat
   const db = firebase.firestore();
   
   // Set up test data
   await firebase.assertSucceeds(
     db.collection('chats').doc('testChatId').set({
       participantIds: ['user1', 'user2'],
       title: 'Test Chat',
       type: 'direct',
       createdAt: firebase.firestore.FieldValue.serverTimestamp()
     })
   );
   
   // Test with non-participant (should fail)
   await firebase.assertFails(
     db.collection('chats').doc('testChatId').get()
   );
   ```

### Automated Testing

Create a `rules.test.js` file in your project for automated testing:

```javascript
const firebase = require('@firebase/rules-unit-testing');
const fs = require('fs');

const PROJECT_ID = 'hive-ui-test';
let testEnv;

beforeAll(async () => {
  // Load rules file
  const rules = fs.readFileSync('firestore.rules', 'utf8');
  
  // Create test environment
  testEnv = await firebase.initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules }
  });
});

afterAll(async () => {
  // Cleanup
  await testEnv.cleanup();
});

beforeEach(async () => {
  // Clear data between tests
  await testEnv.clearFirestore();
});

describe('Chat security rules', () => {
  it('allows chat participants to read chats', async () => {
    // Setup: Create a test chat with two participants
    const admin = testEnv.authenticatedContext('admin');
    await admin.firestore().collection('chats').doc('chat1').set({
      participantIds: ['user1', 'user2'],
      title: 'Test Chat',
      type: 'direct',
      createdAt: firebase.firestore.FieldValue.serverTimestamp()
    });
    
    // Test: user1 (participant) should be able to read the chat
    const user1 = testEnv.authenticatedContext('user1');
    await firebase.assertSucceeds(
      user1.firestore().collection('chats').doc('chat1').get()
    );
    
    // Test: user3 (non-participant) should NOT be able to read the chat
    const user3 = testEnv.authenticatedContext('user3');
    await firebase.assertFails(
      user3.firestore().collection('chats').doc('chat1').get()
    );
  });
  
  // Add more tests...
});
```

Run the tests:
```bash
npm test
```

## Rule Structure & Organization

The security rules are organized into logical sections:

1. **Helper Functions**: Reusable functions for common checks
2. **User Profile Rules**: Control access to user data
3. **Club Rules**: Manage club data and membership
4. **Event Rules**: Control event creation and access
5. **Chat Rules**: Secure messaging and attachments
6. **Space Rules**: Manage access to club spaces and posts
7. **System Rules**: Admin-only and special collections

When making changes:
- Keep helper functions updated and consistent
- Test all affected paths after changes
- Consider impact on existing data

## Maintenance & Updates

### When to Update Rules

Update security rules when:
- Adding new collections or fields
- Changing access patterns or permissions
- Fixing security vulnerabilities
- Optimizing rule performance

### Update Process

1. Make changes in a development environment first
2. Test extensively with the Firebase Emulator
3. Document changes in comments within rules files
4. Deploy to production after thorough testing
5. Monitor for unexpected access issues

### Version Control

- Keep rules in version control with the application code
- Document major rule changes in commit messages
- Create a rollback plan for emergency situations

## Common Issues & Troubleshooting

### Unauthorized Access Errors

If users receive "Permission denied" errors:

1. Check if rules are properly deployed
2. Verify the user is authenticated correctly
3. Confirm collection/document paths match rule paths
4. Check if the user meets all conditions in the rules

### Rule Size Limitations

Firebase has a 256KB limit on rules file size. If you exceed this:

1. Remove redundant or duplicate rules
2. Refactor helper functions to be more efficient
3. Simplify complex conditions where possible

### Performance Considerations

Rules with many `get()` or `exists()` operations can impact performance:

1. Minimize cross-collection lookups
2. Use denormalized data where appropriate
3. Consider moving complex authorization to Cloud Functions
4. Test rule performance with realistic data volumes

### Testing with Admin SDK

Note that the Firebase Admin SDK bypasses security rules. When testing:

1. Always use the client SDK for rule validation
2. Don't rely on Admin SDK behavior to test rules
3. Test both positive and negative cases

## Conclusion

Proper implementation and testing of Firebase security rules is crucial for the HIVE UI platform's data integrity and user privacy. Follow this guide to ensure your rules are correctly deployed and maintained.

For any questions or further assistance, consult:
- Firebase Security Rules documentation: [https://firebase.google.com/docs/rules](https://firebase.google.com/docs/rules)
- HIVE UI development team
- Firebase support channels 