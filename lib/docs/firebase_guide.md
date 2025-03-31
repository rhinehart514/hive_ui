# Firebase Integration Guide for HIVE UI

This guide explains how Firebase is integrated with HIVE UI across different platforms and provides instructions for developers working with Firebase features.

## Firebase Support Status

HIVE UI now supports Firebase across all platforms:

- ✅ Android: Native implementation
- ✅ iOS: Native implementation
- ✅ Web: Web implementation
- ✅ Windows: Native implementation
- ✅ macOS: Native implementation
- ✅ Linux: Native implementation

## Project Setup

The project uses the following Firebase products:

- Firebase Authentication
- Firestore Database
- Firebase Storage
- Firebase Analytics
- Cloud Functions
- Firebase Crashlytics

## Setup for Development

### Required Tools

1. Flutter SDK (latest stable version)
2. Firebase CLI
3. Platform-specific tools (Android Studio, Xcode, Visual Studio for Windows)

### Initial Setup Steps

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Ensure Firebase is properly configured on your development machine

### Windows-Specific Setup

For Windows development, execute these steps after cloning the repository:

```bash
# Navigate to your project directory
cd path/to/hive_ui

# Apply Windows Firebase fixes
flutter pub run flutterfire_cli:main configure

# If you encounter plugin_version.h.in issues, manually create the file:
$pluginDir = "windows/flutter/ephemeral/.plugin_symlinks/firebase_auth/windows"
New-Item -Path "$pluginDir/plugin_version.h.in" -ItemType File -Force
Set-Content -Path "$pluginDir/plugin_version.h.in" -Value "#define PLUGIN_VERSION ""@PLUGIN_VERSION@"""
```

## Firebase Configuration Files

The project includes platform-specific Firebase configuration files:

- `android/app/google-services.json` - Android configuration
- `ios/Runner/GoogleService-Info.plist` - iOS configuration
- `windows/flutter/ephemeral/.plugin_symlinks/firebase_*` - Windows configuration
- `macos/Runner/GoogleService-Info.plist` - macOS configuration
- `web/firebase-config.js` - Web configuration

These files are ignored in .gitignore by default. Contact the project administrator for access to these files for your development environment.

## Testing Firebase Features

### Testing in Development Environment

1. Use real Firebase services in development by default
2. For testing without Firebase, the app will continue with degraded functionality

### Terminal Testing

When testing in terminal environments (CI/CD, Flutter test, etc.), Firebase initialization may fail. The app is designed to handle this gracefully and continue with degraded functionality.

In these scenarios:
- Firebase initialization errors will be logged but not crash the app
- All Firebase-dependent features will degrade gracefully
- Analytics, authentication, and other Firebase features will be disabled

### Debugging Firebase Issues

If you encounter Firebase initialization issues:

1. Check platform-specific configuration files
2. Verify Firebase CLI is properly set up
3. For Windows, ensure plugin_version.h.in file exists
4. Check terminal output for detailed error messages and platform info
5. Verify the `lib/services/firebase_service_interface.dart` implementation

## Adding New Firebase Features

When adding new Firebase functionality:

1. Add the required Firebase packages to pubspec.yaml
2. Update the FirebaseServiceInterface with the new functionality
3. Ensure all platforms are properly supported
4. Add graceful degradation for terminal testing
5. Add appropriate error handling

## Firebase Authentication

Firebase Authentication is implemented across all platforms. Key files:

- `lib/services/auth_service.dart` - Authentication service
- `lib/controllers/auth_controller.dart` - Authentication controller
- `lib/pages/sign_in_page.dart` - Sign in UI
- `lib/pages/create_account.dart` - Account creation UI

## Troubleshooting

### Common Issues

1. **Firebase initialization fails on Windows**
   - Ensure plugin_version.h.in file exists
   - Run `flutter clean` and rebuild

2. **Authentication fails on specific platforms**
   - Verify platform-specific configuration
   - Check Firebase console for enabled authentication methods

3. **Firestore access denied**
   - Verify security rules in Firebase console
   - Check authentication state

### Getting Help

If you encounter Firebase integration issues, contact the development team or refer to the Firebase documentation at [firebase.google.com/docs](https://firebase.google.com/docs). 