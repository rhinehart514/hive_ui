# Social Authentication Redirection System

This document explains how the social authentication redirection system works in the Hive UI app.

## Overview

The social authentication redirection system allows users to initiate authentication from any page in the app and be redirected back to that page after successful authentication. This enables a seamless user experience for protected features.

## Components

The system consists of the following components:

1. **Router Configuration**: Handles auth state and redirection logic based on query parameters.
2. **UserPreferencesService**: Stores and retrieves redirect paths for social authentication.
3. **SocialAuthButton**: Component used on the login/register page that accepts a return path.
4. **SocialLoginButton**: Reusable component that can be used on any page to initiate social authentication with a return path.
5. **DeepLinkService**: Helper service that provides navigation methods for social authentication.

## How It Works

### 1. Initiating Social Authentication with Redirect

Use the `SocialLoginButton` widget on any page where you want to allow social authentication:

```dart
SocialLoginButton(
  text: 'Continue with Google',
  icon: Icons.g_mobiledata_rounded,
  returnToPath: '/spaces/create',
)
```

This button will:
- Navigate to the login page
- Add query parameters `auth_source=social` and `return_to=/spaces/create`
- After successful authentication, redirect the user back to the specified path

### 2. Programmatic Redirection

You can also programmatically redirect to social authentication using:

```dart
DeepLinkService.navigateToSocialAuth(context, '/spaces/create');
```

### 3. Router Configuration

The router handles redirection logic by checking:
- Authentication state
- Query parameters
- User preferences

If a user is authenticated and has a stored redirect path from social authentication, they will be directed to that path after completing any required onboarding or terms acceptance.

### 4. Customizing the Login Page

The login page reads the `return_to` parameter from the URL and passes it to the `SocialAuthButton` component. After successful authentication, the user is redirected to the specified path.

## Usage Examples

### Protected Feature Button

```dart
ElevatedButton(
  onPressed: user == null
    ? () => DeepLinkService.navigateToSocialAuth(context, '/events/create')
    : () => context.push('/events/create'),
  child: Text('Create Event'),
)
```

### Custom Social Auth Button

```dart
SocialLoginButton(
  text: 'Sign in to Comment',
  icon: Icons.comment,
  returnToPath: '/posts/$postId',
  onBeforeNavigate: () {
    // Save any draft comment
    saveDraftComment();
  },
)
```

## Implementation Notes

- All redirects are processed after the user has completed authentication, onboarding, and terms acceptance.
- Redirect paths are stored in shared preferences for persistence across app restarts.
- The redirect system works with both Google Sign-In and (future) additional social providers.

## Testing

To test the social authentication redirection system:
1. Log out of the app
2. Navigate to a protected feature
3. Tap the social authentication button
4. Complete the authentication flow
5. Verify that you are redirected back to the protected feature

## Limitations

- Deep linking from external apps is handled separately from this system.
- The system assumes that all paths are valid within the app. Invalid paths may result in the default redirect to the home page.

## Future Improvements

- Support for external app deep linking with social authentication
- Preservation of more complex states during the authentication flow
- Support for additional social providers 