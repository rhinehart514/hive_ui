# Deep Linking in HIVE

This document explains how deep linking works in the HIVE application, providing both a high-level overview and technical implementation details.

## Overview

HIVE supports deep linking to various content types within the app, allowing users to share links that open specific content directly. Deep links can be used in the following formats:

- Custom URI scheme: `hive://content-type/id`
- Web URLs: `https://hiveapp.com/content-type/id`

## Supported Deep Link Formats

The following content types can be accessed via deep links:

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

## Authentication and Flow

When a deep link is opened:

1. If the user is not authenticated, they are redirected to the login screen
2. The deep link is saved for processing after authentication
3. Once authenticated, the user is redirected to the requested content
4. If the user has not completed onboarding, they must finish onboarding first
5. If the content cannot be found or the link is invalid, a 404 page is displayed

## Technical Implementation

### DeepLinkService

Deep link handling is managed by the `DeepLinkService` class, which:

- Intercepts incoming deep links at app launch
- Listens for links opened while the app is running
- Handles authentication checks
- Processes link parameters
- Navigates to the appropriate screen

### Key Components

- `DeepLinkService`: Main service handling deep link processing logic
- `NavigatorKeyProvider`: Provides a global navigator key for navigation
- `PendingDeepLinkProvider`: Stores pending deep links for after authentication
- `NotFoundScreen`: 404 screen for invalid links

### Error Handling

The deep link system includes robust error handling:

- Invalid URLs are redirected to a custom 404 page
- Malformed links display an appropriate error message
- Missing content IDs trigger fallback routes
- Network errors are handled gracefully

### Implementation Example

```dart
// Processing a deep link
void _processDeepLink(Uri uri) {
  if (_isEventLink(uri)) {
    _handleEventLink(uri);
  } else if (_isSpaceLink(uri)) {
    _handleSpaceLink(uri);
  } else {
    _handleUnknownDeepLink(uri);
  }
}

// Handling an invalid deep link
void _handleUnknownDeepLink(Uri uri) {
  router.goNamed(
    'not_found', 
    queryParameters: {
      'path': uri.toString(),
      'isDeepLink': 'true',
    },
  );
}
```

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

## Future Improvements

Planned enhancements to the deep linking system:

- Dynamic link support (Firebase Dynamic Links)
- Branch.io integration for better tracking
- Deferred deep linking for new user acquisition
- A/B testing for deep link campaigns
- Supporting more content types

## Troubleshooting

If you encounter issues with deep links:

1. Check that the link format matches the supported patterns
2. Ensure the content ID exists in the database
3. Verify the user has permission to access the content
4. Check the app logs for specific error messages
5. Try clearing the app cache if links are not opening correctly 