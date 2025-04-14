# Deep Link Handling in HIVE UI

This document explains how deep linking is implemented in the HIVE UI application, providing technical details about the implementation and how to use and test deep links.

## Overview

HIVE UI supports deep linking to various content types within the app, allowing users to:
- Open the app with a deep link from another app or a web browser
- Share app content via deep links
- Navigate directly to specific content within the app

Deep links are supported in two formats:
- Custom URI scheme: `hive://content-type/id`
- Web URLs: `https://hiveapp.com/content-type/id`

## Implementation Components

### 1. DeepLinkService

The core component handling deep links is the `DeepLinkService` class, which:
- Initializes and listens for deep links using the `uni_links` package
- Processes incoming links and routes users to the appropriate screen
- Handles authentication state and permissions before navigating
- Saves links for processing after authentication/onboarding if needed

```dart
class DeepLinkService {
  // Initialize and start listening for deep links
  Future<void> initialize() async { ... }
  
  // Public method to handle incoming links
  Future<void> handleIncomingLink(String link) async { ... }
  
  // Private implementation for processing links
  Future<void> _handleDeepLink(String link) async { ... }
}
```

### 2. DeepLinkSchemes

The `DeepLinkSchemes` class defines all supported deep link formats:

```dart
class DeepLinkSchemes {
  static const String events = 'events/:eventId';
  static const String spaces = 'spaces/:spaceType/spaces/:spaceId';
  static const String profiles = 'profiles/:profileId';
  // ... other schemes
}
```

### 3. DeepLinkUrlGenerator

The `DeepLinkUrlGenerator` class provides methods to generate properly formatted deep links:

```dart
class DeepLinkUrlGenerator {
  static String eventLink(String eventId, {bool useWebUrl = true}) { ... }
  static String spaceLink(String spaceType, String spaceId, {bool useWebUrl = true}) { ... }
  // ... other generator methods
}
```

### 4. DeepLinkSharingService

The `DeepLinkSharingService` provides methods to share deep links with other apps:

```dart
class DeepLinkSharingService {
  Future<void> shareEvent(Event event) async { ... }
  Future<void> shareSpace(Space space) async { ... }
  // ... other sharing methods
}
```

### 5. Riverpod Integration

Deep link handling is integrated with Riverpod providers:

```dart
// Provider for the DeepLinkService
final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  return DeepLinkService(ref);
});

// Provider for storing pending deep links
final pendingDeepLinkProvider = StateProvider<String?>((ref) => null);

// Provider to check for pending deep links after authentication
final deepLinkAuthListenerProvider = Provider<void>((ref) {
  // Watch auth changes and process pending links
  ...
});
```

### 6. GoRouter Integration

Deep linking is integrated with GoRouter for navigation:

```dart
final routerProvider = Provider<GoRouter>((ref) {
  // Initialize DeepLinkService
  final deepLinkService = ref.watch(deepLinkServiceProvider);
  
  // Watch for auth changes to handle deep links
  ref.watch(deepLinkAuthListenerProvider);
  
  // Initialize deep link handling
  Future.microtask(() async {
    await deepLinkService.initialize();
  });
  
  // Create router with routes
  ...
});
```

## Supported Deep Link Types

| Content Type | URI Format | Web URL Format | Example |
|--------------|------------|----------------|---------|
| Events | `hive://events/{id}` | `https://hiveapp.com/events/{id}` | `hive://events/abc123` |
| Spaces | `hive://spaces/{type}/spaces/{id}` | `https://hiveapp.com/spaces/{type}/spaces/{id}` | `hive://spaces/club/spaces/xyz456` |
| Profiles | `hive://profiles/{id}` | `https://hiveapp.com/profiles/{id}` | `hive://profiles/user789` |
| Direct Chats | `hive://messages/chat/{id}` | `https://hiveapp.com/messages/chat/{id}` | `hive://messages/chat/chat123` |
| Group Chats | `hive://messages/group/{id}` | `https://hiveapp.com/messages/group/{id}` | `hive://messages/group/group456` |
| Posts | `hive://posts/{id}` | `https://hiveapp.com/posts/{id}` | `hive://posts/post789` |
| Search | `hive://search?q={query}` | `https://hiveapp.com/search?q={query}` | `hive://search?q=technology` |
| Organizations | `hive://organizations/{id}` | `https://hiveapp.com/organizations/{id}` | `hive://organizations/org123` |
| Event Check-ins | `hive://events/{id}/check-in/{code}` | `https://hiveapp.com/events/{id}/check-in/{code}` | `hive://events/event123/check-in/ABCDEF` |

## Authentication Flow

When a deep link is opened:

1. If the user is not authenticated:
   - They are redirected to the login screen
   - The deep link is saved using `pendingDeepLinkProvider`
   - After successful authentication, the deep link is processed

2. If the user has not completed onboarding:
   - They are redirected to complete onboarding
   - The deep link is saved using `pendingDeepLinkProvider`
   - After onboarding is completed, the deep link is processed

3. If the user is authenticated and has completed onboarding:
   - The deep link is processed immediately
   - The user is navigated to the appropriate screen

## Error Handling

The deep link system includes robust error handling:

- Invalid URLs are redirected to a custom 404 page
- Malformed links display an appropriate error message
- Missing content IDs trigger fallback routes
- Network errors are handled gracefully

## Testing Deep Links

### On Android

Test deep links on Android using ADB:

```
adb shell am start -a android.intent.action.VIEW -d "hive://events/abc123" com.hiveapp.android
```

### On iOS

Test deep links on iOS using xcrun:

```
xcrun simctl openurl booted "hive://events/abc123"
```

## App Configuration for Deep Links

### Android

In `AndroidManifest.xml`, the activity intent filters are configured:

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <!-- URI scheme -->
    <data android:scheme="hive" />
</intent-filter>
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <!-- Web URL -->
    <data android:scheme="https" android:host="hiveapp.com" />
</intent-filter>
```

### iOS

In `Info.plist`, the URL types are configured:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>com.hiveapp.ios</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>hive</string>
        </array>
    </dict>
</array>
```

For universal links/web URLs, `Associated Domains` is configured as:

```
applinks:hiveapp.com
```

## Future Improvements

Planned enhancements to the deep linking system:

- Firebase Dynamic Links integration
- Short URL generation and handling
- QR code generation for deep links
- Deep link analytics and tracking
- A/B testing for deep link campaigns
- Supporting additional content types

## Troubleshooting

If deep links aren't working:

1. Check Android/iOS configuration
2. Verify `uni_links` package is properly initialized
3. Check console logs for errors
4. Test with both URI scheme and web URL formats
5. Ensure content IDs exist in the database 