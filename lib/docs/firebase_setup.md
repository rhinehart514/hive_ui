# Firebase Setup for HIVE UI

This document outlines the steps needed to properly configure Firebase with the HIVE UI application.

## Prerequisites

1. Firebase project created at [firebase.google.com](https://firebase.google.com)
2. Flutter SDK installed and configured
3. Node.js installed for the Firebase CLI

## Setup Steps

### 1. Install Required Tools

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Install FlutterFire CLI
dart pub global activate flutterfire_cli
```

### 2. Login to Firebase

```bash
firebase login
```

### 3. Configure FlutterFire

From the root of your project, run:

```bash
flutterfire configure --project=hive-9265c
```

This will:
- Select your Firebase project
- Configure platforms (Android, iOS, Web)
- Create the necessary Firebase configuration files
- Update the `firebase_options.dart` file with proper credentials

### 4. Update the Firebase Options

The current `firebase_options.dart` file has placeholder values. After running `flutterfire configure`, it will be updated with the correct values for your project.

### 5. Initialize Firebase in Your App

In your `main.dart` file, make sure to initialize Firebase:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// ...

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Rest of your app initialization
  // ...
}
```

## Adding Firebase Services

After the basic setup, you can add specific Firebase services:

### Authentication

```bash
flutter pub add firebase_auth
```

### Cloud Firestore

```bash
flutter pub add cloud_firestore
```

### Cloud Storage

```bash
flutter pub add firebase_storage
```

### Analytics

```bash
flutter pub add firebase_analytics
```

### Messaging

```bash
flutter pub add firebase_messaging
```

## Troubleshooting

If you encounter issues with the Firebase setup:

1. Ensure you have the latest version of the Firebase CLI
2. Make sure you're logged in with the correct Firebase account
3. Verify that your `firebase_options.dart` file has the correct credentials
4. Check that the platforms (Android, iOS, Web) are properly configured in your Firebase project 