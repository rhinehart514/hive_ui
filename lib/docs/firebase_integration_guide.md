# Firebase Integration Guide for HIVE

This document outlines how Firebase is integrated into the HIVE application and provides guidelines for testing and development.

## 1. Integration Overview

HIVE uses Firebase for authentication, data storage, analytics, and cloud messaging across all platforms (iOS, Android, Web, and Windows). The Firebase integration is designed to:

- Provide consistent functionality across all platforms
- Support terminal testing without compilation
- Handle platform-specific requirements and limitations
- Enable proper error handling for development and production

## 2. Firebase Services Used

- **Firebase Authentication**: User authentication and account management
- **Cloud Firestore**: NoSQL database for structured data storage
- **Firebase Storage**: Binary storage for images and files
- **Firebase Analytics**: User behavior tracking and insights
- **Firebase Cloud Messaging**: Push notifications
- **Firebase Crashlytics**: Crash reporting and analysis

## 3. Project Structure

The Firebase integration follows a layered architecture for maintainability and testability:

```
lib/
  ├── services/
  │   ├── firebase_service_interface.dart     # Common interface for Firebase operations
  │   ├── firebase_service_implementation.dart # Real Firebase implementation
  │   └── mock/
  │       └── firebase_mock_service.dart      # Mock implementation for testing
  ├── features/
  │   ├── auth/                               # Authentication feature module
  │   │   ├── data/                           # Firebase auth implementation
  │   │   ├── domain/                         # Auth domain model and interfaces
  │   │   └── presentation/                   # Auth UI components
  │   └── ...                                 # Other feature modules
  ├── firebase_options.dart                   # Auto-generated Firebase configuration
  └── main.dart                               # App initialization with Firebase
```

## 4. Terminal Testing Without Compilation

The application is designed to gracefully handle Firebase initialization failures during terminal testing, allowing for development and testing without fully compiling the app.

### 4.1 Testing Behavior

During terminal testing:

- Firebase initialization errors are caught and logged
- The application continues to run in a degraded mode
- Mock data is used when Firebase services are unavailable
- UI elements display appropriate fallback states
- Non-Firebase functionality remains testable

### 4.2 Testing Commands

Use these commands for terminal testing:

```bash
# Run the app with hot reload for UI testing
flutter run -d windows

# Run specific test files
flutter test test/services/firebase_service_test.dart

# Run all tests with mocked Firebase
flutter test --dart-define=USE_FIREBASE_MOCKS=true
```

## 5. Platform-Specific Considerations

### 5.1 Windows Platform

Windows support for Firebase has been implemented with several custom fixes:

- CMake configuration in `windows/CMakeLists.txt`
- Firebase plugin fixes in `windows/fix_firebase_*.ps1` scripts
- Variant type compatibility fixes for C++ integration
- Custom error handling for Windows-specific Firebase issues

### 5.2 Android Platform

Android Firebase integration requires:

- Proper configuration in `android/app/build.gradle`
- Google Services plugin configuration
- Manifest permissions for Firebase services

### 5.3 iOS Platform

iOS Firebase integration requires:

- Proper configuration in `ios/Podfile`
- GoogleService-Info.plist integration
- Background modes for Firebase messaging

## 6. Authentication Implementation

Firebase Authentication is integrated through the `FirebaseAuthRepository` implementation, which:

- Supports email/password authentication
- Maps Firebase user data to domain models
- Handles authentication state changes
- Provides error handling with user-friendly messages

## 7. Firestore Data Model

The Firestore database uses the following collections:

- `users`: User profiles and preferences
- `clubs`: Club information and metadata
- `events`: Event details and RSVPs
- `chats`: Messaging data and chat history

## 8. Firebase Storage Structure

Firebase Storage organizes binary data in the following structure:

- `/profile_images/{userId}`: User profile pictures
- `/club_images/{clubId}`: Club logos and media
- `/event_images/{eventId}`: Event banners and photos
- `/chat_media/{chatId}/{messageId}`: Media shared in chats

## 9. Common Issues and Solutions

### 9.1 Firebase Initialization Failures

If Firebase initialization fails during terminal testing:

1. The app will log detailed error information
2. It will continue with reduced functionality
3. Mock data will be used where possible

This is expected behavior for terminal testing without compilation.

### 9.2 Windows-Specific Issues

Windows has limited Firebase plugin support. If you encounter issues:

1. Run the Windows fix scripts in `windows/fix_firebase_windows.bat`
2. Check the logs for specific error messages
3. Refer to Windows README for detailed troubleshooting

### 9.3 Firebase Plugin Versions

Ensure Firebase plugin versions are compatible. Current versions:

- firebase_core: ^2.32.0
- firebase_auth: ^4.11.0
- cloud_firestore: ^4.17.5
- firebase_storage: ^11.6.5
- firebase_analytics: ^10.10.7
- firebase_messaging: ^14.7.10

## 10. Development Guidelines

### 10.1 Adding New Firebase Features

When adding new Firebase functionality:

1. Define domain interfaces in the feature's domain layer
2. Create both real and mock implementations
3. Add error handling for terminal testing
4. Add appropriate fallback UI states
5. Document platform-specific considerations

### 10.2 Error Handling

Follow these principles for Firebase-related errors:

1. Catch specific Firebase exceptions (FirebaseAuthException, FirebaseException)
2. Map error codes to user-friendly messages
3. Log detailed error information for debugging
4. Provide graceful fallbacks for terminal testing

### 10.3 Testing

For comprehensive testing:

1. Create unit tests with Firebase mocks
2. Use integration tests for Firebase API validation
3. Test error scenarios and recovery
4. Verify functionality across all supported platforms

## 11. Deployment Checklist

Before deploying:

1. Verify Firebase configuration for all platforms
2. Check security rules for Firestore and Storage
3. Test authentication flows end-to-end
4. Verify offline functionality and error handling
5. Ensure Firebase Analytics events are properly tracked

## 12. Resources

- [Firebase Flutter documentation](https://firebase.google.com/docs/flutter/setup)
- [Firebase console](https://console.firebase.google.com/project/hive-9265c/)
- [Flutter Firebase plugins](https://github.com/firebase/flutterfire) 